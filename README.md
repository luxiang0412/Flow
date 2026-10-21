# Flow — Luminous Ink (Prototype 01)

原生 iOS/iPadOS **Metal 触控流动艺术原型**：轻触绽放柔和墨迹，拖动牵引速度场，画圈形成旋涡，
多指通过同一流场互相影响，抬手后墨迹继续流动并衰减。

三层视觉目标：**液态主体 + 沿流场拉伸的丝状细节 + 克制的局部柔光**，并保留深色留白。

- 语言/框架：Swift 6（严格并发）· SwiftUI（壳）· UIKit（触控）· Metal / MetalKit（渲染）
- 最低部署：iOS / iPadOS **18.0**，Universal（iPhone + iPad）
- 依赖：**仅 Apple 系统框架**，无任何第三方运行期依赖
- 工程事实源：`project.yml`（[XcodeGen](https://github.com/yonaskolb/XcodeGen)），`Flow.xcodeproj` 不入库

工程契约：[FLOW-PROTOTYPE-01.md](FLOW-PROTOTYPE-01.md)
阶段状态与证据：[docs/PROGRESS.md](docs/PROGRESS.md) · 给协作者/Agent 的上下文：[AGENTS.md](AGENTS.md)

---

## 状态

| 阶段 | 状态 |
|---|---|
| P0 环境与工程 | ✅ PASS |
| P1 Metal 画布（原生分辨率合成） | ✅ PASS |
| P2 触控采集 / 预处理 / 确定性回放 | ✅ PASS |
| P3 速度场 + 颜料输运 | ✅ PASS |
| P4 丝状细节 + 柔光（视觉闸门） | 🟡 **等人工视觉验收** |
| P5 布局 / 生命周期 | 🟡 真机跑通；真实手指多指与 Apple Pencil 待人工 |
| P6 质量 / 性能 / 长期运行 | ✅ PASS（iPad 真机 10 分钟 60 fps，0 崩溃） |
| P7 自动化 / CI / 交付 | 🟡 本地全绿；CI 已接入 |

**实测（真机 iPad Pro 11" / M1 / iPad13,6）**

| 指标 | 值 |
|---|---|
| 稳态帧率 | **60.0 fps**（P50 16.67 ms / P95 16.74 ms / P99 17.6 ms） |
| 10 分钟循环回放（63 次） | P95 ≤ 16.86 ms，P99 ≤ 18.26 ms，**0 崩溃** |
| 模拟网格 | 512 短边（384 / 640 均已验证可行，`--flow-grid`） |
| 过曝（亮度 > 0.9 的像素） | 0.0 % – 0.2 % |
| 确定性 | 同 fixture 两次回放，7 帧 PNG 字节一致 |

截图与对照：[`docs/screenshots/review/`](docs/screenshots/review/)（含 SHA-256 清单）

---

## 怎么玩

App 启动即为可交互画布，直接用手：

| 操作 | 效果 |
|---|---|
| 轻点 | 柔和绽放并持续扩散、变形（不是圆印章） |
| 按住不动 | 缓慢增浓（有上限） |
| 慢拖 | 宽而柔的色带，边缘清晰但不硬 |
| 快划 | 较细的拖尾，抬手后继续漂移 |
| 画圈 | 流场被带动，形成会转、会演化的旋涡 |
| 双指 / 多指 | 通过同一速度场互相挤压、交织 |
| 抬手 | 停止注入，已有墨继续流动并衰减（速度 0.65 s / 颜料 6.5 s 半衰期） |

颜色沿画布做 Aurora 渐变（紫 → 品红 → 粉 → 暖橙），同一位置同一颜色，可复现。

**调试面板**：右下角圆形按钮展开（iPhone 为底部条，iPad 为左侧浮层）
`Pause/Resume`、`Clear`、`Capture`、`Replay ▾`（7 组预设手势）、`Metrics`（实测 FPS / P50 / P95 / NaN 计数）、
`Flow`（动量与阻尼）、`Glow`（仅视觉）、`Ink Life`（颜料寿命）。Debug 构建专属。

---

## 从干净目录构建

```bash
# 0. 环境核验（写入 docs/ENVIRONMENT.md）
./scripts/env.sh

# 1. 生成工程
xcodegen generate --spec project.yml
xcodebuild -list -project Flow.xcodeproj

# 2. 选一台模拟器
xcrun simctl list devices available
export SIM_UDID="<udid>"

# 3. 构建 / 测试（保留完整日志与 xcresult 于 artifacts/）
./scripts/build.sh
./scripts/test.sh

# 4. 确定性 Replay（自动收集原生分辨率 PNG）
./scripts/replay.sh spiral

# 5. 高码率评审视频（用帧序列自行编码，避开模拟器录屏的低码率）
./scripts/make-video.sh spiral

# 6. 宿主 CPU 层冒烟测试（无需模拟器）
./scripts/host-smoke.sh          # 100+ 项：时钟/归一化/去重/流体数学/fixture 确定性

# 7. 一条命令跑完全部可达验证
./scripts/verify-all.sh
```

要求：macOS + **完整 Xcode 27.1**、iOS 18 或更新 Simulator Runtime、XcodeGen ≥ 2.46。

## 真机运行

```bash
./scripts/device.sh --list                      # 查真机、签名身份、Team ID
./scripts/device.sh                             # 构建 → 安装 → 启动（自动推导 Team）
./scripts/device.sh --perf 60                   # 顺带采集 60 s 真机性能日志
./scripts/device-video.sh spiral                # 真机帧序列 → 高码率视频
```

一次性配置：
1. `Xcode → Settings…` → **Accounts** → `+` → **Apple ID**（免费 ID 即可）
2. 打开 `Flow.xcodeproj` → 选 **TARGETS 下的 `Flow`**（不是 PROJECTS）→
   **`Signing & Capabilities`** → 勾 `Automatically manage signing` → 选你的 Team
3. 设备上打开 `设置 → 隐私与安全性 → 开发者模式`；插线后「信任此电脑」
4. 首次安装后在 `设置 → 通用 → VPN 与设备管理` 信任该开发者（个人签名 7 天过期）

签名通过 `FLOW_DEV_TEAM` 环境变量注入（`project.yml` 中 `DEVELOPMENT_TEAM: ${FLOW_DEV_TEAM}`），
手改 Xcode 会被下次 `xcodegen generate` 覆盖。

## Debug 启动参数

```text
--flow-replay <fixture>    tap | slow-stroke | fast-swipe | spiral | two-fingers | crossing | four-fingers
--flow-seed <int>          固定噪声种子（缺省 2401）
--flow-fixed-dt <sec>      固定物理步长（推荐 0.0083333333）
--flow-capture-at a,b,c    额外捕获时刻（模拟秒）
--flow-disable-bloom / --flow-disable-detail
--flow-dump-frames <fps>   按模拟时间导出原生分辨率 PNG 帧序列（视频源）
--flow-metrics-log         每 2 s 打印 fps / P50 / P95 / P99
--flow-grid 384|512|640    模拟网格短边
--flow-loop-replay         回放结束后自动重放（长时压力测试）
```

---

## 架构速览

- **SwiftUI 壳**（`ContentView` / `DebugOverlay`）只承载控件；指标以 ≈2 Hz 轮询，不参与逐帧重算。
- **`FlowMetalView`**（UIKit + MTKView）：multi-touch + coalesced 采样 + Apple Pencil；
  预测触点不进入永久模拟状态；输出归一化 `TouchSample`。
- **`InputNormalizer`**：坐标归一化、时间戳去重、速度估计与上限、按半径 0.4× 自适应插值，
  并区分「轻点爆发 / 按住补墨 / 描边」三类事件。
- **`SimulationClock`**：固定步长累加器（1/120 s），暂停/恢复/过载截断（每帧 0–3 步）。
- **`FlowRenderer`**：每个固定步依次执行
  `advectVelocity → injectVelocity → dampVelocity → advectPigment → injectPigment →
  decayPigment → advectDetail → injectDetailDecay`，随后 `composite → bloom → finish`；
  速度/颜料/细节各自 A/B 双缓冲。
- **`finishFragment`**：在 **drawable 原生分辨率**逐像素合成（背景 + 主体 + 柔光 + 原生分辨率丝状调制），
  不在低分辨率网格上完成后放大。
- **`ReplayEngine`**：固定种子 + 固定步长重放，走与真机相同的归一化输入路径。
- **`TestCapture`**：独立离屏渲染 → 共享缓冲回读 → PNG（sRGB）。

**确定性**：注入 kernel 在每个 texel 上串行遍历按 `(timestamp, touchID)` 排序的事件表，
不使用原子操作、不依赖线程调度；捕获在固定步内编码，因此同一 fixture + 种子在任意帧率下
产出逐字节一致的图像。

## 测试

- `FlowTests`（Swift Testing）：坐标/宽高比、多指独立、coalesced 去重、零长度非 NaN、
  速度上限、固定步长下 60/120 Hz 等物理时间、暂停不累积墙钟、受限注入不溢出、
  阻尼公式、advect 边界、Swift↔Metal 结构布局、网格比例、纹理格式、离屏 PNG。
- `FlowUITests`：启动、Debug 控件可访问性、fixture 菜单、CLI Replay、
  iPad 旋转/前后台/横屏面板、100 次 pause+clear+resume、90 s 持续交互。
- `HostSmoke`：无需 Xcode/iOS SDK 的 100+ 项 CPU 核心检查。
- 真机多指手感与 Apple Pencil 压力：需要人工在设备上验证（回放不经过 UIKit 触摸栈）。

---

## 已知限制

- 无压力投影（Poisson 求解）；仅在需要时考虑 curl enhancement。
- 无 120 FPS 调优（当前 60 FPS）。
- 无作品导出、相册/分享、云同步、订阅等功能（原型明确非目标）。
- Apple Pencil 压力/倾角未在真机上验证。
- iPhone 真机未测（仅 iPad 真机 + 两类模拟器）。

细节与已解决的回归记录见 [docs/KNOWN-ISSUES.md](docs/KNOWN-ISSUES.md)。

## 许可

本仓库暂未附许可协议（默认为保留所有权利）。如需开源授权，请先添加 `LICENSE`。
