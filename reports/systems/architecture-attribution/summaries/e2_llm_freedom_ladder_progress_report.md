# E2 LLM Freedom Ladder 进展报告

## 1. 作用

这份文档记录 `Architecture Attribution Experiment` 中 `E2 LLM Freedom Ladder` 已完成的实验、当前可成立的结论，以及后续待补部分。

当前这份报告先收紧到：

- `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`

后续如果 `E2` 扩展到其它 family，可按同一格式继续并入本文件，或在范围明显扩大后再拆分。

## 2. 当前覆盖范围

### 2.1 当前目标

`cron-utils` 的 `E2` 固定为五档：

1. `M1_original`
2. `M2_candidate_source_window`
3. `M3_target_context_constrained`
4. `M4_free_auditor`
5. `M5_agentic_auditor`

### 2.2 当前状态

截至目前：

- `M1` 已完成归档
- `M2` 已完成归档
- `M3` 已完成归档
- `M4` 已完成归档
- `M5` 已完成归档

当前已完成归档的 `E2` mode：

- `M1_original`
- `M2_candidate_source_window`
- `M3_target_context_constrained`
- `M4_free_auditor`
- `M5_agentic_auditor`

### 2.3 当前证据

- [E2 runbook](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e2_cronutils_five_level_runbook.md:1)
- [E2 checklist](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e2_cronutils_execution_checklist.md:1)
- [E1 cron-utils runbook](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e1_cronutils_runbook.md:1)
- [E1 进展报告 `cron-utils` 小节](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e1_static_gate_oracle_progress_report.md:251)
- [E2 run_manifest.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/run_manifest.json:1)
- [M1 run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M1_original/run_summary.json:1)

## 3. 共享判定规则

对这份 `E2` 报告，只有同时满足以下 3 条，才记为“恢复 target-aligned reasoning”：

1. 明确把 `value` 或等价 cron 表达式输入识别为外部可控输入。
2. 明确指出异常消息字符串经 `getMessage()` 进入 `buildConstraintViolationWithTemplate(...)`。
3. 明确把这条链解释成 `cwe-094wLLM / SpelInjection` 方向风险。

以下情况不记为成功：

- 只说 `CronParser.parse` 会抛异常
- 只说 `CronValidator.isValid(...)` 会返回 `false`
- 只说 `javax.validation` 或模板接口“可能有风险”
- 只给出与目标链无关的 off-target finding

## 4. 当前总表

| mode | status | output_format | target_alignment | 当前说明 |
|---|---|---|---|---|
| `M1_original` | completed | structured_labels | false | Stage 3 只标出 `1 sink + 1 taint-propagator`，Stage 4 标出 `6` 个 source function parameters，但最终仍 `0 alarms / 0 paths / recall=false`。 |
| `M2_candidate_source_window` | completed | structured_labels | false | 注入最小 `source-window` 后，Stage 3 变成 `0 source + 0 sink + 9 taint-propagators`，Stage 4 收缩到 `4` 个 source function parameters，但最终仍 `0 alarms / 0 paths / recall=false`。 |
| `M3_target_context_constrained` | completed | constrained_json | true | 加入 `target-context memo` 后，模型首次明确恢复 `CronValidator -> getMessage -> buildConstraintViolationWithTemplate` 目标链。 |
| `M4_free_auditor` | completed | freeform_audit | true | 保持与 `M3` 同一上下文，只去掉 JSON 约束，模型仍能稳定写出完整漏洞因果链。 |
| `M5_agentic_auditor` | completed | freeform_agentic | true | 受控 agentic 检索阶段请求 `0` 个额外文件，说明 `M3/M4` 的起始 bundle 已足够恢复这条 family 的目标推理。 |

## 5. 方法边界

当前需要显式记录：

1. 这份报告只接收写入 `artifacts/architecture_attribution/E2/` 的新证据。
2. `E1` 的已有证据只能作为前置背景，不可直接当作 `E2` 结果。
3. 如果某个 mode 只完成了本地失败尝试，但没有形成完整 `E2` 归档包，则不能把它记为“completed”。
4. 如果某个 mode 因环境阻断中止，必须把阻断类型写清楚，不可误记成模型或 workflow 本体失败。

## 6. `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`

### 6.1 当前目标语义链

本 family 的共享目标语义固定为：

`CronValidator.isValid(String value)#value`
-> `CronParser.parse(value)`
-> `IllegalArgumentException`
-> `Throwable.getMessage()`
-> `ConstraintValidatorContext.buildConstraintViolationWithTemplate(String p0)`

### 6.2 `M1_original`

当前状态：

- `completed`

