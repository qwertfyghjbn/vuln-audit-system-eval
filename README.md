# vuln-audit-system-eval

这个仓库用于整理 `LLM / agentic vulnerability audit systems` 的评估数据、收口报告和归因实验材料。

当前仓库覆盖四条已经完成第一轮收口的实验主线：

1. `OpenAnt`
2. `DeepAudit`
3. `IRIS`
4. `Architecture Attribution`

仓库目标不是提供可运行应用，而是提供：

- 可回链的 benchmark case 与源码快照
- 单系统评估报告与规范化 registry
- 跨系统 canonical results / failure taxonomy / 总报告
- 架构归因实验的证据包

## 当前收口状态

当前第一轮收口已经完成，核心总表位于：

- `reports/cross_system/canonical_results.tsv`

当前 canonical scope 为：

- `OpenAnt`: `8` 行
- `DeepAudit`: `13` 行
- `IRIS`: `22` 行
- `Architecture Attribution`: `9` 行

总计：

- `52` 行 canonical results

## 四条实验主线的梗概结论

### 1. `OpenAnt`

- `OpenAnt` 能命中部分 benchmark target，尤其是较小、较直接的 case。
- 在更大的 repo case 上，它更像 `broad scanner`，会优先产出真实但非 target-local 的安全问题。
- `verify` 更像风险复核器，不是 benchmark target 重锚器。

一句话收口：

> `OpenAnt` 的价值在于自由 repo 审计和宽召回，但它并不天然是 target-local benchmark verifier。

### 2. `DeepAudit`

- `A / instant analysis` 是当前最清晰的基础语义上界。
- `C / 完整 repo + target_files` 是当前最接近可用的受控 repo 工作流。
- `D / 完整 repo，无 target_files` 仍能恢复 target signal，但更像高成本硬换收敛。

一句话收口：

> `DeepAudit` 的优势在于自由 repo 审计可以恢复 target-aligned reasoning，但只有在受控收窄下，这种能力才更稳定地转化为可用输出。

### 3. `IRIS`

- `IRIS` 当前已不是“跑不起来”，而是“能跑完，但经常没有 target signal”。
- 官方 case 线支持“弱复现”和“失败分化”，不支持“稳定等价复现”。
- `candidate-selection` 是真实脆弱点，但不是多数 failure family 的统一第一主因。

一句话收口：

> `IRIS-style static-gated workflow` 的问题是多层级表示约束，而不是单一前层 gate 问题。

### 4. `Architecture Attribution`

- `static-tool constraint strength` 已足够被视为重要解释变量之一。
- 但它不是唯一解释变量；不同 family 的恢复条件不同。
- 更自由的工作流能恢复 target reasoning，但不自动等于稳定恢复 `fixed-side guard semantics`。
- 当前实验支持：`IRIS-style static-gated workflow` 确实会限制 LLM 的语义发挥，但限制的主因不是简单的“工具权威压制 LLM”，而更像是“静态标签 / 路径表示 + 缺少目标链 framing / 差分 framing”。
- 同时，`DeepAudit / 自由审计` 在某些单侧语义链 case 上确实表现出低信息条件下的架构优势，但在 `vulnerable/fixed pair` 上仍不天然具备稳定差分解释能力。

一句话收口：

> 放开工作流能帮助恢复 target-aligned reasoning，但只有在 local semantic framing、bridge semantics 和 fixed-side guard understanding 也恢复时，这种自由度才会转化为可靠的差分理解。

## 快速导航

### 跨系统总入口

- 总报告：`reports/cross_system/overall_report.md`
- canonical 结果表：`reports/cross_system/canonical_results.tsv`
- canonical scope 清单：`reports/cross_system/canonical_scope_manifest.md`
- failure taxonomy：`reports/cross_system/failure_taxonomy.md`

### 单系统入口

- `OpenAnt`：`reports/systems/openant/README.md`
- `DeepAudit`：`reports/systems/deepaudit/README.md`
- `IRIS`：`reports/systems/iris/README.md`
- `Architecture Attribution`：`reports/systems/architecture-attribution/README.md`

### 关键单系统总结

- `OpenAnt` 学习报告：`reports/systems/openant/summaries/openant_learning_report.md`
- `DeepAudit` 边界总结：`reports/systems/deepaudit/summaries/boundary_expansion_summary.md`
- `IRIS` 总体学习报告：`reports/systems/iris/summaries/iris_learning_evaluation_overall_report.md`
- `Architecture Attribution` 总报告：`reports/systems/architecture-attribution/summaries/overall_architecture_attribution_report.md`

### 数据与证据

- benchmark 数据集：`datasets/`
- 原始与半原始证据：`artifacts/`
- 人读报告入口：`reports/`

## 仓库结构

```text
datasets/
  synthetic/
  real_world/

artifacts/
  architecture_attribution/
  deepaudit_boundary_expansion/
  deepaudit_minimal_expansion/
  iris_case_trustworthiness/
  iris_candidate_selection_dominance/
  iris_smoke/

reports/
  cross_system/
  systems/

docs/
scripts/
```

## 阅读顺序建议

如果你第一次进入这个仓库，建议按下面顺序看：

1. `reports/cross_system/overall_report.md`
2. `reports/cross_system/canonical_results.tsv`
3. `reports/cross_system/failure_taxonomy.md`
4. 任选一个系统入口继续下钻

如果你只想看“为什么系统之间会出现这种差异”，建议直接看：

1. `reports/systems/architecture-attribution/summaries/overall_architecture_attribution_report.md`
2. `reports/systems/iris/summaries/iris_candidate_selection_all7_formal_results.md`
3. `reports/systems/deepaudit/summaries/boundary_expansion_summary.md`
4. `reports/systems/openant/summaries/openant_round1_failure_taxonomy.md`

## 说明

- `artifacts/` 负责保留证据，`reports/` 负责组织结论。
- 这不是 leaderboard 仓库，也不是单一系统的产品代码仓库。
- 当前结论对应“第一轮收口版本”，后续若继续补实验，应优先更新 `reports/cross_system/canonical_scope_manifest.md` 与 `canonical_results.tsv`。
