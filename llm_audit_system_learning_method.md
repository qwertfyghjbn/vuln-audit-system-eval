# LLM 漏洞审计系统学习与评估方法

## 1. 背景与目标

在后续学习 LLM 主导的漏洞挖掘 / 代码审计系统时，不应一开始就追求“充分评估每一个系统”，也不应只看最终 `VULNERABLE / SAFE` 结果。更合理的目标是：

1. 理解每个系统如何拆解漏洞审计问题。
2. 识别系统的优势场景、失败模式和工程约束。
3. 判断哪些机制值得迁移到当前 V3 系统。
4. 对少数候选系统做可比的扩大评估。

当前 V3 的定位应从“追求成为最强漏洞检测系统”调整为：

> 可解释对照平台 / 消融实验平台 / 失败模式分析平台。

与此同时，应将更多精力投入到横向学习和评估其他 LLM 审计系统中。

---

## 2. 核心原则

### 2.1 区分“学习系统”和“完整评估系统”

学习一个系统时，重点是理解机制：

- 它如何组织代码上下文？
- 它如何生成候选漏洞？
- 它如何表达漏洞语义？
- 它如何做验证和降噪？
- 它的输出粒度是什么？
- 它为什么会误报、漏报或定位偏移？

完整评估一个系统时，重点才是可比指标：

- recall
- false positive rate
- anchor hit rate
- top-k target hit
- type correctness
- guard awareness
- cost
- reproducibility

不要对每个系统都做大规模完整评估。大规模评估只适用于少数值得深入研究的候选系统。

### 2.2 先小样本诊断，再扩大评估

推荐顺序：

1. 先跑 3–5 个 case，确认能否跑通和输出什么。
2. 再跑 10–15 个 case，分析失败模式。
3. 只有少数系统进入 30–50 个 case 的正式对比。

### 2.3 不要只看“是否报漏洞”

尤其在 repository-level 审计系统中，需要区分：

| 问题 | 含义 |
|---|---|
| finding 是否成立 | 这个 finding 本身是不是一个真实安全问题？ |
| 是否命中 benchmark target | 它是不是评估集标注的目标漏洞？ |
| 是否命中 anchor | 它是否落在 ground truth 文件 / 函数 / 行附近？ |
| 是否 guard-aware | 它是否理解过滤、校验、修复逻辑？ |
| 是否 off-target | 它是否只是发现了仓库里的其他安全问题？ |

例如，OpenAnt 在部分 vulnerable case 上能够产生 `VULNERABLE` 信号，但不一定命中 benchmark 的 ground truth anchor。这说明它更接近 broad repository security scanner，而不天然等于 benchmark target verifier。

---

## 3. 学习每个审计系统时要回答的 6 个问题

每学习一个系统，优先回答以下问题。

### 3.1 代码表示

系统如何表示代码？

常见方式包括：

- 文件级 chunk
- 函数 / 方法
- 类 / 模块
- Unit
- AST
- 调用图
- 数据流图
- patch / diff
- trace
- agent memory

需要关注：

- 是否有显式代码切分？
- 是否支持跨文件上下文？
- 是否支持调用关系？
- 是否支持 source-sink-guard 表达？
- 是否能处理大仓库？

### 3.2 候选生成

系统如何决定哪些代码值得分析？

常见方式包括：

- 全仓库扫描
- 关键字 / regex
- SAST 工具召回
- CodeQL / Semgrep / Bandit / SpotBugs
- LLM 初筛
- changed files / patch 定位
- entrypoint 扩展
- source / sink 搜索
- framework-aware routing

需要关注：

- 候选是否过宽？
- 是否容易漏掉真实目标？
- 是否会被 off-target security smell 带偏？
- 是否有 top-k ranking？

### 3.3 漏洞语义

系统如何表达漏洞类型？

需要观察：

- 是否直接使用 CWE prompt？
- 是否使用规则库？
- 是否使用 SAST 工具结果？
- 是否显式建模 source、sink、guard？
- 是否区分 dangerous evidence 和 protective evidence？
- 是否会发生类型漂移？

重点关注：

> 工具原始告警是否会被错误映射成 benchmark vuln_type。

例如，Bandit 的 `flask_debug_true` 不应直接成为 path traversal / SSTI 的主证据，它最多应作为 `debug_enabled` 辅助风险。

### 3.4 上下文控制

系统给 LLM 什么上下文？

需要观察：

- 当前函数代码
- caller / callee
- imports / symbols
- entrypoint
- source-sink path
- guard / sanitizer
- configuration
- dependency 信息
- test / PoC
- patch diff
- tool evidence
- prior agent notes

关键问题：

- LLM 是否看到了判断漏洞所需的最小上下文？
- 是否塞入太多无关代码导致泛化误报？
- 是否缺失 guard 或调用者信息？

