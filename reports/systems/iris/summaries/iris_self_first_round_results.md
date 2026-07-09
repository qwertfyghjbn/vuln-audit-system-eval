# IRIS 自有对照线首轮结果总结

## 1. 文档定位

这份文档总结 `DEEPSEEK_SELF01` 这一轮自有对照线首轮运行的结果。

它回答的问题是：

> 在与官方行为线相同的 `iris-runtime-compat-001 + DeepSeek` 运行边界下，3 个冻结自有 case 单独各跑 1 轮之后，`IRIS` 实际表现出了什么结果形态？

这不是能力改动实验总结，也不是官方可信性总报告。

## 2. 证据范围

主证据：

- 批次目录：
  - [DEEPSEEK_SELF01/README.md](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/README.md:1)
- 批次摘要：
  - [DEEPSEEK_SELF01/summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/summary.tsv:1)
  - [DEEPSEEK_SELF01/run_manifest.json](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/run_manifest.json:1)
- 3 个 case 的首轮归档：
  - [PT case](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/README.md:1)
  - [SSRF vuln case](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/README.md:1)
  - [SSRF fixed case](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/README.md:1)
- 官方行为线对照基线：
  - [canonical_results.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:1)
  - [iris_official_behavior_stage_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_official_behavior_stage_summary.md:1)

## 3. 先给结论

1. `DEEPSEEK_SELF01` 的 3 个自有 case 都完成了单独首轮运行，并且都走到了 `Stage 9`。
2. 两个 vulnerable case 仍然都没有形成最终漏洞路径：
   - `PT-JA-REPO-CVE-2024-53677-VULN` 是 `source` 已出现，但 `sink=0`
   - `SSRF-JA-REPO-CVE-2023-3432-VULN` 是 `source/sink` 都出现，但 `paths=0`
3. `SSRF-JA-REPO-CVE-2023-3432-FIXED` 这一条 fixed 控制组也保持 `paths=0`，本轮没有出现误报命中。
4. 和 `OFFICIALSMOKE01` 相比，这轮“单 case 独立运行”最明显的变化不是最终结果，而是 Stage 3 标签形状：
   - `PT` 从 `source=0` 变成了 `source=6`
   - `SSRF vuln` 从 `source=0` 变成了 `source=1`
   - 但这些变化都没有把最终结果从 `no_signal` 推到“形成有效路径”
5. 因此，这轮自有线首轮已经足够说明：
   - 这 3 个自有 case 的当前主要问题不再只是“完全没有标签”
   - 更准确的症状是“即使局部标签恢复，最终路径仍然不成立”

## 4. 批次级结果

批次摘要 [summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/summary.tsv:1) 当前记录为：

| case | run_id | run_status | system_verdict | target_match | failure_reason |
|---|---|---|---|---|---|
| `PT-JA-REPO-CVE-2024-53677-VULN` | `DEEPSEEK_SELF01__pt53677_r1` | `completed` | `no_signal` | `no` | `missing_sink_and_no_path` |
| `SSRF-JA-REPO-CVE-2023-3432-VULN` | `DEEPSEEK_SELF01__ssrf3432_vuln_r1` | `completed` | `no_signal` | `no` | `no_path_after_partial_source_sink_labelling` |
| `SSRF-JA-REPO-CVE-2023-3432-FIXED` | `DEEPSEEK_SELF01__ssrf3432_fixed_r1` | `completed` | `target_match` | `yes` | `none` |

这里的 `target_match` 对 fixed case 不是“命中漏洞”，而是“作为 near-miss / fixed 对照组，保持零路径，行为符合预期”。

## 5. 个案结果

### 5.1 `PT-JA-REPO-CVE-2024-53677-VULN`

首轮归档结果：

- 运行记录：`DEEPSEEK_SELF01__pt53677_r1`
- 批次摘要：`candidates=25; sources=6; sinks=0; tp=5; posthoc_paths=0`
- 关键日志：
  - [Stage 3 入口](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/fetch_build/command.stdout.log:21)
  - [Stage 3 标签统计](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/fetch_build/command.stdout.log:23)
  - [Stage 7 零路径](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/fetch_build/command.stdout.log:48)
  - [Stage 9](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/fetch_build/command.stdout.log:55)

本轮可直接写出的观察：

1. 这条 PT 线已经不是 `source=0`。
   - 当前出现了 `6` 个 `source` 标签。

2. 但它仍然没有形成最终结果。
   - `sink=0`
   - `Original #alarms: 0; Original #paths: 0`

3. 因此，这条 case 的当前失败形状更精确地说是：
   - `source recovered, but sink missing`

### 5.2 `SSRF-JA-REPO-CVE-2023-3432-VULN`

首轮归档结果：

- 运行记录：`DEEPSEEK_SELF01__ssrf3432_vuln_r1`
- 批次摘要：`candidates=77; sources=1; sinks=6; tp=15; stage3_json_parse_errors=1; posthoc_paths=0`
- 关键日志：
  - [Stage 3 入口](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/fetch_build/command.stdout.log:17)
  - [Stage 3 解析回退](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/fetch_build/command.stdout.log:20)
  - [Stage 3 标签统计](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/fetch_build/command.stdout.log:21)
  - [Stage 7 零路径](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/fetch_build/command.stdout.log:45)
  - [Stage 9](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-VULN/fetch_build/command.stdout.log:52)

