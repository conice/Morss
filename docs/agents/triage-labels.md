# Triage Labels

分诊角色与本项目任务状态使用以下对应关系。

| 技能角色 | 本项目标签 | 含义 |
| --- | --- | --- |
| `needs-triage` | `needs-triage` | 等待维护者评估 |
| `needs-info` | `needs-info` | 等待补充信息 |
| `ready-for-agent` | `ready-for-agent` | 需求充分，可交由代理实施 |
| `ready-for-human` | `ready-for-human` | 需要人工实施 |
| `wontfix` | `wontfix` | 不予处理 |

技能提到某个分诊角色时，使用对应标签；本地 Markdown 的实现任务将其记录在顶部的 `Status:` 行。以后调整标签名称时只修改本表的第二列。
