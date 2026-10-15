# 证据 0001-A 探针本机构建机空跑

- 日期：2026-10-15
- 机器：构建机（Windows 11 25H2，build 26200.9711，标准用户 IsAdmin=False）
- 命令：`powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\17763-readiness.ps1 -OutFile <path>`
- 引擎：Windows PowerShell 5.1.26100.9711（与目标机同款引擎）

## 结果

- 退出码 0，报告文件生成成功（4531 字节，UTF-8 无 BOM）。
- 汇总：39 项发现，0 FAIL，0 WARN。
- 判定：CLEAR。

## 结论

探针在本机可执行、语法与运行路径均通过，WinRT 探测路径（UISettings 与 ApiInformation.IsPropertyPresent）在此引擎下确认可用。

本机为健康基线，判定 CLEAR 属预期结果；探针的真实判定能力待目标机（build 17763）运行验证。

## 本机附带发现（非目标机结论）

- 本机 `Get-AppxPackage` 返回 179 个包，`%ProgramFiles%\WindowsApps` 存在，AppXSvc 为 Running/Automatic。
- `%WINDIR%\System32\WindowsApps` 在本机不存在；上游卸载脚本以该路径判断精简系统，在健康机器上会产生误判。探针改用权威信号，不采用该目录检查。
- uxtheme 四个序数在本机（uxtheme 10.0.26100.8875）全部解析成功且地址互不相同；命名导出 ShouldAppsUseDarkMode 等在 26200 上不按名称导出，印证这些入口只能按序数访问。
