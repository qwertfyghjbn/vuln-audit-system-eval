# IRIS 学习评估总体报告

## 1. 文档定位

这份文档是当前仓库内 `IRIS` 学习评估材料的正式汇总版。

它回答的问题是：

> 截至当前，基于本仓库已经完成的官方行为观察、官方 case 可信度对照、自有 case 对照、LLM 方差重跑、candidate-selection 诊断、contrast 诊断，`IRIS` 在本地学习评估中已经呈现出什么总体画像？

这份文档的目标是：

- 收口现有学习性实验结论
- 给出按实验线组织的统一叙事
- 给出当前最稳妥的总体判断与后续工作方向

这不是：

- 正式 benchmark 排名报告
- 官方论文真伪裁决
- `IRIS` 能力改造完成后的最终能力结论

## 2. 证据边界与版本边界

### 2.1 证据边界

本报告只汇总当前已完成、已写入仓库的下列材料：

- 总入口与记录规则：
  - [reports/systems/iris/README.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/README.md:1)
  - [reports/systems/iris/registries/variant_registry.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/variant_registry.md:1)
- 官方行为线：
  - [iris_official_behavior_stage_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_official_behavior_stage_summary.md:1)
  - [canonical_results.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:1)
- 官方 case 可信度对照线：
  - [iris_official_case_claim_vs_local_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_official_case_claim_vs_local_summary.md:1)
- 自有对照线：
  - [iris_self_first_round_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_self_first_round_results.md:1)
  - [artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/summary.tsv:1)
- LLM 方差线：
  - [iris_llm_variance_rerun_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_llm_variance_rerun_results.md:1)
  - [artifacts/iris_case_trustworthiness/DEEPSEEK_LLMVAR01/summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_LLMVAR01/summary.tsv:1)
- candidate-selection 能力诊断线：
  - [iris_candidate_selection_baseline_diagnosis.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_candidate_selection_baseline_diagnosis.md:1)
  - [iris_candidate_selection_all7_formal_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_candidate_selection_all7_formal_results.md:1)
- 官方线 vs 自有线 contrast 诊断线：
  - [iris_contrast_exp1_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_exp1_results.md:1)
  - [iris_contrast_exp2_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_exp2_results.md:1)
  - [iris_contrast_exp3_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_exp3_results.md:1)
  - [iris_contrast_batch_overall_judgment.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_batch_overall_judgment.md:1)

### 2.2 版本边界

本报告必须区分 3 类对象，不能混写成一个“IRIS”：

1. `official_upstream_baseline`
   - 对应当前登记线：`iris-upstream-observed`
   - 用于描述上游机制的观察目标

2. `runtime_compatibility_variant`
   - 对应当前主证据线：`iris-runtime-compat-001`
   - 用于恢复 `Native Evaluation Environment` 下的稳定可执行性

3. `capability_changing_variant`
   - 对应当前能力实验线：如 `iris-capability-candsel-001`
   - 用于验证候选生成、语义建模、prompt、ranking、后处理等能力边界

因此，下面所有总体结论如果未特别说明，默认是对“当前学习期本地主证据线”的总结，而不是对“未经补丁的官方上游 IRIS”做无条件外推。

## 3. 实验线地图

当前 `IRIS` 学习评估已经形成 6 条可区分的实验线：

| 实验线 | 代表文档 / run_id | 主要回答的问题 | 当前状态 |
|---|---|---|---|
| 官方行为线 | `OFFICIALSMOKE01`、[iris_official_behavior_stage_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_official_behavior_stage_summary.md:1) | `IRIS` 在本地是否已形成稳定可审计执行基线 | 已收口 |
| 官方 case 可信度线 | `DEEPSEEK_TRUST01`、[iris_official_case_claim_vs_local_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_official_case_claim_vs_local_summary.md:1) | 官方成功声称与本地实际结果差在哪 | 已收口 |
| 自有对照线 | `DEEPSEEK_SELF01`、[iris_self_first_round_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_self_first_round_results.md:1) | benchmark 自有 case 在同一冻结边界下呈现何种失败形状 | 已完成首轮 |
| LLM 方差线 | `DEEPSEEK_LLMVAR01`、[iris_llm_variance_rerun_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_llm_variance_rerun_results.md:1) | 哪些官方成功线是稳定失败，哪些是可达但高方差 | 已收口 |
| candidate-selection 诊断线 | `BASELINE_CANDSEL_DIAG01`、`CANDSEL001`、[iris_candidate_selection_all7_formal_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_candidate_selection_all7_formal_results.md:1) | candidate-selection 是否是主要失败断点 | 已形成 7 family 总结 |
| contrast 诊断线 | [iris_contrast_batch_overall_judgment.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_batch_overall_judgment.md:1) | 官方线与自有线分别断在哪一层 | 已收口 |

