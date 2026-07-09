# OpenAnt 学习报告

## 0. 文档定位

- 文档类型：对比学习报告，不是 V3 改进方案
- 当前阶段：对比 OpenAnt 与 V3，并学习 OpenAnt 的机制边界
- 结论边界：
  - 不把 OpenAnt 是否能跑完表述成“更快”
  - 不把局部 case 优势外推成“整体更强”
  - 不把 round1 的初始观察直接当作最终结论
  - 必须结合后续受控实验与吞吐归因，重新解释 round1

本报告重写并整合以下目录中的已有产物：

- `artifacts/openant_eval/`
- `artifacts/unit_partition_compare/`
- `artifacts/unit_partition_controlled_eval/`
- `artifacts/throughput_attribution/`

---

## 1. 报告目标

本报告不回答“是否应该直接把 OpenAnt 替换成 V3 主链”，而回答以下四个问题：

1. OpenAnt 当前最值得学习的机制是什么。
2. round1 里看上去像“OpenAnt 优势”的部分，哪些后来被受控实验证伪或收缩了。
3. OpenAnt 与 V3 的大仓库差异，究竟主要来自 unit partition、验证策略，还是吞吐路径与扫描范围。
4. 现阶段对 OpenAnt 最稳妥的学习结论是什么，哪些结论仍然不能成立。

---

## 2. 证据来源与可信度分层

### 2.1 第一层：round1 原始观察

主要来源：

- `artifacts/openant_eval/2026-06-28-round1/openant_case_matrix.json`
- `artifacts/openant_eval/2026-06-28-round1/openant_vs_current_comparison.md`
- `artifacts/openant_eval/2026-06-28-round1/failure_taxonomy.md`
- `artifacts/openant_eval/2026-06-28-round1/manifests/openant_b1_batch_analyze_summary.json`
- `artifacts/openant_eval/2026-06-28-round1/manifests/openant_b2_verify_batch_summary.json`
- `artifacts/openant_eval/2026-06-28-round1/current_system/a1_balanced_no_semver_report.json`
- `artifacts/openant_eval/2026-06-28-round1/current_system/a2_strict_semver_cases.json`

这一层用于回答：

- OpenAnt `parse + analyze + verify` 的外观表现
- 首批 8 个 Python case 上的初始现象
- 初始 failure taxonomy

但这一层不能单独回答：

- unit partition 是否真是差异主因
- 大仓库差异是否来自 provider timeout
- round1 中某些 dramatic 差异是否只是实验口径问题

### 2.2 第二层：受控结构实验

主要来源：

- `artifacts/unit_partition_compare/2026-06-30-e1/unit_partition_diff_report.md`
- `artifacts/unit_partition_controlled_eval/2026-06-30-e1/e1_experiment_report.md`
- `artifacts/unit_partition_controlled_eval/2026-06-30-e1/e1_residual_binding_audit.md`
- `artifacts/unit_partition_controlled_eval/2026-06-30-e2/e2_experiment_report.md`
- `artifacts/unit_partition_controlled_eval/2026-06-30-e2/parser_backlog.md`
- `artifacts/unit_partition_controlled_eval/2026-06-30-e2/module_span_backlog.md`
- `artifacts/openant_eval/2026-06-30-e1-scope-aligned/manifests/parse_status_summary.json`

这一层用于回答：

- OpenAnt 的 unit 结构与 V3 的结构差异是什么
- 只替换 partition 后，绑定、candidate、target rank 是否稳定改变
- round1 / round2 中看似巨大的 partition 差异，是否其实来自 parse scope mismatch

### 2.3 第三层：吞吐归因实验

主要来源：

- `artifacts/throughput_attribution/2026-06-30-round1/hypothesis_assessment.md`
- `artifacts/throughput_attribution/2026-06-30-round2/hypothesis_assessment.md`
- `artifacts/throughput_attribution/ta2-provider-attribution/ta2_provider_attribution_report.md`

这一层用于回答：

- OpenAnt 为什么能在大仓库上持续推进
- V3 为什么会在大仓库上 `timeout@provider`
- 这种差异是否与 emission、candidate 后处理无关

---

## 3. round1 原始观察：OpenAnt 在看什么

### 3.1 首批 8 个 Python case 的表面现象

`openant_vs_current_comparison.md` 给出的 round1 `compare_bucket` 分布为：

