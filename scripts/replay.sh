#!/usr/bin/env bash
# Deterministic gesture-replay run on a simulator: builds, installs, launches
# the app with fixture CLI args, then fetches the offscreen PNG captures.
#
# Usage:
#   SIM_UDID="<udid>" ./scripts/replay.sh spiral
#   SIM_UDID="<udid>" ./scripts/replay.sh two-fingers --flow-capture-at 0.6,2
set -o pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p artifacts/logs artifacts/captures

SIM_UDID="${SIM_UDID:?set SIM_UDID to an available simulator UDID}"
FIX="${1:?usage: replay.sh <fixture> [extra-args]}"
shift
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="artifacts/logs/replay-${FIX}-${STAMP}.log"

if [ ! -f "Tests/Fixtures/${FIX}.json" ]; then
  echo "BLOCKED: fixtures/${FIX}.json not found; run scripts/generate-fixtures.py" >&2
  exit 3
fi

BUNDLE="dev.luminousink.prototype01"
APP="artifacts/DerivedData/Build/Products/Debug-iphonesimulator/Flow.app"

echo "=== boot simulator (if needed) ==="
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$SIM_UDID" -b >> "$LOG" 2>&1

echo "=== build ==="
./scripts/build.sh || { echo "build failed" >&2; exit 4; }

echo "=== terminate stale app, install & launch ==="
xcrun simctl terminate "$SIM_UDID" "$BUNDLE" 2>/dev/null || true
sleep 0.7
# A running app can make `install` silently keep the old binary → uninstall first.
xcrun simctl uninstall "$SIM_UDID" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$SIM_UDID" "$APP" >> "$LOG" 2>&1 || { echo "install failed" >&2; exit 5; }

# Verify the installed binary really is the one we just built (mtime+size check)
INST="$(xcrun simctl get_app_container "$SIM_UDID" "$BUNDLE" app 2>/dev/null)"
if [ -n "$INST" ]; then
  A=$(stat -f '%z' "$APP/Flow" 2>/dev/null || echo x)
  B=$(stat -f '%z' "$INST/Flow" 2>/dev/null || echo y)
  if [ "$A" != "$B" ]; then
    echo "WARN: installed binary size ($B) != built ($A); captures may be stale" >&2
  fi
fi

xcrun simctl launch "$SIM_UDID" "$BUNDLE" \
  --flow-replay "$FIX" \
  --flow-seed 2401 \
  --flow-fixed-dt 0.0083333333 \
  --flow-capture-at "${CAPTURE_AT:-0.5,1,0}" \
  "$@" >> "$LOG" 2>&1

echo "=== wait for replay + captures (default 20s; override REPLAY_WAIT) ==="
sleep "${REPLAY_WAIT:-22}"

CAPDIR="artifacts/captures/${FIX}"
rm -rf "$CAPDIR"; mkdir -p "$CAPDIR"
# fetch only this run's PNGs from the app sandbox
CONTAINER="$(xcrun simctl get_app_container "$SIM_UDID" "$BUNDLE" data 2>/dev/null)"
if [ -n "$CONTAINER" ]; then
  for f in "$CONTAINER"/Documents/captures/"${FIX}_"*.png; do
    [ -e "$f" ] && mv "$f" "$CAPDIR/"
  done
  echo "captures → $CAPDIR"
  ls -la "$CAPDIR" 2>/dev/null
else
  echo "WARN: no container found; captures may be missing. log=$LOG" >&2
fi

echo "replay done. exit=$? log=$LOG"