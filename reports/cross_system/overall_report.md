# 四大实验综合总报告

## 1. 文档定位

这份文档是当前仓库收尾阶段的总入口。

它的目标不是新增实验，而是把已经完成的四条实验线统一收口：

1. `OpenAnt`
2. `DeepAudit`
3. `IRIS`
4. `Architecture Attribution Experiment`

它回答的问题是：

- 每条实验线各自解决了什么问题
- 当前已经形成了哪些稳定结论
- 哪些结论只应停留在 line-level，不应跨线外推
- 后续 `canonical results` 与 `failure taxonomy` 应如何引用这些材料

## 2. 统一证据入口

| 实验线 | 本仓库稳定入口 | 当前角色 |
|---|---|---|
| `OpenAnt` | [reports/systems/openant/README.md](/home/lqs/llm_audit_system_learning/reports/systems/openant/README.md:1) | 外部证据导入后的本仓库统一入口 |
| `DeepAudit` | [reports/systems/deepaudit/README.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/README.md:1) | `repo-oriented` 审计器学习线 |
| `IRIS` | [reports/systems/iris/README.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/README.md:1) | `IRIS-style static-gated workflow` 学习线 |
| `Architecture Attribution` | [reports/systems/architecture-attribution/README.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/README.md:1) | 独立的 workflow 架构归因线 |

## 3. 当前建议的总报告结构

### 3.1 `OpenAnt`

主入口：

- [openant_learning_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/openant/summaries/openant_learning_summary.md:1)
- [openant_learning_report.md](/home/lqs/llm_audit_system_learning/reports/systems/openant/summaries/openant_learning_report.md:1)
- [openant_case_matrix.csv](/home/lqs/llm_audit_system_learning/reports/systems/openant/registries/openant_case_matrix.csv:1)

当前最稳妥的结论是：

1. `OpenAnt` 在小范围 case 上可以直接命中 benchmark target，例如 `PT-PY-FILE-001`。
2. 但在更大的 repo case 上，它更像 `broad scanner`，会优先枚举仓库里的真实安全问题，而不是自动收敛到 benchmark target。
3. `verify` 的作用更接近“危险性复核器”，不是“benchmark anchor 对齐器”。
4. `unit partition` 与 `relation` 受控实验已经足够说明：先前若干看似巨大的差异，主要来自 parse scope 或实验口径，而不是稳定的结构优势。

因此，对 `OpenAnt` 的收口不应写成“整体更强”，而应写成：

> `OpenAnt` 的主要价值在于自由 repo 审计和宽召回；它能命中 target，但并不天然是 target-local benchmark verifier。

### 3.2 `DeepAudit`

主入口：

- [learning_run_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/summaries/learning_run_summary.md:1)
- [boundary_expansion_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/summaries/boundary_expansion_summary.md:1)
- [minimal_expansion_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/summaries/minimal_expansion_summary.md:1)

当前最稳妥的结论是：

1. `A / instant analysis` 是当前最清晰的基础语义上界。
2. `C / 完整 repo + target_files` 是当前最接近受控可用的 repo 工作流形态。
3. `C-real-world` 的可用性不再只建立在单个 `PT` 项目线上，已经得到第二条 real-world 与第二类漏洞家族支撑。
4. `D / 完整 repo，无 target_files` 仍然能恢复 target signal，但更像“用高成本硬换收敛”，而不是日常可用形态。

因此，对 `DeepAudit` 的收口不应写成“自由度越高越强”，而应写成：

> `DeepAudit` 的优势在于自由 repo 审计可以恢复 target-aligned reasoning，但只有在受控收窄下，这种能力才更稳定地转化为可用输出。

### 3.3 `IRIS`

主入口：

- [iris_learning_evaluation_overall_report.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_learning_evaluation_overall_report.md:1)
- [iris_official_case_claim_vs_local_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_official_case_claim_vs_local_summary.md:1)
- [iris_candidate_selection_all7_formal_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_candidate_selection_all7_formal_results.md:1)

当前最稳妥的结论是：

1. `IRIS` 在当前本地环境下已经不是“跑不起来”，而是“能稳定跑完，但经常没有 target signal”。
2. 官方 case 线支持“弱复现”与“失败分化”，不支持“稳定等价复现”。
3. `candidate-selection` 是一个真实脆弱点，但不是大多数 failure family 的统一第一主因。
4. 更常见的主断点发生在 `summary/path`、`query semantics`、`exception transport bridge`、`target alignment` 和 `LLM variance` 这些更下游层。

因此，对 `IRIS` 的收口不应写成“主要就是 candidate 不够”，而应写成：

> `IRIS-style static-gated workflow` 的问题是真实的多层级表示约束，而不是单一前层 gate 问题。

