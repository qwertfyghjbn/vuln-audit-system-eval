# `canonical_results.tsv` 纳入范围清单

## 1. 文档定位

这份清单用于冻结 [canonical_results.tsv](/home/lqs/llm_audit_system_learning/reports/cross_system/canonical_results.tsv:1) 的纳入范围。

它回答三个问题：

1. 哪些结果行必须进入最终收口表。
2. 哪些材料明确不进入最终收口表。
3. 为什么某些实验虽然重要，但只保留在 `comparisons/`、`summaries/` 或总报告中。

这份清单不是：

- 原始 run inventory
- 逐条 case 结果表
- 新一轮评估计划

## 2. 全局规则

### 2.1 允许的行粒度

`canonical_results.tsv` 只允许两种粒度：

1. `case-level row`
   - 一行对应一个 `case_id × system_id × system_mode`
2. `pair/family-level row`
   - 只有当实验本身的最小结果单位就是 `pair` 或 family-level mode 时才允许
   - 当前主要对应 `Architecture Attribution`

### 2.2 不纳入的内容类型

以下内容默认不纳入 `canonical_results.tsv`：

- 纯环境验证
- 纯结构对比
- parser/backlog/diagnosis 说明
- 单纯为解释优势来源而设计的 controlled experiment
- pending / not run / 仍未收口的实验占位

### 2.3 表的目标

最终 `canonical_results.tsv` 的目标是：

- 覆盖四条实验线的稳定结果
- 支撑 [overall_report.md](/home/lqs/llm_audit_system_learning/reports/cross_system/overall_report.md:1) 的综合结论
- 保持规模可读，不退化成 raw dump

## 3. OpenAnt

### 3.1 必须纳入

纳入范围：

- `round1 learning / evaluation` 的 8 个 benchmark case

当前来源：

- [openant_case_matrix.csv](/home/lqs/llm_audit_system_learning/reports/systems/openant/registries/openant_case_matrix.csv:1)
- [openant_learning_report.md](/home/lqs/llm_audit_system_learning/reports/systems/openant/summaries/openant_learning_report.md:1)
- [openant_round1_failure_taxonomy.md](/home/lqs/llm_audit_system_learning/reports/systems/openant/summaries/openant_round1_failure_taxonomy.md:1)

预期规模：

- `8` 行

纳入原因：

- 这是 `OpenAnt` 作为 benchmark-facing auditor 的主结果面
- 字段可稳定映射到 `target_hit / off_target / failure_mode / conclusion`
- 已经足够支撑 `OpenAnt` 在总报告中的主要结论

### 3.2 明确不纳入

不纳入范围：

- `unit_partition_compare`
- `unit_partition_controlled_eval E1`
- `unit_partition_controlled_eval E2`
- 逐文件结构差异、parser backlog、module backlog

不纳入原因：

- 它们回答的是“优势从哪里来”，不是“benchmark 结果是什么”
- 这些实验更适合进入 `comparisons/` 与总报告中的 `information_advantage_controlled` 叙事
- 若强行纳入，会把结果表与机制解释表混在一起

## 4. DeepAudit

### 4.1 必须纳入

纳入范围：

- `boundary` 主表 8 行
- `minimal expansion` 5 行

当前来源：

- [boundary_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/20260702T013845Z/boundary_matrix.tsv:1)
- [expansion_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_minimal_expansion/20260702T061515Z/expansion_matrix.tsv:1)

预期规模：

- `13` 行

纳入原因：

- 这两张表共同定义了 `DeepAudit` 的当前可用边界
- `boundary` 提供主形态
- `minimal expansion` 提供跨漏洞家族、跨项目线与 repeat 的修正结论

### 4.2 明确不纳入

不纳入范围：

- `preflight`
- `smoke` 环境验证
- `timing` 辅助诊断
- 单次 staging / polling / upload 等原始运行细节

不纳入原因：

- 这些内容主要服务于“能不能跑”和“为什么成本这样”
- 其价值应折叠进 `cost` 和总报告叙述，而不是单独变成 canonical 行

