# 评估结果目录规范

## 1. 目的

`reports/` 是本仓库中所有**人读结果文档**的统一入口。

它服务于以下目标：

1. 把 `Learning Run`、`Smoke Experiment`、`Boundary-Condition Diagnostic Expansion`、`Diagnostic Evaluation` 的结论文档从仓库根目录中收口。
2. 把单个系统的结论入口与 `artifacts/` 下的原始证据层分离。
3. 为后续多个 `system under evaluation` 提供统一目录骨架，避免每增加一个系统就新增一批散落在根目录的 `*.md`。

## 2. 与 artifacts 的边界

目录职责必须严格区分：

- `artifacts/`
  - 保存原始运行证据。
  - 包括 `run_manifest.json`、`task_object.json`、`task_findings.json`、`metrics.json`、阶段性 `tsv/json/md` 结果。
  - 默认视为证据层，不作为主要阅读入口。
- `reports/`
  - 保存面向人读的索引、总结、规范、对比入口。
  - 默认不重复复制大体积原始证据，只链接或索引到 `artifacts/`。

简单说：

> `artifacts/` 负责“保留证据”，`reports/` 负责“组织结论”。

## 3. 顶层结构

后续统一使用下面的目录骨架：

```text
reports/
  README.md
  systems/
    <system-id>/
      README.md
      runbooks/
      summaries/
      registries/
      comparisons/
  cross_system/
    README.md
```

字段含义：

- `systems/<system-id>/`
  - 单个被评估系统的统一入口。
- `runbooks/`
  - 该系统的运行说明、实验约束、阶段定义。
- `summaries/`
  - 该系统的阶段结论、学习报告、收口摘要。
- `registries/`
  - 该系统的人读索引和规范化表。
- `comparisons/`
  - 该系统内部不同阶段、不同配置、不同输入形态之间的比较说明。
- `cross_system/`
  - 多个系统之间的横向对照入口。

## 4. 单系统目录规范

每个系统目录都应至少满足以下约束。

### 4.1 必备入口

必须有：

- `README.md`

它负责回答：

1. 这个系统当前处于哪个评估阶段。
2. 当前有哪些 `run stage`。
3. 哪些文件是主要阅读入口。
4. 原始证据位于哪些 `artifacts/` 目录。

### 4.2 子目录职责

#### `runbooks/`

存放：

- 部署 / 预检说明
- 阶段性运行规范
- 输入形态说明
- 固定约束说明

不存放：

- 单次 run 的原始输出
- 面向结论收口的综合报告

#### `summaries/`

存放：

- `Learning Run` 总结
- `Smoke Experiment` 总结
- `Diagnostic Evaluation` 总结
- 边界扩展或最小扩样的收口报告

命名建议：

- `learning_run_summary.md`
- `smoke_summary.md`
- `boundary_expansion_summary.md`
- `diagnostic_evaluation_summary.md`

#### `registries/`

存放：

- `run_inventory.tsv`
- `canonical_results.tsv`
- `evidence_index.json`
- `legacy_to_canonical_mapping.tsv`

原则：

- registry 是“主入口索引”，不是原始日志备份。
- 一个字段只应有一个主定义，不在多份表中随意漂移。

#### `comparisons/`

存放：

- 同系统内部的阶段对照
- 同系统内部的输入形态对照
- 同系统内部的预算 / 成本 / 编排行为对照

例如：

- `shape_comparison.md`
- `timing_profile.md`
- `budget_tradeoff.md`

## 5. 命名规范

### 5.1 system id

`systems/` 下目录统一使用：

- 小写
- ASCII
- 短横线或单词直连优先

例如：

- `deepaudit`
- `openant`
- `codegate`

### 5.2 文件命名

人读文件统一优先使用：

- 稳定语义名
- 不带日期
- 不把一次性 run id 放进文件名

例如：

- `README.md`
- `learning_run_summary.md`
- `canonical_results.tsv`

带时间戳的一次性产物应继续留在 `artifacts/`，而不是写进 `reports/`。

## 6. 根目录约束

自本规范起：

1. 新增的人读评估文档不再直接放在仓库根目录。
2. 新增的系统级总结、索引、收口文档统一放入 `reports/systems/<system-id>/...`。
3. 根目录现有历史文档先保留，视为 `legacy root docs`，后续按需要迁移。

这条规则的目的不是立即重排所有旧文件，而是阻止新的散乱继续增加。

## 7. DeepAudit 迁移策略

当前 DeepAudit 已经有：

- 根目录 runbook / report 文档
- `artifacts/deepaudit_*` 证据目录
- `artifacts/deepaudit_boundary_expansion/registry/` 阶段性 registry

因此 DeepAudit 的第一步不是移动所有旧文件，而是：

1. 在 `reports/systems/deepaudit/` 建立统一入口。
2. 把当前根目录文档按 `runbooks / summaries / registries / comparisons` 重新映射。
3. 后续新增 DeepAudit 文档优先写入 `reports/systems/deepaudit/`。

## 8. 未来新增系统的最低要求

每新增一个待评估系统，至少应创建：

```text
reports/systems/<system-id>/
  README.md
  runbooks/README.md
  summaries/README.md
  registries/README.md
  comparisons/README.md
```

这样可以保证：

- 任何系统都先有固定落点
- 任何阶段总结都不会直接散到根目录
- 任何跨系统比较都有统一入口可以引用

