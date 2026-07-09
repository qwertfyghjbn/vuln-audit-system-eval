# M5 Prompt Contract Template

`M5_differential_agentic_auditor` 以 `M4_differential_free_auditor` 的同一批起始 bundle 作为输入，并额外允许受控检索：

- 起始 bundle 与 `M4` 相同
- 新增一个 `phase1` 检索决策步骤
- 允许从预先列出的目标文件里请求额外文件
- 只允许扩展到直接 caller/callee 或解释 fixed guard 必需的相邻文件
- `phase2` 再基于起始 bundle 与检索结果输出最终 differential audit

这档回答的问题是：

> 如果允许有限的 repo 内主动检索，模型是否需要额外文件才能恢复 `SSRF-3432 pair` 的 fixed-side guard 解释？

默认允许文件：

- `src/net/sourceforge/plantuml/tim/stdlib/LoadJson.java`
- `src/net/sourceforge/plantuml/security/SURL.java`
- `src/net/sourceforge/plantuml/security/SecurityProfile.java`
- `src/net/sourceforge/plantuml/security/SecurityUtils.java`

默认预算：

- 最多请求 `4` 个文件

提示词必须继续禁止：

- 读取 `ground_truth.json`
- 读取 answer-bearing `README`
- 引入 `E4` 的高信息 `CVE_CONTEXT` 或 `target_files`
- 直接引入 patch、diff、官方修复说明

执行时建议使用两次调用：

1. `phase1_system_prompt.txt` + `phase1_user_prompt.txt`
   输出 JSON 检索决策
2. `phase2_system_prompt.txt` + `phase2_user_prompt.txt`
   输出最终自由文本差分审计结果

执行后必须保存：

- `tool_trace.json`
- `opened_files.txt`
- `context_volume.json`
- `new_files_beyond_M4.txt`

最终结果仍必须回答：

- `VULN` 侧为何成立
- `FIXED` 侧为何不再成立
- 最小语义差是什么
- 成功是否依赖额外上下文获取
