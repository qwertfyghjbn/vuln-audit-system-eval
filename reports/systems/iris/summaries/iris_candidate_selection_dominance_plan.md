# IRIS Missed-Vuln Case Family 候选主导性诊断计划

## 1. 文档定位

这份计划用于验证一个被收紧后的假设：

> 在已完成实验的 missed-vuln `Case Family` 中，`candidate-selection / API lifting` 是否构成一条主脆弱线；它在哪些 family 上是主因，在哪些 family 上只是前置必要条件，在哪些 family 上并不是主解释？

这不是：

- 对 `IRIS` 一切失败的统一根因宣判
- 新一轮正式评测
- 只做 3-case 的候选边界轻量验证

它属于一个新的 `Learning Run`，目标是产出一张可审计的 `failure-layer map`。

## 2. 与已有文档的关系

这份计划建立在以下已有结果之上：

- 官方行为线：
  - [iris_official_behavior_stage_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_official_behavior_stage_summary.md:1)
- 官方 5 case 本地复现对照：
  - [iris_official_case_claim_vs_local_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_official_case_claim_vs_local_summary.md:1)
- 自有对照线首轮：
  - [iris_self_first_round_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_self_first_round_results.md:1)
- LLM 方差重跑：
  - [iris_llm_variance_rerun_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_llm_variance_rerun_results.md:1)
- 旧的 3-case 候选验证线：
  - [iris_candidate_selection_validation_plan.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_candidate_selection_validation_plan.md:1)
  - [iris_candidate_selection_baseline_diagnosis.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_candidate_selection_baseline_diagnosis.md:1)
- `PT / SSRF-3432` 的对比深诊断：
  - [iris_contrast_exp2_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_exp2_results.md:1)
  - [iris_contrast_exp3_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_exp3_results.md:1)
  - [iris_contrast_batch_overall_judgment.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_batch_overall_judgment.md:1)

与旧的 `candidate-selection` 验证计划相比，这份计划有 3 个新增边界：

1. 统计对象从 `单次运行` 收紧为 `Case Family`
2. 目标从“source 缺失是否来自候选边界”扩展为“各 family 的主断点层分布”
3. 证据链从 `baseline 诊断 + 单变量放宽` 扩展为：
   - `candidate coverage audit`
   - `forced candidate injection`
   - `minimal target-adjacent oracle replay`

## 3. 核心术语

本计划固定使用以下术语：

1. `Case Family`
   - 用于把同一目标漏洞场景下的多次 run、rerun、变体结果合并为一个稳定诊断对象

2. `missed-vuln Case Family`
   - 指已完成实验中，本应命中 `Target Vulnerability`，但当前本地 `IRIS` 未稳定命中目标漏洞的 family

3. `target-adjacent API set`
   - 指围绕目标漏洞真实路径闭环所需的最小 source / sink / summary 邻近 API 集

4. `Minimal Target-adjacent Oracle`
   - 指人工提供的最小 source / sink / summary 标签集
   - 它只用于回答“后半段机制是否可工作”，不是为了做最大化人工救活

5. `candidate-selection dominant`
   - 指决定性阻断发生在 Stage 3 候选边界之前，后续 LLM 标签和 CodeQL 路径形成都没有拿到最小必要语义锚点

## 4. 统计对象与排除项

### 4.1 主表统计对象

主表只统计以下 `7` 个 missed-vuln `Case Family`：

1. `PT-JA-REPO-001`
2. `SSRF-JA-REPO-001`
3. `PT-JA-REPO-CVE-2024-53677-VULN`
4. `SSRF-JA-REPO-CVE-2023-3432-VULN`
5. `vert-x3__vertx-web_CVE-2018-12542_3.5.3.CR1`
6. `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`
7. `rhuss__jolokia_CVE-2018-1000129_1.4.0`

### 4.2 方差注记

以下对象不重复计权，但必须保留注记：

1. `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`
   - `stable source-zero failure`

2. `rhuss__jolokia_CVE-2018-1000129_1.4.0`
   - `high-variance official success case`

### 4.3 排除项

本计划不把以下对象计入“missed-vuln 主表”：

1. `FIXED / near-miss` 控制组
   - 例如 `SSRF-JA-REPO-CVE-2023-3432-FIXED`

2. 早期运行链路失败
   - 例如 `TESTRUNREAL`

3. 已经达到 `target_match=true` 的弱复现 case
   - 例如两条 `spark` official case

