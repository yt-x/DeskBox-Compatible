# CONTEXT

## 词条

| 术语 | 当前理解 | 证据来源 |
|---|---|---|
| MinVersion | Inno Setup 编译期 OS 下限常量，本分支为 10.0.17763 | installer/DeskBox.iss |
| SupportedOSPlatformVersion | MSBuild 平台声明，驱动 CA1416 平台兼容性分析 | src/DeskBox/DeskBox.csproj |
| TargetPlatformMinVersion | 仅商店（MSIX）分发路径使用的地板声明 | src/DeskBox/DeskBox.csproj |
| servicing family | 19041–19045 同属一族；17763 属 1809/LTSC 族，跨度与上游不同 | tests/DeskBox.Tests/Windows10InstallerCompatibilityContractTests.cs |
| self-contained | Windows App SDK 运行时随包私有部署，目标机无需预装 | scripts/publish-aot-retail.ps1 |
| CA1416 | 平台兼容性分析警告，识别调用点低于目标平台下限的情形；不识别 ApiInformation 运行时守卫 | 构建实测 |
| IL2050 | 裁剪分析警告，指 COM 封送正确性无法保证；上游要求为零，接口被静态引用时为误报 | 构建实测与上游 AOT 路线文档 |
| ilc parallelism | Native AOT 编译器并发线程数，默认等于逻辑处理器数；内存紧张时需下调 | ilc --help |
| UniversalApiContract | WinRT API 契约版本体系；UISettings.AdvancedEffectsEnabled 在 17763 上实测存在 | 目标机探针报告 |
| Full 载荷 | 内置私有 Windows App Runtime 的安装包形态，离线可用 | installer/DeskBox.Dependencies.iss |
| 地板（floor） | 声明的最低支持系统版本；本分支为 build 17763 | specs/current.md |

## 待确认区

| 术语 | 我的理解 | 证据来源 | 待确认问题 |
|---|---|---|---|
| uxtheme 序数 | 未文档化私有导出；17763 上 104/133/135/136 均可解析且地址互异 | 目标机探针报告 | 解析成功不等于指向正确函数，语义正确性无独立验证手段 |

## 变更日志

- 2026-10-16 收尾：MinVersion、SupportedOSPlatformVersion、self-contained、CA1416、UniversalApiContract 等词条由待确认区转入词条表；servicing family 的差异说明重写完成。仅 uxtheme 序数语义保留待确认。