- `hit_vulnerable`: `2`
- `miss_no_signal`: `3`
- `fp_offtarget`: `2`
- `clean_negative`: `1`

这说明 round1 时最直接的观察不是“OpenAnt 全面优于当前系统”，而是：

- 它确实能在部分真实漏洞 case 上命中 target
- 它也经常在真实漏洞 case 上给出 off-target 强阳性
- 它在 near-miss 上并不天然保守

在 `5` 个 vulnerable case 上，以 Stage1 中 `VULNERABLE/BYPASSABLE` 候选按置信度排序重新统计，OpenAnt 的 vulnerable-like anchor 命中为：

- `top-1 = 1/5`
- `top-3 = 2/5`
- `top-5 = 2/5`
- `any-anchor = 2/5`

也就是说，OpenAnt 的主要特点不是“排序不好但都能看见目标”，而是：

> 在一部分真实漏洞 case 上，它看到的是仓库里的别的风险点，而不是 benchmark 指定锚点。

### 3.2 代表性 case

### `PT-PY-FILE-001`

- OpenAnt Stage1 即命中目标
- target anchor rank 为 `1`
- Stage2 结果为 `confirmed_vulnerable`

这是 OpenAnt 的正面样例，说明它在小范围、sink 清晰、语义直接的 case 上能形成强解释。

### `PT-PY-REPO-001`

- OpenAnt Stage1 命中目标
- target anchor rank 为 `2`

这说明 OpenAnt 不只对 file case 有效，在跨函数但仍相对收敛的 repo case 上也能命中。

### `SSRF-PY-REPO-CVE-2025-2828-VULN`

- OpenAnt Stage1 在大仓库中分析了 `575` 个 unit
- 产出 `93` 个 vulnerable-like 候选
- 顶部强阳性落在 `labelstudio_callback.py` 一类代码
- benchmark target 是 `toolkit.py:get_tools`

这说明 OpenAnt 的大仓库行为更接近：

- 能持续扫很多 unit
- 能发现仓库里真实存在的安全风险
- 但不会自动围绕 benchmark target 收敛

### `SSTI-PY-REPO-001`

- OpenAnt Stage1 顶部 finding 可以落在 `debug=True` 一类弱点
- benchmark target 是模板渲染链
- Stage2 对该 case 给出 `confirmed_vulnerable`

这再次说明：

> OpenAnt Stage2 能确认 finding 是否像真实安全问题，但不会替系统把 finding 重新锚回 benchmark 指定 target。

### `SSTI-PY-REPO-CVE-2024-45053-FIXED`

- round1 中它是 benchmark 负样本
- OpenAnt Stage2 回填结果为 `13 confirmed + 29 needs_review`

这不是“OpenAnt 错了”这么简单，而更像：

- benchmark 标注的是该 case 对目标漏洞的正负
- OpenAnt 扫到的是仓库里其他真实安全问题
- 它的输出语义更接近“安全事实枚举”，而不是“只回答 benchmark 问题”

### 3.3 round1 failure taxonomy 仍然有价值

round1 的 7 类 taxonomy 仍然保留解释力，但只能作为初始标签，不是最终归因：

- `T1_strict_semantic_veto_on_true_positive`
- `T2_stage1_offtarget_on_true_vulnerable`
- `T3_stage1_clean_negative`
- `T4_stage1_false_positive_on_near_miss`
- `T5_stage2_prunes_but_does_not_reanchor`
- `T6_large_repo_timeout_vs_broad_scan`
- `T7_provider_evidence_type_drift`

其中后续最重要的两条是：

- `T5`：Stage2 会降噪，但不会重锚
- `T6`：大仓库差异不能只看“谁跑完了”，必须继续做吞吐归因

---

## 4. 对当前系统对照的重新口径化

round1 当时的当前系统对照不能不加区分地继续沿用。

### 4.1 `A1 balanced + disable-semantic-verification`

`a1_balanced_no_semver_report.json` 表明，在同一批 8 case 上：

- `matched_recall_anchor_count = 0`
- `emitted_but_missed_anchor_count = 4`
- `finding_emitted_outside_guard_scope_count = 3`
- `no_finding_emitted_count = 1`

其中：

- `SSRF-PY-REPO-CVE-2025-2828-VULN` 是 `timeout`
- `SSTI-PY-REPO-CVE-2024-45053-FIXED` 出现大量 guard scope 外 finding

因此 round1 的一个稳定事实是：

