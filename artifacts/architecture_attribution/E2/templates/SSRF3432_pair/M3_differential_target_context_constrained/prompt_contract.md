# M3 Prompt Contract Template

`M3_differential_target_context_constrained` 在 `M1_original` 的材料之上，只新增 pair-aware `target-context memo`，并把输出格式固定成 JSON：

- 保留 `M1` 的原始 static-gated 输入
- 新增 `target-context memo`
- 不加入 `source-window`
- 不允许自由文本发挥
- 不允许 agentic repo 检索

这档回答的问题是：

> 当模型被显式拉回 `SSRF-3432 pair` 的差分目标，同时仍然被约束在固定 JSON 输出里，是否已经足够恢复 pair-level differential reasoning？

`target-context memo` 允许包含：

- `family_id = SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED`
- `query_id = cwe-918wLLM`
- `LoadJson.path -> SURL -> URL constraint` 是共享目标链
- fixed-side 关注点是 “为什么不再成立”
- `E1` 的非结论性事实：
  `candidate` 已充分
  `LoadJson.path` 已物化过
  caller-side slice 已试过
- `E4` 的非结论性事实：
  注意力可被拉回 `LoadJson / SURL / SecurityProfile`
  freer auditor 仍未自然解释 fixed-side guard

`target-context memo` 禁止包含：

- `ground_truth.json`
- 标准答案文本
- `patch`、`diff`、官方修复说明
- `E4 D4 target_files` 原样清单
- “真实修复点就是 X” 这类结论性断言

JSON 输出至少要包含：

- `vulnerable_source_candidates`
- `vulnerable_sink_candidates`
- `fixed_guard_candidates`
- `vulnerable_path_hypothesis`
- `fixed_side_explanation`
- `minimal_semantic_delta`
- `why_fixed_not_just_no_path`
- `confidence`

执行时建议使用：

- `python3 scripts/run_llm_prompt_capture.py --expect-json`
- `system_prompt.txt`
- `user_prompt.txt`
