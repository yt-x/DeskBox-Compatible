# fork 增量架构

只描述本分支相对上游新增的形态。上游自身架构见仓库 docs/architecture/ 下的 current_architecture.md，此处不重复。

## 运行单元

- 构建机：Windows 11（build 26200），标准用户，无管理员权限；承载编译链与打包链，产出安装器。
- 目标机：Windows 10 LTSC 2019（build 17763），标准用户；只运行探针脚本与最终安装产物，不编译。
- 两机无网络互通，文件由用户手工搬运。

## 组件与边界

fork/ 下全部为新增文件；上游文件仅补丁清单覆盖的地板常量、一处契约测试与一处事件守卫被修改（共 11 个文件）。

- probes/：只读系统探针，纯 PowerShell，不安装、不写注册表；独立于上游构建产物。
- patches/17763-floor.patch：对上述上游修改点的集合，用 git apply 在干净上游上重放。
- specs/、docs/、decisions/：分支自身的规格、文档与决策层。

依赖方向单向：patches 依赖上游源码；probes 不依赖任何构建产物；文档层只引用、不改写上游文档。

## 数据流

- 补丁重放流：上游 main 更新 → git apply 补丁 → dotnet test → publish-aot-retail.ps1 → ISCC → 安装器。
- 验证反馈流：探针在目标机输出报告 → 用户搬运回构建机 → 分析后决策（放行 / 修复 / 放弃）。

## 外部接口

- 上游仓库：git remote upstream，Tianyu199509/DeskBox。
- Windows App SDK 2.5.1：self-contained 随包私有部署；微软支持矩阵覆盖 17763。
- Inno Setup 6：ISCC 重编安装器。
- 目标机 PowerShell 5.1：探针运行环境，只用核心 cmdlet 与 Add-Type。

## 部署形态

产物为 current-user 范围的 Inno 安装器，目标机上无管理员权限安装；验收在目标机测试目录进行，不指向真实桌面数据。

## 地板相关的系统事实

目标机（build 17763）实测结论如下，构成本分支可行性的依据：

- WindowsCompatibilityService.cs::AreAdvancedEffectsEnabled 引用的 `UISettings.AdvancedEffectsEnabled` 在 17763 上存在且可读，该引用不构成地板障碍。
- WindowsCompatibilityService.cs 中 `UISettings.AnimationsEnabledChanged` 的订阅按契约自 19041 起提供，在 17763 上须由 `ApiInformation.IsEventPresent` 守卫，该守卫已加装。
- deskbox-thumbnail-proxy 的 main.rs 使用的四个 uxtheme 序数（104/133/135/136）在 17763 的 uxtheme 10.0.17763.1 上均可解析且地址互异；解析成功不证明指向预期函数，语义正确性无独立验证手段。
- 目标机未预装 Windows App Runtime，私有自包含载荷是可运行的前提；Native AOT 使 .NET 运行时同样无需预装。
- 能力门禁集中在 WindowsCompatibilityService.cs，一律与 build 22000 比较，17763 与上游地板 19041 走同一分支。