### 3.4 `Architecture Attribution`

主入口：

- [overall_architecture_attribution_report.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/overall_architecture_attribution_report.md:1)
- [e1_static_gate_oracle_progress_report.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e1_static_gate_oracle_progress_report.md:1)
- [e2_ssrf3432_pair_differential_freedom_report.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e2_ssrf3432_pair_differential_freedom_report.md:1)
- [e4_ssrf3432_deepaudit_information_control_report.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e4_ssrf3432_deepaudit_information_control_report.md:1)
- [e4_cronutils_deepaudit_information_control_report.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e4_cronutils_deepaudit_information_control_report.md:1)

当前最稳妥的结论是：

1. `Static-tool Constraint Strength` 已足够被视为重要解释变量之一。
2. 但它不是唯一解释变量；不同 family 的恢复条件不同。
3. `SSRF-JA-REPO-001` 说明 candidate gate 存在，但最终恢复仍依赖最小 `summary/path` 物化语义。
4. `SSRF-3432 pair` 说明真正关键的是 `local differential framing` 与 `fixed-side guard semantics`，而不是继续扩大 candidate 或 slice。
5. `cron-utils` 说明在某些 family 上，自由 repo 审计本身就足以恢复目标异常消息链，因此这里更像真实架构优势，而不是单纯信息优势。

因此，这条线的收口应写成：

> `static-gated workflow` 会限制模型，但放开工作流之后，系统仍然需要强的 local semantic framing、bridge semantics 和 fixed-guard understanding，才能稳定恢复 benchmark 目标差分。

## 4. 当前跨线综合结论

把四条实验线合在一起，当前最稳妥的综合判断有五条。

1. `OpenAnt` 与 `DeepAudit` 都证明了“更自由的审计形态”可以恢复 `IRIS-style` 更难恢复的目标语义，但它们恢复出来的能力不是同一种。
2. `OpenAnt` 更接近“自由 broad scanner + verify 复核器”，因此它的主要风险是 `off-target` 与不重锚。
3. `DeepAudit` 更接近“受控收窄时可用的 repo auditor”，因此它的主要风险是 `D-shape` 下的高成本和 broad-scan noise。
4. `IRIS` 的失败分布已经足够说明：如果后续要迁移机制，不应只盯着 candidate gate，而应优先关注 `summary/path`、`bridge semantics`、`target framing` 与 `fixed-side guard understanding`。
5. `Architecture Attribution` 已经把这些现象连接成更高层解释：
   `static-tool constraint strength` 重要，但它只解释“为什么语义会丢”，不自动解释“语义怎样才能稳定恢复”。

## 5. 与 `canonical_results.tsv` 的关系

[canonical_results.tsv](/home/lqs/llm_audit_system_learning/reports/cross_system/canonical_results.tsv:1) 应承担的是“统一字段映射”，不是“替代四条长报告”。

当前表中写入的是“代表性 canonical 行”，而不是所有历史 run。每一行至少承担以下三种作用之一：

1. 给一条实验线提供正例锚点。
2. 给一条实验线提供典型失败形状。
3. 给综合结论提供可回链的最小证据。

因此总报告中的每一条高层结论都应满足：

1. 能回链到某条单系统或单实验线的稳定入口。
2. 能说明它属于 `case-level result`、`family-level interpretation`，还是 `experiment-level conclusion`。
3. 不把不同口径的运行结果硬合并成同一分数。

## 6. 当前阶段最需要避免的混写

当前最容易发生的错误有三类：

1. 把 `off-target but real security issue` 直接当成 `target_hit`。
2. 把 `case-level failure mode` 与 `experiment-level attribution conclusion` 混进同一列。
3. 把外部工作区中的一次性 artifacts 直接当成 GitHub 仓库里的稳定入口。

## 7. GitHub 提交前检查项

提交前至少应确认：

1. `overall_report.md` 的主要链接优先指向本仓库 `reports/` 下入口。
2. `OpenAnt` 入口只依赖本仓库内链接，不再依赖外部绝对路径。
3. `canonical_results.tsv` 的每一行都能回链到本仓库中稳定存在的摘要、对照或 matrix。
4. `failure_taxonomy.md` 中的 `experiment-level attribution conclusion` 没有被误写进 `failure_mode_*` 字段。

## 8. 当前收口判断

如果只用一句话概括当前四大实验综合结论，应写成：

> 当前证据已经足够支持：`IRIS-style static-gated workflow` 的表现差异确实部分来自架构约束；更自由的审计结构能够恢复 target-aligned reasoning，但只有在 target-local semantics、bridge semantics 与 fixed-side guard understanding 也被稳定恢复时，这种自由度才会转化为可靠的 benchmark differential understanding。
