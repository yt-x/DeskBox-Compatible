# 0001 fork 目录布局与门禁根

## Problem

本分支为私有仓库，不向上游贡献，但需要跟踪上游更新。上游仓库已有自己的 README 与 AGENTS.md；分支文档层若放仓库根，上游 merge 时产生冲突并污染补丁面。官方装钩脚本把门禁根写死为 git 仓库根，与 fork/ 子目录布局不兼容。

## Decision

分支全部自有文件收拢在 fork/ 下；上游文件只允许补丁清单内的修改。pre-commit 钩子手写，门禁根指向 fork/。不激活上游 .githooks，提交使用本机用户身份，不冒用上游作者身份。

## Alternatives considered

- 四件套放仓库根：可见性好，但上游 AGENTS.md 已存在，合并冲突且补丁面变大，放弃。
- 另建独立仓库：彻底隔离，但丢失 git 血缘，无法用 git apply 重放补丁、跟踪上游更新，放弃。