## 5. 要回答的核心问题

本计划必须回答以下 4 个问题：

1. 在这 `7` 个 missed-vuln `Case Family` 中，哪些 family 的关键 `target-adjacent API` 根本没有进入 Stage 3 candidate set？
2. 对这些 family，仅放宽 candidate 边界后，下游标签形状是否会显著恢复？
3. 在最小人工 oracle 条件下，后续 `materialization + CodeQL + posthoc` 是否足以形成 target-aligned 结果？
4. 最终有多少 family 应归为：
   - `candidate-selection dominant`
   - `candidate-selection necessary but not sufficient`
   - 其它主断点层

## 6. 实验设计

每个 `Case Family` 都执行同一套三段式诊断。

### 6.1 Phase A: Candidate Coverage Audit

目标：

- 为每个 family 建立一个 `target-adjacent API set`
- 检查这些 API 在现有归档中的通过层级

每个 API 必须检查是否进入：

1. raw API universe
2. internal API universe
3. Stage 3 candidate set
4. `llm_labelled_*.json`
5. `MySources.qll` / `MySinks.qll` / `MySummaries.qll`

这一步只做静态归档审计，不新增运行。

### 6.2 Phase B: Forced Candidate Injection

目标：

- 在不改 prompt、不改 ranking、不改主 `ql` 查询骨架的前提下
- 只注入缺失的 `target-adjacent API`
- 观察 Stage 3 到最终查询链路的形状是否发生可审计变化

固定边界：

1. 只改 candidate 输入边界
2. 不改 LLM 提示词
3. 不改 `source/sink/summary` 模板语义
4. 不改 posthoc 策略

### 6.3 Phase C: Minimal Target-adjacent Oracle Replay

目标：

- 对注入后的 case family，提供最小必要 source / sink / summary 标签
- 只验证后半段 `materialization + query + posthoc` 是否可形成 target-aligned 结果

固定边界：

1. oracle 只能覆盖目标路径闭环所需最小集合
2. 不得构造“全量人工救活”标签包
3. 仍然沿用系统原有 QLL 模板与主 `ql` 骨架

## 7. 每个 family 的预期记录字段

本计划要求产出一张统一诊断表，每行一个 `Case Family`，至少包含：

- `case_family`
- `query_id`
- `variance_note`
- `target_adjacent_api_count`
- `missing_from_candidate_count`
- `missing_target_adjacent_apis`
- `baseline_source_shape`
- `baseline_sink_shape`
- `baseline_target_match`
- `after_candidate_injection_source_shape`
- `after_candidate_injection_sink_shape`
- `after_candidate_injection_target_match`
- `after_oracle_replay_target_match`
- `primary_break_layer`
- `candidate_selection_role`
- `evidence_links`

## 8. 判定规则

### 8.1 `candidate-selection dominant`

只有在以下条件同时满足时，才允许判成：

1. baseline 中至少一个关键 `target-adjacent API` 不在 Stage 3 candidate set
2. `forced candidate injection` 后，下游形状显著改善：
   - `source` 从 `0 -> >0`
   - 或 `sink` 从 `0 -> >0`
   - 或 target-adjacent API 首次进入 `llm_labelled_*.json`
3. `minimal oracle replay` 后，可以形成 target-aligned 结果：
   - `results > 0`
   - 且命中目标漏洞对应方法或位置

### 8.2 `candidate-selection necessary but not sufficient`

满足以下条件时，判成：

1. baseline 中存在关键 `target-adjacent API` 缺失于 candidate set
2. `forced candidate injection` 后，下游标签形状确实改善
3. 但 `minimal oracle replay` 后，仍然不能形成 target-aligned 结果

这说明 candidate 边界是前置阻断，但不是最终主断点。

### 8.3 其它主断点层

若不满足上面条件，则根据现有与新增证据判入：

- `labeling dominant`
- `query-semantics dominant`
- `target-match dominant`
- `variance-dominant`

## 9. 当前先验预期

这部分不是结论，只是当前最合理的工作假设：

1. `PT-JA-REPO-CVE-2024-53677-VULN`
   - 预期：`candidate-selection dominant`

2. `SSRF-JA-REPO-CVE-2023-3432-VULN`
   - 预期：`candidate-selection necessary but not sufficient`

3. `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`
   - 预期：待判定
   - 可能落在：
     - `candidate-selection`
     - `query-semantics`

