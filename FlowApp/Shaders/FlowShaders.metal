// FLOW — Luminous Ink: Prototype 01 shaders
//
// Pass order per fixed step (§5.5), executed by FlowRenderer:
//   1 advectVelocity → 2 injectVelocity → 3 dampVelocity
//   4 advectPigment → 5 injectPigment
//   6 advectDetail → 7 injectDetailDecay
//   composite → bloomExtract → bloomBlurH → bloomBlurV → final (display/capture)
//
// Invariants:
//   - Each texture is written by, at most, one kernel in a pass; reads are of
//     the previous state only (A/B roles managed in Swift).
//   - Injection kernels iterate `events[]` serially per texel → deterministic
//     across thread schedules (no read-modify-write races, no atomics).
//   - No wall-clock randomness. All noise uses `seed` (fixed by fixtures).
//   - Textures that must be sampled declare `access::sample`; output textures
//     use `access::write`. Layouts mirror ShaderBridge.swift (asserted at
//     runtime; sizes 88 / 64 bytes).

#include <metal_stdlib>
using namespace metal;

// ---------------------------------------------------------------------------
// Shared types
// ---------------------------------------------------------------------------

struct StepParams {
    float2 dtRadius;      // dt, radiusFraction
    float2 iso;           // (sx, sy) physical scale vs short side
    float2 invIso;
    float2 gains;         // momentumGain, maxVelocity
    float2 noiseSeed;     // noiseScale, seed (float)
    float2 maxDyeStrength;// maxDye, detailStrength
    float2 wavelengthHL;  // detailWavelength, velocityHalfLife
    float2 pigDetHL;      // pigmentHalfLife, detailHalfLife
    float2 bloom;         // bloomStrength, bloomThreshold
    float2 bg0;           // background linear rgb (r,g)
    float2 bg1;           // background b, pad
    float2 edgeCurve;     // dye remap range (lo, hi) for a clear-but-soft rim
};

struct StrokeEvent {
    float2 pos;           // normalized canvas [0,1]², top-left
    float2 vel;           // short-side / s
    float  radius;        // short-side fraction
    float  strength;      // momentum multiplier
    float  dye;           // amount 0...1
    float  force;         // 0...1
    float3 color;         // linear RGB [0,1]
    float2 tangent;       // unit, physical frame
    uint   kind;          // 0 tap, 1 stroke
    float  radiusPigment; // pigment footprint (denser core than velocity)
};

// ---------------------------------------------------------------------------
// Utilities
// ---------------------------------------------------------------------------

constant sampler kLinear (coord::normalized, address::clamp_to_edge, filter::linear);
constant sampler kNearest (coord::normalized, address::clamp_to_edge, filter::nearest);

inline float hash21(float2 p, float seedF) {
    float2 q = p * 127.1f + float2(seedF * 31.7f, seedF * 17.3f);
    float h = fract(sin(dot(q, float2(127.1f, 311.7f))) * 43758.5453f);
    return h;
}

inline float2 uvOf(uint2 gid, uint w, uint h) {
    return (float2(gid) + 0.5f) / float2(w, h);
}

inline float2 physOffset(float2 uv, float2 pos, float2 iso) {
    return float2((uv.x - pos.x) * iso.x, (uv.y - pos.y) * iso.y);
}

inline float gaussian(float r2, float radius) {
    float inv = 1.0f / max(radius * radius, 1e-5f);
    return exp(-r2 * inv * 0.5f);
}

// Soft, long-tailed radial kernel used for PIGMENT and DETAIL.
// A Gaussian saturates in the core and then drops steeply, which produced a
// flat “stamp” disc. This polynomial falls smoothly to zero at `radius`, so
// concentration — and therefore luminance — varies visibly across the blob.
inline float softKernel(float r2, float radius) {
    float x = r2 / max(radius * radius, 1e-6f);
    float w = max(0.0f, 1.0f - x);
    return w * w * w;                     // (1 - r²/R²)³ : long gentle shoulder
}

