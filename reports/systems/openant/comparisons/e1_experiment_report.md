# ADR 0011 E1 实验结果报告

## 1. 实验目标

E1 固定为：

- `phase=partition_only`
- `emission_policy=candidate_only`
- OpenAnt parse 改为 `skip_tests=false`

目标是先去掉两类干扰：

- `balanced` policy 带来的 finding emission 噪声
- OpenAnt parse `skip_tests=true` 带来的 `parse scope mismatch`

这样本轮只回答一个问题：在 `shared provider evidence` 不变的前提下，OpenAnt projected partition 的 `binding / candidate / ranking` 效用是否还存在稳定差异。

## 2. 本轮产物

- OpenAnt E1 parse：
  - `artifacts/openant_eval/2026-06-30-e1-scope-aligned/`
- parse 状态摘要：
  - `artifacts/openant_eval/2026-06-30-e1-scope-aligned/manifests/parse_status_summary.json`
- unit catalog：
  - `artifacts/unit_partition_compare/2026-06-30-e1/normalized_units_v3.jsonl`
  - `artifacts/unit_partition_compare/2026-06-30-e1/normalized_units_openant.jsonl`
- roster：
  - `artifacts/unit_partition_controlled_eval/2026-06-30-e1/python_18_case_roster.json`
- manifest / contract / preflight：
  - `artifacts/unit_partition_controlled_eval/2026-06-30-e1/unit_partition_manifest.json`
  - `artifacts/unit_partition_controlled_eval/2026-06-30-e1/unit_partition_contract_report.json`
  - `artifacts/unit_partition_controlled_eval/2026-06-30-e1/unit_partition_preflight.json`
- 正式实验报告：
  - `artifacts/unit_partition_controlled_eval/2026-06-30-e1/unit_partition_report.json`

## 3. 执行备注

- 18 个 case 的 OpenAnt parse 最终全部成功。
- `parse_status_summary.json` 显示：
  - `success_count=18`
  - `skip_tests_false_count=18`
- `SSTI-PY-REPO-CVE-2024-45053-{VULN,FIXED}` 在批处理第一次运行时被 `auto` 误判成 `javascript`，触发 JS parser lock 文件写入失败。
- 这两个 case 已单独按 `--language python` 重跑；最终 E1 使用的是重跑后的成功产物。

## 4. 总体结果

### 4.1 全局 aggregate

| 指标 | V3 baseline | OpenAnt E1 | 观察 |
|---|---:|---:|---|
| `provider_evidence_count` | `18302` | `18302` | shared input 完全一致 |
| `bound_provider_evidence_count` | `18302` | `18269` | OpenAnt 仅少 `33` 条，缺口约 `0.18%` |
| `candidate_count` | `6813` | `6600` | OpenAnt 略少 `213` 个 candidate |
| `emitted_finding_count` | `0` | `0` | 符合 `candidate_only` 设计 |

### 4.2 按 strata 摘要

| stratum | V3 `bound` | OpenAnt `bound` | V3 `candidate` | OpenAnt `candidate` | V3 `target rank hit cases` | OpenAnt `target rank hit cases` |
|---|---:|---:|---:|---:|---:|---:|
| `S1` | `7` | `7` | `6` | `6` | `6/6` | `6/6` |
| `S2` | `8` | `8` | `8` | `8` | `2/6` | `1/6` |
| `S3` | `18287` | `18254` | `6799` | `6586` | `1/6` | `1/6` |

解释边界：

- `S1` 已经完全对齐，E1 没有暴露新的 partition 问题。
- `S3` 的主导问题已不再是 `skip_tests=true` 导致的大面积失配。
- `S2` 仍然保留 `1` 个 target rank hit 差异，具体就是 `SSTI-PY-REPO-001`。

## 5. 重点 Case 复核

### 5.1 `PT-PY-REPO-CVE-2024-32982-VULN`

| arm | round2 `bound` | E1 `bound` | round2 `candidate` | E1 `candidate` | round2 `no_matching_unit` | E1 `no_matching_unit` |
|---|---:|---:|---:|---:|---:|---:|
| `v3-native` | `4140` | `4140` | `1699` | `1699` | `0` | `0` |
| `openant-projected` | `58` | `4130` | `46` | `1596` | `4082` | `10` |

结论：

- round2 里 OpenAnt 的 binding 崩塌基本被消掉了。
- 这证明前一轮主导差异确实来自 `skip_tests=true`，不是 target method 的 partition fidelity。
- 但两侧仍然都没有 target candidate，因此这个 case 现在也不能反证 OpenAnt 更优。

### 5.2 `PT-PY-REPO-CVE-2024-32982-FIXED`

