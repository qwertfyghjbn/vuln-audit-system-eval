# IRIS LLM 差异重跑结果总结

## 1. 文档定位

这份文档总结 `DEEPSEEK_LLMVAR01` 这一轮最小重跑实验的实际结果。

它回答的问题是：

> 对 `cron-utils` 和 `jolokia` 这两个最像 `LLM/provider` 差异主导的官方 case，多次重跑之后，失败形态是否稳定？这对“官方声称是否可信”意味着什么？

这不是新的实验计划，也不是能力改动总结。

## 2. 证据范围

主证据：

- 重跑计划：
  - [iris_llm_variance_rerun_plan.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_llm_variance_rerun_plan.md:1)
- 批次摘要：
  - [DEEPSEEK_LLMVAR01/summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_LLMVAR01/summary.tsv:1)
- 本轮重跑归档：
  - [cron-utils r1](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_LLMVAR01/official/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/rerun_1/local_observation/run_summary.json:1)
  - [jolokia r1](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_LLMVAR01/official/rhuss__jolokia_CVE-2018-1000129_1.4.0/rerun_1/local_observation/run_summary.json:1)
  - [jolokia r2](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_LLMVAR01/official/rhuss__jolokia_CVE-2018-1000129_1.4.0/rerun_2/local_observation/run_summary.json:1)
  - [jolokia r3](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_LLMVAR01/official/rhuss__jolokia_CVE-2018-1000129_1.4.0/rerun_3/local_observation/run_summary.json:1)
- 对照基线：
  - [iris_official_case_claim_vs_local_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_official_case_claim_vs_local_summary.md:1)

## 3. 先给结论

1. `cron-utils` 已完成 `3` 轮重跑，结果已经足够说明：`source=0` 是稳定失败形态。
2. `jolokia` 已完成 `3` 轮重跑，结果已经足够说明：`sink=0` 不是稳定失败形态。
3. `jolokia` 在冻结配置下出现了明显 run-to-run variance：
   - `r1` 完全失败
   - `r2` 命中官方方法点
   - `r3` 恢复了 `sink`，但只命中非官方目标点
4. 因此，`jolokia` 这条官方成功线不能再被解读为“本地稳定可复现”，更准确的说法是“官方成功声称在本地是可达但不稳定”。
5. 当前没有证据证明官方一定采用了“多次运行取最佳”，但这组结果足以说明：如果采用 `best-of-n` 统计，表观 recall 可能显著高于单次运行的典型表现，尤其对 `jolokia` 这种高方差 case 更是如此。

## 4. 个案结果

### 4.1 `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`

官方与基线背景：

- 官方声称：`IRIS+GPT-4 recall=1`，`CodeQL recall=0`
- 本地基线 `DEEPSEEK_TRUST01`：`sources=0, sinks=1, results=0, recall_method=false`

当前已完成 `3` 轮重跑：

| run | parse errors | sources | sinks | taint-propagators | results | recall@method | 观察 |
|---|---:|---:|---:|---:|---:|---:|---|
| `r1` | `7` | `0` | `1` | `22` | `0` | `false` | 延续基线 `source=0` 失败 |
| `r2` | `7` | `0` | `2` | `1` | `0` | `false` | 仍然 `source=0`，未形成结果 |
| `r3` | `5` | `0` | `2` | `10` | `0` | `false` | 第三次保持 `source=0` 零结果 |

当前可写入的判断：

- `source=0` 是稳定失败形态。
- 尽管 `sink` 和 `taint-propagator` 数量会波动，但这没有改变最终 `results=0`、`recall=false` 的收敛结果。
- 这条线现在已经可以从“证据不足”升级为“冻结配置下的稳定 provider-sensitive failure”。

对官方可信性的含义：

- 当前可以更强地说：官方 `recall=1` 的差异优势，在本地 `DeepSeek + IRIS` 上没有得到重跑支持。
- 这并不自动证明官方声称错误，但至少说明它不是当前冻结配置下的稳定可复现结论。
- 对这条 case，更合适的标签已经是“官方成功声称未在本地复现，且失败模式稳定”。

### 4.2 `rhuss__jolokia_CVE-2018-1000129_1.4.0`

官方与基线背景：

- 官方声称：`IRIS+GPT-4 recall=1`，`CodeQL recall=1`
- 本地基线 `DEEPSEEK_TRUST01`：`sources=12, sinks=0, results=0, recall_method=false`

当前已完成 `3` 轮重跑：

