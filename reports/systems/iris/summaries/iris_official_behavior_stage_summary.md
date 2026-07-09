# IRIS 官方行为线阶段总结

## 1. 文档定位

这份总结只服务于 `IRIS` 的官方行为线阶段收口。

它回答的问题是：

> 截至当前，官方 `IRIS` 及其最小运行兼容变体，在本仓库固定 5-case Java smoke 范围内，已经表现出了什么稳定行为和失败模式？

这不是正式评测结果，也不是能力改动实验总结。

## 2. 版本边界

当前阶段涉及两个相关对象：

1. `iris-upstream-observed`
   - 类型：`official_upstream_baseline`
   - 作用：观察官方上游机制的原始行为
   - 局限：当前尚未形成完全无补丁但稳定可执行的证据闭环

2. `iris-runtime-compat-001`
   - 类型：`runtime_compatibility_variant`
   - 作用：仅恢复当前 `Native Evaluation Environment` 下的可执行性
   - 包含内容：
     - `OPENAI_BASE_URL` / `OPENAI_MODEL` 接线
     - 环境变量 CRLF 清洗
     - 本机 CodeQL 路径对接
     - DeepSeek 空 `stop` 参数兼容修复
     - 自定义 benchmark 缺失上游 CVE 元数据时允许继续运行

本总结中的“可执行官方行为观察”主要以 `iris-runtime-compat-001` 为证据代理，因为它当前是唯一能稳定完成 5-case 主流程的最小变体。

## 3. 证据范围

当前阶段主要依据以下证据：

- preflight：
  - [artifacts/iris_preflight/PYREADY/preflight_checks.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_preflight/PYREADY/preflight_checks.tsv:1)
  - [artifacts/iris_preflight/PYREADY/run_manifest.json](/home/lqs/llm_audit_system_learning/artifacts/iris_preflight/PYREADY/run_manifest.json:1)
- 早期失败批次：
  - [artifacts/iris_smoke/TESTRUNREAL/summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_smoke/TESTRUNREAL/summary.tsv:1)
- 当前已完成的官方行为线 5-case smoke：
  - [artifacts/iris_smoke/OFFICIALSMOKE01/summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_smoke/OFFICIALSMOKE01/summary.tsv:1)
  - [reports/systems/iris/registries/canonical_results.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:1)

## 4. 当前已确认状态

### 4.1 preflight 已通过

`IRIS` 当前在本机已经满足学习期 smoke 的基础前置条件：

- 上游源码存在
- Python 环境存在
- CodeQL 可用
- Java / javac 可用
- 5 个固定 Java smoke case 的目录契约存在

这说明“部署骨架是否成立”这一问题已经收敛。

### 4.2 早期脚本级 smoke 曾停在运行链路失败

早期批次 [TESTRUNREAL/summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_smoke/TESTRUNREAL/summary.tsv:1) 显示：

- 5 个 case 全部为 `runtime_failure`
- 失败原因统一为 `planned command exited with code 127`

这批结果现在只保留为“早期链路未打通”的证据，不再代表当前官方行为线状态。

### 4.3 `OFFICIALSMOKE01` 已完成固定 5-case 主流程

当前批次 [OFFICIALSMOKE01/summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_smoke/OFFICIALSMOKE01/summary.tsv:1) 显示：

- `PT-JA-REPO-001`
- `SSRF-JA-REPO-001`
- `PT-JA-REPO-CVE-2024-53677-VULN`
- `SSRF-JA-REPO-CVE-2023-3432-VULN`
- `SSRF-JA-REPO-CVE-2023-3432-FIXED`

5 个 case 全部 `completed`，并都到达 `Stage 9`。

这说明当前最小运行兼容变体已经足以把官方 `IRIS` 的主机制稳定跑完一轮固定 smoke。

## 5. 当前已确认的官方行为特征

### 5.1 当前 5/5 case 都是“跑通但无有效漏洞信号”

规范化结果表 [canonical_results.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:1) 显示：

- 5 个 case 全部 `runner_status = completed`
- 5 个 case 全部 `system_verdict = no_signal`
- 5 个 case 全部 `num_vulnerable_paths = 0`
- 5 个 case 的最终 `results.csv` 都为空

因此，当前官方行为线的主结论已经从“跑不起来”变成了“能跑完，但 5/5 都没有产出最终漏洞信号”。

### 5.2 Stage 3 已经不是纯粹的模型接线问题

当前 5 个 case 中，Stage 3 的 LLM 标签产出并不统一为空：