> V3 当时的问题并不主要表现为“语义太严格”，而是 anchor miss、guard scope miss 和大仓库 provider timeout。

### 4.2 `A2 strict + semantic verification`

`a2_strict_semver_cases.json` 中这 8 个 case 在该轮全部是 `execution_error`，原因是 `reuse_latest_snapshot` 缺少可复用快照。

因此：

- strict round1 不能当作与 OpenAnt 同轮、同口径的可比基线
- 任何“OpenAnt 相比 strict 更好/更差”的表述，都只能引用历史观察，不能当成这轮的硬证据

---

## 5. 后续实验修正了什么：不能把差异都归因给 unit partition

### 5.1 结构对比先给出的结论很有限

`unit_partition_diff_report.md` 比较了 `18` 个 Python case 的 unit 落盘结构。

总体统计：

- V3 unit 总数：`83579`
- OpenAnt unit 总数：`72632`
- anchor containment：`both=17`，`only_v3=1`，`only_openant=0`，`both_missing=0`

span overlap 分布：

- `same_boundary = 67807`
- `v3_contains_openant = 8918`
- `openant_contains_v3 = 5317`
- `near_same = 2193`
- `no_overlap = 2965`

这一步只能证明：

- 两边都基本能覆盖目标 anchor
- V3 往往保留更多显式父子结构
- OpenAnt 更明显地区分“结构主表”和“实际分析子集”

这一步不能证明：

- OpenAnt 的 unit partition 天然更适合漏洞发现
- 只换 unit boundary 就能解释 round1 大部分差异

### 5.2 E1 把最显著的伪信号清掉了

`E1` 固定：

- `phase=partition_only`
- `emission_policy=candidate_only`
- OpenAnt parse 改为 `skip_tests=false`

其核心结果是：

- shared provider input 完全一致：两臂 `provider_evidence_count = 18302`
- OpenAnt 仅少 `33` 条 bound evidence，缺口约 `0.18%`
- `candidate_count`：V3 `6813`，OpenAnt `6600`

这一步最重要的不是数字本身，而是它推翻了两类早先看上去很 dramatic 的结论：

### `PT-PY-REPO-CVE-2024-32982-{VULN,FIXED}`

round2 里 OpenAnt 曾出现大规模 binding collapse；E1 后该现象基本消失。

这说明：

> 之前的巨大差异主要来自 `skip_tests=true` 造成的 parse scope mismatch，而不是 target method 的 partition fidelity。

### `SSTI-PY-REPO-CVE-2024-45053-VULN`

round2 里 OpenAnt 的 target rank 曾从 `2323 -> 17`，看起来像巨大提升；E1 scope 对齐后变成：

- V3：`2323`
- OpenAnt：`2319`

这说明：

> 先前的“大幅 ranking 优势”主要是候选池被错误缩小后的实验假象，不是稳定的 OpenAnt partition 优势。

### 5.3 `SSTI-PY-REPO-001` 也不是 OpenAnt 真正丢了一个好命中

E1 与 residual binding audit 表明，这个 case 中保留下来的差异更接近：

- V3 的宽 module unit 把 line 3 的 evidence 与目标函数行段包在同一个大 unit 中
- OpenAnt 的 module unit 边界更紧，去掉了这个“伪 target hit”

因此该 case 的更稳解释是：

> 这是 module-level candidate contamination，而不是 OpenAnt 丢掉了一个本来就成立的真实命中。

### 5.4 E2 说明“补 parent relation”不是关键学习点

`E2` 在 OpenAnt arm 上注入 `parent_only` relation 后：

- `bound_provider_evidence_count` 不变：仍是 `18269`
- `no_matching_unit` 不变：仍是 `33`
- `candidate_count` 从 `6600` 增长到 `7142`

关键 case 上：

- `SSTI-PY-REPO-001` 仍然没有 target candidate
- `SSTI-PY-REPO-CVE-2024-45053-VULN` 的 target rank 反而从 `2319` 变坏到 `2798`

这说明：

> 现阶段从 OpenAnt 学到的重点不是“补 parent relation”，而是 parse scope、结构主表与分析子集分离、以及 analysis object 的组织方式。

---

## 6. OpenAnt 真正值得学习的机制

结合 round1、E1/E2 和吞吐归因，当前最稳的 OpenAnt 学习点有四个。

### 6.1 它的主对象是 unit，不是整仓库一次性全扫

