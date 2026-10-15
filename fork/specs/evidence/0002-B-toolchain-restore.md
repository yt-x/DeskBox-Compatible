# 证据 0002-B 工具链安装与 restore 实测

- 日期：2026-10-15
- 机器：构建机（Windows 11 25H2，build 26200，标准用户 IsAdmin=False）

## 结论

**无管理员权限下工具链已凑齐并通过 `dotnet restore` 实测。** F2 验收判定成立。

## 安装动作与结果

| 组件 | 方式 | 结果 |
|---|---|---|
| .NET SDK 10.0.402 | dotnet-install.ps1，用户级目录 | 成功；`dotnet --list-sdks` 显示 10.0.402 |
| Rust 1.96.0 | `rustup toolchain install 1.96.0-x86_64-pc-windows-msvc --profile minimal` | 成功；rustc 1.96.0 (ac68faa20) |
| MSVC 工具链 | 已在位（VS 2019 Build Tools 14.29.30133） | 无需安装 |
| Windows SDK | 未安装新版本（本机仅 19041） | 由 NuGet 包 Microsoft.Windows.SDK.BuildTools 10.0.28000.2270 提供 |

安装路径（用户级，无需管理员）：`%LOCALAPPDATA%\Microsoft\dotnet`

## 关键实测

命令：`dotnet restore .\DeskBox.sln -p:Platform=x64`
结果：退出码 0，三个项目全部还原成功。

- src/DeskBox.Updater/DeskBox.Updater.csproj（40.75 秒）
- src/DeskBox/DeskBox.csproj（51.32 秒）
- tests/DeskBox.Tests/DeskBox.Tests.csproj（53.65 秒）

## 由此确认的事实

- 仅 19041 的 Windows Kit 不构成阻塞：SDK 头文件与库由 NuGet 包提供。
- MSVC 14.29.30133 足以完成还原阶段；是否能完成 Native AOT 编译尚需实际 publish 验证。
- winget 安装 .NET SDK 在本机卡在 DeliveryOptimization 下载阶段约 30 分钟无进展；dotnet-install 脚本为可靠替代路径。

## 待验证

- `dotnet build` Debug 是否通过（下一步）。
- `publish-aot-retail.ps1` 的 Native AOT 全链路是否通过，特别是 MSVC 14.29 版本是否满足 ILC 要求。
- Inno Setup 6 尚未获取，打包阶段需要。

## 追加实测：Debug 编译通过

命令：`dotnet build .\src\DeskBox\DeskBox.csproj --configuration Debug --no-restore -p:Platform=x64`

结果：退出码 0，0 错误、20 警告，耗时 3 分 28 秒。

产物目录 `src\DeskBox\bin\x64\Debug\net10.0-windows10.0.22621.0`：

- DeskBox.dll（12.16 MB）、DeskBox.exe、DeskBox.pri、Microsoft.WindowsAppRuntime.Bootstrap.Net.dll
- 共 224 个文件，74.8 MB

警告均为上游既有（CS8602 空引用、CS0108 成员隐藏），非本次改动引入。

## 关于 Rust 原生层的准确结论

- 缩略图代理**已实际编译**：产物位于 `src\DeskBox\obj\rust-thumbnail-proxy\Debug\x64\no-rid\Static\DeskBox.ThumbnailProxy.exe`。该组件正是高危点 C4（uxtheme 序数）所在，其编译链已验证可用。
- `deskbox_native.dll` 在 Debug 配置下**不产出**，原因是 `DeskBoxRustNative` 默认值为 false（见 src/DeskBox/DeskBox.csproj 中该属性定义）。零售 AOT 路径需显式传 `-p:DeskBoxRustNative=true`，F3 出包时必须带此参数。
- 工具链版本确认：`cargo 1.96.0 (30a34c682)`、`rustc 1.96.0 (ac68faa20)`，与仓库 pin 一致。
