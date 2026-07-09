# E1 Static-gate Oracle 进展报告

## 1. 作用

这份文档记录 `Architecture Attribution Experiment` 中 `E1 Static-gate Oracle` 已完成的实验、当前可成立的结论，以及后续待补部分。

当前只整理已经完成并归档到 `artifacts/architecture_attribution/E1/` 的 family：

- `SSRF-JA-REPO-001`
- `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED`

后续 `E1` 剩余 family 和补充判断继续写入本文件，不另起平行版本。

## 2. 当前覆盖范围

### 2.1 已完成归档

- `SSRF-JA-REPO-001`
  - [run_manifest.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PILOT_SSRF001_20260706T115321Z/run_manifest.json:1)
  - [family_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PILOT_SSRF001_20260706T115321Z/family_matrix.tsv:1)
  - [family memo](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PILOT_SSRF001_20260706T115321Z/SSRF-JA-REPO-001/README.md:1)
- `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED`
  - [run_manifest.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PAIR_SSRF3432_20260706T125947Z/run_manifest.json:1)
  - [family_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PAIR_SSRF3432_20260706T125947Z/family_matrix.tsv:1)
  - [VULN memo](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PAIR_SSRF3432_20260706T125947Z/SSRF-JA-REPO-CVE-2023-3432-VULN/README.md:1)
  - [FIXED memo](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PAIR_SSRF3432_20260706T125947Z/SSRF-JA-REPO-CVE-2023-3432-FIXED/README.md:1)

### 2.2 尚未写入本报告的 `E1` 剩余范围

- `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`
- 如后续出现新的 `E1` 补跑 family，也继续并入本文件

## 3. 当前总判断

| family | `A` | `B` | `C` | `D` | 当前主结论 |
|---|---|---|---|---|---|
| `SSRF-JA-REPO-001` | 复现 `source=0, sink=0, results=0` | `sink` 从 `0` 到 `1`，仍 `0 path` | 恢复 target-aligned finding | 按停止规则跳过 | 不是纯 `candidate gate`；真正恢复仍依赖最小 `summary/path` 物化 |
| `SSRF-JA-REPO-CVE-2023-3432-VULN` | 保留错误 source `System.getenv` | 仍停在错误 source 片段 | 强制 `LoadJson.path` 后仍 `0 path` | 扩 caller-side slice 后仍 `0 path` | `candidate`、最小 `summary/path`、`slice` 都不是充分解释，主断点仍是更深层的 `query_semantics_mismatch` |
| `SSRF-JA-REPO-CVE-2023-3432-FIXED` | 复现 `source=0, path=0` | 被带到同样错误 source | 强制 `LoadJson.path` 后仍 `0 path` | 扩 caller-side slice 后仍 `0 path` | 不能把 `0 path` 解读成 fix-awareness；当前 static-gated 表示仍未解释修复 guard |

截至目前，`E1` 支持的总方向是：

- `SSRF-JA-REPO-001` 证明 `candidate gate` 会造成前层丢失，但最终恢复仍受下游 QLL 物化语义约束。
- `SSRF-3432 pair` 证明继续扩大候选、补最小 source/path、补 caller-side slice，都不足以让 `IRIS-style static-gated workflow` 恢复这条 pair 的目标语义。
- 因而 `SSRF-3432 pair` 的下一步应进入更自由的语义归因线，而不是继续停留在同一套静态 gate 表示中扩大局部补丁。

## 4. 方法边界

这两批 `E1` 归档并不都是“从零新跑”的同构执行，当前需要显式记录：

- `SSRF-JA-REPO-001` 使用的是 `evidence_replay_with_new_archival_package`
  - `A/B/C` 复用了既有权威证据
  - `D` 因 `C` 已成功而按 runbook 停止
- `SSRF-3432 pair` 使用的是 `mixed_evidence_replay_with_in_package_oracle_replay`
  - `A/B` 复用既有权威基线与 candidate 注入证据
  - `C/D` 在本次 `E1` 归档包内做了 manual oracle replay
  - 这些 replay 只写入 `artifacts/architecture_attribution/E1/`，不回写 `IRIS` 原评估线