本轮可直接写出的观察：

1. 这条 SSRF vuln 线已经不是“完全没有 source”。
   - 当前出现了 `1` 个 `source` 标签。

2. 但 `source + sink + taint-propagator` 同时存在，仍然没有形成路径。
   - `sources=1`
   - `sinks=6`
   - `tp=15`
   - `paths=0`

3. 这说明当前瓶颈至少已经不是“Stage 3 完全空输出”。
   - 更接近“局部语义恢复后，查询组装或路径连通性仍不成立”。

### 5.3 `SSRF-JA-REPO-CVE-2023-3432-FIXED`

首轮归档结果：

- 运行记录：`DEEPSEEK_SELF01__ssrf3432_fixed_r1`
- 批次摘要：`candidates=78; sources=0; sinks=6; tp=11; stage3_json_parse_errors=2; posthoc_paths=0`
- 关键日志：
  - [Stage 3 入口](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/fetch_build/command.stdout.log:17)
  - [Stage 3 解析回退 1](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/fetch_build/command.stdout.log:20)
  - [Stage 3 解析回退 2](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/fetch_build/command.stdout.log:22)
  - [Stage 3 标签统计](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/fetch_build/command.stdout.log:23)
  - [Stage 7 零路径](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/fetch_build/command.stdout.log:47)
  - [Stage 9](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/SSRF-JA-REPO-CVE-2023-3432-FIXED/fetch_build/command.stdout.log:54)

本轮可直接写出的观察：

1. fixed 控制组保持了 `0` 条最终路径。
2. 它和 vuln case 一样拿到了 `sink` 与 `taint-propagator`，但仍然没有形成结果。
3. 这意味着：
   - 当前系统还没有表现出“轻易把 fixed 对照组也打成漏洞”的误报趋势
   - 但也同时说明，单看 `sink` 或 `tp` 数量并不能推断最终是否会形成有效漏洞路径

## 6. 和 `OFFICIALSMOKE01` 的直接对照

官方行为线基线 [canonical_results.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:1) 中，同三条 case 的记录分别在：

- [PT line](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:4)
- [SSRF vuln line](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:5)
- [SSRF fixed line](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:6)

把两轮放在一起看：

| case | OFFICIALSMOKE01 | DEEPSEEK_SELF01 r1 | 差异含义 |
|---|---|---|---|
| `PT-JA-REPO-CVE-2024-53677-VULN` | `filtered=19, source=0, sink=0, tp=4, paths=0` | `filtered=25, source=6, sink=0, tp=5, paths=0` | 单独运行后 `source` 明显恢复，但仍卡在 `sink=0` |
| `SSRF-JA-REPO-CVE-2023-3432-VULN` | `filtered=71, source=0, sink=6, tp=16, paths=0` | `filtered=77, source=1, sink=6, tp=15, paths=0` | 单独运行后 `source` 从 `0` 升到 `1`，但仍未成路径 |
| `SSRF-JA-REPO-CVE-2023-3432-FIXED` | `filtered=72, source=0, sink=6, tp=16, paths=0; shared_cwe_cache_reused_71_candidates` | `filtered=78, source=0, sink=6, tp=11, paths=0` | 独立 run 去掉共享缓存后，仍然保持零路径 |

这里最重要的不是“最终 verdict 变了”，而是：

1. `DEEPSEEK_SELF01` 通过每 case 独立 `run_id`，消除了 `OFFICIALSMOKE01` 那种同 `CWE` 批处理共享缓存的影响。
2. 在这种更干净的单 case 运行方式下：
   - `PT` 与 `SSRF vuln` 的 `source` 数量都上升了
   - 但最终结果依旧是 `0 paths`
3. 所以当前自有线的主要结论不是“缓存导致了全部失败”，而是：
   - 即使去掉共享缓存并恢复一部分 `source`，系统仍然没有稳定形成目标路径

## 7. 当前能回答的问题

基于这一轮首轮结果，现在已经可以回答：

1. 这 3 个自有 case 是否都已经在冻结边界下跑完 1 轮？
   - 可以。答案是：都已完成，并且都到达 `Stage 9`。

2. 自有线当前是否还停留在“完全没有 Stage 3 标签”的老失败形状？
   - 不可以这样说。
   - `PT` 和 `SSRF vuln` 都已经出现了 `source`。

3. vulnerable case 当前是否已经恢复到能形成最终路径？
   - 还没有。

4. fixed 控制组当前是否出现明显误报？
   - 没有。

## 8. 当前不能过度宣称的事项

以下结论当前还不能写得过强：

1. 不能说这 3 个自有 case 已经证明 `IRIS` 完全不适合自有评估集。
   - 当前只完成了首轮，不是多轮分布实验。

2. 不能把 `PT` 或 `SSRF vuln` 的 `source` 恢复直接解释成“问题已接近解决”。
   - 因为最终仍然是 `0 paths`。

3. 不能把 fixed 控制组这 1 轮零路径直接解读成“误报风险已经很低”。
   - 当前只是说明本轮没有出现误报命中。

## 9. 一句话结论

这轮 `DEEPSEEK_SELF01` 首轮结果已经证明：

> 在 3 个冻结自有 case 上，`IRIS` 当前已经不再只是“完全没有标签”，而是进入了“局部标签有所恢复，但最终路径仍然不成立”的阶段；同时 fixed 控制组本轮保持了零路径。
