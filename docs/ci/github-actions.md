# GitHub Actions 构建

[Build Morss 工作流](../../.github/workflows/build.yml)使用 Flutter 3.47.4，先逐项执行签名准备测试、Flutter 静态分析、示例阅读状态、示例界面、SQLite 阅读库、真实订阅界面、OPML 管理控制器与管理界面测试，再由独立任务构建 Web、Windows 与 Android。每个测试文件使用单独步骤，失败后可明确定位。

## 触发与下载

- 推送到 `main`。
- 推送 `v` 开头的标签，例如 `v0.1.0`。
- 创建或更新拉取请求。
- 在仓库 **Actions → Build Morss → Run workflow** 中手动触发。手动入口需要工作流先进入默认分支。

成功后，在该次运行页面的 **Artifacts** 下载产物，默认保留 14 天：

| 产物名称 | 内容与运行方式 |
| --- | --- |
| `morss-web-release` | 完整 Web 静态文件。解压后在文件目录运行 `python -m http.server 8080`，打开 `http://localhost:8080/` |
| `morss-windows-x64-release` | Windows x64 的完整 Release 目录。解压后运行 `morss.exe`，保留旁边的 DLL 和 `data` 目录 |
| `morss-android-release` | 配置签名后生成的通用 `app-release.apk` |
| `morss-android-debug` | 无签名配置或 PR 构建生成的通用 `app-debug.apk` |

Web 使用默认根路径 `/`，CanvasKit 等 Web 运行资源随包生成；部署到站点子目录时，相应修改工作流中的 `--base-href /子目录/`。Windows 目标机器需要 Microsoft Visual C++ x64 运行库，见 [Flutter Windows 发布说明](https://docs.flutter.dev/deployment/windows#building-your-own-zip-file-for-windows)。

版本名称与版本号沿用 `pubspec.yaml` 中的 `version`；标签用于触发构建，不会覆盖应用版本。

## Android 签名

在仓库 **Settings → Secrets and variables → Actions → New repository secret** 中配置：

| Secret | 内容 |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | JKS / keystore 文件的 Base64 内容 |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 密码 |
| `ANDROID_KEY_ALIAS` | 签名密钥别名 |
| `ANDROID_KEY_PASSWORD` | 该别名对应的密钥密码 |

四项均未配置时自动执行 `flutter build apk --debug`。四项齐全时执行 `flutter build apk --release`，使用指定 keystore。只配置部分项会报出缺失的名称；Base64 无效、keystore 格式错误、密码或别名错误均使 Android 任务失败。拉取请求不注入这些 Secrets，始终构建 debug APK。

已有 keystore 时，使用下面的跨平台 Python 命令生成用于填入 Secret 的文件：

```sh
python -c "from pathlib import Path; import base64; p = Path('upload-keystore.jks'); p.with_suffix(p.suffix + '.base64').write_bytes(base64.b64encode(p.read_bytes()))"
```

将 `upload-keystore.jks.base64` 的完整内容填入 `ANDROID_KEYSTORE_BASE64`。Base64 文件与 keystore 含有同一份密钥材料；两者和 `android/key.properties` 均已加入 Git 忽略规则。

如需新建 keystore，在安装了 JDK 的环境中执行以下命令，再按提示输入密码和证书资料：

```sh
keytool -genkeypair -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias morss
```

此时 `ANDROID_KEY_ALIAS` 为 `morss`；其余两项密码按创建时的实际值填写。固定保存该 keystore，用于后续版本升级签名。

[签名准备脚本](../../tools/prepare_android_signing.py)将 keystore 写入 runner 临时目录，生成权限为 `0600` 的 `android/key.properties`，支持密码中的空格、反斜杠和 Unicode。任务结束时始终清理这两个文件；上传路径仅包含构建产物。

debug 包使用临时 runner 的 debug 密钥。不同签名的 APK 不能直接覆盖安装；需要连续升级时，应配置固定的 release 签名。

### 本地构建使用同一份签名

也可以自行创建被忽略的 `android/key.properties`：

```properties
storeFile=/absolute/path/upload-keystore.jks
storePassword=your-store-password
keyAlias=morss
keyPassword=your-key-password
```

`storeFile` 的相对路径以 `android/` 为基准；Windows 路径可写为 `C:/keys/upload-keystore.jks`。这是 Java Properties 格式，手写时需要转义特殊字符。文件存在但配置不完整时，Gradle 会报错；不存在时，本地 release 构建沿用 debug 签名，CI 则明确生成 debug 构建。

## 验证范围

工作流使用 GitHub 托管的 Linux / Windows runner，Flutter 版本固定，依赖按 `pubspec.lock` 安装，引用的 Actions 固定到具体提交。

本地签名分支测试单独执行：

```sh
python -m unittest discover -s tools/tests -p 'test_*.py' -v
```

测试使用合成数据，验证模式选择、配置缺失、Base64、Properties 转义、文件权限和既有文件保护；真实 keystore 的密码、别名与 APK 签名由 Android 构建验证。

2026-09-13 的[运行 34706736742](https://github.com/conice/Morss/actions/runs/34706736742)针对界面示例版本 `c810ff9`，已通过 Verify、Web release、Windows x64 release 与 Android 签名 release 构建，三份产物均已上传。Android 前两次因 keystore 无法读取而失败；签名 Secrets 更新后，单独重跑 Android 的第三次尝试通过，原签名错误未复现。实施与逐项验证记录见[任务 03](../../.scratch/morss/issues/03-github-build-workflow.md)。

真实订阅版本 `146b1ac` 的[运行 34721865778](https://github.com/conice/Morss/actions/runs/34721865778)已通过 Verify、Web release、Windows x64 release 与 Android APK 构建，三份产物均已上传。该版本包含 SQLite 原生库、应用数据目录和浏览器插件；实际安装、数据持久化与浏览器唤起仍需在设备上验证，见[任务 04](../../.scratch/morss/issues/04-live-subscriptions.md)。

订阅管理增量使用 `file_picker` 接入 Android / Windows 系统文件对话框；OPML 控制器与界面各有独立测试步骤。该增量的本地与平台验证记录见[任务 05](../../.scratch/morss/issues/05-subscription-management.md)，之前版本的构建成功不能代替新插件的构建及真实文件操作验证。
