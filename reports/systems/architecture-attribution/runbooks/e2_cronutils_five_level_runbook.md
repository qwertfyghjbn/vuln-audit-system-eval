# E2 Cron-utils 五档 Runbook

## 1. 作用

这份 runbook 用于执行 `Architecture Attribution Experiment` 中 `jmrozanec__cron-utils_CVE-2021-41269_9.1.5` 的 `E2 LLM Freedom Ladder`。

它回答的问题不是：

- `IRIS-style static-gated workflow` 还能不能继续补一个 candidate
- 还能不能继续补一个普通 summary
- 还能不能继续扩大 caller-side slice

它真正要回答的是：

- 当 `E1` 已经证明不应继续扩大静态补丁时，沿着 `LLM freedom` 逐档放宽约束，是否能恢复这条 family 的 `target-aligned reasoning`
- `cron-utils` 的主断点，到底更像 `workflow representation limit`，还是即使放开表示形式后也仍然难以恢复

## 2. 为什么现在启动

`cron-utils` 的 `E1` 已经给出足够强的停止信号：

1. `B_oracle_candidate` 没有改变失败形状，说明 `candidate gate` 不是主因。
2. `C_oracle_summary_path` 显式注入 `IllegalArgumentException(...) -> Throwable.getMessage()` 后仍然 `0 paths`，说明问题深于局部 summary 缺口。
3. `D_oracle_slice` 把 `CronValidator.isValid(String value)#value` 暴露为真实入口 source，并把 slice 收紧到异常链相关文件后仍然 `0 paths`，说明继续扩大 `E1` 的边际收益很低。

对应证据：

- [E1 cron-utils runbook](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e1_cronutils_runbook.md:1)
- [E1 进展报告 `cron-utils` 小节](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e1_static_gate_oracle_progress_report.md:251)
- [AAE1_CRONUTILS_20260707T023145Z run_manifest](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_CRONUTILS_20260707T023145Z/run_manifest.json:1)

因此这条 family 的下一步不再是扩大 `E1`，而是切到 `E2`，直接测试：

- LLM 是否只是被 `IRIS-style static-gated workflow` 的表示边界卡住
- 还是在更自由的表示下也仍然不能稳定恢复这条异常消息链

## 3. 共享目标语义

五档实验都围绕同一条 `target-aligned` 语义链，不允许每档各自追不同的泛化风险：

`CronValidator.isValid(String value)#value`
-> `CronParser.parse(value)`
-> `IllegalArgumentException`
-> `Throwable.getMessage()`
-> `ConstraintValidatorContext.buildConstraintViolationWithTemplate(String p0)`

对本 runbook，只有当输出至少满足以下 3 条时，才算“恢复 target-aligned reasoning”：

1. 明确把 `value` 或等价的 cron 表达式输入识别为外部可控输入。
2. 明确指出异常消息字符串通过 `getMessage()` 进入 `buildConstraintViolationWithTemplate(...)`。
3. 明确把这条链解释成 `cwe-094wLLM / SpelInjection` 方向的风险，而不是泛泛的 “parse 失败会报错”。

如果只说：

- `CronParser.parse` 会抛异常
- `CronValidator` 会返回 `false`
- `javax.validation` 可能有风险

但没有把异常消息到 template argument 的传播说清楚，则不算成功。

## 4. 五档定义

`cron-utils` 这条 family 明确采用五档，而不是总规划中的四档简化版。

原因很具体：

- 这条 case 的核心疑点不是 “LLM 完全没看到 target API”
- 而是 “LLM 看到 API 之后，是否仍然因为表示格式过窄而恢复不了异常消息链”

因此需要把 `M2` 单独保留出来，专门隔离：

- “给一点 source-window 是否就够”
- 和
- “必须给到更强 target-context 才够”

### 4.1 `M1 original`

LLM 看到：

- 原始 `IRIS` Stage 3 候选 API / source func param 候选
- 原始 package summary 与方法签名

LLM 能做：

- 只输出 `source / sink / taint-propagator` 结构化标签

不允许：

- 自由写漏洞路径
- 添加 caller-side 解释文字
- 额外读 repo 文件