OpenAnt 的外观流程是：

- `parse`
- 生成 unit catalog 与 reachable subset
- 对 unit 做逐个 `analyze`
- 对 finding 做 `verify`

这意味着它的最小工作对象是 unit，而不是：

- 整个 repo 一次性交给模型
- 单次 provider 对全仓做长时间、单预算的 rule 扫描

这个机制本身不保证 target 对齐，但保证了：

- 可渐进推进
- 可统计每个 unit 的结果
- 可持续产出中间结果

### 6.2 它把“结构主表”和“分析纳入子集”分开

这是 unit 对比报告里最值得保留的机制认识。

OpenAnt 的结构表达不是“只有被 analyze 的 unit 才存在”，而更像：

- `functions/classes/module` 维护结构 catalog
- `dataset.json` 或等价产物表示本轮实际纳入分析的 subset

这与“只看最终 finding”完全不同。它更容易支持：

- 解释为什么某个 target 没被分析
- 解释为什么某个 finding 出现在某个 unit
- 解释 parse scope 与 analyze scope 是否一致

### 6.3 它更像“安全事实解释器”，不是 benchmark target 对齐器

OpenAnt Stage1/Stage2 的强项是：

- 能写出像真实安全分析的 reasoning
- 能给出 CWE、攻击向量、上下文解释
- Stage2 能把一部分明显不稳的 finding 压下去

但它的边界也很明确：

- Stage2 会 prune，不会 re-anchor
- 它会确认“这里像安全问题”，不会自动回答“这是不是 benchmark 指定的那一个点”

因此，学习 OpenAnt 时应区分两个目标：

- 学它如何形成安全事实解释
- 不要误以为它天然解决 benchmark target 对齐

### 6.4 它在大仓库上的关键差异不是更快，而是工作单元与预算边界不同

吞吐归因给出的结论非常明确：

- V3 大仓库 timeout 主要发生在 `provider / tool-evidence-scan`
- 把 V3 切到 `candidate_only` 后，timeout 仍然存在
- `tool_evidence_scan_time_ms` 约等于整段 wall time
- `finding_emission_time_ms` 接近 `0`

而 OpenAnt 在两个大仓库 case 上的参考耗时是：

- `SSRF-PY-REPO-CVE-2025-2828-VULN`：parse `49.05s`，analyze `1819.29s`，总计 `1868.34s`
- `SSTI-PY-REPO-CVE-2024-45053-FIXED`：parse `6.34s`，analyze `1514.36s`，总计 `1520.70s`

因此这里真正要学的不是“OpenAnt 快”，而是：

> OpenAnt 的 parse/analyze 路径可以用 unit 级长时推进方式持续工作；V3 当前大仓库断点则位于 full-repo provider scan 的 30s budget 前段。

---

## 7. 大仓库差异的真正归因：不是 unit partition 本身

TA1 与 TA2 归因把大仓库差异进一步讲清了。

### 7.1 emission / candidate 后处理不是大仓库 timeout 主因

`throughput_attribution/2026-06-30-round2/hypothesis_assessment.md` 表明：

- `SSRF-PY-REPO-CVE-2025-2828-VULN`
  - `v3-as-is`: `timeout@provider`, `30000 ms`
  - `v3-candidate-first`: `timeout@provider`, `30872 ms`
  - `tool_evidence_scan_time_ms = 30869`
  - `finding_emission_time_ms = 2`
- `SSTI-PY-REPO-CVE-2024-45053-FIXED`
  - `v3-candidate-first`: `timeout@provider`, `30544 ms`
  - `tool_evidence_scan_time_ms = 30543`
  - `finding_emission_time_ms = 0`

所以：

> OpenAnt 与 V3 的大仓库差异，不能再解释成 emission policy、candidate 后处理或 verifier 差异。

### 7.2 no-op provider 很快，说明 wrapper 不是主瓶颈

`ta2_provider_attribution_report.md` 给出：

- `v3-noop-provider`
  - SSRF 大仓库：`493 ms`
  - SSTI 大仓库：`292 ms`
- `v3-bandit-provider`
  - SSRF：约 `30.5 s` timeout
  - SSTI：约 `30.3 s` 完成

这说明：

> V3 的 provider 外围 orchestration 不是主要耗时来源。

### 7.3 真正慢的是 full-repo provider scan 与证据噪声

直接 Bandit CLI 基线显示：

