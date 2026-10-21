# PERFORMANCE — Flow Prototype 01

> **当前状态：DEVICE_MEASURED（iPad Pro 11" 第3代 / iPad13,6 / M1）**
> 已取得真机实测；iPhone 真机仍未测（BLOCKED，无 iPhone 设备）。
> 模拟器数据单独列在下方，不与真机混淆。

## 测量方法（计划）

- **FPS**：`FrameMetrics` 记录帧间隔环（P50/P95），Debug Overlay 每秒发布实测值（不含 `preferredFramesPerSecond` 掩耳盗铃）。
- **CPU 编码时间**：每帧 `draw(in:)` 内计时（`lastFrameEncodeMs`）。
- **GPU pass 时间**：真机用 Instruments（Metal System Trace / GPU counters）或
  `MTLCaptureManager` 保存 `.gputrace`（Debug 构建），按 pass 记录。模拟器数值**不作真机结论**。
- **模拟网格 A/B**：384 / 512 / 640 短边对照；Bloom on/off；记录 P50/P95/P99。
- **长期**：连续交互 ≥10 min、100 次 pause/clear/resume、横竖屏、后台恢复、低内存模拟。
- **正确性**：`statsScan` Debug readback 输出 NaN/Inf 计数及 max alpha/speed（每 30 帧，启用在 Show Metrics 时）。

## 硬指标（§6.6 表格的取证方式）

| 指标 | 取证 |
|---|---|
| 60 FPS 目标 | 真机帧间隔统计（P50/P95），非模拟器 |
| 帧预算 ~16.67 ms | P50/P95/P99 完整统计 |
| 主渲染 ≤8–10 ms（争取） | 真机 GPU trace |
| 响应性 | 真机高帧率视频/观测；快速划动无滞影 |
| 稳定性 | 10 min 日志 + 采样统计 |
| Clear/Pause 正确性 | 自动化测试 + 截图 |
| 视觉 | 用户评审（见 VISUAL-SPEC） |

## 真机实测 — iPad Pro 11"（第 3 代, iPad13,6, M1）

设备信息：`iPad Pro (11-inch) (3rd generation)`，UDID `<DEVICE_UDID>`，
iOS Developer Mode 已启用，团队 `<TEAM_ID>`（Personal Team）。

命令：
```bash
xcodebuild -project Flow.xcodeproj -scheme Flow -configuration Debug \
  -destination "platform=iOS,id=<DEVICE_UDID>" \
  -derivedDataPath artifacts/DerivedData -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=<TEAM_ID> CODE_SIGNING_ALLOWED=YES build
xcrun devicectl device install app --device <udid> .../Flow.app
xcrun devicectl device process launch --device <udid> --console \
  dev.luminousink.prototype01 --flow-replay spiral --flow-metrics-log
```

| 指标 | 实测值（触控结束后 20 s 稳态） |
|---|---|
| drawable | 1668 × 2388（原生） |
| 模拟网格 | 512 × 733 |
| FPS | **60.0** |
| P50 帧间隔 | **16.67 ms** |
| P95 | **16.74 – 16.80 ms** |
| P99 | **17.3 – 17.7 ms** |
| 启动首帧抖动 | P99 31.16 ms（仅第一秒，随后回落） |
| 每帧物理步 | 2（= 120 Hz 物理 / 60 Hz 显示，实时） |

原始日志：`artifacts/logs/device-console.log`（单次）、`artifacts/logs/device-10min.log`（10 分钟循环压力）。

真机渲染产物核验（`artifacts/captures/device-ipad/spiral_3.20.png`，1668×2388）：

| 指标 | 真机 iPad | 模拟器 iPad | 差值 |
|---|---|---|---|
| 可见 >0.10 / >0.20 / >0.35 | 12.5% / 6.5% / 3.3% | 10.5% / 6.3% / 3.2% | ≤2pp |
| 平均亮度 | 0.157 | 0.163 | 0.006 |
| 最大亮度 | 0.893 | 0.905 | 0.012 |
| 过曝 >0.9 | 0.0% | 0.0% | 一致 |
| 边缘能量 / 峰值 | 0.0072 / 0.343 | 0.0070 / 0.343 | ≈0 |

→ **真机与模拟器渲染结果在同一量级**，说明视觉行为不依赖模拟器转换层。
衰减也正确：t=11.20 s 时最大亮度降到 0.145。

### 真机 10 分钟循环压力测试

命令：
```bash
xcrun devicectl device process launch --device <udid> --console \
  dev.luminousink.prototype01 --flow-replay spiral --flow-loop-replay --flow-metrics-log
```

| 项 | 结果 |
|---|---|
| 时长 | 10 分钟连续（`--flow-loop-replay` 自动重放 63 次） |
| 采样点 | 319 个（每 2 s） |
| FPS | 中位 60.0，最大 60.0（最小值 0.0 为首帧前的那一条） |
| P95 | 中位 **16.74 ms**，最差 **16.86 ms** |
| P99 | 中位 **17.63 ms**，最差 **18.26 ms** |
| 首尾对比 | P95 16.75 → 16.75；P99 17.44 → 18.19（+0.75 ms，约 4%） |
| 崩溃 / fatal | **0** |