这不影响本报告的归因用途，因为 `E1` 关心的是：

- 同一个 family 在 `A/B/C/D` 阶梯下断点是否后移
- 哪一层补丁能恢复 target-aligned result

而不是要求所有 family 都必须以相同方式完全重跑。

## 5. `SSRF-JA-REPO-001`

### 5.1 已完成版本

| 版本 | 状态 | `llm_sources` | `llm_sinks` | `paths` | 结果 |
|---|---:|---:|---:|---:|---|
| `A_original` | completed | 0 | 0 | 0 | 成功复现 baseline 无信号态 |
| `B_oracle_candidate` | completed | 0 | 1 | 0 | 候选补入后只改善了 sink 形状 |
| `C_oracle_summary_path` | completed | 1 | 1 | 1 | 恢复 target-aligned SSRF finding |
| `D_oracle_slice` | skipped | - | - | - | `C` 已成功，按 stop rule 不再继续 |

对应证据：

- [family memo](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PILOT_SSRF001_20260706T115321Z/SSRF-JA-REPO-001/README.md:1)
- [A run_summary](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PILOT_SSRF001_20260706T115321Z/SSRF-JA-REPO-001/A_original/run_summary.json:1)
- [B run_summary](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PILOT_SSRF001_20260706T115321Z/SSRF-JA-REPO-001/B_oracle_candidate/run_summary.json:1)
- [C run_summary](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PILOT_SSRF001_20260706T115321Z/SSRF-JA-REPO-001/C_oracle_summary_path/run_summary.json:1)
- [D run_summary](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PILOT_SSRF001_20260706T115321Z/SSRF-JA-REPO-001/D_oracle_slice/run_summary.json:1)

### 5.2 当前结论

这个 family 不能再被简单写成“纯 candidate-selection dominant”。

更准确的 `E1` 结论是：

1. `A -> B` 证明早期 `candidate gate` 确实挡住了 target-adjacent sink 暴露。
2. 但 `B` 仍然没有恢复结果，说明只把候选放进来还不够。
3. `C` 恢复结果，说明真正的恢复点落在最小 `source/sink` 物化语义，即 `summary/path modeling` 层。

因此，这个 family 当前应归为：

- `summary/path_modeling_after_candidate_gate`

而不是：

- “只要放宽 candidate 就能恢复”的纯前层断点

## 6. `SSRF-JA-REPO-CVE-2023-3432-VULN`

### 6.1 已完成版本

| 版本 | 状态 | `llm_sources` | `llm_sinks` | `llm_taint_propagators` | `paths` | 结果 |
|---|---:|---:|---:|---:|---:|---|
| `A_original` | completed | 1 | 6 | 15 | 0 | 唯一 source 仍是错误的 `System.getenv` |
| `B_oracle_candidate` | completed | 1 | 6 | 14 | 0 | 扩候选后仍停在同一错误 source |
| `C_oracle_summary_path` | completed | 1 | 6 | 14 | 0 | 手工把 source 改成 `LoadJson.loadStringData(path)` 后仍无路径 |
| `D_oracle_slice` | completed | 1 | 1 | 14 | 0 | 扩 caller-side slice 后仍无路径 |

对应证据：

- [family memo](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PAIR_SSRF3432_20260706T125947Z/SSRF-JA-REPO-CVE-2023-3432-VULN/README.md:1)
- [A run_summary](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PAIR_SSRF3432_20260706T125947Z/SSRF-JA-REPO-CVE-2023-3432-VULN/A_original/run_summary.json:1)
- [B run_summary](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PAIR_SSRF3432_20260706T125947Z/SSRF-JA-REPO-CVE-2023-3432-VULN/B_oracle_candidate/run_summary.json:1)
- [C run_summary](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PAIR_SSRF3432_20260706T125947Z/SSRF-JA-REPO-CVE-2023-3432-VULN/C_oracle_summary_path/run_summary.json:1)
- [D run_summary](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PAIR_SSRF3432_20260706T125947Z/SSRF-JA-REPO-CVE-2023-3432-VULN/D_oracle_slice/run_summary.json:1)

