# DEEPSEEK_TRUST01

这是本轮 `DeepSeek + IRIS` 官方 case 与自有 case 可信度对照学习批次的真实执行目录。

本轮冻结的真实 `run_id` 就是 `DEEPSEEK_TRUST01`。它由 `PLAN_DEEPSEEK_TRUST01/` 复制初始化而来，后续所有原始证据与判定补充产物都应落在此目录下。

为保证“规划骨架 -> 真实执行目录”的链路可追溯，这里同时保留：

1. `run_manifest.json`
2. `run_manifest.template.json`

## 结构

```text
DEEPSEEK_TRUST01/
├── run_manifest.json
├── run_manifest.template.json
├── case_inventory.tsv
├── _shared/
├── official/
└── self/
```

## 归档规则

每个 case 目录最终至少应出现：

1. `fetch_build/`
2. `codeql_db/`
3. `iris_run/`
4. `generated_queries/`
5. `raw_prompts/`
6. `raw_responses/`
7. `official_row/`
8. `local_observation/`
9. `notes/`

当前阶段应始终以 `DEEPSEEK_TRUST01/` 作为主入口；`PLAN_DEEPSEEK_TRUST01/` 仅保留为规划骨架来源。各 case 目录随着执行推进，按上面的固定槽位补齐产物。
