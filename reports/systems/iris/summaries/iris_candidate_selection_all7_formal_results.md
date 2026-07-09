# IRIS candidate-selection 正式实验总结果（7 个 family）

本文把 `iris_candidate_selection_dominance_plan.md` 的三轮正式实验合并为一份总文档，覆盖：

1. `PT-JA-REPO-001`
2. `SSRF-JA-REPO-001`
3. `PT-JA-REPO-CVE-2024-53677-VULN`
4. `SSRF-JA-REPO-CVE-2023-3432-VULN`
5. `vert-x3__vertx-web_CVE-2018-12542_3.5.3.CR1`
6. `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`
7. `rhuss__jolokia_CVE-2018-1000129_1.4.0`

这份总文档替代此前两份分批总结文档；详细阶段证据仍保留在各批次结果表中。

## 1. 证据范围

第一轮：

- [first3 Phase A](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_first3_candidate_coverage_audit.tsv:1)
- [first3 Phase B](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_first3_forced_candidate_injection.tsv:1)
- [first3 Phase C](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_first3_minimal_target_adjacent_oracle.tsv:1)
- [first3 总表](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_first3_diagnosis_matrix.tsv:1)

第二轮：

- [next2 Phase A](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_next2_candidate_coverage_audit.tsv:1)
- [next2 Phase B](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_next2_forced_candidate_injection.tsv:1)
- [next2 Phase C](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_next2_minimal_target_adjacent_oracle.tsv:1)
- [next2 总表](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_next2_diagnosis_matrix.tsv:1)

第三轮：

- [last2 Phase A](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_last2_candidate_coverage_audit.tsv:1)
- [last2 Phase B](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_last2_forced_candidate_injection.tsv:1)
- [last2 Phase C](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_last2_minimal_target_adjacent_oracle.tsv:1)
- [last2 总表](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_last2_diagnosis_matrix.tsv:1)

补充诊断证据：

- [iris_contrast_exp2_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_exp2_results.md:1)
- [iris_llm_variance_rerun_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_llm_variance_rerun_results.md:1)

## 2. 总体结论

7 个 family 的合并判断不支持原始强假设：

> “IRIS 的静态分析先抽候选 API 这一步是绝大多数失败 case 的第一主断点，甚至经常直接阻碍后续 LLM 和 CodeQL 发挥。”

当前总结果是：

- `candidate-selection dominant`: `1 / 7`
- `not_primary`: `6 / 7`

也就是说：

- candidate selection 确实是一个真实脆弱点
- 但在这 7 个 family 里，它只在 `SSRF-JA-REPO-001` 上构成第一主断点
- 更常见的主断点是：
  - DB / compile coverage 偏差
  - source 语义错位
  - sink / query 语义缺口
  - 目标命中错位
  - LLM sink 标注的 run-to-run variance

## 3. 7 个 family 的正式归因

| family | query | candidate gap 是否存在 | 最强证据 | candidate_selection_role | primary_break_layer | 结论 |
|---|---|---|---|---|---|---|
| `PT-JA-REPO-001` | `cwe-022wLLM` | 有，但不是主因 | 最小 source oracle 一加就中 | `not_primary` | `variance` | compile recipe 只保留 util 层，controller/service 根本没进 DB。 |
| `SSRF-JA-REPO-001` | `cwe-918wLLM` | 有，且是主因 | 补回 `RestTemplate.getForObject` 后最小 oracle 恢复命中 | `candidate-selection dominant` | `candidate_selection` | sink 在 raw extraction 里存在，但被 internal package 规则筛掉。 |
| `PT-JA-REPO-CVE-2024-53677-VULN` | `cwe-022wLLM` | 有，但不是主因 | receiver-based sink oracle 仍然 `0` 结果 | `not_primary` | `query_semantics` | 把缺失 API 注回后，固定 query/sink 语义仍然走不通。 |
| `SSRF-JA-REPO-CVE-2023-3432-VULN` | `cwe-918wLLM` | 仅 source 侧有局部缺口 | `CANDSEL001` 只恢复到错误语义片段上的 `System.getenv` | `not_primary` | `query_semantics_mismatch` | sink 与 summary 已在，真正缺的是对 `LoadJson.path` 这条请求入口的 source 建模。 |
| `vert-x3__vertx-web_CVE-2018-12542_3.5.3.CR1` | `cwe-022wLLM` | 无主导性 candidate gap | baseline 已有 6 条结果，但全都没打中官方 target | `not_primary` | `target_alignment` | request source 与 `sendFile` sink 都在，问题是结果落点偏到其它 template/file 路径。 |
| `jmrozanec__cron-utils_CVE-2021-41269_9.1.5` | `cwe-094wLLM` | 无主导性 candidate gap | source 参数与 sink 都已物化，但 `Throwable.getMessage` 不进 summary | `not_primary` | `summary_semantics` | 最可疑的断点是“异常对象到异常消息字符串”的桥接缺失。 |
| `rhuss__jolokia_CVE-2018-1000129_1.4.0` | `cwe-079wLLM` | 无主导性 candidate gap | 同一 DB / 同类 candidate 下 `r2` 恢复 `sink=5` 且命中官方 target | `not_primary` | `llm_variance` | baseline sink=0 不是候选漏选，而是 Stage 3 sink 标注高波动。 |

