# 证据 0004-A 零售 AOT 出包与安装器重编

- 日期：2026-10-15
- 机器：构建机（Windows 11 25H2，build 26200，标准用户，无管理员）
- 提交：2d19ec0（发布时工作区干净）

## 结论

**零售 AOT 全链路成功，安装器已按 17763 地板重编。** 唯一未消除的技术风险（MSVC 14.29 是否满足 .NET 10 Native AOT）已排除。

## 环境补齐

| 组件 | 方式 | 结果 |
|---|---|---|
| Inno Setup 6.7.3 | 官方 GitHub release 安装包，`/PORTABLE=1` 后以 `/DIR=` 装到用户目录 | 成功，ISCC 可用 |

ISCC 路径：`%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe`。语言文件（含日文、繁中等）齐备。

## AOT 发布

命令：
`.\scripts\publish-aot-retail.ps1 -Platform x64`

结果：**退出码 0**，耗时 178987 毫秒。summary.json 关键字段：

| 字段 | 值 |
|---|---|
| productProfile / deploymentProfile | retail / full |
| selfContained | True |
| windowsAppSdkSelfContained | True |
| dotnetSdkVersion | 10.0.402 |
| gitCommit | 2d19ec0c61a1199dda1aad0f35b8326c3d92f0da |
| gitDirty | False |
| sourceStableDuringPublish | True |
| unexpectedWarningCodes | {} |
| publishFileCount / installManifestFileCount | 386 / 386 |
| publishBytes | 135946126（129.6 MB） |

脚本内置的全部校验均通过：PE 机器架构、禁止文件（coreclr/hostfxr/托管 DLL）、冒烟令牌扫描、警告码闸门、源码稳定性指纹。

### 关键结论：MSVC 14.29.30133 满足 Native AOT

ILC 完成 native code 生成，`deskbox_native.dll` 由 Rust 1.96.0 + 该 MSVC 构建成功，且脚本校验 `VcRuntimeImports: {}`（静态 CRT 链接，不依赖目标机 VC++ 运行库）。

## 载荷完整性

- 12 个必需文件全部存在，缺失数 0。
- publish 文件数 386 与安装清单条数 386 一致。
- 禁止项全部缺席：coreclr.dll、clrjit.dll、hostfxr.dll、hostpolicy.dll、System.Private.CoreLib.dll、DeskBox.dll、DeskBox.deps.json、DeskBox.runtimeconfig.json。

关键二进制（均 x64 / PE32+）：

| 文件 | 大小 |
|---|---|
| DeskBox.exe | 49.48 MB |
| DeskBox.Updater.exe | 2.47 MB |
| DeskBox.ThumbnailProxy.exe | 0.34 MB |
| deskbox_native.dll | 0.23 MB |
| Microsoft.WindowsAppRuntime.dll | 2.49 MB |

### Native AOT 权威判定（dumpbin）

用 MSVC 自带 dumpbin 读取 PE 头：

```
DeskBox.exe            8664 machine (x64)   20B magic # (PE32+)
                       0 [0] RVA [size] of COM Descriptor Directory
```

COM Descriptor Directory 即 CLR 运行时头（数据目录索引 14）；RVA 为 0 表示不存在 CLR 头，即真正的 Native AOT。`deskbox_native.dll` 同样无 CLR 头。

## 安装器重编

命令：
`ISCC.exe /DDeskBoxNativeAot=1 /DDeskBoxBundledRuntime=1 /DMyAppReleaseDir=..\.artifacts\aot-retail\win-x64\publish .\installer\DeskBox.iss`

结果：**Successful compile (29.172 sec)**，产物 `Output\DeskBox_Setup_1.5.8_x64.exe`。

| 项目 | 值 |
|---|---|
| 大小 | 33240988 字节（31.70 MB） |
| SHA256 | 92317593B19CCE01D7EC8F220B20585DE0CD9F319FA9701A728C2C819A4C2196 |
| 上游官方同版 x64 大小 | 33246196 字节（参考对照，差 5208 字节） |

### 地板值已进入产物的验证（代码级，非字符串搜索）

安装器载荷为 LZMA 压缩，且本机 build 26200 高于两种地板，无法用本机运行区分，因此采用源码级证明：

1. `installer/DeskBox.iss` 中 `MinVersion=10.0.17763` 位于第 46 行，**不在任何条件编译分支内**——其上最近的 `#endif` 在第 40 行关闭 AppComments 分支。
2. 全部 installer 脚本中仅两处 MinVersion，均为 10.0.17763。
3. 无 `#define` 或宏可覆盖该值；无 `OnlyBelowVersion`。
4. 编译命令仅传入 DeskBoxNativeAot、DeskBoxBundledRuntime、MyAppReleaseDir 三个宏，均与 MinVersion 无关。

因此 ISCC 在编译期读取到的即为 10.0.17763，产物内地板与源码一致。

尝试过的替代验证及其限制：innoextract 1.9 仅支持到 Inno Setup 6.0.5，无法解析本次的 6.7.3 格式，故未能解包读取。

## 过程中修正的问题

首次发布以退出码 1 结束，报 "The repository changed during the AOT retail publish"。原因是发布进行期间写入了变更记录文件，触发脚本的源码稳定性指纹校验。该防护为脚本设计意图，非缺陷。先行提交文档使工作区稳定后重跑即通过。

## 未完成项

- 安装器在目标机（17763）的实际启动与安装，属 F5。
- arm64 包未制作（本分支目标机为 x64）。
