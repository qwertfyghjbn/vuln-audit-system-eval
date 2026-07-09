# IRIS 官方 5 Case 声称与本地复现对照总结

## 1. 文档定位

这份文档只回答一个问题：

> 在 `DEEPSEEK_TRUST01` 这批 5 个官方 case 上，官方 `IRIS+GPT-4` 的结果声称，与本地实际跑出来的结果，差异到底在哪里？

这里的“本地结果”指：

- 同一批次 5/5 case 都完成 `fetch/build -> CodeQL DB -> IRIS -> 归档`
- 本地运行使用的是当前最小运行兼容基线
- LLM 提供方使用 `DeepSeek`，不是官方 `GPT-4`

因此，这份文档不是“官方论文真假”的最终裁决，而是“当前本地可复现实证”的对照表。

## 2. 证据范围

主证据：

- 批次进度表：
  - [artifacts/iris_case_trustworthiness/DEEPSEEK_TRUST01/_shared/official_progress.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_TRUST01/_shared/official_progress.tsv:1)
- 5 个 case 的官方行数据：
  - `official_row/IRIS+GPT-4.json`
  - `official_row/CodeQL.json`
- 5 个 case 的本地摘要：
  - `local_observation/run_summary.json`

## 3. 总体结论

先给最重要的结论：

1. 这 5 个 case 里，`5/5` 都成功跑完到 `Stage 9`，所以“官方 case 在本机完全跑不起来”这个结论不成立。
2. 但只有 `2/5` 本地结果达到 `recall=true`，所以“官方声称可以稳定本地复现”同样不成立。
3. 即使在 `recall=true` 的 2 个 case 上，本地 `alerts/paths` 也明显低于官方声称，因此更准确的说法是“弱复现”，不是“等价复现”。
4. 另外 `3/5` 的失败模式并不一致，至少已经分化成：
   - `source/sink` 一端缺失导致零路径
   - 已形成不少路径，但没有命中官方 ground truth
   - Stage 3/4 存在可恢复的 JSON 解析噪声

## 4. 逐案对照

### 4.1 Anchor

- case：`perwendel__spark_CVE-2018-9159_2.7.1`
- 角色：`anchor`
- 官方 `IRIS+GPT-4`：`Recall=1, Alerts=10, Paths=32`
- 官方 `CodeQL`：`Recall=1, Alerts=12, Paths=36`
- 本地 `vanilla`：`Recall@Method=true, Results=2, Paths=8`
- 本地 `posthoc`：`Recall@Method=true, Results=2, Paths=8`
- 本地标签统计：`sources=10, sinks=4, taint-propagators=38`
- 解析噪声：`Stage 3 JSON parse errors = 6`
- 失败模式判断：
  - 这不是“未复现”，而是“弱复现”
  - 方向上复现了官方 `recall=true`
  - 但告警数和路径数明显缩水，说明本地行为与官方不是同一量级

证据：

- [anchor run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_TRUST01/official/perwendel__spark_CVE-2018-9159_2.7.1/local_observation/run_summary.json:1)

### 4.2 Contrast

- case：`perwendel__spark_CVE-2016-9177_2.5.1`
- 角色：`contrast`
- 官方 `IRIS+GPT-4`：`Recall=1, Alerts=10, Paths=40`
- 官方 `CodeQL`：`Recall=1, Alerts=11, Paths=35`
- 本地 `vanilla`：`Recall@Method=true, Results=4, Paths=11`
- 本地 `posthoc`：`Recall@Method=true, Results=4, Paths=7`
- 本地标签统计：`sources=5, sinks=2, taint-propagators=48`
- 解析噪声：`Stage 3 JSON parse errors = 4`
- 失败模式判断：
  - 同样属于“弱复现”
  - 能命中官方漏洞方法，但产出规模远低于官方行数据
  - `posthoc` 进一步把路径从 `11` 压到 `7`，说明后处理会继续缩减结果

证据：

- [contrast run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_TRUST01/official/perwendel__spark_CVE-2016-9177_2.5.1/local_observation/run_summary.json:1)

### 4.3 Differential-1

- case：`vert-x3__vertx-web_CVE-2018-12542_3.5.3.CR1`
- 角色：`differential-1`
- 官方 `IRIS+GPT-4`：`Recall=1, Alerts=6, Paths=12`
- 官方 `CodeQL`：`Recall=0, Alerts=0, Paths=0`
- 本地 `vanilla`：`Recall@Method=false, Results=6, Paths=22`
- 本地 `posthoc`：`Recall@Method=false, Results=6, Paths=15`
- 本地标签统计：`sources=45, sinks=24, taint-propagators=70`
- 解析噪声：`Stage 3 JSON parse errors = 15`
- 失败模式判断：
  - 这是“有结果但没复现官方命中”的类型
  - 本地并不是零信号，相反它形成了不少结果和路径
  - 但这些路径没有命中官方 `ground truth method`
  - 当前更像“路径错配 / 标签噪声过高 / 命中位置偏移”，而不是简单的 `source` 或 `sink` 缺失

证据：