日志：`artifacts/logs/device-10min.log`。

真机视频（契约 §6.4 要求的真实设备素材，来自 iPad GPU 的确定性帧序列导出，
**不是**模拟器素材；也非屏幕录制，已在文件名与文档中标注）：

- `artifacts/video/device-spiral.mp4`（1668×2388，171 帧，1.9 Mbps）
- `artifacts/video/device-slow-stroke.mp4`（170 帧，2.6 Mbps）
- `artifacts/video/device-two-fingers.mp4`（161 帧，1.7 Mbps）

视频帧统计与真机捕获一致（t=3.0 s：可见 11.7% vs 12.5%，边缘 0.0069 vs 0.0072）。

### 网格分辨率 × Bloom 的 A/B（真机 iPad13,6）

命令（`--flow-grid` 为新增的 Debug 参数）：
```bash
xcrun devicectl device process launch --terminate-existing --device <udid> --console \
  dev.luminousink.prototype01 --flow-replay spiral --flow-metrics-log --flow-grid {384|512|640} \
  [--flow-disable-bloom]
```

| 配置 | 网格 | FPS | P50 | P95 | P99（6 采样均值） |
|---|---|---|---|---|---|
| 384 + bloom | 384×549 | 60.0 | 16.67 | 16.73 | 18.63 |
| 512 + bloom | 512×733 | 60.0 | 16.67 | 16.75 | 19.60 |
| **640 + bloom** | 640×916 | 60.0 | 16.67 | **16.75** | **18.23** |
| 512 + no bloom | 512×733 | 60.0 | 16.67 | 16.75 | 18.28 |

画质对照（同为原生 1668×2388 捕获，spiral 触尾）：

| 网格 | 平均边缘能量 | 峰值边缘 | 可见 >0.10 |
|---|---|---|---|
| 512 | 0.0072 | 0.343 | 12.5% |
| **640** | **0.0074** | **0.382（+11%）** | 11.7% |

结论：
- 在这台 iPad（M1）上 **384/512/640 都保持 60 fps**，P95 几乎相同；差异只在 P99 尾部，
  且 640 的 P99 反而更低 → 网格不是当前瓶颈。
- 640 的结构锐度有可见提升（峰值边缘 +11%），内存代价可忽略。
- **默认仍保持 512**（契约 §5.4 的基线；对未测试的更旧设备更保守）。
  在 iPad13,6 及更新设备上可用 `--flow-grid 640` 获得更好细节。
- Bloom 开关对帧率影响在噪声范围（P95 相同，P99 18.28 vs 19.60 差异不显著）。

## 模拟器实测（2026-10-21，`--flow-metrics-log`）

命令：
```bash
xcrun simctl launch <udid> dev.luminousink.prototype01 --flow-replay spiral --flow-metrics-log
xcrun simctl spawn <udid> log show --last 1m --predicate 'process == "Flow"' | grep perf
```
原始日志：`artifacts/logs/perf-simulator-iphone.log`、`perf-simulator-ipad.log`。

| 设备（模拟器） | drawable | 模拟网格 | FPS | P50 | P95 | P99 | 每帧物理步 |
|---|---|---|---|---|---|---|---|
| iPhone 16 Pro | 1206×2622 | 512×1113 | 60.0 | 16.67 ms | 16.70 ms | 16.74 ms | 2 |
| iPad Pro 11 (M4) | 1668×2420 | 512×742 | 60.0 | 16.66 ms | 16.70 ms | 16.72 ms | 2 |

观察：
- 两台设备都**贴着 vsync**（P50 ≈ 16.67 ms = 60 Hz 一帧），P95/P99 抖动 < 0.1 ms。
- 网格按画布比例推导：iPad 竖屏 1668/2420 = 0.689 → 512/0.689 = 743 ≈ 742 ✓ 未被拉伸。
- 每帧 2 步 = 实时（120 Hz 物理 / 60 Hz 显示）。

**不能由这些数字得出的结论**（必须真机）：
- 真实 GPU 负载与 pass 级耗时（模拟器 GPU 是宿主 Mac 的转换层）。
- 真机填充率/带宽瓶颈、发热与降频、120 Hz 设备上的表现。
- 触控到上屏的端到端延迟。

## 待真机执行的测量清单（P6）

1. Instruments（Metal System Trace / GPU counters）逐 pass 耗时。
2. `MTLCaptureManager` 保存 `.gputrace`（Debug 构建）。
3. 384 / 512 / 640 网格 × Bloom on/off 的 A/B。
4. 连续交互 ≥10 min + 100 次 pause/clear/resume（模拟器侧已通过，见 TEST-REPORT）。
5. 120 FPS 可选探索（当前 `preferredFramesPerSecond = 60`）。

## 环境依赖

- Instruments 模板名以真实 `xcrun xctrace list templates` 为准（不得臆造）。
- 性能不与模拟器数据混写；真机缺位时全列 `NOT_MEASURED` / `BLOCKED`。