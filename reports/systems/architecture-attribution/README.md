# Architecture Attribution 结果入口

## 1. 作用

这个目录是 `Architecture Attribution Experiment` 的统一人读入口。

它与 `IRIS`、`DeepAudit` 的系统评估线同级，但不代表一个新的被评估产品。它的目标是隔离和解释 workflow 架构变量，尤其是 `Static-tool Constraint Strength` 对 LLM 漏洞审计能力的影响。

## 2. 当前状态

当前阶段是规划阶段，尚未形成正式运行结果。

已冻结的规划边界包括：

- 主归因对象：`IRIS-style static-gated workflow`
- 外部参照：`DeepAudit`
- 第一轮暂不把 `OpenAnt` 放入主矩阵
- 第一轮使用 3 个 `Case Family`
- `Differential Semantic Evaluation` 作为共享评价轴
- 证据层独立写入 `artifacts/architecture_attribution/`

## 3. 当前模块地图

- `runbooks/`
  - 实验规划、运行约束、模式矩阵
- `summaries/`
  - 后续阶段结论和收口文档
- `registries/`
  - 后续 run inventory、case matrix、evidence index
- `comparisons/`
  - 后续跨模式、跨系统参照、信息优势控制比较

## 4. 边界规则

- 本实验线的结果不得写入 `reports/systems/iris/` 或 `artifacts/iris_*`。
- 本实验线可以引用既有 IRIS、DeepAudit、OpenAnt 证据，但新运行证据应独立保存在 `artifacts/architecture_attribution/`。
- 如果后续引入 `OpenAnt`，应作为第二阶段扩展，而不是 retroactively 改写第一轮主矩阵。

## 5. 主要入口

- [architecture_attribution_experiment_plan.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/architecture_attribution_experiment_plan.md:1)
- [e1_static_gate_oracle_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e1_static_gate_oracle_runbook.md:1)
- [e2_cronutils_five_level_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e2_cronutils_five_level_runbook.md:1)
- [e2_cronutils_execution_checklist.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e2_cronutils_execution_checklist.md:1)
- [e2_ssrf3432_pair_differential_freedom_ladder_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e2_ssrf3432_pair_differential_freedom_ladder_runbook.md:1)
- [e2_ssrf3432_pair_execution_checklist.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e2_ssrf3432_pair_execution_checklist.md:1)
- [ADR 0001](/home/lqs/llm_audit_system_learning/docs/adr/0001-architecture-attribution-as-independent-experiment-line.md:1)
