# Morss

按已确认的 **A · 玻璃阅读台** 实现的 Flutter 阅读界面。桌面使用订阅栏、文章列表、正文三栏，手机从列表进入正文；沿用 A 的配色、玻璃背景、图片和线条图标，支持深色模式与字号调整。

当前交付的是可运行的界面和内存示例交互。订阅抓取、SQLite、真实全文提取、局域网同步、在线翻译 / AI、加密备份尚未实现；刷新应用会重置示例数据。产品要求仍以[总规格](.scratch/morss/spec.md)为准，其中 75 项产品验收尚未执行。

## 预览

已构建过 Flutter Web 时，在项目根目录执行：

```sh
python tools/serve.py flutter
```

打开 <http://127.0.0.1:8788/>。首次准备或修改 Flutter 代码后先构建：

```sh
flutter pub get
flutter build web --release --no-web-resources-cdn
```

A 版网页对照使用相同的文章、图片和字体，无需 Flutter：

```sh
python tools/serve.py reference
```

打开 <http://127.0.0.1:8787/>。两个预览服务在各自终端运行，用 `Ctrl+C` 停止。Web 是界面对照入口；既定原生交付平台仍为 Android、Windows。

## 开发与构建

本次使用 Flutter 3.47.4 / Dart 3.13.3。验证分开执行，每条命令返回后再运行下一条：

```sh
flutter test test/reader_controller_test.dart
flutter test test/reader_screen_test.dart
flutter analyze
```

在常规 Flutter 环境中查看设备并启动：

```sh
flutter devices
flutter run -d chrome
```

Android 连接设备后用 `flutter run -d <设备 ID>`；Windows 环境用 `flutter run -d windows`。已生成两个平台的工程文件和 Morss 应用图标。

当前 Termux 环境中的 SDK 安装在个人工具目录，使用 `bash tools/flutter.sh` 代替 `flutter`，例如：

```sh
bash tools/flutter.sh test test/reader_controller_test.dart
bash tools/flutter.sh test test/reader_screen_test.dart
bash tools/flutter.sh analyze
bash tools/flutter.sh build web --release --no-web-resources-cdn
```

这个入口兼容常规 PATH 中的 Flutter，也可通过 `MORSS_FLUTTER_ROOT` 指定 SDK。Termux 中的 Linux SDK 运行兼容处理只在本机工具目录，不属于应用源码。

## GitHub 构建

[Build Morss 工作流](.github/workflows/build.yml)在推送 `main`、推送 `v*` 标签、拉取请求或手动触发时执行。各项测试独立执行，通过后分别生成 Web release、Windows x64 release 和 Android APK，并上传至该次运行的 **Artifacts**，保留 14 天。

Android 的四项签名 Secrets 齐全时生成签名 release APK；均未配置时生成 debug APK，部分配置会明确报错。拉取请求始终生成 debug APK。完整配置、产物下载与本地签名方式见 [GitHub 构建说明](docs/ci/github-actions.md)。

工作流已配置；GitHub runner 的实际构建及 Android / Windows 安装运行仍需验证，记录见[任务 03](.scratch/morss/issues/03-github-build-workflow.md)。

## 界面交互

- 搜索文章、正文与归档；筛选未读、收藏、分类与订阅源；继续上次阅读。
- 切换 RSS 正文、提取全文和归档快照；各正文版本保存自己的阅读位置。
- 收藏与归档分别管理；取消收藏保留快照，删除时确认受影响的附加结果。
- 展示逐段英文对照、摘要引用和预设问答；演示模型选择、结果复用与调用额度。
- 演示设备配对 / 撤销、规则预览 / 执行、选择性恢复和普通缓存清理。

服务、同步、生成和备份面板均说明示例边界。无需输入真实 API Key 或密码；这些输入不会写入存储。

## 文档与来源

- [采用 A 的设计记录](docs/design/selected-a.md)与[对照页说明](design/reference-a/README.md)。
- [Flutter 界面实现记录](.scratch/morss/issues/02-implement-selected-a.md)。
- [领域词汇](CONTEXT.md)、[原型选择记录](.scratch/morss/issues/01-ios-style-ui-prototype.md)。
- 原始 A/B/C 实验已归档到 `prototype/ios-glass-abc` 分支，提交 `ee16af178b3043c099c5a204bd224e3eb4182814`。主分支仅保留采用的 A。
- 字体许可证位于 `assets/fonts/*-OFL.txt`；示例图片来源见对照页说明。
