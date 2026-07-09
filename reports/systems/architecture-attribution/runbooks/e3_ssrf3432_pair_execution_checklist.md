# E3 SSRF-3432 Pair Execution Checklist

## 1. 这轮要完成什么

本清单服务于：

- [e3_ssrf3432_pair_tool_authority_ablation_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e3_ssrf3432_pair_tool_authority_ablation_runbook.md:1)

当前目标是验证：

- 静态工具在 prompt/workflow 中是否形成高权威先验
- 这种权威先验是否压制模型主动挑战 `no path`

本轮固定执行：

1. `A_strong_authority`
2. `B_weak_authority`
3. `C_faulty_tool_injection`

本轮明确不做：

- `cron-utils`
- `SSRF-JA-REPO-001`
- `repo-level agentic search`

## 2. 固定 run_id

执行前先固定：

- `run_id = AAE3_PAIR_SSRF3432_<UTC timestamp>`

后续所有产物都必须落到：

- `artifacts/architecture_attribution/E3/<run_id>/`

## 3. 共享前置检查

执行前先确认以下条件全部成立：

- `family_id` 固定为：
  `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED`
- `query_id` 固定为：
  `cwe-918wLLM`
- 三档使用同一模型来源
- 三档使用同一 clean pair-local evidence 基线
- 三档使用同一 differential semantic evaluation
- 不读取：
  `ground_truth.json`
  answer-bearing `README`
  `E4` staging 高信息文件
- 不注入：
  patch
  diff
  官方修复说明
  `E4 D4 target_files`
  `E1` 手工静态补丁

## 4. 共享目标语义检查

执行前先确认 pair-level 目标语义已经冻结：

- `VULN` 侧：
  `%load_json` / `LoadJson.path`
  `LoadJson -> SURL`
  `userinfo/@ / allowlist / redirect`
- `FIXED` 侧：
  `forbiddenURL()`
  `isInUrlAllowList()`
  `userinfo/@` 拒绝或等价局部 guard
- 本轮目标不是 generic SSRF 面枚举，而是解释：
  同类输入为什么在 `VULN` 成立、在 `FIXED` 不再成立

## 5. 共享成功判定

只有同时满足以下 4 条，才记为本轮恢复了 pair-level differential understanding：

1. 明确识别 `LoadJson.path` 或等价 `%load_json` 参数是目标外部输入。
2. 明确指出 `LoadJson -> SURL` 或等价 URL 访问链是 query 目标路径。
3. 明确解释 `VULN` 侧为何会落到 `userinfo/@ / allowlist / redirect` 差分语义。
4. 明确解释 `FIXED` 侧为何不再成立，而不是只给出 `0 path`。

以下情况都不算成功：

- 只说 `VULN` 有 SSRF 风险
- 只保留 generic `java.net` URL/URLConnection 面
- 只说 `FIXED` 不报了
- 只报 `LEGACY`、`executeInclude()` 或其他 off-target finding

## 6. `A_strong_authority` 执行清单

确认 `A` 满足：

- 输入中包含强工具权威措辞
- 明确出现：
  `no path`
  `source predicate 为空`
  或等价“工具已基本判定完成”的表述
- 同时给出候选 source/sink 列表或相关 surfaces
- 仍然不直接给标准答案

执行后记录：

- `authority_compliance`
- `tool_output_challenged`
- `contains_LoadJson_path_source`
- `contains_SURL_related_sink`
- `fixed_guard_explained`
- `target_alignment`

关键检查：

- 模型是否顺从工具 `no path`
- 模型是否因此放弃恢复 `LoadJson -> SURL`
- 模型是否把 `FIXED` 侧退化成“没路径所以安全”

## 7. `B_weak_authority` 执行清单

确认 `B` 满足：

- 保持与 `A` 同一批 pair-local 文件与上下文
- 去掉强 `no path` 权威措辞
- 明确提示：
  不要假设静态分析完整，
  候选只是辅助，不是完整 oracle
- 仍不引入比 `A` 更多的信息

