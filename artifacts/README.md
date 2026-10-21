# artifacts/

暂时性工程产物（默认不提交 Git）：

- `logs/` — build/test/replay 完整原始日志（含退出码）
- `xcresult/` — Xcode 测试结果包
- `captures/` — Replay 离屏 PNG 与 GUI 截图、`.sha256`
- `DerivedData/` — 构建中间产物

代表性证据（小图/短视频）提交到 `docs/screenshots/`。长期保留在本地，报告中引用确切路径。
## 保留策略

`artifacts/` 会被构建脚本反复写入，长期积累可达数 GB。用脚本清理，不要手工删：

```bash
./scripts/clean.sh --dry-run   # 先看会删什么
./scripts/clean.sh             # 默认：删构建缓存/测试包/批量捕获/逐次日志
./scripts/clean.sh --all       # 连保留的真机证据一起删
```

默认保留（文档引用的证据）：
- `captures/device-ipad/`、`captures/ipad*/`：真机与模拟器原生分辨率捕获
- `logs/device-10min.log`、`logs/device-console.log`、`logs/perf-simulator-*.log`、`logs/verify-all-*.log`
- `video/device-*.mp4`：真机渲染视频（同时作为 v0.1.0 发布附件）

自动生成的清单写到 `logs/INVENTORY.md`（不覆盖 `docs/TEST-REPORT.md`，后者是人工维护的）。
