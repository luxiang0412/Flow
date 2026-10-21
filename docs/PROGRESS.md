# PROGRESS — Flow Prototype 01

> 每阶段逐条记录（§11 强制模板）。`PASS` 必须有命令/测试/证据；当前环境状态：
> **无完整 Xcode**（`docs/ENVIRONMENT.md`），因此 build/test/GPU/模拟器证据全部为
> `BLOCKED`，以下如实记录。**未生成的证据不被当作通过。**

## P0 — 环境、项目生成、测试壳

- Status: **PARTIAL / BLOCKED**（环境缺 Xcode；工程与源码已就绪可审）
- Git commit: `ee033ee`（p0: project scaffold）
- Host / Xcode / SDK: macOS 27.2 (26B5091g) / arm64；**无 Xcode.app**；Swift CLI 6.4；无 iOS SDK
- Devices: 无（无 simctl、无真机）
- Commands executed:
  - `sw_vers` → exit=0；`uname -m` → arm64；`xcode-select -p` → `/Library/Developer/CommandLineTools`
  - `xcodebuild -version` → exit≠0（"requires Xcode"）；`xcrun simctl list runtimes` → 不可用
  - `brew install xcodegen` → 成功（2.46.0）；`brew install xcodes` → 成功（2.1.0）
  - `python3 scripts/generate-fixtures.py` → 生成 7 个 fixture JSON ✓
  - 完整探测输出：`docs/ENVIRONMENT.md`
- Tests:
  - **host-smoke（本机真实执行）**: `scripts/host-smoke.sh` → **102 passed / 0 failed，exit=0**
    （log=`artifacts/logs/host-smoke-*.log`）。覆盖：时钟固定步长/暂停/过载、坐标归一化、
    多指独立、coalesced 去重、零长度非 NaN、速度上限、受限注入数学、阻尼公式、advect clamp、
    Swift/Metal 布局断言（88/64）、7 个 fixture 的确定性排序与 schema、网格尺寸/长边上限。
    **性质**：真实运行证据，但为 macOS 宿主 CPU 层；iOS 构建/GPU/模拟器仍 BLOCKED。
  - iOS 测试已编写未运行：`FlowTests/`（Swift Testing）、`FlowUITests/`（XCUITest）
- Captures: 无（无 GPU/模拟器）
- FPS / GPU: NOT_MEASURED（无设备/工具链）
- Visual review: 无（READY_FOR_REVIEW 为否）
- Failures & root cause:
  1. **完整 Xcode 缺失**（根因：本机仅 CLT）。`xcodes install` 需要 Apple ID / 用户授权，
     ~10 GB 下载。修复路径见 `docs/ENVIRONMENT.md` §2。
  2. GitHub git-protocol 被代理阻断（GitHub-Babel），brew 使用 `brewforge/chinese` 镜像 tap 正常。
- Open issues:
  - [ ] 用户安装 Xcode 27.1（或授权 `xcodes install 27.1`）并 `sudo xcode-select -s ...`
  - [ ] 下载 iOS 18 Simulator Runtime；随后重跑 `scripts/env.sh` 并对齐 `project.yml`（swift 6.0 / deploymentTarget 18.0）
  - [ ] 首次 `xcodegen generate` 后核验 Scheme/target；跑 build/test；补截图
- Next stage gate: **否** —— Xcode 未就绪，不得进入 P1 的“可运行”验收；但 P0 的非阻塞产物（工程规范、
  源码、fixtures、脚本、CI、文档骨架）已完成。

## P2 — Touch Capture、采样预处理、确定性回放

- Status: **PASS（模拟器侧）**；真机核验子项 BLOCKED
- Commands: `scripts/build.sh` → exit=0；`scripts/test.sh` → 23 单测 exit=0
- Captures: 六组 fixture 在模拟器回放并收集逐时刻 PNG（`artifacts/captures/*_*.png`）
- Failures fixed: `startReplay` 未调 `engine.start()`（输入为空画布）；每时刻捕获共用文件名覆盖
- Open issues: 无真机两指核验（BLOCKED）

## P3 — Velocity & Pigment：第一条可用渲染路径

