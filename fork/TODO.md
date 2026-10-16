# TODO

## 功能进度

| 功能 | 状态 | 验收判定 | 证据 |
|---|---|---|---|
| F1 17763 就绪探针 | 进行中 | 目标机跑出完整报告且脚本无错误 | specs/evidence/0001-A-probe-build-machine-dryrun.md |
| F2 无管理员编译链探明 | 完成 | dotnet 10.0.402、cargo 1.96.0、试编译通过 | specs/evidence/0002-B-toolchain-restore.md |
| F3 地板降至 17763 并制成补丁 | 完成 | 契约测试全绿且 CA1416 评审无未处理项 | specs/evidence/0003-A-floor-lowering.md |
| F4 重编安装器 | 进行中 | 12 个必需文件齐全且安装器在目标机启动 | specs/evidence/0004-A-retail-package.md |
| F5 实机验收 | 未开始 | 六项验收清单全部通过 | |
| F6 补丁重放机制 | 完成 | 干净 checkout 上 git apply 成功 | specs/evidence/0003-A-floor-lowering.md |

## 当前状态

零售 AOT 出包链路全通：Native AOT 编译成功（dumpbin 确认无 CLR 头），载荷 386 文件与安装清单一致，12 个必需文件齐备，安装器已按 17763 地板重编为 Output\DeskBox_Setup_1.5.8_x64.exe（33240988 字节）。MSVC 14.29 满足 ILC 要求，最后一个技术风险已排除。地板改动 11 文件已入库，契约测试 3/3，CA1416 归零。

## 下一步

1. 把探针与安装器拷到目标机运行——探针产出报告且安装器完成安装、DeskBox 能启动
2. 按六项清单在目标机验收——逐项勾选并回收结果
3. 补齐 arm64 包——ISCC 以 DeskBox.arm64.iss 产出 arm64 安装器

## 阻塞

- F4 后半与 F5 依赖目标机文件搬运：由用户手工完成，与构建机无网络互通