执行后记录：

- `authority_compliance`
- `tool_output_challenged`
- `contains_LoadJson_path_source`
- `contains_SURL_related_sink`
- `fixed_guard_explained`
- `target_alignment`

关键检查：

- 去掉权威措辞后，模型是否会主动补回 `LoadJson.path`
- 是否会主动把链条组织成 `LoadJson -> SURL -> fixed guard`
- 是否比 `A` 更愿意质疑“工具可能漏掉关键点”

## 8. `C_faulty_tool_injection` 执行清单

确认 `C` 满足：

- 保持与 `B` 同一批 pair-local 文件与目标上下文
- 故意给一份不完整或偏置的工具候选
- 至少缺失以下一类关键项之一：
  `LoadJson.path`
  `SURL.getBytes()`
  `forbiddenURL()` / `isInUrlAllowList()`
- 明确允许模型指出工具列表不完整

执行后记录：

- `authority_compliance`
- `tool_output_challenged`
- `recovered_missing_source`
- `recovered_missing_sink`
- `recovered_missing_guard`
- `target_alignment`

关键检查：

- 模型是否显式指出工具候选不完整
- 模型是否主动补全缺失 source/sink/guard
- 如果看见明显冲突，模型是否比 `A/B` 更愿意反驳工具

## 9. 每档必须回填的字段

`A/B/C` 每档至少记录：

- `mode_id`
- `authority_strength`
- `tool_output_challenged`
- `authority_compliance`
- `vulnerable_path_explained`
- `fixed_guard_explained`
- `minimal_semantic_delta`
- `target_alignment`
- `guard_awareness`
- `off_target_finding`
- `cost_tokens`
- `wall_time_seconds`
- `tool_call_count`
- `context_volume`

## 10. 停止规则

满足以下任一条件即可先停止本轮：

- `A` 明显失败而 `B/C` 明显成功，已经足够支持 authority 假设
- `A/B/C` 都失败，已经足够支持“问题不只在 authority”
- `A/B/C` 都成功，已经足够支持“authority 不是主瓶颈”

本轮不在 `E3` 内继续扩成：

- `M5` 风格 agentic repo search
- `DeepAudit` 式额外文件遍历
- 更高信息 patch/fix 注入

这些属于其他实验问题，不应在 `E3` 混入。

## 11. 每档落盘检查

`A/B/C` 每档至少检查以下文件齐全：

- `input_contract.json`
- `prompt_contract.md`
- `context_bundle/`
- `normalized_output.json`
- `run_summary.json`

如果该档走单轮 `run_llm_prompt_capture.py`，则额外检查：

- `llm_run/request.json`
- `llm_run/response.txt`
- `llm_run/run_meta.json`

默认模板入口：

- [templates README](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/templates/SSRF3432_pair/README.md:1)
- [A input_contract.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/templates/SSRF3432_pair/A_strong_authority/input_contract.json:1)
- [A prompt_contract.md](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/templates/SSRF3432_pair/A_strong_authority/prompt_contract.md:1)
- [B input_contract.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/templates/SSRF3432_pair/B_weak_authority/input_contract.json:1)
- [B prompt_contract.md](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/templates/SSRF3432_pair/B_weak_authority/prompt_contract.md:1)
- [C input_contract.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/templates/SSRF3432_pair/C_faulty_tool_injection/input_contract.json:1)
- [C prompt_contract.md](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/templates/SSRF3432_pair/C_faulty_tool_injection/prompt_contract.md:1)

## 12. 最终解释检查

按以下规则解释本轮结果：

- `A` 失败、`B/C` 成功：
  支持“静态工具权威先验限制 LLM”。
- `A/B` 失败、`C` 成功：
  支持“模型能纠正错误工具，但需要显式看到冲突”。
- `A/B/C` 都失败：
  支持“问题不只是 authority，而是更深的语义解释缺口”。
- `A/B/C` 都成功：
  支持“authority 不是这条 pair 的主瓶颈，`E2` 的收益更多来自任务 framing”。