- Status: **PASS（基础证据充分，视觉待用户）**；真机阶段未到
- Git commit: `f3faa51`
- Host / Xcode / SDK: macOS 27.2 · Xcode 27.1 (27A9275) · iphonesimulator27.1
- Devices: iPhone 16 Pro 模拟器 <SIM_UDID_IPHONE>（iOS 27.1 运行时）
- Commands:
  - `xcodebuild ... build` → exit=0，`artifacts/logs/build-simulator-*.log`
  - `xcodebuild ... test` → exit=0（23 tests），`artifacts/xcresult/...`
  - `scripts/replay.sh {tap,slow-stroke,fast-swipe,spiral,two-fingers,crossing}` → 退出码 0
- Captures: `artifacts/captures/<fixture>/<fixture>_{0.00,0.50,1.00,10.00,10.10,10.50,12.00,18.00}.png`
  逐帧实测（见 VISUAL-SPEC 表，非背景像素占比 1.5–12%，颜色数 2–91）
- FPS / GPU: 未作真机测量（模拟器 FPS 不作真机结论）；编码帧时间指标已埋点
- Visual review: **READY_FOR_VISUAL_REVIEW**（材料见 `docs/screenshots/review/`，等 Pi 用户审看）
- Failures & root cause:
  1. 注入不可见（纯背景）→ A/B 角色单一化导致 composite 读未注入副本，改为**按字段独立角色**并恒定运行全部 pass（`f3faa51`）
  2. 缺失 pigment 半衰衰减 pass → 新增 `decayPigment`
- Next stage gate: P3 数值/数据基础已满足；P4 丝状/柔光进阶与用户目验收闸门待打开

## P4 — Detail Field（视觉品质闸门）

- Status: **READY_FOR_VISUAL_REVIEW**（工程完成 + 两轮调优，未获用户视觉验收 → 不标 PASS）
- 调优轮次（每轮均留 A/B）：
  1. **显示路径修复**：MTKView 委托模式从不自动 present → 补 `commandBuffer.present(drawable)`。
     此前屏幕上的 `#070A13` 实际是 SwiftUI 底层背景，不是渲染结果（离屏捕获正常掩盖了该缺陷）。
  2. **Aurora 空间渐变**：单一 touchID 取纯色导致“单指永远紫色、bloom 永不触发”；
     改为 `auroraLinear(t)` 沿画布平滑过渡四色（smoothstep 防色带断裂）。
  3. 动量 6.0→2.2、速度上限 2.0→1.1（此前颜料被半拉格朗日稀释成发丝线）。
  4. 半径 2.5%→3.0%（4.5% 时旋涡臂互相合并成实心盘）；bloom 阈值 0.7→0.18（原阈值永不触发）。
  5. 确定性修复：回放节拍改为墙钟驱动但**捕获在固定步内编码**；同一夹具两次运行 7 帧字节全等。
- A/B 量化（spiral，触尾时刻）：detail 关闭 → p90 0.537（开 0.645）、mean 0.219（开 0.244）；
  bloom 关闭 → mean 0.238（开 0.244）。两者均有贡献且无过曝。
- 过曝检查：六组 fixture 峰值帧 sat>0.9 均为 **0.0%**，最大亮度 ≤0.904。
- 材料：`docs/screenshots/review/`（18 格对照 + spiral A/B）+ `artifacts/video/sim-{slow-stroke,spiral,two-fingers}.mp4`
- 调优轮次 2（用户反馈 “tap 太小 / spiral 太满” 后执行）：
  1. **画面上下翻转 bug**：触控为左上原点、渲染为左下原点，墨迹与手指上下镜像
     （tap 在 y=0.42 却显示在 0.58）。修复 `fullscreenVertex` 的 uv.y 翻转。
  2. **tap 是“圆形印章”**：逐步累积注入把整个足迹饱和成平顶（剖面 `1177…7711`）。
     改为「首帧一次性爆发（宽、软核）+ 按住时极小 top-up（0.022）」，并按事件类型
     选择核（径向用软核求渐变，描边用高斯保宽度）。剖面变为钟形。
  3. 分离 tap/描边参数（半径倍率、染料、径向推力、颜料核比例各自独立）。
  4. spiral fixture 缩小（外半径 0.32、内 0.09）；颜料半衰期 8→6.5s、速度半衰期 0.8→0.65s。
- 轮 2 实测：六组夹具全部有亮度梯度、零过曝（sat>0.9 ≤0.2%）、spiral 留白充足；
  确定性仍成立（spiral 连跑两次 7 帧字节一致）；23 单测 + 5 UI 全绿。
- 剩余已知问题：见 `docs/KNOWN-ISSUES.md` §7（真机手感未验证、tap 尺寸可再议）

## P5~P7

