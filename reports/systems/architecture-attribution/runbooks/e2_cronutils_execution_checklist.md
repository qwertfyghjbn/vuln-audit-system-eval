# E2 Cron-utils Execution Checklist

## 1. 这轮要完成什么

本清单服务于：

- [e2_cronutils_five_level_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e2_cronutils_five_level_runbook.md:1)

当前目标不是继续扩张 `E1`，而是按顺序完整执行：

1. `M1_original`
2. `M2_candidate_source_window`
3. `M3_target_context_constrained`
4. `M4_free_auditor`
5. `M5_agentic_auditor`

默认要求：

- 五档全部跑完
- 不因为中途某档“看起来已经差不多成功”就提前停
- 不把 `E1` 的手工静态补丁混入 `E2`

## 2. 固定 run_id

执行前先固定：

- `run_id = AAE2_CRONUTILS_<UTC timestamp>`

后续所有产物都必须落到：

- `artifacts/architecture_attribution/E2/<run_id>/`

## 3. 共享前置检查

执行 `M1-5` 之前，先确认以下条件全部成立：

- `family_id` 固定为：
  `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`
- `query_id` 固定为：
  `cwe-094wLLM`
- 共享目标语义链固定为：
  `CronValidator.isValid(String value)#value`
  `CronParser.parse(value)`
  `IllegalArgumentException`
  `Throwable.getMessage()`
  `buildConstraintViolationWithTemplate(String p0)`
- 不读取：
  `ground_truth.json`
  answer-bearing `README`
  `E1` 归档中的结论性摘要
- 不注入：
  新的 `candidate`
  新的 `MySummaries.qll`
  新的 `true entry source`
  `patch / diff / fixed-side` 信息
- 五档使用同一 `Experiment-side Configuration`
- 五档使用同一 clean input 基线

## 4. 共享成功判定

只有同时满足以下 3 条，才记为“恢复 target-aligned reasoning”：

1. 明确识别 `value` 或等价 cron 表达式输入是外部可控输入。
2. 明确指出异常消息字符串经 `getMessage()` 进入 `buildConstraintViolationWithTemplate(...)`。
3. 明确把这条链解释成 `cwe-094wLLM / SpelInjection` 方向风险。

以下情况都不算成功：

- 只说 `CronParser.parse` 会抛异常
- 只说 `CronValidator.isValid` 会返回 `false`
- 只说 `javax.validation` 或模板接口“可能有风险”
- 只报与目标链无关的 off-target finding

## 5. `M1` 执行清单

确认 `M1` 满足：

- 输入只包含原始 `IRIS` Stage 3 候选 API / source func param 候选
- 输入包含原始 package summary 与方法签名
- 输出格式仍为 `source / sink / taint-propagator` 结构化标签
- 没有自由文本漏洞路径说明
- 没有额外 repo 文件读取

执行后记录：

- `llm_sources`
- `llm_sinks`
- `llm_taint_propagators`
- `contains_CronValidator_value_source`
- `contains_getMessage_bridge`
- `contains_buildConstraintViolation_sink`
- `target_alignment`

关键检查：

- 是否再次复现 `source=0` 型塌缩
- 是否仍然看不到 `CronValidator.isValid(String value)#value`

## 6. `M2` 执行清单

确认 `M2` 只比 `M1` 多出最小 `source-window`：

- `CronValidator.java`
- `CronParser.java`
- `CronParserField.java`
- `FieldParser.java`

窗口必须覆盖：

- `CronValidator.isValid(String value)`
- `CronParser.parse(String expression)`
- `catch (IllegalArgumentException e)`
- `buildConstraintViolationWithTemplate(e.getMessage())` 或等价片段

确认 `M2` 仍然：

- 只输出结构化标签
- 不自由写审计结论
- 不读额外文件
- 不跳到 repo 级探索

执行后记录：

- `llm_sources`
- `llm_sinks`
- `llm_taint_propagators`
- `contains_CronValidator_value_source`
- `contains_getMessage_bridge`
- `contains_buildConstraintViolation_sink`
- `target_alignment`

关键检查：

- 最小局部代码窗口是否已足够让 LLM 串起目标链

## 7. `M3` 执行清单

