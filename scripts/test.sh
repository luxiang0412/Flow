#!/usr/bin/env bash
# Run Flow unit + UI tests on a simulator; full log + xcresult + exit code.
# Usage: SIM_UDID="<udid>" ./scripts/test.sh [--only-unit|--skip-ui]
set -o pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p artifacts/logs artifacts/xcresult

SIM_UDID="${SIM_UDID:?set SIM_UDID to an available simulator UDID}"
STAMP="$(date +%Y%m%d-%H%M%S)"
RESULT="artifacts/xcresult/Flow-${STAMP}.xcresult"
LOG="artifacts/logs/test-simulator-${STAMP}.log"

ONLY="${1:-}"

libs=()
[ "$ONLY" = "--only-unit" ] && libs+=( -only-testing:FlowTests )
[ "$ONLY" = "--skip-ui" ]  && libs+=( -skip-testing:FlowUITests )

xcodebuild -project Flow.xcodeproj -scheme Flow \
  -configuration Debug -destination "platform=iOS Simulator,id=${SIM_UDID}" \
  -derivedDataPath artifacts/DerivedData CODE_SIGNING_ALLOWED=NO \
  -resultBundlePath "$RESULT" \
  "${libs[@]}" \
  test > "$LOG" 2>&1
RC=$?
echo "exit=$RC log=$LOG result=$RESULT"
grep -E "Test Suite|Test Case.*(passed|failed)|TEST|error:" "$LOG" | tail -20
exit "$RC"