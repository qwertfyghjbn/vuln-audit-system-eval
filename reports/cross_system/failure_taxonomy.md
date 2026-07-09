# 统一 Failure Taxonomy

## 1. 文档定位

这份文档定义当前仓库综合收尾阶段使用的统一 taxonomy。

它服务于两个目标：

1. 为 [canonical_results.tsv](/home/lqs/llm_audit_system_learning/reports/cross_system/canonical_results.tsv:1) 提供稳定的 `failure_mode_*` 取值边界。
2. 把 `case-level failure` 与 `experiment-level attribution conclusion` 明确分开，避免在总表里混写。

这不是：

- 单个系统的局部 failure 复盘
- 新一轮 `cross-system experiment` 的实验计划
- 对所有 case 的最终逐条归因结果表

## 2. 使用规则

### 2.1 行粒度规则

当前 [canonical_results.tsv](/home/lqs/llm_audit_system_learning/reports/cross_system/canonical_results.tsv:1) 允许两种行粒度，但必须显式区分：

1. `case-level row`
   - 一行对应一个 `case_id × system_id × system_mode`
   - 适用于 `OpenAnt`、`DeepAudit`、`IRIS` 的普通 benchmark case 结果
2. `pair/family-level row`
   - 一行对应一个 `pair_context` 或 family-level attribution mode
   - 适用于 `Architecture Attribution` 中明确不是单 case verdict 的结果，例如：
     - `SSRF-JA-REPO-CVE-2023-3432-pair / E2_M1_original`
     - `SSRF-JA-REPO-CVE-2023-3432-pair / E2_M4_differential_free_auditor`

使用约束：

- `case-level row` 优先。
- 只有当实验本身的最小输出单位就是 `pair` 或 family-level mode 时，才允许写 `pair/family-level row`。
- 如果同一实验既有 case-level 结果，也有 pair-level 结论，二者可以同时存在，但不得伪装成同一粒度。

### 2.1.1 `canonical_results.tsv` 的字段约束

- `failure_mode_primary`
  - 只允许填写“case-level failure mode”
- `failure_mode_secondary`
  - 只允许填写另一个“case-level failure mode”，用于记录次级断点
- `conclusion`
  - 可以填写更高层的实验判断，例如“official claim weakly reproduced”或“broad scanner but not target verifier”

### 2.1.2 共享字段枚举

以下枚举用于降低填表时的自由发挥空间。

#### `target_hit`

- `true`
  - 明确命中 benchmark target，或在 pair-level 行中明确恢复 target-local vulnerable path
- `false`
  - 没有命中 benchmark target
- `partial`
  - 有 target-adjacent signal，但命中不稳定、排序不稳，或只恢复了部分 target semantics

#### `fixed_guard_explained`

- `true`
  - 明确解释 fixed-side / near-miss side 的 guard、sanitizer、拒绝条件或修复逻辑
- `false`
  - 没有解释，或虽然结果为 `0 path` 但不能证明是 fix-aware
- `not_applicable`
  - 该行没有 fixed-side 语义目标，例如普通 vulnerable 单例 case

#### `off_target`

- `true`
  - 主要输出落在非 benchmark target 上，且这种偏移是当前结论的重要组成部分
- `false`
  - 主要输出与 benchmark target 对齐
- `partial`
  - 既有 target signal，又明显混入 target-adjacent 或 broad-scan noise
- `not_applicable`
  - 该行不是 finding-oriented 结果，例如某些纯 replay / oracle family 行

#### `cost`

`cost` 当前保持单列字符串，但建议统一用半结构格式：

- `tokens=<n>; time=<n>s; tool_calls=<n>`
- `api_calls=<n>; candidates=<n>; sources=<n>; sinks=<n>`
- `stage1_units=<n>; confirmed=<n>; review=<n>`

约束：

- 不要求所有系统完全同口径
- 但同一系统内部应尽量稳定
- 如果该行没有可比较的归一化成本，可写：
  - `no_normalized_cost`
  - `evidence_replay; no_normalized_cost`