这档用于复现：原始 static-gated 表示下，`cron-utils` 为什么稳定塌缩到 `source=0`。

### 4.2 `M2 candidate + source window`

LLM 看到：

- `M1` 的全部材料
- 一组极小 `source-window`，只覆盖目标链的局部代码窗口

默认窗口只允许来自以下文件：

- `CronValidator.java`
- `CronParser.java`
- `CronParserField.java`
- `FieldParser.java`

窗口必须至少覆盖：

- `CronValidator.isValid(String value)`
- `CronParser.parse(String expression)`
- `catch (IllegalArgumentException e)`
- `buildConstraintViolationWithTemplate(e.getMessage())` 或等价片段

LLM 能做：

- 仍然只输出 `source / sink / taint-propagator` 结构化标签

不允许：

- 自由写审计结论
- 读额外文件
- 跳到 repo 级探索

这档用于回答：

- 只补最小局部上下文后，LLM 是否就能把 `CronValidator.isValid(String value)#value`、`Throwable.getMessage()`、`buildConstraintViolationWithTemplate(String p0)` 串起来

### 4.3 `M3 target-context constrained`

LLM 看到：

- `M2` 的全部材料
- 一份显式 `target-context memo`

`target-context memo` 允许包含：

- family ID 与 query ID：`jmrozanec__cron-utils_CVE-2021-41269_9.1.5` / `cwe-094wLLM`
- 目标关注链：`CronValidator -> CronParser -> IllegalArgumentException -> getMessage -> buildConstraintViolationWithTemplate`
- `E1` 已知事实：
  `candidate` 已充分
  `Throwable.getMessage()` 候选存在
  `E1` 不再继续扩大

`target-context memo` 不允许包含：

- `ground_truth.json`
- 标准答案文本
- “正确 source/sink 就是 X/Y”的最终断言
- `E1 C/D` 的结论性语言，例如“已经证明真正主因是 exception transport”

LLM 能做：

- 对 source / sink / path 合理性作出结构化判断
- 输出固定 JSON 结论，而不是 IRIS 原始标签列表

建议 JSON 字段：

- `source_candidates`
- `sink_candidates`
- `bridge_nodes`
- `target_path_hypothesis`
- `confidence`
- `why_not_just_parse_error`

这档用于回答：

- 当 LLM 被明确拉回目标链，但仍保留结构化输出约束时，是否已经足够恢复 target reasoning

### 4.4 `M4 free auditor`

LLM 看到：

- 与 `M3` 相同的文件与上下文

LLM 能做：

- 不再输出 `source/sink/taint-propagator` 标签
- 直接自由描述漏洞路径、关键证据和风险解释

固定要求：

- 必须写出一条完整因果链
- 必须说明 `getMessage()` 在链中的作用
- 必须解释为什么这不是普通的 validation failure，而是 query 目标相关风险

不允许：

- 读 repo 以外新文件
- 引入 patch、diff、fixed side 或官方答案

这档用于回答：

- 如果去掉结构化标签格式，只保留同样信息量，LLM 是否已经能恢复 target-aligned explanation

### 4.5 `M5 agentic auditor`

LLM 看到：

- 与 `M4` 相同的起始 bundle
- 允许在同一份 clean repo / curated subset 内继续检索、追调用链、打开必要文件

允许读取的默认范围：

- `D_oracle_slice` 已确认相关的异常链文件
- 为解释调用链所必需的直接相邻文件

不允许：

- 读 `ground_truth.json`
- 读任何 answer-bearing README
- 读 `E1` 归档里的结论性摘要再复述
- 引入 patch / diff / DeepAudit 结果

必须额外记录：

- `tool_call_count`
- `opened_files`
- `context_volume`
- `new_files_beyond_M4`

这档用于回答：

- 如果 `M4` 仍失败，repo 内主动探索是否能恢复 target reasoning
- 如果 `M5` 成功但 `M4` 失败，成功是否主要来自额外上下文与调用链追踪能力

## 5. 统一输入边界

### 5.1 冻结项

五档都必须冻结：

- 同一 `Experiment-side Configuration`
- 同一 family
- 同一 clean input 基线
- 不引入 `patch / diff / fixed-side` 信息
- 不改 query 目标

