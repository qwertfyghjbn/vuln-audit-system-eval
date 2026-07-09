# 架构归因实验总规划

## 1. 文档定位

本文是 `Architecture Attribution Experiment` 的第一轮总规划。

这条实验线与 `IRIS`、`DeepAudit` 的系统评估线同级，但它不是一个新的系统评估结果目录。它的目标是验证 workflow 架构变量是否解释了不同系统之间的表现差异，尤其是 `Static-tool Constraint Strength` 是否限制了 LLM 的漏洞审计能力。

本规划不是：

- `IRIS` 的 capability-changing variant 结果
- `DeepAudit` 的新评估结果
- `OpenAnt` 的第二轮评估
- 正式 benchmark 排名

## 2. 核心假设

第一轮主假设是：

> 在同一个 `Case`、同一个模型、相近运行条件下，静态工具证据对 LLM reasoning 的约束越强，`target-aligned recall` 越容易下降；但 off-target finding 和不可解释泛化也可能下降。

因此，本实验不预设“静态工具不好”。它要观察的是一条 trade-off 曲线：

- 强约束 workflow 是否更可控但更容易漏掉 target path
- 弱约束 workflow 是否释放 LLM 语义推理但更容易产生 off-target finding
- agentic workflow 的优势是否来自架构本身，还是来自更多输入信息

## 3. 术语边界

本实验使用以下仓库术语：

- `Architecture Attribution Experiment`
- `Static-tool Constraint Strength`
- `Differential Semantic Evaluation`
- `Case Family`
- `Target Vulnerability`
- `Off-target Finding`
- `Experiment-side Configuration`

相关术语定义见 [CONTEXT.md](/home/lqs/llm_audit_system_learning/CONTEXT.md:1)。

## 4. 实验对象边界

第一轮范围：

- 主归因对象：`IRIS-style static-gated workflow`
- 外部参照：`DeepAudit`
- 暂不进入第一轮主矩阵：`OpenAnt`

`OpenAnt` 延后到第二阶段的原因是：它的 unit、exposure、reachability 与 verify 机制和 `IRIS-style` 的 CodeQL source/sink/path workflow 不同。第一轮同时纳入 OpenAnt 会让自变量混入 unit boundary、broad scanner、verify 不重锚等因素。

## 5. 第一轮 Case Family

第一轮固定 3 个 `Case Family`：

| 角色 | Case Family | 选择原因 |
|---|---|---|
| candidate gate 正例 | `SSRF-JA-REPO-001` | 既有 7-family 结果中唯一 `candidate-selection dominant`；补回 `RestTemplate.getForObject` 后最小 oracle 可恢复 target hit。 |
| query/path 语义正例 | `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED` | sink 与 summary 已在，但 source 对准错误语义片段；同时具备 vulnerable/fixed pair。 |
| summary/bridge 语义正例 | `jmrozanec__cron-utils_CVE-2021-41269_9.1.5` | source 参数和 sink 已存在，疑似缺少 `Throwable.getMessage` summary bridge。 |

候补 family：

- `PT-JA-REPO-CVE-2024-53677-VULN`
- `vert-x3__vertx-web_CVE-2018-12542_3.5.3.CR1`

候补 family 不进入第一轮主矩阵，除非第一轮运行暴露出选例无法覆盖预期因果分支。

## 6. 实验矩阵

第一轮采用 `minimal causal matrix`，不做全量交叉。

### 6.1 E1 Static-gate Oracle

目标：验证失败是否来自静态候选、路径或输入切片 hard gate。

适用范围：3 个 family 全跑。

| 版本 | 改动 | 判定含义 |
|---|---|---|
| `A original` | 不改原始 workflow | 复现当前失败。 |
| `B oracle candidate` | 手工加入真实 source/sink/wrapper 候选 | 如果成功，说明 candidate gate 是主因。 |
| `C oracle summary/path` | 手工加入关键 propagator 或 summary | 如果 B 不成功而 C 成功，说明 dataflow/summary/path modeling 是主因。 |
| `D oracle slice` | 加入完整 caller-side 文件、真实入口和依赖 | 如果 C 不成功而 D 成功，说明 build/slice 边界是主因。 |

判定规则：

- `B` 成功：早期候选过滤限制了 LLM 或后续 path 形成。
- `B` 不成功、`C` 成功：静态 dataflow 或 summary 建模限制了系统。
- `C` 不成功、`D` 成功：输入切片或构建边界限制了系统。
- `D` 仍不成功，但 DeepAudit 在低信息条件下成功：支持 agentic/semantic workflow 优势假设。

### 6.2 E2 LLM Freedom Ladder

目标：验证 LLM 是否被 workflow 表示形式限制。

适用范围：3 个 family 全跑。

| 模式 | LLM 能看到什么 | LLM 能做什么 |
|---|---|---|
| `M1 original` | 原始候选 API 列表 | 只能标 source/sink/taint propagator。 |
| `M3 target-context constrained` | 候选与漏洞目标方法上下文 | 判断 source/sink/path 是否合理，但仍受结构化输出约束。 |
| `M4 free auditor` | 同样文件或上下文 | 不强制 CodeQL 标签格式，自由描述漏洞路径。 |
| `M5 agentic auditor` | 可检索 repo、追调用链、查看必要上下文 | 形成假设、验证、修正。 |

第一轮暂不跑 `M2 candidate API + source window`。它与 `M3` 的区分度不足，优先级低于保持矩阵可控。

核心判定：

- 如果 `M4/M5` 能稳定指出 target vulnerability，而 `M1/M3` 失败，说明问题更可能来自 workflow 表示约束，而不是模型本身不会推理。
- 如果 `M5` 成功但 `M4` 失败，需要记录 tool calls、读取文件数和上下文规模，避免把信息量优势误判为 agentic 能力优势。