### 2.1.3 不应写入 `failure_mode_*` 的内容

以下结论不应写进 `failure_mode_primary` 或 `failure_mode_secondary`：

- `tool_authority_not_primary`
- `information_advantage_controlled`
- `strong_architecture_signal`
- `weak_reproduction`

它们属于 `experiment-level attribution conclusion`，应放入总报告或个别 case 的 `conclusion` / 正文解释中。

## 3. Case-level Failure Modes

| taxonomy_id | 定义 | 适用边界 | 不适用边界 |
|---|---|---|---|
| `candidate_gate_failure` | target-adjacent API、unit 或 evidence 在前层 candidate boundary 就被挡掉，导致后续阶段没有足够目标语义可消费 | 典型信号是 candidate 补回后下游形状明显改善 | 候选已在，但失败发生在更下游 query、summary 或 differential framing |
| `summary_path_modeling_failure` | target-adjacent candidate 已在，但系统缺少稳定的 source/sink summary、path 物化或局部 bridge semantics | 最小 `summary/path` oracle 可恢复 target-aligned reasoning | 纯前层 candidate 缺失，或纯 broad-scan off-target |
| `query_semantics_mismatch` | source、sink、taint step 或 vulnerability query 的语义建模与目标漏洞不匹配 | 注回 candidate 后仍走不到目标链，或只恢复到错误 source/sink 片段 | 主要问题是 fixed-side guard 未解释，或只是 target framing 偏移 |
| `exception_transport_failure` | 异常对象、异常消息或 message transport bridge 没有被正确建模，导致目标链断在异常传播层 | 典型场景是 `Throwable -> getMessage -> sink` 一类链条 | 普通 source/sink query 错配、与异常 transport 无关 |
| `target_framing_limit` | 系统能看到相关风险，但没有把注意力稳定压回 benchmark target-local semantics | 常见于找到真实但非目标的安全问题，或仅给出宽泛风险解释 | fixed/vulnerable 差分已明确，只差 guard 落点解释 |
| `differential_guard_unresolved` | 在 `vulnerable/fixed` pair 或 `near_miss` 中，系统未能解释 fixed-side guard、sanitizer 或修复逻辑为何阻断目标漏洞 | 典型信号是 vulnerable 侧有风险感知，但 fixed 侧解释不能闭环 | 纯粹没看见任何 target signal，或只是 broad scan 产生噪声 |
| `off_target_broad_scan` | 系统在 repo-level 审计下能产生真实安全 finding，但主要落在非 benchmark target 上 | 常见于 large-repo broad scanner 行为 | 严格无信号、前层 candidate 缺失，或已明确命中 target anchor |

## 4. 主次 Failure 判定顺序

### 4.1 `primary` 的选择规则

从上到下按以下顺序判断，命中第一条即可优先作为 `failure_mode_primary`：

1. `candidate_gate_failure`
   - 只有在前层 candidate 补回后，下游形状明显改善时才可优先使用
2. `summary_path_modeling_failure`
   - 候选已在，但最小 `summary/path` 物化后才恢复 target hit
3. `exception_transport_failure`
   - 若核心断点明确落在异常消息 bridge，则优先于一般 `query_semantics_mismatch`
4. `query_semantics_mismatch`
   - 候选或局部 source 已在，但 query 语义仍走不到目标链
5. `differential_guard_unresolved`
   - 只有当行本身需要 fixed-side 或 near-miss guard 解释时才能优先使用
6. `target_framing_limit`
   - 系统看到了相关风险，但未稳定收敛到 benchmark target-local semantics
7. `off_target_broad_scan`
   - 主要用于 repo-level broad scanner 行为成为主结论时

### 4.2 `secondary` 的选择规则

`failure_mode_secondary` 只在下列情况下填写：

1. 主断点之外，还存在一个明确影响结论的次级断点。
2. 次级断点不是高层归因结论。
3. 次级断点不会改写主断点，只是补充说明失败形状。

