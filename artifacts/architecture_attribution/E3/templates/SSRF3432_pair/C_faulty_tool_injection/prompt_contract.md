# `C_faulty_tool_injection` Prompt Contract

这档与 `B_weak_authority` 共享同一批 pair-local 代码窗口与目标链上下文，但故意注入一份不完整或偏置的工具候选列表。

faulty injection 至少应满足以下一类：

- 漏掉 `LoadJson.path` 或等价 source
- 漏掉 `SURL.getBytes()` 或等价网络 sink
- 漏掉 `forbiddenURL()` / `isInUrlAllowList()` 一类 fixed guard

提示词必须明确允许模型：

- 指出工具列表不完整
- 主动补全缺失 source / sink / guard
- 挑战工具结论，而不是机械复述

提示词必须继续禁止：

- `ground_truth.json`
- 标准答案文本
- patch、diff、官方修复说明
- `E4 D4 target_files`

这档回答的问题是：

> 当工具输出本身存在明显缺口时，模型是否会显式反驳并补全关键语义，还是仍然被工具形态牵着走？

输出建议至少覆盖：

- `tool_output_challenged`
- `recovered_missing_source`
- `recovered_missing_sink`
- `recovered_missing_guard`
- `vulnerable_path_explained`
- `fixed_guard_explained`
