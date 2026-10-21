# AGENTS.md — Flow / Luminous Ink (Prototype 01)

给所有 AI/人类协作者的持久上下文。先读这里，再读 `FLOW-PROTOTYPE-01.md`（**唯一权威验收契约**）。

---

## 1. 这是什么

原生 iOS/iPadOS Metal 触控流动艺术原型：轻触绽放墨迹、拖动牵引流场、画圈成旋涡、多指通过同一流场互相影响、抬手后墨迹继续流动并衰减。

- 语言/框架：Swift 6（严格并发）+ SwiftUI（壳）+ UIKit（触控）+ Metal/MetalKit（渲染）
- 最低部署：iOS/iPadOS 18.0，Universal
- 工程唯一事实源：`project.yml`（XcodeGen），**`Flow.xcodeproj` 不入库、每次重新生成**
- 无任何第三方运行期依赖

## 2. 常用命令

```bash
xcodegen generate --spec project.yml          # 生成工程（改过 project.yml 必须重跑）

export SIM_UDID="<SIM_UDID_IPHONE>"   # iPhone 16 Pro 模拟器
export IPAD_SIM="<SIM_UDID_IPAD>"   # iPad Pro 11 M4 模拟器

./scripts/build.sh                    # 模拟器构建（CODE_SIGNING_ALLOWED=NO）
./scripts/test.sh                     # 单元 + UI 测试（保留 xcresult）
./scripts/host-smoke.sh               # 100+ 项纯 CPU 逻辑检查，无需模拟器
./scripts/replay.sh <fixture>         # 确定性回放 + 原生分辨率 PNG 捕获
./scripts/make-video.sh <fixture>     # 高码率视频（模拟器帧序列）
./scripts/device-video.sh <fixture>   # 高码率视频（真机帧序列）
./scripts/device.sh --list            # 查真机 + 签名身份 + Team ID
./scripts/verify-all.sh               # 端到端：生成→构建→测试→6 回放→host smoke→报告
```

真机（iPad Pro 11" 3rd gen / iPad13,6 / M1，UDID `<DEVICE_UDID>`）：

```bash
xcodebuild -project Flow.xcodeproj -scheme Flow -configuration Debug \
  -destination "platform=iOS,id=<DEVICE_UDID>" \
  -derivedDataPath artifacts/DerivedData -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=<TEAM_ID> CODE_SIGNING_ALLOWED=YES build
xcrun devicectl device install app --device <udid> artifacts/DerivedData/Build/Products/Debug-iphoneos/Flow.app
xcrun devicectl device process launch --terminate-existing --device <udid> --console \
  dev.luminousink.prototype01 --flow-replay spiral --flow-metrics-log
```

## 3. Debug 启动参数（仅 Debug 构建）

```
--flow-replay <fixture>      tap|slow-stroke|fast-swipe|spiral|two-fingers|crossing|four-fingers
--flow-seed <int>            固定噪声种子
--flow-fixed-dt <sec>        固定物理步长（推荐 0.0083333333）
--flow-capture-at a,b,c      额外捕获时刻（模拟秒）
--flow-disable-bloom / --flow-disable-detail
--flow-dump-frames <fps>     按模拟时间导出原生分辨率 PNG 帧序列（视频源）
--flow-metrics-log           每 2 s 打印 fps/P50/P95/P99
--flow-grid 384|512|640      模拟网格短边
--flow-loop-replay           回放结束后自动重放（长时压力测试）
```

## 4. 不可破坏的架构约束（改代码前必读）

1. **A/B 角色按字段独立**：`TextureSet.velRole / pigRole / detRole`。速度与颜料每步翻转，细节不翻转。
   曾经用单一 `role` 导致 composite 读到未注入的副本 → 画面全空。**不要合并成一个 role。**
2. **每个 pass 恒定执行**，无事件时用 `eventCount = 0` 直通。曾经用 `if hasEvents` 跳过来优化，
   造成 A/B 状态错位。
