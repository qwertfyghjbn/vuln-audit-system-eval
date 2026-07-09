# E4 SSRF-3432 DeepAudit D4 Runbook

## 1. 作用

这个 runbook 用于执行 `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED` 的 `E4 D4`：

- 有 `CVE` 高层描述
- 有真实 `VULN -> FIXED` patch/diff
- 有显式 `target_files`

它回答的问题是：

- `D3` 已证明 `diff` 本身不足以让 `DeepAudit` 稳定收敛到真实修复差分
- 在补上 `target_files` 之后，`DeepAudit` 是否开始把注意力收敛到真实修复文件，并表现出更强的 vulnerable/fixed 差分理解

## 2. 条件定义

### 2.1 D4

输入约束：

- 使用与 `D3` 同一层级的 curated subset repo
- 提供 repo 根目录的 `CVE_CONTEXT.md`
- 提供 repo 根目录的 `FIX_PATCH.diff`
- 在 task payload 中显式设置 `target_files`

`target_files` 只取真实 patch 改动文件：

- `src/net/sourceforge/plantuml/security/SURL.java`
- `src/net/sourceforge/plantuml/security/SecurityProfile.java`
- `src/net/sourceforge/plantuml/security/SecurityUtils.java`
- `src/net/sourceforge/plantuml/tim/stdlib/LoadJson.java`

不把 `TContext.java` 纳入 `target_files`，因为本轮要验证的是：

- 目标文件约束能否把模型从泛化入口枚举重新拉回到真实修复差分

## 3. 输入落点

- [AAE4_SSRF3432_VULN_D4.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/specs/AAE4_SSRF3432_VULN_D4.json:1)
- [AAE4_SSRF3432_FIXED_D4.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/specs/AAE4_SSRF3432_FIXED_D4.json:1)
- [VULN D4 staging](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/staging/SSRF-JA-REPO-CVE-2023-3432-VULN_D4/CVE_CONTEXT.md:1)
- [FIXED D4 staging](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/staging/SSRF-JA-REPO-CVE-2023-3432-FIXED_D4/CVE_CONTEXT.md:1)

## 4. 运行约束

真实 `DeepAudit` 连通性检查与 runner 启动都必须使用提权网络上下文，不得在默认沙箱里探测。

固定检查顺序：

1. `curl http://127.0.0.1:8000/health`
2. `curl http://localhost:8000/health`
3. `curl http://172.27.144.1:8000/health`

如果三者之一返回 `200`，优先使用第一个成功地址作为 backend。

## 5. 执行顺序

固定顺序：

1. `VULN D4`
2. `FIXED D4`

重点判断：

- `VULN D4` 是否比 `D3` 更接近 `userinfo/@ -> allowlist bypass` 这条修复差分
- `FIXED D4` 是否开始显式解释 “fixed side 为什么不再成立”

## 6. 完成后要写回哪里

本轮 `D4` 结果的主产物仍写入：

- `artifacts/architecture_attribution/E4/`

但结果解读需要回填到：

- [e1_static_gate_oracle_progress_report.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e1_static_gate_oracle_progress_report.md:1)

写法要求：

- 作为 `SSRF-3432 pair` 的 `E1` 后续分流记录
- 与 `D3` 并排比较，显式拆开 `diff` 与 `target_files` 的贡献