### 6.2 当前结论

这个 `VULN` case 已经把 `E1` 的四层阶梯都走完，但没有任何一层恢复 target-aligned path。

当前能成立的判断是：

1. `B` 不成功，说明继续扩大 `candidate` 不是主解。
2. `C` 不成功，说明把真实请求入口硬注入到最小 `source` 物化层仍然不够。
3. `D` 不成功，说明 caller-side slice 扩展也不是充分条件。

因此，这个 case 当前不支持以下解释：

- `candidate gate` 是主因
- `summary/path modeling` 是唯一主因
- `slice boundary` 是唯一主因

当前最稳妥的归因仍是：

- `query_semantics_mismatch_beyond_candidate_summary_slice`

换句话说，`IRIS-style static-gated workflow` 在这个 case 上的主断点，已经穿透了 `E1` 当前三层静态修补。

## 7. `SSRF-JA-REPO-CVE-2023-3432-FIXED`

### 7.1 已完成版本

| 版本 | 状态 | `llm_sources` | `llm_sinks` | `llm_taint_propagators` | `paths` | 结果 |
|---|---:|---:|---:|---:|---:|---|
| `A_original` | completed | 0 | 6 | 11 | 0 | 复现 source-empty fixed 基线 |
| `B_oracle_candidate` | completed | 1 | 6 | 14 | 0 | 被带到和 `VULN` 同样的错误 `System.getenv` source |
| `C_oracle_summary_path` | completed | 1 | 6 | 14 | 0 | 强制 `LoadJson.loadStringData(path)` 后仍无路径 |
| `D_oracle_slice` | completed | 1 | 1 | 14 | 0 | 扩 caller-side slice 后仍无路径 |

对应证据：

- [family memo](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PAIR_SSRF3432_20260706T125947Z/SSRF-JA-REPO-CVE-2023-3432-FIXED/README.md:1)
- [A run_summary](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PAIR_SSRF3432_20260706T125947Z/SSRF-JA-REPO-CVE-2023-3432-FIXED/A_original/run_summary.json:1)
- [B run_summary](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PAIR_SSRF3432_20260706T125947Z/SSRF-JA-REPO-CVE-2023-3432-FIXED/B_oracle_candidate/run_summary.json:1)
- [C run_summary](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PAIR_SSRF3432_20260706T125947Z/SSRF-JA-REPO-CVE-2023-3432-FIXED/C_oracle_summary_path/run_summary.json:1)
- [D run_summary](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_PAIR_SSRF3432_20260706T125947Z/SSRF-JA-REPO-CVE-2023-3432-FIXED/D_oracle_slice/run_summary.json:1)

### 7.2 当前结论

这个 `FIXED` case 最重要的不是“仍然 `0 path`”，而是：

- 这个 `0 path` 还不能被解释为系统理解了修复

当前能成立的判断是：

1. `A` 只是复现了 fixed 基线的 source-empty 状态。
2. `B` 说明放宽 candidate 会把 fixed 也带到与 `VULN` 同样的错误 source 片段。
3. `C/D` 说明即使强制对齐到 `LoadJson.path`，系统仍然没有显式解释 `forbiddenURL()` 或 `isInUrlAllowList()` 一类修复 guard。

因此，这个 `FIXED` case 当前只能归为：

- `differential_guard_semantics_unresolved_after_candidate_summary_slice`

不能归为：

- `fix-aware no path`

## 8. 当前对 `SSRF-3432 pair` 的合并判断

把 `VULN/FIXED` 放在一起看，当前 `E1` 得到的是一个更强的 pair-level 结论：

1. `candidate gate` 不是这组 pair 的主因。
2. 最小 `source` 物化语义不是充分条件。
3. caller-side slice 扩展也不是充分条件。
4. `FIXED=0 path` 目前只是“系统在同一表示里仍然打不通”，不是“系统理解了修复差分”。

这意味着：