### 3.5 验证机制

系统如何降低误报？

常见方式包括：

- LLM self-check
- verifier / skeptic agent
- multi-agent debate
- dynamic validation
- PoC generation
- test execution
- patch comparison
- tool cross-check
- dataflow confirmation
- guard-aware reasoning

需要区分：

| 验证目标 | 含义 |
|---|---|
| finding validity | 这个 finding 本身是否成立 |
| target alignment | 这个 finding 是否是目标漏洞 |
| exploitability | 是否存在可利用路径 |
| fix awareness | 修复逻辑是否已经阻断漏洞 |

很多系统的 verifier 只能判断 finding 本身是否合理，但不能自动把 off-target finding 迁移到 ground truth anchor。

### 3.6 输出与评估

系统输出什么？

常见输出粒度包括：

- 仓库级 verdict
- 文件级 verdict
- 函数级 finding
- 行级定位
- CWE / vuln_type
- source-sink path
- exploit scenario
- patch / fix suggestion
- confidence
- needs_review

需要关注：

- 输出是否可解析？
- 是否支持定位到函数 / 行？
- 是否有 evidence chain？
- 是否能区分 confirmed、needs_review、safe？
- 是否能用于自动评估？

---

## 4. 三阶段实践流程

## 阶段 A：机制复现

### 目标

搞清楚系统到底怎么工作，而不是判断它是否强。

### 样本数量

3–5 个 case。

### 推荐样本构成

| 类型 | 数量 | 目的 |
|---|---:|---|
| 简单 vulnerable | 1 | 看是否能发现明显漏洞 |
| 简单 near-miss | 1 | 看是否会看到危险 API 就误报 |
| repo-level vulnerable | 1 | 看跨文件上下文能力 |
| fixed / patch pair | 1 | 看是否理解修复逻辑 |
| 大仓库 case | 0–1 | 看吞吐和候选收敛能力 |

### 记录内容

```text
case_id:
label:
vuln_type:
input_mode:
system_verdict:
top_finding_location:
top_finding_type:
anchor_match:
guard_match:
off_target:
run_time:
cost:
failure_reason:
notes:
```

### 阶段 A 不应做的事

- 不下最终性能结论。
- 不统计复杂指标。
- 不急着扩大评估集。
- 不为了跑通一个系统无限修环境。

---

## 阶段 B：诊断性小评估

### 目标

识别系统的失败模式。

### 样本数量

10–15 个 case。

### 评估重点

| 维度 | 说明 |
|---|---|
| vulnerable recall | 真实漏洞是否产生阳性信号 |
| near-miss FP | 负样本 / 修复样本是否误报 |
| anchor match | 是否命中 ground truth anchor |
| top-k hit | 目标漏洞是否出现在候选前 k 个 |
| off-target | 是否报了仓库里的其他安全问题 |
| type correctness | CWE / vuln_type 是否正确 |
| guard awareness | 是否识别过滤、校验、修复 |
| explanation quality | 是否能解释 source-sink-guard |
| cost | 时间、token、人工 review 成本 |
| reproducibility | 多次运行是否稳定 |

### 输出形式

阶段 B 的主要产物不是排行榜，而是 failure taxonomy。

示例分类：

| 类型 | 含义 |
|---|---|
| no_signal | 没有发现任何相关信号 |
| strict_veto | 已有候选但被严格 gate 压掉 |
| off_target | 报了安全问题，但不是目标漏洞 |
| anchor_mismatch | 漏洞类型对，但定位不对 |
| guard_scope_miss | 没有识别修复 / 防护逻辑 |
| type_drift | 工具告警或语义被映射成错误漏洞类型 |
| broad_scan_noise | 大仓库上产生大量宽泛 finding |
| timeout | 系统无法在预算内完成 |

---

## 阶段 C：扩大评估

### 目标

对少数候选系统做相对正式的可比评估。

### 进入条件

一个系统只有满足以下条件，才值得进入扩大评估：

1. 能稳定跑通。
2. 输出格式可解析。
3. 在小评估中表现出值得研究的机制。
4. 与 V3 / OpenAnt 有明显不同设计。
5. 有可迁移到 V3 或后续研究的价值。

### 样本数量

30–50 个 case。

### 适用对象

最多选择 2–3 个系统：

- OpenAnt
- V3-fixed
- 另一个机制差异明显的 LLM audit 系统
- 一个传统 SAST / CodeQL / Semgrep baseline

不要让所有系统都进入扩大评估。

---

## 5. 分层评估集设计

## 5.1 Level 1：Smoke Set

### 用途

快速判断系统能否跑通、输入输出是什么样。

### 建议规模

3–5 个 case。

### 建议构成

