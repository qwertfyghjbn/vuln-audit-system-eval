# E1 Checklist: Cron-utils

## 1. 这轮要完成什么

当前已完成：

1. 把 `A original` 固化成 `E1` 归档包
2. 执行 `B oracle candidate` 的一次性 replay
3. 执行 `C oracle summary/path` 的最小异常 bridge replay

当前待做：

- `D oracle slice`

## 2. 固定 run_id

- `run_id = AAE1_CRONUTILS_20260707T023145Z`

## 3. 已选 baseline

- baseline 来源固定为：
  [rerun_3 local_observation/run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_LLMVAR01/official/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/rerun_3/local_observation/run_summary.json:1)

理由：

- `source=0` 稳定
- `sink>0`
- `func_param_sources` 已波动到 `12`，但仍然 `0 results`

## 4. A original 归档检查

确认这些文件已经进入：

- `A_original/analysis/common/candidate_apis.csv`
- `A_original/analysis/common/source_func_param_candidates.csv`
- `A_original/generated_queries/cwe-094wLLM/`
- `A_original/raw_responses/`
- `A_original/results/results.csv`
- `A_original/results/posthoc_results.json`
- `A_original/results/posthoc_stats.json`
- `A_original/run_summary.json`

## 5. `B` 结果检查

确认 `B` 满足以下条件：

- `candidate_injection_mode = no_op_validation`
- replay 前 monitor 集已经存在
- replay 后仍然保持 `llm_sources = 0`
- replay 后仍然保持 `num_vulnerable_paths = 0`

监控集合应固定为：

- `Throwable.getMessage()`
- `IllegalArgumentException(String p0)`
- `IllegalArgumentException(String p0, Throwable p1)`
- `buildConstraintViolationWithTemplate(String p0)`
- `CronParser.parse(String expression)#expression`

## 6. `C` 结果检查

确认 `C` 满足以下条件：

- `MySummaries.qll` 已显式加入：
  `IllegalArgumentException(...)`
  `Throwable.getMessage()`
- 不新增新的 source/sink 物化
- replay 后仍然保持 `num_vulnerable_paths = 0`

如果上述条件成立，则后续不能再把这条线笼统描述为“缺普通 summary”。

## 7. `D` 执行清单

真正进入 `D` 时，按以下顺序执行：

1. 在 `D_oracle_slice/` 中继承 `C` 的 `generated_queries/` 与 `raw_responses/`
2. 显式把 `CronValidator.isValid(String value)#value` 加入 `true entry source`
3. 初始 slice 只纳入以下文件：
   `CronValidator.java`
   `CronParser.java`
   `CronParserField.java`
   `FieldParser.java`
   `Preconditions.java`
   `StringUtils.java`
4. 先做一次小型异常驱动检查，确认能从真实入口打到 `IllegalArgumentException`
5. 若 stack trace 中出现新的项目内文件，只按 stack 增补，不按目录扩张
6. 只重跑 CodeQL，不重跑 LLM
7. 记录：
   `results.csv`
   `results.sarif`
   `run_summary.json`
   `injection_manifest.json`

## 8. `D` 的成功/停止标准

`D` 成功标准：

- 恢复 target-aligned path
- 且可以明确说明真实入口暴露或 caller-side exception slice 是决定性增量

`D` 停止标准：

- 如果 `D` 仍然 `0 paths`，停止这条 family 的 `E1` 内部扩张
- 后续不再继续补 candidate
- 后续不再继续补普通 summary
- 直接分流到 `E2` 或 `DeepAudit`
