#!/usr/bin/env bash
# Clean regenerable build output while keeping the evidence the docs point at.
#
#   ./scripts/clean.sh            # default: drop caches + bulk captures/logs
#   ./scripts/clean.sh --all      # also remove retained evidence (videos, logs, captures)
#   ./scripts/clean.sh --dry-run  # only report what would be removed
#
# Never touches git-tracked files: docs/screenshots/review/* is committed, so the
# review material survives regardless.
set -o pipefail
cd "$(dirname "$0")/.." || exit 1

MODE="default"
case "${1:-}" in
  --all) MODE="all" ;;
  --dry-run) MODE="dry" ;;
esac

# Kept in the default mode: real-device evidence referenced by the docs.
KEEP_CAPTURES=(device-ipad ipad ipad-portrait.png)
KEEP_LOGS=(
  device-10min.log
  device-console.log
  perf-simulator-iphone.log
  perf-simulator-ipad.log
  verify-all-20261021-025511.log
)
KEEP_VIDEO_PREFIX="device-"

before=$(du -sh . | cut -f1)
echo "artifacts before: $(du -sh artifacts 2>/dev/null | cut -f1)"

remove() {  # remove <path>
  [ -e "$1" ] || return 0
  if [ "$MODE" = "dry" ]; then
    printf '  would remove %-52s %s\n' "$1" "$(du -sh "$1" 2>/dev/null | cut -f1)"
  else
    rm -rf "$1"
  fi
}

echo "== build caches =="
remove artifacts/DerivedData
remove artifacts/xcresult
remove .build
remove ci

echo "== captures =="
if [ "$MODE" = "all" ]; then
  for d in artifacts/captures/*; do remove "$d"; done
else
  for d in artifacts/captures/*; do
    b=$(basename "$d")
    keep=0
    for k in "${KEEP_CAPTURES[@]}"; do [ "$b" = "$k" ] && keep=1; done
    [ "$keep" = "1" ] || remove "$d"
  done
fi

echo "== logs =="
if [ "$MODE" = "all" ]; then
  for f in artifacts/logs/*; do remove "$f"; done
else
  for f in artifacts/logs/*; do
    b=$(basename "$f")
    keep=0
    for k in "${KEEP_LOGS[@]}"; do [ "$b" = "$k" ] && keep=1; done
    [ "$keep" = "1" ] || remove "$f"
  done
fi

echo "== video =="
if [ "$MODE" = "all" ]; then
  for f in artifacts/video/*; do remove "$f"; done
else
  for f in artifacts/video/*; do
    case "$(basename "$f")" in
      ${KEEP_VIDEO_PREFIX}*) ;;
      *) remove "$f" ;;
    esac
  done
fi

echo "== scratch dirs =="
rm -rf /tmp/flow-frames-* /tmp/dev-frames-* /tmp/ci-art /tmp/ci2 /tmp/ci3 2>/dev/null || true

echo
echo "artifacts after:  $(du -sh artifacts 2>/dev/null | cut -f1)"
echo "project: $before -> $(du -sh . | cut -f1)"
echo "disk free: $(df -h / | awk 'NR==2{print $4}')"
[ "$MODE" = "dry" ] && echo "(dry run — nothing was deleted)" || true
