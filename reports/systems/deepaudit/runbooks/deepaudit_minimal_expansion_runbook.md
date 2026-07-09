# DeepAudit 最小扩样 Runbook

本 runbook 用于在 [deepaudit_boundary_condition_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/runbooks/deepaudit_boundary_condition_runbook.md:1) 已完成 v1 收口后，做一轮`最小规模、强约束、问题驱动`的补充实验。

这轮不是新的大样本 benchmark，也不是继续铺更多 `A/B/C/D` 槽位，而是只回答一个问题：

- 当前 `ABCD` 边界结论会不会只是小样本偶然

因此，本轮只补：

- 1 组 synthetic 非 `PT` repo 对照
- 1 组第二 real-world repo CVE 对照
- 1 个关键 repeat

总计 5 个实验。

## 1. 本轮目标

本轮只试图补强三类证据：

1. `漏洞类型泛化`
   - 当前主表主要由 `PT` 驱动
   - 需要确认 `C/D` 的结论是否能迁移到第二种漏洞类型
2. `real-world 泛化`
   - 当前唯一明确 `usable` 的 repo 级主记录是 `C-real-world-PT-PY-REPO-CVE-2024-32982-VULN`
   - 需要确认这不是单一项目特例
3. `关键结论稳定性`
   - 需要确认当前最重要的 repo 级 `usable` 结论不是一次性波动

本轮不试图回答：

- 统计意义上的总体优劣
- 全漏洞家族泛化
- 大规模稳定性分布
- near-miss / negative control

## 2. 固定约束

沿用 boundary v1 的固定约束：

- DeepAudit 官方部署版本
- `.env_deepseek` 中固定的 `LLM_PROVIDER` / `LLM_MODEL` / `LLM_BASE_URL`
- `verification_level=analysis_only`
- Windows 主机上的 DeepAudit 服务
- WSL 侧 ZIP 上传工作流
- 不向系统暴露 `ground_truth.json`、标准答案 README、带标签 `case.yaml`

额外约束：

- 本轮只记录 `C` / `D` 形态，不再补 `A` / `B`
- 所有基于 benchmark 已知锚点的 `target_files` 注入，都必须标记为 `diagnostic only`
- 本轮产物单独落盘，不与 boundary v1 主表混写

建议产物目录：

- `artifacts/deepaudit_minimal_expansion/<run-id>/...`

## 3. 样本选择结论

### 3.1 synthetic 非 `PT` repo case

本轮选择：

- [SSRF-PY-REPO-001](/home/lqs/llm_audit_system_learning/datasets/synthetic/SSRF-PY-REPO-001/README.md:1)

不选其他 synthetic 非 `PT` repo 的原因：

- 不选 `SSTI-PY-REPO-001` 作为第一选择，是因为 `SSRF-PY-REPO-001` 与现有 `PT-PY-REPO-001` 在 repo 形态上更对称，都是 Python、3 层 route→service→utils、跨文件传播、文件规模也一致，更适合回答“只换漏洞类型时，`C/D` 的边界是否保持”。
- 不选 Java synthetic repo 作为第一选择，是为了避免把语言变化和漏洞类型变化混在一起。

### 3.2 第二个 real-world repo CVE

本轮主选择：

- [SSTI-PY-REPO-CVE-2024-45053-VULN](/home/lqs/llm_audit_system_learning/datasets/real_world/SSTI-PY-REPO-CVE-2024-45053-VULN/README.md:1)

选择理由：

- 它保持了 `Python + real-world + 完整 repo` 这一主轴，只把“漏洞类型 / 项目”从当前的 `PT/Litestar` 换成 `SSTI/Fides`。
- 它比 `SSRF-PY-REPO-CVE-2025-2828-VULN` 更适合作为最小扩样主选择：
  - `Fides` 快照约 `3414` 个文件
  - `LangChain` 快照约 `6811` 个文件
  - 在仍然保持 Python real-world 完整 repo 的前提下，`Fides` 成本更可控
- 它比 Java curated subset 更适合作为主选择，因为它不引入语言切换这个额外变量。

不选为主选择但可作为 fallback 的 case：