这 6 条线共同构成当前的学习评估闭环：

1. 官方行为线先回答“能不能跑”。
2. 官方可信度线再回答“官方声称能不能在本地弱复现或复现失败”。
3. 自有对照线回答“在本仓库关心的 family 上，本地失败具体长什么样”。
4. 方差线回答“失败是稳定塌缩还是高波动可达”。
5. candidate-selection 线回答“候选边界是不是统一主因”。
6. contrast 线把 `PT` 与 `SSRF` 的主断点层正式分流。

## 4. 阶段一：本地执行基线已经形成，但当前官方行为线仍然是 no-signal

截至当前，官方行为线已经能够稳定支持如下结论：

1. `IRIS` 的学习期部署骨架已经成立。
   - preflight 已通过。
   - 上游源码、Python、CodeQL、Java、固定 5-case smoke 输入契约均已打通。

2. 早期“完全跑不起来”的阶段已经结束。
   - 早期 `runtime_failure` 仅代表链路未通，不再代表当前状态。

3. 当前以 `iris-runtime-compat-001` 为证据代理时，固定 `5` 个 Java smoke case 已经可以稳定完成主流程。

4. 但当前官方行为线的稳定结果仍然是：
   - `5/5 completed`
   - `5/5 no_signal`
   - `5/5 num_vulnerable_paths = 0`

从 [canonical_results.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:1) 可直接看到：

- `OFFICIALSMOKE01` 下 5 个 case 均为 `runner_status = completed`
- 5 个 case 均为 `system_verdict = no_signal`
- `PT-JA-REPO-CVE-2024-53677-VULN` 为 `filtered_candidates = 19, llm_sources = 0, llm_sinks = 0`
- `SSRF-JA-REPO-CVE-2023-3432-VULN` 为 `filtered_candidates = 71, llm_sources = 0, llm_sinks = 6`
- `SSRF-JA-REPO-CVE-2023-3432-FIXED` 为 `filtered_candidates = 72, llm_sources = 0, llm_sinks = 6`

因此，当前阶段对 `IRIS` 的第一性判断已经不是“能不能运行”，而是：

> `IRIS` 在当前最小运行兼容边界下已经能稳定跑完，但尚未在固定 5-case 官方行为线中形成有效漏洞信号。

## 5. 阶段二：官方成功声称不是“全假”，但也不是“稳定本地复现”

官方 5 case 可信度对照线给出的总体结论非常明确：

1. 这 5 个官方 case 不是伪样本。
   - 因为本地并非 `5/5` 全零、全不可达。

2. 但这 5 个官方 case 也不能被当作“当前本地稳定可复现的强证据集”。

3. 当前更准确的批次级描述是：
   - `5/5` 跑通到 `Stage 9`
   - `2/5` 弱复现
   - `3/5` 未复现

`DEEPSEEK_TRUST01` 的 5 个官方 case 已经分化成 3 类：

| 类别 | case | 当前含义 |
|---|---|---|
| 弱复现 | `spark anchor`、`spark contrast` | `recall=true`，但 `alerts/paths` 明显低于官方声称，属于缩水版命中 |
| 路径错配型未复现 | `vertx-web differential-1` | 已形成不少结果和路径，但没有打到官方 `ground truth method` |
| 一端语义缺失导致零路径 | `cron-utils differential-2`、`jolokia control` | 一个是 `source=0`，一个是 `sink=0`，最终 `results=0` |

这条线对总体报告最重要的启发有两个：

1. 不能再把“官方成功声称”理解成单次、冻结配置下的稳定本地画像。
2. 也不能把当前未复现直接翻译成“官方声称错误”。

更稳妥的写法应是：

> 官方 case 可以作为高价值对照样本，但当前本地证据只支持“部分弱复现、部分未复现且失败分化”，不支持把官方单行结果直接上升为稳定本地事实。

## 6. 阶段三：自有对照线说明失败已进入“局部标签恢复但最终路径不成立”阶段

自有对照线 `DEEPSEEK_SELF01` 的三条冻结 case，当前都已完成单 case 独立运行，并全部走到 `Stage 9`。

从 [artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/summary.tsv:1) 可直接读出：

- `PT-JA-REPO-CVE-2024-53677-VULN`
  - `no_signal`
  - `candidates=25; sources=6; sinks=0; tp=5; posthoc_paths=0`
