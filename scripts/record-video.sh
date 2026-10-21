#!/usr/bin/env bash
# Record a simulator screen video of a deterministic fixture replay.
#
# NOTE (§6.4): simulator video is NOT a substitute for real-device footage.
# Files are labelled `sim-` on purpose.
#
# Usage: SIM_UDID="<udid>" ./scripts/record-video.sh spiral [seconds]
set -o pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p artifacts/video docs/screenshots/review

SIM_UDID="${SIM_UDID:?set SIM_UDID}"
FIX="${1:?usage: record-video.sh <fixture> [seconds]}"
SECS="${2:-14}"
BUNDLE="dev.luminousink.prototype01"
APP="artifacts/DerivedData/Build/Products/Debug-iphonesimulator/Flow.app"
OUT="artifacts/video/sim-${FIX}.mp4"

./scripts/build.sh >/dev/null || { echo "build failed" >&2; exit 4; }
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$SIM_UDID" -b >/dev/null 2>&1
xcrun simctl terminate "$SIM_UDID" "$BUNDLE" 2>/dev/null || true
xcrun simctl uninstall "$SIM_UDID" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$SIM_UDID" "$APP" || exit 5

# Replay without auto-captures so we watch motion, not measurement.
xcrun simctl launch "$SIM_UDID" "$BUNDLE" --flow-replay "$FIX" --flow-seed 2401 >/dev/null
sleep 0.5

rm -f "$OUT"
xcrun simctl io "$SIM_UDID" recordVideo --codec=h264 --force "$OUT" >/dev/null 2>&1 &
REC=$!
sleep "$SECS"
kill -INT "$REC" 2>/dev/null || true
wait "$REC" 2>/dev/null || true
xcrun simctl terminate "$SIM_UDID" "$BUNDLE" 2>/dev/null || true

if [ -f "$OUT" ]; then
  echo "recorded $OUT ($(stat -f '%z' "$OUT") bytes)"
else
  echo "WARN: no video produced" >&2
  exit 6
fi
