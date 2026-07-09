# IRIS 官方线与自有线对比诊断实验计划

## 1. 文档定位

这份文档固定下一阶段 `IRIS` 学习工作的执行方案。

它回答的问题是：

> 在同一冻结运行边界下，`Official Asset-Chain Case` 与 `Self Comparison Case` 的失败层级究竟在哪里分叉；而当 `IRIS` 已经产出部分 `source / sink / taint-propagator` 标签但 `results.csv` 仍为空时，漏洞路径到底断在了哪里？

这份文档对应一个新的 **`Contrast Diagnostic Batch`**，不是：

- `Diagnostic Evaluation`
- `Boundary-Condition Diagnostic Expansion`
- 新一轮能力改动实验

## 2. 术语与边界

本计划使用以下冻结术语：

1. `Contrast Diagnostic Batch`
   - 保持单一冻结运行边界
   - 对比 `Official Asset-Chain Case` 与 `Self Comparison Case`
   - 目标是解释失败层差异，而不是产出新的可比分数

2. `Official case`
   - 本文中特指 `OFFICIALSMOKE01` 中与 3 个自有 case 对应的 3 条官方行为记录

3. `Self case`
   - 本文中特指 `DEEPSEEK_SELF01` 中的 3 个冻结自有 case 首轮结果

4. `Path non-connectivity diagnosis`
   - 只用于“已有部分 `source/sink/tp`，但最终 `results.csv` 仍为空”的情况

5. `Sink completeness diagnosis`
   - 只用于“`sink=0` 导致最终路径无法成立”的情况

本计划明确不做：

- 能力改动
- prompt 修改
- benchmark 输入边界扩展
- 多轮重跑分布实验

## 3. 冻结运行边界

本计划只使用以下冻结运行边界：

- `variant_id = iris-runtime-compat-001`
- `official_run_id = OFFICIALSMOKE01`
- `self_run_id_batch = DEEPSEEK_SELF01`
- `llm_provider = deepseek`
- `llm_model_alias = deepseek-v4-pro`

默认原则：

1. 先使用现有归档做静态诊断
2. 不新增运行
3. 只有在现有证据不足以判定断点层级时，才允许补最小增量检查

## 4. 固定 case 范围

本计划只覆盖 `3 对 3` 的对应视图：

| 角色 | case |
|---|---|
| 官方对照 | `PT-JA-REPO-CVE-2024-53677-VULN` in `OFFICIALSMOKE01` |
| 官方对照 | `SSRF-JA-REPO-CVE-2023-3432-VULN` in `OFFICIALSMOKE01` |
| 官方对照 | `SSRF-JA-REPO-CVE-2023-3432-FIXED` in `OFFICIALSMOKE01` |
| 自有线 | `PT-JA-REPO-CVE-2024-53677-VULN` in `DEEPSEEK_SELF01` |
| 自有线 | `SSRF-JA-REPO-CVE-2023-3432-VULN` in `DEEPSEEK_SELF01` |
| 自有线 | `SSRF-JA-REPO-CVE-2023-3432-FIXED` in `DEEPSEEK_SELF01` |

不把另外 2 个官方 smoke case 混入本批次。

原因：

- 本批次目标是“对应差异解释”
- 不是重做一次官方行为总览

## 5. 执行顺序

本计划严格按以下顺序执行：

1. 实验 1：`3 对 3` 对比矩阵
2. 实验 2：`SSRF vuln / fixed` 配对 `path non-connectivity diagnosis`
3. 实验 3：`PT` 的 `sink completeness diagnosis`

只有前一实验完成并形成明确结论，才能进入下一实验。

## 6. 实验 1：`3 对 3` 对比矩阵

### 6.1 目标

回答：

> `Official case` 与 `Self case` 的差异主要发生在 candidate、label、path，还是缓存/解析干扰层？

### 6.2 输入

主输入：