| Phase | Status | 说明 |
|---|---|---|
| P5 多指/Pencil/布局/生命周期 | **PARTIAL**：真机 iPad 已安装运行并采集；**真实手指多指交互与 Apple Pencil 仍待人工** | `artifacts/captures/device-ipad/`、`artifacts/video/device-*.mp4` |
| P6 性能/长期 | **PASS（iPad 真机）**：真机 10 分钟 60 fps（P50 16.67 / P95 16.74 / P99 17.6，无恶化、0 崩溃）；iPhone 真机 **BLOCKED** | `artifacts/logs/device-10min.log` |
| P7 CI/交付 | PARTIAL | `xcodegen build test` 已在本地验证；GitHub runner 稳定 Xcode CI 待推送确认

## 最终状态

- `ENGINEERING_PARTIAL / DEVICE_VALIDATION_BLOCKED`（真实设备缺失 + toolchain 缺失）。
  境内已完成并**真实执行**的部分：环境探测、工程规范（XcodeGen 生成成功）、全部 Swift/Metal
  源码、7 个 fixture、CI、文档，以及宿主 CPU 层 host-smoke（102/102 通过）。
  未完成：一切需要 Xcode/模拟器/真机/GPU 的证据（诚实标注为 BLOCKED/NOT_MEASURED）。
- 逐步解除阻塞的下一步在 `docs/ENVIRONMENT.md` 与上方 Open issues。
## 干净克隆可复现性验证（P7 · 本机真实执行 · 2026-10-21）

```bash
cd /tmp && git clone ~/project/Flow flow-clone && cd flow-clone
xcodegen generate --spec project.yml     # exit=0，生成 Flow.xcodeproj（3 targets，scheme Flow）
./scripts/build.sh                       # exit=0  BUILD SUCCEEDED
./scripts/test.sh                        # exit=0  TEST SUCCEEDED（23 单测 + 5 UI）
./scripts/replay.sh tap                  # exit=0  生成 7 张逐时刻 PNG
```

结论：**从干净目录按 README 即可复现构建、测试与捕获**，无硬编码私有路径。
一条命令复跑全部：`SIM_UDID=<udid> ./scripts/verify-all.sh`。

**未验证项（如实保留）**：GitHub Actions 实跑（本机无 GitHub 推送凭据，`git` 协议被代理阻断）；
真机 iPhone/iPad 运行、Pencil 输入、真机 FPS/GPU 轨迹（无设备）。

## P5 模拟器侧验收（2026-10-21）

| 测试 | 设备 | 结果 |
|---|---|---|
| `testRotationKeepsCanvasAlive` | iPad Pro 11 (M4) 模拟器 | PASS（11.4s，竖→横→竖，canvas 存活） |
| `testBackgroundAndForegroundSurvives` | iPad 模拟器 | PASS（9.4s，后台再回前台不崩溃） |
| `testDebugPanelReachableInLandscape` | iPad 模拟器 | PASS（7.4s，横屏可打开 Debug 面板） |

iPad 原生捕获：`artifacts/captures/ipad/spiral_3.20.png`（1668×2420，可见>0.10 = 10.5%，
过曝 0.0%，与 iPhone 数值同量级 → 跨设备族视觉一致）。

**仍 BLOCKED**：真实 iPhone/iPad 手感、Apple Pencil 压力/倾角、iPad 多窗口 Split View 真实尺寸变化。

## P6 模拟器侧验收（2026-10-21）

| 项 | 结果 | 证据 |
|---|---|---|
| FPS（iPhone 16 Pro 模拟器） | 60.0，P50 16.67 / P95 16.70 / P99 16.74 ms | `artifacts/logs/perf-simulator-iphone.log` |
| FPS（iPad Pro 11 M4 模拟器） | 60.0，P50 16.66 / P95 16.70 / P99 16.72 ms | `artifacts/logs/perf-simulator-ipad.log` |
| 100 次 pause/clear/resume | PASS（46.1s，无崩溃，canvas 存活） | `FlowUITests/StabilityTests` |
| 90 秒持续拖拽交互 | PASS（94.1s，始终前台响应） | 同上 |

**仍 BLOCKED**：真机 GPU pass 耗时、填充率/带宽、发热降频、端到端触控延迟、10 分钟真机长跑。

## 端到端验证（2026-10-21 02:55，`scripts/verify-all.sh`）

