# KNOWN-ISSUES — Flow Prototype 01

> 记录每个可复现问题：现象、复现、根因、修复/绕过、状态。

## 1. 完整 Xcode 未安装（环境阻塞）

- **现象**：`xcodebuild`/`simctl`/Metal Debugger 不可用；iOS 构建无法验证。
- **复现**：`xcode-select -p` → `/Library/Developer/CommandLineTools`。
- **根因**：本机仅安装了 Command Line Tools。
- **修复路径**：安装 Xcode 27.1（App Store / `xcodes install 27.1`，需 Apple ID），
  `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`。
- **状态**：BLOCKED（第 1 优先）。

## 2. GitHub 仓库访问被代理阻断

- **现象**：`git clone https://github.com/...` 需要凭据（GitHub-Babel 代理）。
- **影响**：brew tap（如 homebrew-xcodes）需走镜像 `brewforge/chinese`；CI 的
  actions/checkout 不受影响（由 Runner 环境处理）。无项目级修复必要。

## 3. 触控 ID 使用 `UITouch.hashValue`（设计内已知限制）

- **备注**：会话内稳定，不持久化；disabled/Pencil 混用时 hash 可能变化。已接受（DECISIONS.md D6）；
  若出现幽灵触点，会在 P2 阶段用自定义 ID 分配器替换并记录前后测试。

## 4. 未验证项（工具链/设备就绪前，不视为通过）

- Swift 6 严格并发编译通过与否：**未验证**（无编译器）；已按保守策略编码，保留后续编译迭代。
- Metal shader 布局断言 `ShaderBridge.assertLayouts()`：**未验证**（编译时运行）。
- `resampleState` resize 内容保持、`statsScan` 回读：**未验证**（需 GPU 环境）。
- 真机手写/画笔/Pencil 压力与倾角路径：**未验证**（P5，需设备）。

## 5. 画质待评审项（P4 视觉闸门）

- detail 只实现了一种方案；若丝状质感不足，将按 §5.7 试验“受限制器的高阶输运”并记录 A/B。
- Bloom 阈值/强度初始假设；`--flow-disable-bloom` A/B 后定参。

## 6. 已知性能/内存关注点

- 每固定步分配小缓冲（DECISIONS.md D4）。规模极小，但长跑可加环形池；先观察仪器数据再决定。
- `statsScan` 每 30 帧全网格扫描，仅测试时开启，避免 Release 路径开销。
## 0. Pi 没有图像视觉能力（重要，影响验收方式）

本机 harness 会把 PNG 作为附件传给模型，但当前模型返回
`[Current model does not support images. The image will be omitted from this request.]`
——**Pi 全程看不到画面**。所有“视觉”判断均来自：

1. 像素统计（覆盖率/亮度分布/边缘能量/径向剖面）；
2. 把图像降采样成 **ASCII 亮度图**后由文本通道阅读（分辨率很低，只能看大致形状与梯度）；
3. A/B 数值差异。

因此：**美术质量、丝状质感、手感、颜色喜好只能由用户判断**。Pi 能自证的只有
「结构上是否存在梯度/硬边/环带/过曝/镜像/尺寸错误」。契约 §13 的视觉闸门不能由 Pi 代签。

## 7. 视觉调优遗留项（P4，非正确性缺陷）

- **tap 尺寸**：当前绽放直径约 22% 短边（视频实测可见面积 3.3%）。若用户认为偏小，
  调 `tapRadiusScale`（4.2）与 `tapDye`（1.0），每次改动需同时看剖面梯度是否被压平。
- **真机手感未验证**：跟手性、迟滞、抬手后惯性观感只能在真机判断（BLOCKED）。
- **tap 仍偏“规则”**：ASCII 视图下已从「同心环完美圆盘」改善为带角向起伏的圆斑
  （`wobble()` 三个低频谐波），但**内部没有触须状/丝状结构**；是否足够“像墨”需人眼定。
  若需更强有机感，下一步是对径向扰动引入更多谐波或做多子斑叠加（会牺牲一点可控性）。
- **detail 观感未经人眼确认**：目前仅能用亮度统计与 A/B 差异间接证明其存在，
  是否像“丝”而不是“雾”必须由用户审看（`spiral-ab.png`）。
- **120 FPS 未调优**：`preferredFramesPerSecond` 固定 60。

### 已解决（保留记录）
- 色带偏细 → 半径 2.5%→3.0%、动量 6.0→2.2（轮 1）。
- Bloom 永不触发 → 注入亮度不足 + 阈值 0.7；改为 Aurora 空间渐变 + 阈值 0.18（轮 1）。
- 画面上下翻转 → `fullscreenVertex` uv.y 未翻转（轮 2）。
- tap 为平顶圆形印章 → 移除逐步累积饱和，改一次性爆发 + 软核（轮 2）。
- 回放非确定 → 捕获改为在固定步内编码（轮 1）。
