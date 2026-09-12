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
| `LC_ALL=C bash tools/flutter.sh test --concurrency=1 --reporter expanded` | 云端复核结束后补跑完整 Flutter 套件，21 项通过；测试文件串行执行 |
| 文档链接 | 首次检查 15 份 Markdown、83 个本地链接与锚点通过；本次更新的 4 份文档、38 个本地链接与锚点复核通过 |
| `git diff --cached --check` | 通过 |

另已查询 Flutter 官方发行清单，确认 Linux / Windows x64 均提供 3.47.4 stable，提交与当前 SDK 一致。前轮 Flutter 逻辑 10 项、组件 11 项及静态分析的结果见任务 02；本次未修改 Flutter 界面源码。

### GitHub runner

2026-09-13（北京时间）使用已登录的 `gh` 获取[运行 34706736742](https://github.com/conice/Morss/actions/runs/34706736742)的实际结果，源代码提交为 `c810ff90c7385ee30e329a26f084c64688bf3aaa`：

| 任务 | 结果 |
| --- | --- |
| [Verify](https://github.com/conice/Morss/actions/runs/34706736742/job/103588034331) | 首次尝试通过：7 项签名准备测试、Flutter 静态分析、10 项状态测试、11 项界面测试 |
| [Web release](https://github.com/conice/Morss/actions/runs/34706736742/job/103588289853) | 首次尝试通过；`morss-web-release` 已上传，41,905,583 字节 |
| [Windows x64 release](https://github.com/conice/Morss/actions/runs/34706736742/job/103588289862) | 首次尝试通过；`morss-windows-x64-release` 已上传，39,918,221 字节 |
| Android APK：[尝试 1](https://github.com/conice/Morss/actions/runs/34706736742/job/103588289888)、[尝试 2](https://github.com/conice/Morss/actions/runs/34706736742/job/103594291489) | 均选择 release；在 `:app:packageRelease` 读取 keystore 时失败，报错相同 |
| [Android APK：尝试 3](https://github.com/conice/Morss/actions/runs/34706736742/job/103596983328) | 单独重跑通过；`morss-android-release` 已上传，80,517,084 字节；签名文件清理通过 |

前两次 Android 的错误为 `Keystore was tampered with, or password was incorrect`，日志本身不能区分密码不匹配与 keystore 损坏。仓库 Secret 元数据显示，keystore 密码、密钥别名和密钥密码在第二次失败后更新。

按用户要求执行 `gh run rerun 34706736742 --repo conice/Morss --job 103594291489`，仅重跑 Android。第三次尝试在 Secrets 更新后启动，于北京时间 02:03:15–02:07:51 完成；日志确认 `Android build mode: release`，成功生成 `app-release.apk`，未再出现原 keystore 错误。Verify、Web 和 Windows 沿用首次尝试的成功结果，未重新执行。该次运行最终状态为 `success`，三份产物均未过期。

签名准备单元测试使用合成字节；本次真实 keystore 签名由 Android runner 构建成功验证。Android / Windows 安装运行与完整产品的 75 项验收仍待执行。

工作流提交 `3f08b90...c810ff9` 已完成 Standards 与 Spec 两项审查，均未发现已确认问题。

## Comments

2026-09-13：按用户要求开始配置，无需新增产品或视觉决策。

2026-09-13：工作流与签名处理配置完成。语法检查、7 项签名测试、锁定依赖安装、Web 构建、文档链接和差异检查分别通过；当时尚未执行 GitHub 首次运行及原生安装验证。

2026-09-13：补齐 GitHub 构建结果与双项审查记录。更新签名 Secrets 后，单独重跑的 Android release 构建通过，当前配置下原错误未复现；完整 Flutter 套件 21 项串行通过。README、产品规格及构建说明同步实际状态。
