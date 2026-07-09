# IRIS LLM 差异怀疑 Case 重跑小计划

## 1. 文档定位

这份文档定义一轮最小重跑实验，用来优先回答：

> 当前 5 个官方 case 里，怀疑由 `LLM / provider` 差异导致的失败，究竟是随机波动，还是稳定的系统性差异？

这轮实验不是：

- 官方 `IRIS+GPT-4` 复现
- 能力改动实验
- 静态分析链路诊断扩展

它属于：

- `Learning Run`
- `official_case_followup`
- `LLM-variance diagnosis`

## 2. 目标问题

本轮只回答两个问题：

1. `jmrozanec__cron-utils_CVE-2021-41269_9.1.5` 的 `source=0`，是否只是 `DeepSeek` 输出波动？
2. `rhuss__jolokia_CVE-2018-1000129_1.4.0` 的 `sink=0`，是否只是 `DeepSeek` 输出波动？

若多次重跑后：

- `cron-utils` 仍然稳定 `source=0`
- `jolokia` 仍然稳定 `sink=0`

则当前更应把这两条线归类为：

- `provider-sensitive systematic failure`

而不是：

- `single-run random failure`

## 3. 为什么先做这轮

当前 5 个官方 case 中，最像 `LLM` 差异主导的是：

1. `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`
   - 本地：`sources=0, sinks=1, taint-propagators=20, results=0`
2. `rhuss__jolokia_CVE-2018-1000129_1.4.0`
   - 本地：`sources=12, sinks=0, taint-propagators=42, results=0`
   - 且 `Stage 3 JSON parse errors = 27`

这两条线都有一个共同特点：

- 主流程已经跑完
- CodeQL DB 已成功建立
- 失败集中出现在 `Stage 3/4` 的语义标注闭环上

因此，它们比 `vertx-web` 这类“已有大量路径但未命中官方点位”的 case，更适合作为 LLM 波动优先排查对象。

## 4. 冻结边界

这轮实验必须严格冻结除 `run_id` 之外的几乎所有变量。

### 4.1 冻结对象

固定不变：

1. `IRIS` 代码版本
   - 使用当前已验证可跑通的本地运行兼容基线
2. case checkout
   - 不重新切换源码版本
3. CodeQL DB
   - 优先复用当前已建好的 DB
   - 不在这轮里重新讨论 DB 正确性
4. provider
   - 固定 `DeepSeek`
5. 模型名
   - 固定当前主实验模型别名与实际模型配置
6. prompt
   - 不改 prompt
7. candidate selection
   - 不改
8. source / sink / taint-propagator 建模逻辑
   - 不改
9. post-processing
   - 不改

### 4.2 允许变化

只允许变化：

1. `run_id`
2. 与 `run_id` 绑定的新输出目录
3. Stage 3/4 的 LLM 返回内容

## 5. Case 范围

本轮只跑 2 个 case：

1. `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`
   - query：`cwe-094wLLM`
   - 观察重点：`source` 是否从 `0` 恢复
2. `rhuss__jolokia_CVE-2018-1000129_1.4.0`
   - query：`cwe-079wLLM`
   - 观察重点：`sink` 是否从 `0` 恢复

不在本轮内重跑：

1. `perwendel__spark_CVE-2018-9159_2.7.1`
2. `perwendel__spark_CVE-2016-9177_2.5.1`
3. `vert-x3__vertx-web_CVE-2018-12542_3.5.3.CR1`

原因：

- 它们当前更像“弱复现”或“静态结果差异”
- 不是 LLM 波动排查的最低成本入口

## 6. 重跑规模

建议每个 case 重跑 `3-5` 次。

最小可接受规模：

- 每个 case `3` 次

推荐规模：

- 每个 case `5` 次

建议先从 `3` 次开始；如果结果明显分化，再补到 `5` 次。

## 7. run_id 规划

建议使用新的批次前缀，不覆盖 `DEEPSEEK_TRUST01`。

推荐：

- `DEEPSEEK_LLMVAR01`

case execution run id 建议：

- `DEEPSEEK_LLMVAR01__cronutils_r1`
- `DEEPSEEK_LLMVAR01__cronutils_r2`
- `DEEPSEEK_LLMVAR01__cronutils_r3`
- `DEEPSEEK_LLMVAR01__jolokia_r1`
- `DEEPSEEK_LLMVAR01__jolokia_r2`
- `DEEPSEEK_LLMVAR01__jolokia_r3`

如果扩到 5 次，再补：

- `..._r4`
- `..._r5`

## 8. 执行矩阵

最小矩阵：