- [SSRF-JA-REPO-CVE-2023-3432-VULN](/home/lqs/llm_audit_system_learning/datasets/real_world/SSRF-JA-REPO-CVE-2023-3432-VULN/README.md:1)

fallback 使用条件：

- 如果 `SSTI-PY-REPO-CVE-2024-45053-VULN` 的 `D` 形态在当前预算下出现纯粹的系统性不可操作，例如持续超时且没有任何 target signal，可改用该 Java curated subset 补一组低成本对照。
- 但 fallback 只能作为“运行性备选”，不能替代本轮主选择的解释价值。

## 4. 五个实验

### 实验 1

- `experiment_id`: `C-synthetic-SSRF-PY-REPO-001`
- `shape`: `C`
- `layer`: `synthetic`
- `case_id`: `SSRF-PY-REPO-001`
- `run_class`: `diagnostic only`
- `constraint_summary`: 完整 synthetic repo；显式 `target_files` 收窄；Python；非 `PT`

推荐 `target_files`：

- `src/routes/proxy_routes.py`
- `src/services/proxy_service.py`
- `src/utils/http_utils.py`

目的：

- 在尽量不改变 repo 结构的前提下，把漏洞类型从 `PT` 换成 `SSRF`
- 检查 `C` 形态的优势是否能迁移到第二种 Python repo 漏洞类型

### 实验 2

- `experiment_id`: `D-synthetic-SSRF-PY-REPO-001`
- `shape`: `D`
- `layer`: `synthetic`
- `case_id`: `SSRF-PY-REPO-001`
- `run_class`: `baseline-like`
- `constraint_summary`: 完整 synthetic repo；无 `target_files`；Python；非 `PT`

目的：

- 与实验 1 配对
- 检查 `D` 形态的高噪声 / 慢收敛问题，是不是 repo 工作流层面的共性，而不是只在 `PT` 上成立

### 实验 3

- `experiment_id`: `C-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN`
- `shape`: `C`
- `layer`: `real-world`
- `case_id`: `SSTI-PY-REPO-CVE-2024-45053-VULN`
- `run_class`: `diagnostic only`
- `constraint_summary`: 完整 real-world repo；显式 `target_files` 收窄；Python；第二项目第二漏洞家族

推荐 `target_files`：

- `src/fides/api/service/messaging/message_dispatch_service.py`
- `src/fides/api/models/messaging_template.py`

目的：

- 检查 `C-real-world` 的 `usable` 结论是不是只在 `PT-PY-REPO-CVE-2024-32982-VULN` 上成立
- 维持 Python real-world 完整 repo 条件，减少解释上的额外变量

### 实验 4

- `experiment_id`: `D-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN`
- `shape`: `D`
- `layer`: `real-world`
- `case_id`: `SSTI-PY-REPO-CVE-2024-45053-VULN`
- `run_class`: `baseline-like`
- `constraint_summary`: 完整 real-world repo；无 `target_files`；Python；第二项目第二漏洞家族

目的：

- 与实验 3 配对
- 检查不显式收窄时，`D-real-world` 是否仍主要落在 `partially_usable`

### 实验 5

- `experiment_id`: `C-real-world-PT-PY-REPO-CVE-2024-32982-VULN-repeat1`
- `shape`: `C`
- `layer`: `real-world`
- `case_id`: `PT-PY-REPO-CVE-2024-32982-VULN`
- `run_class`: `diagnostic only`
- `constraint_summary`: 对当前唯一明确 repo 级 `usable` 主记录做同口径 repeat

沿用 `target_files`：

- `litestar/static_files/base.py`
- `litestar/file_system.py`

目的：

- 检查当前最关键结论是否具有最基本的稳定性
- 量化 repeat 后在 `target_signal`、排序、tokens、耗时上的波动范围

## 5. 执行顺序

本轮不建议按 1→5 机械顺序跑，而应按成本和信息增益排序：

1. `C-synthetic-SSRF-PY-REPO-001`
2. `D-synthetic-SSRF-PY-REPO-001`
3. `C-real-world-PT-PY-REPO-CVE-2024-32982-VULN-repeat1`
4. `C-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN`
5. `D-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN`

原因：

