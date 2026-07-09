# IRIS 对比诊断实验 1 结果总结

## 1. 文档定位

这份文档记录 [iris_contrast_diagnostic_plan.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_diagnostic_plan.md:1) 中实验 1 的结果。

它回答的问题是：

> 在同一冻结运行边界下，`OFFICIALSMOKE01` 与 `DEEPSEEK_SELF01` 这 `3 对 3` 对应 case 的差异，主要发生在 candidate、label、path，还是缓存/解析干扰层？

这不是新的运行批次，也不是能力改动结果。

## 2. 证据范围

主证据：

- 对比矩阵：
  - [iris_contrast_exp1_matrix.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_contrast_exp1_matrix.tsv:1)
- 官方线基线：
  - [canonical_results.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:1)
  - [OFFICIALSMOKE01/summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_smoke/OFFICIALSMOKE01/summary.tsv:1)
- 自有线首轮：
  - [DEEPSEEK_SELF01/summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/summary.tsv:1)
  - [iris_self_first_round_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_self_first_round_results.md:1)

## 3. 先给结论

1. `PT` 的主要分叉层不是 path，而是 `sink completeness layer`。
   - 自有线已经把 `source` 从 `0` 恢复到 `6`
   - 但 `sink` 仍然是 `0`
   - 因此当前不该把 `PT` 写成 `path non-connectivity`

2. `SSRF vuln` 的主要分叉层已经进入 `path connectivity layer`。
   - 自有线把 `source` 从 `0` 恢复到 `1`
   - `sink` 仍然存在
   - 但 `paths` 仍是 `0`
   - 这说明下一步最值得做的是配对 `path non-connectivity diagnosis`

3. `SSRF fixed` 也应归入 `path connectivity layer`，并与 `SSRF vuln` 等深度同检。
   - 官方线存在 `shared_cwe_cache_reused_71_candidates`
   - 自有线去掉共享缓存后，最终仍是 `0 paths`
   - 所以共享缓存是一个真实差异，但不是足以单独解释最终失败的主层

4. 解析噪声不是当前最主要的分叉解释。
   - 官方线 3 条都是 `parse_errors=0`
   - 自有 SSRF 两条分别是 `1` 和 `2`
   - 但两侧最终都仍然 `0 paths`

## 4. 对比矩阵

完整矩阵见 [iris_contrast_exp1_matrix.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_contrast_exp1_matrix.tsv:1)。

这里给出可直接阅读的核心版本：

| case_pair | official | self | primary_break_layer | next_diagnostic_action |
|---|---|---|---|---|
| `PT-JA-REPO-CVE-2024-53677` | `candidates=19, source=0, sink=0, tp=4, paths=0` | `candidates=25, source=6, sink=0, tp=5, paths=0` | `sink_completeness_layer` | 进入实验 3 |
| `SSRF-JA-REPO-CVE-2023-3432-VULN` | `candidates=71, source=0, sink=6, tp=16, paths=0` | `candidates=77, source=1, sink=6, tp=15, paths=0` | `path_connectivity_layer` | 进入实验 2 |
| `SSRF-JA-REPO-CVE-2023-3432-FIXED` | `candidates=72, source=0, sink=6, tp=16, paths=0, shared_cache=yes` | `candidates=78, source=0, sink=6, tp=11, paths=0, shared_cache=no` | `path_connectivity_layer` | 进入实验 2 |

## 5. 三条 pair 的判定理由

### 5.1 `PT-JA-REPO-CVE-2024-53677`

关键证据：

- 官方：
  - [canonical row](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:4)
  - [official Stage 3](/home/lqs/llm_audit_system_learning/artifacts/iris_smoke/OFFICIALSMOKE01/PT-JA-REPO-CVE-2024-53677-VULN/command.stdout.log:22)
  - [official labels](/home/lqs/llm_audit_system_learning/artifacts/iris_smoke/OFFICIALSMOKE01/PT-JA-REPO-CVE-2024-53677-VULN/command.stdout.log:23)
- 自有：
  - [self summary row](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/summary.tsv:2)
  - [self Stage 3](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/fetch_build/command.stdout.log:22)
  - [self labels](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/fetch_build/command.stdout.log:23)

判定理由：

1. 自有线已经恢复出 `source=6`，所以差异不再是“完全没有 source”。
2. 但 `official` 与 `self` 两侧都还是 `sink=0`。
3. 因此主分叉层应写成：
   - `sink_completeness_layer`
