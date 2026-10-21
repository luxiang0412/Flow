#!/usr/bin/env bash
# Produce a CRISP review video from deterministic native-resolution captures.
#
# The Simulator's recordVideo bitrate is far too low for smooth gradient art
# (measured 402 kbps for a 1206x2622 tap clip), which makes the art look blurry.
# Instead we dump frames from the renderer (--flow-dump-frames, deterministic in
# simulation time) and encode them ourselves at a high bitrate.
#
# NOTE (§6.4): this is Metal output from the Simulator — real render, but NOT a
# real-device recording. Files are prefixed `sim-`.
#
# Usage: SIM_UDID="<udid>" ./scripts/make-video.sh <fixture> [fps] [Mbps] [seconds]
set -o pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p artifacts/video artifacts/logs

SIM_UDID="${SIM_UDID:?set SIM_UDID}"
FIX="${1:?usage: make-video.sh <fixture> [fps] [Mbps] [seconds]}"
FPS="${2:-24}"
MBPS="${3:-20}"
SECS="${4:-13}"
BUNDLE="dev.luminousink.prototype01"
APP="artifacts/DerivedData/Build/Products/Debug-iphonesimulator/Flow.app"
OUT="artifacts/video/hq-sim-${FIX}.mp4"
STAGE="/tmp/flow-frames-${FIX}"

./scripts/build.sh >/dev/null || { echo "build failed" >&2; exit 4; }
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$SIM_UDID" -b >/dev/null 2>&1
xcrun simctl terminate "$SIM_UDID" "$BUNDLE" 2>/dev/null || true
xcrun simctl uninstall "$SIM_UDID" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$SIM_UDID" "$APP" || exit 5

rm -rf "$STAGE"; mkdir -p "$STAGE"
xcrun simctl launch "$SIM_UDID" "$BUNDLE" \
  --flow-replay "$FIX" --flow-seed 2401 --flow-dump-frames "$FPS" >/dev/null
sleep "$SECS"
xcrun simctl terminate "$SIM_UDID" "$BUNDLE" 2>/dev/null || true

C="$(xcrun simctl get_app_container "$SIM_UDID" "$BUNDLE" data 2>/dev/null)"
if [ -z "$C" ] || [ ! -d "$C/Documents/captures/frames/$FIX" ]; then
  echo "no frames dumped (see docs/KNOWN-ISSUES.md)" >&2; exit 6
fi
cp "$C/Documents/captures/frames/$FIX"/*.png "$STAGE/" 2>/dev/null
N=$(ls "$STAGE"/*.png 2>/dev/null | wc -l | tr -d ' ')
echo "frames: $N"
[ "$N" -ge 10 ] || { echo "too few frames: $N" >&2; exit 7; }

swift scripts/encode-frames.swift "$STAGE" "$FPS" "$OUT" "$MBPS" || exit 8
rm -rf "$STAGE"
ls -la "$OUT"