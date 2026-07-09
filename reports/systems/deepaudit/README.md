# DeepAudit 结果入口

## 1. 作用

这个目录是 `DeepAudit` 作为 `system under evaluation` 的统一人读入口。

它的职责不是替代 `artifacts/`，而是把当前已经存在的：

- 运行说明
- 阶段总结
- 局部 registry
- 对照报告

重新映射到一个稳定的目录骨架中，避免后续继续把新文档直接放在仓库根目录。

## 2. 当前模块地图

按本仓库术语，当前 DeepAudit 相关内容可以分成四层。

### 2.1 约束与语义层

- [CONTEXT.md](/home/lqs/llm_audit_system_learning/CONTEXT.md:1)
- [llm_audit_system_learning_method.md](/home/lqs/llm_audit_system_learning/llm_audit_system_learning_method.md:1)
- [agent_eval_learning_rules.md](/home/lqs/llm_audit_system_learning/agent_eval_learning_rules.md:1)

这些文件定义：

- `Learning Run`
- `Smoke Experiment`
- `Boundary-Condition Diagnostic Expansion`
- `Diagnostic Evaluation`
- `target vulnerability`
- `off-target finding`
- `near_miss`
- `Clean Input`

### 2.2 运行 caller 层

- [scripts/deepaudit_prepare_and_preflight.sh](/home/lqs/llm_audit_system_learning/scripts/deepaudit_prepare_and_preflight.sh:1)
- [scripts/run_deepaudit_smoke_cases.sh](/home/lqs/llm_audit_system_learning/scripts/run_deepaudit_smoke_cases.sh:1)
- [scripts/run_deepaudit_diagnosis_cases.sh](/home/lqs/llm_audit_system_learning/scripts/run_deepaudit_diagnosis_cases.sh:1)
- [scripts/run_deepaudit_boundary_instant_slots.sh](/home/lqs/llm_audit_system_learning/scripts/run_deepaudit_boundary_instant_slots.sh:1)
- [scripts/run_deepaudit_boundary_agent_slots.sh](/home/lqs/llm_audit_system_learning/scripts/run_deepaudit_boundary_agent_slots.sh:1)
- [scripts/run_deepaudit_repo_experiment.sh](/home/lqs/llm_audit_system_learning/scripts/run_deepaudit_repo_experiment.sh:1)
- [scripts/run_deepaudit_file_repo_timing.sh](/home/lqs/llm_audit_system_learning/scripts/run_deepaudit_file_repo_timing.sh:1)

这些 caller 负责把 `Case` 转成 `Clean Input`，并把单次运行沉淀为 `artifacts/` 证据。

### 2.3 原始证据层

- `artifacts/deepaudit_smoke/`
- `artifacts/deepaudit_diagnosis/`
- `artifacts/deepaudit_boundary_expansion/`
- `artifacts/deepaudit_minimal_expansion/`
- `artifacts/deepaudit_repo_experiments/`
- `artifacts/deepaudit_timing/`

这些目录属于证据层，不建议直接作为首次阅读入口。

### 2.4 当前人读结论层

- [deepaudit_wsl_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/runbooks/deepaudit_wsl_runbook.md:1)
- [deepaudit_boundary_condition_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/runbooks/deepaudit_boundary_condition_runbook.md:1)
- [deepaudit_minimal_expansion_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/runbooks/deepaudit_minimal_expansion_runbook.md:1)
- [learning_run_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/summaries/learning_run_summary.md:1)
- [artifacts/deepaudit_boundary_expansion/registry/README.md](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/registry/README.md:1)

## 3. 规范化目录映射

当前采用“先建入口，再逐步迁移”的策略。现阶段的规范化映射如下。

### 3.1 runbooks

对应文件：

- [deepaudit_wsl_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/runbooks/deepaudit_wsl_runbook.md:1)
- [deepaudit_boundary_condition_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/runbooks/deepaudit_boundary_condition_runbook.md:1)
- [deepaudit_minimal_expansion_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/runbooks/deepaudit_minimal_expansion_runbook.md:1)

语义：

- 部署 / 预检规范
- `Boundary-Condition Diagnostic Expansion` 规范
- 最小扩样规范

### 3.2 summaries

当前主要入口：

- [learning_run_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/summaries/learning_run_summary.md:1)
- [boundary_expansion_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/summaries/boundary_expansion_summary.md:1)
- [minimal_expansion_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/summaries/minimal_expansion_summary.md:1)

语义：

- DeepAudit `Learning Run` 总结
- `A/B/C/D` 可用边界总结
- 最小扩样后的修正结论

### 3.3 registries

当前主要入口：

- [artifacts/deepaudit_boundary_expansion/registry/README.md](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/registry/README.md:1)
- [canonical_boundary_slots.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/registry/canonical_boundary_slots.tsv:1)
- [legacy_experiment_registry.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/registry/legacy_experiment_registry.tsv:1)

语义：

- 旧实验到 `A/B/C/D` 槽位的映射
- canonical 槽位覆盖情况

### 3.4 comparisons

当前主要入口：

- [timing_profile.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/comparisons/timing_profile.md:1)

语义：

- 同案 `file / repo / instant` 编排行为与耗时对照

## 4. 推荐阅读顺序

如果要快速理解 DeepAudit 当前学习结论，建议顺序如下：

1. [learning_run_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/summaries/learning_run_summary.md:1)
2. [canonical_boundary_slots.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/registry/canonical_boundary_slots.tsv:1)
3. [boundary_expansion_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/summaries/boundary_expansion_summary.md:1)
4. [minimal_expansion_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/summaries/minimal_expansion_summary.md:1)
5. [timing_profile.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/comparisons/timing_profile.md:1)

## 5. 后续落盘规则

从现在开始，DeepAudit 新增的人读文档应遵循下面规则：

1. 新的阶段总结优先放入 `reports/systems/deepaudit/summaries/`。
2. 新的 registry / 索引优先放入 `reports/systems/deepaudit/registries/`。
3. 新的对照报告优先放入 `reports/systems/deepaudit/comparisons/`。
4. 新的运行说明优先放入 `reports/systems/deepaudit/runbooks/`。
5. 原始 run 产物仍继续写入 `artifacts/`。

## 6. 当前状态

当前目录的角色是：

- 先作为 `DeepAudit` 的统一入口
- 不立即移动历史根目录文档
- 为后续多个系统共用同一组织方式提供样板
