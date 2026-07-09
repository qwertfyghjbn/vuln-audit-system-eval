# DEEPSEEK_SELF01

这是本轮 `DeepSeek + IRIS` 自有对照 case 学习批次的真实执行目录。

本轮冻结的真实 `run_id` 是 `DEEPSEEK_SELF01`。它只服务于 3 个自有对照 case，不混入官方 case 结果。

## 结构

```text
DEEPSEEK_SELF01/
├── run_manifest.json
├── run_manifest.template.json
├── case_inventory.tsv
├── summary.tsv
├── _shared/
└── self/
    ├── PT-JA-REPO-CVE-2024-53677-VULN/
    ├── SSRF-JA-REPO-CVE-2023-3432-VULN/
    └── SSRF-JA-REPO-CVE-2023-3432-FIXED/
```

## 归档规则

每个 case 目录最终至少应补齐：

1. `fetch_build/`
2. `codeql_db/`
3. `iris_run/`
4. `generated_queries/`
5. `raw_prompts/`
6. `raw_responses/`
7. `local_observation/`
8. `notes/`

补充约定：

- `generated_queries/` 保留 `IRIS` 原生的 `myqueries/...` 嵌套层级，不做平铺。
- 自有 case 没有 `official_row/` 槽位；对照信息统一写入批次级 summary 和 case 级 notes。
- `raw_prompts/posthoc/` 在未触发 `posthoc` 过滤时允许为空。
