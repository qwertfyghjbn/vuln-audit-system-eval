# E2 实验报告：`partition_plus_relation + parent_only`

## 1. 实验目标

验证 ADR 0011 的第二步假设：

- 在 E1 已经完成 `scope-aligned parse` 的前提下
- 若给 OpenAnt arm 额外注入 `parent_only` relation
- 是否能修复剩余的 target 命中差异，或者至少缓解 `module-boundary` 带来的 candidate 丢失

本轮固定：

- `phase=partition_plus_relation`
- `emission_policy=candidate_only`
- `semantic_verification=disabled`
- `18` 个 Python case
- 三臂对照：
  - `v3-native`
  - `openant-projected`
  - `openant-parent`

## 2. 输入与校验

- manifest：`artifacts/unit_partition_controlled_eval/2026-06-30-e2/unit_partition_manifest.json`
- contract report：`artifacts/unit_partition_controlled_eval/2026-06-30-e2/unit_partition_contract_report.json`
- preflight：`artifacts/unit_partition_controlled_eval/2026-06-30-e2/unit_partition_preflight.json`
- report：`artifacts/unit_partition_controlled_eval/2026-06-30-e2/unit_partition_report.json`

校验结果：

- contract `valid`
- preflight `valid`
- `18 case / 3 arms / S1-S3 各 6`
- 无 warning，无 error

## 3. 总体结果

| arm | bound provider evidence | candidate | no matching unit |
|---|---:|---:|---:|
| `v3-native` | `18302` | `6813` | `0` |
| `openant-projected` | `18269` | `6600` | `33` |
| `openant-parent` | `18269` | `7142` | `33` |

核心观察：

- `openant-parent` 相比 `openant-projected`，只增加了 candidate 数，`bound_provider_evidence_count` 完全不变
- `33` 条 residual `no_matching_unit` 完全不变
- 说明 `parent_only` relation 无法修 parser omission，也无法修 module/top-level coverage gap

## 4. 按 strata 观察摘要

| stratum | arm | bound | candidate | no matching | target rank 变化 |
|---|---|---:|---:|---:|---|
| `S1` | `v3-native` | `7` | `6` | `0` | 六个 case 全部 `rank=1` |
| `S1` | `openant-projected` | `7` | `6` | `0` | 与 baseline 完全一致 |
| `S1` | `openant-parent` | `7` | `6` | `0` | 与 projected 完全一致 |
| `S2` | `v3-native` | `8` | `8` | `0` | `SSTI-PY-REPO-001`、`SSTI-PY-REPO-002` 均命中 |
| `S2` | `openant-projected` | `8` | `8` | `0` | `SSTI-PY-REPO-001` 仍无 target candidate |
| `S2` | `openant-parent` | `8` | `8` | `0` | 与 projected 完全一致 |
| `S3` | `v3-native` | `18287` | `6799` | `0` | `SSTI-PY-REPO-CVE-2024-45053-VULN rank=2323` |
| `S3` | `openant-projected` | `18254` | `6586` | `33` | `SSTI-PY-REPO-CVE-2024-45053-VULN rank=2319` |
| `S3` | `openant-parent` | `18254` | `7128` | `33` | `SSTI-PY-REPO-CVE-2024-45053-VULN rank=2798` |

按 strata 解读：

- `S1` 没有任何变化，说明 relation 注入对 file 级 case 没有增益
- `S2` 也没有变化，说明 relation 注入没有修复 `SSTI-PY-REPO-001` 的 pseudo-hit 消失
- 所有可见变化都集中在 `S3`

## 5. 关键 case 变化

### 5.1 `SSTI-PY-REPO-001`

三臂均为：

- `candidate_count=2`
- `openant-projected` 与 `openant-parent` 都没有 target candidate
- `parent_only` 没有把 `utils/template_utils.py:3` 的 module evidence 重新抬到 target 函数

结论：

- E2 再次支持 E1 的解释
- 该 case 仍应视为 `module-level candidate contamination`
- 不是缺一条 parent relation 就能修复的 target 丢失

### 5.2 `PT-PY-REPO-CVE-2024-32982-VULN`

- `openant-projected`：`candidate_count=1596`，`no_matching_unit=10`
- `openant-parent`：`candidate_count=1604`，`no_matching_unit=10`
- 仅新增 `8` 个 candidate；`target_candidate_rank` 仍为 `null`

### 5.3 `PT-PY-REPO-CVE-2024-32982-FIXED`

- `openant-projected`：`candidate_count=1600`，`no_matching_unit=10`
- `openant-parent`：`candidate_count=1608`，`no_matching_unit=10`
- 同样只新增 `8` 个 candidate；负样本状态不变

### 5.4 `SSTI-PY-REPO-CVE-2024-45053-VULN`

- `v3-native`：`target_candidate_rank=2323`
- `openant-projected`：`target_candidate_rank=2319`
- `openant-parent`：`target_candidate_rank=2798`

同时：

- `no_matching_unit` 仍是 `13`
- `bound_provider_evidence_count` 仍是 `9984`
- `relation_injected=7637`
- `candidate_count` 从 `3390` 增加到 `3916`

结论：

- `parent_only` relation 大量扩张了 candidate 空间
- 但没有修复 residual binding
- 反而把 target rank 拉坏

## 6. 结论

E2 给出的结论很直接：

1. `parent_only` relation 不能解决 E1 剩余的 `33` 条 residual `no_matching_unit`。
2. 它也不能恢复 `SSTI-PY-REPO-001` 的 target hit，因此不能推翻 E1 对该 case 的解释。
3. 在 `S3` 中，relation 注入主要表现为 candidate 膨胀，而不是 target 命中改善。
4. 对 `SSTI-PY-REPO-CVE-2024-45053-VULN`，它甚至带来明显副作用：`2319 -> 2798`。

因此，当前最稳的解释边界是：

> E1 后剩余的问题，主因仍是 `parser omission + module/top-level coverage gap`，而不是“缺少 parent relation”。`parent_only` relation 不足以成为默认修复方向，也不会推翻前面对 ADR 0011 的主结论。

## 7. 后续建议

- 主线不要继续扩 relation 注入策略
- parser 问题单独进入 `parser backlog`
- module / top-level coverage 问题单独进入 `adapter / module-span backlog`
- 如果还要继续 ADR 0011，下一步应基于 backlog 选择是否做小范围修复验证，而不是把 `parent_only` 并入主实验口径
