# E2 SSRF-3432 Pair Differential Freedom Ladder Runbook

## 1. 作用

这份 runbook 用于执行 `Architecture Attribution Experiment` 中 `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED` 的 `E2 differential freedom ladder`。

它要回答的问题不是：

- 还能不能继续扩大 `E1` 的 candidate
- 还能不能继续补一个最小 `source/path`
- 还能不能继续扩 caller-side slice

它真正要回答的是：

- 当 `E1` 已经证明静态 gate 内的局部补丁收益很低后，把 LLM 沿着 `differential freedom` 逐档放宽，是否能恢复这条 pair 的 `target-aligned differential reasoning`
- `SSRF-3432 pair` 的主断点，更像 `workflow representation limit`、`output format limit`，还是必须依赖更自由的 repo 内探索

## 2. 为什么现在启动

`SSRF-3432 pair` 的现有证据已经给出足够强的切换信号：

1. `E1` 证明 `candidate gate` 不是主因。
2. `E1` 证明最小 `source` 物化不是充分条件。
3. `E1` 证明 caller-side slice 扩展也不是充分条件。
4. `FIXED=0 path` 目前不能被解释成 `fix-aware no path`，而只能解释成系统仍然没有在同一表示里打通修复语义。
5. `E4 D3/D4` 进一步说明，即使换成更自由的 `DeepAudit`，注意力虽然能回到 `LoadJson / SURL / SecurityProfile`，也仍然不会自然恢复稳定的 fixed-side 差分解释。

对应证据：

- [E1 进展报告 `SSRF-3432 pair` 小节](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e1_static_gate_oracle_progress_report.md:183)
- [AAE1_PAIR_SSRF3432 run_manifest](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PAIR_SSRF3432_20260706T125947Z/run_manifest.json:1)
- [E4 独立人读报告](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e4_ssrf3432_deepaudit_information_control_report.md:172)
- [AAE4_SSRF3432_D4 run_manifest](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D4_20260707T020239Z/run_manifest.json:1)

因此，这条 pair 的下一步不应继续扩大 `E1`，而应切到 `E2`，直接测试：

- 如果仍然冻结在 `IRIS-style static-gated workflow` 的原始表示里，模型为什么恢复不了目标语义
- 如果给到 pair-aware differential framing，但不再扩静态输入，模型是否已经足够解释 `vulnerable/fixed` 最小语义差

## 3. 共享目标语义

本 runbook 的所有模式都围绕同一条 pair-level 目标语义，不允许每档各自追不同的泛化 SSRF 面。

### 3.1 VULN 侧目标

至少要围绕以下概念链组织解释：

- `%load_json` 或等价用户输入进入 `LoadJson.loadStringData(path)`
- `path` 进一步进入 `SURL` 或等价 URL 访问路径
- 风险点与 `userinfo/@`、allowlist、redirect 或等价 URL 约束绕过语义相关

### 3.2 FIXED 侧目标

至少要解释以下一类修复语义为何改变了结论：

- `forbiddenURL()` 一类拒绝逻辑
- `isInUrlAllowList()` 一类 allowlist 收紧
- `userinfo/@` 处理变化
- 或其他能够明确说明 “同类输入为什么在 fixed side 不再成立” 的 guard 语义

### 3.3 Pair-level 成功标准

只有同时满足以下 4 条，才算恢复了 `differential semantic understanding`：

1. 明确识别 `LoadJson.path` 或等价 `%load_json` 参数是目标外部输入。
2. 明确指出 `LoadJson -> SURL` 或等价 URL 访问链是本 query 的目标路径。
3. 明确解释 `VULN` 侧为何会落到 `userinfo/@ / allowlist / redirect` 相关 SSRF 语义。
4. 明确解释 `FIXED` 侧为何不再成立，而不是只给出一个 `0 path` 或“fixed 没报”。

以下情况都不算成功：

- 只在 `VULN` 侧报出泛化 SSRF finding
- 只说 `LoadJson` 能访问 URL，但没有落到目标差分机制
- 只说 `FIXED` 没有路径，却不解释 guard
- 只报 `LEGACY`、`executeInclude()` 或其他 off-target finding

## 4. 阶梯定义

这条 pair 的 `E2` 不采用 `cron-utils` 的五档全量执行，而采用：

- 默认执行 `M1`
- 跳过 `M2`
- 执行 `M3`
- 执行 `M4`
- 仅在必要时执行 `M5`

原因是这条 pair 当前最强疑点不是“缺一个极小 local source-window”，而是“差分目标语义与 fixed-side guard 没被正确框定”。

