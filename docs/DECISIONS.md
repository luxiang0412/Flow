# DECISIONS — Flow Prototype 01

> 记录已确定的实现决策、待决事项与理由。对应 `FLOW-PROTOTYPE-01.md` 各节。

## D1. 确定性 GPU 注入（§5.5）

- **决策**：注入 kernel（velocity/pigment/detail）采用 **“每 texel 一线程，串行遍历事件表”**。
  事件先按 `(timestamp, touchID)` 升序在 CPU 排好；同一 texel 的累加顺序对所有线程一致，
  因此结果与 GPU 线程调度顺序无关，无需原子、无读改写竞争。
- **成本**：典型事件数 ≈ 0–4/步（插值间距 ≤ 0.4×radius），每 texel 遍历量很小。
- **替代**（拒绝）：per-texel atomic 累加（RG16/R16/RGBA16 不支持、且乱序）；单一线程全texel（延迟不可接受）。

## D2. 物理单位与分辨率无关性（§5.1）

- 模拟在归一化 `[0,1]²` 上进行；速度存为 **short-side/秒**；着色器用 `iso=(sx,sy)` 把归一化坐标
  映射到短边物理单位做各向同性采样/输运。短边长 384/512/640 texel，长边按画布比例推导、上限 1024。
- **推论**：旋转或缩放只改变 texel 数，不改 stored velocity ⇒ resize 无需速度换算，
  仅需内容重采样（`resampleState`：新画布每个 texel 的短边物理坐标 → 旧画布归一化坐标；
  越界区域置零 = 新区域留空，不做非等比拉伸）。

## D3. 边界策略（§5.9）

- 初版：所有采样 `clamp_to_edge`；流体触边时默认“法向分量随接近边缘衰减”由 advect 反向
  采样近边缘 clamp 天然近似 + `dampVelocity` 上限共同抑制反弹。不引入显式压力投影（§5.8 触发条件未满足）。

## D4. per-step 小缓冲分配（§3.3）

- 每固定步为一个 compute pass 组（≤7 个 kernel）。为**避免同一次 command buffer 内多条
  dispatch 之间 and 跨 command buffer 的在途写竞争**，每步为 params/events 新建几 KB 的
  `storageModeShared` 小缓冲。device/queue/pipeline/全尺寸纹理仍是一次建好。
  - 备选（拒绝）：固定环形缓冲池 —— 无法在 CPU 侧证明“上一 command buffer 已消费”；
    增加复杂性与并发错误面。小缓冲分配量级极低（Debug 阶段记录于本文件，后续可优化）。

## D5. 色彩 / 伽马（§4.1 / §5.4）

- 模拟与合成全程 **线性 sRGB**；调色板 `Aurora` 在 CPU 侧 sRGB→linear。
- 最终 pass 负责 linear→sRGB 编码，输出到 `bgra8Unorm` drawable / capture（避免双重伽马）。
- Background `#070A13` 直接用其线性值；capture PNG 以 sRGB 色彩空间写入（`CGColorSpace.sRGB`）。

## D6. 触控 ID 生命周期（§5.2）

- `UITouch.hashValue` 作为会话内稳定 ID（每次 begin 分配，end/cancel 释放；不持久化内存地址）。
  记录为已知限制：UIKit 可能在同一次交互内复用 UITouch 实例，生成的 ID 仍稳定即可；
  不用于跨 fixture 持久身份。

## D7. 压力与预测（§5.2）

- Pencil pressure 仅在 `estimatedPropertiesExpectingUpdates` 不含 `.force` 且 `force ≥ 0` 时使用，
  否则用中性值 `0.5`（不做捏造）。预测触点（`predictedTouches`）**不进入永久模拟状态**。

## D8. Swift 6 并发纪律（§3.3）

- 渲染线程 = MTKView display-link 线程（≈ 主 run loop）。`FlowRenderer` / `FlowMetalView` /
  `InputNormalizer` 均为**同一序列执行上下文**；跨 SwiftUI 边界的共享状态用
  `nonisolated(unsafe)` + 文档化单调用者规则（`MetricsStore`、`TouchInputBuffer`、错误记录器）。
- 该选择让 MTKViewDelegate 回调在 Swift 6 严格并发下可编译，而不引入 actor 跳转的每帧开销。
- 单线程共享对象（`TouchInputBuffer`/`MetricsStore`/`ErrorStatus`/`FrameMetrics`/`ReplayEngine`）
  标记为 `@unchecked Sendable` —— 这是对“单调用者 + 主线程纪律”的显式承诺（文档化于本文件），
  避免在 SwiftUI(MainActor) 与渲染回调之间传递非 Sendable 引用的编译告警。
  **待决**：若后续并入后台渲染线程，改回显式队列/actor 隔离。

## D9. Replay 与捕获（§6）

- Replay 用 `SimulationClock` 固定步进（`--flow-fixed-dt`），墙面时间只决定“每秒执行多少步”
  的节奏（上限 3/frame）；捕获在**绝对模拟时刻**触发，与帧率无关。
- 捕获渲染到独立 `bgra8Unorm` capture 纹理 → blit 到 shared buffer → CPU 读回 PNG；
  不读取 `currentDrawable`（§6.4）。

## D10. 尚未实现 / 延期（§1.3、§5.8）

- 无压力投影 / curl enhancement；无 predicted-touch 驱动视觉；无 120 FPS 调优；无作品导出/相册/分享。
- `detail` 使用“轨迹对齐带 + 固定种子缓慢扰动”实现（单一方案，未做双方案 A/B；若真机视觉
  不满足丝状标准，再按 §5.7 并行试验受限制器的高阶输运并记录前后对照）。

## D11. 工程文件策略

- `Flow.xcodeproj` 不入库；任何 clone+CI 都以 `xcodegen generate --spec project.yml` 重建。
  记录 `xcodegen --version`（当前 2.46.0）。
- `Tests/Fixtures/*.json` 同时编入 App target（Debug Replay UI/CLI）与 FlowTests（解析测试）。
- `.gitignore` 排除 DerivedData/xcresult/大体积 capture；阶段代表性小图入 `docs/screenshots/`。

## D13. 模拟网格长边上限（§5.4 微调，实测依据）

- 规格建议长边上限 1024；按 512 短边 + iPhone 竖屏比例（1170×2532 ≈ 2.16:1）会把网格裁成
  512×1024（长宽比 0.5 vs 目标 0.462，约 8% 比例失真），违反 §4.1「不准非等比拉伸」的更强约束。
- **决策**：上限提高到 **2048**（此时 512×1107 / 640×1382 均不触发裁剪）。单位宽高纹理内存仍然很小；
  若无性能问题，此上限不再下调。
- 证据：`testResizePreservesAspectAndDoesNotStretchCircles` 用 1170×2532 竖屏实测捕获并断言 <0.02。

## D12. 外部依赖

- 无第三方运行期 SDK/美术素材；仅用 Apple 框架。`scripts/generate-fixtures.py` 为确定性生成器（已入库）。