## 4. 三轮实验分别证明了什么

### 4.1 第一轮：候选筛选确实能单独杀死能力

`SSRF-JA-REPO-001` 提供了最干净的正例：

- `RestTemplate.getForObject` 在 raw extraction 中存在
- 但 stub 包被误写进 internal package 列表
- Stage 3 前直接被筛掉
- 只要把 sink API 注回，并用最小 oracle 规范化 `p0`，目标命中就恢复

这证明：

> candidate selection 不是伪问题，它在特定 family 上确实可以单独决定成败。

### 4.2 第二轮：更多失败其实已经发生在 candidate 之后

`SSRF-JA-REPO-CVE-2023-3432-VULN`：

- `SURL.getBytes`、`URL.openConnection`、`SURL.create` 都已经在
- 但 source 只落到 `System.getenv`
- 因此主问题是 source 语义错位，不是 sink 候选漏选

`vert-x3__vertx-web_CVE-2018-12542_3.5.3.CR1`：

- `request.path`
- `normalizePath`
- `TemplateEngine.render`
- `sendFile`

这些都已在 baseline 中。

但 baseline 的 6 条结果都落在别的 sink 上，没有打到官方 differential target。

这说明：

> 只看“有没有候选 API”已经不够，还要看 query 最终把结果打到了哪里。

### 4.3 第三轮：还有一类失败完全是更下游的语义与波动问题

`jmrozanec__cron-utils_CVE-2021-41269_9.1.5`：

- `CronParser.parse(String)` 参数 source 已物化
- `buildConstraintViolationWithTemplate` sink 已物化
- 但 `Throwable.getMessage()` 没进 summary

这里更像：

> query 走不到“异常消息字符串”这一段，而不是 candidate 没看到 API。

`rhuss__jolokia_CVE-2018-1000129_1.4.0`：

- baseline candidate set 里就有 `Writer.write` / `append` / `JSONStreamAware.writeJSONString`
- baseline 却 `sink=0`
- `r2` 在同一 DB、同类 candidate 下恢复到 `sink=5` 且命中官方 target

这里最强的结论是：

> 失败主因已经不是候选筛选，而是 Stage 3 sink 标注与最终 target 命中的 run-to-run variance。

## 5. 对原假设的最终改写

如果把原假设改写成更精确的版本，那么当前最稳妥的表述是：

> IRIS 的 candidate selection 是一个真实、可复现、在个别 family 上占主导的脆弱点；但它不是这 7 个失败 family 的统一第一主因。更常见的主断点发生在 source/sink/query 语义建模、异常/消息桥接、DB 覆盖，以及结果 target alignment 这些更下游层面。

## 6. 下一步最值得做的实验

按优先级，下一步应拆成三条线，而不是继续泛化做更多 candidate 注回。

1. `source 语义建模线`
   - 重点 case：
     - `SSRF-JA-REPO-CVE-2023-3432-VULN`
   - 目标：
     - 让 request-origin 参数或 wrapper 入口进入 source candidate / source materialization

2. `summary / bridge 语义线`
   - 重点 case：
     - `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`
   - 目标：
     - 验证异常对象到异常消息字符串的桥接是否是关键缺边

3. `target alignment / label variance 线`
   - 重点 case：
     - `vert-x3__vertx-web_CVE-2018-12542_3.5.3.CR1`
     - `rhuss__jolokia_CVE-2018-1000129_1.4.0`
   - 目标：
     - 区分“命中了别的可疑路径”与“真正没能力走到官方 target”
     - 区分“候选漏选”与“LLM sink 标注高波动”

## 7. 一句话总结

这 7 个 family 的正式实验最终说明：

> candidate selection 是 IRIS 的一个真脆弱点，但只在 `1/7` family 上构成第一主断点；把它当成 IRIS 失败的统一解释，会系统性高估候选筛选的重要性，并低估更下游的语义建模与结果对齐问题。
