# M1 Prompt Contract Template

`M1_original` 保持 `IRIS-style static-gated workflow` 的原始表示，不做任何 `E2` differential 强化：

- 只使用原始 Stage 3 API candidates 与原始 source function parameter candidates
- 不额外加入 `source-window`
- 不加入 `target-context memo`
- 不允许自由文本漏洞路径解释
- 不允许 agentic repo 遍历

这档只回答一个问题：

> 在完全原始的 structured-label workflow 下，`SSRF-3432 pair` 是否仍然停在错误 source 或 `source=0/path=0`，并且无法恢复 pair-level differential semantics？

提示词必须保持以下约束：

- 不显式告诉模型真实修复点
- 不引入 `patch`、`diff`、`target_files`
- 不引入 `E4` 的高信息 `CVE_CONTEXT`
- 不允许把 `FIXED no path` 直接解释成理解了修复

执行时应使用：

- 原始 `IRIS` Stage 3 输入物化
- 原始 structured-label 输出格式

执行后重点检查：

- 是否识别 `LoadJson.path` 或仍停在错误 source
- 是否识别 `SURL` 相关 sink 或仍然偏离目标链
- 是否完全没有 fixed-side guard 解释能力
