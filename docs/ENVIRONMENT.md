# ENVIRONMENT — Flow Prototype 01 (regenerated './scripts/env.sh')

> Regeneration overwrites a previously saved snapshot. Keep the record
> that matches any reported build/test results.

### 2026-10-21T03:53:37Z

$ sw_vers
  | ProductName:		macOS
  | ProductVersion:		27.2
  | BuildVersion:		26B5091g
  [exit=0]

$ uname -m
  | arm64
  [exit=0]

$ xcode-select -p
  | /Applications/Xcode-27.1.0.app/Contents/Developer
  [exit=0]

$ xcodebuild -version
  | Xcode 27.1
  | Build version 27A9275
  [exit=0]

$ xcrun swift --version
  | swift-driver version: 1.168.6 Apple Swift version 6.4 (swiftlang-6.4.0.34.1 clang-2100.3.34.1)
  | Target: arm64-apple-macosx27.2.0
  [exit=0]

$ xcrun simctl list runtimes
  | == Runtimes ==
  | iOS 18.0 (18.0 - 22A3351) - com.apple.CoreSimulator.SimRuntime.iOS-18-0
  | iOS 18.2 (18.2 - 22C150) - com.apple.CoreSimulator.SimRuntime.iOS-18-2
  | iOS 18.6 (18.6 - 22G86) - com.apple.CoreSimulator.SimRuntime.iOS-18-6
  | iOS 26.2 (26.2 - 23C54) - com.apple.CoreSimulator.SimRuntime.iOS-26-2
  [exit=0]

$ xcrun simctl list devices available
  | == Devices ==
  | -- iOS 18.0 --
  |     iPhone 16 Pro (<SIM_UDID_IPHONE>) (Shutdown) 
  |     iPhone 16 Pro Max (1F15D97E-E6AB-45CA-941D-90CB4D0AA277) (Shutdown) 
  |     iPhone 16 (6072CBE5-4442-4B3E-8F0D-C3A6D92363D1) (Shutdown) 
  |     iPhone 16 Plus (79639A65-12ED-4594-924F-9A59D5E4E362) (Shutdown) 
  |     iPhone SE (3rd generation) (C02AE89E-FFB8-42A2-AEC2-6F2DE4F80D90) (Shutdown) 
  |     iPad Pro 11-inch (M4) (<SIM_UDID_IPAD>) (Shutdown) 
  |     iPad Pro 13-inch (M4) (5D4995E2-9907-4EED-B394-F5168DDF433C) (Shutdown) 
  |     iPad Air 11-inch (M2) (BA598CE2-E941-467C-9B23-8C6F9B6A2BC4) (Shutdown) 
  |     iPad Air 13-inch (M2) (5FA2EE5F-2D28-49F9-BDE8-A16954F6DE14) (Shutdown) 
  |     iPad (10th generation) (9741415B-6E07-45E9-81AA-C7ABB26358DB) (Shutdown) 
  |     iPad mini (6th generation) (E92DC404-41EA-4F66-9E58-1E0C7B4CB0A6) (Shutdown) 
  | -- iOS 18.2 --
  |     iPhone 16 Pro (9D74FC68-9336-49B6-BDBE-20AC44CC14F9) (Shutdown) 
  |     iPhone 16 Pro Max (56EAE262-1BE6-4F9B-84A6-360E9C44473F) (Shutdown) 
  |     iPhone 16 (A6C94279-FDFF-4BF2-B696-CF70D424AA8B) (Shutdown) 
  |     iPhone 16 Plus (76DFE508-1187-483E-BD9D-67586B83D82B) (Shutdown) 
  |     iPhone SE (3rd generation) (6019BC14-73D9-4CFF-A585-D9F39A6B96F7) (Shutdown) 
  |     iPad Pro 11-inch (M4) (51A21265-4D43-4E8E-8B79-C97982BF7F69) (Shutdown) 
  |     iPad Pro 13-inch (M4) (8D95BD4C-C871-4BC6-905D-0A50F786B616) (Shutdown) 
  |     iPad Air 11-inch (M2) (65EAE51A-620C-4AEC-B4CF-B0FB4F63E1EE) (Shutdown) 
  |     iPad Air 13-inch (M2) (AB551652-304A-4E73-AF06-29B7F23D36CC) (Shutdown) 
  |     iPad mini (A17 Pro) (CA0ECD66-DD9C-4B95-9BE8-B87ECAAF0958) (Shutdown) 
  |     iPad (10th generation) (A56FFFAC-BF43-4406-8772-CBFE67DECF97) (Shutdown) 
  | -- iOS 18.6 --
  |     iPhone 16 Pro (81062B18-3A36-4574-8D41-1F3E0461CE45) (Shutdown) 
  |     iPhone 16 Pro Max (072922C5-D69D-44F4-9851-4B59FB296B3D) (Shutdown) 
  |     iPhone 16e (8F180535-A4C9-443F-A37A-7A481BC98C7A) (Shutdown) 
  |     iPhone 16 (F87AB88E-9FD0-4323-86DF-D6E52451DE6D) (Shutdown) 
  |     iPhone 16 Plus (509B9D25-62B9-4965-A808-3DCCE2E271B8) (Shutdown) 
  |     iPad Pro 11-inch (M4) (1C1F0676-6346-4066-9DA6-9358C02A613D) (Shutdown) 
  |     iPad Pro 13-inch (M4) (FF6340A5-856B-46C9-A9AD-0D2D15C50761) (Shutdown) 
  |     iPad mini (A17 Pro) (61C6BCC6-6F12-4868-8C91-E9888D8EC787) (Shutdown) 
  |     iPad (A16) (C8C62277-6A95-49EC-B7A9-7A842C09D420) (Shutdown) 
  |     iPad Air 13-inch (M3) (87A551A7-0996-4562-8FCB-090EE67E293B) (Shutdown) 
  |     iPad Air 11-inch (M3) (70B238EA-82C6-45FD-8E3A-44459543F0BA) (Shutdown) 
  | -- iOS 26.2 --
  |     iPhone 17 Pro (5A74D3B8-51AB-4A1B-83AB-E8F88C4DC15E) (Shutdown) 
  |     iPhone 17 Pro Max (41036A88-02B9-49CA-9AAD-7191D03763D7) (Shutdown) 
  |     iPhone Air (9B44ED76-85F0-45DE-B2E6-5F245CB1E563) (Shutdown) 
  |     iPhone 17 (20E2CD25-490C-4B65-A7F0-439981011D52) (Shutdown) 
  |     iPhone 16e (D6D71CE8-29C0-41DE-8F85-FC52BB686687) (Shutdown) 
  |     iPad Pro 13-inch (M5) (<SIM_UDID_IPAD2>) (Shutdown) 
  |     iPad Pro 11-inch (M5) (4A061872-8713-45AD-8691-1EA608D0393F) (Shutdown) 
  |     iPad mini (A17 Pro) (CE512ACC-B30B-4011-9C78-793A88CBE17A) (Shutdown) 
  |     iPad (A16) (C9F9AA29-59AA-41B4-B156-1C0B17A1E970) (Shutdown) 
  |     iPad Air 13-inch (M3) (E4186D26-C97D-42AF-9622-4101E079D89F) (Shutdown) 
  |     iPad Air 11-inch (M3) (9F44769C-D256-4ABC-AD9C-3EDF05AACA85) (Shutdown) 
  [exit=0]