### 5.2 可变项

五档唯一允许变化的是：

- LLM 可见上下文的组织方式
- LLM 是否受结构化标签输出约束
- LLM 是否允许主动检索更多 repo 上下文

不允许把以下内容混入 `E2`：

- 新的 `E1` candidate 注回
- 新的 `MySummaries.qll` 手工补丁
- 新的 `true entry source` 物化
- `DeepAudit` 风格的外部高信息提示

## 6. 输出与判定

### 6.1 每档至少记录

- `mode_id`
- `model_source`
- `input_bundle`
- `output_format`
- `target_alignment`
- `mentions_true_entry`
- `mentions_exception_message_bridge`
- `mentions_template_sink`
- `explains_cwe_094_semantics`
- `off_target_findings`
- `cost_tokens`
- `wall_time_seconds`
- `tool_call_count`
- `context_volume`

### 6.2 `M1/M2` 额外记录

- `llm_sources`
- `llm_sinks`
- `llm_taint_propagators`
- `contains_CronValidator_value_source`
- `contains_getMessage_bridge`
- `contains_buildConstraintViolation_sink`

### 6.3 `M3/M4/M5` 额外记录

- `path_explanation_quality`
- `bridge_explanation_quality`
- `why_not_parse_error_quality`
- `freeform_target_alignment`

## 7. 结果解释规则

五档跑完后，按以下顺序解释：

1. 如果 `M1` 失败、`M2` 成功：
   主断点更像 `local context omission`，而不是更深层的自由度问题。
2. 如果 `M2` 失败、`M3` 成功：
   主断点更像 `target-context representation`，即 LLM 需要被显式拉回目标链。
3. 如果 `M3` 失败、`M4` 成功：
   主断点更像 `structured label format`，而不是模型不会做这条推理。
4. 如果 `M4` 失败、`M5` 成功：
   主断点更像 `repo exploration / context acquisition`，需要 agentic 搜索能力。
5. 如果 `M5` 仍失败：
   当前不能把这条 family 的失败简单归因为 `IRIS-style` 静态 gate；更可能是这条 target 本身对当前模型与任务表达都不稳定。

## 8. 运行顺序与 stop rule

运行顺序固定为：

1. `M1`
2. `M2`
3. `M3`
4. `M4`
5. `M5`

这条 family 不建议在 `M3` 或 `M4` 成功后提前停止。

原因：

- `cron-utils` 的核心问题正是要拆开 `context`、`format`、`agentic retrieval` 三者的贡献
- 如果 `M4` 成功但不跑 `M5`，就无法判断 agentic 能力是否只是重复 `M4`
- 如果 `M3` 成功但不跑 `M4`，就无法判断结构化输出约束是否仍然在压制更稳定的表达

唯一允许的提前终止条件是：

- 某档因为环境原因完全不可执行
- 且同档问题重复出现三次以上

否则应完整跑满五档。

## 9. 证据落点

新证据统一写入：

```text
artifacts/architecture_attribution/E2/<run_id>/
  run_manifest.json
  family_matrix.tsv
  jmrozanec__cron-utils_CVE-2021-41269_9.1.5/
    M1_original/
    M2_candidate_source_window/
    M3_target_context_constrained/
    M4_free_auditor/
    M5_agentic_auditor/
```

每档至少保存：

```text
<mode>/
  input_contract.json
  prompt_contract.md
  context_bundle/
  stdout.log
  stderr.log
  normalized_output.json
  run_summary.json
```

`M5` 额外保存：

```text
tool_trace.json
opened_files.txt
```

## 10. 与其他实验线的关系

这份 runbook 只负责：

- `cron-utils` 的 `E2` 五档自由度阶梯

它不负责：

- 回头继续扩大 `E1`
- 直接跑 `DeepAudit`
- 把结果写回 `reports/systems/iris/`
- 改写总规划里其他 family 的默认矩阵

如果 `cron-utils E2` 成功恢复 target reasoning，再回头更新：

- `reports/systems/architecture-attribution/summaries/`
- 必要时再决定是否把同样五档结构推广到其它 family