常见组合：

- `target_framing_limit + off_target_broad_scan`
- `query_semantics_mismatch + differential_guard_unresolved`
- `off_target_broad_scan + differential_guard_unresolved`

### 4.3 什么时候不要填 `secondary`

以下情况应留空：

1. 行本身已经是稳定 target hit 正例。
2. 只有一个主断点，次级断点并不清楚。
3. 该行本质上是高层实验成功结论，而不是失败解释行。

## 5. `not_applicable` 规则

### 5.1 `fixed_guard_explained = not_applicable`

适用于：

- 普通 vulnerable 单例 case
- 普通 file/repo hit 行
- 不涉及 fixed-side / near-miss / pair differential 的行

### 5.2 `off_target = not_applicable`

只在非常少数情况下使用：

- family-level replay 行，其输出不是 finding-oriented 结果
- 明确以 `pair_context` 为主且没有单独 target-vs-off-target finding 语义的行

### 5.3 不应使用 `not_applicable` 的情况

- 普通 repo auditor finding 行
- near-miss / fixed 行
- large-repo broad scan 行

这些行即使没有命中 target，也应在 `off_target` 或 `fixed_guard_explained` 上给出明确判断。

## 6. 系统间映射规则

### 6.1 `OpenAnt`

- `anchor_match=false` 且有强 `VULNERABLE` finding
  - 优先映射为 `target_framing_limit`
- `near_miss/FIXED` 上出现大量非目标 confirmed findings
  - 优先映射为 `off_target_broad_scan`
  - 若 fixed-side guard 也未被解释，可再加 `differential_guard_unresolved`
- `verify` 降噪但不重锚
  - 写入 `conclusion`
  - 不单独作为 `failure_mode`

### 6.2 `DeepAudit`

- `C-shape` 命中 target 且噪声低
  - 通常不填 `failure_mode_*`
- `D-shape` 高成本命中且噪声高
  - 优先映射为 `off_target_broad_scan`
  - 若 target signal 仍存在但 framing 不稳，可补 `target_framing_limit`
- `FIXED` / pair side 仍持续报 patch 文件风险
  - 优先映射为 `differential_guard_unresolved`

### 6.3 `IRIS`

- `source=0` 或 `sink=0` 导致 `0 path`
  - 默认先看具体 family
  - 若断在异常消息 bridge，映射为 `exception_transport_failure`
  - 否则优先映射为 `query_semantics_mismatch`
- candidate 补回后才出现关键改善
  - 可映射为 `candidate_gate_failure`
  - 但必须有明确前后对照证据
- `0 path` 不能自动写成 `differential_guard_unresolved`
  - 只有 fixed-side guard 本身成为分析目标时才可使用

### 6.4 `Architecture Attribution`

- `E1/E2/E4` 的高层成功判断通常写进 `conclusion`
- `M1_original` 一类 collapsed 行
  - 可写 `query_semantics_mismatch`
  - 若 fixed-side guard 解释缺失明显，可补 `differential_guard_unresolved`
- `M3/M4` 一类成功恢复行
  - 通常不写 `failure_mode_*`

## 7. 仓库内正反例

### 7.1 `candidate_gate_failure`

- 正例：
  - `SSRF-JA-REPO-001 / E1 A->B->C`
- 反例：
  - `SSRF-3432 pair / E1-E2`
  - 继续扩大 candidate 不能恢复 pair-level differential understanding

### 7.2 `summary_path_modeling_failure`

- 正例：
  - `SSRF-JA-REPO-001 / E1_C_oracle_summary_path`
- 反例：
  - `PT-PY-FILE-001 / OpenAnt`
  - 这里不是 summary/path 不足，而是已经直接命中 target

### 7.3 `query_semantics_mismatch`

- 正例：
  - `SSRF-JA-REPO-CVE-2023-3432-VULN / IRIS official behavior`
  - `SSRF-3432 pair / E2_M1_original`
- 反例：
  - `cron-utils / DeepAudit E4_D1`
  - 这里已经恢复了目标链，不属于 query mismatch

