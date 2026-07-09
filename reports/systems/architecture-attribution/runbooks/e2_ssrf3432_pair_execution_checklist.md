# E2 SSRF-3432 Pair Execution Checklist

## 1. 这轮要完成什么

本清单服务于：

- [e2_ssrf3432_pair_differential_freedom_ladder_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e2_ssrf3432_pair_differential_freedom_ladder_runbook.md:1)

当前目标不是继续扩 `E1`，而是按顺序执行：

1. `M1_original`
2. `M3_differential_target_context_constrained`
3. `M4_differential_free_auditor`

条件执行：

4. `M5_differential_agentic_auditor`

本轮明确不做：

- `M2_candidate_source_window`

## 2. 固定 run_id

执行前先固定：

- `run_id = AAE2_PAIR_SSRF3432_<UTC timestamp>`

后续所有产物都必须落到：

- `artifacts/architecture_attribution/E2/<run_id>/`

## 3. 共享前置检查

执行前先确认以下条件全部成立：

- `family_id` 固定为：
  `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED`
- `query_id` 固定为：
  `cwe-918wLLM`
- 五档中的实际执行模式固定为：
  `M1`
  `M3`
  `M4`
  `M5 if needed`
- 五档使用同一 `Experiment-side Configuration`
- 五档使用同一 clean input 基线
- 不读取：
  `ground_truth.json`
  answer-bearing `README`
  `E4` 的高信息 staging 文件
- 不注入：
  patch
  diff
  官方修复说明
  新的 `E1` 手工静态补丁

## 4. 共享目标语义检查

执行前先确认 pair-level 目标语义已经冻结：

- `VULN` 侧：
  `%load_json` / `LoadJson.path`
  `LoadJson -> SURL`
  `userinfo/@ / allowlist / redirect` 相关 SSRF 差分
- `FIXED` 侧：
  需要解释 `forbiddenURL()`、`isInUrlAllowList()`、`userinfo/@` 拒绝或等价 guard
- pair-level 目标不是泛化 SSRF 面扫描，而是解释 “同类输入在 VULN 成立、在 FIXED 不再成立”

## 5. 共享成功判定

只有同时满足以下 4 条，才记为本轮成功：

1. 明确识别 `LoadJson.path` 或等价 `%load_json` 参数是目标外部输入。
2. 明确指出 `LoadJson -> SURL` 或等价 URL 访问链是 query 目标路径。
3. 明确解释 `VULN` 侧为何会落到 `userinfo/@ / allowlist / redirect` 差分语义。
4. 明确解释 `FIXED` 侧为何不再成立，而不是只给出 `0 path`。

以下情况都不算成功：

- 只提升 `VULN` 侧 recall
- 只报 `LoadJson` / `SURL` 一般性 SSRF 风险
- 只说 `FIXED` 不报了
- 只报 `LEGACY`、`executeInclude()` 或其他 off-target finding

## 6. `M1` 执行清单

确认 `M1` 满足：

- 输入只包含原始 `IRIS` Stage 3 候选 API / source func param 候选
- 输入包含原始 package summary 与方法签名
- 输出格式仍为 `source / sink / taint-propagator` 结构化标签
- 没有自由文本漏洞路径说明
- 没有 pair-level 比较文本
- 没有额外 repo 文件读取

执行后记录：

- `llm_sources`
- `llm_sinks`
- `llm_taint_propagators`
- `contains_LoadJson_path_source`
- `contains_SURL_related_sink`
- `target_alignment`
- `off_target_findings`

关键检查：

- 是否再次复现错误 source 或 `source=0/path=0`
- 是否仍然不能把注意力拉回 `LoadJson -> SURL`

## 7. `M3` 执行清单

确认 `M3` 只比 `M1` 多出 pair-aware `target-context memo`。

`target-context memo` 允许：

- `family_id`
- `query_id`
- pair-level 目标链
- `E1` 的非结论性事实：
  `candidate` 已充分
  `LoadJson.path` 已物化过
  caller-side slice 已试过
- `E4` 的非结论性事实：
  freer auditor 可回到 `LoadJson / SURL / SecurityProfile`
  但 fixed-side guard 仍未自然解释

`target-context memo` 禁止：

- `ground_truth.json`
- 标准答案文本
- “真实修复点就是 X”
- `E4 D4 target_files` 原样清单

确认 `M3` 输出：

- 是固定 JSON
- 不是原始标签列表
- 显式比较 `VULN/FIXED`

建议 JSON 字段是否齐全：

- `vulnerable_source_candidates`
- `vulnerable_sink_candidates`
- `fixed_guard_candidates`
- `vulnerable_path_hypothesis`
- `fixed_side_explanation`
- `minimal_semantic_delta`
- `why_fixed_not_just_no_path`
- `confidence`

执行后记录：