| arm | round2 `bound` | E1 `bound` | round2 `candidate` | E1 `candidate` | round2 `no_matching_unit` | E1 `no_matching_unit` |
|---|---:|---:|---:|---:|---:|---:|
| `v3-native` | `4150` | `4150` | `1703` | `1703` | `0` | `0` |
| `openant-projected` | `58` | `4140` | `46` | `1600` | `4092` | `10` |

结论：

- FIXED 侧和 VULN 侧同样完成了 scope 对齐。
- 这进一步确认 round2 的问题是 parse coverage，而不是漏洞语义差异。

### 5.3 `SSTI-PY-REPO-CVE-2024-45053-VULN`

| arm | round2 `bound` | E1 `bound` | round2 `candidate` | E1 `candidate` | round2 `target rank` | E1 `target rank` |
|---|---:|---:|---:|---:|---:|---:|
| `v3-native` | `9997` | `9997` | `3397` | `3397` | `2323` | `2323` |
| `openant-projected` | `127` | `9984` | `109` | `3390` | `17` | `2319` |

结论：

- round2 中 OpenAnt `2323 -> 17` 的表面大幅提升在 E1 里消失了。
- scope 对齐后，OpenAnt 与 V3 的 target rank 基本回到同一量级：`2319 vs 2323`。
- 因此这个 case 不再支持“OpenAnt partition 在大仓库 ranking 上明显更优”的说法。

### 5.4 `SSTI-PY-REPO-001`

| arm | round2 `target rank` | E1 `target rank` | round2 `candidate` | E1 `candidate` |
|---|---:|---:|---:|---:|
| `v3-native` | `1` | `1` | `2` | `2` |
| `openant-projected` | `null` | `null` | `2` | `2` |

结论：

- 这个差异在 E1 中完全保留，没有被 `candidate_only` 或 `skip_tests=false` 消掉。
- 因此它仍然是当前唯一保留下来的“partition boundary 可能影响 target hit”的弱信号。
- 结合上一轮人工复核，这个信号仍更接近“V3 宽 module unit 制造伪 target hit”，而不是“OpenAnt 丢掉真实 hit”。

## 6. E1 之后可以成立的结论

本轮可以成立的只有以下几点：

- E1 成功去掉了 round2 中最明显的 `parse scope mismatch`。
- `PT-PY-REPO-CVE-2024-32982-{VULN,FIXED}` 不再能被解释成 OpenAnt 的大幅 partition 退化。
- `SSTI-PY-REPO-CVE-2024-45053-VULN` 不再能被解释成 OpenAnt 的大幅 ranking 增益。
- `candidate_only` 下，两侧 finding emission 全部归零，说明后续如果还要比较 audit utility，必须显式切回其他 policy，而不能混用本轮结果。

## 7. E1 之后仍不能成立的结论

以下判断在 E1 之后仍然不能成立：

- `OpenAnt partition 明显优于 V3`
- `OpenAnt partition 明显劣于 V3`
- `S3 已经给出稳定迁移证据`
- `当前就可以进入 E2 并直接做强迁移结论`

原因很直接：

- 目前仍有 `33` 条 residual `no_matching_unit`
- `SSTI-PY-REPO-001` 的弱信号还需要继续单独解释
- 本轮只回答了 `partition_only + candidate_only`，还没有覆盖 relation 增益

## 8. 阶段性结论

E1 的主要价值不是证明 OpenAnt 更强，而是把 round2 的两个伪信号清掉：

- `PT-PY-REPO-CVE-2024-32982-*` 的“巨大退化”被证实主要来自 `skip_tests=true`
- `SSTI-PY-REPO-CVE-2024-45053-VULN` 的“巨大增益”被证实主要来自候选池被错误缩小

因此，E1 之后最保守、也是当前最稳的结论应为：

> `partition_only + candidate_only + scope-aligned parse` 已经证明，round2 中最显著的正负差异主要是实验口径问题，不是稳定的 unit partition 增益或退化。当前仍然保留下来的差异，只有 `SSTI-PY-REPO-001` 这一条弱 module-boundary 信号，以及 `33` 条 residual `no_matching_unit` 需要继续归因。

## 9. 下一步建议

在进入 E2 之前，建议先补一个很小的 E1.5：

- 逐条审计这 `33` 条 residual `no_matching_unit`
- 确认它们是路径归一化、非 Python 证据，还是 OpenAnt parse 仍缺少某些可绑定 unit
- 对 `SSTI-PY-REPO-001` 再做一次 candidate 级人工复核，确认它是否足以作为 module-boundary 设计的保留信号

如果这两步没有引出新的大口径问题，再进入 `partition_plus_relation` 才有意义。