// Deterministic angular wobble of the radius (no wall-clock randomness).
// A mathematically perfect circle reads as machine-drawn; real ink spreads
// unevenly. Two low harmonics keep the outline organic and cheap to evaluate.
inline float wobble(float2 d, float seedF) {
    float ang = atan2(d.y, d.x);
    return 1.0f + 0.17f * sin(3.0f * ang + seedF * 1.7f)
                + 0.10f * sin(5.0f * ang - seedF * 0.9f)
                + 0.06f * sin(8.0f * ang + seedF * 2.3f);
}

inline float2 safe2(float2 v) { return select(float2(0.0f), v, isfinite(v)); }
inline float  safe1(float v)  { return isfinite(v) ? v : 0.0f; }
inline float4 safe4(float4 v) { return select(float4(0.0f), v, isfinite(v)); }

// ---------------------------------------------------------------------------
// PASS 1 — Advect velocity (semi-Lagrangian reverse sampling)  velA→velB
// ---------------------------------------------------------------------------
kernel void advectVelocity(texture2d<float, access::sample> src [[texture(0)]],
                           texture2d<float, access::write>  dst [[texture(1)]],
                           constant StepParams& p [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]]) {
    uint w = dst.get_width(), h = dst.get_height();
    if (gid.x >= w || gid.y >= h) return;
    float2 uv = uvOf(gid, w, h);
    float2 vel = safe2(src.sample(kLinear, uv).xy);
    float2 back = uv - float2(vel.x * p.invIso.x, vel.y * p.invIso.y) * p.dtRadius.x;
    back = saturate(back);
    dst.write(float4(safe2(src.sample(kLinear, back).xy), 0.0f, 0.0f), gid);
}

// ---------------------------------------------------------------------------
// PASS 2 — Inject velocity  velB→velA (serial per-texel, deterministic)
// ---------------------------------------------------------------------------
kernel void injectVelocity(texture2d<float, access::sample> src   [[texture(0)]],
                           texture2d<float, access::write>  dst   [[texture(1)]],
                           constant StepParams& p [[buffer(0)]],
                           device const StrokeEvent* events       [[buffer(1)]],
                           constant uint& eventCount              [[buffer(2)]],
                           uint2 gid [[thread_position_in_grid]]) {
    uint w = dst.get_width(), h = dst.get_height();
    if (gid.x >= w || gid.y >= h) return;
    float2 uv = uvOf(gid, w, h);
    float2 v = safe2(src.sample(kLinear, uv).xy);
    for (uint i = 0; i < eventCount; ++i) {
        StrokeEvent e = events[i];
        float2 d = physOffset(uv, e.pos, p.iso);
        float g = gaussian(dot(d, d), e.radius);
        if (g < 1e-4f) continue;
        float2 add;
        if (e.kind == 0) {
            float rl = max(length(d), 1e-5f);
            add = (d / rl) * g * 0.35f * e.strength;   // radial bloom, no hard ring
        } else {
            add = e.vel * g * e.strength;
        }
        v += add;
    }
    dst.write(float4(safe2(v), 0.0f, 0.0f), gid);
}

// ---------------------------------------------------------------------------
// PASS 3 — Damp + clamp velocity  velA→velB
// ---------------------------------------------------------------------------
kernel void dampVelocity(texture2d<float, access::sample> src [[texture(0)]],
                         texture2d<float, access::write>  dst [[texture(1)]],
                         constant StepParams& p [[buffer(0)]],
                         uint2 gid [[thread_position_in_grid]]) {
    uint w = dst.get_width(), h = dst.get_height();
    if (gid.x >= w || gid.y >= h) return;
    float2 uv = uvOf(gid, w, h);
    float2 v = safe2(src.sample(kLinear, uv).xy);
    float decay = pow(0.5f, p.dtRadius.x / max(p.wavelengthHL.y, 1e-6f));
    v *= decay;
    float m = length(v);
    if (m > p.gains.y) v *= p.gains.y / m;
    dst.write(float4(v, 0.0f, 0.0f), gid);
}