- [differential-1 run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_TRUST01/official/vert-x3__vertx-web_CVE-2018-12542_3.5.3.CR1/local_observation/run_summary.json:1)

### 4.4 Differential-2

- case：`jmrozanec__cron-utils_CVE-2021-41269_9.1.5`
- 角色：`differential-2`
- 官方 `IRIS+GPT-4`：`Recall=1, Alerts=2, Paths=1`
- 官方 `CodeQL`：`Recall=0, Alerts=0, Paths=0`
- 本地 `vanilla`：`Recall@Method=false, Results=0, Paths=0`
- 本地 `posthoc`：`Recall@Method=false, Results=0, Paths=0`
- 本地标签统计：`sources=0, sinks=1, taint-propagators=20`
- 解析噪声：`Stage 3 JSON parse errors = 6`
- 失败模式判断：
  - 这是最典型的 `source` 缺失塌缩
  - `sink` 和 `taint-propagator` 并非完全没有
  - 但因为 `sources=0`，最终没有形成任何路径
  - 因此，官方“IRIS 能打败 CodeQL”的差异优势，在本地这条线上没有复现出来

证据：

- [differential-2 run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_TRUST01/official/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/local_observation/run_summary.json:1)

### 4.5 Control

- case：`rhuss__jolokia_CVE-2018-1000129_1.4.0`
- 角色：`control`
- 官方 `IRIS+GPT-4`：`Recall=1, Alerts=71, Paths=133`
- 官方 `CodeQL`：`Recall=1, Alerts=1, Paths=1`
- 本地 `vanilla`：`Recall@Method=false, Results=0, Paths=0`
- 本地 `posthoc`：`Recall@Method=false, Results=0, Paths=0`
- 本地标签统计：`sources=12, sinks=0, taint-propagators=42`
- 解析噪声：`Stage 3 JSON parse errors = 27`
- 失败模式判断：
  - 这是与 `differential-2` 对称的另一种塌缩
  - 这里不是 `source` 缺失，而是 `sink` 缺失
  - 同时它的 Stage 3 解析噪声是 5 个 case 里最严重的
  - 官方行数据声称 `Alerts=71, Paths=133`，而本地是 `0/0`，差距最大

证据：

- [control run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_TRUST01/official/rhuss__jolokia_CVE-2018-1000129_1.4.0/local_observation/run_summary.json:1)

## 5. 失败模式归类

把 5 个 case 合起来看，可以分成 3 类。

### 5.1 弱复现

包含：

- `perwendel__spark_CVE-2018-9159_2.7.1`
- `perwendel__spark_CVE-2016-9177_2.5.1`

特征：

- `recall=true`
- 但 `alerts/paths` 明显低于官方声称
- 存在可恢复的 Stage 3 JSON 解析噪声

含义：

- 这些 case 能证明本地系统并非完全失效
- 但不足以证明“本地行为等价于官方行为”

### 5.2 路径错配型未复现

包含：

- `vert-x3__vertx-web_CVE-2018-12542_3.5.3.CR1`

特征：

- 已经有较多 `source/sink/taint-propagator`
- 已经形成多条结果路径
- 但 `recall@method=false`

含义：

- 问题不在“有没有路径”，而在“路径是否打到官方认定的位置”

### 5.3 一端语义缺失导致零路径

包含：

- `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`
- `rhuss__jolokia_CVE-2018-1000129_1.4.0`

特征：

- 一个 case `source=0`
- 一个 case `sink=0`
- 最终 `results=0, paths=0`

含义：

- IRIS 的主流程是跑完了
- 但 `Stage 3/4` 的语义标注没有稳定形成闭环

## 6. 对“官方 case 是否可信”的当前判断

截至这批 5 case，本地证据支持的判断是：

1. 官方 case 不是“伪 case”。
   - 因为其中 `2/5` 本地仍然打到了 `recall=true`。

2. 但官方行数据不能直接当作“本地可稳定复现事实”。
   - 因为当前只有 `2/5` 命中 `recall=true`
   - 且这 `2/5` 仍然是明显缩水版

3. 对官方最有价值的两类声称，本地都还没有被充分验证：
   - `IRIS+GPT-4` 明显优于 `CodeQL recall=0` 的差异优势
   - 高 alerts / 高 paths 的大规模命中能力

更谨慎的表述应是：

> 官方 case 可以作为“值得观察的对照样本”，但当前不足以作为“本地已被证实可复现的强证据集”。

## 7. 现阶段最合理的使用方式

当前这 5 个官方 case 更适合被用作：

1. 可运行性验证样本
2. 失败模式分型样本
3. 官方声称与本地行为差异的证据样本

而不适合直接被当作：

1. 已稳定复现的官方 benchmark 子集
2. 能直接支持“IRIS 在本机复现了官方能力结论”的证据

## 8. 一句话结论

这批 5 个官方 case 的本地结果，不是“完全失败”，也不是“成功复现官方结果”，而是：

> `5/5` 跑通，`2/5` 弱复现，`3/5` 未复现，且未复现已经分化成多种不同失败模式。
