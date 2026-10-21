#!/usr/bin/env bash
# Capture a REAL-DEVICE render video (native frames dumped by the iPad's GPU).
#
# Contract §6.4 forbids presenting Simulator footage as device evidence. This
# script produces frames on the physical device via --flow-dump-frames and
# encodes them at high bitrate, so the mp4 is real-device render output (it is
# a render capture, not a screen recording — stated explicitly in the docs).
#
# Usage: ./scripts/device-video.sh <fixture> [fps] [Mbps] [seconds]
set -o pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p artifacts/video artifacts/logs

FIX="${1:?usage: device-video.sh <fixture> [fps] [Mbps] [seconds]}"
FPS="${2:-24}"
MBPS="${3:-20}"
SECS="${4:-14}"
BUNDLE="dev.luminousink.prototype01"
APP="artifacts/DerivedData/Build/Products/Debug-iphoneos/Flow.app"
STAGE="/tmp/dev-frames-${FIX}"
OUT="artifacts/video/device-${FIX}.mp4"

TEAM="$(security find-certificate -c 'Apple Development' -p 2>/dev/null \
  | openssl x509 -noout -subject 2>/dev/null | tr ',' '\n' | sed -n 's/.*OU *= *//p' | head -1)"
[ -n "$TEAM" ] || { echo "no Apple Development certificate" >&2; exit 2; }

DEV="$(xcrun devicectl list devices 2>/dev/null | awk '$NF=="physical"' \
  | grep -oE '[0-9A-F]{8}(-[0-9A-F]+)+' | head -1)"
[ -n "$DEV" ] || { echo "no physical device connected" >&2; exit 3; }
echo "device=$DEV team=$TEAM"

xcodebuild -project Flow.xcodeproj -scheme Flow -configuration Debug \
  -destination "platform=iOS,id=${DEV}" -derivedDataPath artifacts/DerivedData \
  -allowProvisioningUpdates DEVELOPMENT_TEAM="$TEAM" \
  CODE_SIGNING_ALLOWED=YES build > "artifacts/logs/device-video-build.log" 2>&1 \
  || { echo "build failed (artifacts/logs/device-video-build.log)" >&2; exit 4; }

xcrun devicectl device install app --device "$DEV" "$APP" >/dev/null 2>&1 || exit 5

rm -rf "$STAGE"; mkdir -p "$STAGE"
(timeout $((SECS + 6)) xcrun devicectl device process launch --device "$DEV" --console \
   "$BUNDLE" --flow-replay "$FIX" --flow-dump-frames "$FPS" \
   > "artifacts/logs/device-video-${FIX}.log" 2>&1) || true

xcrun devicectl device copy from --device "$DEV" \
  --domain-type appDataContainer --domain-identifier "$BUNDLE" \
  --source "Documents/captures/frames/${FIX}" \
  --destination "$STAGE" >/dev/null 2>&1 || true

N=$(ls "$STAGE"/*.png 2>/dev/null | wc -l | tr -d ' ')
echo "frames: $N"
[ "$N" -ge 10 ] || { echo "too few frames — check artifacts/logs/device-video-${FIX}.log" >&2; exit 6; }

swift scripts/encode-frames.swift "$STAGE" "$FPS" "$OUT" "$MBPS" || exit 7
rm -rf "$STAGE"
ls -la "$OUT"