// ---------------------------------------------------------------------------
// PASS 4 — Advect pigment (premultiplied linear transport)  pigA→pigB
// ---------------------------------------------------------------------------
kernel void advectPigment(texture2d<float, access::sample> src    [[texture(0)]],
                          texture2d<float, access::sample> velTex [[texture(1)]],
                          texture2d<float, access::write>  dst    [[texture(2)]],
                          constant StepParams& p [[buffer(0)]],
                          uint2 gid [[thread_position_in_grid]]) {
    uint w = dst.get_width(), h = dst.get_height();
    if (gid.x >= w || gid.y >= h) return;
    float2 uv = uvOf(gid, w, h);
    float2 vel = safe2(velTex.sample(kLinear, uv).xy);
    float2 back = uv - float2(vel.x * p.invIso.x, vel.y * p.invIso.y) * p.dtRadius.x;
    back = saturate(back);
    float4 c = src.sample(kLinear, back);
    c.xyz = min(c.xyz, c.a);            // premul invariant
    c = max(c, float4(0.0f));
    dst.write(safe4(c), gid);
}

// ---------------------------------------------------------------------------
// PASS 5 — Inject pigment (bounded overlay, sequential per texel)  pigB→pigA
// ---------------------------------------------------------------------------
kernel void injectPigment(texture2d<float, access::sample> src   [[texture(0)]],
                          texture2d<float, access::write>  dst   [[texture(1)]],
                          constant StepParams& p [[buffer(0)]],
                          device const StrokeEvent* events       [[buffer(1)]],
                          constant uint& eventCount              [[buffer(2)]],
                          uint2 gid [[thread_position_in_grid]]) {
    uint w = dst.get_width(), h = dst.get_height();
    if (gid.x >= w || gid.y >= h) return;
    float2 uv = uvOf(gid, w, h);
    float4 c = src.sample(kLinear, uv);
    c.xyz = min(c.xyz, c.a);
    float freeA = 1.0f - saturate(c.a);
    for (uint i = 0; i < eventCount; ++i) {
        StrokeEvent e = events[i];
        float2 d = physOffset(uv, e.pos, p.iso);
        float rPig = (e.radiusPigment > 0.0f) ? e.radiusPigment : e.radius;
        // Radial (tap/hold) events need the long-tailed soft kernel so the bloom
        // is graded; strokes keep the wider Gaussian footprint that makes a
        // ribbon read as continuous rather than thin.
        float g;
        if (e.kind == 0) {
            float wb = wobble(d, p.noiseSeed.y);
            g = softKernel(dot(d, d) * wb * wb, rPig);
        } else {
            g = gaussian(dot(d, d), rPig);
        }
        if (g < 1e-4f) continue;
        float s = clamp(g * e.dye * (0.4f + 0.6f * e.force), 0.0f, 1.0f);
        float inject = freeA * s;                 // added = (1-a)*s
        c.a += inject;
        c.xyz += inject * e.color;
        freeA = 1.0f - saturate(c.a);
        if (freeA <= 0.0f) break;
    }
    c.xyz = min(c.xyz, c.a);
    c = max(c, float4(0.0f));
    c.a = min(c.a, p.maxDyeStrength.x + 1e-4f);
    dst.write(safe4(c), gid);
}

