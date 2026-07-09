# 架构归因实验第一轮总结报告

## 1. 文档定位

这份文档是 `Architecture Attribution Experiment` 的第一轮总结报告。

它回答的不是：

- 哪个系统在 benchmark 上“总体更强”
- 哪个系统应当取代哪个系统
- 所有剩余实验是否都已经补满

它回答的是：

- 当前已完成的架构归因实验，是否已经足以支持第一轮主结论
- 这些主结论具体是什么
- 还有哪些实验仍值得补，但已经不再阻断第一轮收口

## 2. 第一轮主问题

第一轮总问题来自：

- [architecture_attribution_experiment_plan.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/architecture_attribution_experiment_plan.md:1)

核心假设是：

> 在同一 case、同一模型、相近运行条件下，`static-tool constraint strength` 越强，系统越容易丢失 `target-aligned reasoning`；但自由审计带来的增益，又未必等于稳定的 differential semantic understanding。

这条假设需要拆成 4 个子问题：

1. `IRIS-style static-gated workflow` 的失败，究竟卡在 `candidate`、`summary/path`、`slice`，还是更深层的语义表示边界。
2. 当静态表示放宽后，LLM 是否会恢复目标漏洞理解。
3. 静态工具在 prompt/workflow 中是否形成了过强 authority prior。
4. `DeepAudit` 的优势有多少来自架构自由度，有多少来自更多输入信息。

## 3. 当前覆盖范围

### 3.1 已完成的主实验

| 实验 | family | 当前状态 | 备注 |
|---|---|---|---|
| `E1` | `SSRF-JA-REPO-001` | completed | `A/B/C` 已足够收口，`D` 按 stop rule 跳过 |
| `E1` | `SSRF-3432 pair` | completed | `A/B/C/D` 全部完成 |
| `E1` | `cron-utils` | completed | `A/B/C/D` 全部完成 |
| `E2` | `cron-utils` | completed | `M1-5` 全部完成 |
| `E2` | `SSRF-3432 pair` | completed | `M1/M3/M4` 完成，`M5` 不再需要 |
| `E3` | `SSRF-3432 pair` | completed | `A/B/C` 全部完成 |
| `E4` | `SSRF-3432 pair` | completed | `D1/D2/D3/D4` 全部完成 |
| `E4` | `cron-utils` | partially completed | `D1` 已完成，且已给出强信号 |

### 3.2 尚未补齐但不阻断第一轮结论的项

| 实验 | family | 当前状态 | 当前定位 |
|---|---|---|---|
| `E2` | `SSRF-JA-REPO-001` | not run | 泛化性补位，不是主结论前提 |
| `E3` | `SSRF-JA-REPO-001` | not run | authority 结论横向验证，不是主结论前提 |
| `E4` | `cron-utils D2/D4` | pending | 信息增益拆分，不是“能否命中”前提 |

因此，更准确的状态判断是：

- 第一轮主结论已经具备收口条件
- 但第一轮矩阵尚未完全补满

## 4. 已成立的 family-level 结论

### 4.1 `SSRF-JA-REPO-001`

对应证据：

- [E1 进展报告](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e1_static_gate_oracle_progress_report.md:1)

当前最稳妥的结论是：

1. 这条 family 确实存在前层 `candidate gate` 问题。
2. 但它不是“只要放宽 candidate 就恢复”的纯前层断点。
3. 真正恢复 target hit 的关键，仍然是最小 `summary/path` 物化语义。

因此它应当被表述为：

- `candidate gate exists, but recovery still depends on target-adjacent summary/path semantics`

而不是：

- “纯 candidate-selection dominant”

### 4.2 `SSRF-3432 pair`

对应证据：

- [E1 进展报告](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e1_static_gate_oracle_progress_report.md:1)
- [E2 pair 报告](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e2_ssrf3432_pair_differential_freedom_report.md:1)
- [E3 pair 报告](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e3_ssrf3432_pair_tool_authority_ablation_report.md:1)
- [E4 SSRF-3432 报告](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e4_ssrf3432_deepaudit_information_control_report.md:1)

