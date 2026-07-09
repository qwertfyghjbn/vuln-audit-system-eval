# M4 Prompt Contract Template

`M4_differential_free_auditor` 与 `M3_differential_target_context_constrained` 使用同一批上下文：

- 相同 `target-context memo`
- 相同原始 static-gated 输入摘录
- 相同 pair-level 目标语义

唯一变化是输出格式：

- 不再要求固定 JSON
- 改为自由文本 differential audit

这档回答的问题是：

> 如果去掉结构化输出约束，但保持相同信息量，模型是否会更稳定地恢复 `SSRF-3432 pair` 的差分解释？

提示词必须要求模型明确回答：

- `VULN` 侧为何成立
- `FIXED` 侧为何不再成立
- 最小语义差是什么
- 为什么这不是泛化 SSRF 面枚举

提示词必须继续禁止：

- 引入 `patch`、`diff`、官方修复说明
- 引入 `target_files`
- 引入 `E4` 的高信息 staging 内容
- 把 `FIXED no path` 当作充分答案

执行时建议使用：

- `python3 scripts/run_llm_prompt_capture.py`
- `system_prompt.txt`
- `user_prompt.txt`

执行后重点检查：

- 是否显式提到 `LoadJson -> SURL`
- 是否显式解释 `forbiddenURL()`、`isInUrlAllowList()`、`userinfo/@` 拒绝或等价 guard
- 是否仍被 `LEGACY`、`executeInclude()` 等 off-target finding 吸走