- `SSRF-JA-REPO-CVE-2023-3432-VULN`
  - `no_signal`
  - `candidates=77; sources=1; sinks=6; tp=15; posthoc_paths=0`
- `SSRF-JA-REPO-CVE-2023-3432-FIXED`
  - `target_match`
  - 这里的 `target_match` 指 fixed 对照组保持零路径，行为符合预期，而不是命中漏洞

这条线的总体意义是：

1. 当前失败已经不再只是“Stage 3 完全没有标签”。
2. 对 vulnerable case 来说，更准确的症状是：
   - 局部标签恢复了
   - 但最终路径仍然没有成立
3. fixed 控制组当前没有表现出明显误报趋势。

这使得总体报告可以更精确地区分两类状态：

- “完全塌缩型失败”
- “局部语义恢复后仍无法闭环型失败”

而当前自有线主样本明显更接近第二类。

## 7. 阶段四：LLM/provider 差异在线表现为两种不同状态

`DEEPSEEK_LLMVAR01` 这条线已经把两个高价值官方 case 分成了两种完全不同的状态。

### 7.1 `cron-utils`：稳定 `source-zero failure`

连续 `3` 轮重跑均表现为：

- `source = 0`
- `results = 0`
- `recall = false`

因此，这条线已经可以从“单次未复现”升级为：

> 冻结配置下的稳定 `source-zero` 失败线。

### 7.2 `jolokia`：`reachable but not single-run stable`

连续 `3` 轮重跑表现为：

- `r1`：`sink = 0`，完全失败
- `r2`：`sink = 5`，命中官方方法点
- `r3`：`sink = 5`，形成结果但未命中官方目标点

因此，这条线已经足够支持如下结论：

1. `sink=0` 不是稳定失败形态。
2. 官方成功线不是“本地绝对不可达”。
3. 但官方成功线也不是“单次稳定可复现”。

这对总体报告的价值在于：

- `IRIS` 当前并不是简单地“对 DeepSeek 全面失效”
- 更准确的说法是：
  - 有的 case 会稳定塌缩
  - 有的 case 是高方差可达

因此，总体报告中对 provider / LLM 差异的总结必须避免一刀切。

## 8. 阶段五：candidate-selection 是真实脆弱点，但不是统一第一主因

candidate-selection 线先给出了 baseline 诊断，再给出了 7 个 family 的正式结论。

当前最关键的正式结果来自 [iris_candidate_selection_all7_formal_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_candidate_selection_all7_formal_results.md:1)：

- `candidate-selection dominant`: `1 / 7`
- `not_primary`: `6 / 7`

这说明两件事必须同时写进总体报告：

1. candidate-selection 绝不是伪问题。
   - 它在 `SSRF-JA-REPO-001` 上确实构成第一主断点。

2. 但 candidate-selection 也不是大多数失败 family 的统一解释。
   - 更常见的主断点其实发生在更下游层：
     - DB / compile coverage
     - source 语义错位
     - sink / query 语义缺口
     - summary bridge 缺失
     - target alignment
     - LLM variance

这条结论对总体报告非常关键，因为它直接阻止了一种常见但错误的概括：

> “IRIS 当前失败主要就是因为 candidate 没选好。”

现有正式证据不支持这种强说法。更精确的总结应是：

> candidate-selection 是一个真实、可复现、在个别 family 上占主导的脆弱点，但它不是当前失败分布的统一第一主因。

## 9. 阶段六：官方线 vs 自有线的主断点已经明确分流

contrast 诊断线已经把 `PT` 与 `SSRF` 的主断点层正式分开。

### 9.1 `PT`：主问题是 `sink_not_in_candidate_set`

[iris_contrast_exp3_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_exp3_results.md:1) 已经把 `PT-JA-REPO-CVE-2024-53677-VULN` 收紧为：

- `source` 已恢复到 `6`
- `sink` 仍然是 `0`
- Stage 3 candidate set 停在 wrapper / 参数装配层
- file/path 暴露层没有被带进 candidate set

因此 `PT` 当前不能再被笼统写成“path non-connectivity”。

更准确的判断是：

> 它当前还没进入“source 与 sink 都已存在但路径不连”的层面，而是更早地断在 `sink_not_in_candidate_set`。

### 9.2 `SSRF vuln/fixed`：主问题是 `query_semantics_mismatch`

[iris_contrast_exp2_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_exp2_results.md:1) 已经证明：

- `vuln` 与 `fixed` 断在同一主层
- 这一主层不是 `sink completeness`
- 也不是 `summary` 大面积缺失
- 而是 `query_semantics_mismatch`