当前最稳妥的结论是：

1. 继续扩大 `candidate`、最小 `summary/path`、caller-side `slice`，都不足以让 `IRIS-style static-gated workflow` 恢复这条 pair 的目标差分语义。
2. 一旦转入 pair-level `differential target context`，模型可以恢复：
   `LoadJson.path -> SURL` 漏洞链
   以及 `fixed-side @/userinfo guard`。
3. `tool authority` 不是这条 pair 的主瓶颈。
   即使强工具 authority 存在，模型仍会主动挑战 `no path` 并补全缺失 source/guard。
4. `DeepAudit` 在更自由条件下能找到很多相关风险，但这不等于自然恢复 `vulnerable/fixed` 差分解释。
   尤其 `D4` 已说明：`target_files` 只能改善“看哪里”，不能单独解决“为什么 fixed 已不成立”。

因此这条 pair 的收口应写成：

- `the main bottleneck is not candidate scarcity or tool authority, but the absence of stable local differential framing and fixed-guard semantics`

### 4.3 `cron-utils`

对应证据：

- [E2 cron-utils 进展报告](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e2_llm_freedom_ladder_progress_report.md:1)
- [E4 cron-utils 报告](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e4_cronutils_deepaudit_information_control_report.md:1)

当前最稳妥的结论是：

1. `E1` 已经证明，不应继续扩大这条 family 的静态 patch。
   `candidate`、最小异常 bridge、`true entry + exception slice` 都已补过，仍然 `0 paths`。
2. `E2` 已经证明：
   一旦把模型显式拉回
   `CronValidator -> CronParser -> IllegalArgumentException -> getMessage -> buildConstraintViolationWithTemplate`
   这条链，目标推理就能恢复。
3. `E4 D1` 又进一步证明：
   即使没有 `CVE hint / diff / target_files`，`DeepAudit` 也能在自由 repo 审计下直接恢复这条链。

因此 `cron-utils` 当前给出的信号很强：

- 这里确实存在明显的架构优势信号
- 即 `DeepAudit` 的 repo-level 自由审计表示，已经强到足以在低信息条件下恢复目标异常消息链

## 5. 已成立的跨实验结论

### 5.1 `static-gated workflow` 的失败不是单一原因

第一轮最重要的负面结论是：

- `IRIS-style static-gated workflow` 的失败不能统一归结为某一个局部断点

当前至少已经看到三种不同形状：

1. `SSRF-JA-REPO-001`：
   前层 `candidate gate` 存在，但不是最终恢复条件。
2. `SSRF-3432 pair`：
   局部 static patch 扩张不足以恢复差分语义，主断点更接近 pair-level semantic framing。
3. `cron-utils`：
   static-gated 形态下对异常消息链恢复失败，但更自由表示很快恢复。

因此，第一轮不支持任何过度简化说法，例如：

- “IRIS 主要就是 candidate 不够”
- “IRIS 主要就是少一个 summary”
- “只要多给 slice 就行”

### 5.2 更高自由度确实能恢复 target reasoning，但恢复机制不一样

第一轮支持一个较强的正面结论：

- 更自由的表示和审计结构，确实能恢复 static-gated workflow 丢失的目标语义

但这种恢复并不是单一机制：

1. 对 `cron-utils`：
   关键是允许模型或 auditor 恢复异常消息 transport 语义。
2. 对 `SSRF-3432 pair`：
   关键是把任务拉回到一条局部 differential chain，而不是让模型在泛化 SSRF 面里自由漂移。

因此，更准确的表述是：

- `freedom helps, but what must be reintroduced differs by family: bridge semantics in one case, local differential framing in another`

### 5.3 `tool authority` 不是当前最强解释变量

第一轮只在 `SSRF-3432 pair` 上完整做了 `E3`，但这个结果已经足够有区分度：

- 强 authority prior 没有把模型压回顺从 `no path`
- 错误工具输出也没有把模型带偏到无法修复