| 类型 | 数量 |
|---|---:|
| 简单 vulnerable | 1 |
| 简单 near-miss | 1 |
| repo-level vulnerable | 1 |
| fixed / patch pair | 1 |
| 大仓库 case | 0–1 |

### 使用对象

所有新系统。

---

## 5.2 Level 2：Diagnostic Set

### 用途

诊断失败模式，比较系统设计差异。

### 建议规模

10–15 个 case。

### 建议构成

| 类型 | 数量 |
|---|---:|
| Path Traversal vulnerable | 2 |
| Path Traversal near-miss / fixed | 2 |
| SSRF vulnerable | 2 |
| SSRF near-miss / fixed | 2 |
| SSTI vulnerable | 2 |
| SSTI near-miss / fixed | 2 |
| 大仓库 CVE | 2–3 |

### 使用对象

值得继续观察的系统。

---

## 5.3 Level 3：Focused Benchmark

### 用途

正式比较少数候选系统。

### 建议规模

30–50 个 case。

### 指标

| 指标 | 含义 |
|---|---|
| vulnerable recall | 是否发现真实漏洞 |
| near-miss false positive rate | 是否误报负样本 / 修复样本 |
| top-1 anchor hit | 首个 finding 是否命中目标 |
| top-k anchor hit | 目标是否出现在候选前 k 个 |
| off-target rate | 是否报了仓库中其他安全问题 |
| type correctness | CWE / vuln_type 是否正确 |
| guard awareness | 是否识别过滤、校验、修复 |
| cost per case | 时间、token、人工 review 成本 |
| reproducibility | 多次运行是否稳定 |

### 使用对象

少数最终候选系统。

---

## 6. 评估集优先补充方向

后续扩展评估集时，不应平均扩展，而应优先补充能区分系统能力的 case。

### 6.1 Near-miss / fixed pair

最能暴露误报问题。

优先补充：

- 有路径规范化和目录限制的 Path Traversal。
- 有 allowlist / blocklist 的 SSRF。
- 使用 safe template rendering 的 SSTI。
- vulnerable / fixed diff 很小的 CVE pair。

### 6.2 Off-target 干扰样本

仓库中存在其他安全 smell，但 benchmark 目标漏洞已经修复或不存在。

目的：

> 测试系统能否区分“仓库里有安全问题”和“目标漏洞存在”。

### 6.3 Anchor-sensitive 样本

仓库中存在多个相似 sink，但只有其中一个是目标漏洞。

目的：

- 测试 top-1 anchor hit。
- 测试 top-k anchor hit。
- 测试 target-aware ranking。

### 6.4 大仓库预算样本

数量不需要多，2–3 个即可。

观察：

- 是否 timeout。
- 是否能把目标区域排进 top-k。
- 是否产生大量 irrelevant vulnerable。
- 单 case 人工 review 成本有多高。

### 6.5 Java 样本

如果后续关注 Java，应谨慎增加。

原因：

- Java 涉及 build / compile。
- 依赖 classpath / jar。
- Spring 等框架语义复杂。
- CodeQL / SpotBugs / FindSecBugs 适配成本更高。

建议先补：

- 2 个小型 Java synthetic。
- 1 个真实 Java CVE vulnerable。
- 1 个 fixed pair。

---

## 7. 每个系统的学习卡片模板

每学习一个系统，产出一页学习卡片。

```text
系统名称：

系统定位：
- broad repository scanner / target verifier / patch auditor / SAST-assisted agent / dynamic validator / other

核心思想：

代码切分方式：

上下文组织方式：

候选生成方式：

漏洞语义来源：

验证方式：

输出粒度：

最强能力：

最明显局限：

在 Smoke Set 上的表现：

典型成功 case：

典型失败 case：

失败模式：
- no_signal:
- off_target:
- anchor_mismatch:
- guard_scope_miss:
- type_drift:
- timeout:
- broad_scan_noise:

可迁移到 V3 的设计：

不适合迁移的设计：

是否值得进入 Diagnostic Set：
- 是 / 否

原因：
```

---

## 8. 单 case 深挖模板

每个系统至少深挖一个成功 case 和一个失败 case。

```text
case_id:
system:
label:
vuln_type:

1. 系统最终输出
- verdict:
- top finding:
- CWE / type:
- confidence:
- explanation:

2. Ground Truth
- target file:
- target function:
- target line:
- expected source:
- expected sink:
- expected guard / fix:

3. 对齐情况
- anchor_match:
- target_alignment:
- guard_match:
- type_correct:
- off_target:

4. 系统看到了什么
- code context:
- tool evidence:
- caller / callee:
- dataflow:
- patch / diff:
- config:

5. 系统没看到什么
- missing guard:
- missing source:
- missing sink:
- missing caller:
- missing framework semantics:
- missing patch context:

6. 错误来源
- candidate generation:
- ranking:
- context packing:
- semantic reasoning:
- verifier:
- output parsing:
- benchmark mismatch:

7. 结论
- finding 本身是否成立:
- 是否是目标漏洞:
- 是否说明系统能力:
- 是否说明评估集问题:
- 对 V3 的启发:
```