4. `rhuss__jolokia_CVE-2018-1000129_1.4.0`
   - 预期：不是纯 `candidate-selection` 主因

5. `vert-x3__vertx-web_CVE-2018-12542_3.5.3.CR1`
   - 预期：更可能是 `target-match dominant`

## 10. 交付物

本计划完成后，必须产出：

1. 一张 `missed-vuln family diagnosis matrix`
2. 每个 family 的 `target-adjacent API set`
3. 每个 family 的 `Minimal Target-adjacent Oracle`
4. 一份批次总结，明确：
   - `candidate-selection` 在多少 family 上是主因
   - 在多少 family 上只是前置必要条件
   - 哪些 family 的主问题已明确不在 candidate 层

## 11. 可执行任务清单

以下任务清单按执行顺序给出，默认每一步都要保留可审计产物。

### 11.1 Phase A: Candidate Coverage Audit

1. 固化主表范围
   - 冻结 `7` 个 missed-vuln `Case Family`
   - 为 `cron-utils` 与 `jolokia` 增加 `variance_note`

2. 为每个 family 建立 `target-adjacent API set`
   - 从 ground-truth 路径出发
   - 列出最小 source / sink / summary 邻近 API
   - 不追求“尽量多”，只追求“闭环所必需”

3. 审计现有归档中的通过层级
   - 检查每个 `target-adjacent API` 是否进入：
     - raw API universe
     - internal API universe
     - Stage 3 candidate set
     - `llm_labelled_*.json`
     - `MySources.qll` / `MySinks.qll` / `MySummaries.qll`

4. 为每个 family 填写 baseline 诊断结论
   - 记录 `baseline_source_shape`
   - 记录 `baseline_sink_shape`
   - 记录 `baseline_target_match`
   - 初步标记 `candidate gap` 是否存在

5. 产出 `Phase A` 结果表
   - 使用下面的模板 A

### 11.2 Phase B: Forced Candidate Injection

1. 为每个 family 设计最小注入包
   - 只包含当前缺失但属于 `target-adjacent API set` 的 API
   - 不额外放宽与目标路径无关的大范围 internal API

2. 运行单变量 candidate 注入实验
   - 不改 prompt
   - 不改 ranking
   - 不改主 `ql` 查询骨架
   - 不改 posthoc

3. 记录注入后的 Stage 3 形状变化
   - `source` 是否从 `0 -> >0`
   - `sink` 是否从 `0 -> >0`
   - `target-adjacent API` 是否首次进入 `llm_labelled_*.json`

4. 记录注入后的最终结果变化
   - `results.csv` 是否仍为空
   - `target_match` 是否仍为 `false`

5. 产出 `Phase B` 结果表
   - 使用下面的模板 B

### 11.3 Phase C: Minimal Target-adjacent Oracle Replay

1. 为每个 family 构造 `Minimal Target-adjacent Oracle`
   - 只填闭合目标路径所必需的 source / sink / summary
   - 不构造 maximal rescue label set

2. 冻结 candidate 注入结果
   - Phase C 不再额外修改 candidate 集

3. 重放 oracle 标签并重新物化
   - 生成 `MySources.qll`
   - 生成 `MySinks.qll`
   - 生成 `MySummaries.qll`

4. 运行 `materialization + CodeQL + posthoc`
   - 检查是否形成 target-aligned 结果
   - 记录是“仍然不成路径”还是“成路径但仍未打中 target”

5. 产出 `Phase C` 结果表
   - 使用下面的模板 C

### 11.4 批次级归因收口

1. 为每个 family 赋一个唯一 `primary_break_layer`
2. 为每个 family 赋一个唯一 `candidate_selection_role`
3. 汇总：
   - `candidate-selection dominant` 数量
   - `candidate-selection necessary but not sufficient` 数量
   - `labeling / query-semantics / target-match / variance` 数量
4. 形成批次总结
   - 明确哪些 family 值得进入能力改动
   - 明确哪些 family 不应再优先归因到 candidate-selection

## 12. 结果表模板

本计划至少需要三张结果表，分别对应 `Phase A / B / C`。

### 12.1 模板 A: `candidate_coverage_audit.tsv`

