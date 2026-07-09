# IRIS Candidate-Selection 验证计划

## 1. 作用

这份计划用于单独验证以下问题：

> `IRIS` 当前 5-case 官方行为线里的 `source` 缺失，是否主要来自 `candidate-selection` 阶段把关键内部包装 API 挡在了 Stage 3 之外？

这条线属于 `capability-changing variant`，不并回官方行为线。

## 2. 问题拆分

当前需要区分两个判断：

1. `H1`
   - 关键 `source-like` / `boundary-like` API 根本没有进入 Stage 3
   - 主要原因是 `keep_external_packages()` 把项目内包装 API 过滤掉

2. `H2`
   - 关键 API 已经进入 Stage 3
   - 但 prompt / LLM 标签逻辑没有把它们识别成 `source`

如果 `H1` 更接近事实，那么第一轮最小修复不应改 prompt，而应只改 `candidate-selection`。

## 3. 实验边界

这轮验证必须遵守以下边界：

1. 官方行为线保持冻结
   - 当前基线为 `OFFICIALSMOKE01 + iris-runtime-compat-001`

2. baseline 诊断阶段不改 `IRIS` 逻辑
   - 只复用现有 `OFFICIALSMOKE01` 产物做差集分析

3. 第一轮能力实验只改一个变量
   - 仅改 `candidate-selection`
   - 不改 prompt
   - 不改 ranking
   - 不改 post-processing
   - 不改 benchmark 输入边界

4. 所有能力改动必须挂到单独变体
   - 计划变体：`iris-capability-candsel-001`

## 4. 代表性 case 选择

第一轮只使用 3 个 case：

1. `PT-JA-REPO-CVE-2024-53677-VULN`
   - 当前表现为只产出 `taint-propagator`
   - 用于验证 `PT` 下 source-like 包装 API 是否被挡掉

2. `SSRF-JA-REPO-CVE-2023-3432-VULN`
   - 当前表现为有 `sink` / `taint-propagator`，但 `source = 0`
   - 用于验证 `SSRF` 下内部网络包装 API 是否被挡掉

3. `SSRF-JA-REPO-CVE-2023-3432-FIXED`
   - 与对应 `VULN` case 形成配对
   - 用于观察放宽候选后是否还能保持 `VULN / FIXED` 分化

## 5. 实验分阶段

### 5.1 Phase A: Baseline 诊断

目标：

- 固化 `OFFICIALSMOKE01` 里每个代表性 case 的：
  - Stage 1 原始 API 集合
  - internal package 过滤差集
  - Stage 3 实际候选集合
  - Stage 3 标签结果

产物：

- [artifacts/iris_candidate_validation/BASELINE_CANDSEL_DIAG01/summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_candidate_validation/BASELINE_CANDSEL_DIAG01/summary.tsv:1)
- [artifacts/iris_candidate_validation/BASELINE_CANDSEL_DIAG01/README.md](/home/lqs/llm_audit_system_learning/artifacts/iris_candidate_validation/BASELINE_CANDSEL_DIAG01/README.md:1)

进入条件：

- `OFFICIALSMOKE01` 已完成

退出条件：

- 三个 case 都有可审计的候选差集记录

### 5.2 Phase B: 最小 candidate-selection 变体

目标：

- 验证只放宽一小类内部包装 API 后，`llm_sources` 是否会从 `0` 变为 `>0`

拟议改动范围：

- 仅调整 `keep_external_packages()` 之后的保留条件
- 保守引入项目内、且满足 source-like / boundary-like 特征的包装 API
- 不把所有 internal API 全量放进 Stage 3

拟议实现方向：

1. 保留当前 external candidate 逻辑不变
2. 额外引入一小类 internal wrapper candidate
3. internal wrapper 的第一版筛选只基于：
   - 函数名模式
   - 返回类型模式
   - 少量与 `PT` / `SSRF` 高相关的语义边界

进入条件：

- Phase A 已证明三条代表性 case 都存在“关键内部 API 未进入 Stage 3”的强信号

退出条件：

- 产生首轮 capability run

### 5.3 Phase C: 结果判定

第一轮 capability run 只看以下 4 个指标：

1. `llm_sources`
   - 是否从 `0` 变成 `>0`

2. final path
   - 最终 `results.csv` 是否首次非空

3. `VULN / FIXED` 分化
   - `SSRF-3432-VULN` 与 `SSRF-3432-FIXED` 是否开始出现差异

4. 候选爆炸风险
   - candidate 数量是否失控增长
   - 是否明显引入大量离题 label

判定规则：

- 若 `llm_sources` 仍然全部为 `0`
  - 说明问题不主要在 `candidate-selection`
- 若 `llm_sources > 0`，但 final path 仍然全空
  - 说明 `candidate-selection` 不是唯一瓶颈
- 若 `VULN` 出信号而 `FIXED` 也同步大幅出信号
  - 说明放宽过粗，存在明显噪声问题
- 若 `VULN` 首次出信号且 `FIXED` 仍接近 `no_signal`
  - 说明这个方向值得扩展

## 6. 当前启动状态

截至 `2026-07-03`，这条验证线已经启动到 Phase A。

已完成：

1. baseline 诊断运行：
   - `diagnostic_run_id = BASELINE_CANDSEL_DIAG01`

2. 已确认 3 个代表性 case 都出现同一模式：
   - `llm_sources = 0`
   - 存在被 internal/external 边界挡掉的关键内部包装 API

3. 已确认 `PT` 与 `SSRF` 两类问题都不是“Stage 3 完全没有候选”
   - 而是“Stage 3 候选集合偏向 JDK / 外部库基础 API”

对应阶段总结见：

- [iris_candidate_selection_baseline_diagnosis.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_candidate_selection_baseline_diagnosis.md:1)

## 7. 下一步

按当前证据，最合理的下一步是：

1. 登记 `iris-capability-candsel-001`
2. 只实现最小 internal wrapper 放宽逻辑
3. 先重跑 3 个代表性 case
4. 只有当 `source` 数量或最终 path 确实改变，才扩到完整 5-case