### 4.1 `M1 original`

LLM 看到：

- 原始 `IRIS` Stage 3 候选 API / source func param 候选
- 原始 package summary 与方法签名

LLM 能做：

- 只输出 `source / sink / taint-propagator` 结构化标签

不允许：

- 自由写漏洞路径
- 自由比较 `VULN/FIXED`
- 读 repo 文件

这档用于复现：

- 原始 static-gated 表示下，系统是否仍停在错误 source 或 `source=0/path=0`

### 4.2 `M3 differential target-context constrained`

LLM 看到：

- `M1` 的全部材料
- 一份 pair-aware `target-context memo`

`target-context memo` 允许包含：

- `family_id` 与 `query_id`
- `VULN/FIXED` 共享目标链：`LoadJson.path -> SURL -> URL constraint`
- fixed-side 关注点是 “为什么不再成立”，而不是只看 `no path`
- `E1` 的非结论性事实：
  `candidate` 已充分
  `LoadJson.path` 已被强制物化过
  caller-side slice 扩展已试过
- `E4` 的非结论性事实：
  注意力可被拉回 `LoadJson / SURL / SecurityProfile`
  但 freer auditor 仍未自然解释 fixed-side guard

`target-context memo` 不允许包含：

- `ground_truth.json`
- 标准答案文本
- `D4` 的 target file 清单原样复述成“正确文件”
- “真实修复点就是 X” 这类结论性断言

LLM 能做：

- 输出固定 JSON，而不是原始标签列表
- 显式比较 `VULN/FIXED`

建议 JSON 字段：

- `vulnerable_source_candidates`
- `vulnerable_sink_candidates`
- `fixed_guard_candidates`
- `vulnerable_path_hypothesis`
- `fixed_side_explanation`
- `minimal_semantic_delta`
- `why_fixed_not_just_no_path`
- `confidence`

这档用于回答：

- 如果只把模型显式拉回 pair-level 差分目标，但仍保留结构化输出约束，是否已经足够恢复目标语义

### 4.3 `M4 differential free auditor`

LLM 看到：

- 与 `M3` 相同的文件与上下文

LLM 能做：

- 不再输出 `source/sink/taint-propagator` 标签
- 直接自由描述 `VULN/FIXED` 的差分漏洞路径、关键证据和最小语义差

固定要求：

- 必须分别写出 `VULN` 与 `FIXED` 的解释
- 必须显式回答 “fixed side 为什么不再成立”
- 必须说明这不是普通 SSRF 面枚举，而是目标 `userinfo/@ / allowlist / redirect` 差分

不允许：

- 读 repo 以外新文件
- 引入 `patch/diff` 文本
- 引入 `target_files`
- 引入官方答案

这档用于回答：

- 如果保持同样信息量，只去掉结构化输出束缚，模型是否已经能恢复 pair-level 差分解释

### 4.4 `M5 differential agentic auditor`

LLM 看到：

- 与 `M4` 相同的起始 bundle
- 允许在同一份 clean repo / curated subset 内继续检索、追调用链、打开必要文件

默认允许读取的优先文件：

- `src/net/sourceforge/plantuml/tim/stdlib/LoadJson.java`
- `src/net/sourceforge/plantuml/security/SURL.java`
- `src/net/sourceforge/plantuml/security/SecurityProfile.java`
- `src/net/sourceforge/plantuml/security/SecurityUtils.java`

默认允许读取的扩展范围：

- 上述文件的直接 caller/callee
- 为解释 fixed-side guard 必需的直接相邻文件

不允许：

- 读 `ground_truth.json`
- 读 answer-bearing `README`
- 读 `E4` staging 里的高信息 `CVE_CONTEXT` / `target_files`
- 直接引入 patch、diff 或官方修复说明

必须额外记录：

- `tool_call_count`
- `opened_files`
- `context_volume`
- `new_files_beyond_M4`

这档用于回答：

- 如果 `M4` 仍失败，repo 内主动探索是否能恢复差分语义
- 如果 `M5` 成功但 `M4` 失败，成功是否主要来自额外上下文获取能力

### 4.5 为什么这轮不做 `M2`

这条 pair 当前不做 `M2 candidate + source window`，原因是：

1. `E1-C/D` 已经证明，把 source 强制拉回 `LoadJson.path` 后，系统仍然不能解释目标语义。
2. 这条 pair 的主断点更像 `differential framing / fixed-guard semantics`，不是单个 local window 缺失。
3. 总实验规划里，`E2` 第一轮本来就优先做 `M1/M3/M4/M5`，把 `M2` 视作低区分度条件。