// ---------------------------------------------------------------------------
// PASS 5b — Decay pigment (half-life) + premul clamp  pigA→pigB
// ---------------------------------------------------------------------------
kernel void decayPigment(texture2d<float, access::sample> src [[texture(0)]],
                         texture2d<float, access::write>  dst [[texture(1)]],
                         constant StepParams& p [[buffer(0)]],
                         uint2 gid [[thread_position_in_grid]]) {
    uint w = dst.get_width(), h = dst.get_height();
    if (gid.x >= w || gid.y >= h) return;
    float2 uv = uvOf(gid, w, h);
    float4 c = src.sample(kLinear, uv);
    float decay = pow(0.5f, p.dtRadius.x / max(p.pigDetHL.x, 1e-6f));  // pigmentHalfLife
    c *= decay;
    c.xyz = min(c.xyz, c.a);
    dst.write(safe4(max(c, float4(0.0f))), gid);
}

// ---------------------------------------------------------------------------
// PASS 6 — Advect detail  detA→detB
// ---------------------------------------------------------------------------
kernel void advectDetail(texture2d<float, access::sample> src    [[texture(0)]],
                         texture2d<float, access::sample> velTex [[texture(1)]],
                         texture2d<float, access::write>  dst    [[texture(2)]],
                         constant StepParams& p [[buffer(0)]],
                         uint2 gid [[thread_position_in_grid]]) {
    uint w = dst.get_width(), h = dst.get_height();
    if (gid.x >= w || gid.y >= h) return;
    float2 uv = uvOf(gid, w, h);
    float2 vel = safe2(velTex.sample(kLinear, uv).xy);
    float2 back = uv - float2(vel.x * p.invIso.x, vel.y * p.invIso.y) * p.dtRadius.x;
    back = saturate(back);
    dst.write(safe1(src.sample(kLinear, back).x), gid);
}

// ---------------------------------------------------------------------------
// PASS 7 — Inject detail (trajectory-aligned filament) + decay  detB→detA
// ---------------------------------------------------------------------------
kernel void injectDetailDecay(texture2d<float, access::sample> src   [[texture(0)]],
                              texture2d<float, access::write>  dst   [[texture(1)]],
                              constant StepParams& p [[buffer(0)]],
                              device const StrokeEvent* events       [[buffer(1)]],
                              constant uint& eventCount              [[buffer(2)]],
                              uint2 gid [[thread_position_in_grid]]) {
    uint w = dst.get_width(), h = dst.get_height();
    if (gid.x >= w || gid.y >= h) return;
    float2 uv = uvOf(gid, w, h);
    float d = safe1(src.sample(kLinear, uv).x);
    float wl = max(p.wavelengthHL.x, 1e-4f);
    for (uint i = 0; i < eventCount; ++i) {
        StrokeEvent e = events[i];
        float2 off = physOffset(uv, e.pos, p.iso);
        float rDet = (e.radiusPigment > 0.0f) ? e.radiusPigment : e.radius;
        float g;
        if (e.kind == 0) {
            float wb = wobble(off, p.noiseSeed.y);
            g = softKernel(dot(off, off) * wb * wb, rDet);
        } else {
            g = gaussian(dot(off, off), rDet);
        }
        if (g < 1e-4f) continue;
        float2 tangent = e.kind == 0 ? float2(1.0f, 0.0f) : safe2(e.tangent);
        float2 perp = float2(-tangent.y, tangent.x);
        float along = dot(off, tangent);
        float lat = dot(off, perp);
        // slow, deterministic spatial wobble (fixed seed) — continuous banding
        float phase = hash21(floor(uv * 48.0f), p.noiseSeed.y);
        float band = 1.0f + 0.65f * cos((along / wl) * 6.2831853f + phase * 6.2831853f);
        float latBand = 1.0f - 0.55f * exp(-lat * lat / max(wl * wl * 1.5f, 1e-5f));
        float value = g * (0.5f + 0.5f * band) * latBand;
        d = min(1.0f, d + value * 0.55f);
    }
    float decay = pow(0.5f, p.dtRadius.x / max(p.pigDetHL.y, 1e-6f));  // detailHalfLife
    d *= decay;
    dst.write(safe1(clamp(d, 0.0f, 1.0f)), gid);
}

