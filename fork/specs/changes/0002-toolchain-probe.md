# 0002 无管理员权限下的编译链探明

状态：进行中

## 目标

确定在无管理员权限的构建机上，能否凑齐 DeskBox 的零售 AOT 编译与打包链，并给出每一项的结论与来源。

## 背景

本分支的 F3 需要重新编译应用与安装器，因此必须先确认工具链可得性，否则后续工作可能整体阻塞在环境准备上。

## 任务

- [x] 清点 MSVC 工具链与 VS 安装器现状
- [x] 确认构建脚本对 Visual Studio 的最低要求（是否必须完整 IDE）
- [x] 确认 .NET SDK 版本可得性
- [x] 安装 .NET 10 SDK 并确认版本为 10.0.402
- [x] 确认 Rust 1.96.0 工具链可装
- [ ] 确认 Inno Setup 6（ISCC）可得
- [x] 以实际 restore 与编译验证 Windows Kit 19041 与 MSVC 14.29 是否满足

## 验收判定

dotnet 10.0.402、cargo 1.96.0、ISCC 可用且试编译通过。

## 验证证据

- 组件可得性清点：specs/evidence/0002-A-toolchain-availability.md
- 安装与 restore、Debug 编译实测：specs/evidence/0002-B-toolchain-restore.md
- 结论：.NET 10.0.402、cargo 1.96.0 均已就位，restore 与 Debug 编译均以退出码 0 通过；ISCC 待补（F4 前置）。
