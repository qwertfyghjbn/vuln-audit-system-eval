# IRIS 变体登记表

## 1. 作用

这个表用于把 `IRIS` 的运行结果绑定到明确的变体线，避免把：

- 官方上游行为
- 运行兼容补丁
- 能力改动实验

混成同一份结论。

## 2. 变体类型

- `official_upstream_baseline`
  - 上游默认机制，不主动改动能力边界
- `runtime_compatibility_variant`
  - 只做本机运行、模型接线、OpenAI-compatible provider 兼容修正
- `capability_changing_variant`
  - 改动候选生成、source/sink 建模、prompt、解析、ranking、后处理等能力边界

## 3. 登记字段

每个变体至少记录：

| variant_id | parent | type | status | scope | modifications | expected_effect | first_run_id | notes |
|---|---|---|---|---|---|---|---|---|

## 4. 当前已登记变体

| variant_id | parent | type | status | scope | modifications | expected_effect | first_run_id | notes |
|---|---|---|---|---|---|---|---|---|
| `iris-upstream-observed` | `v2@upstream` | `official_upstream_baseline` | `observed_only` | 官方机制观察 | 不额外引入能力改动；仅用于对照官方 IRIS 在学习样本上的自然行为 | 形成官方行为基线 | `FIRSTREAL` | 当前尚未形成完全无补丁的稳定可运行证据 |
| `iris-runtime-compat-001` | `iris-upstream-observed` | `runtime_compatibility_variant` | `active` | 运行接线修复 | 支持 `OPENAI_BASE_URL` / `OPENAI_MODEL`；环境变量 CRLF 清洗；配置读取本机 CodeQL 路径；避免向 DeepSeek 发送空 `stop`；自定义 benchmark 模式下缺失上游 CVE 元数据时允许继续运行 | 让 IRIS 在当前 `Native Evaluation Environment` 和实验侧模型配置下稳定执行 | `FIRSTREAL_STOPFIX` | 目标是恢复预期执行链路，不把候选生成或 prompt 逻辑改造成 benchmark 特化 |
| `iris-capability-branch-placeholder` | `iris-runtime-compat-001` | `capability_changing_variant` | `reserved` | 后续能力实验 | 预留给 internal/external 候选过滤、source/sink 建模、prompt 或 post-processing 改动 | 单独评估机制改动是否更适配 benchmark 输入边界 | `pending` | 未登记具体改动前，不应在该行下记录运行结果 |
| `iris-capability-candsel-001` | `iris-runtime-compat-001` | `capability_changing_variant` | `active` | candidate-selection 单变量实验 | 在 `collect_invoked_external_apis()` 中保留原 external candidate 逻辑，同时白名单放宽少量 internal wrapper API 进入 Stage 3；当前包含 `ActionContext` / `MultiPartRequestWrapper` / `SURL` 相关入口 | 验证 `llm_sources = 0` 是否主要来自 internal/external 候选边界，而不是 prompt / ranking 问题 | `CANDSEL001` | `PT-53677` 的候选数从 `19` 增到 `25` 但仍未产出 source；`SSRF-3432` 的候选数从 `71/72` 增到 `77/78`，并首次把 `source` 从 `0` 提升到 `1` |

## 5. 使用规则

1. 新增任何修改前，先决定它属于哪一类变体。
2. 若修改会影响能力边界，不得挂在 `runtime_compatibility_variant` 下。
3. 每次新增能力改动，都应新增一行或更新 `modifications`，并绑定新的 `run_id`。
4. 汇总结论时，必须按 `variant_id` 分开写，不能只写 `IRIS`。
