#!/usr/bin/env bash
# Host-level smoke test for the pure CPU core (runs without Xcode/iOS SDK).
# Real runtime evidence for deterministic logic; NOT a substitute for the
# iOS build/test gates (see docs/PROGRESS.md).
set -o pipefail
cd "$(dirname "$0")/.." || exit 1
mkdir -p artifacts/logs
LOG="artifacts/logs/host-smoke-$(date +%Y%m%d-%H%M%S).log"

xcrun swiftc -swift-version 6 \
  FlowApp/Simulation/SimulationConfig.swift \
  FlowApp/Simulation/SimulationClock.swift \
  FlowApp/Simulation/FluidMath.swift \
  FlowApp/Simulation/ReplayEngine.swift \
  FlowApp/Input/TouchSample.swift \
  FlowApp/Input/InputNormalizer.swift \
  FlowApp/Diagnostics/FrameMetrics.swift \
  FlowApp/Diagnostics/ErrorStatus.swift \
  FlowApp/Rendering/ShaderBridge.swift \
  HostSmoke/main.swift \
  -o /tmp/flow-host-smoke 2>&1 | tee "$LOG"
RC=$?
if [ "$RC" != "0" ]; then
  echo "compile failed (exit=$RC) log=$LOG" >&2
  exit "$RC"
fi
echo "=== running host smoke ===" >> "$LOG"
/tmp/flow-host-smoke -p true 2>&1 | tee -a "$LOG"
RC=${PIPESTATUS[0]}
echo "host-smoke exit=$RC log=$LOG"
exit "$RC"