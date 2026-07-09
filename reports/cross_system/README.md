# 跨实验综合入口

这个目录用于存放当前仓库的综合收尾产物。

它的职责不是新增一轮 `cross-system experiment`，而是把已经完成的几条实验线收口成统一的人读入口：

- `IRIS`
- `DeepAudit`
- `OpenAnt`
- `Architecture Attribution Experiment`

## 当前主要入口

- [canonical_results.tsv](/home/lqs/llm_audit_system_learning/reports/cross_system/canonical_results.tsv:1)
- [failure_taxonomy.md](/home/lqs/llm_audit_system_learning/reports/cross_system/failure_taxonomy.md:1)
- [overall_report.md](/home/lqs/llm_audit_system_learning/reports/cross_system/overall_report.md:1)

## 与 `systems/` 的边界

- `reports/systems/<system-id>/`
  - 负责单条实验线的运行说明、阶段总结、局部 registry 和内部比较。
- `reports/cross_system/`
  - 负责把多条实验线映射到统一字段、统一 taxonomy 和统一总报告中。

简单说：

> `systems/` 负责“各自怎么做、各自看到了什么”，`cross_system/` 负责“如何用同一语言收口这些结果”。

## 当前落盘规则

1. `canonical_results.tsv` 只放稳定字段，不把一次性 run id 写进文件名。
2. `failure_taxonomy.md` 只定义共享术语和判定边界，不重复复制单系统长报告。
3. `overall_report.md` 作为四大实验线的总入口，优先链接 `reports/systems/...` 下的稳定文档。