当前结果：

1. 本次 `M1` 采用与既有 `IRIS` baseline 同一条全链路执行骨架：
   `src/iris.py --query cwe-094wLLM --llm gpt-4 jmrozanec__cron-utils_CVE-2021-41269_9.1.5`
2. 统计结果为：
   `num_external_api_calls = 9812`
   `num_api_candidates = 384`
   `num_labelled_sources = 0`
   `num_labelled_sinks = 1`
   `num_labelled_taint_propagators = 1`
   `num_labelled_func_param_sources = 6`
   `num_results = 0`
   `num_paths = 0`
   `recall_method = false`
3. 唯一保留下来的 sink 仍是：
   `buildConstraintViolationWithTemplate(String p0)`
4. `Stage 4` 仍然能看到：
   `CronParser.parse(String expression)`
   `CronParserField.parse(String expression)`
   `FieldParser.parse(String expression)`
   但没有恢复：
   `CronValidator.isValid(String value)#value`
5. `Throwable.getMessage()` 仍然没有进入可用 bridge，`target-aligned reasoning` 没有恢复。

对应证据：

- [M1 run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M1_original/run_summary.json:1)
- [M1 normalized_output.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M1_original/normalized_output.json:1)
- [M1 final_results.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M1_original/results/final_results.json:1)
- [M1 stdout.log](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M1_original/logs/stdout.log:1)

当前结论：

1. `M1` 没有恢复 target-aligned reasoning。
2. 这次失败比 `rerun_3` 更“瘦”：
   `rerun_3` 仍有 `2 sinks + 10 taint propagators`，而本次 `M1` 只剩 `1 sink + 1 taint propagator`。
3. 但失败形状的核心没变：
   仍然 `source API = 0`
   仍然没有 `Throwable.getMessage()` bridge
   仍然 `0 results / 0 paths`
4. 因此 `M1` 继续支持：
   原始 structured-label 表示本身就足以把 `cron-utils` 压回 `source-zero / no-path` 形状。

### 6.3 `M2_candidate_source_window`

当前状态：

- `completed`

当前结果：

1. 这次 `M2` 保持 `M1` 的原始 candidate 集合不变，只新增一份最小 `source-window`，并通过本地 `IRIS` prompt hook 追加到 `Stage 3` 和 `Stage 4` 的 user prompt。
2. 统计结果为：
   `num_external_api_calls = 9812`
   `num_api_candidates = 384`
   `num_labelled_sources = 0`
   `num_labelled_sinks = 0`
   `num_labelled_taint_propagators = 9`
   `num_labelled_func_param_sources = 4`
   `num_results = 0`
   `num_paths = 0`
   `recall_method = false`
3. `Stage 3` 的分布明显改变：
   不再保留 `buildConstraintViolationWithTemplate(String p0)` sink，
   而是转向标注 `IllegalArgumentException(...)`、`IllegalStateException(...)`、`NullPointerException(...)` 以及若干 `java.io` / `CharSequence` propagator。
4. `Stage 4` 仍然保留：
   `CronParser.parse(String expression)`
   `CronParserField.parse(String expression)`
   `FieldParser.parse(String expression)`
   并额外保留 `CronConverter.using(String cronExpression)`；
   但仍未恢复 `CronValidator.isValid(String value)#value`。
5. `Throwable.getMessage()` 仍未进入可用 bridge，最终仍然没有生成 target path。

对应证据：

- [M2 run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M2_candidate_source_window/run_summary.json:1)
- [M2 normalized_output.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M2_candidate_source_window/normalized_output.json:1)
- [M2 final_results.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M2_candidate_source_window/results/final_results.json:1)
- [M2 Stage 3 raw_user_prompt_0.txt](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M2_candidate_source_window/analysis/logs/label_apis/raw_user_prompt_0.txt:1)
- [M2 Stage 4 raw_user_prompt_0.txt](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M2_candidate_source_window/analysis/logs/label_func_params/raw_user_prompt_0.txt:1)

当前结论：

1. `M2` 仍然没有恢复 target-aligned reasoning。
2. 但它不是简单复现 `M1`：
   source-window 的确改变了 `Stage 3` 的判断重心，把模型推向“异常构造器 / 泛化 propagator”。
3. 这种变化没有落到真正需要的 bridge 上：
   仍然没有 `Throwable.getMessage()`
   仍然没有 template sink
   仍然 `0 results / 0 paths`
4. 因此 `M2` 当前支持的判断是：
   只补最小局部代码窗口，足以改变 structured-label 输出分布，但不足以恢复 `cron-utils` 这条 family 的 target path。

