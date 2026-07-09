# OpenAnt 结果入口

## 1. 作用

这个目录是 `OpenAnt` 相关实验在当前仓库中的统一人读入口。

当前它承担的是“外部证据导入入口”，不是原始 `artifacts/` 存储层。也就是说：

- 原始 `OpenAnt` 结果目前仍在外部工作区
- 本目录负责把这些结果映射成当前仓库可稳定引用的结构

## 2. 当前状态

当前 `OpenAnt` 相关学习已经至少形成三条可区分的实验线：

1. `round1 learning / evaluation`
2. `unit partition compare`
3. `unit partition controlled evaluation`

这些材料已经足够支撑本仓库的收尾阶段：

- 建立 `OpenAnt` 的本地入口
- 参与 `canonical results` 统一字段映射
- 进入四大实验综合总报告

## 3. 当前模块地图

- `runbooks/`
  - 外部证据导入规则、口径对齐规则、收尾写作约束
- `summaries/`
  - `OpenAnt` 学习结论与受控实验收口文档
- `registries/`
  - case matrix、parse 状态、受控实验 contract 的统一索引入口
- `comparisons/`
  - `OpenAnt` 与当前系统的行为比较、unit partition 对照、relation 注入对照

## 4. 当前证据根

当前主要证据已经复制到本仓库：

- [openant_learning_report.md](/home/lqs/llm_audit_system_learning/reports/systems/openant/summaries/openant_learning_report.md:1)
- [unit_partition_diff_report.md](/home/lqs/llm_audit_system_learning/reports/systems/openant/comparisons/unit_partition_diff_report.md:1)
- [e1_experiment_report.md](/home/lqs/llm_audit_system_learning/reports/systems/openant/comparisons/e1_experiment_report.md:1)
- [e2_experiment_report.md](/home/lqs/llm_audit_system_learning/reports/systems/openant/comparisons/e2_experiment_report.md:1)

## 5. 推荐阅读顺序

1. [summaries/openant_learning_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/openant/summaries/openant_learning_summary.md:1)
2. [comparisons/README.md](/home/lqs/llm_audit_system_learning/reports/systems/openant/comparisons/README.md:1)
3. [registries/README.md](/home/lqs/llm_audit_system_learning/reports/systems/openant/registries/README.md:1)

## 6. 当前落盘规则

1. 本目录优先保存人读入口和归一化文档，不复制大体积原始 artifacts。
2. `OpenAnt` 的关键结论、对照文档与最小 registry 已优先转成本仓库内链接。
3. 仍未迁入的大体积原始运行目录，默认不作为总报告的唯一证据入口。