3. **注入 kernel 每个 texel 串行遍历按 `(timestamp, touchID)` 排序的事件表** —— 这样结果与 GPU
   线程调度无关，无需原子。**不要改成并行累加 + 原子**（RG16/R16/RGBA16 不支持，且顺序不定）。
4. **确定性**：捕获在固定步内编码（`takeDueCapture` 在 step 循环里），不按墙面时间决定。
   同一 fixture + 同 seed 两次运行，7 张 PNG 必须字节一致。改回放逻辑后必须复验这一点。
5. **最终合成在原生分辨率执行**（`finishFragment` 逐目标像素）。契约 §5.4 明确禁止把低分辨率图
   放大当成品。**不要在 sim 网格上做 composite 再放大。**
6. **预乘合成只能乘一次 alpha**：`linear = C*a + bg*(1-a)`，其中 `C = premul.rgb / a`。
   曾经写 `mix(bg, a*C, a)` 把 alpha 乘了两次 → 亮度 ∝ a² → 内部压平（“软边印章”）。
7. **上下翻转**：画布原点左上（契约 §5.1），Metal NDC y=+1 是顶部，因此 `fullscreenVertex`
   必须 `uv.y = 1 - uv.y`。曾经漏掉，墨迹与手指上下镜像。
8. **MTKView 委托模式必须自己 `commandBuffer.present(drawable)`**，否则画面从不上屏，
   而窗口底色 `#070A13` 与背景色相同，会伪装成“渲染正常”。
9. **`.inactive` 不暂停**，只有 `.background` 才暂停。模拟器窗口失焦会触发 `.inactive`，
   曾经导致脚本截图/录屏全是静止帧。
10. **布局断言**：`ShaderBridge.assertLayouts()` 要求 `StepParams` 96 B（12×SIMD2）、
    `StrokeEvent` 64 B。改任一结构体必须同步 Swift 与 MSL 两侧并更新 `FlowTests`。
11. 每帧不得创建 `MTLDevice` / `MTLCommandQueue` / pipeline / 全尺寸纹理；小缓冲按步分配是
    有意为之（见 `docs/DECISIONS.md` D4）。

## 5. 已知环境坑（都已在脚本处理）

| 坑 | 说明 |
|---|---|
| Team ID | 证书名括号里的值（`<CERT_NAME_SUFFIX>`）**不是** Team；真正的 Team 是证书 subject 的 **OU**（`<TEAM_ID>`）。脚本自动推导。 |
| 签名 | `project.yml` **不能**全局 `CODE_SIGNING_ALLOWED: NO`，否则真机构建产出未签名 App。模拟器/CI 显式传 `=NO`。 |
| 设备 UDID | 新格式是 `8-16`（`<DEVICE_UDID>`），不是旧的 `8-4-4-4-12`。 |
| 个人签名 | 首次安装需在设备 `设置 → 通用 → VPN 与设备管理` 手动信任；描述文件 **7 天过期**。 |
| 模拟器录屏 | `simctl recordVideo` 对平滑内容只给 ~400 kbps，会把渐变压糊。用 `--flow-dump-frames` + `make-video.sh`（实测 PSNR 99 dB）。 |
| 旧二进制 | `simctl install` 在 App 运行时可能静默保留旧版本。`replay.sh` 已改为 terminate → uninstall → install。 |

## 6. 视觉设计基线（不要随手改）

- 背景 `#070A13`；Aurora 调色板 `#6548DF #C754CE #FB719E #FFC68B`，沿画布 `auroraLinear(t)` 平滑过渡
- 三层：液态主体 + 沿流场丝状细节 + 克制局部柔光；关掉 bloom 必须仍然好看
- tap 是「一次性宽幅爆发 + 极小 top-up」，**不是**每步重复注入（重复会饱和成平顶印章）
- 径向事件用 `softKernel`（长尾渐变），描边用 `gaussian`（保持宽度）
- 覆盖率曲线 `dye * smoothstep(edgeCurve)`：只压制低端尾巴，**不能**用纯 smoothstep（会钳平内部）

