#!/usr/bin/env bash
# Environment probe → docs/ENVIRONMENT.md  (spec §2.2 / §7)
set -o pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p docs artifacts/logs

probe() {
  echo "### $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  for c in \
    "sw_vers" "uname -m" "xcode-select -p" "xcodebuild -version" \
    "xcrun swift --version" "xcrun simctl list runtimes" \
    "xcrun simctl list devices available" "xcrun xcodebuild -showsdks" \
    "command -v xcodegen || true" "xcodegen --version" \
    "command -v xcrun || true"; do
    echo "\$ $c"
    eval "$c" 2>&1 | sed 's/^/  | /'
    echo "  [exit=$?]"
    echo
  done
}

{
  echo "# ENVIRONMENT — Flow Prototype 01 (regenerated '$0')"
  echo
  echo '> Regeneration overwrites a previously saved snapshot. Keep the record'
  echo '> that matches any reported build/test results.'
  echo
  probe
} > docs/ENVIRONMENT.md

echo "wrote docs/ENVIRONMENT.md"
grep -q "Xcode.app" docs/ENVIRONMENT.md && echo "NOTE: check Xcode presence / xcode-select"
exit 0