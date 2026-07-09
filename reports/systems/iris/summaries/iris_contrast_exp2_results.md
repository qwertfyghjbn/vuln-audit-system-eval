# IRIS 对比诊断实验 2 结果总结

## 1. 文档定位

这份文档记录 [iris_contrast_diagnostic_plan.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_diagnostic_plan.md:1) 中实验 2 的结果。

它回答的问题是：

> 当 `SSRF-JA-REPO-CVE-2023-3432-VULN / FIXED` 已经拿到部分 `source/sink/tp` 标签但 `results.csv` 仍为空时，路径究竟断在哪一层；两条线是断在同一层还是不同层？

这一步只使用现有归档做静态诊断，没有新增运行。

## 2. 证据范围

主证据：

- 配对诊断表：
  - [iris_contrast_exp2_pair_diagnosis.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_contrast_exp2_pair_diagnosis.tsv:1)
- `vuln` 归档：
  - [MySources.qll](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/generated_queries/myqueries/cwe-918wLLM/MySources.qll:1)
  - [MySinks.qll](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/generated_queries/myqueries/cwe-918wLLM/MySinks.qll:1)
  - [MySummaries.qll](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/generated_queries/myqueries/cwe-918wLLM/MySummaries.qll:1)
  - [llm_labelled_source_apis.json](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/raw_responses/llm_labelled_source_apis.json:1)
  - [llm_labelled_sink_apis.json](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/raw_responses/llm_labelled_sink_apis.json:1)
  - [results.csv](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/iris_run/results.csv:1)
  - [posthoc_results.json](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/iris_run/posthoc_results.json:1)
- `fixed` 归档：
  - [MySources.qll](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/generated_queries/myqueries/cwe-918wLLM/MySources.qll:1)
  - [MySinks.qll](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/generated_queries/myqueries/cwe-918wLLM/MySinks.qll:1)
  - [MySummaries.qll](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/generated_queries/myqueries/cwe-918wLLM/MySummaries.qll:1)
  - [llm_labelled_source_apis.json](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/raw_responses/llm_labelled_source_apis.json:1)
  - [llm_labelled_sink_apis.json](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/raw_responses/llm_labelled_sink_apis.json:1)
  - [results.csv](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/iris_run/results.csv:1)
  - [posthoc_results.json](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/iris_run/posthoc_results.json:1)

## 3. 先给结论

1. `VULN` 与 `FIXED` 的主断点层相同：
   - `same break layer = query_semantics_mismatch`

2. `label_not_materialized_into_query` 是真实的次级问题，但不是主断点。
   - 两条线都把 `6` 个 sink 标签只物化了 `3` 个
   - 但保留下来的 `SURL.getBytes` 和 `URL.openConnection` 已经覆盖了实际请求路径上的关键 sink 位置

3. `missing_required_summary_edge` 不是主断点。
   - `VULN` 的 `15` 个 propagator 全部物化
   - `FIXED` 的 `11` 个 propagator 全部物化
   - 而且都包含 `SURL.create` 这样的关键包装层桥接

4. `post_query_zero_path` 可以排除。
   - 主查询 `results.csv` 已经为空
   - posthoc 结果也是空

5. 当前真正卡住的是 source 侧 query 语义：
   - `VULN`：唯一物化出来的 source 是 `System.getenv`
   - `FIXED`：source predicate 直接是 `1 = 0`

## 4. 配对诊断表

完整表见 [iris_contrast_exp2_pair_diagnosis.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_contrast_exp2_pair_diagnosis.tsv:1)。

这里给出最关键的配对结论：

| case | source side | sink side | summary side | primary_break_layer |
|---|---|---|---|---|
| `SSRF-JA-REPO-CVE-2023-3432-VULN` | `1` 个 source，且唯一 source 是 `System.getenv` | `6` 个 sink 标签仅物化 `3` 个 | `15/15` 全部物化 | `query_semantics_mismatch` |
| `SSRF-JA-REPO-CVE-2023-3432-FIXED` | `0` 个 source，`MySources.qll` 为 `1 = 0` | `6` 个 sink 标签仅物化 `3` 个 | `11/11` 全部物化 | `query_semantics_mismatch` |

配对判断：

- `same break layer = yes`
- 但两条线的具体表现不同：
  - `VULN` 是“有 source，但 source 落在错误语义片段上”
  - `FIXED` 是“source 侧直接为空”

## 5. 为什么不是 `label_not_materialized_into_query`

这是必须先排除的竞争解释。

### 5.1 两条线都确实存在物化不完整

`VULN` 的 sink 标签有 `6` 个，但 `MySinks.qll` 里只有 `3` 个真实谓词分支，另外 `3` 个退成了 `1 = 0`：

- [MySinks.qll:18](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/generated_queries/myqueries/cwe-918wLLM/MySinks.qll:18)
- [MySinks.qll:24](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/generated_queries/myqueries/cwe-918wLLM/MySinks.qll:24)

`FIXED` 的 `MySinks.qll` 结构相同。

### 5.2 但保留下来的 sink 已经覆盖真实请求路径

代码中的网络请求主路径包括：

- `LoadJson.loadStringData(String path)` 中的 `url.getBytes()`
  - [LoadJson.java:166](/home/lqs/llm_audit_system_learning/datasets/real_world/SSRF-JA-REPO-CVE-2023-3432-VULN/repo/src/net/sourceforge/plantuml/tim/stdlib/LoadJson.java:166)