$ xcrun xcodebuild -showsdks
  | DriverKit SDKs:
  | 	DriverKit 27.0                	-sdk driverkit27.0
  | 
  | iOS SDKs:
  | 	iOS 27.1                      	-sdk iphoneos27.1
  | 
  | iOS Simulator SDKs:
  | 	Simulator - iOS 27.1          	-sdk iphonesimulator27.1
  | 
  | macOS SDKs:
  | 	macOS 27.0                    	-sdk macosx27.0
  | 	macOS 27.0                    	-sdk macosx27.0
  | 
  | tvOS SDKs:
  | 	tvOS 27.0                     	-sdk appletvos27.0
  | 
  | tvOS Simulator SDKs:
  | 	Simulator - tvOS 27.0         	-sdk appletvsimulator27.0
  | 
  | visionOS SDKs:
  | 	visionOS 27.0                 	-sdk xros27.0
  | 
  | visionOS Simulator SDKs:
  | 	Simulator - visionOS 27.0     	-sdk xrsimulator27.0
  | 
  | watchOS SDKs:
  | 	watchOS 27.0                  	-sdk watchos27.0
  | 
  | watchOS Simulator SDKs:
  | 	Simulator - watchOS 27.0      	-sdk watchsimulator27.0
  | 
  [exit=0]

$ command -v xcodegen || true
  | /opt/homebrew/bin/xcodegen
  [exit=0]

$ xcodegen --version
  | Version: 2.46.0
  [exit=0]

$ command -v xcrun || true
  | /usr/bin/xcrun
  [exit=0]


## 5. 模拟器清理记录（2026-10-21）

用户决定暂停 iOS 开发、仅保留 macOS 开发环境，因此清理了 iOS 模拟器相关数据：

| 对象 | 释放 |
|---|---|
| 44 个模拟器设备（含 App 与数据） | ~4.6 GB |
| 4 个 iOS 模拟器运行时（18.0 / 18.2 / 18.6 / 26.2） | ~20 GB |
| 部分运行时安装镜像（AssetsV2 中被 simctl 一并清理的） | ~8 GB |
| `~/Library/Developer/Xcode/iOS DeviceSupport` | 4.5 GB |
| 全局 `~/Library/Developer/Xcode/DerivedData` | 372 MB |

结果：可用空间 32 GiB → **62 GiB**。

**未能清理的 25 GB**：`/System/Volumes/Data/System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime`
下残留 3 个 `.dmg`（分别 8.4 / 8.5 / 8.0 GB）。这些目录带有 SIP 的 `restricted` 标志，
即使 root 也无法删除（`Operation not permitted`），且 `simctl runtime delete`
的注册表里已无对应条目（`--notUsedSinceDays` 也匹配不到）。可行的处理方式：

1. 交给 macOS 的资产垃圾回收自动清理（通常数周，或在磁盘紧张时触发）；
2. 或在 Xcode → Settings… → Components 中查看是否有残留条目可删；
3. 不建议为此关闭 SIP。

**保留项**：`com_apple_MobileAsset_MetalToolchain`（881 MB，macOS Metal 开发需要）、
Xcode 27.1 本身、签名证书与描述文件。

恢复 iOS 模拟器：
```bash
xcodebuild -downloadPlatform iOS
xcrun simctl create "iPhone 16 Pro" "iPhone 16 Pro" <runtime-id>
```