### 6.3 E3 Tool Authority Ablation

目标：验证静态工具在 prompt 和 workflow 中是否变成高权威先验，压制 LLM 主动质疑和补全。

适用范围：

- `SSRF-JA-REPO-001`
- `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED`

第一轮暂不优先跑 `cron-utils`，因为它更适合 summary/bridge 归因。

| 条件 | 提示形态 | 观察点 |
|---|---|---|
| `A strong authority` | 强提示 CodeQL 未找到 path，并给出候选 source/sink 列表 | LLM 是否顺从工具结论。 |
| `B weak authority` | 只给相关文件和调用关系，提示不要假设静态分析完整 | LLM 是否主动推断漏掉的 wrapper/source/sink。 |
| `C faulty tool injection` | 故意给不完整 source/sink 列表 | LLM 是否挑战工具输出。 |

核心判定：

- 如果 LLM 在 `B/C` 能指出工具漏掉 wrapper/source/sink，但在 `A` 中顺从 no path，则支持“静态工具权威先验限制 LLM”的假设。

### 6.4 E4 DeepAudit Information Advantage Control

目标：控制 DeepAudit 是否因为拿到更多信息而表现更强。

适用范围：

- `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED`
- `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`

| 条件 | CVE 描述 | patch/fixed diff | 目标文件 | 目的 |
|---|---|---|---|---|
| `D1` | 否 | 否 | 否 | 观察纯仓库审计能力。 |
| `D2` | 是 | 否 | 否 | 观察 CVE hint 带来的优势。 |
| `D4` | 是 | 是 | 是 | 观察最大信息条件。 |

第一轮暂不跑 `D3 CVE + diff + no target files`。如果后续需要单独拆解 diff 与 target_files 的贡献，再补为第二轮。

核心判定：

- 如果 DeepAudit 只有在 `D4` 成功，而 `D1/D2` 不成功，它的优势可能主要来自信息优势。
- 如果 DeepAudit 在 `D1/D2` 也明显优于 IRIS-style workflow，则更支持 agentic 探索能力或更弱静态约束的架构优势。

## 7. 共享评价轴

第一轮所有实验共享 `Differential Semantic Evaluation`，尤其用于 vulnerable/fixed pair。

最少记录以下字段：

- `vulnerable_path_explained`
- `fixed_guard_explained`
- `minimal_semantic_delta`
- `fix_type_classification`
- `target_alignment`
- `off_target_finding`
- `guard_awareness`
- `cost_tokens`
- `wall_time_seconds`
- `tool_call_count`
- `context_volume`

对 fixed 或 near-miss case，`no path` 只能算必要现象，不能直接算理解修复语义。必须检查系统是否解释了 guard、sanitizer、allowlist、canonicalization、permission check 或 path restriction。

## 8. 预算与运行原则

第一轮优先级是：正常跑完实验，高于严格预算压缩。

预算原则：

- 模型统一来自当前 `Experiment-side Configuration`。
- 记录每个 run 的成本、耗时、token、tool call 和上下文规模。
- 不因为追求绝对等预算而提前截断关键 run。
- 对 `M5 agentic auditor` 和 DeepAudit 条件，必须记录它们额外读取了哪些文件、使用了多少上下文，否则不能把成功直接归因于架构。

当前经验显示，DeepAudit 在上千文件自有 case 上使用 DeepSeek 单次成本约为 2-3 元，因此第一轮以完成可解释运行为主。

## 9. 证据落点

人读入口：

- `reports/systems/architecture-attribution/`

原始证据：

- `artifacts/architecture_attribution/`

禁止混写：

- 不把新结果写入 `reports/systems/iris/`
- 不把新结果写入 `artifacts/iris_*`
- 不把 DeepAudit 控制实验写入 `artifacts/deepaudit_*`

允许引用既有证据，但新实验的 run manifest、输入物化、原始输出、规范化表都应保存在本实验线下。

## 10. 第一轮预计运行量

按当前最小矩阵估算：

- `E1`: 3 family x 4 versions = 12 runs
- `E2`: 3 family x 4 modes = 12 runs
- `E3`: 2 family x 3 conditions = 6 runs
- `E4`: 2 family x 3 conditions = 6 runs

预计总量：约 36 runs。

该数字是规划估算，不是硬性配额。若某个 family 在早期模式已经给出清晰因果分支，可以在 summary 中记录后停止同类重复。

## 11. 成功与失败解释规则

本实验只在满足以下条件时支持“workflow 架构限制 LLM”：

1. 原始 static-gated workflow 失败。
2. 更弱静态约束或更高 LLM 自由度条件能恢复 target-aligned reasoning。
3. 信息优势已被控制或记录。
4. 恢复结果不只是 off-target finding。
5. vulnerable/fixed 差分语义能够被解释，而不只是 vulnerable 报告更多。

如果 DeepAudit 只在高信息条件下成功，本实验不能把它解释为架构优势。

如果 free auditor 或 agentic auditor 成功但不能解释 fixed side，本实验只能说明 recall 改善，不能说明 differential semantic understanding 改善。

## 12. 后续阶段

第二阶段候选方向：

- 把 `OpenAnt` 纳入同一 `Static-tool Constraint Strength` 框架。
- 补跑 `E4 D3`，拆解 diff 与 target_files 的相对贡献。
- 扩展到 `PT-JA-REPO-CVE-2024-53677-VULN` 和 `vert-x3__vertx-web_CVE-2018-12542_3.5.3.CR1`。
- 建立 `canonical_results.tsv` 和 `evidence_index.json`。
