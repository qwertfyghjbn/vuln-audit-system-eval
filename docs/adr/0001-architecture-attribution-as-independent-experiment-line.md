# 0001. Architecture Attribution 作为独立实验线

## 状态

Accepted

## 背景

当前仓库已经存在 `IRIS` 与 `DeepAudit` 两条系统级评估线，并通过 `reports/systems/<system-id>/` 组织人读文档，通过 `artifacts/` 保存原始证据。

后续需要进行一轮 `Architecture Attribution Experiment`，目标是验证 workflow 架构变量，尤其是 `Static-tool Constraint Strength`，是否解释了 `IRIS`、`OpenAnt` 与 `DeepAudit` 的表现差异。

这类实验会引用既有 IRIS、DeepAudit、OpenAnt 结果，但它本身既不是 IRIS 的 capability-changing variant，也不是 DeepAudit 的新系统评估。

## 决策

将 `Architecture Attribution Experiment` 建为独立实验线：

- 人读入口：`reports/systems/architecture-attribution/`
- 原始证据：`artifacts/architecture_attribution/`
- 术语入口：`CONTEXT.md`

新运行结果不得写入：

- `reports/systems/iris/`
- `artifacts/iris_*`
- `reports/systems/deepaudit/`
- `artifacts/deepaudit_*`

## 后果

正面影响：

- 保持架构归因结果与具体系统评估结果分离。
- 避免把 IRIS-style workflow 的能力改动、DeepAudit 信息优势控制、OpenAnt 后续对照混成一个系统的分数。
- 让后续 reader 可以按同级实验线找到规划、证据和总结。

代价：

- 需要维护一个新的 `reports/systems/architecture-attribution/` 骨架。
- 后续 cross-system 总结需要显式链接这条实验线，而不能默认从 IRIS 或 DeepAudit 目录继承。

## 替代方案

### 放入 `reports/systems/iris/`

拒绝。第一轮主归因对象虽然是 `IRIS-style static-gated workflow`，但实验目标不是评估 IRIS 变体，而是隔离 workflow 架构变量。放入 IRIS 目录会让读者误以为结果属于 IRIS capability line。

### 放入 `reports/systems/deepaudit/`

拒绝。DeepAudit 只作为信息优势控制和外部参照，不是这条实验线的唯一对象。

### 放入 `reports/cross_system/`

拒绝。`cross_system` 更适合放最终横向比较入口；本实验需要自己的 runbooks、registries、summaries 和 artifacts，生命周期接近系统级实验线。
