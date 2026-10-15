# 0004 零售 AOT 出包与安装器重编

状态：进行中

## 目标

在地板降至 17763 之后，产出可安装的 x64 零售包，并确认其载荷完整、安装器已按新地板编译。

## 背景

本阶段验证两件事：

1. MSVC 14.29.30133 是否满足 .NET 10 Native AOT（ILC）的编译要求——这是唯一尚未消除的技术风险。
2. 重编后的安装器是否接受 17763，且载荷的 12 个必需文件齐备。

工具链已就位：.NET SDK 10.0.402、Rust 1.96.0、Inno Setup 6.7.3（用户级安装于 %LOCALAPPDATA%\Programs\Inno Setup 6）。

## 任务

- [x] 获取并安装 Inno Setup 6（用户级，无管理员）
- [ ] 运行 scripts/publish-aot-retail.ps1 -Platform x64
- [ ] 确认 publish 目录含 12 个必需文件
- [ ] 用 ISCC 以 /DDeskBoxNativeAot=1 /DDeskBoxBundledRuntime=1 重编安装器
- [ ] 校验安装器产物存在且哈希可记录

## 验收判定

12 个必需文件齐全且安装器在目标机启动。

## 验证证据

待补（存入 specs/evidence/）。
