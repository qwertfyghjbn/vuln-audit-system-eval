# SSRF-3432 Pair E3 Templates

这个目录存放 `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED` 的 `E3 tool authority ablation` 模板文件。

用途：

- 作为 [e3_ssrf3432_pair_tool_authority_ablation_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e3_ssrf3432_pair_tool_authority_ablation_runbook.md:1) 的默认模板入口
- 供后续实际运行时复制到 `artifacts/architecture_attribution/E3/<run_id>/.../<mode>/`

当前模板覆盖：

- `A_strong_authority`
- `B_weak_authority`
- `C_faulty_tool_injection`

这三档共用同一 `SSRF-3432 pair` 差分目标语义，只改变工具权威的注入强度和表述方式。
