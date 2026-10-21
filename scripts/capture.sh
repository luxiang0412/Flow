#!/usr/bin/env bash
# Fetch current Debug-capture + UI-screenshot evidence from a simulator.
# Usage: SIM_UDID="<udid>" ./scripts/capture.sh [fixture-name]
set -o pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p artifacts/captures

SIM_UDID="${SIM_UDID:?set SIM_UDID to an available simulator UDID}"
TAG="${1:-screen}"
BUNDLE="dev.luminousink.prototype01"

echo "=== GUI screenshot (UI layout, not replay-precise) ==="
xcrun simctl io "$SIM_UDID" screenshot "artifacts/captures/${TAG}-screen.png" && echo "saved artifacts/captures/${TAG}-screen.png"

echo "=== app offscreen captures ==="
CONTAINER="$(xcrun simctl get_app_container "$SIM_UDID" "$BUNDLE" data 2>/dev/null)"
if [ -n "$CONTAINER" ] && [ -d "$CONTAINER/Documents/captures" ]; then
  cp -R "$CONTAINER/Documents/captures/." "artifacts/captures/${TAG}/" 2>/dev/null
  echo "saved → artifacts/captures/${TAG}/"
  (cd "$CONTAINER/Documents/captures" && sha256sum *.png 2>/dev/null) | tee "artifacts/captures/${TAG}.sha256" || true
else
  echo "WARN: no offscreen captures found (run a replay first)" >&2
fi