# 0001 17763 就绪探针

状态：进行中

## 目标

在目标机（Windows 10 LTSC 2019 / build 17763）上以只读方式采集判定"DeskBox 能否在该机运行"所需的事实，产出一份可搬运回构建机的报告。

## 背景

地板下调能否成立，取决于两个上游代码点与若干系统前置条件，且这些事实只存在于目标机：

- WindowsCompatibilityService.cs::AreAdvancedEffectsEnabled 直接引用 UniversalApiContract v10 的 UISettings.AdvancedEffectsEnabled；17763 对应契约 v8。
- deskbox-thumbnail-proxy 的 main.rs 使用 uxtheme 序数 104/133/135/136，源码注释自述假设 22621 及以后。
- 私有 WinAppSDK 2.5.1 运行时随包部署，其自包含载荷在 17763 上的加载结果未知。

探针不依赖上游构建产物，因此先于编译环境探明执行。

## 任务

- [x] 探针脚本兼容 PowerShell 5.1，只读，不安装、不写注册表
- [x] 覆盖：OS 版本、VC++ 运行库、AppX 平台、Everything、uxtheme 序数解析、WinRT 契约与属性存在性、文件系统与长路径
- [x] 输出单一报告文件，UTF-8，含判定结论与原始证据
- [x] 在构建机（build 26200）空跑验证脚本无错误
- [ ] 在目标机（build 17763）运行并回收报告

## 验收判定

目标机跑出完整报告且脚本无错误。

## 验证证据

- 构建机空跑：specs/evidence/0001-A-probe-build-machine-dryrun.md（0 FAIL / 0 WARN，退出码 0）
- 目标机运行：待执行
