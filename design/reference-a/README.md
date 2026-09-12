# A · 玻璃阅读台对照页

用户已选择“完全复刻 A”，并确认重写为 Flutter、保留 A 网页作为对照。此目录保存采用的 A，供核对视觉与交互；完整 A/B/C 实验另有 Git 归档。

## 启动

在项目根目录执行：

```sh
python tools/serve.py reference
```

打开 <http://127.0.0.1:8787/>，用 `Ctrl+C` 停止。可用 `--port 8790` 更换端口。页面通过 HTTP 加载共用示例 JSON，需要使用此服务启动。

Flutter 预览使用另一终端中的 `python tools/serve.py flutter`，地址为 <http://127.0.0.1:8788/>；首次运行先按[根目录说明](../../README.md)构建 Web。

## 可以核对的内容

桌面三栏、手机列表进入正文、继续阅读、明暗外观、字号、来源与收藏筛选、搜索、正文版本切换、逐段对照、摘要引用，以及设备、规则、服务和恢复面板。

在第一篇文章取消收藏，再进入“保留归档”，可以核对收藏标记与已保存内容的区别。示例配对码为 `426 810`；问答返回预设结果。所有状态都保存在内存，刷新页面会重置，不发送真实订阅、模型或设备同步请求，不进行数据库写入或加密备份。

在开发者控制台读取 `window.morssReferenceState` 可查看示例状态。B/C、实验切换栏和布局切换快捷键已从对照页移除。页面本身不需要 npm 依赖或外部字体、图片 CDN。

布局数值、截图与已知平台差异见[采用 A 的设计记录](../../docs/design/selected-a.md)；实施边界与分项验证见[实现任务](../../.scratch/morss/issues/02-implement-selected-a.md)。产品行为仍以[总规格](../../.scratch/morss/spec.md)为准，界面示例不等于产品验收完成。

## 共用资源

| 文件 | 用途 |
| --- | --- |
| [index.html](index.html) | A 对照页入口 |
| [reader-reference.css](reader-reference.css) | A 的响应式布局和明暗样式 |
| [reader-reference.js](reader-reference.js) | 内存交互与状态展示 |
| [reader_demo.json](../../assets/data/reader_demo.json) | Flutter 与网页共用的 7 篇文章、6 个虚构订阅源 |
| [assets/icons/](../../assets/icons/) | 从 A 共用的 Morss 标识和细线图标 |
| [assets/fonts/](../../assets/fonts/) | Noto Sans SC、Noto Serif SC 及各自 OFL 许可证 |

## 图片来源

以下照片与原始 A 使用相同文件，保存在 `assets/images/`，运行时不访问图片服务。

| 本地图片 | Unsplash 原始图片地址 |
| --- | --- |
| [mountain.jpg](../../assets/images/mountain.jpg) | <https://images.unsplash.com/photo-1464822759023-fed622ff2c3b> |
| [forest.jpg](../../assets/images/forest.jpg) | <https://images.unsplash.com/photo-1441974231531-c6227db76b6e> |
| [architecture.jpg](../../assets/images/architecture.jpg) | <https://images.unsplash.com/photo-1487958449943-2429e8be8625> |
| [desk.jpg](../../assets/images/desk.jpg) | <https://images.unsplash.com/photo-1499750310107-5fef28a66643> |
| [coast.jpg](../../assets/images/coast.jpg) | <https://images.unsplash.com/photo-1518837695005-2083093ee35b> |

## 原型归档

完整实验位于 `prototype/ios-glass-abc` 分支，提交 `ee16af178b3043c099c5a204bd224e3eb4182814` 的 `.scratch/morss/prototype/`。例如，在项目根目录读取当时的说明：

```sh
git show prototype/ios-glass-abc:.scratch/morss/prototype/README.md
```

归档回答的是布局选择问题；当前 Flutter 界面按[任务 02](../../.scratch/morss/issues/02-implement-selected-a.md)重新实现。