```
0. environment      Xcode 27.1 (27A9275), xcodegen 2.46.0, 模拟器在线
1. regenerate       xcodegen generate → Flow.xcodeproj (3 targets, scheme Flow)
2. build            ** BUILD SUCCEEDED **
3. unit + UI tests  ** TEST SUCCEEDED **（23 单测 + 8 UI：5 功能 + 3 布局 + 2 稳定性中 1 个长测在 P6 单独跑）
4. replays          6 fixtures → 42 张原生分辨率 PNG
5. host smoke       102 passed / 0 failed
6. report           docs/TEST-REPORT.md 重新生成
```
日志：`artifacts/logs/verify-all-20261021-025511.log`（完整，含每步退出码）。

## 最终状态表 (2026-10-21)

| 阶段 | 状态 | 关键证据 |
|---|---|---|
| P0 环境与工程 | **PASS** | `docs/ENVIRONMENT.md`；Xcode 27.1 + iOS 27.1 SDK；干净克隆可复现 |
| P1 Metal 画布 | **PASS**（模拟器） | 上屏渲染、原生分辨率合成、旋转/resize 保持内容 |
| P2 触控/预处理/Replay | **PASS**（模拟器） | 23 单测；7 夹具；同夹具两次 7 帧字节一致；真机触控 BLOCKED |
| P3 速度场 + 颜料 | **PASS**（数据层） | 六夹具实测有梯度流体、零过曝、衰减符合半衰期 |
| P4 Detail / 柔光 | **READY_FOR_VISUAL_REVIEW** | 4 轮调优 + A/B；用户明确「先这样」→ 未验收，不标 PASS |
| P5 布局/生命周期 | **PARTIAL** | iPad 模拟器旋转/前后台/横屏 Debug 3/3 PASS；真机与 Pencil BLOCKED |
| P6 性能/长期 | **PARTIAL** | 模拟器 60 fps（P50 16.67/P95 16.70/P99 16.74）；100 次循环 + 90 s 持续 PASS；真机性能 BLOCKED |
| P7 CI / 交付 | **PARTIAL** | 本地 `verify-all` 全绿；GitHub Actions 待推送（本机无推送凭据）；真机门槛未过 |

**整体结论：`ENGINEERING_PARTIAL / AWAITING_VISUAL_ACCEPTANCE / DEVICE_VALIDATION_BLOCKED`**

## 真机验证（2026-10-21 · iPad Pro 11" 第3代 / iPad13,6 / M1）

设备与签名：UDID `<DEVICE_UDID>`，Team `<TEAM_ID>`（Personal Team），
Developer Mode 已启用，个人签名已在设备端信任。

| 项 | 结果 |
|---|---|
| 真机构建 | **PASS**（`BUILD SUCCEEDED`，TeamIdentifier=<TEAM_ID> 已签名） |
| 真机安装 | **PASS**（`devicectl device install app`） |
| 真机启动 + 回放 | **PASS**（`--flow-replay spiral`，原生 1668×2388 捕获） |
| 真机渲染画质 | 与模拟器同量级（可见 12.5% vs 10.5%，最大亮度 0.893 vs 0.905，0% 过曝） |
| 真机 10 分钟循环 | **PASS**（63 次重放，P95 16.74 ms，P99 ≤18.26 ms，0 崩溃） |
| 真机视频 | `artifacts/video/device-{spiral,slow-stroke,two-fingers}.mp4` |

**踩到并记录的坑（都已在脚本里处理）**：
1. `DEVELOPMENT_TEAM` 不能用证书名括号里的值（`<CERT_NAME_SUFFIX>`），
   真正的 Team 是证书 subject 的 **OU** 字段（`<TEAM_ID>`）——脚本改为自动从证书推导。
2. `project.yml` 原来全局 `CODE_SIGNING_ALLOWED: NO`，真机构建会产出未签名 App
   （`No code signature found`）。已移除，改由模拟器脚本显式传入。
3. 设备 UDID 新格式为 `8-16`（如 `<DEVICE_UDID>`），旧正则 `8-4-4-4-12` 匹配不到。
4. 个人 Team 首次安装需在设备 **设置 → 通用 → VPN 与设备管理** 手动信任；
   描述文件 7 天过期（当前至 2026-10-28）。

**仍未验证（BLOCKED / NEEDS_HUMAN）**：
- 真实手指的双指/四指交互手感（回放路径不经过 UIKit 触摸栈）。
- Apple Pencil 压力/倾角（需兼容的 Pencil 硬件）。
- iPhone 真机（无 iPhone 设备可用）。
- 真机 GPU pass 级耗时（需 Instruments / Metal Debugger 图形界面操作）。
