# SSRF-3432 Pair E2 Templates

这个目录存放 `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED` 的 `E2 differential freedom ladder` 模板文件。

用途：

- 作为 [e2_ssrf3432_pair_differential_freedom_ladder_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e2_ssrf3432_pair_differential_freedom_ladder_runbook.md:1) 的默认模板入口
- 供后续实际运行时复制到 `artifacts/architecture_attribution/E2/<run_id>/.../<mode>/`

当前模板覆盖：

- `M1_original`
- `M3_differential_target_context_constrained`
- `M4_differential_free_auditor`
- `M5_differential_agentic_auditor`

本轮不提供 `M2` 模板，因为 `SSRF-3432 pair` 的 `E2` 第一轮明确跳过 `M2`。
