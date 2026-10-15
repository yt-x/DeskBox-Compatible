# TODO

## 功能进度

| 功能 | 状态 | 验收判定 | 证据 |
|---|---|---|---|
| F1 17763 就绪探针 | 进行中 | 目标机跑出完整报告且脚本无错误 | specs/evidence/0001-A-probe-build-machine-dryrun.md |
| F2 无管理员编译链探明 | 完成 | dotnet 10.0.402、cargo 1.96.0、试编译通过 | specs/evidence/0002-B-toolchain-restore.md |
| F3 地板降至 17763 并制成补丁 | 完成 | 契约测试全绿且 CA1416 评审无未处理项 | specs/evidence/0003-A-floor-lowering.md |
| F4 重编安装器 | 未开始 | 12 个必需文件齐全且安装器在目标机启动 | |
| F5 实机验收 | 未开始 | 六项验收清单全部通过 | |
| F6 补丁重放机制 | 完成 | 干净 checkout 上 git apply 成功 | specs/evidence/0003-A-floor-lowering.md |

## 当前状态

地板已降至 17763：11 个文件改毕，契约测试 3/3 通过，完整套件 5507 通过（唯一失败项经 stash 对照证实在原始上游即失败，属环境既有）。CA1416 经评审处理后归零，原高危点 C3 判定不成立。可重放补丁已生成并在干净 checkout 上验证通过。编译链在无管理员权限下打通。缺 Inno Setup 6（ISCC），为 F4 前置。

## 下一步

1. 把探针拷到目标机运行——报告文件产出且判定栏可读
2. 获取 Inno Setup 6 并确认 ISCC 可用——ISCC.exe 存在且带版本输出
3. 运行零售 AOT 发布链出包——publish 目录含 12 个必需文件

## 阻塞

- F3 依赖 F2 结论：MSVC 与 Windows SDK 的无管理员来源未定
- F4、F5 依赖目标机文件搬运：由用户手工完成
