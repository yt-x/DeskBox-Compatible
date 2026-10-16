# 0002 CA1416 残留警告用定向抑制处理

## Problem

地板降至 17763 后，CA1416 全量分析在全项目仅命中一处：`WindowsCompatibilityService` 订阅 `UISettings.AnimationsEnabledChanged`，而该事件按契约自 19041 起提供。

该订阅已按上游自身在同一代码块对 `AdvancedEffectsEnabledChanged` 采用的写法，加装 `ApiInformation.IsEventPresent` 运行时守卫，功能上已安全。但 CA1416 只识别 `OperatingSystem.*` 版本判断，不识别 `ApiInformation` 运行时守卫，因此警告在加装守卫后依然存在。

发布脚本 `scripts/publish-aot-retail.ps1` 的警告码闸门正则覆盖 IL/CS/MSB/WMC/MVVMTK/CsWinRT/NETSDK/SYSLIB，不含 CA，因此该警告不会阻断发布，但会留在构建输出中。

## Decision

保留 ApiInformation 运行时守卫，并对该订阅语句加 `#pragma warning disable CA1416` 定向抑制，附注说明"CA1416 无法识别 ApiInformation 守卫，运行时探测才是真正的门禁，已在 17763 上验证"。

不修改发布脚本的警告码正则。

## Alternatives considered

- 改为反射调用该事件：可在运行时彻底规避契约引用，但上游曾因 Native AOT 裁剪问题把同类反射查找改为直接引用（见 `WindowsCompatibilityService` 中关于 `AdvancedEffectsEnabled` 的注释），重蹈该覆辙风险高，放弃。
- 完全移除该事件订阅：动画开关变化的实时响应会丢失，属功能削减，超出"只降门槛"的分支定位，放弃。
- 把 CA 加入发布脚本警告码闸门：会立即让本次这一条（以及任何未来的 CA 类警告）阻断发布，超出本分支范围，且改动上游发布脚本的必要性不足，放弃。

## 影响与复查条件

抑制是局部的，仅覆盖这一条语句，不具备全局掩盖能力。若将来该文件新增其他 CA1416 命中，应逐条评估而非扩大抑制范围。
