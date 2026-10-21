#!/usr/bin/env python3
"""Deterministically generate the six standard gesture fixtures (contract §6).

Schema must match ReplayEngine.Fixture:
  schemaVersion, name, seed, canvasAspectRatio, durationSeconds, samples[]
  samples: touchID, phase, time, x, y, inputKind, force?

Run from repo root: python3 scripts/generate-fixtures.py
Output: Tests/Fixtures/*.json (committed)
"""
import json
import math
import os
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "Tests" / "Fixtures"

RATE = 60.0  # raw sample rate (replay normalizer interpolates at 120 Hz steps)


def line(t0, dt, p0, p1, touch_id=0, kind="finger"):
    """Equally spaced samples from p0 to p1 over dt seconds."""
    n = max(1, int(round(dt * RATE)))
    out = []
    for i in range(n + 1):
        t = t0 + dt * i / n
        k = i / n
        x = p0[0] + (p1[0] - p0[0]) * k
        y = p0[1] + (p1[1] - p0[1]) * k
        out.append({"touchID": touch_id, "phase": "moved", "time": round(t, 6),
                    "x": round(x, 6), "y": round(y, 6), "inputKind": kind})
    return out


def begin(t, p, touch_id=0, kind="finger"):
    return {"touchID": touch_id, "phase": "began", "time": round(t, 6),
            "x": round(p[0], 6), "y": round(p[1], 6), "inputKind": kind, "force": 0.5}


def end(t, p, touch_id=0, kind="finger"):
    return {"touchID": touch_id, "phase": "ended", "time": round(t, 6),
            "x": round(p[0], 6), "y": round(p[1], 6), "inputKind": kind}


def fixture(name, seed, samples, duration, aspect=0.4625, expect_curl=None):
    samples.sort(key=lambda s: (s["time"], s["touchID"]))
    doc = {
        "schemaVersion": 1,
        "name": name,
        "seed": seed,
        "canvasAspectRatio": aspect,
        "durationSeconds": duration,
        "samples": samples,
    }
    if expect_curl is not None:
        doc["expectVisibleCurlAtSeconds"] = expect_curl
    return doc


def build_tap():
    s = [begin(0.20, (0.5, 0.42), 0)]
    s += [end(0.24, (0.5, 0.42), 0)]
    return fixture("tap", 2401, s, 10.0)


def build_slow_stroke():
    s = [begin(0.20, (0.30, 0.62), 0)]
    t0, dur = 0.20, 4.0
    # S curve: (0.30,0.62) → (0.43,0.42) → (0.56,0.66) → (0.70,0.46)
    keys = [(0.30, 0.62), (0.43, 0.42), (0.56, 0.66), (0.70, 0.46)]
    seg_t = dur / (len(keys) - 1)
    for i in range(len(keys) - 1):
        p0, p1 = keys[i], keys[i + 1]
        ts = t0 + i * seg_t
        s += line(ts, seg_t, p0, p1, 0)
    s += [end(t0 + dur + 0.02, keys[-1], 0)]
    return fixture("slow-stroke", 2402, s, 10.0)


def build_fast_swipe():
    s = [begin(0.60, (0.08, 0.5), 0)]
    s += line(0.60, 0.20, (0.08, 0.5), (0.92, 0.50), 0)   # 200 ms crossing
    s += [end(0.83, (0.92, 0.5), 0)]
    return fixture("fast-swipe", 2403, s, 10.0)


def build_spiral():
    # continuous inward spiral, radius 0.36 → ~0.02, ~4 turns, over 3 s
    s = [begin(0.20, (0.5 + 0.32 * math.cos(0.6), 0.5 + 0.32 * math.sin(0.6) * 0.85), 0)]
    t = 0.20
    dt = 1.0 / RATE
    n = int(3.0 * RATE)
    a0 = 0.6
    turns = 3.0
    for i in range(1, n + 1):
        k = i / n
        r = 0.32 * (1.0 - k) + 0.09 * k
        a = a0 + turns * math.tau * k
        x = 0.5 + r * math.cos(a)
        y = 0.5 + r * math.sin(a) * 0.85
        s.append({"touchID": 0, "phase": "moved", "time": round(t, 6),
                  "x": round(x, 6), "y": round(y, 6), "inputKind": "finger"})
        t += dt
    s.append(end(t, (0.5 + r * math.cos(a), 0.5 + r * math.sin(a) * 0.85), 0))
    return fixture("spiral", 2404, s, 10.0, expect_curl=3.2)


def build_two_fingers():
    s = [begin(0.40, (0.30, 0.30), 0), begin(0.40, (0.70, 0.70), 1)]
    s += line(0.40, 1.20, (0.30, 0.30), (0.70, 0.30), 0)     # finger 0 sweeps right
    s += line(0.40, 1.20, (0.70, 0.70), (0.30, 0.70), 1)     # finger 1 sweeps left
    s += [end(1.62, (0.70, 0.30), 0), end(1.62, (0.30, 0.70), 1)]
    return fixture("two-fingers", 2405, s, 10.0)


def build_crossing():
    s = [begin(0.40, (0.25, 0.30), 0), begin(0.40, (0.25, 0.70), 1)]
    s += line(0.40, 1.10, (0.25, 0.30), (0.75, 0.70), 0)     # 0 crossing down
    s += line(0.40, 1.10, (0.25, 0.70), (0.75, 0.30), 1)     # 1 crossing up
    s += [end(1.52, (0.75, 0.70), 0)]
    # finger 1 is cancelled mid-path for ghost-touch validation
    s.append({"touchID": 1, "phase": "cancelled", "time": round(1.52, 6),
              "x": 0.75, "y": 0.30, "inputKind": "finger"})
    return fixture("crossing", 2406, s, 10.0)


def build_four_fingers():
    """Extra-logic fixture: four fingers with staggered begin/end."""
    s = []
    starts = [(0.35, 0.25), (0.65, 0.25), (0.65, 0.75), (0.35, 0.75)]
    for i in range(4):
        t0 = 0.30 + 0.10 * i
        p0 = starts[i]
        p1 = ((1.0 - p0[0]), (1.0 - p0[1]))
        s.append(begin(t0, p0, i))
        s += line(t0, 0.8, p0, p1, i)
        s += [end(t0 + 0.82, p1, i)]
    return fixture("four-fingers", 2407, s, 10.0)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, doc in [("tap", build_tap()),
                      ("slow-stroke", build_slow_stroke()),
                      ("fast-swipe", build_fast_swipe()),
                      ("spiral", build_spiral()),
                      ("two-fingers", build_two_fingers()),
                      ("crossing", build_crossing()),
                      ("four-fingers", build_four_fingers())]:
        path = OUT / f"{name}.json"
        with open(path, "w", encoding="utf-8") as f:
            json.dump(doc, f, indent=1)
            f.write("\n")
        print(f"wrote {path.name} ({len(doc['samples'])} samples)")


if __name__ == "__main__":
    main()