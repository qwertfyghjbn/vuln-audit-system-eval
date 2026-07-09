# DeepAudit 边界条件诊断扩展 Runbook

本 runbook 用于在当前 `smoke experiment` 已基本完成的前提下，开展一轮`窄范围、带约束条件的诊断性扩展`。

按 [CONTEXT.md](/home/lqs/llm_audit_system_learning/CONTEXT.md:1) 的术语，这一轮不是 `Diagnostic Evaluation`，而是：

- `Boundary-Condition Diagnostic Expansion`

其目标不是扩大 case 数量，也不是形成可比较分数，而是：

- 量化 DeepAudit 在不同输入形态下的`可用边界`
- 区分“能做”与“可用”
- 记录结果质量边界，并把成本作为次级维度

## 1. 适用范围

本 runbook 只适用于：

1. DeepAudit 官方版本、固定模型配置下的学习阶段扩展
2. 少量代表性 case 的受控对照实验
3. 以形态边界为主轴的量化记录

本 runbook 不适用于：

- 冻结配置后的大样本 `Diagnostic Evaluation`
- 全量 benchmark 扩展
- 为了追求更高命中率而临时修改 DeepAudit 部署或提示词

## 2. 固定约束

除非某个实验条目明确说明变更，下列条件必须保持固定：

- DeepAudit 官方部署版本
- `.env_deepseek` 中的 `LLM_PROVIDER` / `LLM_MODEL` / `LLM_BASE_URL`
- `verification_level=analysis_only`
- Windows 主机上的 DeepAudit 服务
- WSL 侧 ZIP 上传工作流
- 不向系统暴露 `ground_truth.json`、带标签 `case.yaml`、README 标准答案

任何基于 benchmark 已知锚点注入收窄信息的运行，例如设置 `target_files`，都必须标记为：

- `diagnostic only`

## 3. 本轮主目标

本轮扩展的主目标是：

- 先量化`输入形态边界`
- 再在同一小集合上观察结果质量边界

不是先量化 case 类型边界，也不是先做大规模稳定性统计。

因此，后续所有结果都应围绕下面四种输入形态展开：

- `A. instant analysis / 单文件或关键片段`
- `B. 小 repo / 裁剪 repo，不给 target_files`
- `C. 完整 repo + target_files`
- `D. 完整 repo，不给 target_files，只选少量代表性 case`

## 4. 主轴与对照

本轮不把四种形态平均展开，而采用：

主轴：

- `A`
- `C`

校准对照：

- `B`
- `D`

原因：

- `A` 代表最低上下文、最高语义直达能力
- `C` 代表真实 repo 工作流中最有实用价值的受控形态
- `B` 用于分离“repo 结构感”和“显式收窄提示”
- `D` 用于保留现实世界基线压力，但不应成为主要扩展面

## 5. 优先量化的边界

本轮优先量化：

- `结果质量边界`

成本边界作为次级维度记录。

判断顺序固定为：

1. 是否存在 `target signal`
2. `off-target noise` 是否可接受
3. 排序是否稳定服务于使用
4. 达成上述结果的成本是否过高

这意味着：

- “多花 tokens 最终也能跑出来”不等于“可用”
- 只有结果质量先成立，成本数据才有解释价值

## 6. 分层方式

本轮结果必须分层记录，不得把 synthetic 和 real-world 混成一个主表。

分为两层：

- `Layer 1: synthetic boundary cases`
- `Layer 2: real-world transfer cases`

解释口径：

- synthetic 主要回答“机制边界”
- real-world 主要回答“迁移边界”

## 7. 最小代表 case 集

第一版固定以下最小代表集：

1. `PT-PY-FILE-001`
2. `SSRF-PY-FILE-001`
3. `PT-PY-REPO-001`
4. `PT-PY-REPO-CVE-2024-32982-VULN`

使用规则：

- 默认优先在这 4 个 case 上复用形态
- 如某种形态天然不适配某个 case，可以跳过，但必须记录“形态不适配”
- near-miss 如要补充，只能作为扩展，不进入第一版主表

## 8. 三档可用性阈值

本轮统一使用三档可用性判定，而不是二元成功/失败。

### `usable`

满足以下条件：

- 命中 `target vulnerability`
- 前 3 条 findings 中至少有 1 条为目标信号
- `off-target noise` 不压过主结论

### `partially_usable`

满足以下条件：

- 命中 `target vulnerability`
- 但存在以下至少一种问题：
  - 噪声较重
  - 排序不稳
  - 成本过高
  - 需要人工二次筛选才能消费

### `not_usable`

满足以下任一条件：

- 未命中 `target vulnerability`
- 只产出泛化告警或 `off-target findings`
- 成本高到不具实际操作性

## 9. 统一记录字段

每次运行都必须记录以下字段：

- `experiment_id`
- `shape`：A / B / C / D
- `layer`：synthetic / real-world
- `case_id`
- `run_class`：`baseline-like` / `diagnostic only`
- `constraint_summary`
- `status`
- `total_iterations`
- `tool_calls_count`
- `tokens_used`
- `wall_clock_seconds`
- `findings_count`
- `top_3_findings`
- `target_signal`
- `noise_shape`
- `ranking_quality`
- `usability_tier`
- `notes`

## 10. 统一输出结构

本轮输出以两层结构为主：

1. `统一量化结果表`
2. `简短结论 memo`

原始 artifacts 只作为证据层，不作为主要阅读入口。

建议输出文件：