- `SSRF-PY-REPO-CVE-2025-2828-VULN`
  - `full_repo = 45047 ms`
  - `exclude_tests = 27173 ms`
  - `target_package = 17486 ms`
  - `openant_scope_if_available = 6623 ms`
- `SSTI-PY-REPO-CVE-2024-45053-FIXED`
  - `full_repo = 25975 ms`
  - `exclude_tests = 10273 ms`
  - `target_package = 10109 ms`
  - `openant_scope_if_available = 3845 ms`

而 evidence explosion profiling 表明：

- `SSRF` 全仓 `8939` 条 evidence 中，`B101 = 8370`
- `SSTI` 全仓 `10001` 条 evidence 中，`B101 = 9397`
- `SSTI` 的全仓 top dir 是 `tests/ops = 8398`

因此大仓库差异更接近：

- full-repo provider scan 输入规模过大
- tests/非目标目录吞吐噪声很重
- 少数高噪 rule 主导绝大多数 evidence
- 30s provider budget 在这种输入规模下过紧

这是一条与 OpenAnt 学习直接相关的结论，因为它说明：

> OpenAnt 与 V3 的大仓库差异，当前更像“工作对象和扫描边界不同”，而不是“OpenAnt 的 unit 边界神奇地解决了大仓库问题”。

---

## 8. 当前最稳的学习结论

下面按证据强度整理当前可以成立与不能成立的判断。

### 8.1 可以成立

### 结论 A：OpenAnt 的核心价值是 staged、unit-level、可持续推进

证据强度：`confirmed`

依据：

- round1 大仓库可以持续跑出很多 unit 结果
- 吞吐归因显示 V3 大仓库断在 provider 前段
- OpenAnt 不是更快，但它的工作对象和预算边界允许它继续推进

### 结论 B：OpenAnt 擅长形成“安全事实解释”，不擅长自动 benchmark re-anchor

证据强度：`confirmed`

依据：

- `SSTI-PY-REPO-001`、`SSRF-PY-REPO-CVE-2025-2828-VULN` 都表现出“finding 成立但不落目标锚点”
- round1 taxonomy 中 `T5_stage2_prunes_but_does_not_reanchor`
- Stage2 已回填 case 均未显示自动重锚能力

### 结论 C：把差异简单归因给 unit partition 是不成立的

证据强度：`confirmed`

依据：

- 结构对比显示两边大多数 anchor 都能覆盖
- E1 清除了多个看似 dramatic 的 partition 差异
- E2 说明 parent relation 注入不能解决残余问题

### 结论 D：OpenAnt 的“结构主表”和“分析子集”分离，是值得学习的表达机制

证据强度：`likely`

依据：

- 该机制在 unit 对比、scope 对齐和 residual audit 中都提供了更强解释力
- 它帮助把 parse scope、analysis scope、binding 缺口分开描述

### 结论 E：OpenAnt 与 V3 在大仓库上的主要差异，当前更像吞吐路径与扫描边界差异

证据强度：`confirmed`

依据：

- TA1 排除了 emission/candidate 后处理
- TA2 排除了 wrapper 慢
- bounded scan / openant scope 显著降低了 direct Bandit 成本

### 8.2 不能成立

### 结论 F：OpenAnt 更快

证据强度：`ruled out`

依据：

- 两个大仓库 OpenAnt 总耗时在 `1500-1800` 秒量级
- V3 的问题是 `30s provider budget` 先截断，不是 OpenAnt 更快

### 结论 G：只要换成 OpenAnt 的 unit partition，V3 大仓库问题就会解决

证据强度：`ruled out`

依据：

- E1/E2 没有支持这种因果链
- 吞吐归因把主断点定位到了 provider full-repo scan 与 budget

### 结论 H：只要补 parent relation，就能学到 OpenAnt 的关键增益

证据强度：`ruled out`

依据：

- E2 只带来 candidate 膨胀
- 不能修复 `33` 条 residual `no_matching_unit`
- 还会恶化某些 target rank

### 结论 I：Stage2 verify 能自动把 off-target finding 改成 target finding

证据强度：`ruled out`

依据：

- 当前所有已回填 case 都更支持 prune/not prune，而不是 re-anchor

---

## 9. 对“学习 OpenAnt”这件事本身的含义

在当前阶段，学习 OpenAnt 的重点不应表述成“继续局部优化 V3”，而应表述成三条更精确的认识。