- 先用最便宜的 synthetic 配对检查“非 `PT` 时 `C/D` 是否仍分化”
- 然后先做现有关键主记录 repeat，优先补稳定性证据
- 最后再进入第二条 real-world 项目线

## 6. 运行门槛与降级规则

### 6.1 `C` 先于 `D`

对每个新 case，必须先跑 `C`，再决定是否跑 `D`。

原因：

- `C` 是当前最接近“受控可用”的 repo 形态
- 如果 `C` 完全没有 target signal，那么直接跑同 case 的 `D` 往往只会更贵、更吵

### 6.2 `D-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN` 的降级规则

如果实验 4 出现以下情况之一：

- 超时且无任何目标信号
- tokens / wall clock 明显高于当前 `D-real-world-PT-PY-REPO-CVE-2024-32982-VULN`
- 结果只有泛化 Jinja 告警而没有命中 `_render()`

则：

- 记录为 `not_usable` 或 `partially_usable`
- 不在本轮继续追加更大的 Python real-world case
- 如需保留第二条 real-world 对照，可改跑 `SSRF-JA-REPO-CVE-2023-3432-VULN` 作为低成本 fallback

## 7. 统一记录字段

沿用 boundary v1 的字段集：

- `experiment_id`
- `shape`
- `layer`
- `case_id`
- `run_class`
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

## 8. 输出物

建议输出：

- `artifacts/deepaudit_minimal_expansion/<run-id>/expansion_matrix.tsv`
- `artifacts/deepaudit_minimal_expansion/<run-id>/expansion_memo.md`
- `artifacts/deepaudit_minimal_expansion/<run-id>/<experiment_id>/...`

解释口径：

- `expansion_matrix.tsv` 只记录本轮新增 5 个实验
- 不覆盖 boundary v1 主表
- 最终结论必须与 [artifacts/deepaudit_boundary_expansion/20260702T013845Z/boundary_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/20260702T013845Z/boundary_matrix.tsv:1) 联合阅读

当前已落地产物：

- [expansion_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_minimal_expansion/20260702T061515Z/expansion_matrix.tsv:1)
- [expansion_memo.md](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_minimal_expansion/20260702T061515Z/expansion_memo.md:1)

当前主表版本说明：

- 该版 `expansion_matrix.tsv` 已收录本轮 5 个最小扩样实验
- 该版 `expansion_memo.md` 已完成本轮结论收口
- 该版输出用于补强 boundary v1，而不是替代 boundary v1 主表

## 9. 本轮想回答的最小问题集

完成这 5 个实验后，应能更稳地回答：

1. `C` 的优势是不是只在 `PT` 上成立
2. `D` 的高噪声 / 高成本是不是只在 `PT` 上成立
3. `C-real-world usable` 是否只在 `Litestar / CVE-2024-32982` 上成立
4. 当前最关键的 `C-real-world-PT-PY-REPO-CVE-2024-32982-VULN` 结论是否至少具备一次 repeat 稳定性

基于当前已生成的 [expansion_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_minimal_expansion/20260702T061515Z/expansion_matrix.tsv:1) 与 [expansion_memo.md](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_minimal_expansion/20260702T061515Z/expansion_memo.md:1)，本轮最小问题集已经得到如下回答：

1. `C` 的优势不是只在 `PT` 上成立
   - `C-synthetic-SSRF-PY-REPO-001` 与 `C-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN` 都提供了正向证据
2. `D` 的高成本 / 更发散编排不是只在 `PT` 上成立
   - `D-synthetic-SSRF-PY-REPO-001` 已出现更分散的结构层展开
   - `D-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN` 则复现了完整大仓库下的高成本收敛
3. `C-real-world usable` 不再只建立在 `Litestar / CVE-2024-32982` 一条线上
   - `C-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN` 已达到 `usable`
4. `C-real-world-PT-PY-REPO-CVE-2024-32982-VULN` 的 repeat 支持 target signal 稳定
   - 但不支持“排序与 framing 完全稳定”

## 10. 退出条件

当以下条件满足时，本轮最小扩样可以收口：