4. 下一步不该进入 path 断连诊断，而应直接进入 `PT` 的 `sink completeness diagnosis`。

### 5.2 `SSRF-JA-REPO-CVE-2023-3432-VULN`

关键证据：

- 官方：
  - [canonical row](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:5)
  - [official Stage 3](/home/lqs/llm_audit_system_learning/artifacts/iris_smoke/OFFICIALSMOKE01/SSRF-JA-REPO-CVE-2023-3432-VULN/command.stdout.log:18)
  - [official labels](/home/lqs/llm_audit_system_learning/artifacts/iris_smoke/OFFICIALSMOKE01/SSRF-JA-REPO-CVE-2023-3432-VULN/command.stdout.log:19)
- 自有：
  - [self summary row](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/summary.tsv:3)
  - [self Stage 3](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/fetch_build/command.stdout.log:18)
  - [self parse fallback](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/fetch_build/command.stdout.log:20)
  - [self labels](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/fetch_build/command.stdout.log:21)

判定理由：

1. 自有线把 `source` 从 `0` 提升到了 `1`。
2. `sink` 在两侧都已存在，`tp` 也只小幅变化。
3. 但 `paths` 仍然是 `0`。
4. 所以当前主分叉层已经不是 candidate 缺失，而是：
   - `path_connectivity_layer`
5. 下一步应进入 `SSRF vuln/fixed` 配对 `path non-connectivity diagnosis`。

### 5.3 `SSRF-JA-REPO-CVE-2023-3432-FIXED`

关键证据：

- 官方：
  - [canonical row](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:6)
  - [official cached stage 3](/home/lqs/llm_audit_system_learning/artifacts/iris_smoke/OFFICIALSMOKE01/SSRF-JA-REPO-CVE-2023-3432-FIXED/command.stdout.log:18)
  - [official labels](/home/lqs/llm_audit_system_learning/artifacts/iris_smoke/OFFICIALSMOKE01/SSRF-JA-REPO-CVE-2023-3432-FIXED/command.stdout.log:19)
- 自有：
  - [self summary row](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/summary.tsv:4)
  - [self Stage 3](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/fetch_build/command.stdout.log:18)
  - [self parse fallback 1](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/fetch_build/command.stdout.log:20)
  - [self parse fallback 2](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/fetch_build/command.stdout.log:22)
  - [self labels](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/fetch_build/command.stdout.log:23)

判定理由：

1. 官方 fixed 存在显式共享缓存：
   - `#Cached: 71`
2. 自有 fixed 是 per-case 独立 run，没有共享缓存。
3. 但两侧最终都是 `0 paths`。
4. 因此共享缓存是一个要保留记录的差异，但当前不足以成为主断点层。
5. 更合理的主层仍然是：
   - `path_connectivity_layer`
6. 这条 case 必须与 `SSRF vuln` 等深度进入实验 2。

## 6. 批次级判断

实验 1 现在已经能给出 3 个稳定判断：

1. `PT` 和两条 `SSRF` 不能再用同一种失败语义概括。
   - `PT` 是 `sink completeness` 问题
   - `SSRF` 是 `path connectivity` 问题

2. `shared cache` 与 `parse noise` 都是真实现象，但都不是当前最主要的批次级解释。
   - `shared cache` 只在 `official SSRF fixed` 上出现
   - `parse noise` 只在 `self SSRF` 两条上出现
   - 但两侧最终都还是 `0 paths`

3. 因此，实验 2 和实验 3 的进入条件已经满足：
   - `SSRF vuln/fixed` 进入配对 `path non-connectivity diagnosis`
   - `PT` 进入 `sink completeness diagnosis`

## 7. 实验 1 的退出结论

按 [iris_contrast_diagnostic_plan.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_diagnostic_plan.md:1) 的定义，实验 1 已经完成了它的退出条件：

1. `3` 条 `case_pair` 的硬字段已填齐
2. 每条 `case_pair` 已给出唯一 `primary_break_layer`
3. 已明确后续动作：
   - `SSRF vuln/fixed` -> 实验 2
   - `PT` -> 实验 3

## 8. 一句话结论

实验 1 证明：

> 当前官方线与自有线的主要分叉不是统一发生在同一层；`PT` 的主问题是 `sink completeness`，而 `SSRF vuln/fixed` 的主问题已经进入 `path connectivity` 层。
