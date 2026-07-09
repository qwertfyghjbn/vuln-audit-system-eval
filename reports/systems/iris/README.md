# IRIS 结果入口

## 1. 作用

这个目录是 `IRIS` 作为 `system under evaluation` 的统一人读入口。

当前阶段的目标不是形成正式评测结论，而是：

- 固化 `IRIS` 的部署约束
- 固化 `Preflight + Smoke Experiment` 的输入边界
- 为后续 `artifacts/iris_*` 证据目录提供稳定入口

## 2. 当前状态

当前 `IRIS` 仍处于 `Learning Run` 准备阶段。

已冻结的学习期决策包括：

- 运行形态：`Native Evaluation Environment`
- 配置来源：复用仓库唯一 `Experiment-side Configuration`
- 首轮漏洞范围：`PT + SSRF`
- Java 构库策略：优先使用 `Compile Recipe`
- 首轮 smoke case：固定为 5 个 Java repo case

## 3. 当前模块地图

- `runbooks/`
  - 部署说明、preflight 约束、smoke 输入边界
- `summaries/`
  - 后续 `Learning Run` 与 `Smoke Experiment` 收口文档
- `registries/`
  - 后续 `run_inventory.tsv`、证据索引等
- `comparisons/`
  - 后续不同输入形态、不同预算、不同查询策略对照

## 4. 版本边界

`IRIS` 在本仓库中的后续运行必须区分以下 3 类对象，不能混记。

1. `official upstream baseline`
   - 指上游 `IRIS` 的默认机制与默认候选生成逻辑。
   - 这一类结果只用于回答“官方 IRIS 在当前学习样本上的原始行为是什么”。

2. `runtime compatibility variant`
   - 指为了让 `IRIS` 在当前 `Native Evaluation Environment` 和实验侧模型接线下可运行而做的兼容补丁。
   - 例如：模型 base URL 接线、环境变量清洗、与特定 OpenAI-compatible provider 的请求参数兼容修正。
   - 这类改动会影响运行成败与部分输出，但目标不是主动提升漏洞检测能力。

3. `capability-changing variant`
   - 指会改变 `IRIS` 候选生成、漏洞语义建模、source/sink 识别、排序、解析或后处理能力边界的改动。
   - 例如：放宽 internal/external API 候选过滤、修改 prompt 语义、调整 ranking、修改 post-processing 逻辑。
   - 这类改动必须视为另一条实验分支，不能与 `official upstream baseline` 或 `runtime compatibility variant` 直接混作同一系统版本。

## 5. 记录规则

- 后续所有能力改动都应进入另一条分支或变体线，不再并入“官方 IRIS 学习记录”。
- 每一次修改都必须登记修改日期、修改位置、修改类型、动机和影响预期。
- 运行结果必须显式绑定到某个 `variant_id`，不能只写 `IRIS`。
- 若修改影响候选生成、prompt、解析、ranking、budget 或后处理，则必须视为新版本重新开始一轮记录。

推荐做法：

- 保留一条只用于学习官方行为的 `official` 线。
- 保留一条只用于最小接线修复的 `runtime-compat` 线。
- 把所有能力改动放入单独的 `patched-capability` 线，并逐项登记。

## 6. 主要入口

- [runbooks/iris_deployment_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/runbooks/iris_deployment_runbook.md:1)
- [registries/variant_registry.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/variant_registry.md:1)
