# 证据 0003-A 地板下调与验证

- 日期：2026-10-15
- 机器：构建机（Windows 11 25H2，build 26200，标准用户）
- 工具链：.NET SDK 10.0.402（用户级）、Rust 1.96.0、MSVC 14.29.30133

## 修改清单（11 个文件）

| 文件 | 修改内容 |
|---|---|
| installer/DeskBox.iss | MinVersion 10.0.19041 → 10.0.17763 |
| installer/DeskBox.arm64.iss | MinVersion 10.0.19041 → 10.0.17763 |
| src/DeskBox/DeskBox.csproj | SupportedOSPlatformVersion、TargetPlatformMinVersion → 10.0.17763.0 |
| src/DeskBox.Updater/DeskBox.Updater.csproj | SupportedOSPlatformVersion → 10.0.17763.0 |
| tests/DeskBox.Tests/DeskBox.Tests.csproj | SupportedOSPlatformVersion → 10.0.17763.0 |
| tests/DeskBox.NotificationActivationProbe/DeskBox.NotificationActivationProbe.csproj | SupportedOSPlatformVersion → 10.0.17763.0 |
| src/DeskBox/Package.appxmanifest | TargetDeviceFamily MinVersion → 10.0.17763.0 |
| scripts/Test-StoreStartupTaskLifecycle.ps1 | 探针清单 MinVersion → 10.0.17763.0 |
| tests/DeskBox.NotificationActivationProbe/Run-MSIX.ps1 | 探针清单 MinVersion → 10.0.17763.0 |
| tests/DeskBox.Tests/Windows10InstallerCompatibilityContractTests.cs | 六处断言改为 17763，重写服务族注释 |
| src/DeskBox/Services/WindowsCompatibilityService.cs | AnimationsEnabledChanged 加 ApiInformation 守卫 |

## CA1416 平台兼容性评审（本轮关键产出）

编译命令：
`dotnet build .\src\DeskBox\DeskBox.csproj --configuration Debug --no-restore -p:Platform=x64 -p:EnableNETAnalyzers=true -p:AnalysisMode=AllEnabledByDefault`

**清空 obj 后全量重编译，全项目仅 1 条 CA1416：**

```
WindowsCompatibilityService.cs(377,21): warning CA1416:
可在 Windows 10.0.17763.0 及更高版本上访问此调用站点。
"UISettings.AnimationsEnabledChanged" 仅在 Windows 10.0.19041.0 及更高版本上受支持。
```

处置：该事件属于 UniversalApiContract v10（19041 起），确实高于本分支地板。按上游自身既有的守卫写法（同文件对 AdvancedEffectsEnabledChanged 即用 ApiInformation.IsEventPresent）加装守卫，并附定向抑制说明——CA1416 不识别 ApiInformation 运行时守卫，只识别 OperatingSystem.* 版本判断。

处置后：**CA1416 归零，0 错误。**

### 附带结论：原高危点 C3 不成立

`WindowsCompatibilityService.cs` 的 `AreAdvancedEffectsEnabled` 属性（直接引用 UISettings.AdvancedEffectsEnabled，原先据其注释判断依赖 v10 契约）**未被 CA1416 命中**，说明该属性在编译器契约视图中对 17763 可用，其契约早于 v10。原清点报告中标为高危的 C3 由此降级为不成立；真正需要处理的是同一代码块中被漏掉的 AnimationsEnabledChanged。

## 测试验证

### 契约测试

命令：`dotnet test .\tests\DeskBox.Tests\DeskBox.Tests.csproj --filter "FullyQualifiedName~Windows10InstallerCompatibilityContractTests"`
结果：**通过 3，失败 0**。确认 12 处地板常量与断言一致。

### 完整套件

命令：`dotnet test .\tests\DeskBox.Tests\DeskBox.Tests.csproj --no-restore -p:Platform=x64`
结果：通过 5507，失败 1，总计 5508。

### 唯一失败项的归因（已证实为环境既有，非本轮回归）

失败用例：`DesktopBlankHitTestTests.IsShellDesktopListView_AcceptsTheRealDesktopListView`（tests/DeskBox.Tests/DesktopBlankHitTestTests.cs:123）

该用例实时枚举本机桌面的窗口层级（SHELLDLL_DefView → SysListView32）并断言其被识别，属依赖运行环境的集成测试。

归因方法：以 `git stash` 暂存全部地板改动，恢复到原始上游代码（MinVersion=10.0.19041）后运行同一用例。

结果：**原始上游代码上以完全相同的方式失败（失败 1，通过 7，总计 8）**。

结论：该失败在改动前即存在，与本轮地板下调无关，不阻塞本轮验收。

## 未完成项

- 仅作 Debug 编译验证；Native AOT 零售发布链（publish-aot-retail.ps1）尚未运行，F4 阶段执行。
- 目标机（17763）实机行为验收待 F5。
