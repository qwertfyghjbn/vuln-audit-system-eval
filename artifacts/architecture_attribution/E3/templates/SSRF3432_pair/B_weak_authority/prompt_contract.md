# `B_weak_authority` Prompt Contract

这档与 `A_strong_authority` 使用同一批 pair-local 证据，但去掉强 `no path` 权威措辞。

输入应包含：

- 与 `A` 相同的 pair-local 代码窗口
- 与 `A` 相同的 source/sink/guard candidates
- 与 `A` 相同的 `M1` 失败背景

唯一变化是：

- 不再把工具输出表述成近似最终结论
- 明确提示：
  候选列表只是辅助，不是完整 oracle
  不要假设静态分析完整

这档回答的问题是：

> 如果保留同样的信息量，但降低工具权威强度，模型是否会更主动地补全 `LoadJson.path`、`SURL.getBytes()` 和 fixed-side guard？

输出建议使用自由文本审计说明，并至少覆盖：

- 是否挑战工具输出不完整
- 是否恢复 `LoadJson -> SURL` 目标链
- 是否解释 `forbiddenURL()`、`isInUrlAllowList()`、`userinfo/@` guard
- 是否区分这不是 generic SSRF 面枚举
