# DeskBox 17763 兼容分支

在上游 DeskBox v1.5.8 基础上把最低系统要求从 Windows 10 19041 降至 17763（LTSC 2019）的维护性私有分支：只调整版本门槛与一处事件订阅守卫，不增改功能，不向上游贡献。许可证沿用上游 GPL-3.0-only，修改处在文件内标注声明与日期。

怎么跑：安装包见仓库根 `Output\DeskBox_Setup_1.5.8_x64.exe`；重新构建见 `scripts/publish-aot-retail.ps1` 与仓库根 README 的 Build from source 一节；目标机验收步骤见 `specs/changes/archive/0005-target-machine-acceptance.md`。

文档导航：调度见 TODO.md；版本归档与改动清单见 docs/releases/v1.5.8-ltsc17763.1.md；fork 增量架构见 docs/architecture.md；规格入口见 specs/current.md；术语见 CONTEXT.md；决策见 decisions/；可重放补丁见 patches/。
