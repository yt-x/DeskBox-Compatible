# 证据 0005-A 目标机探针报告与功能验收

- 日期：2026-10-16
- 目标机：`NDNP-P2682369Q1`，Windows 10 Enterprise LTSC 2019，build 17763.9020，x64
- 用户：`DOMAIN\P268236`
- 探针耗时：1.9 秒

## 探针结论

**39 项发现，0 FAIL，1 WARN。判定 CONDITIONAL。**

唯一的 WARN 是 FloorCheck 本身（`17763 >= 17763`），即"这就是需要降地板的目标机型"——属预期信息，不是缺陷。

## 关键确认项

| 项目 | 结果 | 意义 |
|---|---|---|
| 操作系统 | LTSC 2019 / 17763.9020 | 正是目标机型 |
| VC++ 运行库加载 | all load | 自包含载荷的运行前提具备 |
| AppX 平台 | 根目录 present，Appx 模块 2.0.1.0，Get-AppxPackage 41 个包 | 平台存在 |
| AppXSvc | Stopped / **StartType=Manual** | 与构建机的 Automatic 不同；Manual 非 Disabled，可为按需启动 |
| **已安装 WindowsAppRuntime 包** | **none** | 印证 self-contained 决策的必要性，见下 |
| Everything | 已安装，2 个进程 | 搜索功能可用 |
| uxtheme FileVersion | 10.0.17763.1 | 目标机版本 |
| uxtheme 四个序数 | 104/133/135/136 全部解析成功且地址互异 | 槽位非空；语义仍未被探针验证 |
| UISettings.AdvancedEffectsEnabled | **PRESENT** | 高危点 C3 在真实目标机上确认不触发 |
| AdvancedEffectsEnabledChanged 事件 | True | 同上 |
| 写 TEMP | ok | 文件系统可用 |
| LongPathsEnabled | **0** | 见观察项 |
| 磁盘 | C: 剩 22.0 GB；D: 剩 168.0 GB | D 盘空间充足，符合收纳目录优先非系统盘的默认策略 |

### 重要印证：self-contained 决策是必需的

目标机**未安装任何 Windows App Runtime 包**（`installed WindowsAppRuntime packages = none`）。这直接证明：若采用框架依赖模式分发，DeskBox 在这台机器上无法启动；Full 包内置私有运行时是该机型可用的前提。同时 Native AOT 免 .NET 运行时，故本机也不必装 .NET 10。

### 高危点 C3 的最终结论

探针在 17763.9020 上实测 `UISettings.AdvancedEffectsEnabled` 为 **PRESENT**。此前由 CA1416 编译期分析得出的"该属性契约早于 v10、17763 可用"的判断，在真实目标机上得到确认。C3 彻底关闭。

## 功能验收（用户实测）

用户报告：安装成功、程序可用，除下方一项语义疑问外未发现其他问题。

| 验收项 | 结果 |
|---|---|
| 安装器启动且无版本不受支持错误 | 通过 |
| 启动、托盘、进程不崩溃 | 通过 |
| 文件格子列出文件 | 通过 |
| 拖入文件 | 通过（移动） |
| 拖出文件 | 通过（复制，见下） |
| 设置窗口可用 | 通过 |
| 右键菜单（含「移回桌面」） | 通过 |
| 仅用测试目录 | 通过 |

### 拖出为复制：确认为设计行为，非缺陷

用户疑问：拖入是移动，拖出却是复制，是否为默认？移回桌面需右键选择。

核实结论：**是默认行为，且与本次地板下调无关。**

1. 默认设置为「跟随 Windows 默认」（`FileWidgetSettingsSlice.ManagedDragOutAction` 默认值 `FollowWindows`）。
2. 设置位置：设置 → 收纳分组 →「拖出格子时」卡片，三选项为 跟随 Windows 默认 / 复制 / 移动。
3. Windows 10 上的具体含义由产品自身文案说明，`Strings/zh-CN.json` 的 `Settings.DragOutAction.Win10Note`：
   "Windows 10 上拖出始终按所选方式直接执行(『跟随 Windows 默认』按复制处理，接收方应用不会移除原文件)；拖动中的 Ctrl/Shift 只对 DeskBox 格子有效"
4. 技术原因见 `Views/SettingsWindow.StorageAndUpdates.cs` 的注释：Windows 10 上代理拖放对外部目标只能声明单一效果，无法像 Windows 11 那样把修饰键传递给外部目标，因此该卡片在 Win10 上追加说明，并禁用修饰键提示开关（判定条件为 `WindowsCompatibilityService.IsWindows11OrLater`，即 build >= 22000）。
5. 真正移动的路径是右键菜单「移回桌面」（`Widget.MoveBackToDesktop`），符合用户观察。

**与地板下调无关的依据**：上述分支条件是 build >= 22000。17763 与 19041 取同一分支，故本机行为与上游在 19041 上的行为完全一致，本次改动未触及该路径。

## 观察项（非阻塞，建议知悉）

- **LongPathsEnabled = 0**：Windows 10 1809 的默认状态。超长路径（>260 字符）在收纳深层目录时可能失败。这是 Windows 自身限制，在上游 19041 地板上同样存在，与本分支无关。
- **AppXSvc 为 Manual**：构建机为 Automatic。Manual 表示按需启动，非禁用，当前不构成阻塞；若后续涉及打包/商店相关路径需注意差异。
- 用户粘贴的报告在 FS 段之后被截断（Env 段与解释说明未贴出），但全部实质性判据已包含在内。

## 待确认

- 重启 DeskBox 后布局保持（清单项之一，用户未明确提及）。