- `SURL.getBytes()`
  - [SURL.java:347](/home/lqs/llm_audit_system_learning/datasets/real_world/SSRF-JA-REPO-CVE-2023-3432-VULN/repo/src/net/sourceforge/plantuml/security/SURL.java:347)
- `URL.openConnection()`
  - [SURL.java:467](/home/lqs/llm_audit_system_learning/datasets/real_world/SSRF-JA-REPO-CVE-2023-3432-VULN/repo/src/net/sourceforge/plantuml/security/SURL.java:467)

而这几个关键点在 `MySinks.qll` 里已经保留下来了：

- `URL.openConnection`
- `SURL.getBytes`

所以“有一部分 sink 没物化”是次级问题，但不足以单独解释为什么两条线都 `0 paths`。

## 6. 为什么不是 `missing_required_summary_edge`

### 6.1 `VULN` 的 summary 侧是完整物化

`VULN` 的 `15` 个 taint-propagator 标签全部进入了 `MySummaries.qll`，包括：

- `URL(String)`
- `String.split`
- `String.toLowerCase`
- `SURL.create`
- `SURL.removeUserInfoFromUrlPath`

见：

- [MySummaries.qll:5](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/generated_queries/myqueries/cwe-918wLLM/MySummaries.qll:5)

### 6.2 `FIXED` 也是同样情况

`FIXED` 的 `11` 个 propagator 也都进入了 `MySummaries.qll`。

因此当前没有证据支持“缺 caller-side / wrapper-side summary edge”是主断点。

## 7. 为什么主断点是 `query_semantics_mismatch`

### 7.1 `VULN`：唯一 source 落在配置环境变量片段

`VULN` 的 `MySources.qll` 只把 `System.getenv` 当成 source：

- [MySources.qll:5](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/generated_queries/myqueries/cwe-918wLLM/MySources.qll:5)

而代码中这个 source 片段位于安全配置读取逻辑：

- [SecurityUtils.java:212](/home/lqs/llm_audit_system_learning/datasets/real_world/SSRF-JA-REPO-CVE-2023-3432-VULN/repo/src/net/sourceforge/plantuml/security/SecurityUtils.java:212)

但实际网络请求路径来自另一个片段：

- `LoadJson.path -> SURL.create(path) -> url.getBytes()`
  - [LoadJson.java:166](/home/lqs/llm_audit_system_learning/datasets/real_world/SSRF-JA-REPO-CVE-2023-3432-VULN/repo/src/net/sourceforge/plantuml/tim/stdlib/LoadJson.java:166)
  - [SURL.java:347](/home/lqs/llm_audit_system_learning/datasets/real_world/SSRF-JA-REPO-CVE-2023-3432-VULN/repo/src/net/sourceforge/plantuml/security/SURL.java:347)

也就是说：

- query 不是完全没有 source
- 但 source 物化到了错误的程序语义片段

这正对应：

- `query_semantics_mismatch`

### 7.2 `FIXED`：source 侧直接为空

`FIXED` 的 `MySources.qll` 直接退成：

- `1 = 0`
  - [MySources.qll:5](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/generated_queries/myqueries/cwe-918wLLM/MySources.qll:5)

与此同时，代码中的请求路径仍然存在：

- [LoadJson.java:166](/home/lqs/llm_audit_system_learning/datasets/real_world/SSRF-JA-REPO-CVE-2023-3432-FIXED/repo/src/net/sourceforge/plantuml/tim/stdlib/LoadJson.java:166)
- [SURL.java:353](/home/lqs/llm_audit_system_learning/datasets/real_world/SSRF-JA-REPO-CVE-2023-3432-FIXED/repo/src/net/sourceforge/plantuml/security/SURL.java:353)

这意味着：

- 当前 query 仍然没有得到任何可用的 request-origin source 语义
- 问题仍然落在 source 侧 query 语义，而不是后处理阶段

因此 `FIXED` 的主断点也应归到：

- `query_semantics_mismatch`

## 8. 配对结论

实验 2 需要明确回答的核心问题是：

> `same break layer or different break layer`？

当前答案是：

- `same break layer = query_semantics_mismatch`

但“同层”不等于“同表现”：

1. `VULN`
   - source 侧不是空
   - 但 source 语义落在配置环境变量片段，而不是请求路径片段

2. `FIXED`
   - source 侧直接为空
   - sink / summary 仍然保留了大部分网络请求路径

因此更精确的总结是：

> 两条线都没有走到能够表达“请求参数如何驱动网络请求”的那一层；`VULN` 是 source 语义错位，`FIXED` 是 source 语义缺失。

## 9. 对实验 3 的影响

实验 2 完成后，可以更清楚地理解实验 3 的位置：

- `SSRF` 的主问题已经不是“有没有 sink”
- 而是“source 侧 query 语义是否对准了实际请求路径”
- 这也反过来说明：`PT` 的 `sink completeness diagnosis` 不应与 `SSRF` 混成同一种路径断裂问题

## 10. 一句话结论

实验 2 证明：

> `SSRF vuln/fixed` 两条线断在同一主层：`query_semantics_mismatch`；区别只在于 `vuln` 是 source 语义错位，而 `fixed` 是 source 语义缺失。