1. 上述 5 个实验全部有有效记录，或者已按第 6 节规则做出明确降级记录
2. 至少获得 1 条新的非 `PT` synthetic `C/D` 配对结论
3. 至少获得 1 条新的第二 real-world 项目线结论
4. 已获得 `C-real-world-PT-PY-REPO-CVE-2024-32982-VULN` 的 repeat 结果
5. 已能把结论升级为：
   - “基于 8 条 canonical primary records 的 v1 边界判断”
   - 加上“1 组非 `PT` synthetic 配对、1 组第二 real-world 项目线、1 个关键 repeat”的小范围扩样判断

当前达成状态：

1. 上述 5 个实验全部有有效记录，或者已按第 6 节规则做出明确降级记录
   结果：已满足
2. 至少获得 1 条新的非 `PT` synthetic `C/D` 配对结论
   结果：已满足
3. 至少获得 1 条新的第二 real-world 项目线结论
   结果：已满足
4. 已获得 `C-real-world-PT-PY-REPO-CVE-2024-32982-VULN` 的 repeat 结果
   结果：已满足
5. 已能把结论升级为：
   - “基于 8 条 canonical primary records 的 v1 边界判断”
   - 加上“1 组非 `PT` synthetic 配对、1 组第二 real-world 项目线、1 个关键 repeat”的小范围扩样判断
   结果：已满足，见 [expansion_memo.md](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_minimal_expansion/20260702T061515Z/expansion_memo.md:1)

据此，本轮最小扩样已经达到 runbook 定义的收口条件。

## 11. 当前脚本状态

当前脚本状态：

- [scripts/run_deepaudit_boundary_instant_slots.sh](/home/lqs/llm_audit_system_learning/scripts/run_deepaudit_boundary_instant_slots.sh:1)
  - 只覆盖 `A` 形态 instant analysis
- [scripts/run_deepaudit_boundary_agent_slots.sh](/home/lqs/llm_audit_system_learning/scripts/run_deepaudit_boundary_agent_slots.sh:1)
  - 目前只内置 `D-synthetic-PT-PY-REPO-001`
- [scripts/run_deepaudit_repo_experiment.sh](/home/lqs/llm_audit_system_learning/scripts/run_deepaudit_repo_experiment.sh:1)
  - 已提供参数化 repo-runner
  - 已支持本轮最小扩样的 5 个 spec 文件直接执行

本轮实际使用的 spec 文件位于：

- [scripts/spec_templates/deepaudit_minimal_expansion/C-synthetic-SSRF-PY-REPO-001.json](/home/lqs/llm_audit_system_learning/scripts/spec_templates/deepaudit_minimal_expansion/C-synthetic-SSRF-PY-REPO-001.json:1)
- [scripts/spec_templates/deepaudit_minimal_expansion/D-synthetic-SSRF-PY-REPO-001.json](/home/lqs/llm_audit_system_learning/scripts/spec_templates/deepaudit_minimal_expansion/D-synthetic-SSRF-PY-REPO-001.json:1)
- [scripts/spec_templates/deepaudit_minimal_expansion/C-real-world-PT-PY-REPO-CVE-2024-32982-VULN-repeat1.json](/home/lqs/llm_audit_system_learning/scripts/spec_templates/deepaudit_minimal_expansion/C-real-world-PT-PY-REPO-CVE-2024-32982-VULN-repeat1.json:1)
- [scripts/spec_templates/deepaudit_minimal_expansion/C-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN.json](/home/lqs/llm_audit_system_learning/scripts/spec_templates/deepaudit_minimal_expansion/C-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN.json:1)
- [scripts/spec_templates/deepaudit_minimal_expansion/D-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN.json](/home/lqs/llm_audit_system_learning/scripts/spec_templates/deepaudit_minimal_expansion/D-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN.json:1)

因此，本 runbook 在执行层已经从“规划状态”进入“已完成并收口状态”，不再需要继续讨论 runner 选型。

当前更重要的是：

- 基于 [expansion_memo.md](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_minimal_expansion/20260702T061515Z/expansion_memo.md:1) 做最终结论表述
- 决定是否把这轮最小扩样回填到 boundary v1 的更高层总结中

如果后续继续实验，应进入新的目标轮次，而不是继续扩写这份最小扩样 runbook。
