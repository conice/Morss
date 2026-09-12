# Domain Docs

本项目采用 single-context 布局：根目录 `CONTEXT.md` 保存领域词汇，`docs/adr/` 保存架构决策。

## Before exploring

- 探索代码或设计领域模型前，读取根目录 `CONTEXT.md`，以及 `docs/adr/` 中与当前工作相关的 ADR。
- 文件不存在时直接继续。`domain-modeling` 在术语或决策明确后按需创建它们。

## Vocabulary and decisions

- 在任务、设计、假设和测试命名中使用 `CONTEXT.md` 定义的术语。
- 遇到未定义的概念，先核对它是否属于现有术语；确有缺口时交由 `domain-modeling` 补充。
- 提议与已有 ADR 冲突时，明确列出相应 ADR 和重新讨论的理由。
