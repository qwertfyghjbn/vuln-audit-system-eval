# File/Repo Timing Comparison

## 摘要

- 首轮 file 总时长: `150.904` 秒
- 首轮 repo 总时长: `275.742` 秒
- 首轮 instant 总时长: `24.0` 秒
- 首轮 file 主耗时阶段: `首个 finding 之前的分析阶段`
- 首轮 repo 主耗时阶段: `首个 finding 之前的分析阶段`
- 首轮 instant 主耗时阶段: `同步 instant analysis`
- repeat file 总时长: `164.297` 秒
- repeat repo 总时长: `193.96` 秒
- repeat instant 总时长: `36.0` 秒
- repeat file 主耗时阶段: `首个 finding 之前的分析阶段`
- repeat repo 主耗时阶段: `首个 finding 之前的分析阶段`
- repeat instant 主耗时阶段: `同步 instant analysis`

## 分轮关键指标

### 首轮 / file

- experiment_id: `F1-PT-PY-FILE-001`
- duration_seconds: `150`
- total_iterations: `15`
- tool_calls_count: `6`
- tokens_used: `102939`
- planning_time_seconds: `2.161`
- analysis_before_first_finding_seconds: `147.904`
- time_to_first_finding_seconds: `150.065`
- reporting_time_seconds: `0.0`
- avg_tokens_per_iteration: `6862.6`

### 首轮 / repo

- experiment_id: `R1-PT-PY-FILE-001`
- duration_seconds: `275`
- total_iterations: `18`
- tool_calls_count: `13`
- tokens_used: `148915`
- planning_time_seconds: `1.683`
- analysis_before_first_finding_seconds: `273.742`
- time_to_first_finding_seconds: `275.424`
- reporting_time_seconds: `0.0`
- avg_tokens_per_iteration: `8273.056`

### 首轮 / instant

- experiment_id: `I1-PT-PY-FILE-001`
- duration_seconds: `24.0`
- total_iterations: `null`
- tool_calls_count: `null`
- tokens_used: `null`
- planning_time_seconds: `null`
- analysis_before_first_finding_seconds: `null`
- time_to_first_finding_seconds: `null`
- reporting_time_seconds: `null`
- avg_tokens_per_iteration: `null`

### repeat / file

- experiment_id: `F1-REPEAT-PT-PY-FILE-001`
- duration_seconds: `164`
- total_iterations: `13`
- tool_calls_count: `9`
- tokens_used: `87479`
- planning_time_seconds: `1.989`
- analysis_before_first_finding_seconds: `162.0`
- time_to_first_finding_seconds: `163.989`
- reporting_time_seconds: `0.297`
- avg_tokens_per_iteration: `6729.154`

### repeat / repo

- experiment_id: `R1-REPEAT-PT-PY-FILE-001`
- duration_seconds: `193`
- total_iterations: `19`
- tool_calls_count: `10`
- tokens_used: `132416`
- planning_time_seconds: `1.422`
- analysis_before_first_finding_seconds: `191.96`
- time_to_first_finding_seconds: `193.382`
- reporting_time_seconds: `0.0`
- avg_tokens_per_iteration: `6969.263`

### repeat / instant

- experiment_id: `I1-REPEAT-PT-PY-FILE-001`
- duration_seconds: `36.0`
- total_iterations: `null`
- tool_calls_count: `null`
- tokens_used: `null`
- planning_time_seconds: `null`
- analysis_before_first_finding_seconds: `null`
- time_to_first_finding_seconds: `null`
- reporting_time_seconds: `null`
- avg_tokens_per_iteration: `null`

## 稳定性判断

- repo 更慢次数: `2` / `2`
- file 更慢次数: `0` / `2`
- 在当前最小重复集上，`repo 更慢` 是稳定复现现象。

## 初步解释

- 至少有一轮显示 repo 形态即使不增加迭代数，也会在单轮分析上花更久、消耗更多 token。
- 多数成本仍集中在首个 finding 之前的分析阶段，而不是上传、排队或报告收尾。
- instant analysis 在两轮里都远快于 agent file / repo，这强烈支持慢主要来自 agent 编排层，而不是基础语义识别本身。
