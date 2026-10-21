# TEST-REPORT — Flow Prototype 01

> 本文件是**人工维护**的测试报告（实测数字、证据路径、结论）。
> 自动生成的 artifacts 清单在 `artifacts/logs/INVENTORY.md`（git-ignored），不会覆盖本文。
>
> 最后更新：2026-10-21

## 1. 环境

| 项 | 本机 | CI runner |
|---|---|---|
| Xcode | 27.1 (27A9275) | 16.4 (16F6) |
| iOS SDK | 27.1 | 18.5 |
| 模拟器运行时 | iOS 18.0 / 18.2 / 18.6 / 26.2 | 随 runner |
| 真机 | iPad Pro 11" 第3代（M1 / iPad13,6） | — |

## 2. 自动化测试

### 2.1 单元测试（Swift Testing，`FlowTests/`）

运行：`xcodebuild -only-testing:FlowTests test` → **23 tests / 4 suites 全部通过**。

| 套件 | 覆盖 |
|---|---|
| `ConfigAndClockTests` | 参数区间符合契约、tap 与描边参数相互独立、Flow 滑条映射、60/120 Hz 下物理时间一致、暂停不累积墙钟、过载截断陈旧时间 |
| `InputNormalizerTests` | 归一化坐标与宽高比、多指 ID 独立、coalesced 去重、零长度不产生 NaN、输入速度上限、缺失 Pencil 压力取中性值、插值密度受半径约束 |
| `ReplayAndFluidTests` | fixture 稳定种子与排序、边界时刻取样、cancel 触点映射、受限注入不溢出 alpha、阻尼公式、advect 边界钳制、Resize 不改变宽高比 |
| `TextureAndCaptureTests` | Swift↔Metal 结构布局（96 B / 64 B）、GPU 纹理格式与尺寸、离屏 PNG 尺寸与色彩空间、网格比例推导与长边上限 |

### 2.2 UI 测试（XCUITest，`FlowUITests/`）

运行：`xcodebuild -only-testing:FlowUITests test` → **10 tests 全部通过**（iPhone 16 Pro 模拟器）。

| 套件 | 用例 | 说明 |
|---|---|---|
| `FlowUITests` | 启动与画布可访问性、Debug 控件可访问性、fixture 菜单、CLI Replay 启动、模拟器截图附件 | 5 |
| `LayoutTests` | 旋转后画布存活、前后台往返、横屏 Debug 面板可达 | 3（iPad 模拟器） |
| `StabilityTests` | 100 次 pause/clear/resume（46 s）、90 s 持续拖拽交互（94 s） | 2 |

### 2.3 宿主 CPU 冒烟（`scripts/host-smoke.sh`）

无需 Xcode/iOS SDK，直接编译纯逻辑模块执行：**102 项检查全部通过**（时钟、归一化、去重、速度上限、受限注入数学、阻尼公式、advect 钳制、布局断言、7 个 fixture 的确定性、网格尺寸）。

### 2.4 端到端（`scripts/verify-all.sh`）

`xcodegen generate` → `build` → `test` → 6 组 fixture 回放 → `host-smoke` → 生成清单，**全部退出码 0**。

## 3. 真机测试（iPad Pro 11" / M1 / iPad13,6）

| 项 | 结果 | 证据 |
|---|---|---|
| 构建（自动签名，Personal Team） | **BUILD SUCCEEDED** | `artifacts/logs/` |
| 安装 / 启动 | 成功（`devicectl`） | — |
| 渲染分辨率 | 原生 drawable 1668×2388 | `artifacts/captures/device-ipad/` |
| 稳态帧率 | **60.0 fps**，P50 16.67 ms / P95 16.74 ms / P99 17.6 ms | `artifacts/logs/device-console.log` |
| 10 分钟循环回放（63 次重放，319 采样） | P95 中位 16.74 / 最差 16.86 ms；P99 中位 17.63 / 最差 18.26 ms；**0 崩溃**；无明显恶化趋势 | `artifacts/logs/device-10min.log` |
| 真机画质 vs 模拟器 | 可见度 12.5% vs 10.5%；最大亮度 0.893 vs 0.905；过曝均为 0% | `docs/VISUAL-SPEC.md` |
| 真机渲染视频 | 3 段（1668×2388，来自设备 GPU 的确定性帧序列） | `artifacts/video/device-*.mp4`，亦作为 v0.1.0 发布附件 |

## 4. 性能（模拟器，仅供参考）

| 设备（模拟器） | 网格 | FPS | P50 | P95 | P99 |
|---|---|---|---|---|---|
| iPhone 16 Pro | 512×1113 | 60.0 | 16.67 | 16.70 | 16.74 |
| iPad Pro 11 (M4) | 512×742 | 60.0 | 16.66 | 16.70 | 16.72 |

模拟器数值**不可**当作设备性能结论（契约 §9）。

## 5. 确定性验证

同一 fixture（`spiral`）+ 同一种子连续回放两次，7 张原生分辨率 PNG 的 **SHA-256 全部一致**；
捕获时刻固定为触尾 / +0.5 s / +2 s / +8 s（按模拟时间，与帧率无关）。
`--flow-dump-frames` 导出的帧序列同样逐帧可复现。

## 6. 画质客观指标（非人眼判断）

六组 fixture 峰值帧（原生分辨率捕获）：

| Fixture | 可见 >0.10 | >0.20 | >0.35 | 最大亮度 | 过曝 >0.9 |
|---|---|---|---|---|---|
| tap | 1.7% | 1.4% | 1.0% | 0.672 | 0.0% |
| slow-stroke | 12.5% | 10.5% | 5.5% | 0.810 | 0.0% |
| fast-swipe | 5.9% | 1.8% | 0.6% | 0.733 | 0.0% |
| spiral | 6.0% | 2.6% | 1.6% | 0.922 | 0.2% |
| two-fingers | 10.4% | 7.0% | 1.3% | 0.483 | 0.0% |
| crossing | 19.6% | 15.0% | 6.2% | 0.585 | 0.0% |

阈值间明显分离 = 存在真实亮度梯度；过曝可忽略。细节见 `docs/VISUAL-SPEC.md`。

## 7. CI（GitHub Actions）

仓库 <https://github.com/luxiang0412/Flow>，`.github/workflows/ci.yml`，`runs-on: macos-15`（Xcode 16.4）。

流程：`xcodegen generate` → `xcodebuild build` → `xcodebuild test`（23 单测 + 10 UI），
失败时收集模拟器 `.ips` 崩溃报告与 xcresult 摘要到 artifact（保留 3 天）。

最近一次结果：**success**。CI 抓到并修复的 3 个真实缺陷记录在 `docs/PROGRESS.md` 的 P7 章节
（其中 1 个是 Metal 回调闭包继承 `@MainActor` 导致的 SIGTRAP 崩溃，本机工具链不报错）。

## 8. 未覆盖 / 未验证

| 项 | 原因 |
|---|---|
| 真实手指多指手感 | 回放不经过 UIKit 触摸栈，需人工在设备上操作 |
| Apple Pencil 压力/倾角 | 需要兼容的 Pencil 硬件 |
| iPhone 真机 | 无设备 |
| GPU 逐 pass 耗时 | 需 Instruments / Metal Debugger 图形界面操作 |
| 120 Hz 表现 | 未调优 |
| 美术质量与手感 | **必须由人判断**；AI 会话看不到图像（见 `docs/KNOWN-ISSUES.md` §0） |
