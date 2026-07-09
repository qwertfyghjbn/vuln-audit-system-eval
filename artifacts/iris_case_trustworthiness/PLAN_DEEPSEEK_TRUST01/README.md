# PLAN_DEEPSEEK_TRUST01

这是本轮 `DeepSeek + IRIS` 官方 case 与自有 case 可信度对照学习批次的执行与归档骨架。

它是规划目录，不代表对应 case 已运行完成。

## 结构

```text
PLAN_DEEPSEEK_TRUST01/
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

当前阶段先用 `README.md` 作为目录占位，后续运行时再落真实产物。
