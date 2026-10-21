#!/usr/bin/env bash
# Build Flow for a simulator, saving the complete log + exit code.
# Usage: SIM_UDID="<udid>" ./scripts/build.sh [--device]
set -o pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p artifacts/logs artifacts/xcresult

SIM_UDID="${SIM_UDID:?set SIM_UDID to an available simulator UDID (see scripts/test.sh)}"
MODE="${1:---simulator}"
STAMP="$(date +%Y%m%d-%H%M%S)"

if [ ! -x "$(command -v xcodebuild)" ]; then
  echo "BLOCKED: no usable xcodebuild (see docs/ENVIRONMENT.md)" >&2
  exit 3
fi

if [ "$MODE" = "--device" ]; then
  DEVICE_ID="${DEVICE_ID:?set DEVICE_ID for real-device build}"
  LOG="artifacts/logs/build-device-${STAMP}.log"
  xcodebuild -project Flow.xcodeproj -scheme Flow \
    -configuration Debug -destination "platform=iOS,id=${DEVICE_ID}" \
    build > "$LOG" 2>&1
  RC=$?
else
  LOG="artifacts/logs/build-simulator-${STAMP}.log"
  xcodebuild -project Flow.xcodeproj -scheme Flow \
    -configuration Debug -destination "platform=iOS Simulator,id=${SIM_UDID}" \
    -derivedDataPath artifacts/DerivedData CODE_SIGNING_ALLOWED=NO \
    build > "$LOG" 2>&1
  RC=$?
fi

echo "exit=$RC log=$LOG"
# compact status line for the report (full log preserved)
tail -5 "$LOG" | grep -E "BUILD|error:" || true
exit "$RC"