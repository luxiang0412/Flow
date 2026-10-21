# FLOW-PROTOTYPE-01 — Luminous Ink / 流光墨迹

> **执行对象**：本地 AI Coding Agent（Pi）  
> **文档版本**：1.0 · 2026-10-21  
> **性质**：**工程实施规范 + 阶段验收合同**，不是概念提案  
> **目标**：开发一个可在 iPhone / iPad 运行的 **原生 Metal 交互流光原型**，证明单指与多指输入可以生成有惯性、有旋涡、有细腻结构的高品质流动艺术画面。  
> **停止条件**：只有“真机视觉与手感合格 + 可复现测试证据 + 代码可构建”才能宣布 Prototype 01 完成。  
> **开发范围**：此文档仅覆盖 **Prototype 01**。不提前建设完整 MVP、App Store 发布资源或其他艺术模式。

---

## 0. 给 Pi 的最高优先级指令

你是本项目的**实现工程师和测试执行者**，不是产品经理。必须实现本文确定的产品与架构决策。对于本文未定义且会显著改变视觉效果、交互手感、设备支持范围或外部依赖的决定：**不要自行扩展；先采用最保守、可撤销的实现，记录为待决事项**。

1. **体验质量 > 功能数量 > 架构复杂度。** 不要将“编译成功”“单元测试通过”“模拟器可以运行”写成“产品体验已通过”。
2. **一步一验收。** 每完成一个阶段，执行规定命令、保存结果、记录失败与修复；不允许连续实现所有阶段最后才测试。
3. **不得伪造证据。** 没有物理设备就标记真机项 `BLOCKED`；没有 Apple Pencil 就标记 Pencil 项 `NOT_TESTED`；不可用的性能指标必须注明原因，不能估算成实测值。
4. **禁止悄悄降级。** 如果核心丝状结构实现不了、手感迟滞或帧率不够，必须明确报告差距，禁止用廉价粒子、静态贴图或全屏渐变替换后继续声称目标达成。
5. **没有真实渲染时不得提交最终视觉截图。** 测试图像必须来自 App/Metal 实际输出；示意图单独标识。
6. **所有随机效果必须可复现。** 调试/回放使用固定种子和固定模拟时钟；禁止在 Shader 中基于当前墙钟随机跳动。
7. **不要引入后端、网络权限、账号、广告、订阅、云同步、第三方美术素材或运行期第三方 SDK。**
8. **每个可观测失败都要保留原始日志。** 不能只粘贴 `BUILD SUCCEEDED` 或日志最后几行；必须保存完整日志与退出码。
9. **阶段性提交 Git。** 提交信息可采用 `p0: bootstrap project`、`p1: metal canvas` 等；不得为赶进度删除失败测试或隐藏诊断功能。
10. **以用户主观验收为最终门槛。** 不要替用户宣布“艺术质感优秀”。如需人工判断，提供截图、真机短视频及具体待评估问题。

### 完成状态语义

- `PASS`：有与阶段对应的命令、测试结果和必要视觉/真机证据。
- `FAIL`：已执行，未达到明确验收标准；附复现方法。
- `BLOCKED`：因设备、证书、工具或系统环境无法执行；列出阻塞条件和可操作的下一步。
- `NOT_TESTED`：尚未运行，不得视为通过。

如果一个阶段存在 `FAIL/BLOCKED` 的**阻断项**，不能将后续依赖阶段标记为整体 `PASS`。可以开发独立部分，但必须维护阻断清单。

---

## 1. 产品定义与非目标

### 1.1 产品陈述

**Flow — Luminous Ink** 是一个沉浸式、原生触控生成式艺术原型。用户轻触产生柔和彩色墨迹；拖动牵引流场、留下丝绸般的轨迹；画圈形成旋涡；双指让两股流动相遇；抬手后墨迹持续运动并逐渐衰减。

视觉目标：**液态主体 + 稳定跟随流场的丝状细节 + 克制的局部柔光**。

### 1.2 Prototype 01 需要有的能力

- 全屏 Metal 实时画布，iPhone/iPad 的布局与横竖屏、iPad 窗口尺寸变化不崩溃。
- 轻触、长按、慢拖、快速划动、画圆、两指及至少四指同时输入。
- 触点独立追踪，采集 UIKit coalesced touches；Apple Pencil 可用时获取压力和倾角等输入（优雅降级）。
- `Aurora` 默认颜色预设（另两套只需要预留数据模型，**此原型不要求做完整的调色 UI**）。
- 模拟暂停/继续、清空；可见的少量调试控件（仅 Debug 构建）。
- 本地确定性手势回放与关键帧捕获；从 Metal 渲染结果生成测试 PNG（**仅开发验证**，不是产品级导出）。
- 单元测试、GPU/模拟器验证、真机体验与性能记录。

### 1.3 禁止在 Prototype 01 扩展

作品库、正式相册导出工作流、系统分享 UI、视频导出、订阅、音效、账号、云同步、社交、专业级调色器、独立粒子引擎、复杂滤镜、多种艺术模式、App Store 资料制作。

### 1.4 成功画面的辨识标准

1. **轻触 ≠ 圆形印章**：可见柔和绽放及后续非刚性形变。
2. **慢拖 ≠ 一串圆点**：色带连续、宽柔，边缘可辨；局部保留精细结构。
3. **快划 ≠ 笔刷线条**：有惯性和拉伸尾迹，抬手后继续漂移。
4. **画圈 ≠ 静态圆环**：形成可见的卷曲/旋涡，并持续演化。
5. **双指 ≠ 两条无关的线**：彼此通过同一速度场影响、交织。
6. **Bloom ≠ 模糊遮罩**：关掉柔光仍然好看，最亮部分才有柔光。
7. **留白**：大部分时间仍有清晰的深色负空间，不能迅速铺满为浑浊彩雾。

---

## 2. 稳定技术基线与开工检查

### 2.1 版本基线

按 **2026-10-21 Apple 官方公开信息**：

| 项目 | 决策 |
|---|---|
| 构建平台 | Mac，安装完整 Xcode，而非仅 Command Line Tools |
| 推荐 Xcode | **27.1 稳定版**；不要主动使用 27.2 RC/Beta |
| Xcode 要求的 macOS | macOS Tahoe 26.6 或更新版本；启动前以当前 Apple 官方矩阵和本机检测复核 |
| Swift 编译器 | 随 Xcode 27.1 的 Swift 6.4；项目选择 Swift 6 语言模式 |
| 最低部署 | **iOS/iPadOS 18.0**；按同一 Universal iOS App Target 支持 iPhone 和 iPad |
| UI | SwiftUI（壳、Debug 控件）+ UIKit（真实触控视图） |
| 核心 GPU | Metal / MetalKit；使用稳定、成熟的 `MTLCommandQueue` / `MTLComputeCommandEncoder` 等 API，不强制 Metal 4 新特性 |
| 测试 | Swift Testing 或 XCTest 单元测试；XCUITest 自动化；Instruments + Metal Debugger 真机验证 |
| 运行期依赖 | Apple 系统框架，无三方依赖 |
| 项目生成 | 推荐 **XcodeGen** 仅作为开发期构建工具，保留可复现 `project.yml` 和版本记录 |

> 如果安装了更新的稳定 Xcode，不要为了追版本而频繁切换；记录确切版本、SDK、最低目标和兼容性。若本机不满足 Xcode 27.1 要求，应先解决环境，不能默默改用 Beta 或更低目标。以 `xcodebuild -version` 的真实输出为准。

官方核对入口：

