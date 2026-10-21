# TODO

## 功能进度

| 功能 | 状态 | 验收判定 | 证据 |
|---|---|---|---|
| F1 17763 就绪探针 | 完成 | 目标机跑出完整报告且脚本无错误 | specs/evidence/0005-A-target-machine-acceptance.md |
| F2 无管理员编译链探明 | 完成 | dotnet 10.0.402、cargo 1.96.0、试编译通过 | specs/evidence/0002-B-toolchain-restore.md |
| F3 地板降至 17763 并制成补丁 | 完成 | 契约测试断言满足且 CA1416 归零 | specs/evidence/0003-A-floor-lowering.md |
| F4 重编安装器 | 完成 | 12 个必需文件齐全且安装器在目标机安装成功 | specs/evidence/0004-A-retail-package.md |
| F5 实机验收（.1） | 完成 | 八项验收清单全部通过 | specs/evidence/0005-A-target-machine-acceptance.md |
| F6 补丁重放机制 | 完成 | 干净 checkout 上 git apply 成功 | specs/evidence/0006-A-upstream-merge-2.md |
| F7 合并上游 27 提交并出包 .2 | 完成 | 零冲突、地板保持、AOT 出包退出码 0 | specs/evidence/0006-A-upstream-merge-2.md |

## 当前状态

分支版本 `v1.5.8-ltsc17763.2`，已并入上游 `bbb9e697`（右键菜单重构等 27 个提交），零冲突，地板全部保持 17763，补丁在新基线重放通过。安装器已重编为 32.08 MB。`.2` 尚未在目标机复验；`dotnet test` 在本会话环境因 testhost 进程句柄限制无法执行，地板断言以逐条核验替代。

## 下一步

【验证】在目标机（LTSC 2019）安装 .2 并复验右键菜单、打开方式子菜单与 ZIP 压缩 —— 八项清单逐项通过并回收结果
【测试】在普通终端人工执行地板契约测试与完整套件 —— 契约测试 3/3、通过数与总数相等
【打包】补 arm64 安装包 —— ISCC 以 DeskBox.arm64.iss 产出 arm64 产物

## 阻塞

无（`.2` 目标机复验依赖用户搬运文件）
