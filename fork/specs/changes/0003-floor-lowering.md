# 0003 地板下调至 17763

状态：进行中

## 目标

把分支的最低支持系统从 Windows 10 19041（2004）下调到 17763（Windows 10 1809 / LTSC 2019），使安装器与编译期平台声明一致地接受目标机。

## 背景

上游以 19041 为地板是明确决策（CHANGELOG 1.5.6 记录该次下调），并由安装器 MinVersion、csproj 平台属性、应用清单、两个探针脚本与一份契约测试共同钉住。清点结论为 12 处常量加一处契约测试。

底层可行性已具备：Windows App SDK 2.x 的官方支持矩阵包含 Win10 1809，且载荷以 self-contained 方式随包私有部署，不依赖目标机预装运行时。

## 本轮修改点

| 序号 | 文件 | 位置 | 现值改目标值 |
|---|---|---|---|
| 1 | installer/DeskBox.iss | MinVersion | 10.0.19041 → 10.0.17763 |
| 2 | installer/DeskBox.arm64.iss | MinVersion | 10.0.19041 → 10.0.17763 |
| 3 | src/DeskBox/DeskBox.csproj | SupportedOSPlatformVersion | 10.0.19041.0 → 10.0.17763.0 |
| 4 | src/DeskBox/DeskBox.csproj | TargetPlatformMinVersion | 10.0.19041.0 → 10.0.17763.0 |
| 5 | src/DeskBox.Updater/DeskBox.Updater.csproj | SupportedOSPlatformVersion | 10.0.19041.0 → 10.0.17763.0 |
| 6 | tests/DeskBox.Tests/DeskBox.Tests.csproj | SupportedOSPlatformVersion | 10.0.19041.0 → 10.0.17763.0 |
| 7 | tests/DeskBox.NotificationActivationProbe/DeskBox.NotificationActivationProbe.csproj | SupportedOSPlatformVersion | 10.0.19041.0 → 10.0.17763.0 |
| 8 | src/DeskBox/Package.appxmanifest | MinVersion | 10.0.19041.0 → 10.0.17763.0 |
| 9 | scripts/Test-StoreStartupTaskLifecycle.ps1 | 探针清单 MinVersion | 10.0.19041.0 → 10.0.17763.0 |
| 10 | tests/DeskBox.NotificationActivationProbe/Run-MSIX.ps1 | 探针清单 MinVersion | 10.0.19041.0 → 10.0.17763.0 |
| 11 | tests/DeskBox.Tests/Windows10InstallerCompatibilityContractTests.cs | 六处断言与注释 | 断言改目标值并重写服务族注释 |
| 12 | README / CHANGELOG / docs 相关陈述 | 地板描述 | 改为本分支地板并标注分支来源 |

## 不改动项及理由

- TargetFramework 保持 net10.0-windows10.0.22621.0：它是编译期 SDK 表面，与运行时地板解耦，上游 csproj 内有注释说明该设计。
- WindowsCompatibilityService.cs 的全部能力门禁不改：它们一律与 22000 比较，17763 与 19041 走同一分支。
- Win32Helper.DisplayTiming.cs 的 Win11 判断不改：已是带 else 分支的优雅降级。

## 任务

- [x] 建立本轮变更记录
- [x] 修改上述 12 处
- [x] 运行契约测试确认断言同步
- [x] 运行完整测试套件确认无回归
- [x] 收集并评审 CA1416 平台兼容性警告
- [x] 生成可重放补丁文件

## 验收判定

dotnet test 全绿且 CA1416 评审无未处理项。

## 验证证据

- 修改与验证全记录：specs/evidence/0003-A-floor-lowering.md
- 补丁文件：patches/17763-floor.patch（11 文件，42 增 23 删）
- 补丁重放实测：在 fb6e1c4 干净 checkout 上 git apply 成功，19041 → 17763 复现一致

## 结果摘要

- 契约测试 3/3 通过；完整套件 5507 通过 / 1 失败。
- 唯一失败用例 DesktopBlankHitTestTests.IsShellDesktopListView_AcceptsTheRealDesktopListView 已证实在原始上游代码上以完全相同方式失败（stash 对照实验），属环境既有，非本轮回归。
- CA1416：全项目原仅 1 条，定位到 AnimationsEnabledChanged（v10 契约），按上游既有守卫写法处理后归零。
- 原高危点 C3（AreAdvancedEffectsEnabled）经 CA1416 判定不成立，该属性契约早于 v10。