## 5. IRIS

### 5.1 必须纳入

纳入范围：

- `official_behavior` 5 行
- `official_case_trustworthiness` 5 行
- `self_comparison` 3 行
- `candidate-selection formal` 7 个 family 行
- `llm_variance` 2 个 family 行

当前主要来源：

- [canonical_results.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:1)
- [iris_official_case_claim_vs_local_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_official_case_claim_vs_local_summary.md:1)
- [iris_candidate_selection_all7_formal_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_candidate_selection_all7_formal_results.md:1)
- [iris_llm_variance_rerun_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_llm_variance_rerun_results.md:1)

预期规模：

- `22` 行左右

纳入原因：

- 这几组结果共同构成 `IRIS` 当前学习评估闭环
- 既保留了 case-level benchmark 结果，也保留了最关键的 family-level failure diagnosis

### 5.2 明确不纳入

不纳入范围：

- `r1/r2/r3` 逐次 rerun 原始重复行
- preflight / 部署链路细节
- 单次 parse failure 明细日志

不纳入原因：

- `llm_variance` 需要的是 family-level 收口，而不是所有 rerun 平铺
- 原始重复行会显著放大高方差 family 的权重

## 6. Architecture Attribution

### 6.1 必须纳入

纳入范围：

- `E1 SSRF-JA-REPO-001` 的 canonical 恢复行
- `E2 SSRF-3432 pair` 的关键 mode 行：
  - `M1_original`
  - `M3_differential_target_context_constrained`
  - `M4_differential_free_auditor`
- `E4 cron-utils D1`
- `E4 SSRF-3432 pair` 中已完成且会改变结论的 canonical 行

当前主要来源：

- [e1_static_gate_oracle_progress_report.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e1_static_gate_oracle_progress_report.md:1)
- [e2_ssrf3432_pair_differential_freedom_report.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e2_ssrf3432_pair_differential_freedom_report.md:1)
- [e4_cronutils_deepaudit_information_control_report.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e4_cronutils_deepaudit_information_control_report.md:1)
- [e4_ssrf3432_deepaudit_information_control_report.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e4_ssrf3432_deepaudit_information_control_report.md:1)

预期规模：

- `6-12` 行

纳入原因：

- 这条实验线的目标不是“更多行”，而是保留真正改变主结论的 canonical mode
- 因此只纳入能稳定支撑主归因结论的 family / mode

### 6.2 明确不纳入

不纳入范围：

- pending / not run 的模式
- 纯 checklist / execution memo
- 不改变主结论的冗余 replay 细节

不纳入原因：

- `Architecture Attribution` 的价值在于因果收口，不在于 run 数量
- 若把所有子模式平铺，会让结果表退化成实验日志索引

## 7. 当前目标规模

按当前口径，完整收口表的目标规模大致为：

- `OpenAnt`: `8`
- `DeepAudit`: `13`
- `IRIS`: `22` 左右
- `Architecture Attribution`: `6-12`

总规模预计：

- 约 `50` 行上下

这个规模的目标是：

- 足够覆盖结论
- 足够保留差异
- 但不膨胀成 raw run dump

## 8. 扩表执行顺序

建议固定按以下顺序扩：

1. `OpenAnt`
2. `DeepAudit`
3. `IRIS` case-level rows
4. `IRIS` family-level diagnosis rows
5. `Architecture Attribution`

原因：

- 前两条线字段最稳定，适合先把表结构跑顺
- `IRIS` 与 `Architecture Attribution` 更容易混入 family-level / pair-level 粒度，放后面更稳

## 9. 完成定义

当且仅当下面条件同时满足，才可认为 `canonical_results.tsv` 已完成完整收口：

1. 四条实验线都按本清单完成纳入。
2. 所有 `evidence_ref` 都能回链到本仓库稳定文件。
3. 没有把高层归因结论写入 `failure_mode_*`。
4. `pair/family-level row` 都被明确标记，不与普通 case-level row 混淆。