```tsv
case_family	query_id	variance_note	target_adjacent_api_role	target_adjacent_api	raw_api_present	internal_api_present	stage3_candidate_present	llm_label_present	qll_materialized_present	baseline_source_shape	baseline_sink_shape	baseline_target_match	candidate_gap_class	notes	evidence_links
PT-JA-REPO-CVE-2024-53677-VULN	cwe-022wLLM		sink	UploadedFile.getAbsolutePath	no	no	no	no	no	source=6	sink=0	false	missing_from_candidate_set		expected evidence links
```

字段说明：

- `target_adjacent_api_role`
  - 只允许：`source` / `sink` / `summary`
- `candidate_gap_class`
  - 只允许：
    - `missing_from_raw_universe`
    - `missing_after_internal_filter`
    - `missing_from_stage3_candidate_set`
    - `present_in_candidate_but_missing_in_label`
    - `present_in_label_but_missing_in_qll`
    - `fully_present`

### 12.2 模板 B: `forced_candidate_injection.tsv`

```tsv
case_family	query_id	injected_api_count	injected_apis	baseline_source_shape	baseline_sink_shape	post_injection_source_shape	post_injection_sink_shape	post_injection_label_delta	post_injection_qll_delta	post_injection_results	post_injection_target_match	candidate_injection_effect	notes	evidence_links
PT-JA-REPO-CVE-2024-53677-VULN	cwe-022wLLM	3	UploadedFile.getAbsolutePath; UploadedFile.getContent; FileUploadAction.setUpload(File)	source=6	sink=0	source=6	sink=2	sink_labels_0_to_2	MySinks_nonempty	results=0	false	shape_improved_no_target_hit		expected evidence links
```

字段说明：

- `candidate_injection_effect`
  - 只允许：
    - `no_effect`
    - `shape_improved_no_target_hit`
    - `target_hit_recovered`
    - `off_target_only`

### 12.3 模板 C: `minimal_target_adjacent_oracle.tsv`

```tsv
case_family	query_id	oracle_source_count	oracle_sink_count	oracle_summary_count	oracle_sources	oracle_sinks	oracle_summaries	post_oracle_qll_state	post_oracle_results	post_oracle_target_match	post_oracle_primary_observation	candidate_selection_role	primary_break_layer	notes	evidence_links
PT-JA-REPO-CVE-2024-53677-VULN	cwe-022wLLM	1	1	1	MultiPartRequestWrapper.getFiles	FileUploadAction.setUpload(File)	UploadedFile.getContent	all_nonempty	results=1	true	target_aligned_result_recovered	candidate-selection dominant	sink_not_in_candidate_set		expected evidence links
```

字段说明：

- `candidate_selection_role`
  - 只允许：
    - `candidate-selection dominant`
    - `candidate-selection necessary but not sufficient`
    - `not_primary`
- `primary_break_layer`
  - 只允许：
    - `candidate_selection`
    - `labeling`
    - `query_semantics`
    - `target_match`
    - `variance`
    - `mixed_but_query_semantics_primary`

### 12.4 批次总表模板: `missed_vuln_family_diagnosis_matrix.tsv`

```tsv
case_family	query_id	variance_note	target_adjacent_api_count	missing_from_candidate_count	baseline_source_shape	baseline_sink_shape	after_candidate_injection_source_shape	after_candidate_injection_sink_shape	after_oracle_replay_target_match	candidate_selection_role	primary_break_layer	difference_summary	next_action	evidence_links
PT-JA-REPO-CVE-2024-53677-VULN	cwe-022wLLM		5	3	source=6	sink=0	source=6	sink=2	true	candidate-selection dominant	candidate_selection	target-adjacent sinks were absent from candidate set; minimal injection restored sink labels and minimal oracle replay recovered the target-aligned result	enter capability change on candidate/API lifting	expected evidence links
```

这张总表是最终批次总结的唯一主表。

## 13. 非目标

本计划明确不做：

1. 把全部失败压缩成单一统一根因
2. 直接改 prompt / ranking / posthoc 多个变量并行混测
3. 把高方差 rerun 当成新的独立 family 重复计数
4. 直接推出“IRIS 不适合本 benchmark”的总评结论

## 14. 一句话结论

这份计划的目标不是证明“IRIS 一切失败都来自 `candidate-selection`”，而是：

> 用统一的三段式归因流程，判断 `candidate-selection / API lifting` 在哪些 missed-vuln `Case Family` 上已经足以构成主阻断，在哪些 family 上只是前置必要条件，而在另外一些 family 上，真正的主问题已经位于更下游的 `query semantics`、`target-match` 或 `variance` 层。
