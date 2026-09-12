# Morss

按已确认的 **A · 玻璃阅读台** 实现的 Flutter 阅读界面。桌面使用订阅栏、文章列表、正文三栏，手机从列表进入正文；沿用 A 的配色、玻璃背景、图片和线条图标，支持深色模式与字号调整。

Android / Windows 已接入真实 RSS / Atom 订阅和 SQLite 本地阅读库：添加订阅、刷新文章、保存正文文字、阅读位置、已读、收藏、归档和外观设置，重启后可离线阅读。首次启动为空库；原网页可在浏览器中打开。Web 保留 A 的内存示例预览，刷新页面会重置示例数据。

当前增量不包含 OPML、订阅管理增强、图片离线下载、缓存到期清理、网页全文提取、局域网同步、在线翻译 / AI 或备份恢复。原生界面将尚未开放的功能明确标出。产品要求仍以[总规格](.scratch/morss/spec.md)为准，75 项完整产品验收尚未完成；本次范围见[真实订阅与本地保存](.scratch/morss/issues/04-live-subscriptions.md)。

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
flutter pub get --enforce-lockfile
flutter test --no-pub test/reader_controller_test.dart
flutter test --no-pub test/reader_screen_test.dart
flutter test --no-pub test/reader_library_controller_test.dart
flutter test --no-pub test/reader_library_screen_test.dart
flutter analyze --no-pub
```

在常规 Flutter 环境中查看设备并启动：

```sh
flutter devices
flutter run -d chrome
```

Android 连接设备后用 `flutter run -d <设备 ID>`；Windows 环境用 `flutter run -d windows`。已生成两个平台的工程文件和 Morss 应用图标。

当前 Termux 环境中的 SDK 安装在个人工具目录，使用 `bash tools/flutter.sh` 代替 `flutter`，例如：

```sh
bash tools/flutter.sh pub get --enforce-lockfile
bash tools/flutter.sh test --no-pub test/reader_library_controller_test.dart
bash tools/flutter.sh test --no-pub test/reader_library_screen_test.dart
bash tools/flutter.sh analyze --no-pub
bash tools/flutter.sh build web --release --no-pub --no-web-resources-cdn
```

这个入口兼容常规 PATH 中的 Flutter，也可通过 `MORSS_FLUTTER_ROOT` 指定 SDK。Termux 中的 Linux SDK 运行兼容处理只在本机工具目录，不属于应用源码。

原生插件需要创建符号链接，Android 共享存储（如 `/storage/emulated/0/`）不支持这项操作。在 Termux 中请将构建 checkout / worktree 放到应用私有目录，再执行依赖安装、测试和构建。

## GitHub 构建

[Build Morss 工作流](.github/workflows/build.yml)在推送 `main`、推送 `v*` 标签、拉取请求或手动触发时执行。各项测试独立执行，通过后分别生成 Web release、Windows x64 release 和 Android APK，并上传至该次运行的 **Artifacts**，保留 14 天。

Android 的四项签名 Secrets 齐全时生成签名 release APK；均未配置时生成 debug APK，部分配置会明确报错。拉取请求始终生成 debug APK。完整配置、产物下载与本地签名方式见 [GitHub 构建说明](docs/ci/github-actions.md)。

2026-09-13，界面示例版本 `c810ff9` 已通过 GitHub runner 的 Verify、Web release、Windows x64 release 与 Android 签名 release 构建，记录见[任务 03](.scratch/morss/issues/03-github-build-workflow.md)。本轮加入 SQLite 与原生插件后的 Android / Windows 构建及实际安装运行仍待验证，不能沿用上一版的成功结果。

## 原生阅读

- 添加 HTTP(S) RSS / Atom 地址，可填写名称和分类；相同地址合并，同源条目更新保留状态与已有快照。
- 启动、返回前台、使用期间每 30 分钟或手动刷新；后台暂停定时刷新。失败保留已保存内容并显示原因。
- 搜索本机文章与归档，筛选未读、收藏、分类和订阅源；继续上次阅读，保存各正文版本的位置。
- 收藏与归档分别管理；取消收藏保留快照，删除最后一份归档不改变收藏或已读标记。
- 当前保存正文段落文字，图片和源站排版通过原网页查看。数据位于系统应用支持目录中的 `reader.sqlite`，卸载或清除应用数据会删除本机阅读库；当前尚无备份导出。

## Web 示例交互

- 搜索文章、正文与归档；筛选未读、收藏、分类与订阅源；继续上次阅读。
- 切换 RSS 正文、提取全文和归档快照；各正文版本保存自己的阅读位置。
- 收藏与归档分别管理；取消收藏保留快照，删除时确认受影响的附加结果。
- 展示逐段英文对照、摘要引用和预设问答；演示模型选择、结果复用与调用额度。
- 演示设备配对 / 撤销、规则预览 / 执行、选择性恢复和普通缓存清理。

Web 的服务、同步、生成和备份面板均说明示例边界。无需输入真实 API Key 或密码；这些输入不会写入存储。

## 文档与来源

- [采用 A 的设计记录](docs/design/selected-a.md)与[对照页说明](design/reference-a/README.md)。
- [Flutter 界面实现记录](.scratch/morss/issues/02-implement-selected-a.md)。
- [真实订阅与本地保存实现记录](.scratch/morss/issues/04-live-subscriptions.md)。
- [领域词汇](CONTEXT.md)、[原型选择记录](.scratch/morss/issues/01-ios-style-ui-prototype.md)。
- 原始 A/B/C 实验已归档到 `prototype/ios-glass-abc` 分支，提交 `ee16af178b3043c099c5a204bd224e3eb4182814`。主分支仅保留采用的 A。
- 字体许可证位于 `assets/fonts/*-OFL.txt`；示例图片来源见对照页说明。
