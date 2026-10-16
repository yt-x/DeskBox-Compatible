# 当前规格

当前版本：`v1.5.8-ltsc17763.1`（归档记录见 docs/releases/v1.5.8-ltsc17763.1.md）

## 承诺

本分支的最低支持系统为 **Windows 10 17763（1809 / LTSC 2019）**，x64。上游为 19041（2004）。

分发形态沿用上游的 Full 自包含载荷：安装器内置匹配的私有 Windows App Runtime，且应用为 Native AOT，因此目标机无需预装 Windows App Runtime，也无需安装 .NET 运行时。

## 相对上游 v1.5.8 的差异

| 差异 | 性质 |
|---|---|
| 安装器与编译期平台地板值由 19041 改为 17763 | 能力变更（用户可见） |
| `UISettings.AnimationsEnabledChanged` 订阅加 `ApiInformation.IsEventPresent` 守卫 | 缺陷修复（17763 上该事件不存在） |
| 地板契约测试的断言与说明文字随地板调整 | 测试同步 |

除上述三项外，本分支与上游行为一致。

## 已验证的环境事实

在目标机（Windows 10 Enterprise LTSC 2019，build 17763.9020，x64）实测确认：

- 目标机未安装任何 Windows App Runtime 包，自包含载荷是可用前提。
- `UISettings.AdvancedEffectsEnabled` 存在且可读。
- uxtheme 序数 104/133/135/136 均可解析且地址互异；其语义正确性未由探针验证。
- AppXSvc 为 Manual（非 Disabled）。
- `LongPathsEnabled` 为 0，属 Windows 10 1809 默认状态。

## 未覆盖

- arm64 未出包。
- uxtheme 私有序数的语义正确性未经独立验证，仅由实际运行观察间接确认。
- 上游地板以下的其他 Windows 10 版本（低于 17763）不在承诺范围。

## 验收状态

八项实机验收清单全部通过，证据见 `specs/evidence/`。
