# TODO

## 功能进度

| 功能 | 状态 | 验收判定 | 证据 |
|---|---|---|---|
| F1 17763 就绪探针 | 完成 | 目标机跑出完整报告且脚本无错误 | specs/evidence/0005-A-target-machine-acceptance.md |
| F2 无管理员编译链探明 | 完成 | dotnet 10.0.402、cargo 1.96.0、试编译通过 | specs/evidence/0002-B-toolchain-restore.md |
| F3 地板降至 17763 并制成补丁 | 完成 | 契约测试 3/3 且 CA1416 归零 | specs/evidence/0003-A-floor-lowering.md |
| F4 重编安装器 | 完成 | 12 个必需文件齐全且安装器在目标机安装成功 | specs/evidence/0004-A-retail-package.md |
| F5 实机验收 | 完成 | 八项验收清单全部通过 | specs/evidence/0005-A-target-machine-acceptance.md |
| F6 补丁重放机制 | 完成 | 干净 checkout 上 git apply 成功 | specs/evidence/0003-A-floor-lowering.md |

## 当前状态

六项功能全部完成。安装器 Output\DeskBox_Setup_1.5.8_x64.exe 已在目标机（Windows 10 Enterprise LTSC 2019，build 17763.9020）安装成功并通过八项验收；探针报告 0 FAIL。地板值 17763 已进入源码与产物。可重放补丁 patches/17763-floor.patch 已验证。CA1416 归零，原高危点 C3 经目标机实测关闭。

## 下一步

1. 同步上游更新——git fetch upstream 后以 patches/17763-floor.patch 重放并重跑 dotnet test
2. 补齐 arm64 包——ISCC 以 DeskBox.arm64.iss 产出 arm64 安装器
3. 若 uxtheme 菜单主题在目标机出现异常——在 deskbox-thumbnail-proxy 加序数版本守卫

## 阻塞

无
