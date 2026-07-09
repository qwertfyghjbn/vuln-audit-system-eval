# Agent 评估与学习规则

## 1. 目的

这份文件约束后续用于漏洞审计的 agent 在本仓库上的学习、调试和评估行为，避免：

- 用 benchmark 标注反向污染 agent
- 在单个 case 上过度 prompt-tune
- 把 off-target finding 误当成目标命中
- 把“学机制”和“刷分”混在一起
- 因运行预算、工具配置、日志缺失导致结果不可比

本文件是对 [llm_audit_system_learning_method.md](/home/lqs/llm_audit_system_learning/llm_audit_system_learning_method.md) 的执行层补充。方法文档讲原则；本文件讲约束。

## 2. 适用范围

适用于所有在本仓库 `datasets/` 上运行的系统，包括但不限于：

- 单 agent 审计器
- 多 agent 审计器
- SAST-assisted agent
- patch verifier
- broad repository scanner
- target-aware verifier

## 3. 术语

- `学习`：理解系统机制、输入输出、失败模式，不以最终分数为首要目标。
- `评估`：在冻结配置下运行一批 case，产出可比较结果。
- `case`：`datasets/` 下的一个独立样本目录。
- `target vulnerability`：该 case 的 ground truth 主目标漏洞。
- `off-target finding`：finding 本身可能真实，但不是 benchmark 标注目标。
- `anchor hit`：finding 命中 ground truth 指定的文件 / 函数 / 行范围。
- `near_miss`：表面看起来危险，但保护逻辑足以阻断漏洞的样本。

## 4. 硬性规则

### 4.1 禁止标注泄漏

在正式评估运行中，agent 不得读取或使用：

- `ground_truth.json`
- `case.yaml` 中的 `label`
- README 中显式给出的“正确答案”段落

允许使用的输入应仅限于：

- `input.primary_file`
- `input.context_files`
- `input.repo_root`
- 用户显式允许的补充上下文

如果为了实现 runner 需要读取 `case.yaml`，只能读取输入路径与元数据，不能把 `label`、`expected_findings`、`should_not_report` 注入 agent prompt。

### 4.2 学习与评估必须分离

同一系统在同一轮中必须区分两个阶段：

1. 学习阶段：允许少量抽样、人工阅读结果、总结失败模式。
2. 评估阶段：冻结 prompt、工具链、预算和后处理逻辑后批量运行。

一旦进入评估阶段，不得因为某个 case 结果不好就修改：

- system prompt
- verifier prompt
- tool selection
- ranking 逻辑
- parsing 逻辑
- budget

如果确需修改，必须视为新版本，重新记录版本号并从新一轮开始。

### 4.3 每轮评估必须冻结配置

每一轮评估必须固定以下内容：

- agent 版本 / commit
- prompt 版本
- 模型名称
- temperature / seed / max tokens
- 检索策略
- 工具清单
- 超时
- 每 case 最大轮数
- 每 case 最大 token / 成本预算
- 后处理与判定规则

未冻结配置的结果不进入正式比较。

### 4.4 先小样本诊断，再扩大规模

禁止新系统直接跑完整评估集。

推荐顺序：

1. `3-5` 个 case 的 smoke 学习
2. `10-15` 个 case 的诊断性评估
3. `30-50` 个 case 的扩大评估

只有在前一阶段已经满足“可稳定运行、输出可解析、值得研究”后，才进入下一阶段。

### 4.5 不能只看 verdict

任何评估都不能只记录 `VULNERABLE / SAFE`。至少必须同时判断：

- finding 是否成立
- 是否命中 benchmark target
- 是否命中 anchor
- 是否理解 guard / fix
- 是否属于 off-target

### 4.6 `near_miss` 与 `vulnerable` 同等重要

对 `near_miss` case，不允许把“报出可疑 API”记为部分得分。核心检查是：

- agent 是否识别主 guard
- agent 是否避免把修复后代码误报为漏洞
- agent 是否把 source-sink 表象和真实 exploitability 区分开

### 4.7 不得按 case 单独调参

禁止以下行为：

- 针对某个 case 名称写特殊 prompt 分支
- 针对某个 CVE 写 hardcoded 规则
- 针对某类路径写 case-specific allowlist
- 根据 ground truth 文件名反向引导检索

允许的是：