- [canonical_results.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:1)
- [DEEPSEEK_SELF01/summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/summary.tsv:1)
- 6 条 case 的 `fetch_build/command.stdout.log`
- 6 条 case 的 `raw_responses/llm_labelled_*.json`

### 6.3 必填硬字段

每一行 `case_pair` 都必须填写：

- `case_pair`
- `vuln_type`
- `official_run_id`
- `self_run_id`
- `official_candidate_count`
- `self_candidate_count`
- `official_sources`
- `self_sources`
- `official_sinks`
- `self_sinks`
- `official_taint_propagators`
- `self_taint_propagators`
- `official_num_paths`
- `self_num_paths`
- `official_stage3_parse_errors`
- `self_stage3_parse_errors`
- `official_shared_cache_effect`
- `self_shared_cache_effect`
- `primary_break_layer`
- `difference_summary`
- `next_diagnostic_action`

允许的备注字段：

- `notes`
- `evidence_links`
- `special_observation`

### 6.4 交付物

必须产出：

1. 一张 `3 对 3` 对比矩阵
2. 每条 `case_pair` 的 `primary_break_layer`
3. 每条 `case_pair` 的 `next_diagnostic_action`
4. 一段批次级总结，回答：
   - 差异主要发生在哪一层
   - 哪些差异足以进入更深诊断

### 6.5 退出条件

实验 1 只有在以下条件同时满足时才算完成：

1. 3 条 `case_pair` 都已填写完整硬字段
2. 每条 `case_pair` 都给出一个唯一 `primary_break_layer`
3. 已明确：
   - `SSRF vuln/fixed` 是否需要进入 `path non-connectivity diagnosis`
   - `PT` 是否应该进入 `sink completeness diagnosis`

## 7. 实验 2：`SSRF vuln / fixed` 配对 path non-connectivity 诊断

### 7.1 目标

回答：

> 当 `SSRF-JA-REPO-CVE-2023-3432-VULN / FIXED` 已经拿到部分 `source/sink/tp` 标签但 `results.csv` 仍为空时，路径究竟断在哪一层；`VULN` 与 `FIXED` 是断在同一层还是不同层？

### 7.2 对象

这一步的两个对象必须 **等深度同检**：

- `SSRF-JA-REPO-CVE-2023-3432-VULN`
- `SSRF-JA-REPO-CVE-2023-3432-FIXED`

`FIXED` 不是轻量备注对照，而是主对象。

### 7.3 允许的断点层级

主断点只能从以下 5 类中选：

1. `label_not_materialized_into_query`
2. `source_sink_not_co_reachable`
3. `missing_required_summary_edge`
4. `query_semantics_mismatch`
5. `post_query_zero_path`

不允许新增自由命名的主断点类别。

### 7.4 必查证据

两条 case 都必须检查：

- `generated_queries/myqueries/cwe-918wLLM/MySources.qll`
- `generated_queries/myqueries/cwe-918wLLM/MySinks.qll`
- `generated_queries/myqueries/cwe-918wLLM/MySummaries.qll`
- `raw_responses/llm_labelled_source_apis.json`
- `raw_responses/llm_labelled_sink_apis.json`
- `raw_responses/llm_labelled_taint_prop_apis.json`
- `iris_run/results.csv`
- `iris_run/results.sarif`
- `iris_run/posthoc_results.json`
- `local_observation/candidate_apis.csv`

### 7.5 必须回答的问题

1. 标签是否真正物化进了最终 query
2. `source` 与 `sink` 是否处于同一可达程序片段
3. 是否缺 caller-side / wrapper-side 所需 summary edge
4. 是否存在 `sink arg` / `source kind` / flow direction 语义不匹配
5. `VULN` 与 `FIXED` 是否断在同一主层

### 7.6 交付物

必须产出：

1. 一份配对诊断表
2. `VULN` 的主断点层级
3. `FIXED` 的主断点层级
4. 一个明确判断：
   - `same break layer`
   - 或 `different break layer`