更具体地说：

1. `VULN`
   - 不是完全没有 source
   - 但唯一 source 落在错误语义片段上

2. `FIXED`
   - source 侧直接为空
   - 但 sink / summary 仍然保留了大部分请求路径

因此 `SSRF` 线当前更准确的总结是：

> 问题不在“有没有 sink”，而在 source-side query semantics 没有对准真实 request-origin path。

### 9.3 总体意义

这条 contrast 线让总体报告可以正式给出一个高价值判断：

> 官方线 vs 自有线不存在统一单一分叉层；`PT` 主要分叉在 `sink completeness`，并已收紧到 `sink_not_in_candidate_set`，而 `SSRF vuln/fixed` 主要分叉在 `path connectivity` 内部，并已收紧到 `query_semantics_mismatch`。

## 10. 当前最稳的总体画像

把前面 6 条实验线合起来，当前 `IRIS` 学习评估最稳的总体画像可以收口为 8 点：

1. 当前本地最小运行兼容线已经建立了稳定可审计执行基线。
2. 在这条基线上，固定官方 5-case smoke 仍表现为 `5/5 no_signal`。
3. 官方成功声称既不是“全假”，也不是“当前本地稳定复现事实”。
4. 自有 case 的主问题已从“完全无标签”进入“局部标签恢复但最终路径不成立”阶段。
5. provider / LLM 差异不是单一模式：
   - `cron-utils` 是稳定塌缩
   - `jolokia` 是高方差可达
6. candidate-selection 是真实脆弱点，但只在少数 family 上占第一主导。
7. 当前失败分布的更多主断点在更下游的语义与结果对齐层。
8. `PT` 与 `SSRF` 已经分流，后续学习与评估不能再混成同一类失败。

如果把它压缩成一句话，那么当前最稳妥的总体判断是：

> `IRIS` 在本地学习评估中已经从“运行链路未通”进入“可稳定执行但能力闭环不足”的阶段；它的失败不是单因子失败，而是按 case family 分流为 candidate boundary、source-side query semantics、summary / target alignment、以及 run-to-run variance 等多种不同主断点。

## 11. 当前不能过度宣称的事项

基于现有证据，以下说法都仍然过强，不应写入正式总体结论：

1. 不能说 `IRIS` 整体不适合本 benchmark。
   - 当前仍处于学习评估，而非规模化正式评测。

2. 不能把 `iris-runtime-compat-001` 的结果等同于“无补丁官方上游的自然表现”。
   - 当前主证据仍依赖最小运行兼容变体。

3. 不能把 candidate-selection 写成统一根因。
   - 这会与现有 `1/7 dominant, 6/7 not_primary` 的正式结果冲突。

4. 不能把官方单条成功行写成“单次稳定可复现”。
   - `jolokia` 已明确表现出高方差。

5. 不能把当前未复现直接翻译成“官方声称错误”。
   - 当前更合理的结论是“缺少稳定性语义，且本地分布与官方单行结果不等价”。

## 12. 对后续学习与评估的直接建议

下一步最值得继续推进的，不是泛化地“继续修 IRIS”，而是按 family 明确分流。

### 12.1 对 `PT`

优先方向：

- candidate selection / API lifting

目标：

- 把 file/path 暴露层带进 Stage 3
- 验证 `sink_not_in_candidate_set` 是否可被最小能力改动打破

### 12.2 对 `SSRF`

优先方向：

- source-side query semantics

目标：

- 让 source 对准真实 request-origin 到 network sink 的路径
- 区分“source 语义错位”与“source 语义缺失”的改进边界

### 12.3 对 `cron-utils`

优先方向：

- source collapse / summary bridge

目标：

- 验证稳定 `source-zero` 是否来自更深层的 source 识别或 summary 缺边

### 12.4 对 `jolokia`

优先方向：

- variance methodology

目标：

- 如果要继续研究，不应再做随意增量重跑
- 应单开方法学实验，明确比较 `single-run` 与 `best-of-n` / `any-hit-in-n`

## 13. 一句话结论

当前 `IRIS` 学习评估的正式总体结论是：

> `IRIS` 在本地已经具备稳定可执行的学习评估基线，但其当前能力画像并不是“统一失效”或“稳定复现官方结果”，而是呈现出按 case family 分流的多断点失败结构；其中 candidate-selection 是真实但非统一主因，`PT` 主要断在 `sink_not_in_candidate_set`，`SSRF` 主要断在 `query_semantics_mismatch`，而部分官方成功 case 还表现出明显的 run-to-run variance。
