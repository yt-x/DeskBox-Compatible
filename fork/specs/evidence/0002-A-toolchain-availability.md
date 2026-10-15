# 证据 0002-A 构建机组件的可得性探明

- 日期：2026-10-15
- 机器：构建机（Windows 11 25H2，build 26200，标准用户 IsAdmin=False）

## 结论摘要

无管理员权限下凑齐编译链的关键组件比预期容易：MSVC 工具链与 VS 安装器已在位，winget 可提供仓库 pin 的 .NET SDK 版本。

| 组件 | 需求 | 本机状态 | 可得性 |
|---|---|---|---|
| MSVC 工具链 | VC.Tools.x86.x64 | 已在位：VS 2019 Build Tools，MSVC 14.29.30133，link.exe 存在 | 满足 |
| vswhere.exe | 构建脚本用于发现 MSVC | 已在位 | 满足 |
| Windows SDK | 构建需要 | 仅 10.0.19041.0；项目通过 NuGet 包 Microsoft.Windows.SDK.BuildTools 10.0.28000.2270 提供 SDK | 待试编译验证 |
| .NET 10 SDK | 仓库 global.json pin 10.0.402 | 缺失（原仅有 8.0.322 运行时） | winget 有 10.0.402，安装中 |
| Rust 1.96.0 | rust-toolchain.toml pin | 仅 stable（1.98.1），未装 1.96.0 | rustup 可装 |
| Inno Setup 6 | 重编安装器需 ISCC.exe | 缺失 | 待装（有便携版） |

## 关键判据

构建脚本 scripts/rust-arm64-msvc-environment.ps1 以如下方式发现 MSVC：

- 查询 `-products *`，即同时接受 Build Tools 与完整 Visual Studio。
- 要求组件 `Microsoft.VisualStudio.Component.VC.Tools.x86.x64`。

由此确定：**不需要完整 Visual Studio IDE，VS Build Tools 即可**，而本机已具备该组件。

## 上游权威依据

- .github/workflows/ci.yml 使用 windows-latest 加 actions/setup-dotnet 指定 10.0.x。
- docs/architecture/rust-native-aot-roadmap.md 记载固定 Rust 1.96.0 与 MSVC/SDK，并明确以减少对 Visual Studio 安装事务的依赖为目标。

## 待验证

- 安装 .NET 10 SDK 后，`dotnet --list-sdks` 是否出现 10.0.402。
- 仅 19041 的 Windows Kit 是否影响编译（预期由 NuGet 包覆盖，须以实际 restore/build 验证）。
- MSVC 14.29.30133 是否满足 .NET 10 Native AOT 的最低要求；若不足，需补装更高版本 MSVC。
