#!/usr/bin/env bash
# One-command verification of everything reachable without a physical device.
#
#   SIM_UDID="<udid>" ./scripts/verify-all.sh
#
# Runs: regenerate → build → unit+UI tests → 6 fixture replays → host smoke
#       → test report. Every step keeps its full log and exit code; the script
#       stops at the first failure and prints the log path.
#
# Device-only gates (real FPS/Pencil/long-run) are NOT covered — see docs/PROGRESS.md.
set -o pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p artifacts/logs

SIM_UDID="${SIM_UDID:?set SIM_UDID to an available simulator UDID}"
SUMMARY="artifacts/logs/verify-all-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee "$SUMMARY") 2>&1

step() { echo; echo "===================== $* ====================="; }
fail() { echo "FAILED: $* (full log: $SUMMARY)"; exit 1; }

step "0. environment"
xcodebuild -version || fail "xcodebuild"
xcodegen --version || fail "xcodegen"
xcrun simctl list devices available | grep -c "$SIM_UDID" >/dev/null || fail "simulator $SIM_UDID not available"

step "1. regenerate project"
xcodegen generate --spec project.yml || fail "xcodegen generate"
xcodebuild -list -project Flow.xcodeproj || fail "xcodebuild -list"

step "2. build"
./scripts/build.sh || fail "build"

step "3. unit + UI tests"
./scripts/test.sh || fail "tests"

step "4. deterministic replays (6 fixtures)"
for fx in tap slow-stroke fast-swipe spiral two-fingers crossing; do
  echo "--- replay $fx"
  ./scripts/replay.sh "$fx" >/dev/null || fail "replay $fx"
done

step "5. host smoke (CPU core)"
./scripts/host-smoke.sh || fail "host smoke"

step "6. report"
./scripts/report.sh

step "DONE"
echo "verify-all: PASS (device gates still BLOCKED — see docs/PROGRESS.md)"
echo "summary: $SUMMARY"