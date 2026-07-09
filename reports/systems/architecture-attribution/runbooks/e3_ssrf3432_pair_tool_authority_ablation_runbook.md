# E3 SSRF-3432 Pair Tool Authority Ablation Runbook

## 1. 作用

这份 runbook 用于执行 `Architecture Attribution Experiment` 中 `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED` 的 `E3 tool authority ablation`。

它要回答的问题不是：

- `E1` 里还能不能继续补 `candidate / summary / slice`
- `E2` 里还能不能继续放宽 auditor 自由度
- `DeepAudit` 再多给一点信息会不会更强

它真正要回答的是：

- 静态工具在 prompt 与 workflow 中，是否已经形成高权威先验
- 这种权威先验，是否会压制 LLM 主动质疑 `no path`、补全缺失 source/sink、以及恢复 fixed-side guard explanation

## 2. 为什么现在启动

`SSRF-3432 pair` 当前已经具备启动 `E3` 的前置证据：

1. `E1` 证明继续补 `candidate / source / slice` 不足以恢复目标语义。
2. `E2` 证明一旦显式把模型锚定到 `LoadJson -> SURL -> fixed guard` 差分链，模型可以恢复 pair-level differential understanding。
3. `E4` 证明“给更多信息”和“放成更自由的 auditor”并不等于自然恢复 fixed-side 修复语义。

这三点合在一起，留下的最关键未回答问题就是：

- 先前失败，到底是模型不会解释这条链，
- 还是静态工具输出在 prompt 里变成了默认不可质疑的上位先验。

对应证据：

- [E1 进展报告 `SSRF-3432 pair` 小节](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e1_static_gate_oracle_progress_report.md:183)
- [E2 SSRF3432 独立人读报告](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e2_ssrf3432_pair_differential_freedom_report.md:1)
- [E4 SSRF3432 独立人读报告](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e4_ssrf3432_deepaudit_information_control_report.md:172)
- [总实验计划 `E3 Tool Authority Ablation`](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/architecture_attribution_experiment_plan.md:113)

## 3. 对象与范围

这份 runbook 第一轮只覆盖：

- `family_id = SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED`
- `query_id = cwe-918wLLM`

本轮明确不做：

- `cron-utils`
- `SSRF-JA-REPO-001`
- `repo-level agentic search`
- `patch / diff / 官方修复说明` 注入

原因是：

1. `SSRF-3432 pair` 已经有最完整的 `E1/E2/E4` 链路证据。
2. 这条 pair 上最容易观察“模型是否顺从工具 `no path` 结论”。
3. `cron-utils` 当前更适合 `summary / bridge` 归因，不是 `tool authority` 的第一优先 family。

## 4. 共享目标语义

`E3` 的三档条件都必须围绕同一条 pair-level 目标语义，不允许把实验退化成 generic SSRF 面扫描。

### 4.1 `VULN` 侧目标

至少要围绕以下概念链组织解释：

- `%load_json` 或等价用户输入进入 `LoadJson.loadStringData(path)`
- `path` 进入 `SURL.create(path)` 与 `SURL.getBytes()`
- 风险与 `userinfo/@`、allowlist、redirect 或等价 URL 约束绕过语义相关

### 4.2 `FIXED` 侧目标

至少要解释以下一类修复语义为何改变了结论：

- `forbiddenURL()` 一类拒绝逻辑
- `isInUrlAllowList()` 一类 allowlist 收紧
- `userinfo/@` 处理变化
- 或其他能说明 “同类输入为什么在 fixed side 不再成立” 的局部 guard 语义

### 4.3 共享成功标准

只有同时满足以下 4 条，才算恢复了 `pair-level differential understanding`：

1. 明确识别 `LoadJson.path` 或等价 `%load_json` 参数是目标外部输入。
2. 明确指出 `LoadJson -> SURL` 或等价 URL 访问链是 query 目标路径。
3. 明确解释 `VULN` 侧为何会落到 `userinfo/@ / allowlist / redirect` 差分语义。
4. 明确解释 `FIXED` 侧为何不再成立，而不是只给出 `0 path`。

以下情况都不算成功：

- 只说 `VULN` 有一般 SSRF 风险
- 只保留 generic `java.net` URL/URLConnection 面
- 只说 `FIXED` 没出路径
- 只报 `LEGACY`、`executeInclude()` 或其他 off-target finding

## 5. 三档条件定义

`E3` 第一轮固定执行三档：

1. `A_strong_authority`
2. `B_weak_authority`
3. `C_faulty_tool_injection`

三档使用同一 clean pair-local evidence 基线，只改变“工具权威如何被表述和注入”。

### 5.1 `A_strong_authority`

LLM 看到：

- 与目标链相关的局部文件、方法、候选 surfaces
- 明确的工具权威措辞，例如：
  `CodeQL/IRIS 未找到 path`
  `当前 source predicate 为空`
  `以下 source/sink 列表可视为主要可疑面`

LLM 任务：

- 在强工具先验存在时，判断还能否主动挑战 `no path` 结论

这档用于观察：

- 模型是否把工具输出当成近似最终答案
- 模型是否因此放弃补全 `LoadJson.path`、`SURL.getBytes()`、fixed guard