### 7.7 退出条件

实验 2 只有在以下条件同时满足时才算完成：

1. `VULN / FIXED` 都已有唯一主断点层级
2. 已能明确说明两者是同层断裂还是异层断裂
3. 已能判断后续是否需要能力改动，且能指向具体层而不是泛泛地“继续改 IRIS”

## 8. 实验 3：`PT` 的 sink completeness 诊断

### 8.1 目标

回答：

> `PT-JA-REPO-CVE-2024-53677-VULN` 当前为什么在 `source` 已恢复的前提下仍然 `sink=0`？

### 8.2 说明

这一步 **不是** `path non-connectivity diagnosis`。

原因：

- 当前 `PT` 的主问题首先是 `sink` 缺失
- 不是“已有 `source/sink` 但路径不连通”

### 8.3 允许的主分类

主诊断类别只能从以下 4 类中选：

1. `sink_not_in_candidate_set`
2. `sink_seen_but_not_labelled`
3. `sink_labelled_but_not_materialized`
4. `sink_materialized_but_semantically_unusable`

### 8.4 必查证据

必须检查：

- `local_observation/candidate_apis.csv`
- `raw_responses/llm_labelled_sink_apis.json`
- `generated_queries/myqueries/cwe-022wLLM/MySinks.qll`
- `generated_queries/myqueries/cwe-022wLLM/MySources.qll`
- `iris_run/results.csv`
- `fetch_build/command.stdout.log`

### 8.5 必须回答的问题

1. 潜在 sink 是否进入了 Stage 3 candidate set
2. 若进入候选，是否被 LLM 标成 sink
3. 若被标成 sink，是否进入 `MySinks.qll`
4. 若已进入 `MySinks.qll`，其参数位或调用语义是否仍不可用

### 8.6 交付物

必须产出：

1. 一份 `sink completeness` 诊断表
2. 一个唯一主分类
3. 一段结论，明确 `PT` 的问题究竟卡在 candidate、label、materialization，还是 sink 语义可用性

### 8.7 退出条件

实验 3 只有在以下条件同时满足时才算完成：

1. 已给出唯一主分类
2. 已能说明 `PT` 不应再被误写成 `path non-connectivity`
3. 已能为后续是否值得进入能力改动提供明确依据

## 9. 新增运行的门槛

本计划默认 **不新增运行**。

### 9.1 允许完全静态完成的实验

- 实验 1：必须完全静态完成

### 9.2 允许最小增量检查的条件

只有满足以下条件时，才允许补最小增量检查：

1. 现有归档不足以判断标签是否真正物化进 query
2. 现有归档不足以判断主查询是否本来已产生 path
3. 不补检查就无法在允许的断点分类中做唯一归类

### 9.3 不允许的新增动作

不允许：

- 为了“看看会不会成功”而直接整 case 重跑
- 把最小增量检查扩成新一轮 LLM 重跑
- 在诊断批次中顺手引入能力改动

## 10. 计划完成判定

这个 `Contrast Diagnostic Batch` 只有在以下条件同时满足时才算结束：

1. 已完成 `3 对 3` 对比矩阵
2. 已完成 `SSRF vuln / fixed` 配对 `path non-connectivity diagnosis`
3. 已完成 `PT` 的 `sink completeness diagnosis`
4. 已形成一个批次级结论，明确回答：
   - 官方线与自有线的主要分叉层
   - 自有线当前最值得进入能力改动的具体断点层

## 11. 一句话执行摘要

下一阶段不是继续重跑，也不是立即改 `IRIS`，而是先完成一个冻结边界下的 `Contrast Diagnostic Batch`：

1. 用 `3 对 3` 对比矩阵定位官方线与自有线的分叉层
2. 对 `SSRF vuln / fixed` 做等深度配对 `path non-connectivity diagnosis`
3. 对 `PT` 做 `sink completeness diagnosis`

只有在这三步完成后，后续能力改动实验才有清晰落点。
