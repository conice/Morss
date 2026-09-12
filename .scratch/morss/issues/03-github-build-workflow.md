Status: ready-for-agent
Outcome: completed

# 配置 Web、Windows 与 Android 构建工作流

用户要求配置 GitHub 工作流，生成 Web、Windows、Android；Android 有签名时使用签名，没有时使用 debug。沿用“分开验证 / 分开测试”的要求。

## Sources

- [产品规格：平台与界面](../spec.md#平台与界面)：Flutter；Android APK 和 Windows 桌面包通过对应平台 CI 构建。
- [Flutter 界面实现记录](02-implement-selected-a.md)：已有 Web、Android、Windows 工程，以及两组独立的 Flutter 测试。

## Scope

- 固定 Flutter 3.47.4，分别构建并上传 Web release、Windows x64 release 与 Android APK。
- 推送 main、推送 v 开头的标签、拉取请求和手动触发均可运行；各项检查单独执行。
- Android 的四项签名 Secrets 齐全时生成 release APK，均未配置时生成 debug APK；部分配置或无效内容明确失败。
- 拉取请求仅生成 debug APK；签名材料仅在构建过程中生成，并在任务结束时清理。
- 补充触发、下载、签名配置与验证范围说明。

## Implementation

- [工作流](../../../.github/workflows/build.yml)包含 Verify、Web、Windows 和 Android 四个任务。Verify 中的签名准备测试、静态分析和两组 Flutter 测试按步骤顺序执行；构建任务各自上传产物。
- Web 与 Windows 生成完整 release 目录，Android 根据签名准备结果选择 debug 或 release 构建。产物在 Actions 运行页面保留 14 天。
- [签名准备脚本](../../../tools/prepare_android_signing.py)从环境变量读取四项 Secrets，生成私有临时文件，保留密码的 Unicode、空白与转义字符，并拒绝覆盖已有签名文件。Gradle 读取标准 `android/key.properties`。
- 签名 Secrets 不注入拉取请求；任务结束时清理签名文件。工作流只授予仓库内容读取权限，引用的 Actions 固定到具体提交。
- [构建说明](../../../docs/ci/github-actions.md)记录触发与下载入口、四项 Secret、keystore 生成与编码方式、本地签名及平台边界。README 和产品规格同步更新。

## Validation

以下检查于 2026-09-13 在 Termux 分别执行，每项结束后才开始下一项：

| 检查 | 结果 |
| --- | --- |
| `actionlint -color .github/workflows/build.yml`（1.7.12） | 通过，未报告工作流错误 |
| `python -m unittest discover -s tools/tests -p 'test_*.py' -v` | 7 项通过；包含全部 14 种缺项组合、无签名回退、完整签名、Base64、特殊字符、文件权限与既有文件保护 |
| `bash tools/flutter.sh pub get --enforce-lockfile` | 通过，使用现有锁定依赖 |
| `bash tools/flutter.sh build web --release --no-pub --no-web-resources-cdn` | 通过；Web 产物与默认 Wasm 预检均成功 |
| 文档链接 | 15 份 Markdown、83 个本地链接与锚点通过 |
| `git diff --cached --check` | 通过 |

另已查询 Flutter 官方发行清单，确认 Linux / Windows x64 均提供 3.47.4 stable，提交与当前 SDK 一致。前轮 Flutter 逻辑 10 项、组件 11 项及静态分析的结果见任务 02；本次未修改 Flutter 界面源码。

签名准备测试使用合成字节，不代表真实 keystore 已完成 APK 签名。GitHub 托管 runner 尚未执行本次工作流，Android / Windows 的构建与安装运行仍待实际验证；配置完成不代表 75 项产品验收通过。

## Comments

2026-09-13：按用户要求开始配置，无需新增产品或视觉决策。

2026-09-13：工作流与签名处理配置完成。语法检查、7 项签名测试、锁定依赖安装、Web 构建、文档链接和差异检查分别通过。GitHub 首次运行及原生安装结果按上文保留为待验证事项。