- [Apple Xcode SDK 与系统要求](https://developer.apple.com/xcode/system-requirements)
- [MetalKit `MTKView`](https://developer.apple.com/documentation/metalkit/mtkview)
- [Apple Pencil 输入](https://developer.apple.com/documentation/uikit/handling-input-from-apple-pencil)
- [Coalesced touches](https://developer.apple.com/documentation/uikit/getting-high-fidelity-input-with-coalesced-touches)
- [Metal on Simulator 的限制](https://developer.apple.com/documentation/metal/developing-metal-apps-that-run-in-simulator)
- [XcodeGen 官方仓库](https://github.com/yonaskolb/XcodeGen)

### 2.2 机器与 SDK 探测：**必须首先运行**

```bash
set -o pipefail
sw_vers
uname -m
xcode-select -p
xcodebuild -version
xcrun swift --version
xcrun simctl list runtimes
xcrun simctl list devices available
xcrun xcodebuild -showsdks
command -v xcodegen || true
```

将完整输出写入 `docs/ENVIRONMENT.md`。检查 `xcode-select -p` 指向完整 Xcode（通常是 `.../Xcode.app/Contents/Developer`），而不是孤立的 CommandLineTools；检查 iOS Simulator Runtime 是否实际安装。

**失败处理**：

- `xcodebuild` 无法运行：核对 `xcode-select`、Xcode First Launch、license；记录现象，经过用户允许后使用 `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` 等官方方式修复；不得盲目循环 `sudo`。
- 缺少 runtime：在 Xcode Settings → Platforms 下载受支持 runtime；以当前机器实际可用设备名称和 UDID 为准。
- 没有真实 iPhone/iPad：允许进入模拟器与算法阶段，**最终真机门槛阻塞**。
- 没有 XcodeGen：可以通过 `brew install xcodegen` 安装（开发期依赖），先记录 Homebrew 可用性、安装版本与来源；若不可安装，可用 Xcode 创建等价 `.xcodeproj`，但仍需提交可复现工程文件。

---

## 3. 项目布局、职责边界、工程约定

### 3.1 目录建议（文件名可以微调，职责不可混淆）

```text
Flow/
├── project.yml                    # XcodeGen 工程规范
├── Flow.xcodeproj/                # 可选择纳入 Git；若不纳入需在 CI 生成
├── FlowApp/
│   ├── App/                       # @main、ContentView、应用生命周期
│   ├── UI/                        # DebugOverlay、暂停/清空控件
│   ├── Input/                     # TouchCaptureView、TouchSample、InputNormalizer
│   ├── Simulation/                # SimulationClock、SimulationConfig、ReplayEngine
│   ├── Rendering/                 # MetalRenderer、TexturePool、PipelineFactory
│   ├── Shaders/                   # .metal files；pass 用明确名称
│   ├── Diagnostics/               # FrameMetrics、TestCapture、ErrorStatus
│   └── Resources/                 # App 基础本地资源（不得使用第三方图片）
├── FlowTests/                     # CPU 逻辑与参数单测
├── FlowUITests/                   # 启动、Debug 操作、截图附件
├── Tests/Fixtures/               # JSON 手势数据、固定种子与期望统计范围
├── scripts/                      # 构建、测试、回放、报告生成的轻量脚本
├── docs/
│   ├── ENVIRONMENT.md
│   ├── PROGRESS.md
│   ├── VISUAL-SPEC.md
│   ├── TEST-REPORT.md
│   ├── PERFORMANCE.md
│   ├── KNOWN-ISSUES.md
│   ├── DECISIONS.md
│   └── screenshots/              # 标注来源、设备、场景与时间点
└── .github/workflows/ci.yml
```

### 3.2 核心模块职责

| 模块 | 职责 | 明确不允许 |
|---|---|---|
| `FlowApp` / SwiftUI | 安全区与 UI、应用生命周期、调试控件 | 每帧触发整个 SwiftUI 视图树重算 |
| `TouchCaptureView` / UIKit | 接收 touches、维护触点身份与事件队列 | 直接在主线程执行 GPU 求解 |
| `InputNormalizer` | 坐标、时间戳、压力、速度估计、连续段重采样 | 为缺失的 Pencil 信息捏造物理数值 |
| `SimulationClock` | 固定时间步、暂停/恢复、过载保护 | 以显示帧数量决定颜色衰减 |
| `MetalRenderer` | 纹理、pass 编码、显示、尺寸变更、命令队列 | 在每个触摸回调里创建 GPU 纹理或 Pipeline |
| `.metal` kernels | 注入、输运、衰减、合成 | 非确定性时间随机、越界访问、同一 pass 未定义读写 |
| `ReplayEngine` | 以固定采样时间重放 JSON 轨迹 | 通过模拟器 UI 自动手势冒充精确多指输入 |
| `TestCapture` | 离屏绘制/读回 PNG、关键帧记录 | 从 SwiftUI 截屏替代真实 Metal 纹理 |
| `Diagnostics` | 记录 CPU、GPU、帧间隔、配置、错误与来源 | 把 Simulator 结果写成设备 GPU 性能 |

### 3.3 工程规则

- Swift 6 严格并发语义：触控 UI 保持主线程/`@MainActor` 约束；模拟输入使用有界队列及清楚的所有权和同步关系。共享可变状态不得依赖“通常不会碰撞”。
- 不允许每帧创建 `MTLDevice`、`MTLCommandQueue`、PipelineState 或全尺寸纹理；在初始化或尺寸变更时建立资源。
- SwiftUI 用 `UIViewRepresentable` 包装拥有触控能力的 `MTKView` 子类，实际绘制由 `MTKViewDelegate` 驱动；不要在 `updateUIView` 中重复创建 Renderer。
- 所有 Debug 开关/回放入口仅用于 Debug 构建，生产配置不依赖它们。
- `.metal` 添加到正确 target 编译来源，保持 Shader 函数名、输入缓冲索引与 Swift 常量一致。
- 明确 GPU 命令执行和资源生命周期：一条 command buffer 中串行编码各 pass，阶段间 A/B 正确切换；多帧并发使用 inflight 同步或确保上帧资源不被覆盖，**不要在主线程每帧 `waitUntilCompleted()`**。

---

## 4. 视觉规范：必须忠实呈现

### 4.1 总体设计

- 画布背景：`#070A13`（深海军黑）。
- 默认调色板 `Aurora`：`#6548DF`、`#C754CE`、`#FB719E`、`#FFC68B`。
- 开始时屏幕可以是空画布；首次轻触必须有即时反馈，不能等待用户拖动。
- 液态主体：边缘清晰但非硬边，亮暗有变化；颜色局部透明叠加，不允许频繁纯白饱和。
- 丝状细节：细于液态主体，沿同一流场自然拉伸；不允许随机方向的“飘雪”。
- 柔光：只影响高亮区域，默认弱；关掉 Bloom 后仍然是漂亮的画面。
- 不用闪烁和频繁颜色跳变制造“动感”；尽量避免 banding、色阶断裂、锯齿、边缘锯状波纹。

### 4.2 控件：原型允许 Debug Overlay

最小 Debug UI：

- `Pause / Resume`、`Clear`、`Replay Fixture`、`Capture Frame`、`Show Metrics`。
- 可调 `Flow`（影响输入动量/阻尼的受限组合）、`Glow`（仅改变视觉合成）、`Ink Lifetime`（仅 Debug）。
- 显示当前 FPS 的**测量值**、模拟分辨率、active touches、当前 replay 名称、设备类型及是否 `SIMULATOR`；不得只展示 `preferredFramesPerSecond`。
- 默认隐藏或折叠，避免影响沉浸式画布；所有控件提供 Accessibility Label。
- iPhone 使用小型底部折叠条；iPad 使用不挡主体的边缘浮动控制层；不以简单整体放大作为 iPad 适配。

### 4.3 基线物理感

| 操作 | 目标结果 |
|---|---|
| Tap | 有小范围色彩绽放，不是硬圆印章 |
| Hold | 缓慢注入、有上限；不会无限增亮 |
| Slow stroke | 连续、略宽、柔和轮廓，不出现孤立点链 |
| Fast swipe | 较细较长尾迹，有残余动量且不丢触点 |
| Circle | 流场形成局部旋涡，而非静态圆圈 |
| Reverse | 反向输入与旧惯性产生交织，不会瞬时整体反向 |
| 2–4 fingers | 每指有稳定身份；通过共享速度场相互影响 |
| Release | 停止注入，但已存在流场继续运动并衰减 |
| Pause | 物理状态完全冻结；Resume 不补算暂停秒数 |
| Clear | Velocity、Pigment、Detail、临时后处理状态全部清零 |

---

## 5. 算法合同：数据、坐标、时钟、Shader

以下是 **必须先实现的确定性基础**，不是建议 Pi 自己挑一个“差不多的 Fluid Shader”。

### 5.1 坐标与时间约定

- UIKit 的触摸位置从 `UIView` **points** 转换到画布归一化坐标 `(u,v)`，范围 `[0,1]`；规定左上角 `(0,0)`，右下角 `(1,1)`。
- 处理 Retina scale、drawableSize、safe area、iPad 多窗口及横竖屏；**触控空间必须和实际 Metal 画布内容区域一致**，不能简单用整个屏幕宽高。
- 速度和注入半径以画布**短边归一化单位**为主；归一化后的屏幕长宽比不得使圆形笔触变成椭圆。
- 时间用单调递增时间戳，以秒表示；禁止用 `Date()` 的墙钟时间差计算物理速度。
- 固定模拟步长推荐 `dt = 1/120s`，可配置，但同一 Replay 必须固定；显示每帧可执行 0–3 个固定模拟步，防止卡顿后的无限追帧。
- `accumulator` 过大时有日志并截断过期模拟时间；不允许用一次 100ms 的大步长代替多个稳定小步长。

### 5.2 输入事件字段

`TouchSample` 的契约：

| 字段 | 类型语义 | 约束 |
|---|---|---|
| `touchID` | 当前会话中稳定的整数 ID | 每次 begin 分配；end/cancel 释放；不要把内存地址持久化 |
| `phase` | began/moved/ended/cancelled | 显式结束，防止“幽灵触点” |
| `timestampSeconds` | 单调时钟 | 每个触点内部非递减；重复样本去重 |
| `position` | 归一化向量 | 按画布实际比例转换 |
| `inputKind` | finger/pencil | 不支持 Pencil 时按 finger 行为稳定降级 |
| `normalizedForce` | 可选压力 | 仅真实有效时使用；默认为中性值 |
| `altitude/azimuth` | 可选角度 | 原型可记录并测试，**不强制驱动视觉** |
| `isPredicted` | 预测标记 | **Prototype 01 禁止进入永久模拟状态** |

UIKit 入口必须 `isMultipleTouchEnabled = true`，针对每个触点读取 `event.coalescedTouches(for:)`，在事件处理当下转换并保存独立的值对象（不要长期持有 `UITouch`）。Apple Pencil 可能存在 `estimatedPropertiesExpectingUpdates`；未获得确认的压力/角度不可声称精确值。

### 5.3 输入预处理

1. 对每个 `touchID` 按时间戳稳定排序，保留不同指头之间的实际时间关系。
2. 同一时间戳重复点去重；接续段最多只注入一次端点，避免多次加墨。
3. 根据相邻位置、真实时间差估计输入速度，低通平滑并设置上限；零长度段处理为 Tap/Hold，不可除以 0。
4. 长距离采样跨越多个网格时进行**按距离自适应线段插值**：建议插值相邻点间隔不大于局部注入半径的 `0.35–0.5` 倍，且每模拟步设置全局事件/子段上限。
5. 过载时优先保留每指的 begin/end、轨迹外形和最后真实点；允许合并冗余中间点，记录 dropped/coalesced 数量。
6. 不允许因为主线程短暂拥塞，让同一段轨迹被当作一次“巨大的速度冲击”。

### 5.4 GPU 纹理与语义

| 资源 | 初始格式 | 内容 | 是否双缓冲 |
|---|---|---|---|
| `velocity` | `RG16Float` | 每像素 `(vx, vy)`，单位为归一化短边/秒 | 是 A/B |
| `pigment` | `RGBA16Float` | `rgb = premultiplied linear RGB`，`a = dye concentration ∈ [0,1]` | 是 A/B |
| `detail` | `R16Float` | 与颜料共流场的细丝/亮度细节强度 `[0,1]` | 是 A/B |
| `composite` | 适当 render target | 已合成主体与细节的线性图像 | 按需 |
| `bloom` | 降采样纹理 | 局部高亮的模糊结果 | 按需 |

**不允许**混用 straight/premultiplied RGB 约定。若 `(rgb, a)` 为预乘表示，需满足 `0 <= rgb <= a`（颜色分量基于 `[0,1]` SDR 线性值，调试时考虑合理数值误差）。在显示前执行对应的线性到 sRGB 转换/设备颜色管理，避免“重复 gamma”或线性值误作 sRGB。

初始模拟网格：**短边 512 texels，长边按画布比例推导，上限建议 1024**；需提供 384 与 640 档作为性能对照。分辨率以实测选择，不能写死导致 iPad 超大纹理。显示合成按 drawable 原生尺寸执行；不能简单把低分辨率图放大当精致画质。

### 5.5 每个固定时间步的 GPU Pass（强制执行顺序）

| 序号 | Pass | 输入 → 输出 | 规则 |
|---|---|---|---|
| 1 | `AdvectVelocity` | velocity A → velocity B | 半拉格朗日反向采样，边缘 clamp；对 NaN/Inf 做防护 |
| 2 | `InjectVelocity` | velocity B + 本步真实 touch segments → velocity A | 沿笔划连续注入速度；Tap 可注入小幅径向扰动 |
| 3 | `DampVelocity` | velocity A → velocity B | 按 `exp(-k_v*dt)` 衰减并裁剪速度上限 |
| 4 | `AdvectPigment` | pigment A + velocity B → pigment B | 线性空间预乘颜料输运，边界处理 |
| 5 | `InjectPigment` | pigment B + touch segments → pigment A | 注入宽柔色彩核；浓度有上限 |
| 6 | `AdvectDetail` | detail A + velocity B → detail B | 细节与主体共用速度场 |
| 7 | `InjectDetailAndDecay` | detail B + touch segments → detail A | 沿局部轨迹方向注入稳定细节；时间衰减 |
| 8 | `FinalizeStep` | velocity B、pigment A、detail A | 更新读写角色；记录统计（Debug） |

以上是**逻辑阶段**；实现可合并相邻、无读写竞争的 kernel 以减少提交成本，但文档必须记录映射、不能因合并改变数学语义。每帧做完 0–N 个模拟步后执行全屏 `Composite`；Bloom 使用单独下采样/模糊/叠加 Pass；静止且暂停时无需持续计算。

#### 物理关系

半拉格朗日输运：

```text
q_next(x) = sample(q_prev, x - dt * velocity(x))
```

阻尼：

```text
velocity *= pow(0.5, dt / velocityHalfLifeSeconds)
pigment  *= pow(0.5, dt / pigmentHalfLifeSeconds)
detail   *= pow(0.5, dt / detailHalfLifeSeconds)
```

这里对 pigment 的预乘 RGB 和浓度 alpha **同步衰减**，避免退色时改变色相；运行时处理数值范围与 alpha=0 的情况。

注入颜色建议用**受限覆盖混合**而非无界相加，设旧浓度 `a`，目标颜色（线性 RGB）为 `C`，有效注入量 `s ∈ [0,1]`：

```text
added = (1 - a) * s
newAlpha = a + added
newPremultipliedRGB = oldPremultipliedRGB + added * C
```

这能避免反复按住时 alpha 无限增加。需要多指同一步确定性处理：按 timestamp + stable touchID 的稳定顺序注入；如果采用 GPU 并行累积，必须保证结果与线程调度顺序无关（例如先聚合触点贡献再进行一次受限合成）。不允许多个线程对同一 texel 做不受支持的读改写。

### 5.6 初始参数（调参起点，非已经过验证的终值）

| 参数 | 起始值/范围 | 作用 |
|---|---|---|
| `simulationStep` | `1/120 s` | 物理时钟 |
| `velocityHalfLife` | `0.8 s`（可调 0.4–1.6） | 释放后的速度余量 |
| `pigmentHalfLife` | `8 s`（可调 4–16） | 颜色保留时间 |
| `detailHalfLife` | `4 s`（可调 1.5–6） | 细丝短于主体寿命 |
| `radius` | 画布短边 `2.5%` 起步（1–5% 可调） | 触摸影响范围 |
| `touchMomentumGain` | 需依速度单位标定；从小值渐进，确保不爆炸 | 流动牵引强度 |
| `maxVelocity` | 约 1.5–2.5 画布短边/秒，按实际演示校准 | 限制异常速度 |
| `glowStrength` | 轻量，默认画面不依赖 Bloom | 高亮光晕 |
| `replaySeed` | 固定整数，如 `2401` | 确定性噪声 |

**重要**：不允许把这些数值直接作为 UI 的百分比写死。`Flow` 需映射到受限的动量/阻尼配置，`Glow` 只影响视觉，不修改模拟状态。

### 5.7 丝状结构算法 — 先做确定性纹理，不做粒子系统

建议在触摸线段上，根据局部切向 `t` 与法向 `n` 注入一个有**横向强弱变化**的 Detail 核：中心与两侧产生低幅亮暗差，沿轨迹连续，并使用固定种子做缓慢空间扰动。Detail 与 Pigment 由同一速度场输运。

Composite 阶段：

1. 读取 Pigment，获得主体预乘线性颜色与浓度。
2. 用 Detail 调制局部亮度/细线对比度，**仅在 pigment 有浓度的位置**有效。
3. 对高亮部分做低强度 Bloom，建议先在 1/2 或 1/4 分辨率提取/模糊。
4. 与深色背景合成；保持色彩不过曝，避免高亮迅速趋近白色。

允许试验两种 Detail 实现并通过同一组手势比较；只保留表现更好且更稳定的一种。**禁止引入随机飘动的独立粒子来替代丝状细节**。

### 5.8 压力投影、涡量增强：延期触发条件

Prototype 01 的第一条可用渲染路径**不做完整不可压缩压力求解**。只有回放证据表明：旋涡过快消失、双指汇合明显塌陷、颜色聚点不可控制等，才允许单独增加可开关的 curl enhancement 或 pressure projection，且必须记录前后对照、GPU 开销和是否真正改善视觉。

不能先花大量时间实现 Poisson Solver，再回头发现输入与视觉主体仍未成型。

### 5.9 边界、暂停、尺寸变更

- 所有采样按边界 clamp；注入区域越界进行裁剪，禁止纹理 OOB、NaN、Inf。
- 流体触边时采用固定的安全策略：初版对边界法向速度衰减或置零，禁止明显反弹/穿屏；在 `DECISIONS.md` 记录所选方案。
- Pause：停止时钟累积/输入注入，保留当前 GPU 纹理；Resume 重设上帧时间戳，不追加暂停期时间。
- Clear：先处理待提交 GPU 命令及资源所有权，再清零 A/B 全部状态与 Bloom 中间状态；下一帧不得出现旧画面。
- Resize：按画布比例重采样 Pigment/Detail，速度方向与大小依统一物理尺度转换；新增画布区域清零，比例变化不得强行非等比拉伸画面。尺寸变化失败时保留最后有效画面并报告，不得崩溃或默默把数据全丢。
- 后台：暂停绘制和 GPU 分配，恢复时重新同步时间；处理 drawable 暂不可用情况，不应无限自旋。

---

## 6. Gesture Replay：可复现视觉测试体系

### 6.1 必须实现的 Debug 模式

支持启动参数，例如：

```text
--flow-replay <fixture-name>
--flow-seed 2401
--flow-fixed-dt 0.0083333333
--flow-capture-at 0,0.5,2,8
--flow-disable-bloom
```

参数格式可以调整，但**要在 `docs/TEST-REPORT.md` 和脚本里统一**。不得在发行构建中接受危险的调试指令。回放直接驱动与真机触摸相同的 `InputNormalizer`/simulation 接口；不通过模拟器鼠标划线替代多指测试。

### 6.2 Fixtures 统一格式

放在 `Tests/Fixtures/*.json`：

- `schemaVersion`、`name`、`seed`、`canvasAspectRatio`、`durationSeconds`、`samples[]`。
- 每个 sample 至少有 `touchID`、`phase`、`time`、`x`、`y`、`inputKind`，按时间稳定排序。
- `x`、`y` 使用归一化坐标；测试包括按住不动、交错多指与取消触点。
- 测试采样时间**不依赖帧率**；渲染结果在同一模拟时间点采集。
- 每次 capture 附带设备/模拟器标识、GPU、Xcode、Shader/配置版本、随机种子、时间点、绘制分辨率。

### 6.3 六个必备手势

| Fixture 名称 | 轨迹 | 必看指标 |
|---|---|---|
| `tap` | 单点轻触后释放 | 绽放、残影、消散、无圆形贴图感 |
| `slow-stroke` | 缓慢 S 曲线 | 无断点、宽度合理、细丝连续 |
| `fast-swipe` | 150–250 ms 内横穿画布 | 不丢输入；尾迹与惯性明显 |
| `spiral` | 从外到内连续圆弧 | 有卷曲、动态旋涡，非静态线圈 |
| `two-fingers` | 两指同时相向与反向 | 真正共享流场；颜色不过曝 |
| `crossing` | 两指交叉路径，可含一指 cancel | 触点身份正确、无突然跳色/幽灵触点 |

**额外逻辑测试**：四指随机顺序 begin/move/end、重复时间戳、空列表、零长度拖动、超高速度、坐标越界、后台后恢复、连续 100 次 clear/pause/resume。

每个 Fixture 至少在 `touch end / +0.5s / +2s / +8s` 取图；另保存 5–10 秒真实连续演示片段。避免把跨设备浮点误差视为必然精确像素相等；同设备同配置可做紧容差比较，跨设备做统计与人工画质对照。

### 6.4 捕获方式

- 需要可复现图像时：**单独的 Metal offscreen render target** → 同步/异步安全读回 → PNG；捕获时明确色彩空间与是否包含 Bloom。
- **不要**直接把 `MTKView.currentDrawable` 当作可随意 CPU 读取的纹理；其 `framebufferOnly` 默认有优化限制。保留屏幕 drawable 的高效默认路径，通过独立离屏渲染取得证据。
- `xcrun simctl io <UDID> screenshot ...` 可用于 UI 布局截图，但它不是可控的精确模拟时刻捕获，不能代替 GPU Replay capture。
- 真机录屏必须来自真实设备（系统屏幕录制或经 Xcode/QuickTime 采集），不可使用模拟器视频冒充。

---

## 7. 本机标准命令与日志约定

以下命令假定项目目录为仓库根目录、工程名/共享 Scheme 为 `Flow`；初次项目生成后若 Scheme 不一致必须统一修正，而不是到处硬编码不一致名字。运行前先选取 **实际可用** Simulator UDID。

```bash
# 在项目根目录；严格使用完整日志与退出码
set -o pipefail
mkdir -p artifacts/logs artifacts/xcresult artifacts/captures

# 如使用 XcodeGen：记录当前版本，再生成工程
xcodegen --version
xcodegen generate --spec project.yml

# 列举 Xcode 工程、scheme、设备
xcodebuild -list -project Flow.xcodeproj
xcrun simctl list devices available
xcodebuild -showdestinations -project Flow.xcodeproj -scheme Flow

# 由上一步人工/脚本选择可用 iOS/iPadOS 模拟器 UDID
export SIM_UDID='<真实可用模拟器 UDID>'

# 建议首次启动模拟器
xcrun simctl boot "$SIM_UDID" || true
xcrun simctl bootstatus "$SIM_UDID" -b

# 构建：保存完整输出；不要只使用 tail
xcodebuild -project Flow.xcodeproj -scheme Flow \
  -configuration Debug -destination "platform=iOS Simulator,id=$SIM_UDID" \
  -derivedDataPath artifacts/DerivedData CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | tee artifacts/logs/build-simulator.log

# 全套测试；每次生成新结果路径，避免已存在 bundle 导致失败
xcodebuild -project Flow.xcodeproj -scheme Flow \
  -configuration Debug -destination "platform=iOS Simulator,id=$SIM_UDID" \
  -derivedDataPath artifacts/DerivedData CODE_SIGNING_ALLOWED=NO \
  -resultBundlePath "artifacts/xcresult/Flow-$(date +%Y%m%d-%H%M%S).xcresult" \
  test 2>&1 | tee artifacts/logs/test-simulator.log

# 查看和提取结构化 xcresult（先以本机 help 校验子命令）
xcrun xcresulttool help get test-results summary
# xcrun xcresulttool get test-results summary --path '<实际生成的结果包路径>'

# GUI 模拟器截图（不是精确 Replay capture）
xcrun simctl io "$SIM_UDID" screenshot artifacts/captures/simulator-screen.png
```

> `xcrun simctl boot ... || true` 只允许用在“已经处于 Booted 状态”的分支；其他启动错误必须检查 `bootstatus` 和日志。绝不能把 `|| true` 用在 build/test/replay 的失败检测中。

**命令失败通用检查顺序**：确认实际 Scheme / destination / Xcode path → 检查完整原始错误（不是最后十行）→ 按分类修复 → 只重跑该阶段 → 把根因与修复记录到 `KNOWN-ISSUES.md` 或 `DECISIONS.md`。

真机编译/测试：

```bash
xcrun devicectl list devices
xcodebuild -showdestinations -project Flow.xcodeproj -scheme Flow

# Device ID、Apple Team、签名证书需从真实环境检测，不得虚构。
# 真机签名由 Xcode 自动签名或已配置的有效开发团队处理。
xcodebuild -project Flow.xcodeproj -scheme Flow \
  -configuration Debug -destination 'platform=iOS,id=<真实设备 UDID>' \
  build 2>&1 | tee artifacts/logs/build-device.log
```

不能在真机构建时强制 `CODE_SIGNING_ALLOWED=NO` 然后声称可安装。设备不可用时记录为 `BLOCKED`。

### 日志与仓库大小

`artifacts/` 默认 `.gitignore`，避免把大体积 DerivedData、`.xcresult`、录屏和 trace 放入 Git 历史。阶段性代表截图可小量纳入 `docs/screenshots/`，其余保存本地 artifacts 并在报告中引用确切路径、文件大小及 SHA-256；GitHub CI 上传压缩后的关键日志与测试结果，并设置短期保留策略。

---

## 8. 分阶段任务（逐关卡执行）

**固定流程**：先满足本阶段 Exit Criteria → 更新文档 → Git commit → 才进入下阶段。所有命令必须在真实环境执行，并把退出码保存在报告中。

### P0 — 环境、项目生成、测试壳

**任务**

1. 运行第 2 节系统探测；核验稳定版 Xcode、Swift、iOS Runtime 与可用设备。
2. 创建 Universal SwiftUI iOS App 工程：`Flow`、最低 iOS 18、Swift 6 语言模式；加入 `FlowTests`、`FlowUITests`，保证 Swift/Metal 源码打包方案正确。
3. 若采用 XcodeGen：提交 `project.yml`，记录 `xcodegen --version`；保证 `xcodegen generate` 后 Scheme、目标、签名/版本信息一致。`Flow.xcodeproj` 可选择不入库，但 CI 必须复现生成。
4. 完成最小 SwiftUI App，显示一张无 GPU 内容的深色背景和可访问性标签（只用于 P0）；加入入口启动测试和一个纯 Swift 单测。
5. 建立 `docs/` 文档骨架、`.gitignore`、单个命令脚本入口、错误处理框架。

**命令**：第 2 节系统探测 + 第 7 节 `xcodegen` / `xcodebuild -list` / `build` / `test`。

**验收**：

- `Flow` Scheme 公开可用；模拟器 Debug build/test 真正退出码 0；两个测试 Target 都能执行。
- 至少 1 张真实模拟器截图和对应设备、系统、Xcode 版本记录。
- `docs/ENVIRONMENT.md`、`PROGRESS.md` 已填写，而非空模板。

**失败处理**：Scheme 缺失修正 target/scheme 定义；Metal target membership 错误先处理资源配置；Xcode/SDK 不匹配返回环境检查。**不得进入 P1**。

### P1 — Metal 黑色画布与渲染资源

**任务**

1. 用 `UIViewRepresentable` + 自定义 `MTKView` 子类 + `MTKViewDelegate` 挂载原生画布。
2. 创建 `MTLDevice`、`MTLCommandQueue`、着色器库、必要 Pipeline；强制检查失败返回值并显示可恢复错误视图。
3. 初始只渲染背景 `#070A13` 与内部测试渐变，不进行流体求解；确保坐标、分辨率、GPU Pass 排序可核查。
4. 监听 drawable size 和布局变化；前后台进入/退出不崩溃、不持续空转。
5. 实现 `TestCapture` 的最小离屏 RGBA 输出，能够落地准确 PNG 并记录像素尺寸、颜色空间。

**命令**：构建/test；在两个真实可用的 iPhone/iPad 模拟器上运行；`xcrun simctl io "$SIM_UDID" screenshot ...`；记录 app 输出的 offscreen PNG；`xcrun xcresulttool get test-results summary --path ...`。

**验收**：

- 图像确实来自 Metal，而非 SwiftUI Rectangle 假装画布。
- iPhone 竖屏和 iPad 横屏比例正确；Debug capture 实际像素非零、背景色误差合理；无黑块、全白错误或闪屏。
- Resize 多次后无崩溃/显著纹理泄漏。无 drawable 时安全跳过而不是强制解包。

**失败处理**：检查设备可用性、Shader 编译日志、像素格式与 colorSpace、`currentDrawable` 生命周期；必要时添加最小 render pass 调试，不得在损坏管线之上继续添加流体。

### P2 — Touch Capture、采样预处理、确定性回放

**任务**

1. `TouchCaptureView` 完整处理 began/moved/ended/cancelled；打开多点触控；采集 coalesced points，按 touchID 正确归档。
2. `InputNormalizer` 处理坐标、时间、重复点、插值、触点速度、压力默认值及上下界。
3. 增加 Debug Overlay 的 touch dots/轨迹（仅调试，单独层；不是最终艺术效果）。
4. 写入六个 Replay JSON Fixture，支持固定步长和固定种子运行；补充多指乱序/取消/零速度/超界测试。
5. 增加模拟器和真机触摸状态日志，明确同步规则与过载处理。

**命令**：

```bash
# 在生成工程并设置 SIM_UDID 后执行；名称按真实测试 target 调整
xcodebuild -project Flow.xcodeproj -scheme Flow \
  -destination "platform=iOS Simulator,id=$SIM_UDID" \
  -only-testing:FlowTests CODE_SIGNING_ALLOWED=NO \
  test 2>&1 | tee artifacts/logs/p2-input-tests.log
```

**验收**：

- 至少 4 个并发触点的 begin/move/end 在单测和回放中不丢身份；不存在 ghost touch。
- 采样线段连续，插值不会因密集采样重复大量上色；取消触点后不再注入。
- 同 Fixture + 同种子 + 同时间点，CPU 事件序列一致。
- 真机两指输入至少进行一次人工核验；缺真机则该子项 `BLOCKED`，不可伪称完成。

**失败处理**：发现触点错乱先回退到单指 Debug 显示；排查 Set 无序迭代、重复末端采样、scene resize 坐标；未稳定前不得进入 P3 的多点模拟。

### P3 — 速度场、颜料输运：实现第一条能玩的路径

**任务**

1. 初始化 Velocity A/B 与 Pigment A/B；写入第 5 节定义的 1–5 Pass，包含注入、输运、阻尼。
2. 通过 Canvas 短边归一化注入核，让 Tap 有小范围花开、Slow Stroke 连续。
3. 固定步长时钟；暂停、继续、清空完整实现，含后台恢复。
4. Debug 显示流场向量或方向色图的**可切换**视图，以及 RGB/alpha 数值异常统计。
5. 输出 `tap`、`slow-stroke`、`fast-swipe`、`spiral` 的确定性截图及短视频。

**命令**：第 7 节构建+测试+Replay；生成 `artifacts/captures/p3/{tap,slow-stroke,fast-swipe,spiral}/...png`；捕获并记录实际运行命令与结果文件（如果 Replay 命令入口仍未实现，要先补齐脚本，不得人工代替）。

**验收**：

- 暂停状态下连续截图像素与内部状态保持稳定；恢复不瞬移。
- Clear 后单步内没有任何残余墨迹/速度；无 NaN/Inf/负浓度。
- fast swipe 不出现触摸采样断链；spiral 有可辨认的涡旋或明确记录为视觉失败，不能仅由环形轨迹充数。
- 原型可以连续运行 5 分钟不崩溃；首版视觉允许不够精致，但应有可靠的物理与数据基础。

**失败处理**：出现数值爆炸先降低动量与 CFL 风险（如增加子步、限制速度），检查坐标单位、纹理寻址、衰减/alpha 语义；纹理读写冲突检查 Pass 和 A/B 角色。不得用全部改成纯色图片“修复”。

### P4 — Detail Field：形成真正的 Luminous Ink 辨识度

**任务**

1. 增加 Detail A/B 和第 6、7 Pass；细节与主体共享速度场，寿命短于颜料。
2. `Composite` 明确实现主体、细丝和深色背景的线性空间混合。
3. 首版 Bloom 为可开关后处理，尽量在低分辨率上工作；不要动态分配大量 blur 纹理。
4. 增加 `--flow-disable-bloom` / `--flow-disable-detail` A/B 诊断切换。
5. 固定 Fixture 三组视觉对比：主体-only、主体+Detail、主体+Detail+Bloom。

**命令**：Build/Test/Replay；收集 `tap, slow-stroke, spiral, crossing` 不同时间点的 A/B PNG；保存对照索引到 `docs/VISUAL-SPEC.md`。

**验收**：

- 主体-only 仍形成漂亮流动；开启 Detail 后是丝状结构而非随机噪点。
- Detail 严格限于已有 Pigment 区域；无黑底孤立光粒。
- Bloom 关闭仍能清晰观察到轮廓；开启后不泛白、不产生强烈 halo。
- 最终视觉初步符合“液态主体 + 丝状细节 + 柔光”三层定义。该项需由用户审看截图/短视频；Pi 只能报告工程状态 `READY_FOR_VISUAL_REVIEW`，不得自行宣告艺术效果达标。

**失败处理**：细节糊成烟雾时检查输运数值耗散、模糊半径与采样分辨率；先减弱 Bloom 和主体宽度，必要时试受限制器的高阶输运并附前后数据；不能简单增加随机粒子掩盖问题。

### P5 — 多指/Pencil、布局与生命周期

**任务**

1. 用 `two-fingers`、`crossing`、四指 Fixture 验证共享流场交互；同时处理 begin/end/cancel 与快速交替。
2. 真机 Apple Pencil 可用时：记录有/无压力两种结果；压力映射只影响注入强度或半径，不影响最基本的轨迹和速度；处理估计属性。
3. 真实 iPad 尺寸变化、横竖屏与窗口调整；保持作品而不是旋转/Resize 就清空。iPhone 操作区不遮挡主体内容。
4. 前后台切换、通知中断、低内存预警；无 GPU 时提供明确错误说明。
5. 测试 Debug 控件与系统辅助功能，例如 Reduce Motion 对装饰性动效的影响，不取消直接触控反馈。

**命令**：`xcrun devicectl list devices`、真机 `xcodebuild ... build`，并运行 Replay 与 UI tests；记录手动操作步骤。Apple Pencil 实测需要兼容的 iPad + Pencil，模拟器不算。

**验收**：

- 双指的色流确实互相影响，而不是两条预渲染线条重叠。
- iPhone/iPad 各至少一次真实设备运行；如果只有其中一类设备，另一类为 `BLOCKED`。
- Resize 不产生非等比拉伸或明显闪烁，恢复前台不突然加速/爆炸。
- Pencil 不可用时手指行为不受影响。

**失败处理**：设备缺失保留阻断，不能改验收条件；窗口变更丢画面检查纹理迁移、viewport、velocity scale；Pencil 异常检查 capability 与 estimated props。

### P6 — 质量、性能、长期运行

**任务**

1. 选择至少一台真实 iPhone 与一台真实 iPad；记录型号、SoC/系统版本、60/120Hz 能力、测试环境、供电及温度相关背景。
2. Debug 日志测量 CPU 帧编码时间、显示帧间隔、每个主要 GPU pass 时长（GPU 计时受设备/工具可用性约束）、活跃触点、模拟步数和内存。
3. 用 Instruments、Metal Debugger/GPU capture 在真机检查热点、纹理分配、GPU 限制和 stutter；分辨模拟性能和设备性能。
4. 连续交互至少 10 分钟；反复 100 次 Pause/Clear/Resume；横竖屏切换；后台恢复；低内存模拟/人为压力条件（在安全范围内）。
5. 比较模拟短边 384 / 512 / 640、Bloom on/off；选择满足流畅度与视觉质量的设备配置。
6. 准备真机完整短视频（至少 `slow-stroke`、`spiral`、`two-fingers`）、原始性能记录及可重复测试步骤。

**运行提示**：从 Xcode Product → Profile 打开 Instruments 的相关模板；用 Metal Frame Capture 分析 command buffer 和各 pass；可用 `MTLCaptureManager` 为 Debug 构建保存 `.gputrace`（设备支持时）。`xcrun xctrace list templates` 可列本机模板；不能臆造当前环境不存在的模板名。性能不以模拟器跑分作为真机结论。

**硬指标（需要设备实测，不是编译验证）**：

| 指标 | Prototype 01 门槛 | 证据 |
|---|---|---|
| 流畅度 | 目标真实稳定 60 FPS；持续场景不能普遍跌到 30 FPS | 真机采样图与帧间隔统计 |
| 帧预算 | 60Hz 单帧约 16.67ms；记录 P50/P95/P99，不仅平均值 | 采集文件与统计方法 |
| GPU | 初步争取主渲染工作量 8–10ms 或更低，不把估算当通过 | 真机 GPU trace / Instruments（如果可测） |
| 响应性 | 日常触控优先下一显示帧可见；实测快速划动无明显拖影/滞后 | 真机高帧率视频或可靠观测记录 |
| 稳定性 | 连续交互 10min 无崩溃、冻结、明显持续恶化 | 日志、录屏、采样统计 |
| 正确性 | Clear 无残影；Pause 无模拟漂移；NaN/Inf 统计为 0 | 自动化测试与截图 |
| 视觉 | 用户实际审看并明确接受形态、丝状质感与颜色 | 对照视频和评审结论 |

不设没有验证基础的绝对“GPU 内存不得超过 XX MB”硬限，改为记录真实使用、趋势、可回收资源和尺寸变化前后差异。保留 120 FPS 作为**可选探索**，不以 120 FPS 作为 Prototype 01 必须门槛。

**失败处理**：若掉帧，先 profile 分辨 CPU/填充率/纹理带宽/compute；优先降低模拟网格、Bloom 开销、纹理读写量，避免降低触控处理质量；每次只改一个主要参数并保存 A/B 视觉+性能。严重发热/长时卡顿需记录，不得仅截取前 30 秒的好结果。

### P7 — 自动化、CI、文档与交付

**任务**

1. 保证所有纯 Swift 数学/状态测试在 CI 可执行，必要时拆出不依赖实际触摸设备的测试模块。
2. XCUITest 覆盖启动、Pause/Resume、Clear、Debug fixture 选择、结果记录、基本 iPhone/iPad UI 布局；可附 `XCTAttachment` 截图。
3. GitHub Actions：选择**有 Xcode 支持的 macOS Runner**，实际读取 `xcodebuild -version` 并记录；若 runner 尚未提供项目所需稳定版 Xcode，不要默默切换 Beta。允许明确报告暂时 `BLOCKED`，本机结果不因此伪造。
4. CI 至少执行 `xcodegen generate` → `xcodebuild build` → `xcodebuild test`；上传失败日志、精简 `xcresult` 或提取测试结果，artifact 设置短期保留（如 3 天）并避免上传 DerivedData/视频大文件。
5. 完成 README、版本/设备矩阵、测试报告、视觉对照、已知问题、运行说明和本阶段验收清单。
6. 不进行 App Store 提审、正式签名发布、原生相册权限、社交功能或其他第二阶段扩展。

**命令**：本地完整重新生成工程并重复第 7 节 build/test；推送后检查 GitHub Actions job 退出码和 artifact；抽查全新 checkout 中 README 的步骤可运行。

**验收**：

- 从干净目录能够按 README 建工程、运行 Debug、执行 tests。
- 所有 P0–P6 状态与原始证据一致；CI 结果不替代真机视觉评审。
- 无 hardcoded 私有路径、账号、证书、钥匙或个人信息进入 Git。
- `docs/TEST-REPORT.md` 和 `docs/PERFORMANCE.md` 有真实数字、方法、设备与时间戳。

**失败处理**：CI Runner/Xcode 不匹配则输出环境差异与明确下一步；若 CI 仅能 build/test 无法验证 GPU 真机性能，标明其覆盖边界，不把它写成全平台性能已通过。

---

## 9. 测试矩阵与证据要求

| 类别 | 执行方法 | 必须断言 | 证据 |
|---|---|---|---|
| 纯 Swift 单测 | Swift Testing / XCTest | 坐标变换、插值、速度限制、时间步累积、暂停恢复、fixture 解析 | `.xcresult` 和测试清单 |
| Replay 一致性 | 固定 seed、固定 dt、固定 fixture | 事件排序、输出统计、无 NaN/Inf、同配置稳定 | JSON + 图像 + hashes/统计 |
| GPU 验证 | Metal offscreen + readback | 非空图、受限 alpha、可正确 Clear、尺寸正确 | PNG + GPU 日志 |
| UI 自动化 | XCUITest | 启动、控件触发、Accessibility Label、基本布局 | xcresult + 截图 |
| Simulator | iPhone + iPad 各至少一种 | 构建运行、画布比例、基本手势回放 | 模拟器截图与环境 |
| 真机 iPhone | 实际触摸、录屏、Profile | 手感、稳定性、60 FPS 目标 | 真实设备视频、性能记录 |
| 真机 iPad | 手指 + 可用时 Pencil | 多指交织、横屏/窗口变化、笔压路径 | 真实设备视频、性能记录 |
| 人工视觉评审 | 对照 6 组 fixture | 3 层视觉、颜色、惯性、旋涡、留白 | 明确 PASS/FAIL/待改进意见 |

### 9.1 最小自动化测试用例清单

- `testNormalizedCoordinatesRespectAspectRatio`
- `testTouchIDsStayIndependentDuringInterleaving`
- `testCoalescedSampleDeduplication`
- `testZeroLengthStrokeDoesNotGenerateNaN`
- `testVelocityClamp`
- `testFixedStepAt60And120HzHasSamePhysicsTime`
- `testPauseResumeDoesNotAccumulateElapsedWallTime`
- `testClearResetsAllFields`
- `testReplayFixtureUsesStableSeedAndOrdering`
- `testLongDurationDyeConcentrationRemainsBounded`
- `testResizePreservesAspectAndDoesNotStretchCircles`
- `testMissingPencilPressureUsesNeutralValue`
- `testGPUTextureFormatsAndDimensions`
- `testOffscreenCaptureDimensionsAndColorSpace`
- `testLaunchAndDebugControlsAccessibility`

具体名称可随测试框架命名调整，必须保持覆盖意图。XCUITest 不应依赖真实多指合成手势的未公开能力；多指精确轨迹以 Replay Engine 注入模拟层验证，手感以真机人工测试补足。

### 9.2 视觉评审采用“问题分类”，不是笼统评分

每个 Fixture 分别记录：

1. `Continuity`：是否断裂/圆点串/锯齿。
2. `Inertia`：抬手后运动是否自然，反向是否保留历史动力。
3. `Curl`：画圈后是否产生清晰卷曲。
4. `Silk Detail`：细丝是否依附主体而非噪点。
5. `Color`：渐变是否精致，有无白化或脏灰混色。
6. `Negative Space`：是否维持深色留白。
7. `Responsiveness`：触点和视觉是否同频，快速手势是否滞后。
8. `Stability`：长时间使用是否变慢/过热/画面闪烁。

每项只使用 `PASS / NEEDS_TUNING / FAIL / NOT_TESTED`，注明观察、截图/视频证据和预计的修正方向。没有真人视觉验收结果时全局状态为 `READY_FOR_REVIEW`，不是 `PASS`。

---

## 10. 失败分类与优先级

### P0 阻断（立即停止相关阶段）

- 编译失败、无法运行、GPU 初始化失败且无错误提示、完全黑屏/全白屏（非空画布预期）、持续 Crash。
- Shader 输出 NaN/Inf、重大越界、同一纹理未定义并发读写、输入 ID 混乱、Clear 有大量残留。
- 真实触摸明显丢段或帧率长期严重不足，并被描述成“正常体验”。
- Replay 不可复现且没有记录原因；无证据却声称已经在真机测试。

### P1 高优先级（不得宣布 Prototype 合格）

- 画圆无法形成有生命感的旋涡；色彩完全糊成雾；细丝像随机粒子。
- 两指完全不互相作用；流体铺满全屏失去负空间；Bloom 过曝。
- iPad 比例/Resize 明显错误；后台恢复跳动。
- 用户仍认为视觉效果欠缺品质。

### P2 后续增强（可保留为 Known Issues）

- 仅部分型号支持压力/倾角、尚未实现 predicted touches。
- 尚无 120 FPS 调优；尚无完整压力投影。
- 暂未建设正式导出、作品保存或高级调色器（均为明确非目标）。

错误修复优先顺序：**正确性 → 交互连续性 → 主体运动 → 细节品质 → Bloom → 额外功能**。

---

## 11. `docs/PROGRESS.md` 强制模板

每阶段结束后填入下列信息，禁止只写一句“已完成”：

```markdown
## P3 — Velocity & Pigment
- Status: PASS / FAIL / BLOCKED / NOT_TESTED
- Git commit: <commit hash>
- Host / Xcode / SDK: <实际版本>
- Devices: <设备型号、系统或 Simulator UDID>
- Commands executed:
  - `<完整命令>` → exit=<退出码>，log=<完整路径>
- Tests: <通过/失败/跳过数量、xcresult 路径>
- Captures: <真实图像及短视频路径、模拟时间点>
- FPS / GPU: <实测统计；若无，则明确 NOT_MEASURED>
- Visual review: <READY_FOR_REVIEW / PASS / NEEDS_TUNING / FAIL>
- Failures & root cause: <问题、复现、修复或阻塞>
- Open issues: <具体下一步>
- Next stage gate: <是否满足及理由>
```

---

## 12. 最终交付合同（Definition of Done）

Pi 最终必须交付：

1. **可克隆并构建的源码**：原生 iOS/iPadOS App、Xcode 工程/生成配置、Metal shaders、可复现 Scheme。
2. **核心渲染**：速度、颜料、细节三种状态，稳定输运、受限注入、柔光合成；单指与多指均工作。
3. **可控制原型**：暂停、继续、清空、少量 Debug 参数，能选/运行六组 Fixture。
4. **测试**：单测、UI 测试、输入与模拟异常测试、Replay 截图和统计。
5. **视觉证据**：六组 Fixture 的指定关键帧，至少三种真机操作录屏（设备可用时）。
6. **性能证据**：真实 iPhone/iPad 的设备、操作场景、采样方式、帧率分布、GPU 或 Instruments 结果；设备不可用写阻断项。
7. **文档**：`README.md`、`docs/ENVIRONMENT.md`、`docs/PROGRESS.md`、`docs/VISUAL-SPEC.md`、`docs/TEST-REPORT.md`、`docs/PERFORMANCE.md`、`docs/KNOWN-ISSUES.md`、`docs/DECISIONS.md`。
8. **CI**：macOS runner 的构建/测试工作流，日志可追踪；环境不支持的工作项有明确 `BLOCKED` 记录。
9. **工程卫生**：无私钥/账号信息、无随意拷贝素材、无大体积 DerivedData 提交、无明显内存和 GPU 资源泄漏。
10. **最终状态表**：每阶段 PASS/FAIL/BLOCKED，逐条链接证据，绝不模糊成“基本完成”。

### 原型最终只有两种结论

- `ENGINEERING_COMPLETE / AWAITING_VISUAL_ACCEPTANCE`：工程、自动化、可用真机验证完成，但用户尚未明确接受艺术与手感。
- `PROTOTYPE_ACCEPTED`：**工程测试通过 + 目标真机验证通过 + 用户明确确认视觉与手感达到目标**。

如果目标真机暂时缺失，应报告 `ENGINEERING_PARTIAL / DEVICE_VALIDATION_BLOCKED`，继续保留真机门槛，而不是放宽定义。

---

## 13. Pi 的执行与汇报节奏

执行本文件时按下列顺序推进：

1. **先勘察**现有仓库目录/工具链，保留已有成果；如果目标目录存在项目，不得覆盖重建；先检查 Git status、文件和提交记录。
2. 建立 P0 文档和工程；自 P0 起，每阶段都执行并记录 Exit Criteria。
3. P1–P3 以数值正确性、输入稳定为重点；P4 是最关键的**视觉品质闸门**，不能跳过对照和用户审看。
4. P5–P6 做真机和性能验证；没有设备的验证可以记录为 `BLOCKED`，不用停止所有非设备依赖的开发，但**最终不能标记 Accepted**。
5. 每次阶段报告以“实现 / 命令及退出码 / 测试 / 截图视频 / 失败及处理 / 下一步”六部分呈现。
6. 对 `FAIL` 项优先提供可复现的最小测试；不要用重写架构掩盖现有错误。
7. **不要替用户发布 GitHub 仓库、配置签名证书或提交 App Store**，除非以后获得明确授权。

### 初始执行 Prompt（本文件配合 Pi 使用）

> 请阅读仓库中的 `FLOW-PROTOTYPE-01.md` 并把它作为本项目最高优先级的工程与验收规范。先完成 P0 的环境检测、工程初始化、测试壳和文档，不要直接跳到复杂 Shader。必须真实执行命令并保存完整日志、退出码和可用的模拟器截图。每个阶段严格按任务、命令、验收与失败处理执行；不能以编译通过代表完成。若有阶段阻断，写清 `BLOCKED` 和证据，继续做不受阻断影响的部分。实现前检查现有目录与 Git，禁止覆盖已有成果。P4 完成时提供 6 个标准 Gesture Replay 的截图/视频供我审看，未经我确认不要自行宣布艺术视觉验收通过。最终向我汇报每阶段状态及真实证据路径。

---

## 14. 权威参考与核对日期

核对日期：**2026-10-21**。随着 Xcode/SDK 更新，请以 Apple 官方在线文档及本机实际 `xcodebuild -version` 为准；不要把本文记录的版本误认为永久最新版。

- [Apple — Xcode system requirements](https://developer.apple.com/xcode/system-requirements)
- [Apple — MTKView](https://developer.apple.com/documentation/metalkit/mtkview)
- [Apple — MTKViewDelegate](https://developer.apple.com/documentation/metalkit/mtkviewdelegate)
- [Apple — preferredFramesPerSecond](https://developer.apple.com/documentation/metalkit/mtkview/preferredframespersecond)
- [Apple — `framebufferOnly`](https://developer.apple.com/documentation/metalkit/mtkview/framebufferonly)
- [Apple — UIKit touch handling](https://developer.apple.com/documentation/uikit/handling-touches-in-your-view)
- [Apple — coalesced touches](https://developer.apple.com/documentation/uikit/getting-high-fidelity-input-with-coalesced-touches)
- [Apple — predicted touches](https://developer.apple.com/documentation/uikit/minimizing-latency-with-predicted-touches)
- [Apple — handling Apple Pencil](https://developer.apple.com/documentation/uikit/handling-input-from-apple-pencil)
- [Apple — Metal on Simulator](https://developer.apple.com/documentation/metal/developing-metal-apps-that-run-in-simulator)
- [Apple — capturing Metal workload](https://developer.apple.com/documentation/xcode/capturing-a-metal-workload-programmatically)
- [Apple — running tests](https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results)
- [Apple — calculating Metal threadgroup sizes](https://developer.apple.com/documentation/metal/calculating-threadgroup-and-grid-sizes)
- [XcodeGen — official README](https://github.com/yonaskolb/XcodeGen)

---

**本任务书的原则：Flow 的胜负不在页面数量，而在每一次触碰能否生成一段值得凝视的流动。**
