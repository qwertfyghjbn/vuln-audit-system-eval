# `cron-utils` 的 `E4` 独立人读报告

## 1. 目的

这份报告汇总 `jmrozanec__cron-utils_CVE-2021-41269_9.1.5` 在 `E4 DeepAudit 信息优势控制实验` 下的当前结果。

这条 family 的 `E4` 不做 vulnerable/fixed pair 差分，而是回答：

- `DeepAudit` 在低信息条件下，能否自己恢复目标异常消息链
- 如果能，这更像 repo-level 自由审计架构优势，还是额外信息优势
- `D2` 与 `D4` 是否还需要继续跑，主要是为了精细拆分信息增益，而不是为了证明系统“能不能命中”

对应 runbook：

- [e4_cronutils_deepaudit_information_control_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e4_cronutils_deepaudit_information_control_runbook.md:1)
- [e4_cronutils_execution_checklist.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e4_cronutils_execution_checklist.md:1)

## 2. 条件定义

| 条件 | 给 `CVE` 描述 | 给真实 `FIX_PATCH.diff` | 给 `target_files` | 目标 |
|---|---|---|---|---|
| `D1` | 否 | 否 | 否 | 观察纯 repo 审计能力 |
| `D2` | 是 | 否 | 否 | 观察高层漏洞 hint 是否足以抬升目标命中 |
| `D4` | 是 | 是 | 是 | 观察最大信息条件是否才带来成功 |

本 family 的共享目标语义固定为：

`CronValidator.isValid(String value)`
-> `CronParser.parse(value)`
-> `IllegalArgumentException`
-> `Throwable.getMessage()`
-> `ConstraintValidatorContext.buildConstraintViolationWithTemplate(String p0)`

## 3. 当前覆盖范围

截至目前：

- `D1` 已完成
- `D2` 尚未运行
- `D4` 尚未运行

当前 run 根目录：

- [AAE4_CRONUTILS_20260708T015906Z](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_CRONUTILS_20260708T015906Z/run_manifest.json:1)
- [experiment_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_CRONUTILS_20260708T015906Z/experiment_matrix.tsv:1)

## 4. `D1` 结果

### 4.1 指标表

| 条件 | Iter | Tool calls | Tokens | Findings | 最显眼输出 |
|---|---:|---:|---:|---:|---|
| `D1` | 33 | 30 | 516100 | 2 | top-1 直接命中 `buildConstraintViolationWithTemplate(e.getMessage())` 的 EL Injection |

核心证据：

- [D1 task_summary.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_CRONUTILS_20260708T015906Z/AAE4_CRONUTILS_D1/task_summary.json:1)
- [D1 task_findings.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_CRONUTILS_20260708T015906Z/AAE4_CRONUTILS_D1/task_findings.json:1)
- [D1 failure_classification.txt](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_CRONUTILS_20260708T015906Z/AAE4_CRONUTILS_D1/failure_classification.txt:1)
- [D1 normalized_output.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_CRONUTILS_20260708T015906Z/AAE4_CRONUTILS_D1/normalized_output.json:1)
- [D1 run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_CRONUTILS_20260708T015906Z/AAE4_CRONUTILS_D1/run_summary.json:1)

### 4.2 语义命中情况

`D1` 已恢复目标链的三个关键锚点：

1. 真实入口：
   [CronValidator.java:21](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/staging/jmrozanec__cron-utils_CVE-2021-41269_9.1.5_D1/repo_bundle/src/main/java/com/cronutils/validation/CronValidator.java:21)
2. 异常消息 bridge：
   [CronParser.java:131](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/staging/jmrozanec__cron-utils_CVE-2021-41269_9.1.5_D1/repo_bundle/src/main/java/com/cronutils/parser/CronParser.java:131)
3. 模板 sink：
   [CronValidator.java:33](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/staging/jmrozanec__cron-utils_CVE-2021-41269_9.1.5_D1/repo_bundle/src/main/java/com/cronutils/validation/CronValidator.java:33)

同时 supporting finding 还补足了更上游的异常消息构造点：

- [FieldParser.java:67](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/staging/jmrozanec__cron-utils_CVE-2021-41269_9.1.5_D1/repo_bundle/src/main/java/com/cronutils/parser/FieldParser.java:67)
- [FieldParser.java:78](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/staging/jmrozanec__cron-utils_CVE-2021-41269_9.1.5_D1/repo_bundle/src/main/java/com/cronutils/parser/FieldParser.java:78)

## 5. 当前判断

### 5.1 `D1` 已经足够回答“能不能命中”

`D1` 的结果很强：

- 没有 `CVE hint`
- 没有 `diff`
- 没有 `target_files`

在这种条件下，`DeepAudit` 仍然直接恢复了：

- `CronValidator.isValid(value)` 真实入口
- `e.getMessage()` 异常消息 bridge
- `buildConstraintViolationWithTemplate(...)` 模板 sink

因此对 `cron-utils` 这条 family，当前已经可以成立一个较强结论：

> `DeepAudit` 的 repo-level 自由审计能力本身就足以恢复目标异常消息链，不需要依赖高信息提示才看见目标漏洞。

### 5.2 这更像架构优势，不像信息优势

因为 `D1` 就成功，所以：

- 当前不能把这条成功解释成 `CVE hint` 优势
- 也不能把它解释成 `diff/target_files` 优势

更合理的解释是：

- `cron-utils` 这条 family 上，`DeepAudit` 的自由 repo 审计表示已经明显强于 `IRIS-style static-gated workflow`
- 它能在纯 repo bundle 下自然组织出 `cron expression -> exception message -> template sink` 这条链

这与 `E1/E2` 的已有证据是相容的：

- `E1` 说明 static-gated workflow 即使补到 `D_oracle_slice` 仍然 `0 paths`
- `E2` 说明一旦给 LLM 受控 target-context，它能恢复目标链
- `E4 D1` 则进一步说明：`DeepAudit` 甚至不需要显式 target-context，就已能在 repo-level 自由审计下恢复这条链

## 6. `D2/D4` 还值不值得跑

从“是否证明系统具备目标命中能力”这个角度看，`D2/D4` 已经不是必需项。

但从“信息优势还能带来什么额外增益”这个角度看，`D2/D4` 仍有价值：

- `D2` 可以验证 `CVE hint` 是否会让 finding 更快、更集中，或者反而带来泛化污染
- `D4` 可以验证真实修复 diff 和 `target_files` 是否会把注意力进一步收敛到 `CronParser.java` 这一真实修复点

因此现在对 `D2/D4` 的定位应当调整为：

- 不是“补救性 run”
- 而是“增益拆分 run”

## 7. 当前结论

截至 `D1`：

1. `DeepAudit` 在 `cron-utils` 上已经表现出明确的架构优势信号。
2. 这个优势在 `D1` 低信息条件下就存在，因此不能归因为额外信息注入。
3. `D2/D4` 若继续执行，主要是为了量化信息增益，而不是为了证明“只有高信息条件才成功”。

这与 `SSRF-3432 pair` 的 `E4` 形成了很好的对照：

- `SSRF-3432 pair` 更像“自由审计能找到风险，但不自然具备差分解释”
- `cron-utils` 则更像“自由审计本身就足以恢复目标异常消息链”
