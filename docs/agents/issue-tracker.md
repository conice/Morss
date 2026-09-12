# Issue tracker: Local Markdown

任务与功能规格保存在 `.scratch/`，以本地文件为任务跟踪记录。

## Conventions

- 每个功能使用一个目录：`.scratch/<feature-slug>/`。
- 功能规格：`.scratch/<feature-slug>/spec.md`。
- 每张实现任务单独保存为 `.scratch/<feature-slug>/issues/<NN>-<slug>.md`，从 `01` 起编号。
- 实现任务顶部的 `Status:` 使用 [triage-labels.md](triage-labels.md) 中的标签字符串。
- 评论与讨论追加在文件末尾的 `## Comments` 下。
- 产品总规格为 `.scratch/morss/spec.md`；功能规格及任务引用总规格相关条款，确认状态以总规格为准。

## Publish and fetch

- 发布功能规格或任务时，按上面的路径分别创建文件及所需目录。
- 获取任务时，读取用户引用的文件；只有编号时，结合所属功能目录定位，无法唯一定位时再澄清。

## Wayfinding operations

`wayfinder` 的探索票使用以下独立状态约定。

- Map：`.scratch/<effort>/map.md`，包含 Notes、Decisions-so-far、Fog。
- 子票：`.scratch/<effort>/issues/<NN>-<slug>.md`，从 `01` 起编号，正文写要解决的问题。
- `Type:` 为 `research`、`prototype`、`grilling` 或 `task`；`Status:` 为 `open`、`claimed` 或 `resolved`。
- `Blocked by: NN, NN` 列出依赖；依赖全部为 `resolved` 后才可执行。
- Frontier：按编号选择首张 open、未被领取且依赖已解决的子票。
- Claim：开始工作前保存 `Status: claimed`。
- Resolve：在 `## Answer` 下追加答案，设为 `Status: resolved`，并在 map 的 Decisions-so-far 中追加结论摘要及子票链接。
