# OpenAnt 学习收口摘要

## 1. 文档定位

这份文档是当前仓库对 `OpenAnt` 相关实验的本地收口入口。

它不是原始实验报告的替代品，而是为了：

1. 给本仓库的 `cross_system` 综合文档提供稳定引用点。
2. 把外部工作区中的 `OpenAnt` 结论按本仓库语言重新组织。
3. 避免四大实验总报告直接深链到大量外部一次性 artifacts。

## 2. 当前证据范围

当前摘要主要依赖以下本地材料：

- [OpenAnt 学习报告](/home/lqs/llm_audit_system_learning/reports/systems/openant/summaries/openant_learning_report.md:1)
- [OpenAnt 首轮 failure taxonomy](/home/lqs/llm_audit_system_learning/reports/systems/openant/summaries/openant_round1_failure_taxonomy.md:1)
- [unit partition 文件对比报告](/home/lqs/llm_audit_system_learning/reports/systems/openant/comparisons/unit_partition_diff_report.md:1)
- [E1 实验报告](/home/lqs/llm_audit_system_learning/reports/systems/openant/comparisons/e1_experiment_report.md:1)
- [E2 实验报告](/home/lqs/llm_audit_system_learning/reports/systems/openant/comparisons/e2_experiment_report.md:1)

## 3. 当前可稳定引用的结论主题

当前 `OpenAnt` 线至少可以按以下三个主题收口：

1. `OpenAnt` 在部分 case 上能形成真实 target signal，但整体更像 `broad scanner`，不天然等于 benchmark target verifier。
2. `verify` 更像危险性复核器，而不是 benchmark anchor 对齐器。
3. `unit partition` 与 `parent relation` 的受控实验已经足够说明：先前若干强差异主要来自实验口径问题，不应直接外推成稳定结构优势。

## 4. 当前不应过度宣称的事项

当前还不应写成稳定结论的内容包括：

- `OpenAnt` 整体优于当前系统
- `unit partition` 单独解释了 `OpenAnt` 的主要优势
- `parent relation` 是默认可迁移修复方向

## 5. 后续补写方向

后续应把这份摘要补成完整本地总结，至少覆盖：

1. round1 case matrix 的目标命中、off-target 和 near-miss 画像
2. `verify` 对噪声的削减边界
3. `E1 / E2` 受控实验如何收缩了早期看似显著的 partition 差异
4. 哪些机制值得进入 `V3` 后续设计讨论，哪些只应保留为观察结论
