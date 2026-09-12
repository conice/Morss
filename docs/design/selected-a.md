# A · 玻璃阅读台

2026-09-12，用户选择“完全复刻 A”，并确认推荐的实施方式：重写为 Flutter 界面，同时保留 A 版网页作为视觉和交互对照。iOS 27 指此次概念视觉风格；交付平台仍是产品规格约定的 Android、Windows。

## 采用内容

浅绿色背景上的玻璃阅读台、深绿文字、衬线文章标题、山林配图与细线图标。桌面三栏保持阅读上下文，手机先显示列表，再进入独立正文。沿用继续阅读卡片、正文来源切换、逐段译文、底部阅读状态和圆角操作面板。

| 布局参数 | A 的约定 |
| --- | --- |
| 手机断点 | 视口宽度 ≤ 760 |
| 紧凑桌面 | 761–1150；订阅栏 178、列表 292 |
| 常规桌面 | 1151–1599；订阅栏 214、列表 354 |
| 大桌面 | ≥ 1600；订阅栏 228、列表 392 |
| 外框 | 最大宽度 1496；桌面左右留白 24、上 52、下 80 |
| 手机外框 | 左右留白 10、上 39、下 73；遵守系统安全区域 |
| 手机导航 | 外框内部左右 20、距底部 84、高 56；沿用 A 实际显示的位置 |
| 圆角与模糊 | 外框 28，手机 23；背景模糊 40 |
| 滚动区域 | 为 A 的滚动条保留 5px 空间 |
| 正文 | 默认 15px，手机增加 1px；可调整 13–22px |
| 字体 | 共用 Noto Sans SC 与 Noto Serif SC，附 OFL 许可证 |

Flutter 数值在 [`reader_theme.dart`](../../lib/design/reader_theme.dart) 中维护。正文和列表使用同一套本地图片与 [`reader_demo.json`](../../assets/data/reader_demo.json)，避免内容不同干扰比较。浏览器与 Flutter 的文字栅格化、滚动条和系统安全区域可能存在平台差异。

## 实现边界

Flutter 使用独立的控制器和类型化模型组织界面状态；网页只是 A 的对照来源。两者都使用内存示例，不读写真实阅读数据库，也不发送订阅、模型或同步请求。文档中的服务、备份周期等文案用于展示既定产品流程，不表示相关后台能力已实现。

已覆盖的交互边界包括：收藏与归档分离；正文版本分别续读；生成、切换译文或引用定位不标已读；实际滚到末尾才标已读；清理普通缓存保留归档；仅恢复归档不恢复收藏和配对授权；手动收藏决定优先于规则。

## 验证

验证记录、执行命令和平台限制保存在[实现任务](../../.scratch/morss/issues/02-implement-selected-a.md)。浏览器截图保存在 [`design/screenshots/`](../../design/screenshots/)，包含同尺寸的网页对照和 Flutter 实际渲染，不能用来替代 Android / Windows 安装验收。

截图工具使用 Node 22+ 和本机 Chromium DevTools 端口。两个预览服务启动后，在单独终端启动浏览器：

```sh
chromium-browser --headless --no-sandbox --disable-dev-shm-usage --disable-gpu \
  --no-first-run --no-default-browser-check --remote-debugging-port=9222 \
  --user-data-dir="${TMPDIR:-/tmp}/morss-ui-capture" about:blank
```

在另一个终端逐条执行截图命令：

```sh
node tools/capture_ui.cjs http://127.0.0.1:8787/ design/screenshots/reference-a-desktop.png 1440 960
node tools/capture_ui.cjs http://127.0.0.1:8788/ design/screenshots/flutter-a-desktop.png 1440 960
```

每次只运行一条截图命令，等待结果后再继续。使用 `--dark` 捕获深色模式；`--click=x,y` 可在同一视口下进入文章或面板，例如 390 × 844 下用 `--click=145,460` 进入第一篇文章。浏览器调试端口仅用于本地截图。

Flutter 的首帧事件早于图片解码完成。截图工具默认在 Flutter 首帧及点击操作后再等待 10 秒，避免软件渲染环境中的首帧空白图片；可以用 `--settle-ms=15000` 调整。网页对照等待字体和图片加载完成。这个等待只用于截图工具，不改变应用的启动和绘制流程。

| 画面 | A 网页 | Flutter |
| --- | --- | --- |
| 桌面 1440 × 960 | [查看](../../design/screenshots/reference-a-desktop.png) | [查看](../../design/screenshots/flutter-a-desktop.png) |
| 手机列表 390 × 844 | [查看](../../design/screenshots/reference-a-mobile.png) | [查看](../../design/screenshots/flutter-a-mobile.png) |
| 手机正文 390 × 844 | [查看](../../design/screenshots/reference-a-mobile-reader.png) | [查看](../../design/screenshots/flutter-a-mobile-reader.png) |
| 深色桌面 1440 × 960 | [查看](../../design/screenshots/reference-a-dark.png) | [查看](../../design/screenshots/flutter-a-dark.png) |

玻璃外框的阴影只绘制在外框之外，避免 Flutter 的填充阴影透过半透明背景、使界面比 A 偏灰。背景光晕沿用 A 的椭圆形状；正文保留网页中相邻段落、标题与引用外边距合并后的间距。

## 原始来源

完整 A/B/C 实验保存在分支 `prototype/ios-glass-abc`，提交 `ee16af178b3043c099c5a204bd224e3eb4182814` 的 `.scratch/morss/prototype/`。原型回答了布局选择问题；Flutter 界面是采用 A 后的重写。B、C 和实验切换栏不进入主分支。
