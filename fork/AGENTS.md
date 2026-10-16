# DeskBox 17763 分支 — 项目级契约

只写与全局契约及上游 AGENTS.md 的差异；形状规则读全局 AGENTS.md。

## 与全局契约 / 上游契约的差异

1. 项目文档层根目录是 fork/；仓库根的 AGENTS.md 是上游的，对其覆盖范围继续有效。
2. 本分支为私有仓库，不向上游贡献；不激活上游 .githooks，提交使用本机用户身份，不冒用上游作者身份。
3. 上游文件只允许补丁清单内的修改；fork 自有文件一律放 fork/ 下，不污染补丁面。
4. 被修改的上游文件在修改处附修改声明与日期，声明随补丁携带；GPL §5(a) 仅在分发时强制，私有不分发时为预备性良好实践。
5. pre-commit 门禁钩子为手写：门禁根指向 fork/（官方装钩脚本写死 git 仓库根，与本布局不兼容）。
6. 验证环境双机分离：编译验证在构建机（Win11），行为验收在 17763 目标机，文件靠用户手工搬运。

## 分工表

| 内容类型 | 家 |
|---|---|
| 需求 / 行为承诺 | specs/current.md |
| 调度 | TODO.md |
| 本轮明细 | specs/changes/ |
| 验证证据 | specs/evidence/ |
| fork 架构形态 | docs/architecture.md |
| 版本归档记录 | docs/releases/ |
| 术语 | CONTEXT.md |
| 因果 | decisions/ |
| 上游架构 | 仓库 docs/architecture/（只读引用，不改） |

## 规格工作流登记

- 核心工作流：能力变更维护当前规格，并保留本轮变更记录和验证证据；不强制采用某个框架的完整流程。
- 当前规格入口：`specs/current.md`
- 当前变更入口：`specs/changes/`
- 历史变更入口：`specs/changes/archive/`
- 验证证据入口：`specs/evidence/`

### 已检测的规格工具

| 工具或框架 | 检测依据 | 当前状态 | 适配说明 |
|---|---|---|---|
| 无 | 上游无 .specify/、openspec/、specs/ 目录 | 未检测到 | 使用上述自定义入口 |