- `vulnerable_path_explained`
- `fixed_guard_explained`
- `minimal_semantic_delta`
- `why_fixed_not_just_no_path`
- `target_alignment`

关键检查：

- 是否因为差分目标被显式框定，模型开始解释 fixed-side guard

## 8. `M4` 执行清单

确认 `M4` 与 `M3` 使用同样文件与上下文。

确认 `M4` 变化只在输出格式：

- 不再输出 `source/sink/taint-propagator`
- 改为自由描述 `VULN/FIXED` 差分路径、关键证据、最小语义差

确认 `M4` 输出中必须出现：

- `VULN` 侧完整解释
- `FIXED` 侧完整解释
- “fixed side 为什么不再成立”
- 为什么这不是泛化 SSRF 面枚举

确认 `M4` 仍然不允许：

- 读 repo 以外新文件
- 引入 `patch/diff`
- 引入 `target_files`
- 引入官方答案

执行后记录：

- `vulnerable_path_explained`
- `fixed_guard_explained`
- `minimal_semantic_delta`
- `guard_awareness`
- `off_target_findings`

关键检查：

- 如果 `M3` 失败而 `M4` 成功，是否可归因为结构化输出格式压制

## 9. `M5` 触发条件清单

只有满足以下任一条件，才允许执行 `M5`：

- `M4` 仍不能稳定解释 fixed-side guard
- `M4` 只有 `VULN` 成功，`FIXED` 仍停在 `no path`
- `M4` 仍被大量 off-target SSRF 面吸走

如果 `M4` 已稳定满足 pair-level 成功标准，则本轮停止，不跑 `M5`。

## 10. `M5` 执行清单

确认 `M5` 起始 bundle 与 `M4` 相同。

确认 `M5` 只新增：

- repo 内检索
- 调用链追踪
- 打开必要文件

默认优先文件：

- `src/net/sourceforge/plantuml/tim/stdlib/LoadJson.java`
- `src/net/sourceforge/plantuml/security/SURL.java`
- `src/net/sourceforge/plantuml/security/SecurityProfile.java`
- `src/net/sourceforge/plantuml/security/SecurityUtils.java`

默认扩展范围：

- 上述文件的直接 caller/callee
- 为解释 fixed guard 必需的直接相邻文件

确认 `M5` 仍然禁止：

- 读 `ground_truth.json`
- 读 answer-bearing `README`
- 读 `E4` staging 的 `CVE_CONTEXT.md`
- 引入 patch、diff、官方修复说明

执行后必须额外保存：

- `tool_call_count`
- `opened_files`
- `context_volume`
- `new_files_beyond_M4`
- `tool_trace.json`
- `opened_files.txt`

关键检查：

- 如果 `M5` 成功但 `M4` 失败，成功是否主要来自额外上下文获取

## 11. 每档落盘检查

`M1/M3/M4/M5` 每档至少检查以下文件齐全：

- `input_contract.json`
- `prompt_contract.md`
- `context_bundle/`
- `normalized_output.json`
- `run_summary.json`

如果该档走 `IRIS` 多阶段或 shell 包装执行，再检查：

- `stdout.log`
- `stderr.log`

如果该档走单轮 `run_llm_prompt_capture.py`，则改为检查：

- `llm_run/request.json`
- `llm_run/response.txt`
- `llm_run/run_meta.json`

如执行 `M5`，额外检查：

- `tool_trace.json`
- `opened_files.txt`
- `context_volume.json`

默认模板入口：

- [templates README](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/README.md:1)
- [M1 input_contract.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/M1_original/input_contract.json:1)
- [M1 prompt_contract.md](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/M1_original/prompt_contract.md:1)
- [M3 input_contract.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/M3_differential_target_context_constrained/input_contract.json:1)
- [M3 prompt_contract.md](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/M3_differential_target_context_constrained/prompt_contract.md:1)
- [M4 input_contract.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/M4_differential_free_auditor/input_contract.json:1)
- [M4 prompt_contract.md](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/M4_differential_free_auditor/prompt_contract.md:1)
- [M5 input_contract.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/M5_differential_agentic_auditor/input_contract.json:1)
- [M5 prompt_contract.md](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/M5_differential_agentic_auditor/prompt_contract.md:1)

## 12. 总表回填检查

本轮结束后至少回填以下字段：

- `mode_id`
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

## 13. 最终解释检查

按以下规则解释本轮结果：

- `M1` 失败，`M3` 成功：
  说明 pair-aware differential framing 是主缺口。
- `M3` 失败，`M4` 成功：
  说明结构化输出格式压制了差分解释。
- `M4` 失败，`M5` 成功：
  说明 repo 内上下文获取与调用链追踪能力是关键缺口。
- `M5` 仍失败：
  说明这条 pair 不是再放宽一点自由度就能稳定恢复，后续应转向更明确的修复语义解释实验。