### 5.2 `B_weak_authority`

LLM 看到：

- 与 `A` 同一批 pair-local 文件、候选与调用关系
- 但不再强调“工具已经证明没有 path”
- 明确提示：
  不要假设静态分析完整，
  候选列表只是辅助，不是完整 oracle

LLM 任务：

- 在低权威注入下，自行判断工具是否漏掉关键 source / sink / guard

这档用于观察：

- 如果去掉权威措辞，模型是否会主动回到 `LoadJson -> SURL -> fixed guard`

### 5.3 `C_faulty_tool_injection`

LLM 看到：

- 与 `B` 相同的 pair-local 代码窗口与目标链上下文
- 但故意给一份不完整或偏置的工具候选列表

这份 faulty injection 应至少满足以下一类：

- 漏掉 `LoadJson.path` 或等价 source
- 漏掉 `SURL.getBytes()` 或等价网络 sink
- 漏掉 `forbiddenURL()` / `isInUrlAllowList()` 一类 fixed guard

LLM 任务：

- 判断工具列表是否不足，并显式挑战或修正它

这档用于观察：

- 模型能否在看到明显不完整工具输出时，主动反驳而不是被动顺从

## 6. 核心判定

`E3` 最重要的不是 “报没报 SSRF”，而是记录以下 4 个维度：

1. `authority_compliance`
   模型是否顺从工具 `no path / no source` 结论。
2. `tool_output_challenged`
   模型是否显式指出工具候选不完整或结论过强。
3. `target_alignment`
   模型是否把解释拉回 `LoadJson -> SURL -> fixed guard`。
4. `fixed_guard_explained`
   模型是否真正解释 `FIXED` 侧 guard，而不是只说 `0 path`。

优先解释矩阵：

- `A` 失败、`B/C` 成功：
  支持“静态工具权威先验限制 LLM”的假设。
- `A/B` 失败、`C` 成功：
  支持“模型能纠正错误工具，但需要看到显式冲突”。
- `A/B/C` 都失败：
  说明问题不只是 authority，更像更深的语义解释缺口。
- `A/B/C` 都成功：
  说明这条 pair 上 authority 不是主瓶颈，`E2` 的收益更多来自任务 framing。

## 7. 输入边界

### 7.1 固定项

三档都必须冻结：

- 同一 `family_id`
- 同一 `query_id`
- 同一模型来源与实验侧配置
- 同一 pair-level differential semantic evaluation
- 同一 clean pair-local evidence 基线

### 7.2 禁止项

`E3` 不允许混入：

- `ground_truth.json`
- answer-bearing `README`
- patch / diff / 官方修复说明
- `E4 D4 target_files`
- `E1` 的手工静态补丁本体
- 任何比 `E2 M3/M4` 更高信息的修复答案提示

### 7.3 允许项

`E3` 允许复用：

- `E2` 已经整理好的 pair-local 代码窗口
- 与目标链直接相关的 source/sink/guard candidates
- `M1` 失败形状摘要

但这些材料必须按 `A/B/C` 的 authority 强弱重新组织，不能直接把 `E2` 的成功结论塞回 prompt。

## 8. 产物要求

本轮新证据统一写入：

- `artifacts/architecture_attribution/E3/<run_id>/`

建议命名：

- `run_id = AAE3_PAIR_SSRF3432_<UTC timestamp>`

每档至少保存：

- `input_contract.json`
- `prompt_contract.md`
- `context_bundle/`
- `normalized_output.json`
- `run_summary.json`

如该档走单轮 `run_llm_prompt_capture.py`，还应保存：

- `llm_run/request.json`
- `llm_run/response.txt`
- `llm_run/run_meta.json`

默认模板入口：

- [SSRF3432_pair E3 templates README](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/templates/SSRF3432_pair/README.md:1)
- [A input_contract.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/templates/SSRF3432_pair/A_strong_authority/input_contract.json:1)
- [A prompt_contract.md](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/templates/SSRF3432_pair/A_strong_authority/prompt_contract.md:1)
- [B input_contract.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/templates/SSRF3432_pair/B_weak_authority/input_contract.json:1)
- [B prompt_contract.md](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/templates/SSRF3432_pair/B_weak_authority/prompt_contract.md:1)
- [C input_contract.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/templates/SSRF3432_pair/C_faulty_tool_injection/input_contract.json:1)
- [C prompt_contract.md](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/templates/SSRF3432_pair/C_faulty_tool_injection/prompt_contract.md:1)

## 9. 与已有实验线的关系

这份 `E3` runbook 的定位是：

- 不替代 `E1`
- 不重复 `E2`
- 不重复 `E4`

它专门补 `E1/E2/E4` 之间尚未拆开的那一段：

- 工具结论在 prompt 中是否获得了过强的默认可信度，
- 以至于模型虽然有能力解释目标链，却在高权威注入下停止主动修正。

如果 `E3` 支持这一点，后续更合理的方向将是：

- 调整静态工具输出在 workflow 中的权重与表述方式
- 让模型明确把 tool output 当作可质疑证据，而不是终局约束

而不是继续在同一权威形态里扩大 `candidate` 或增加更多局部代码片段。