### 7.4 `exception_transport_failure`

- 正例：
  - `jmrozanec__cron-utils_CVE-2021-41269_9.1.5 / IRIS official trustworthiness`
- 反例：
  - `SSRF-PY-REPO-CVE-2025-2828-VULN / OpenAnt`
  - 这里是 large-repo target framing / off-target 问题，不是异常消息 bridge 问题

### 7.5 `target_framing_limit`

- 正例：
  - `SSRF-PY-REPO-CVE-2025-2828-VULN / OpenAnt`
  - `SSRF-3432 FIXED D4 / DeepAudit`
- 反例：
  - `PT-PY-FILE-001 / OpenAnt`
  - 已明确 hit target，不应写成 framing limit

### 7.6 `differential_guard_unresolved`

- 正例：
  - `SSRF-JA-REPO-CVE-2023-3432-FIXED / DeepAudit E4_D4`
  - `PT-PY-REPO-002 / OpenAnt`
- 反例：
  - `PT-JA-REPO-CVE-2024-53677-VULN / IRIS official behavior`
  - 这里没有 fixed-side guard 目标

### 7.7 `off_target_broad_scan`

- 正例：
  - `SSTI-PY-REPO-CVE-2024-45053-FIXED / OpenAnt`
  - `D-real-world-PT-PY-REPO-CVE-2024-32982-VULN / DeepAudit`
- 反例：
  - `A-synthetic-PT-PY-FILE-001 / DeepAudit`
  - 这是相对干净的 target hit，不属于 broad scan

## 8. Experiment-level Attribution Conclusions

以下条目保留为综合报告使用的高层判断，不写入 `failure_mode_*`：

| conclusion_id | 含义 | 主要使用位置 |
|---|---|---|
| `tool_authority_not_primary` | 静态工具 authority prior 不是当前 family 或实验的主断点 | `Architecture Attribution` 总结、family-level 解释 |
| `information_advantage_controlled` | 在信息输入被控制后，某系统剩余优势或差异可以被更精确地归因 | `OpenAnt` 受控结构实验、`DeepAudit` 信息优势控制实验、总报告综合结论 |
| `strong_architecture_signal` | 某条 family 在低信息条件下就恢复了目标链，因此更像架构优势而不是信息提示优势 | `cron-utils / E4 D1` 一类结果 |
| `weak_reproduction` | 官方声称在本地只恢复了缩小版命中，而非稳定等价复现 | `IRIS` 官方 case 可信度线 |

## 9. 当前映射建议

### 9.1 更适合直接写入 `canonical_results.tsv`

- `candidate_gate_failure`
- `summary_path_modeling_failure`
- `query_semantics_mismatch`
- `exception_transport_failure`
- `target_framing_limit`
- `differential_guard_unresolved`
- `off_target_broad_scan`

### 9.2 更适合只在正文中解释

- `tool_authority_not_primary`
- `information_advantage_controlled`
- `strong_architecture_signal`
- `weak_reproduction`

## 10. 填表时的最小流程

推荐按下面顺序逐行判断：

1. 先确定该行是 `case-level` 还是 `pair/family-level`。
2. 再判断 `target_hit / fixed_guard_explained / off_target` 三个共享字段。
3. 若是失败行，再按“主次 Failure 判定顺序”选择 `primary`。
4. 只有在存在明确次级断点时才填 `secondary`。
5. 最后把高层实验判断写进 `conclusion`，不要写进 `failure_mode_*`。

## 11. 证据入口

- `IRIS`：
  [iris_candidate_selection_all7_formal_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_candidate_selection_all7_formal_results.md:1)
- `DeepAudit`：
  [learning_run_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/summaries/learning_run_summary.md:1)
- `Architecture Attribution`：
  [overall_architecture_attribution_report.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/overall_architecture_attribution_report.md:1)
- `OpenAnt`：
  [openant_learning_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/openant/summaries/openant_learning_summary.md:1)
