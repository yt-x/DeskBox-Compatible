# 0003 IL2050 用调用点定点抑制而非放宽发布闸门

## Problem

上游提交 `bbb9e697` 引入的 `ShellOpenWithInterop.SHAssocEnumHandlers` 以 `[MarshalAs(UnmanagedType.Interface)]` 返回 COM 接口，Native AOT 裁剪分析产生 IL2050（"Correctness of COM interop cannot be guaranteed after trimming"）。

零售发布脚本 `scripts/publish-aot-retail.ps1` 要求警告码只能落在白名单内（CS0108、CS0169、CS0414、CS8601、CS8602、WMC1510），IL2050 不在其中，出包中止。

上游自身架构文档把 IL2050 列为必须清零的指标：仓库根 docs/architecture/rust-native-aot-roadmap.md 记载 profile 56 / schema 53 已把 IL2050 等全部清零，因此这是上游当前提交的回归。

## Decision

在调用点 `Helpers/ShellOpenWithHelper.cs` 的 `GetRecommendedApps` 上加 `[UnconditionalSuppressMessage("TrimAnalysis", "IL2050")]`，并附判断依据注释与分支说明。

判断依据：`ShellOpenWithEnumHandlers` 在该方法内被静态引用（返回的 handler 上直接调用 `Next`），裁剪器会保留所需成员，IL2050 在此属误报。

不修改发布脚本的警告码白名单。

## Alternatives considered

- 放宽发布脚本白名单加入 IL2050：改动最小，但闸门会对**所有**未来的 IL2050 失去敏感度；上游明确要求 IL2050 为零，放宽等于放弃一项既有质量指标，放弃。
- 用 `DynamicallyAccessedMembers` 注解接口参数：实测无效——该属性面向类型成员可达性，不作用于 COM 封送正确性分析；加注解后 IL2050 依旧出现，已回退，放弃。
- 重构为 ComWrappers 或窄 vtable 边界：这是上游消除 IL2050 的既定路线，但改动量大、触及上游功能实现，超出本分支"只调地板"的定位，放弃。
- 不合并该上游提交：用户已决定合并，且该提交主体是右键菜单重构，放弃合并代价过大，放弃。

## 复查条件

上游若在下一次提交中自行加注解或改走 ComWrappers，应移除本分支的抑制，避免与其产生重复或冲突。