### 6.4 `M3_target_context_constrained`

当前状态：

- `completed`

当前结果：

1. `M3` 在 `M2` 的最小 `source-window` 基础上新增显式 `target-context memo`，并把输出约束成固定 JSON。
2. 模型在一次成功解析的 JSON 输出中，明确给出：
   `CronValidator.isValid(String value)` 作为 true entry source，
   `Throwable.getMessage()` 作为 message bridge，
   `buildConstraintViolationWithTemplate(String p0)` 作为 sink。
3. `target_path_hypothesis.is_plausible = true`，并且显式解释：
   这不只是普通 parse failure，
   而是 attacker-controlled error message 进入 template evaluation context 的 `CWE-094` 风险。

对应证据：

- [M3 run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M3_target_context_constrained/run_summary.json:1)
- [M3 normalized_output.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M3_target_context_constrained/normalized_output.json:1)
- [M3 parsed_output.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M3_target_context_constrained/llm_run/parsed_output.json:1)

当前结论：

1. `M3` 首次恢复了 target-aligned reasoning。
2. 这说明只补最小 `source-window` 还不够，但一旦显式加入 `target-context memo`，结构化输出本身并不会阻止模型恢复目标链。
3. 相比 `M2`，真正起作用的变化不是再多一点局部代码，而是把模型明确锚定到：
   `CronValidator -> CronParser -> IllegalArgumentException -> getMessage -> buildConstraintViolationWithTemplate`
   这条目标链。

### 6.5 `M4_free_auditor`

当前状态：

- `completed`

当前结果：

1. `M4` 与 `M3` 使用同一批上下文，只移除了 JSON schema 约束，改为自由文本审计说明。
2. 模型明确写出完整因果链，并显式说明：
   `Throwable.getMessage()` 是把 attacker-controlled exception message 带入 template sink 的 conduit。
3. 模型同样明确区分：
   这不是普通 validation failure，
   而是把用户输入带入可解释模板上下文的 `CWE-094` 风险。

对应证据：

- [M4 run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M4_free_auditor/run_summary.json:1)
- [M4 response.txt](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M4_free_auditor/llm_run/response.txt:1)

当前结论：

1. `M4` 保持了 `M3` 的 target alignment。
2. 因此对 `cron-utils` 这条 family 来说，到了 `M3` 以后，去掉结构化 JSON 约束并不是恢复目标链的必要条件，只是不会破坏已经恢复的解释。

### 6.6 `M5_agentic_auditor`

当前状态：

- `completed`

当前结果：

1. `M5` 采用了一个受控的两段式 agentic loop：
   `phase1` 先决定是否需要额外文件，
   `phase2` 再生成最终审计说明。
2. `phase1` 明确返回：
   `need_more_context = false`
   `requested_files = []`
3. `phase2` 在没有任何新增文件的情况下，仍然给出与 `M4` 一致的 target-aligned 审计链。
4. 因此本次 `M5` 的 `opened_files = []`，`new_files_beyond_M4 = 0`。

对应证据：

- [M5 run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M5_agentic_auditor/run_summary.json:1)
- [M5 tool_trace.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M5_agentic_auditor/tool_trace.json:1)
- [M5 phase1 parsed_output.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M5_agentic_auditor/phase1_run/parsed_output.json:1)
- [M5 phase2 response.txt](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_CRONUTILS_20260707T073244Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/M5_agentic_auditor/phase2_run/response.txt:1)

当前结论：

1. `M5` 没有超过 `M4`，因为它根本不需要打开新文件。
2. 这进一步支持：
   对 `cron-utils` 来说，一旦 `target-context memo` 把模型锚回目标链，额外 repo traversal 已不是主要增益来源。
3. 因而这条 family 更像：
   `representation / task framing limit`
   而不是 `repo context volume limit`
   或 `must-have agentic retrieval limit`。

## 7. 后续待补

五档都已完成后，当前可以先收敛出 `cron-utils` 的统一归因判断：

1. `M1` 与 `M2` 失败，说明只在原始 structured-label workflow 内补最小局部上下文，不足以恢复目标链。
2. `M3` 开始成功，说明主断点不是 repo 里“没有足够代码可看”，而是模型在原始 task framing 下没有被锚到正确的目标链。
3. `M4` 与 `M5` 没有继续显著抬升，说明一旦 `target-context memo` 把目标链钉住，自由文本和有限 agentic retrieval 都不是决定性新增因素。
4. 因此 `cron-utils` 当前更支持：
   主因是 `workflow representation / target framing limit`
   而不是继续扩大 `E1` 静态补丁、
   也不是必须依赖更大 repo 探索。