## 7. 实测基线（回退判断用）

| 项 | 值 |
|---|---|
| iPad13,6 真机 | 60.0 fps，P50 16.67 ms，P95 16.74 ms，P99 17.6 ms |
| 10 分钟循环（63 次重放） | P95 ≤16.86 ms，P99 ≤18.26 ms，0 崩溃 |
| 模拟网格 384/512/640 | 均 60 fps；640 峰值边缘 +11%（更强结构） |
| 过曝 | 所有 fixture 亮度 >0.9 的像素 0.0–0.2% |
| 确定性 | 同 fixture 两次运行 7 帧 PNG SHA-256 一致 |

## 8. 测试与证据

```bash
swiftc 一次性统计工具都在 /tmp（不入库），需要时可用：
  可见度覆盖率 / 亮度分布 / 边缘能量 / 径向剖面 / ASCII 视图
```

- 单测：`FlowTests/`（Swift Testing）——时钟、归一化、去重、速度上限、受限注入、布局、网格尺寸
- UI：`FlowUITests/`（启动、Debug 控件、fixture 菜单、iPad 旋转、100 次 pause/clear、90 s 持续）
- 证据目录：`docs/screenshots/review/`（精选）、`artifacts/{logs,captures,video,xcresult}/`（本地）
- `artifacts/` 不入库；`docs/screenshots/review/*.png` 入库

## 9. 当前阶段状态

| 阶段 | 状态 |
|---|---|
| P0 环境/工程 | PASS |
| P1 Metal 画布 | PASS |
| P2 触控/Replay | PASS |
| P3 速度场+颜料 | PASS |
| P4 视觉 | **READY_FOR_VISUAL_REVIEW**（需用户人工验收，禁止 AI 自行标 PASS） |
| P5 布局/生命周期 | PARTIAL（真机跑通；真实手指多指、Apple Pencil 待人工） |
| P6 性能 | PASS（iPad 真机）；iPhone 真机 BLOCKED |
| P7 CI | PARTIAL（本地全绿；GitHub 推送需用户明确授权） |

整体：`ENGINEERING_PARTIAL / AWAITING_VISUAL_ACCEPTANCE / DEVICE_VALIDATION_BLOCKED`

## 10. 协作红线

- **不能**用编译成功/单测通过代替“体验达标”；视觉与手感必须用户确认
- **不能**伪造证据；没有设备就写 `BLOCKED`，没测就写 `NOT_MEASURED`
- **不能**未经授权推送 GitHub、配置签名证书、提交商店
- **不能**引入后端/网络/账号/第三方 SDK/第三方美术素材
- 遇到 `FAIL` 先给最小复现，不要用重写架构掩盖
- 改视觉参数必须留 A/B 与前后数值对照（`docs/VISUAL-SPEC.md`）
- 当前 AI 会话**看不到图像**；判断只能靠像素统计与 ASCII 降采样图，视觉结论必须由人给

## 11. 文档地图

| 文件 | 内容 |
|---|---|
| `FLOW-PROTOTYPE-01.md` | 权威契约（阶段、验收、算法、禁止项） |
| `docs/ENVIRONMENT.md` | 机器/Xcode/SDK/设备探测结果 |
| `docs/PROGRESS.md` | 逐阶段状态与命令证据（含所有踩坑记录） |
| `docs/DECISIONS.md` | 架构决策与拒绝的替代方案 |
| `docs/VISUAL-SPEC.md` | 视觉目标 + 实测数值（覆盖率/亮度/清晰度/A-B） |
| `docs/PERFORMANCE.md` | 真机与模拟器实测、网格 A/B、待测清单 |
| `docs/TEST-REPORT.md` | 测试清单与运行记录 |
| `docs/KNOWN-ISSUES.md` | 已知问题、已解决记录、AI 无视觉能力的说明 |
