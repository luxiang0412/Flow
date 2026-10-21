# Flow — Luminous Ink (Prototype 01)

**原生 Metal 触控流动艺术原型**。轻触绽放柔和墨迹，拖动牵引速度场，画圈形成漩涡；
多指通过同一流场互相影响，抬手后墨迹持续流动衰减。

Engineering contract: [FLOW-PROTOTYPE-01.md](FLOW-PROTOTYPE-01.md).
Status tracking: [docs/PROGRESS.md](docs/PROGRESS.md).

> **状态**：源码/工程配置/脚本/文档已就绪；**完整 Xcode 尚未安装**，所有 build/test/
> Replay/截图证据目前为 `BLOCKED`（见 `docs/ENVIRONMENT.md`）。本机无真实 iPhone/iPad。

## 目录

```text
project.yml              # XcodeGen 规范（唯一工程事实源）
FlowApp/                 # App 源码（App/UI/Input/Simulation/Rendering/Shaders/...）
FlowTests/               # Swift Testing 单元测试
FlowUITests/             # XCUITest
Tests/Fixtures/*.json    # 六组标准手势 fixture（+ four-fingers 逻辑测试）
scripts/                 # env/build/test/replay/capture/report + generate-fixtures.py
docs/                    # 环境、进度、视觉、测试、性能、已知问题、决策
```

## 要求

- macOS（完整 **Xcode 27.1**，非 Command Line Tools）+ iOS 18 Simulator Runtime
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) ≥ 2.46（`brew install xcodegen`）
- 真机验证需要一台 iPhone 与一台 iPad（P5/P6 门槛）

## 从干净目录运行

```bash
# 0. 环境核验（写入 docs/ENVIRONMENT.md）
./scripts/env.sh

# 1. 生成工程（不提交 .xcodeproj，CI 同样生成）
xcodegen generate --spec project.yml
xcodebuild -list -project Flow.xcodeproj

# 2. 选择一台可用模拟器
xcrun simctl list devices available
export SIM_UDID="<udid>"

# 3. 构建 + 测试（保留完整日志与 xcresult）
./scripts/build.sh
./scripts/test.sh

# 4. 确定性 Replay（自动收集 offscreen PNG）：
./scripts/replay.sh spiral
./scripts/replay.sh tap          # 等等；产物在 artifacts/captures/<fixture>/

# 5. GUI 截图与 offscreen 抓取
./scripts/capture.sh spiral

# 6. 宿主 CPU 层冒烟测试（无 Xcode 也可真实运行）
./scripts/host-smoke.sh          # 102 项检查（时钟/归一化/去重/流体数学/fixture 确定性）

# 7. 生成测试报告骨架
./scripts/report.sh
```

也可直接在 Xcode 中打开 `Flow.xcodeproj` → Scheme `Flow` → Run。

## Debug CLI（Replay 模式，§6.1）

```text
--flow-replay <fixture>      tap | slow-stroke | fast-swipe | spiral | two-fingers | crossing
--flow-seed <int>            固定噪声种子（缺省 2401）
--flow-fixed-dt <sec>        固定物理步长（推荐 0.0083333333）
--flow-capture-at a,b,c      在指定模拟秒抓取离屏帧
--flow-disable-bloom
--flow-disable-detail
```

产物示例：`artifacts/captures/spiral/spiral_10.50.png`（模拟时刻，附加 SHA-256）。

## 架构速览

- **SwiftUI 壳**（`ContentView`/`DebugOverlay`）仅承载控件；慢速轮询指标（≈2 Hz）。
- **`FlowMetalView`**（UIKit/MTKView）：采集 multi-touch + coalesced + Pencil ⇒ 归一化 `TouchSample`。
- **`InputNormalizer`**：重采样、去重、速度估计（上限）、按半径 0.4× 自适应插值。
- **`SimulationClock`**：固定步长累加器，暂停/恢复/过载保护（每帧 0–3 步）。
- **`FlowRenderer`**：7 个 compute pass（advect → inject → damp…，A/B 双缓冲），+ composite/Bloom/最终合成。
- **`ReplayEngine`**：固定种子 + 固定 dt 重放，驱动与真机相同的法线化输入路径。
- **`TestCapture`**：独立离屏渲染 → 共享缓冲回读 → PNG（带 sRGB 色彩管理）。

Determinism（§5.5）：注入 kernel 按“每 texel 串行遍历按 (timestamp, touchID) 排序的事件”，
无原子、无读改写竞争；噪声使用固定 seed。Swift/Metal 结构布局在运行时断言一致。

## 测试

- `FlowTests`：坐标/插值/去重/速度上限/时钟/暂停/Replay 稳定序/受限注入/尺寸派生/纹理格式/离屏 PNG。
- `FlowUITests`：启动、Debug 控件可访问性、fixture 菜单、CLI Replay 启动、截图附件。
- 真机 & 多指精确轨迹：以 Replay Engine 注入模拟层验证 + **真机人工核验**（当前 `BLOCKED`）。

## 真机运行（需要一次性配置）

```bash
./scripts/device.sh --list                      # 看是否有真机 + 是否有签名身份
FLOW_DEV_TEAM=ABCDE12345 ./scripts/device.sh    # 构建 → 安装 → 启动
FLOW_DEV_TEAM=ABCDE12345 ./scripts/device.sh --perf 60   # 顺带采集 60s 真机性能日志
```

一次性配置（在 Xcode 里做）：
1. `Xcode → Settings…`（⌘,）→ **Accounts** → 左下 `+` → **Apple ID** 登录（免费 ID 即可）
2. 打开 `Flow.xcodeproj` → 左上选 **TARGETS 下的 `Flow`**（不是 PROJECTS 的）
   → 顶部 **`Signing & Capabilities`** → 勾 `Automatically manage signing` → 选你的 Team
3. 设备上：`设置 → 隐私与安全性 → 开发者模式` 打开；插线后点「信任此电脑」
4. Team ID（10 位）在 `Signing & Capabilities` 里能看到，或 `./scripts/device.sh --list`

> 注意：工程由 `project.yml` 生成，手改 Xcode 签名会被下次 `xcodegen generate` 覆盖。
> 因此签名通过 `FLOW_DEV_TEAM` 环境变量注入（`project.yml` 里 `DEVELOPMENT_TEAM: ${FLOW_DEV_TEAM}`）。

## 已知环境状态

| 项 | 状态 |
|---|---|
| 完整 Xcode 27.1 + iOS 18 SDK | **缺失 → BLOCKED** |
| iOS Simulator | **不可用**（无 simctl） |
| 真机 iPhone/iPad/Pencil | **BLOCKED** |
| XcodeGen 2.46.0 / xcodes 2.1.0 | ✅ 已装 |

安装完整 Xcode：`xcodes install 27.1`（需 Apple ID）或 App Store，然后
`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`。