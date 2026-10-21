# 当前规格

当前版本：`v1.5.8-ltsc17763.2`（上游基线 `bbb9e697`；归档记录见 docs/releases/v1.5.8-ltsc17763.2.md）

上一版本：`v1.5.8-ltsc17763.1`（上游基线 `fb6e1c4`，已在目标机完成八项验收）

## 承诺

本分支的最低支持系统为 **Windows 10 17763（1809 / LTSC 2019）**，x64。上游为 19041（2004）。

分发形态沿用上游的 Full 自包含载荷：安装器内置匹配的私有 Windows App Runtime，且应用为 Native AOT，因此目标机无需预装 Windows App Runtime，也无需安装 .NET 运行时。

## 相对上游的差异

共 12 个文件：地板常量 9 处、契约测试同步、事件守卫修复、裁剪警告抑制。

| 差异 | 性质 |
|---|---|
| 安装器与编译期平台地板值由 19041 改为 17763 | 能力变更（用户可见） |
| `UISettings.AnimationsEnabledChanged` 订阅加 `ApiInformation.IsEventPresent` 守卫 | 缺陷修复（17763 上该事件不存在） |
| `ShellOpenWithHelper.GetRecommendedApps` 加 IL2050 定点抑制 | 构建闸门适配（上游回归，见 decisions/0003-il2050-suppression.md） |
| 地板契约测试的断言与说明文字随地板调整 | 测试同步 |

除上述差异外，本分支行为与上游一致，不增改功能。

## 构建环境要求

`Directory.Build.targets` 提供环境变量门控的 ilc 并行度约束：设置 `DESKBOX_ILC_PARALLELISM` 时在 `IlcCompile` 前注入对应并行度，未设置时不生效。构建机内存不足以支撑默认并行度（逻辑处理器数）时须使用，否则 ILC 会以内存不足中止。

## 已验证的环境事实

在目标机（Windows 10 Enterprise LTSC 2019，build 17763.9020，x64）实测确认（基于 .1 版本）：

- 目标机未安装任何 Windows App Runtime 包，自包含载荷是可用前提。
- `UISettings.AdvancedEffectsEnabled` 存在且可读。
- uxtheme 序数 104/133/135/136 均可解析且地址互异；其语义正确性未由探针验证。
- AppXSvc 为 Manual（非 Disabled）。
- `LongPathsEnabled` 为 0，属 Windows 10 1809 默认状态。

## 未覆盖

- `.2` 版本尚未在目标机复验。上游本轮以右键菜单重构为主，属核心交互，需重点复验。
- 地板契约测试在构建会话环境无法执行（testhost 进程句柄限制），断言以逐条核验方式确认。
- arm64 未出包。
- uxtheme 私有序数的语义正确性未经独立验证，仅由实际运行观察间接确认。
- 上游地板以下的其他 Windows 10 版本（低于 17763）不在承诺范围。

## 验收状态

`.1` 版本八项实机验收全部通过，证据见 `specs/evidence/`。`.2` 版本完成构建机验证，目标机复验待执行。