// ---------------------------------------------------------------------------
// PASS 8 — Composite: premul linear pigment × detail modulation → RGBA16
//          (alpha = dye so the final pass mixes over the background)
// ---------------------------------------------------------------------------
kernel void compositePass(texture2d<float, access::sample> pigment [[texture(0)]],
                          texture2d<float, access::sample> detail  [[texture(1)]],
                          texture2d<float, access::write>  out     [[texture(2)]],
                          constant StepParams& p [[buffer(0)]],
                          uint2 gid [[thread_position_in_grid]]) {
    uint w = out.get_width(), h = out.get_height();
    if (gid.x >= w || gid.y >= h) return;
    float2 uv = uvOf(gid, w, h);
    float4 pig = pigment.sample(kLinear, uv);
    float dye = saturate(pig.a);
    float3 color = max(pig.xyz, float3(0.0f));
    float det = safe1(detail.sample(kLinear, uv).x);
    float mod = 1.0f + det * p.maxDyeStrength.y * 0.55f;   // detail only inside dye
    float3 outColor = min(color * mod, float3(1.2f));
    out.write(float4(outColor, dye), gid);
}

// ---------------------------------------------------------------------------
// BLOOM — extract (downsampled), Gaussian H/V, combine in `final`
// ---------------------------------------------------------------------------
kernel void bloomExtract(texture2d<float, access::sample> src [[texture(0)]],
                         texture2d<float, access::write>  dst [[texture(1)]],
                         constant StepParams& p [[buffer(0)]],
                         uint2 gid [[thread_position_in_grid]]) {
    uint w = dst.get_width(), h = dst.get_height();
    if (gid.x >= w || gid.y >= h) return;
    float2 uv = uvOf(gid, w, h);
    float4 c = max(src.sample(kNearest, uv), float4(0.0f));
    float lum = dot(c.xyz, float3(0.299f, 0.587f, 0.114f));
    float thresh = max(p.bloom.y, 0.01f);
    float e = max(lum - thresh, 0.0f);
    dst.write(float4(c.xyz * e * 0.5f, e), gid);
}

kernel void bloomBlurH(texture2d<float, access::sample> src [[texture(0)]],
                       texture2d<float, access::write>  dst [[texture(1)]],
                       uint2 gid [[thread_position_in_grid]]) {
    uint w = dst.get_width(), h = dst.get_height();
    if (gid.x >= w || gid.y >= h) return;
    float2 uv = uvOf(gid, w, h);
    float2 texel = 1.0f / float2(w, h);
    float4 acc = src.sample(kLinear, uv) * 0.227027f;
    float2 off = float2(texel.x, 0);
    acc += src.sample(kLinear, uv + off) * 0.1945947f;
    acc += src.sample(kLinear, uv - off) * 0.1945947f;
    acc += src.sample(kLinear, uv + off * 2.0f) * 0.1216216f;
    acc += src.sample(kLinear, uv - off * 2.0f) * 0.1216216f;
    acc += src.sample(kLinear, uv + off * 3.0f) * 0.0540541f;
    acc += src.sample(kLinear, uv - off * 3.0f) * 0.0540541f;
    dst.write(acc, gid);
}

kernel void bloomBlurV(texture2d<float, access::sample> src [[texture(0)]],
                       texture2d<float, access::write>  dst [[texture(1)]],
                       uint2 gid [[thread_position_in_grid]]) {
    uint w = dst.get_width(), h = dst.get_height();
    if (gid.x >= w || gid.y >= h) return;
    float2 uv = uvOf(gid, w, h);
    float2 texel = 1.0f / float2(w, h);
    float4 acc = src.sample(kLinear, uv) * 0.227027f;
    float2 off = float2(0, texel.y);
    acc += src.sample(kLinear, uv + off) * 0.1945947f;
    acc += src.sample(kLinear, uv - off) * 0.1945947f;
    acc += src.sample(kLinear, uv + off * 2.0f) * 0.1216216f;
    acc += src.sample(kLinear, uv - off * 2.0f) * 0.1216216f;
    acc += src.sample(kLinear, uv + off * 3.0f) * 0.0540541f;
    acc += src.sample(kLinear, uv - off * 3.0f) * 0.0540541f;
    dst.write(acc, gid);
}