### 9.1 学的是机制拆分，不是单一技巧

OpenAnt 不是一个“把 unit 切得更细”的单点技巧，而是至少包含：

- parse 出结构 catalog
- 选择 reachable / included unit subset
- 对 unit 独立 analyze
- 再对 finding 做 verify

如果只学其中一小块，例如 parent relation 或 boundary 风格，很容易得出错误结论。

### 9.2 学的是分析对象与预算边界

OpenAnt 最值得研究的是：

- 它如何把仓库转成长期可推进的 analysis object
- 它如何让大仓库工作在“许多小步”而不是“一次 full-repo provider 扫描”

这与“最终模型是否更聪明”是两回事。

### 9.3 学的是“安全事实”与“benchmark target”分离

OpenAnt 的输出经常说明：

- 仓库里确实有严重安全问题
- 但不一定是 benchmark 关心的那个点

这提示后续做对比时，至少要把两个指标分开：

- finding validity
- target alignment

否则会把“发现了别的真问题”和“命中了 benchmark target”混为一谈。

---

## 10. 现阶段最值得保留的问题清单

以下问题仍值得继续作为 OpenAnt 学习议题，但当前报告不下强结论。

### 10.1 OpenAnt 的 reachable subset 是如何选出来的

这是大仓库可持续推进的关键之一，但当前报告只看到了结果，没有完整解释其选择策略。

### 10.2 OpenAnt Stage1 的 prompt / context packing 如何影响 off-target 倾向

我们已经知道它会 broad-scan 并形成安全事实解释，但还没有充分解释：

- 为什么某些 case 容易落到 debug/config 风险
- 为什么某些 case 更容易落到 benchmark target

### 10.3 OpenAnt verify 的稳定边界在哪里

目前只足以说明它会 prune，不会 re-anchor；但还不足以说明：

- 在哪些 finding 类型上 prune 最有效
- 在哪些大仓库 case 上 verify 成本是值得的

---

## 11. 最终结论

如果只保留一句最核心的话，那么当前阶段对 OpenAnt 的学习结论应表述为：

> OpenAnt 的价值不在于“更快”或“只靠更好的 unit partition 就能赢”，而在于它把仓库审计拆成了可持续推进的 staged、unit-level 分析过程；它擅长产出可解释的安全事实，但不天然保证 benchmark target 对齐。后续所有对比与学习，都应优先围绕这一点展开，而不是继续把差异简化成 verifier、emission policy 或单一 partition 技巧。

如果展开成三条，则是：

1. OpenAnt 真正可学的是 `parse -> unit subset -> analyze -> verify` 的分析组织方式。
2. 受控实验已经表明，不能把 round1 差异简单归因给 unit partition 或 parent relation。
3. 大仓库差异当前主要由 provider full-repo scan、证据噪声与 30s budget 解释，而不是 OpenAnt “更快”。

---

## 12. 相关产物索引

### OpenAnt round1

- `artifacts/openant_eval/2026-06-28-round1/openant_case_matrix.json`
- `artifacts/openant_eval/2026-06-28-round1/openant_vs_current_comparison.md`
- `artifacts/openant_eval/2026-06-28-round1/failure_taxonomy.md`
- `artifacts/openant_eval/2026-06-28-round1/manifests/openant_b1_batch_analyze_summary.json`
- `artifacts/openant_eval/2026-06-28-round1/manifests/openant_b2_verify_batch_summary.json`

### 结构对比与受控实验

- `artifacts/unit_partition_compare/2026-06-30-e1/unit_partition_diff_report.md`
- `artifacts/unit_partition_controlled_eval/2026-06-30-e1/e1_experiment_report.md`
- `artifacts/unit_partition_controlled_eval/2026-06-30-e1/e1_residual_binding_audit.md`
- `artifacts/unit_partition_controlled_eval/2026-06-30-e2/e2_experiment_report.md`
- `artifacts/unit_partition_controlled_eval/2026-06-30-e2/parser_backlog.md`
- `artifacts/unit_partition_controlled_eval/2026-06-30-e2/module_span_backlog.md`

### 吞吐归因

- `artifacts/throughput_attribution/2026-06-30-round1/hypothesis_assessment.md`
- `artifacts/throughput_attribution/2026-06-30-round2/hypothesis_assessment.md`
- `artifacts/throughput_attribution/ta2-provider-attribution/ta2_provider_attribution_report.md`
