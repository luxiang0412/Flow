#!/usr/bin/env bash
# Build / install / launch on a REAL device and collect measured performance.
#
# Prerequisites (one-time, done by the user in Xcode):
#   1. Xcode → Settings… → Accounts → + → Apple ID (sign in)
#   2. Select target Flow → Signing & Capabilities → tick "Automatically manage
#      signing" → choose your Personal Team
#   3. On the device: Settings → Privacy & Security → Developer Mode → ON,
#      then trust the computer and tap "Trust" when prompted.
#
# Usage:
#   FLOW_DEV_TEAM=ABCDE12345 ./scripts/device.sh            # build + install + launch
#   FLOW_DEV_TEAM=ABCDE12345 ./scripts/device.sh --perf 60  # + 60s of perf logging
#   ./scripts/device.sh --list                              # show connected devices
set -o pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p artifacts/logs

BUNDLE="dev.luminousink.prototype01"

if [ "$1" = "--list" ]; then
  echo "=== connected devices (Reality must NOT be 'simulated') ==="
  xcrun devicectl list devices 2>&1
  echo
  echo "=== signing identities ==="
  security find-identity -v -p codesigning 2>&1 | tail -5
  echo
  echo "=== detected Development Team (cert OU) ==="
  security find-certificate -c "Apple Development" -p 2>/dev/null \
    | openssl x509 -noout -subject 2>/dev/null | tr ',' '\n' | sed -n 's/.*OU *= */  /p' | head -1
  exit 0
fi

PERF_SECONDS=0
if [ "$1" = "--perf" ]; then PERF_SECONDS="${2:-60}"; fi

# Resolve the team. IMPORTANT: the value in an "Apple Development: … (XXXXXXXXXX)"
# certificate name is NOT reliably the team id — the authoritative value is the
# certificate subject's OU field (and the provisioning profile's TeamIdentifier).
detect_team() {
  security find-certificate -c "Apple Development" -p 2>/dev/null \
    | openssl x509 -noout -subject 2>/dev/null \
    | tr ',' '\n' | sed -n 's/.*OU *= *//p' | head -1
}
TEAM="${FLOW_DEV_TEAM:-}"
if [ -z "$TEAM" ]; then TEAM="$(detect_team)"; fi
if [ -z "$TEAM" ]; then
  echo "ERROR: no Apple Development certificate found. Sign in via Xcode →" >&2
  echo "       Settings… → Accounts, then select your Team in Signing & Capabilities." >&2
  exit 2
fi
echo "team: $TEAM"

# --- find a physical device ---
DEV_ID=""
DEV_NAME=""
while IFS= read -r line; do
  case "$line" in
    *simulated*) continue ;;
  esac
  # iOS device UDIDs come in two dash formats:
  #   legacy   8-4-4-4-12   (e.g. <SIM_UDID_IPHONE>)
  #   current  8-8-8        (e.g. <DEVICE_UDID>)
  id=$(echo "$line" | grep -oE '[0-9A-F]{8}(-[0-9A-F]+)+' | head -1)
  if [ -n "$id" ]; then
    DEV_ID="$id"
    DEV_NAME=$(echo "$line" | awk '{print $1, $2, $3}')
    break
  fi
done < <(xcrun devicectl list devices 2>/dev/null)

if [ -z "$DEV_ID" ]; then
  echo "BLOCKED: no physical device connected (only simulators found)." >&2
  echo "         Connect an iPhone/iPad by cable, unlock it, and trust this computer." >&2
  xcrun devicectl list devices 2>&1 | sed 's/^/  /' >&2
  exit 3
fi
echo "device: $DEV_NAME ($DEV_ID)"

if ! security find-identity -v -p codesigning 2>/dev/null | grep -q "valid identities found"; then
  echo "BLOCKED: no code-signing identity. Log in with your Apple ID in Xcode first." >&2
  exit 4
fi
if security find-identity -v -p codesigning 2>/dev/null | grep -q "0 valid identities"; then
  echo "BLOCKED: 0 valid signing identities — see the prerequisites at the top of this script." >&2
  exit 4
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="artifacts/logs/build-device-${STAMP}.log"

echo "=== build for device (team $TEAM) ==="
FLOW_DEV_TEAM="$TEAM" xcodegen generate --spec project.yml || exit 5
set +e
xcodebuild -project Flow.xcodeproj -scheme Flow \
  -configuration Debug \
  -destination "platform=iOS,id=${DEV_ID}" \
  -derivedDataPath artifacts/DerivedData \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM" \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=YES \
  build > "$LOG" 2>&1
RC=$?
set -e
echo "exit=$RC log=$LOG"
if [ "$RC" != "0" ]; then
  echo "BUILD FAILED — most common causes:" >&2
  echo "  * Personal Team can't sign ‘dev.luminousink.prototype01’ → change PRODUCT_BUNDLE_IDENTIFIER in project.yml" >&2
  echo "  * device not trusted / Developer Mode off" >&2
  grep -E "error:" "$LOG" | head -10 >&2
  exit "$RC"
fi

APP="artifacts/DerivedData/Build/Products/Debug-iphoneos/Flow.app"
[ -d "$APP" ] || { echo "ERROR: $APP missing" >&2; exit 6; }

echo "=== install + launch ==="
xcrun devicectl device install app --device "$DEV_ID" "$APP" 2>&1 | tail -3
xcrun devicectl device process launch --device "$DEV_ID" \
  --console \
  "$BUNDLE" --flow-replay spiral --flow-metrics-log 2>&1 | tail -5 &

if [ "$PERF_SECONDS" != "0" ]; then
  echo "=== collecting device perf for ${PERF_SECONDS}s ==="
  sleep "$PERF_SECONDS"
  echo "(device perf is also visible in Xcode → Window → Devices and Simulators → Console)"
fi

echo
echo "NOTE: real-device numbers must be recorded in docs/PERFORMANCE.md, and device"
echo "      video (not Simulator) is required by contract §6.4."