- `PT-JA-REPO-001`：`2` 个标签，其中 `Sink = 1`
- `PT-JA-REPO-CVE-2024-53677-VULN`：`4` 个标签，全部是 `Taint Propagator`
- `SSRF-JA-REPO-CVE-2023-3432-VULN`：`22` 个标签，其中 `Sink = 6`
- `SSRF-JA-REPO-CVE-2023-3432-FIXED`：`22` 个标签，其中 `Sink = 6`

这说明在修复 DeepSeek 空 `stop` 兼容问题之后，当前主失败模式已经不是“模型返回无法解析”，而是“有标签，但仍然没有形成最终漏洞路径”。

### 5.3 当前最明显的缺口仍然是 `source` 稀缺

`OFFICIALSMOKE01` 中的 5 个 case 里：

- `llm_sources = 0` 出现在全部 5 个 case
- `llm_sinks > 0` 只出现在 `PT-JA-REPO-001` 和两条 `SSRF-3432` case
- `PT-JA-REPO-CVE-2024-53677-VULN` 只产出 `taint-propagator`

这使得“缺少可用 source 语义”仍然是当前最稳定、最值得进入下一条实验线的问题。

### 5.4 Stage 4 缺失 fixing commit 元数据是稳定伴随现象

5 个 case 的日志里都出现：

- `No fixing commits found for project; aborting`

但在当前运行兼容变体下，这个现象并不会阻止整个流程继续走到 `Stage 9`。它更像是一个稳定伴随条件，而不是当前批次的直接终止原因。

### 5.5 同一 `run_id` 下存在按 CWE 共享缓存

`SSRF-JA-REPO-CVE-2023-3432-FIXED` 的日志显示：

- `#Candidates: 72`
- `#To Query APIs: 1`
- `#Cached: 71`

这说明当前批处理脚本下，同一 `run_id`、同一 `CWE` 的 case 会共享 Stage 3 API 标签缓存。

这是当前官方行为的一部分，后续比较不同 case 时需要显式记在备注里。

## 6. 当前最稳定的失败模式判断

截至当前，可以稳定写入官方行为线总结的失败模式有 3 类。

### 6.1 早期运行链路失败

表现：

- `runtime_failure`

证据：

- [artifacts/iris_smoke/TESTRUNREAL/summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_smoke/TESTRUNREAL/summary.tsv:1)

含义：

- 这是早期链路问题，不再代表当前可执行状态。

### 6.2 运行兼容修复后，固定 5-case 全部为 `no_signal`

表现：

- `completed`
- `stage9_completed`
- `results.csv` 为空
- `num_vulnerable_paths = 0`

证据：

- [artifacts/iris_smoke/OFFICIALSMOKE01/summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_smoke/OFFICIALSMOKE01/summary.tsv:1)
- [reports/systems/iris/registries/canonical_results.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:1)

含义：

- 当前最小运行兼容变体已经恢复了执行链路，但还没有恢复出 benchmark 需要的有效漏洞信号。

### 6.3 `source` 缺失是当前最一致的机制性症状

表现：

- 全部 5 个 case 的 `llm_sources = 0`

含义：

- 这比“某一个 case 只产出 taint-propagator”更稳定，已经可以作为后续能力改动线的首个诊断入口。

## 7. 当前不能过度宣称的事项

以下结论当前还不能写成“官方 IRIS 的稳定画像”：

1. 不能说 `IRIS` 整体不适合本 benchmark
   - 当前只完成了固定 5-case smoke，不是正式规模化评测

2. 不能把 `iris-runtime-compat-001` 的结果直接写成“无补丁官方上游表现”
   - 当前仍然依赖运行兼容变体

3. 不能把“source 稀缺”直接解释成唯一根因
   - 它是当前最稳定症状，但不等于已经完成根因证明

## 8. 当前阶段结论

截至当前，官方行为线可以给出以下阶段结论：

1. `IRIS` 的部署与 preflight 骨架已经成立。
2. 早期 5-case 脚本级 smoke 曾因运行链路问题全部失败，但这个问题已经被当前运行兼容线跨过。
3. 在 `iris-runtime-compat-001` 下，固定 5 个 Java smoke case 已全部完成一轮可审计运行。
4. 当前这 5 个 case 的稳定结果是：`5/5 completed`，但 `5/5 no_signal`。
5. 当前最稳定的机制性症状是：Stage 3 并非完全无输出，但 `source` 在 5 个 case 中全部缺失。

## 9. 建议的下一步

官方行为线的“要不要先跑 5-case smoke”这个问题现在已经结束，下一步应当是：

1. 以 `OFFICIALSMOKE01` 为当前官方行为线收口基线
2. 继续保持官方行为线冻结，不再混入能力改动
3. 单开 `capability-changing variant`，优先验证 `candidate-selection` / `source` 稀缺问题