- 继续在同一 `static-gated workflow` 内做更大规模 candidate 扩张，收益预期很低。
- 后续应优先转入更自由的语义实验线，例如 `E2 LLM Freedom Ladder`，并保留 `DeepAudit` 作为参照。

## 9. `E1` 后续分流：`SSRF-3432 pair` 的 `DeepAudit D3` 参照

由于 `SSRF-3432 pair` 在 `E1 A/B/C/D` 里已经证明：

- `candidate gate` 不是主因
- 最小 `source` 物化和 caller-side slice 也不是充分条件

因此后续按实验规划补跑了一条更自由的参照：

- `E4 D3 = CVE hint + real fix diff + no target_files`

这条参照不是 `E1` 本体版本，但它直接服务于 `E1` 的失败归因收口，所以在这里登记为“后续分流”。

对应证据：

- [D3 runbook](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e4_ssrf3432_deepaudit_d3_runbook.md:1)
- [D4 runbook](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e4_ssrf3432_deepaudit_d4_runbook.md:1)
- [D3 run_manifest](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D3_20260707T013951Z/run_manifest.json:1)
- [D4 run_manifest](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D4_20260707T020239Z/run_manifest.json:1)
- [VULN D3 metrics](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D3_20260707T013951Z/AAE4_SSRF3432_VULN_D3/metrics.json:1)
- [FIXED D3 metrics](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D3_20260707T013951Z/AAE4_SSRF3432_FIXED_D3/metrics.json:1)
- [VULN D4 metrics](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D4_20260707T020239Z/AAE4_SSRF3432_VULN_D4/metrics.json:1)
- [FIXED D4 metrics](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D4_20260707T020239Z/AAE4_SSRF3432_FIXED_D4/metrics.json:1)

### 9.1 `D2`、`D3`、`D4` 对照

| 条件 | Iter | Tool calls | Tokens | Findings | 当前最显眼输出 |
|---|---:|---:|---:|---:|---|
| `VULN D2` | 31 | 27 | 407604 | 8 | top-1 直接命中 `HTTP redirect following` 绕过，较接近目标机制 |
| `VULN D3` | 30 | 25 | 370115 | 7 | top-1/2 转向 `LEGACY` 默认模式与 `TContext.executeInclude()` 入口，反而偏离 patch 机制 |
| `VULN D4` | 30 | 28 | 479619 | 10 | 注意力回到 `LoadJson` 与 `SURL`；top-2 恢复到 `HTTP redirect`，但仍未聚焦 `@ / userinfo` 修复差分 |
| `FIXED D2` | 27 | 20 | 295330 | 9 | 仍大量报 `allowlist / cleanPath / LoadJson` 相关问题 |
| `FIXED D3` | 31 | 27 | 436815 | 7 | 仍大量报 `LEGACY` 默认模式、`forbiddenURL()` 绕过与 `%load_json` 入口问题 |
| `FIXED D4` | 31 | 23 | 400247 | 11 | 注意力同样回到 `SURL / SecurityProfile / LoadJson`，但 findings 数更多，仍未解释 fixed side 为什么不成立 |

### 9.2 当前结论

`D3` 与 `D4` 合在一起看，把 `SSRF-3432 pair` 的后续归因拆得更清楚了：

1. 只给 `patch/fixed diff`，但不给 `target_files` 的 `D3`，不足以让 `DeepAudit` 稳定收敛到真实修复点。
2. `D4` 说明 `target_files` 是有效约束：
   `VULN D4` 不再像 `D3` 那样被 `TContext.executeInclude()` 吸走，而是回到 `LoadJson`、`SURL`、`SecurityProfile` 这些 patch 相关文件。
3. 但 `D4` 仍然没有恢复真正的 differential semantic understanding：
   `VULN D4` 虽然重新打到了 `HTTP redirect` 和 `LoadJson -> SURL` 入口，但仍没有稳定聚焦到 `@ / userinfo / allowlist` 这条修复差分；
   `FIXED D4` 也没有显式解释 “fixed side 为什么不再成立”，反而报出了更多 findings。
