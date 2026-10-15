# TODO

## 功能进度

| 功能 | 状态 | 验收判定 | 证据 |
|---|---|---|---|
| F1 17763 就绪探针 | 进行中 | 目标机跑出完整报告且脚本无错误 | specs/evidence/0001-A-probe-build-machine-dryrun.md |
| F2 无管理员编译链探明 | 进行中 | dotnet 10.0.402、cargo 1.96.0、ISCC 可用且试编译通过 | specs/evidence/0002-B-toolchain-restore.md |
| F3 地板降至 17763 并制成补丁 | 未开始 | dotnet test 全绿且 CA1416 评审无未处理项 | |
| F4 重编安装器 | 未开始 | 12 个必需文件齐全且安装器在目标机启动 | |
| F5 实机验收 | 未开始 | 六项验收清单全部通过 | |
| F6 补丁重放机制 | 未开始 | 干净 checkout 上 git apply 成功且测试通过 | |

## 当前状态

编译链已在无管理员权限下打通：.NET SDK 10.0.402 与 Rust 1.96.0 装于用户级目录，dotnet restore 与 Debug 编译均以退出码 0 通过（0 错误）。探针已编写并在构建机空跑通过。缺 Inno Setup 6（ISCC），为 F4 前置。

## 下一步

1. 把探针拷到目标机运行——报告文件产出且判定栏可读
2. 获取 Inno Setup 6 并确认 ISCC 可用——ISCC.exe 存在且带版本输出
3. 建立 F3 的本轮变更记录并开始改地板常量——specs/changes/ 下建档且门禁通过

## 阻塞

- F3 依赖 F2 结论：MSVC 与 Windows SDK 的无管理员来源未定
- F4、F5 依赖目标机文件搬运：由用户手工完成