- 针对 `path_traversal / ssrf / ssti` 这类通用漏洞语义做统一建模
- 针对 `file / repo` 两种输入模式做统一策略区分
- 针对语言差异做统一的 Python / Java 分流

### 4.8 所有失败都要归因

正式评估输出中，每个失败 case 至少归入以下之一：

- `no_signal`
- `strict_veto`
- `off_target`
- `anchor_mismatch`
- `guard_scope_miss`
- `type_drift`
- `broad_scan_noise`
- `timeout`
- `parse_failure`
- `runtime_failure`

没有 failure taxonomy 的评估结果不完整。

### 4.9 允许学习，但必须版本化

从一轮评估中学到的经验可以用于改系统，但必须：

1. 总结成规则或设计改动
2. 写入版本说明
3. 在新版本上重新跑评估

禁止把上一轮 case 的答案直接塞回 prompt 当“经验”。

### 4.10 保留可复现日志

每个 case 至少保留：

- 输入路径
- 运行开始/结束时间
- 原始 agent 输出
- 解析后结构化结果
- token / 成本
- top finding
- failure taxonomy

没有原始日志的结果默认不可审计。

## 5. 推荐流程

### 5.1 学习阶段

目标是理解机制，不追求分数。

要求：

- 只抽样少量 case
- 允许人工阅读 README 和 ground truth
- 重点记录 source-sink-guard 理解能力、候选生成方式、输出粒度、误报模式

产物：

- 系统学习卡片
- 初步 failure taxonomy
- 是否值得进入正式评估的判断

### 5.2 诊断评估阶段

目标是识别失败模式。

要求：

- 冻结配置
- 跑 `10-15` 个 case
- vulnerable 与 near_miss 都覆盖
- 至少覆盖 `PT / SSRF / SSTI`
- 至少包含若干 repo-level case

产物：

- recall / anchor / off-target / guard-awareness 的初步画像
- 失败模式分布
- 是否进入扩大评估

### 5.3 扩大评估阶段

目标是对少数候选系统做相对正式的可比评估。

要求：

- 候选系统数量最多 `2-3`
- 配置完全冻结
- 保留完整日志
- 输出统一结果表

## 6. 每个 case 的最小记录字段

建议至少记录：

```text
run_id:
system_name:
system_version:
case_id:
label_blinded:
vuln_type:
input_mode:
system_verdict:
top_finding_valid:
top_finding_type:
top_finding_location:
anchor_match:
target_match:
guard_match:
off_target:
failure_reason:
runtime_seconds:
token_cost:
notes:
```

说明：

- `label_blinded` 表示评估时 agent 本身不知道真实标签。
- `target_match` 与 `top_finding_valid` 必须分开记录。

## 7. 判定规则

### 7.1 vulnerable case

至少分别判断：

- 是否有真实 finding
- finding 类型是否正确
- 是否命中目标 anchor
- 是否解释出主要 source / sink / propagation

### 7.2 near_miss case

至少分别判断：

- 是否避免误报
- 是否识别主 guard
- 是否理解修复阻断点在 sink 前还是 sink 后
- 是否把“危险表象”与“真实可利用漏洞”区分开

### 7.3 repo-level case

额外判断：

- 是否只报 broad security smell
- 是否能把目标区域排进 top-k
- 是否出现大量人工不可审的噪声

## 8. 明确禁止的做法

- 读 `ground_truth.json` 后再让 agent 做正式判断
- 根据 README 的“正确系统应报告什么”构造答案
- 在某个 case 失败后立刻为该 case 单独改 prompt 并继续算同一轮结果
- 把 off-target finding 算成 target hit
- 把 near_miss 上的高置信误报解释为“有安全意识”
- 因为系统跑不通就无限修环境，直到失去比较公平性
- 不保留原始输出，只保留人工总结

## 9. 例外处理

如果出现以下情况，可以中止当前轮次：

- 关键依赖无法稳定运行
- 输出无法解析
- 多次运行波动过大
- 成本超预算

但必须记录：

- 中止原因
- 已完成 case
- 未完成 case
- 是否计划在新版本重跑

## 10. 建议落地方式

后续如果要实现 runner，建议把本文件固化成三类检查：

- `pre-run checks`：是否屏蔽 ground truth、是否冻结配置
- `run-time checks`：是否超预算、是否保留原始日志
- `post-run checks`：是否产出统一字段、是否归类 failure taxonomy

这样 agent 就不是“被口头要求自律”，而是被流程约束。
