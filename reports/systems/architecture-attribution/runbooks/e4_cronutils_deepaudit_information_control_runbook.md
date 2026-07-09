# E4 Cron-utils DeepAudit Information Control Runbook

## 1. 作用

这份 runbook 用于执行 `Architecture Attribution Experiment` 中
`jmrozanec__cron-utils_CVE-2021-41269_9.1.5` 的 `E4 DeepAudit Information Advantage Control`。

它要回答的问题是：

- `DeepAudit` 在几乎不给额外提示时，是否已经能恢复这条 family 的目标异常消息链
- 如果不能，恢复是否主要依赖 `CVE` 高层 hint
- 如果只有在 `diff + target_files` 条件下才能恢复，是否更应归因为信息优势，而不是架构优势

本 family 的共享目标语义固定为：

`CronValidator.isValid(String value)`
-> `CronParser.parse(value)`
-> `IllegalArgumentException`
-> `Throwable.getMessage()`
-> `ConstraintValidatorContext.buildConstraintViolationWithTemplate(String p0)`

## 2. 不做什么

本 runbook 不负责：

- vulnerable/fixed pair differential
- `D3`
- 读取 `ground_truth.json` 或 answer-bearing `README`
- 把 `E2` 的结论性摘要直接喂给模型
- 改写 `DeepAudit` 部署、模型来源或系统 prompt
- 把结果写回 `artifacts/deepaudit_*`

## 3. 为什么现在启动

当前先验已经足够支持把 `cron-utils` 切到 `E4`：

1. `E1` 已证明不应继续扩大静态补丁。
2. `E2` 已证明：一旦给到受控 target-context，模型能恢复目标链。
3. 因此当前最需要分离的问题，不再是“LLM 会不会推”，而是：
   `DeepAudit` 的成功若出现，究竟更像自由 repo 审计能力，还是更像额外信息注入。

对应背景证据：

- [e1_cronutils_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e1_cronutils_runbook.md:1)
- [e2_cronutils_five_level_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e2_cronutils_five_level_runbook.md:1)
- [e2_llm_freedom_ladder_progress_report.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e2_llm_freedom_ladder_progress_report.md:1)

## 4. 条件定义

第一轮只跑 `D1 / D2 / D4`。

### 4.1 `D1`

输入约束：

- 只给 curated repo bundle
- 不提供 `CVE` 描述
- 不提供 `patch/diff`
- 不提供 `target_files`

它回答：

- 纯 repo-level 自由审计是否已经足够恢复异常消息链

### 4.2 `D2`

输入约束：

- 保持与 `D1` 同一份 curated repo bundle
- 不提供 `patch/diff`
- 不提供 `target_files`
- 只额外提供一份 repo 根目录的 `CVE_CONTEXT.md`

它回答：

- 单独增加 `CVE` 高层 hint，是否就足以把模型拉回目标链

### 4.3 `D4`

输入约束：

- 保持与 `D2` 同一份 curated repo bundle
- 提供 repo 根目录的 `CVE_CONTEXT.md`
- 提供真实 `FIX_PATCH.diff`
- 在 task payload 中显式设置 `target_files`

它回答：

- 只有在最大信息条件下，`DeepAudit` 是否才开始稳定恢复目标链

## 5. `cron-utils` 特殊输入约束

### 5.1 `D2` 的 `CVE_CONTEXT.md`

允许包含：

- `CVE-2021-41269`
- 漏洞类型是 `CWE-094 / expression or template injection`
- 高层语义是：用户控制的 cron 表达式可影响校验错误消息，而该错误消息进入模板化校验输出

不允许包含：

- 目标函数名
- 目标文件路径
- 行号
- 标准答案措辞
- `Throwable.getMessage()`、`buildConstraintViolationWithTemplate(...)` 这类 target-level 直接锚点

### 5.2 `D4` 的 `target_files`

`target_files` 不做人工扩面，只取真实 fix diff 改动文件。

执行规则：

1. 先从真实修复补丁生成 `FIX_PATCH.diff`
2. 再从该 diff 中提取真实改动文件列表
3. `D4` 的 `target_files` 只允许使用这份文件列表

如果 diff 只涉及：

- `src/main/java/com/cronutils/validation/CronValidator.java`

则 `D4` 只设置这一项。

如果 diff 还涉及：

- `src/main/java/com/cronutils/parser/CronParser.java`

则把它一并加入。

不因为 `E2` 的 source-window 曾出现以下文件，就默认把它们加入 `target_files`：

- `CronParserField.java`
- `FieldParser.java`

## 6. 运行约束

### 6.1 网络访问

真实 `DeepAudit` 连通性检查必须使用提权网络上下文，不得在默认沙箱里探测。

固定检查顺序：

1. `curl http://127.0.0.1:8000/health`
2. `curl http://localhost:8000/health`
3. `curl http://172.27.144.1:8000/health`

主机选择规则：

- 使用第一个返回 `200` 的 backend URL
- 后续 runner 全部绑定到同一个 backend URL
- frontend URL 采用同主机、端口 `3000`

### 6.2 runner

使用：

- [scripts/run_deepaudit_repo_experiment.sh](/home/lqs/llm_audit_system_learning/scripts/run_deepaudit_repo_experiment.sh:1)

结果必须写入：

- `artifacts/architecture_attribution/E4/`

不得写入：

- `artifacts/deepaudit_*`

## 7. 建议运行顺序

固定顺序：

1. `D1`
2. `D2`
3. `D4`

原因：

- 先判断 repo-level 自由审计本身是否够强
- 再隔离 `CVE` hint 的作用
- 最后再看最大信息条件是否才触发成功

## 8. 成功判定

对 `cron-utils`，只有同时满足以下 4 条，才记为“恢复 target-aligned reasoning”：

1. 明确识别 `CronValidator.isValid(String value)` 或等价真实入口。
2. 明确识别 `Throwable.getMessage()` 或等价异常消息 bridge。
3. 明确识别 `buildConstraintViolationWithTemplate(...)` 或等价模板 sink。
4. 明确把问题解释成模板/表达式注入，而不是泛泛的 parse error。

以下情况不记为成功：

- 只说 cron 解析失败会抛异常
- 只说 validator 会返回 `false`
- 只报 generic `javax.validation` 风险
- 只报与目标链无关的 off-target finding

## 9. 每档至少记录什么

`D1 / D2 / D4` 每档至少记录：

- `contains_CronValidator_value_source`
- `contains_getMessage_bridge`
- `contains_template_sink`
- `target_alignment`
- `off_target_finding`
- `cost_tokens`
- `wall_time_seconds`
- `tool_call_count`
- `context_volume`

## 10. 结果解释规则

- `D1` 就成功：
  强支持 repo-level 自由审计本身具有架构优势。
- `D1` 失败、`D2` 成功：
  更支持 `CVE` 高层 hint 是关键抬升项。
- 只有 `D4` 成功：
  更支持信息优势，而不是架构优势。
- `D4` 也失败：
  说明 `DeepAudit` 对这条异常消息链也没有天然恢复优势。

## 11. 产物要求

每次 run 至少保存：

- `run_manifest.json`
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

此外补一份 family-level 总结，明确：

- `D1/D2/D4` 中哪一档首次恢复目标链
- 该成功更像架构优势还是信息优势
- 是否需要再补第二轮 `D3`