4. 因此，`target_files` 的主要作用是把 attention 拉回 patch 文件，而不是自动把系统提升为可靠的 vulnerable/fixed 差分解释器。

对 `E1` 主线的补充含义是：

- `IRIS-style static-gated workflow` 在 `SSRF-3432 pair` 上失败，不足以单独推出 “只要放开到 agentic auditor 就会自然恢复差分语义”。
- 即便换成更自由的 `DeepAudit`，`D3` 仍会被仓库内更显眼的泛化风险吸走，而 `D4` 虽然解决了这一点，也仍未稳定解决修复差分理解。
- 这条 pair 当前最稳妥的结论是：
  `diff` 信息与 `target_files` 约束都能改变模型注意力分布，但都还不足以单独恢复可靠的 fixed-guard 语义解释。

## 10. `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`

### 10.1 当前状态

| 版本 | status | `llm_sources` | `llm_sinks` | `llm_taint_props` | `num_vulnerable_paths` | 结论 |
|---|---|---:|---:|---:|---:|---|
| `A_original` | completed | 0 | 2 | 10 | 0 | 归档 `rerun_3`，固定稳定 `source-zero` baseline |
| `B_oracle_candidate` | completed | 0 | 1 | 6 | 0 | no-op candidate replay 不改变失败形状，candidate gap 不是主因 |
| `C_oracle_summary_path` | completed | 0 | 1 | 6 | 0 | 最小异常消息 bridge 注入后仍无路径，说明问题深于局部 summary 缺口 |
| `D_oracle_slice` | completed | 1 | 1 | 6 | 0 | 加入 `CronValidator.isValid(String value)#value` 真实入口并收紧 exception slice 后仍无路径 |

对应证据：

- [B run_summary](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_CRONUTILS_20260707T023145Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/B_oracle_candidate/run_summary.json:1)
- [C run_summary](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_CRONUTILS_20260707T023145Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/C_oracle_summary_path/run_summary.json:1)
- [D run_summary](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_CRONUTILS_20260707T023145Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/D_oracle_slice/run_summary.json:1)
- [C injected MySummaries.qll](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_CRONUTILS_20260707T023145Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/C_oracle_summary_path/generated_queries/cwe-094wLLM/MySummaries.qll:1)
- [D exception trace](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E1/AAE1_CRONUTILS_20260707T023145Z/jmrozanec__cron-utils_CVE-2021-41269_9.1.5/D_oracle_slice/results/exception_trace.log:1)

### 10.2 当前结论

这条 family 现在已经能排除三个较浅层解释：

1. 不是 `candidate gate` 主因。
   `B` 的 monitor 集在 replay 前就已经存在，且 replay 仍然保持 `#Source = 0`、`#paths = 0`。
2. 也不是普通的“缺少一个局部 wrapper / getter summary”就能解释。
   `C` 把 `IllegalArgumentException(...)` 与 `Throwable.getMessage()` 这条异常消息 bridge 显式注入 `MySummaries.qll` 后，结果仍然完全为空。
3. 也不是“只要补一个真实入口 source 再加最小 caller-side slice”就能解释。
   `D` 显式加入 `CronValidator.isValid(String value)#value`，并按异常驱动检查把 slice 收紧到 `CronValidator/CronParser/CronParserField/FieldParser`，结果仍然是 `0 results / 0 paths`。

因此，当前最可信的剩余假设已经收紧到：

- `throw/catch` 相关的异常对象 transport 没有进入当前 path model
- 或者这条 family 已经超出 `IRIS-style static-gated workflow` 能通过局部 QLL 注入恢复的异常语义范围

换句话说，这个 family 当前不是“再补一个普通 API summary 就能恢复”的形状，而更像：

- `exception_transport_beyond_slice_and_true_entry`

## 11. 后续待补

后续继续在本报告补以下内容：

- 如有补跑，更新“当前总判断”表
- 如某个 family 后续触发了 `DeepAudit` 参照，只在本报告末尾加“E1 后续分流”小节，不把 `DeepAudit` 结果混写成 `E1` 本体结果