| run | parse errors | sources | sinks | taint-propagators | results | recall@method | 观察 |
|---|---:|---:|---:|---:|---:|---:|---|
| `r1` | `23` | `5` | `0` | `70` | `0` | `false` | 延续基线 `sink=0` 失败 |
| `r2` | `20` | `11` | `5` | `82` | `1` | `true` | 恢复 `sink`，命中官方方法点 |
| `r3` | `26` | `5` | `5` | `105` | `1` | `false` | 恢复 `sink`，但只命中非官方目标点 |

当前可写入的判断：

1. `sink=0` 不是稳定失败形态。
   - 因为 `r2`、`r3` 都恢复到了 `sink=5`。

2. `Stage 3 JSON parse errors` 也不是充分解释。
   - 三轮都有解析噪声，范围在 `20-26`。
   - 但同样有解析噪声的 `r2` 仍然打到了 `recall_method=true`。

3. 真正不稳定的是“从 Stage 3 标签恢复，到最终是否命中官方目标点”这一段。
   - `r2`：恢复 `sink` 且命中官方方法
   - `r3`：恢复 `sink` 但未命中官方方法

对官方可信性的含义：

- 官方 `recall=1` 至少不是“本地绝不可能发生”的结果，因为 `r2` 已经命中过。
- 但这条官方成功线也不能被解释成“冻结配置下稳定单次可复现”，因为 `r1` 和 `r3` 都没有稳定复现同一结果。
- 更准确的说法应当是：
  - 官方成功声称是 `reachable`
  - 但不是 `single-run stable`

## 5. 波动模式归类

把两个 case 放在一起看，目前已经分化成两种不同状态。

### 5.1 `cron-utils`：稳定 source-zero 失败线

当前 `3` 轮已经足够说明：

- `source=0` 没有恢复
- `results=0` 没有恢复
- `recall_method=false` 没有恢复

因此它更应该被归类为：

- `stable source-zero failure`

而不是：

- `pending classification`
- `high variance success/failure mix`

### 5.2 `jolokia`：高方差官方成功线

当前 `3` 轮已经足够说明：

- 从 `sink=0` 到 `sink>0` 会波动
- 从“形成结果”到“命中官方方法点”也会波动

因此它更应该被归类为：

- `high-variance official success case`

而不是：

- `stable sink-zero failure`

## 6. 对“官方可信性”的当前含义

### 6.1 不能再把官方单条结果当成稳定行为画像

至少对 `jolokia` 来说，官方那一行 `recall=1` 更像：

- 一次可达的成功样本

而不是：

- 冻结配置下大概率稳定发生的单次结果

### 6.2 也不能反过来把官方声称直接判死

`jolokia r2` 已经说明：

- 官方成功线在本地 `DeepSeek + IRIS` 下不是完全不可达

所以当前更严谨的表述不是“官方夸大”，而是：

- 官方结果缺少稳定性语义
- 单行 CSV 不能代表单次运行分布

### 6.3 “官方可能是多次运行取最佳”目前仍是合理怀疑，不是已证事实

当前证据能够支持的最强表述是：

- 如果官方采用 `best-of-n` 口径，那么像 `jolokia` 这种高方差 case 的最终 recall 会被显著放大

当前证据还不能支持的表述是：

- 官方确定使用了多次运行取最佳

因为我们没有官方执行协议、重复运行日志或统计口径说明。

## 7. 对后续实验的建议

1. `jolokia` 暂时不需要继续重跑。
   - 当前 `3` 轮已经回答了“`sink=0` 是否稳定”这个问题。
   - 继续加跑只会把问题从“是否稳定失败”转成“成功率分布是多少”，这是另一个实验题。

2. `cron-utils` 暂时也不需要继续重跑。
   - 当前 `3` 轮已经完成最小证据闭环。
   - 继续加跑只会把“稳定失败是否成立”转成“失败概率是否接近 100%”这一更细粒度问题。

3. 如果后续要审计“官方是否可能隐含 `best-of-n`”，应该单开方法学实验。
   - 不再沿用当前这份最小重跑计划
   - 而是明确设计成：
     - 固定 case
     - 固定配置
     - 固定 `n`
     - 比较 `single-run`、`majority-run`、`any-hit-in-n`

## 8. 一句话结论

这轮 `LLM variance` 重跑已经证明：

> `cron-utils` 在本地表现为稳定的 `source-zero` 失败线，而 `jolokia` 在本地表现为“可达但不稳定”的高方差官方成功线。