只有未来出现新证据，明确表明“模型其实只差一个极小局部代码窗口”，才单独回补 `M2`。

## 5. 统一输入边界

### 5.1 冻结项

所有模式都必须冻结：

- 同一 `Experiment-side Configuration`
- 同一 pair：`SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED`
- 同一 clean input 基线
- 同一 query 目标：`cwe-918wLLM`
- 不引入 `ground_truth.json`
- 不引入 answer-bearing `README`
- 不引入 patch、diff、官方修复说明

### 5.2 可变项

本实验唯一允许变化的是：

- LLM 可见上下文的组织方式
- 输出格式是否仍受结构化标签约束
- 是否允许 repo 内主动检索

### 5.3 不允许混入的高信息

不允许把以下内容混入 `E2`：

- `E1` 的手工静态补丁本体
- `E4 D4` 的 `target_files` 清单
- `E4 D2/D3/D4` 的 `CVE_CONTEXT.md`
- “正确答案就是 userinfo bypass” 这类结论性提示

## 6. 输出与判定

### 6.1 每档至少记录

- `mode_id`
- `vulnerable_path_explained`
- `fixed_guard_explained`
- `minimal_semantic_delta`
- `target_alignment`
- `guard_awareness`
- `off_target_finding`
- `confidence`
- `cost_tokens`
- `wall_time_seconds`
- `tool_call_count`
- `context_volume`

### 6.2 Pair-level 关键判定

对这条 pair，以下字段优先级最高：

- `fixed_guard_explained`
- `why_fixed_not_just_no_path`
- `minimal_semantic_delta`

如果某档只提高了 `VULN` 侧 recall，却仍不能解释 fixed-side guard，则只能记为：

- `vulnerable_recall_improved_without_differential_understanding`

不能记为：

- `pair-level success`

## 7. 建议运行顺序与停止规则

默认顺序：

1. `M1_original`
2. `M3_differential_target_context_constrained`
3. `M4_differential_free_auditor`

只有在以下任一条件成立时才进入 `M5`：

- `M4` 仍不能稳定解释 fixed-side guard
- `M4` 只有 `VULN` 成功，`FIXED` 仍停在 `no path`
- `M4` 输出主要是泛化 SSRF 面枚举，未回到目标差分

如果 `M4` 已稳定满足 pair-level 成功标准，则本轮可以停止，不强制跑 `M5`。

## 8. 产物要求

每档至少保存：

- `input_contract.json`
- `prompt_contract.md`
- `context_bundle/`
- `normalized_output.json`
- `run_summary.json`

如该档走 `IRIS` 多阶段或 shell 包装执行，再额外保存：

- `stdout.log`
- `stderr.log`

如该档走单轮 `run_llm_prompt_capture.py`，则用以下文件替代 `stdout/stderr` 作为主执行证据：

- `llm_run/request.json`
- `llm_run/response.txt`
- `llm_run/run_meta.json`

如执行 `M5`，还必须追加：

- `tool_trace.json`
- `opened_files.txt`
- `context_volume.json`

结果统一落到：

- `artifacts/architecture_attribution/E2/<run_id>/`

默认模板入口：

- [SSRF3432_pair templates README](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/README.md:1)
- [M1 input_contract.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/M1_original/input_contract.json:1)
- [M1 prompt_contract.md](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/M1_original/prompt_contract.md:1)
- [M3 input_contract.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/M3_differential_target_context_constrained/input_contract.json:1)
- [M3 prompt_contract.md](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/M3_differential_target_context_constrained/prompt_contract.md:1)
- [M4 input_contract.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/M4_differential_free_auditor/input_contract.json:1)
- [M4 prompt_contract.md](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/M4_differential_free_auditor/prompt_contract.md:1)
- [M5 input_contract.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/M5_differential_agentic_auditor/input_contract.json:1)
- [M5 prompt_contract.md](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/templates/SSRF3432_pair/M5_differential_agentic_auditor/prompt_contract.md:1)

## 9. 解释矩阵

推荐按以下方式解释结果：

- `M1` 失败，`M3` 成功：
  主断点更像缺少 pair-aware differential framing。
- `M3` 失败，`M4` 成功：
  主断点更像结构化输出格式压制了差分解释。
- `M4` 失败，`M5` 成功：
  主断点更像 repo 内上下文获取与调用链追踪能力不足。
- `M5` 仍失败：
  即使放宽到受控 agentic differential auditor，这条 pair 的 fixed-guard 语义仍不稳定，后续应考虑转到更强的修复语义解释实验，而不是继续扩大 `E2`。