// ---------------------------------------------------------------------------
// FINAL — fullscreen composite: bg + linear pigment + bloom → sRGB
// ---------------------------------------------------------------------------
struct FSVertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex FSVertexOut fullscreenVertex(uint vid [[vertex_id]]) {
    float2 uv = float2((vid << 1) & 2, vid & 2);   // (0,0) (2,0) (0,2)
    FSVertexOut o;
    o.position = float4(uv * 2.0f - 1.0f, 0.0f, 1.0f);
    // Contract §5.1 fixes the canvas origin at TOP-LEFT (y down), while Metal
    // NDC y=+1 is the top of the target. Without this flip the whole artwork is
    // mirrored vertically against the finger (found via fixture positions).
    o.uv = float2(uv.x, 1.0f - uv.y);
    return o;
}

// Compose at TARGET resolution (contract §5.4: the display composite must run
// at the drawable's native size — never a straight upscale of the sim grid).
// Samples the low-res state textures with linear filtering, but every gradient,
// filament and background mix is evaluated per native pixel.
fragment float4 finishFragment(FSVertexOut in [[stage_in]],
                               texture2d<float> pigment    [[texture(0)]],
                               texture2d<float> detail     [[texture(1)]],
                               texture2d<float> bloomTex   [[texture(2)]],
                               texture2d<float> velocityTex[[texture(3)]],
                               constant StepParams& p [[buffer(0)]]) {
    float2 uv = in.uv;
    float4 pre = pigment.sample(kLinear, uv);
    float dyeRaw = saturate(pre.a);
    // Contract §4.1: the body needs a clear (not hard) edge, but the INTERIOR
    // must stay graded (a plain smoothstep() here clamped everything above
    // edgeCurve.y to 1.0 and produced a flat-topped disc). Multiplying keeps
    // the interior gradient while suppressing the faint tail into a defined rim.
    float dye = dyeRaw * smoothstep(p.edgeCurve.x, p.edgeCurve.y, dyeRaw);
    // `pre.xyz` is premultiplied (a*C). Undo it so the ink colour can be
    // composited with the coverage once — the previous code multiplied alpha in
    // twice (mix(bg, a*C, a)), which squared the luminance response and made a
    // saturated core look flat.
    float invA = dyeRaw > 1e-4f ? 1.0f / dyeRaw : 0.0f;
    float3 color = clamp(max(pre.xyz, float3(0.0f)) * invA, float3(0.0f), float3(1.6f));
    float det = safe1(detail.sample(kLinear, uv).x);

    // Native-resolution filament structure, aligned with the local flow so it
    // reads as stretched silk rather than random noise (§5.7), and gated by dye
    // so nothing appears outside the ink.
    float2 vel = safe2(velocityTex.sample(kLinear, uv).xy);
    float2 dir = (length(vel) > 1e-4f) ? normalize(vel) : float2(1.0f, 0.0f);
    float2 perp = float2(-dir.y, dir.x);
    float2 pu = uv * p.iso;                       // short-side units
    float freq = max(p.noiseSeed.x, 1.0f);          // cycles per short side
    float phase = dot(pu, dir) * 6.2831853f * freq
                + dot(pu, perp) * 6.2831853f * freq * 0.31f
                + p.noiseSeed.y * 7.0f;
    float fil = pow(0.5f + 0.5f * sin(phase), 3.0f);
    float structure = clamp(det * 0.55f + fil * 0.34f, 0.0f, 1.0f);
    float boost = 1.0f + structure * p.maxDyeStrength.y * 0.6f * dye;

    float3 lit = color * boost;
    float3 bg = float3(p.bg0.x, p.bg0.y, p.bg1.x);
    // Correct premultiplied "over": ink + background*(1 - coverage).
    float3 linear = lit * dye + bg * (1.0f - dye);
    linear += bloomTex.sample(kLinear, uv).xyz * p.bloom.x * 0.85f;
    linear = max(linear, float3(0.0f));
    float3 s3 = step(0.0031308f, linear);
    float3 enc = mix(linear * 12.92f,
                     1.055f * pow(max(linear, 0.0f), 1.0f / 2.4f) - 0.055f, s3);
    return float4(enc, 1.0f);
}