---

## 9. 系统是否值得深挖的判断标准

一个系统值得继续评估，不一定是因为它小样本表现最好，而是因为它有可学习机制。

### 值得深挖的特征

- 有明确代码切分策略。
- 有显式候选生成机制。
- 有 target-aware ranking 或定位逻辑。
- 有 guard-aware verification。
- 有 patch / fixed pair 分析。
- 有 dynamic validation 或 PoC 验证。
- 能输出可解析 evidence。
- 能在大仓库中控制候选规模。
- 与 V3 / OpenAnt 的机制明显不同。

### 不值得深挖的特征

- 只是简单 prompt wrapper。
- 输出不可解析。
- 无法定位到代码位置。
- 无法稳定复现。
- 环境适配成本极高但机制不清晰。
- 小样本中只有仓库级泛泛结论。
- 不能区分 finding validity 与 target alignment。

---

## 10. V3 后续角色与改进边界

V3 不应继续无限扩展为大型 SAST-like 系统。

后续 V3 的主要价值是：

1. 作为对照平台。
2. 作为消融实验平台。
3. 作为 failure taxonomy 生成平台。
4. 作为其他系统机制迁移的试验平台。

### V3 优先保留的改进方向

| 优先级 | 方向 | 目的 |
|---|---|---|
| P0 | provider evidence type drift 修复 | 避免工具告警被映射成错误 vuln_type |
| P1 | target alignment 层 | 区分真实 finding 与目标漏洞 |
| P1 | strict gate ablation | 判断真阳性是否被 gate 压掉 |
| P2 | guard-aware verification | 降低 near-miss / fixed 误报 |
| P2 | top-k anchor ranking | 判断目标漏洞是否进入候选集 |
| P3 | 大仓库预算调度 | 提升大仓库下目标区域召回 |

### 不建议投入过多的方向

- 继续堆大量关键词规则。
- 继续手工补 deterministic 漏洞语义规则。
- 为每个失败 case 定制后处理。
- 过早支持太多语言。
- 在没有修复 evidence/type/anchor 问题前扩大 LLM verifier 权限。

---

## 11. 推荐工作流

### Step 1：整理当前 OpenAnt vs V3 结果

补充：

- top-k anchor hit
- Stage2 完整回填
- finding_validity vs target_alignment
- near-miss / fixed false positive
- 大仓库 broad scan noise
- 运行成本

### Step 2：固定 Smoke Set

选择 3–5 个稳定 case，用于所有新系统。

### Step 3：扩展 Diagnostic Set 到 12–15 个 case

在当前 8 个 case 基础上补充：

- 2 个 near-miss / fixed。
- 2 个 anchor-sensitive vulnerable。
- 1–2 个大仓库或 Java case。

### Step 4：选择下一个系统

优先选择机制差异明显的系统，例如：

- patch-aware 系统
- dynamic validation 系统
- CodeQL / Semgrep-assisted 系统
- multi-agent skeptic verifier 系统
- repository-level context ranking 系统

### Step 5：先跑 Smoke Set

只判断：

- 能否跑通。
- 输出是否可解析。
- 是否有明显机制价值。
- 是否值得进入 Diagnostic Set。

### Step 6：对值得的系统跑 Diagnostic Set

输出：

- 学习卡片。
- failure taxonomy。
- 可迁移机制。
- 不适合迁移的机制。

### Step 7：少数系统进入 Focused Benchmark

最多 2–3 个系统进入 30–50 case 正式评估。

---

## 12. 最终方法论总结

后续学习 LLM 漏洞审计系统时，应采用：

> 小集合高质量诊断，多系统横向理解；少数候选再扩大评估。

具体来说：

1. 不充分评估每一个系统。
2. 所有系统先跑 3–5 case Smoke Set。
3. 值得继续看的系统再跑 10–15 case Diagnostic Set。
4. 只有少数候选系统进入 30–50 case Focused Benchmark。
5. 每个系统都要产出机制分析、学习卡片和失败 taxonomy。
6. V3 继续作为可解释对照平台，而不是无限扩展的大型漏洞扫描器。
7. 评估时必须区分 finding validity、target alignment、anchor match、guard awareness 和 off-target issue。

最终目标不是得到一个简单排行榜，而是理解：

- 为什么系统会误报？
- 为什么系统会漏报？
- 为什么 Stage2 不能 re-anchor？
- 为什么大仓库 broad scan 会 precision 失控？
- 哪些机制真正值得迁移到 V3 或后续研究中？
