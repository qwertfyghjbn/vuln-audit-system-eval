# E1 Cron-utils Runbook

## 1. 作用

这份 runbook 把 `jmrozanec__cron-utils_CVE-2021-41269_9.1.5` 收紧成 `E1 Static-gate Oracle` 的单独执行线。

它的目标不是再验证一次 `candidate gate`，而是尽快回答：

- 这条线是否本质上是 `summary/path modeling` 断点
- `Throwable.getMessage()` 这一异常消息 bridge 一旦进入 `summary/path`，是否能恢复 target-aligned result
- 如果最小异常 bridge 仍然失败，问题是否落在 `true entry / exception slice boundary`

## 2. 当前先验

基于既有正式证据，当前先验已经比较强：

- `source=0` 在多轮 rerun 中稳定存在
- `CronParser.parse(String)#expression` 参数型 source 已存在
- `buildConstraintViolationWithTemplate(String p0)` sink 已存在
- `Throwable.getMessage()` 在候选集中存在
- `B` replay 之后，candidate/materialized 状态仍然无法恢复任何 path
- `C` 已把最小异常消息 bridge 注入 `MySummaries.qll`，结果仍然是 `0 paths`

关键证据：

- [last2 diagnosis matrix](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_last2_diagnosis_matrix.tsv:1)
- [last2 candidate coverage audit](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_last2_candidate_coverage_audit.tsv:1)
- [last2 minimal oracle](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_last2_minimal_target_adjacent_oracle.tsv:1)

## 3. A/B/C/D 策略

### 3.1 `A original`

目标：

- 固定 baseline
- 不再讨论 run-to-run 波动
- 把 `source=0, results=0` 的稳定失败形状正式归档到 `E1`

执行策略：

- 直接复用 [rerun_3](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_LLMVAR01/official/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/rerun_3/local_observation/run_summary.json:1)
- 不做新的全链路重跑

选择 `rerun_3` 的原因：

- 已经证明即使 `num_labelled_func_param_sources = 12`，最终仍是 `0 results`
- 比 `rerun_1/2` 更能说明 “source 参数波动不改变最终失败形状”

### 3.2 `B oracle candidate`

这是一个显式的 `no-op validation`，不是常规意义上的 candidate 扩大。

执行目标：

- 用最小代价再次确认 `candidate gap` 不是主因

执行边界：

- 不新增大范围 candidate
- 不新增与目标无关的 wrapper
- 不改 `summary/path`

只监控以下 target-adjacent 元素是否已经存在：

- `java.lang.Throwable.getMessage()`
- `java.lang.IllegalArgumentException(String p0)`
- `java.lang.IllegalArgumentException(String p0, Throwable p1)`
- `javax.validation.ConstraintValidatorContext.buildConstraintViolationWithTemplate(String p0)`
- `com.cronutils.parser.CronParser.parse(String expression)#expression`

停止规则：

- 如果这些元素已经都存在，则 `B` 立即结束，不再继续做 candidate-oriented 试验
- 直接进入 `C`

### 3.3 `C oracle summary/path`

这是 `cron-utils` 的核心步骤。

最小注入包围绕以下 bridge：

1. `IllegalArgumentException(String p0)`
2. `IllegalArgumentException(String p0, Throwable p1)`
3. `Throwable.getMessage()`
4. `buildConstraintViolationWithTemplate(String p0)`

核心判断：

- 如果 `B` 不成功而 `C` 成功，则可以把这条 family 收口为清晰的 `summary/path modeling` 主例
- 如果 `C` 仍失败，则剩余假设必须收紧到异常 transport 或 caller-side slice，而不能再笼统归因为“少了一个普通 summary”

### 3.4 `D oracle slice`

`D` 现在应当执行，但必须是定向 slice，而不是扩大 repo。

进入 `D` 的前提现在已经满足：

1. `C` 失败
2. 已确认 `Throwable.getMessage` bridge 已进入 `MySummaries.qll`
3. 剩余最强假设已经收紧到 `true entry / exception transport / caller-side boundary`

`D` 的目标不是“多给一些文件看看”，而是把真实入口与异常传播边界显式物化出来。

#### `D` 的核心假设

当前失败不再像：

- 缺 candidate
- 缺一个局部 getter / wrapper summary

而更像：

- `CronValidator.isValid(String value)` 这个真实入口没有被当作 `true entry source`
- `CronParser.parse(...) -> catch (IllegalArgumentException e) -> e.getMessage() -> buildConstraintViolationWithTemplate(...)` 这条异常路径没有在当前 slice 中被充分表达

#### `D` 的 source 策略

`D` 不再只沿用：

- `CronParser.parse(String expression)#expression`

而是显式加入真实入口：

- `com.cronutils.validation.CronValidator.isValid(String value)#value`

这一步在 `D` 中被视为 `oracle slice` 的一部分，而不是新的 candidate 扩大实验。

#### `D` 的最小文件边界

默认只纳入以下文件：

- `com/cronutils/validation/CronValidator.java`
- `com/cronutils/parser/CronParser.java`
- `com/cronutils/parser/CronParserField.java`
- `com/cronutils/parser/FieldParser.java`
- `com/cronutils/utils/Preconditions.java`
- `com/cronutils/utils/StringUtils.java`

如果需要继续扩大，只允许按真实异常链增补，不允许按目录整包扩张。

#### `D` 的预备动作

在真正跑 `D` 前，先做一个很小的异常驱动检查：

1. 构造一个能稳定触发 `IllegalArgumentException` 的 cron 输入
2. 直接从 `CronValidator.isValid(...)` 或 `CronParser.parse(...)` 调用
3. 记录项目内 stack trace
4. 只把 stack 上出现的项目内文件视作可追加 slice 候选

#### `D` 的执行方式

`D` 继承 `C` 的 `MySummaries.qll`，不再重跑 LLM。

只做两类增量：

1. 把 `CronValidator.isValid(String value)#value` 物化为 `true entry source`
2. 把异常路径相关文件组成定向 caller-side slice

执行方式保持和 `C` 一致：

- 手工 query replay
- 只重跑 CodeQL
- 不改 `IRIS` 主代码

#### `D` 的停止规则

- 如果 `D` 恢复 target-aligned path：
  `primary_break_layer = build/slice boundary with true entry exposure`
- 如果 `D` 仍然 `0 paths`：
  停止这条 family 的 `E1` 内部扩张，不再继续补 candidate 或普通 summary，后续直接分流到 `E2` 或 `DeepAudit`

## 4. 当前落地状态

当前已经落地：

- `A_original` 归档
- `B oracle candidate` 的 replay 与归档
- `C oracle summary/path` 的最小异常 bridge replay 与归档

当前尚未执行：

- `D oracle slice`

当前阶段结论：

- `B` 说明 `candidate gate` 不是主因
- `C` 说明问题深于普通局部 summary 缺口
- `D` 的任务是验证：剩余断点是否落在 `true entry / exception slice boundary`

对应证据包：

- [AAE1_CRONUTILS_20260707T023145Z](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_CRONUTILS_20260707T023145Z/run_manifest.json:1)