因此，至少在当前最关键的 pair 上：

- `tool authority` 不是主瓶颈

更强的解释变量仍然是：

- 任务 framing
- 是否给到局部 differential context
- 系统能否解释 fixed-side guard semantics

### 5.4 `DeepAudit` 的优势不能一概而论

第一轮对 `DeepAudit` 给出了一个更精细的判断：

1. 在 `cron-utils` 上，`D1` 已经足够支持真实的架构优势信号。
   成功并不依赖额外信息。
2. 在 `SSRF-3432 pair` 上，`DeepAudit` 更像自由风险发现器。
   它能找到很多 target-adjacent 风险，但这不自动等于稳定的 pair-level differential explainer。

因此，第一轮不支持这类简单化结论：

- “DeepAudit 更强，所以架构优势已经被完全证明”

更稳妥的表述是：

- `DeepAudit shows real architecture advantage on some families, but freer auditing alone does not guarantee stable differential semantic understanding`

## 6. 第一轮主结论

基于当前证据，第一轮架构归因实验可以收口为 5 条主结论：

1. `IRIS-style static-gated workflow` 的失败确实部分来自架构约束，而不是单纯“模型不会推理”。
2. 这种架构约束不是单一层面的；不同 family 的主断点不同。
3. 更自由的表示或 auditor 结构，确实能恢复 target-aligned reasoning。
4. 但“恢复 target-aligned reasoning”不等于“恢复 differential semantic understanding”。
5. 因而真正重要的不是单纯把系统做得更自由，而是：
   在自由度释放后，系统是否还能把注意力稳定压回 target-local semantics，尤其是 fixed-side guard semantics。

如果把第一轮最核心的一句话写出来，它应当是：

> 第一轮实验已经足够支持：`static-tool constraint strength` 是不同系统表现差异的重要解释变量之一，但它不是唯一解释变量；真正决定系统能否稳定恢复目标漏洞与修复差分的，还包括 local semantic framing、bridge semantics 与 fixed-side guard understanding。

## 7. 当前仍值得补、但不阻断收口的实验

### 7.1 `E4 cron-utils D2/D4`

这两档现在的定位已经变了：

- 不再是为了证明 `DeepAudit` “能不能命中”
- 而是为了量化 `CVE hint` 与 `diff/target_files` 的边际增益

### 7.2 `E2/E3 SSRF-JA-REPO-001`

这两组主要是横向泛化验证：

- `E2 SSRF001` 可以验证 `differential freedom` 的结论是否能推广到 candidate/summary 家族
- `E3 SSRF001` 可以验证 `tool authority is not the main bottleneck` 是否不是 pair-only 现象

### 7.3 为什么这些空位不阻断第一轮总结

因为当前最关键的因果分支已经都见到了：

- `candidate + summary/path` 家族：`SSRF-JA-REPO-001`
- `pair-level differential` 家族：`SSRF-3432 pair`
- `exception-message bridge` 家族：`cron-utils`

剩余空位更多是在：

- 提高矩阵完整性
- 拆边际增益
- 做横向泛化

而不是填补主结论缺失。

## 8. 对第二阶段的建议

如果进入第二阶段，最值得做的不是机械补满所有空格，而是围绕当前第一轮结论继续深化：

1. 把 `OpenAnt` 纳入同一归因框架，测试它在 `static-tool constraint strength` 上的位置。
2. 对 `SSRF-3432 pair` 单独做 fixed-side semantic explanation 线，而不是继续堆更多风险发现。
3. 对 `cron-utils` 用 `D2/D4` 量化：
   当低信息 `D1` 已成功时，额外信息究竟还能提升什么。

## 9. 当前结论性判断

所以，对“架构归因实验现在能不能视为基本完成”这个问题，当前最准确的回答是：

- 可以视为第一轮基本完成。
- 可以正式整理并采用这份第一轮总结报告。
- 剩余实验应被视为第二层完善项，而不是第一轮主结论的前提条件。
