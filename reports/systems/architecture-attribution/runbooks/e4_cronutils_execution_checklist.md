# E4 Cron-utils Execution Checklist

## 1. 这轮要完成什么

本清单服务于：

- [e4_cronutils_deepaudit_information_control_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e4_cronutils_deepaudit_information_control_runbook.md:1)

当前目标是按顺序完成：

1. `D1`
2. `D2`
3. `D4`

本轮明确不做：

- vulnerable/fixed pair 对照
- `D3`
- `E2` 风格 prompt 控制
- repo 外额外高信息文件注入

## 2. 固定 run_id

执行前先固定：

- `run_id = AAE4_CRONUTILS_<UTC timestamp>`

后续所有产物都必须落到：

- `artifacts/architecture_attribution/E4/<run_id>/`

## 3. 共享前置检查

执行 `D1/D2/D4` 之前，先确认以下条件全部成立：

- `family_id` 固定为：
  `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`
- `query_id` 固定为：
  `cwe-094wLLM`
- 共享目标语义链固定为：
  `CronValidator.isValid(String value)`
  `CronParser.parse(value)`
  `IllegalArgumentException`
  `Throwable.getMessage()`
  `buildConstraintViolationWithTemplate(String p0)`
- 不读取：
  `ground_truth.json`
  answer-bearing `README`
  `E2` 结论性摘要
- 不注入：
  目标函数名
  行号
  标准答案文本
  与真实 diff 无关的额外 `target_files`

## 4. DeepAudit 环境检查

执行前确认：

1. backend 连通性检查使用提权网络上下文
2. frontend 连通性检查使用同一主机
3. 所有 run 绑定同一 backend URL
4. runner 输出目录指向：
   `artifacts/architecture_attribution/E4/`

## 5. `D1` 输入检查

确认 `D1` 满足：

- 只使用 curated repo bundle
- repo 根目录下没有 `CVE_CONTEXT.md`
- repo 根目录下没有 `FIX_PATCH.diff`
- task payload 不设置 `target_files`
- 没有额外答案型说明文件

执行后记录：

- 是否命中 `CronValidator` 真实入口
- 是否命中 `getMessage()` bridge
- 是否命中 template sink
- 是否只给出 generic parse/validation 解释
- 是否出现 off-target finding

## 6. `D2` 输入检查

确认 `D2` 只比 `D1` 多一份 `CVE_CONTEXT.md`。

人工检查 `CVE_CONTEXT.md` 时，必须确认：

- 只包含 `CVE-2021-41269` 与高层漏洞语义
- 不包含函数名
- 不包含文件路径
- 不包含行号
- 不包含 `Throwable.getMessage()`、`buildConstraintViolationWithTemplate(...)` 等 target-level 直接锚点

确认 `D2` 仍然：

- 没有 `FIX_PATCH.diff`
- 没有 `target_files`

执行后记录：

- 相比 `D1`，是否更接近目标链
- `CVE` hint 是否只带来 generic 注入猜测
- 是否首次恢复 `getMessage()` bridge

## 7. `D4` 输入检查

确认 `D4` 在 `D2` 基础上新增：

- `FIX_PATCH.diff`
- `target_files`

人工检查 `D4` 时，必须确认：

1. `FIX_PATCH.diff` 来自真实修复补丁
2. `target_files` 只取真实 diff 改动文件
3. 不因为 `E2` 的局部 source-window 曾出现某些文件，就把它们额外加入 `target_files`

如果真实 diff 只改：

- `src/main/java/com/cronutils/validation/CronValidator.java`

则 `target_files` 只允许这一项。

如果真实 diff 也改：

- `src/main/java/com/cronutils/parser/CronParser.java`

则把它一并加入。

执行后记录：

- 是否首次稳定恢复完整目标链
- 成功是否明显依赖 diff + target_files
- 是否仍然存在 off-target finding

## 8. 共享成功判定

只有同时满足以下 4 条，才记为“恢复 target-aligned reasoning”：

1. 明确识别 `CronValidator.isValid(String value)` 或等价真实入口。
2. 明确识别 `Throwable.getMessage()` 或等价异常消息 bridge。
3. 明确识别 `buildConstraintViolationWithTemplate(...)` 或等价模板 sink。
4. 明确把问题解释成模板/表达式注入，而不是泛泛的 parse error。

以下情况都不算成功：

- 只说 cron 输入会导致异常
- 只说 validator 构造了错误消息
- 只说存在 `javax.validation` 风险
- 只报目标链外 finding

## 9. 每档必须回填的字段

`D1/D2/D4` 每档至少记录：

- `mode_id`
- `contains_CronValidator_value_source`
- `contains_getMessage_bridge`
- `contains_template_sink`
- `target_alignment`
- `off_target_finding`
- `primary_observation`
- `cost_tokens`
- `wall_time_seconds`
- `tool_call_count`
- `context_volume`

## 10. 每档落盘检查

`D1/D2/D4` 每档至少检查以下文件齐全：

- `spec.json`
- `case_meta.json`
- `create_project.json`
- `upload_zip.json`
- `create_task.json`
- `task_object.json`
- `task_findings.json`
- `task_summary.json`
- `metrics.json`
- `failure_classification.txt`

run 根目录至少检查：

- `run_manifest.json`

## 11. 停止规则

满足以下任一条件即可先停止本轮并写总结：

- `D1` 已经清晰恢复目标链
- `D1` 失败、`D2` 成功，且结论已经足够支持 `CVE hint` 主导
- 只有 `D4` 成功，且已经足够支持信息优势主导
- `D4` 仍失败，已足够支持“这条 family 上 DeepAudit 也不天然占优”

本轮不在 checklist 内继续扩成：

- `D3`
- 更大 repo bundle
- 额外人工路径说明

## 12. 最终解释检查

最终总结时按以下规则解释：

- `D1` 成功：
  优先解释为架构优势。
- `D2` 首次成功：
  优先解释为 `CVE` 高层 hint 抬升。
- `D4` 首次成功：
  优先解释为信息优势。
- `D4` 失败：
  优先解释为该异常消息链对 `DeepAudit` 也仍然困难。
