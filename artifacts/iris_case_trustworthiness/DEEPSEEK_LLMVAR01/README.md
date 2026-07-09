# DEEPSEEK_LLMVAR01

这是 `IRIS` 官方 case `LLM` 差异怀疑线的最小重跑批次目录。

本轮只服务于两个目标 case：

1. `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`
2. `rhuss__jolokia_CVE-2018-1000129_1.4.0`

本轮目标不是复现官方 `GPT-4` 结果，而是验证：

- `cron-utils` 的 `source=0` 是否稳定
- `jolokia` 的 `sink=0` 是否稳定

## 结构

```text
DEEPSEEK_LLMVAR01/
├── run_manifest.json
├── run_manifest.template.json
├── rerun_matrix.tsv
├── summary.tsv
├── _shared/
└── official/
    ├── jmrozanec__cron-utils_CVE-2021-41269_9.1.5/
    └── rhuss__jolokia_CVE-2018-1000129_1.4.0/
```

## 归档规则

每个 `rerun_n/` 目录最终至少应补齐：

1. `iris_run/`
2. `generated_queries/`
3. `raw_prompts/`
4. `raw_responses/`
5. `local_observation/`
6. `notes/`

如需扩展到 `r4` / `r5`，继续沿用相同目录槽位，不覆盖 `r1-r3`。

补充约定：

- `generated_queries/` 保留 `IRIS` 原生的 `myqueries/...` 嵌套层级，不做平铺。
- `raw_prompts/posthoc/` 在未触发 `posthoc` 过滤时允许为空。