确认 `M3` 在 `M2` 基础上只新增 `target-context memo`。

`target-context memo` 允许：

- `family_id`
- `query_id`
- 目标关注链
- `E1` 的非结论性事实：
  `candidate` 已充分
  `Throwable.getMessage()` 候选存在
  `E1` 不再继续扩大

`target-context memo` 禁止：

- `ground_truth.json`
- 标准答案文本
- “正确 source/sink 就是 X/Y”
- “已经证明真正主因是 exception transport” 这类结论性话术

确认 `M3` 输出：

- 固定 JSON 结论
- 不是 IRIS 原始标签列表

建议 JSON 字段是否齐全：

- `source_candidates`
- `sink_candidates`
- `bridge_nodes`
- `target_path_hypothesis`
- `confidence`
- `why_not_just_parse_error`

执行后记录：

- `path_explanation_quality`
- `bridge_explanation_quality`
- `why_not_parse_error_quality`
- `freeform_target_alignment`

关键检查：

- 是否因为 `target-context` 被显式拉回目标链

## 8. `M4` 执行清单

确认 `M4` 与 `M3` 使用同样文件与上下文。

确认 `M4` 变化只在输出格式：

- 不再输出 `source/sink/taint-propagator`
- 改为自由描述漏洞路径、关键证据、风险解释

确认 `M4` 输出中必须出现：

- 一条完整因果链
- `getMessage()` 在链中的作用
- 为什么这不是普通 validation failure，而是 query 目标相关风险

确认 `M4` 仍然不允许：

- 读 repo 以外新文件
- 引入 `patch / diff / fixed-side`
- 引入官方答案

执行后记录：

- `path_explanation_quality`
- `bridge_explanation_quality`
- `why_not_parse_error_quality`
- `freeform_target_alignment`
- `off_target_findings`

关键检查：

- 如果 `M3` 失败而 `M4` 成功，是否能明确归因为结构化标签格式压制

## 9. `M5` 执行清单

确认 `M5` 起始 bundle 与 `M4` 相同。

确认 `M5` 只新增：

- repo 内检索
- 调用链追踪
- 打开必要文件

默认允许读取：

- `D_oracle_slice` 已确认相关的异常链文件
- 为解释调用链所必需的直接相邻文件

确认 `M5` 仍然禁止：

- 读 `ground_truth.json`
- 读 answer-bearing `README`
- 读 `E1` 归档结论性摘要再复述
- 引入 `patch / diff / DeepAudit`

执行后必须额外保存：

- `tool_call_count`
- `opened_files`
- `context_volume`
- `new_files_beyond_M4`
- `tool_trace.json`
- `opened_files.txt`

关键检查：

- 如果 `M4` 失败而 `M5` 成功，成功是否主要来自额外文件与调用链追踪

## 10. 每档落盘检查

`M1-5` 每档至少检查以下文件齐全：

- `input_contract.json`
- `prompt_contract.md`
- `context_bundle/`
- `stdout.log`
- `stderr.log`
- `normalized_output.json`
- `run_summary.json`

`M5` 额外检查：

- `tool_trace.json`
- `opened_files.txt`

## 11. 总表回填检查

五档全部结束后，回填：

- `run_manifest.json`
- `family_matrix.tsv`

至少确认以下字段完整：

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

## 12. 最终解释检查

五档跑完后，按以下顺序收口，不要跳步：

1. `M1` 失败、`M2` 成功：
   归因优先写成 `local context omission`
2. `M2` 失败、`M3` 成功：
   归因优先写成 `target-context representation`
3. `M3` 失败、`M4` 成功：
   归因优先写成 `structured label format`
4. `M4` 失败、`M5` 成功：
   归因优先写成 `repo exploration / context acquisition`
5. `M5` 仍失败：
   不要再写成“只要放开 `IRIS-style` 静态 gate 就自然恢复”，而应收紧到：
   这条 target 对当前模型与任务表达仍不稳定

## 13. 停止规则

默认停止规则只有一个：

- 五档全部完成

唯一允许提前终止的情况：

- 某一档因为环境原因完全不可执行
- 且同档阻塞重复出现三次以上

除此之外，不因“看起来已经有结论”而中途停跑。