// ---------------------------------------------------------------------------
// RESIZE — preserve content on canvas resize (aspect-correct physical mapping;
//          new areas → zero).
// ---------------------------------------------------------------------------
kernel void resampleState(texture2d<float, access::sample> src [[texture(0)]],
                          texture2d<float, access::write>  dst [[texture(1)]],
                          constant float4& oldDim [[buffer(0)]],   // (W0, H0, _ , _)
                          uint2 gid [[thread_position_in_grid]]) {
    uint w = dst.get_width(), h = dst.get_height();
    if (gid.x >= w || gid.y >= h) return;
    float2 uv = uvOf(gid, w, h);
    float S  = float(min(w, h));
    float S0 = max(1.0f, float(min(int(oldDim.x), int(oldDim.y))));
    float2 aspect  = float2(float(w) / S, float(h) / S);
    float2 aspect0 = float2(max(oldDim.x, 1.0f) / S0, max(oldDim.y, 1.0f) / S0);
    float2 phys = uv * aspect;                     // short-side units in new canvas
    float2 uvOld = phys / aspect0;                 // corresponding old normalized
    bool inside = all(uvOld >= 0.0f) && all(uvOld <= 1.0f);
    dst.write(inside ? src.sample(kLinear, uvOld) : float4(0.0f), gid);
}

// ---------------------------------------------------------------------------
// CLEAR — zero-fill any state texture (blit fill API removed in Xcode 27)
// ---------------------------------------------------------------------------
kernel void clearTex(texture2d<float, access::write> dst [[texture(0)]],
                     uint2 gid [[thread_position_in_grid]]) {
    uint w = dst.get_width(), h = dst.get_height();
    if (gid.x >= w || gid.y >= h) return;
    dst.write(float4(0.0f), gid);
}

// ---------------------------------------------------------------------------
// STATS — Debug one-shot readback (NaN/Inf counts, max alpha/speed)
// ---------------------------------------------------------------------------
kernel void statsScan(texture2d<float, access::sample> pigment  [[texture(0)]],
                      texture2d<float, access::sample> velocity [[texture(1)]],
                      device atomic_uint* counts [[buffer(0)]],
                      uint2 gid [[thread_position_in_grid]]) {
    uint w = pigment.get_width(), h = pigment.get_height();
    if (gid.x >= w || gid.y >= h) return;
    float4 c = pigment.sample(kNearest, uvOf(gid, w, h));
    float2 v = velocity.sample(kNearest, uvOf(gid, w, h)).xy;
    if (!isfinite(c.x) || !isfinite(c.w) || !isfinite(v.x) || !isfinite(v.y)) {
        atomic_fetch_add_explicit(counts + 0, 1u, memory_order_relaxed);  // nan
        return;
    }
    if (isinf(c.x) || isinf(v.x) || isinf(c.w)) {
        atomic_fetch_add_explicit(counts + 1, 1u, memory_order_relaxed);  // inf
    }
    atomic_fetch_max_explicit(counts + 2, as_type<uint>(saturate(c.a)), memory_order_relaxed);
    atomic_fetch_max_explicit(counts + 3, as_type<uint>(max(length(v), 0.0f)), memory_order_relaxed);
}