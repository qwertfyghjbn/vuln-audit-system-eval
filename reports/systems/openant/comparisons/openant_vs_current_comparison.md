# OpenAnt vs Current Comparison

轮次：`2026-06-28-round1`

## Step 6A

当前文件基于 OpenAnt `B1 parse + analyze` 与当前系统 `A1/A2` 基线，完成了首批 8 个 case 的 case-level 对齐打标。

compare_bucket 分布：

- `clean_negative`: 1
- `fp_offtarget`: 2
- `hit_vulnerable`: 2
- `miss_no_signal`: 3

## Step 6B

以下 case 来自 Step 6B / Step 8 的 Stage 2 回填结果：

- `PT-PY-FILE-001`: `confirmed_vulnerable` (confirmed=1, needs_review=0)
- `PT-PY-REPO-002`: `needs_review_only` (confirmed=0, needs_review=1)
- `SSTI-PY-REPO-001`: `confirmed_vulnerable` (confirmed=1, needs_review=0)
- `SSTI-PY-REPO-CVE-2024-45053-FIXED`: `mixed_confirmed_and_needs_review` (confirmed=13, needs_review=29)

## Taxonomy Summary

详细版本见 [openant_round1_failure_taxonomy.md](/home/lqs/llm_audit_system_learning/reports/systems/openant/summaries/openant_round1_failure_taxonomy.md:1)。基于当前 8 个 case，可把差异先收敛为 7 类：

- `T1_strict_semantic_veto_on_true_positive`
  - OpenAnt 已命中 GT anchor，但当前系统 strict 因 semantic gate 不发射。
  - 代表：`PT-PY-FILE-001`, `PT-PY-REPO-001`
- `T2_stage1_offtarget_on_true_vulnerable`
  - OpenAnt 在真实漏洞 case 上给出 `VULNERABLE`，但主 finding 不落在 GT anchor。
  - 代表：`SSRF-PY-REPO-001`, `SSTI-PY-REPO-001`, `SSRF-PY-REPO-CVE-2025-2828-VULN`
- `T3_stage1_clean_negative`
  - OpenAnt Stage1 在 near-miss 上保持 `SAFE`。
  - 代表：`SSRF-PY-REPO-002`
- `T4_stage1_false_positive_on_near_miss`
  - near-miss 上出现 off-target 危险 verdict，且不落在 guard scope。
  - 代表：`PT-PY-REPO-002`, `SSTI-PY-REPO-CVE-2024-45053-FIXED`
- `T5_stage2_prunes_but_does_not_reanchor`
  - Stage2 能降噪，但不会把 finding 自动迁回 benchmark target。
  - 代表：`PT-PY-REPO-002`, `SSTI-PY-REPO-001`
- `T6_large_repo_timeout_vs_broad_scan`
  - 当前系统在大仓库上更像 `timeout`；OpenAnt 更像“能跑完但结论很宽”。
  - 代表：`SSRF-PY-REPO-CVE-2025-2828-VULN`, `SSTI-PY-REPO-CVE-2024-45053-FIXED`
- `T7_provider_evidence_type_drift`
  - 当前系统把 Bandit 通用安全告警绑定成 benchmark 指定 vuln_type，造成上游类型漂移。
  - 代表：`PT-PY-FILE-001`, `PT-PY-REPO-002`, `SSTI-PY-REPO-001`

## Case Table

| Case | Label | Vuln Type | Current Strict | OpenAnt B1 Top | Anchor | Guard | Bucket | Stage2 | Confirmed | Review |
|------|-------|-----------|----------------|----------------|--------|-------|--------|--------|-----------|--------|
| `PT-PY-FILE-001` | `vulnerable` | `path_traversal` | `no_finding_emitted` | `VULNERABLE` | `Y` | `` | `hit_vulnerable` | `confirmed_vulnerable` | `1` | `0` |
| `PT-PY-REPO-001` | `vulnerable` | `path_traversal` | `no_finding_emitted` | `VULNERABLE` | `Y` | `` | `hit_vulnerable` | `not_selected` | `None` | `None` |
| `PT-PY-REPO-002` | `near_miss` | `path_traversal` | `clean_no_finding` | `VULNERABLE` | `` | `N` | `fp_offtarget` | `needs_review_only` | `0` | `1` |
| `SSRF-PY-REPO-001` | `vulnerable` | `ssrf` | `no_finding_emitted` | `VULNERABLE` | `N` | `` | `miss_no_signal` | `not_selected` | `None` | `None` |
| `SSRF-PY-REPO-002` | `near_miss` | `ssrf` | `clean_no_finding` | `SAFE` | `` | `N` | `clean_negative` | `not_selected` | `None` | `None` |
| `SSTI-PY-REPO-001` | `vulnerable` | `ssti` | `no_finding_emitted` | `VULNERABLE` | `N` | `` | `miss_no_signal` | `confirmed_vulnerable` | `1` | `0` |
| `SSRF-PY-REPO-CVE-2025-2828-VULN` | `vulnerable` | `ssrf` | `no_finding_emitted` | `VULNERABLE` | `N` | `` | `miss_no_signal` | `reserve_stage2` | `None` | `None` |
| `SSTI-PY-REPO-CVE-2024-45053-FIXED` | `near_miss` | `ssti` | `clean_no_finding` | `VULNERABLE` | `` | `N` | `fp_offtarget` | `mixed_confirmed_and_needs_review` | `13` | `29` |

## 后续实验优先级

### P0

- 在 `T1` 样本上做“strict gate 放松/移除”对照，优先看 `PT-PY-FILE-001` 与 `PT-PY-REPO-001`。目标是确认当前系统到底是“候选已存在但被 gate 压掉”，还是更早就没有正确候选。
- 在 `T7` 样本上检查 Bandit rule 到内部 `vuln_type` 的映射与 finding anchor 绑定。目标是先止住 `flask_debug_true -> path_traversal/ssti` 这类类型漂移。

### P1

- 对 `T2` 与 `T5` 样本，把“finding 是否成立”和“是否命中 benchmark anchor”拆成两个独立指标。优先看 `SSTI-PY-REPO-001`，因为它最能说明 OpenAnt Stage2 的边界是复核 finding，而不是重选 target。
- 对 `PT-PY-REPO-002` 继续保留 near-miss 复核，观察 OpenAnt Stage2 是否能稳定把 off-target 阳性压回 `clean_negative`，而不是停在 `needs_review`。

### P2

- 对 `T6` 样本单独记录吞吐与 precision 指标，包括总 unit 数、Stage1 vulnerable 数、Stage2 confirmed 数、top-k 是否命中 GT anchor。优先看 `SSRF-PY-REPO-CVE-2025-2828-VULN`。
- 若后续要扩到剩余 10 个 Python case，建议先复用当前 taxonomy 打标，而不是先扩展新的判定维度。这样能保证下一轮结果与本轮直接可比。