| case | query | rerun count | 目标 |
|---|---|---:|---|
| `jmrozanec__cron-utils_CVE-2021-41269_9.1.5` | `cwe-094wLLM` | `3` | 验证 `source=0` 是否稳定 |
| `rhuss__jolokia_CVE-2018-1000129_1.4.0` | `cwe-079wLLM` | `3` | 验证 `sink=0` 是否稳定 |

## 9. 执行规则

### 9.1 运行前

每次运行前必须确认：

1. 使用同一份 `.env_deepseek` 来源
2. 环境变量继续做 CRLF 清洗
3. `OPENAI_API_KEY / OPENAI_BASE_URL / OPENAI_MODEL` 设置方式不变
4. `JAVA_HOME / MAVEN_HOME / CodeQL` 路径不变
5. case 对应 DB 已存在且不重建

### 9.2 运行中

每次运行必须：

1. 使用全新 `run_id`
2. 保留完整 `command.log`
3. 保留 Stage 3/4 `raw prompts`
4. 保留 Stage 3/4 `raw responses`
5. 保留 `api_labels_gpt-4.json`
6. 保留 `llm_labelled_source_apis.json`
7. 保留 `llm_labelled_sink_apis.json`
8. 保留 `llm_labelled_taint_prop_apis.json`
9. 保留 `llm_labelled_source_func_params.json`
10. 保留 `final_results.json`

### 9.3 运行后

每次运行都必须抽取同一组指标：

1. `stage3_json_parse_errors`
2. `stage3_llm_labelled_apis`
3. `num_labelled_sources`
4. `num_labelled_sinks`
5. `num_labelled_taint_propagators`
6. `num_labelled_func_param_sources`
7. `vanilla_result.num_results`
8. `vanilla_result.num_paths`
9. `vanilla_result.recall_method`
10. `posthoc_filter_result.recall_method`

## 10. 结果判定标准

### 10.1 对 `cron-utils`

若 `3/3` 次都满足：

- `num_labelled_sources = 0`
- `recall_method = false`

则可初步判定：

- 当前 `DeepSeek + IRIS` 对这个 case 的失败更像稳定 `LLM/provider` 差异

若出现：

- 有的 run `sources=0`
- 有的 run `sources>0`
- 并且最终 `recall_method` 也随之波动

则应判定：

- 该 case 对 LLM 输出波动高度敏感

### 10.2 对 `jolokia`

若 `3/3` 次都满足：

- `num_labelled_sinks = 0`
- `recall_method = false`

则可初步判定：

- 当前 `DeepSeek + IRIS` 对这个 case 的失败更像稳定 `LLM/provider` 差异

若出现：

- 有的 run `sinks=0`
- 有的 run `sinks>0`
- 结果随之波动

则应判定：

- 该 case 对 LLM 输出波动高度敏感

### 10.3 何时停止

如果前 `3` 次已经完全同型，例如：

- `cron-utils` 连续 `3` 次 `source=0`
- `jolokia` 连续 `3` 次 `sink=0`

则可以停止，不必强行补到 `5` 次。

只有在前 `3` 次结果分化明显时，才扩到 `5` 次。

## 11. 产物落盘

建议单开目录：

```text
artifacts/iris_case_trustworthiness/DEEPSEEK_LLMVAR01/
```

建议结构：

```text
artifacts/iris_case_trustworthiness/DEEPSEEK_LLMVAR01/
  README.md
  rerun_matrix.tsv
  summary.tsv
  official/
    jmrozanec__cron-utils_CVE-2021-41269_9.1.5/
      rerun_1/
      rerun_2/
      rerun_3/
    rhuss__jolokia_CVE-2018-1000129_1.4.0/
      rerun_1/
      rerun_2/
      rerun_3/
```

每个 `rerun_n` 下至少保留：

1. `iris_run/`
2. `raw_prompts/`
3. `raw_responses/`
4. `local_observation/run_summary.json`
5. `notes/execution_context.json`

## 12. 预期输出

这轮结束后，至少应能产出一份简短结论：

1. `cron-utils` 的 `source=0` 是随机波动，还是稳定失败
2. `jolokia` 的 `sink=0` 是随机波动，还是稳定失败
3. `Stage 3 JSON parse errors` 与最终 `source/sink` 缺失是否相关
4. 是否还有必要再去重跑其余 3 个官方 case

## 13. 非目标

这轮明确不做：

1. 不更换为 `GPT-4`
2. 不修改 `IRIS` prompt
3. 不修改 `candidate-selection`
4. 不重建 DB 来比较静态差异
5. 不把这轮结果直接解释为“官方结果真假”

## 14. 一句话执行建议

先用 `DEEPSEEK_LLMVAR01` 对 `cron-utils` 和 `jolokia` 各跑 `3` 次，优先判断：

> 当前最像 `LLM` 导致的两个失败，到底是偶发波动，还是稳定的 provider-sensitive failure。