- `artifacts/deepaudit_boundary_expansion/<run-id>/boundary_matrix.tsv`
- `artifacts/deepaudit_boundary_expansion/<run-id>/boundary_memo.md`
- `artifacts/deepaudit_boundary_expansion/<run-id>/<experiment_id>/...`

其中：

- `boundary_matrix.tsv` 是主表
- `boundary_memo.md` 用于总结“DeepAudit 的真正可用边界”

当前已落地产物：

- [boundary_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/20260702T013845Z/boundary_matrix.tsv)
- [boundary_memo.md](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/20260702T013845Z/boundary_memo.md)

当前主表版本说明：

- 该版 `boundary_matrix.tsv` 已补齐第 9 节定义的完整字段集
- 该版 `boundary_memo.md` 已对现有 `A/B/C/D` 主记录完成统一判级总结
- 当前 v1 主表覆盖 8 条 canonical primary records，分别对应 synthetic / real-world 两层下的 `A/B/C/D` 代表记录

## 11. 第一版执行顺序

建议按下面顺序推进，而不是四种形态同时铺开：

### Phase 1：主轴确认

1. `A` 形态跑 `PT-PY-FILE-001`
2. `A` 形态跑 `SSRF-PY-FILE-001`
3. `C` 形态跑 `PT-PY-REPO-001`
4. `C` 形态跑 `PT-PY-REPO-CVE-2024-32982-VULN`

目的：

- 先确认主轴形态的 synthetic / real-world 可用边界

### Phase 2：对照校准

5. `B` 形态跑 `PT-PY-FILE-001` 或对应小 repo 变体
6. `B` 形态跑 `PT-PY-REPO-CVE-2024-32982-VULN`
7. `D` 形态跑 `PT-PY-REPO-001`
8. `D` 形态跑 `PT-PY-REPO-CVE-2024-32982-VULN`

目的：

- 校准“repo 结构感”和“显式收窄提示”的差异
- 保留少量无约束真实基线

## 12. 每次运行后的最小结论格式

每个实验结束后，至少写下以下五行判断：

- `target_signal`: `clear` / `partial` / `absent`
- `noise_shape`: `low` / `moderate` / `high`
- `ranking_quality`: `good` / `mixed` / `poor`
- `cost`: `low` / `moderate` / `high`
- `usability_tier`: `usable` / `partially_usable` / `not_usable`

这样能保证后续汇总时不需要重新人工解释全部原始 finding。

## 13. 当前已知边界

基于当前已完成的学习性实验，可先把已知经验作为执行前假设：

- `A` 通常最能体现基础语义能力
- `B` 往往优于完整大 repo，但通常弱于显式 `target_files` 收窄
- `C` 是当前最接近“受控可用”的 repo 形态
- `D` 最接近现实压力，但最容易出现慢收敛、噪声和排序问题

这些只是执行前假设，不是最终结论；后续必须继续用统一量化表验证。

基于当前已生成的 [boundary_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/20260702T013845Z/boundary_matrix.tsv:1) 与 [boundary_memo.md](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/20260702T013845Z/boundary_memo.md:1)，v1 结论已经收敛为：

- `A`：当前最明确的 `usable` 边界，适合观察基础漏洞语义能力
- `B`：能体现 repo 结构感带来的帮助，但结果干净度与成本仍不稳定，当前归为 `partially_usable`
- `C`：当前最接近“受控可用”的 repo 形态，其中 `C-real-world-PT-PY-REPO-CVE-2024-32982-VULN` 已达到 `usable`
- `D`：能够命中目标，但更常以高成本、慢收敛和 broad-scan noise 的形式出现，当前归为 `partially_usable`

当前统一判级分布为：

- `usable`: 3
- `partially_usable`: 5
- `not_usable`: 0

## 14. 退出条件

当以下条件都满足时，本轮 `Boundary-Condition Diagnostic Expansion` 可以收口：

1. `A/B/C/D` 四种形态至少各有 1 个有效记录
2. synthetic 与 real-world 两层都至少各有 1 个有效记录
3. 四种形态都已得到 `usability_tier`
4. 已能明确写出：
   - 哪些形态 `usable`
   - 哪些形态仅 `partially_usable`
   - 哪些形态 `not_usable`
5. 已形成一份统一量化结果表与简短结论 memo

达到这些条件后，不再继续盲目加 case，而应转入：

- 收口总结
- 或者冻结条件后，再决定是否升级为真正的 `Diagnostic Evaluation`

当前达成状态：

1. `A/B/C/D` 四种形态至少各有 1 个有效记录
   结果：已满足
2. synthetic 与 real-world 两层都至少各有 1 个有效记录
   结果：已满足
3. 四种形态都已得到 `usability_tier`
   结果：已满足
4. 已能明确写出：
   - 哪些形态 `usable`
   - 哪些形态仅 `partially_usable`
   - 哪些形态 `not_usable`
   结果：已满足，见 [boundary_memo.md](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/20260702T013845Z/boundary_memo.md:1)
5. 已形成一份统一量化结果表与简短结论 memo
   结果：已满足，见 [boundary_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/20260702T013845Z/boundary_matrix.tsv:1) 与 [boundary_memo.md](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/20260702T013845Z/boundary_memo.md:1)

据此，当前 boundary v1 已达到 runbook 定义的收口条件。除非后续要单独开展稳定性重复、near-miss 扩展或正式 `Diagnostic Evaluation` 前的冻结验证，否则不再需要在本轮 runbook 下继续追加主表实验。
