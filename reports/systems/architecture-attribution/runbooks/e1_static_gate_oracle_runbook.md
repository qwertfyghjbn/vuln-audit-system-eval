# E1 Static-gate Oracle Runbook

## 1. 作用

这个 runbook 用于执行 `Architecture Attribution Experiment` 的第一条主实验线：

- `E1 Static-gate Oracle`

它的目标不是直接比较 `IRIS`、`DeepAudit`、`OpenAnt` 的最终效果，而是先在 `IRIS-style static-gated workflow` 内部，逐层回答：

1. 失败是否主要来自 `candidate gate`
2. 失败是否主要来自 `summary / path modeling`
3. 失败是否主要来自 `build / slice boundary`
4. 在上述三层都补齐后，系统是否仍然不能恢复 target-aligned result

## 2. 不做什么

本 runbook 不负责：

- `E2 LLM Freedom Ladder`
- `E3 Tool Authority Ablation`
- `E4 DeepAudit Information Advantage Control`
- 对 `OpenAnt` 做第一轮主矩阵比较
- 直接修改 `IRIS` 主代码并将其记作官方行为线结果

## 3. 运行边界

### 3.1 主对象

`E1` 的主对象固定为：

- `IRIS-style static-gated workflow`

这里的“IRIS-style”指：

- 先由静态分析和候选 API 选择形成 Stage 3 输入边界
- 再由 LLM 输出 source / sink / taint-propagator 标签
- 再由 QLL 物化与主查询形成最终 path / result

### 3.2 DeepAudit 是否现在启动

当前阶段不启动 `DeepAudit`。

只有在以下条件同时满足时，才进入 DeepAudit 参照：

1. 同一个 family 的 `A/B/C/D` 已完整跑完
2. `D oracle slice` 仍然没有恢复 target-aligned result
3. 已确认输入切片、summary/path 与 candidate 注入都没有恢复

也就是说：

- `DeepAudit` 不是 `E1` 的起点
- `DeepAudit` 是 `E1` 失败分支的补充参照

## 4. 第一轮 family 与顺序

第一轮固定 3 个 `Case Family`：

1. `SSRF-JA-REPO-001`
2. `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED`
3. `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`

执行顺序固定为：

1. `SSRF-JA-REPO-001`
2. `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED`
3. `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`

原因：

- `SSRF-JA-REPO-001` 是最干净的 `candidate-selection dominant` 正例，最适合先验证 `E1` harness
- `SSRF-3432` 是 `query_semantics_mismatch` 主例，且有 vulnerable/fixed pair
- `cron-utils` 是 summary/bridge 语义主例，适合作为第三步

## 5. A/B/C/D 的解释规则

### 5.1 阶梯规则

`A -> B -> C -> D` 必须按累积阶梯执行，不得把 4 个版本当作互相独立的输入包。

也就是说：

- `B` 基于 `A`
- `C` 基于 `B`
- `D` 基于 `C`

否则在 `C` 或 `D` 成功时，无法判断恢复来自哪一层。

### 5.2 版本定义

| 版本 | 允许改动 | 不允许改动 |
|---|---|---|
| `A original` | 不改 workflow | 不改 candidate、summary、slice、prompt、posthoc |
| `B oracle candidate` | 补 target-adjacent source/sink/wrapper candidate 暴露 | 不改 QLL 语义、不改主查询骨架、不加额外 slice |
| `C oracle summary/path` | 在 `B` 基础上补最小 source/sink/summary/path 物化语义 | 不扩大 repo slice、不换 prompt、不换 posthoc |
| `D oracle slice` | 在 `C` 基础上补 caller-side 文件、真实入口、必要依赖 | 不引入与目标无关的新提示信息 |

### 5.3 判定规则

- `B` 成功：
  `candidate gate` 是主因
- `B` 不成功、`C` 成功：
  `summary/path modeling` 是主因
- `C` 不成功、`D` 成功：
  `build/slice boundary` 是主因
- `D` 仍不成功：
  当前 family 暂不支持“静态 gate 是唯一主因”，需要后续引入 `DeepAudit` 或 `E2`

## 6. 证据目录规范

`E1` 新证据统一写入：

```text
artifacts/architecture_attribution/E1/<run_id>/
  run_manifest.json
  family_matrix.tsv
  <family_id>/
    README.md
    A_original/
    B_oracle_candidate/
    C_oracle_summary_path/
    D_oracle_slice/
```

每个版本目录至少包含：

```text
<variant>/
  input_contract.json
  injection_manifest.json
  command.sh
  stdout.log
  stderr.log
  run_summary.json
  generated_queries/
  raw_responses/
  results/
```

说明：

- `generated_queries/` 保存 `MySources.qll`、`MySinks.qll`、`MySummaries.qll`
- `raw_responses/` 保存 LLM 标签原始响应与解析结果
- `results/` 保存 `results.csv`、`posthoc_results.json` 等最终产物

## 7. 统一记录字段

`family_matrix.tsv` 每行一个 family，至少记录：

- `family_id`
- `query_id`
- `variant_reached`
- `candidate_injected`
- `summary_injected`
- `slice_expanded`
- `llm_sources`
- `llm_sinks`
- `llm_taint_propagators`
- `num_vulnerable_paths`
- `target_alignment`
- `vulnerable_path_explained`
- `fixed_guard_explained`
- `primary_break_layer`
- `notes`
- `evidence_links`

每个 `run_summary.json` 额外记录：

- `cost_tokens`
- `wall_time_seconds`
- `tool_call_count`
- `context_volume`
- `parse_error_count`

## 8. 现有自动化可复用范围

### 8.1 可直接复用的部分

以下已有脚本可直接复用作输入准备或 baseline 参考：

- [scripts/iris_prepare_and_preflight.sh](/home/lqs/llm_audit_system_learning/scripts/iris_prepare_and_preflight.sh:1)
- [scripts/run_iris_smoke_cases.sh](/home/lqs/llm_audit_system_learning/scripts/run_iris_smoke_cases.sh:1)

它们已经覆盖：

- `SSRF-JA-REPO-001`
- `SSRF-JA-REPO-CVE-2023-3432-VULN`
- `SSRF-JA-REPO-CVE-2023-3432-FIXED`

### 8.2 暂不能直接复用的部分

`cron-utils` 不在固定 5-case smoke 脚本里。

因此：

- `SSRF-JA-REPO-001` 与 `SSRF-3432` 可以复用既有 clean input / compile recipe 约束
- `cron-utils` 需要沿用既有 official case trustworthiness / rerun 证据路径，先手工执行

当前 runbook 的默认策略是：

- 先手工执行 `E1`
- 等 `SSRF-JA-REPO-001` pilot 跑通后，再考虑补自动化脚本

## 9. 每个 family 的具体操作

### 9.1 `SSRF-JA-REPO-001`

当前已知证据：

- 在 7-family 正式结论中，这是唯一 `candidate-selection dominant` family
- 既有 forced candidate injection 说明缺失 sink API 是关键现象
- 最小 oracle 已证明 target-aligned result 可恢复

参考证据：

- [first3 forced candidate injection](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_first3_forced_candidate_injection.tsv:1)
- [first3 minimal oracle](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_first3_minimal_target_adjacent_oracle.tsv:1)

#### `A original`

目标：

- 复现 baseline 的 `source=0, sink=0, results=0`

建议 baseline 来源优先级：

1. 直接复用已有 `official_behavior` 证据
2. 若需要重跑，使用原始 `IRIS-style workflow`

#### `B oracle candidate`

只补 target-adjacent candidate 暴露，不补 summary/path。

最小注入包应优先覆盖：

- `RestTemplate()`
- `RestTemplate.getForObject`
- `HttpUtil.getUrl(String)` 对应的 source-side target-adjacent 暴露

预期：

- 如果 `B` 已直接恢复 target-aligned result，则该 family 的主断点可判为 `candidate_selection`
- 如果 `B` 只改善 `sink` 形状但仍无结果，继续进入 `C`

#### `C oracle summary/path`

在 `B` 基础上，只补最小 path 物化语义。

重点检查：

- sink 参数名是否按 `p0` 这类位置参数正确物化
- source / sink QLL 是否不再退化为 `1 = 0`

如果 `C` 才恢复 target-aligned result，则不应再把这个 family 归入“纯 candidate gate 主因”，而应判为更下游的 `summary/path modeling`

#### `D oracle slice`

通常对该 family 不是高优先级主战场。

只有在 `C` 仍然不能恢复时，才补完整 caller-side 文件、入口和依赖。

### 9.2 `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED`

当前已知证据：

- 关键 sink 与 summary 已在
- `VULN` 的唯一 source 落在错误语义片段 `System.getenv`
- `FIXED` 的 source 直接为空
- 两条线当前共同主断点是 `query_semantics_mismatch`

参考证据：

- [iris_contrast_exp2_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_exp2_results.md:1)
- [next2 diagnosis matrix](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_next2_diagnosis_matrix.tsv:1)

#### `A original`

分别固定 `VULN` 与 `FIXED` baseline，记录：

- `VULN`: source 错位到 `System.getenv`
- `FIXED`: source 缺失
- 两者 `paths=0`

#### `B oracle candidate`

只补 source-side target-adjacent candidate 暴露，不补 summary/path。

注入重点：

- 围绕 `LoadJson.path -> SURL.create(path) -> url.getBytes()` 的 request-origin 片段
- target-adjacent wrapper / caller candidate 暴露

不在 `B` 里直接改 summary 或物化规则。

预期：

- `B` 可能只改善 source 形状，不太可能单独恢复最终结果

#### `C oracle summary/path`

这是该 family 的主战场。

重点只补：

- request-origin source 到网络请求 sink 的最小 source/sink/path 物化语义
- 与 `SURL.create`、`SURL.getBytes`、`URL.openConnection` 闭环所需的最小 bridge

成功判定不只看 `results>0`，还要同时检查：

- `VULN` 能解释 vulnerable path
- `FIXED` 能解释为什么修复后 path 不成立

#### `D oracle slice`

如果 `C` 仍不能恢复，则补：

- 完整 caller-side 文件
- 真实入口文件
- compile recipe 未覆盖但与真实 request-origin 相关的必要依赖

`D` 的目的不是加“更多背景信息”，而是验证当前 compile/slice 边界是否裁掉了决定性入口语义。

### 9.3 `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`

当前已知证据：

- `source=0` 在多轮重跑中稳定存在
- candidate gap 不是主断点
- 更像 `Throwable.getMessage` 这一异常消息 bridge 没有进入 summary

参考证据：

- [iris_llm_variance_rerun_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_llm_variance_rerun_results.md:1)
- [last2 diagnosis matrix](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_last2_diagnosis_matrix.tsv:1)

#### `A original`

固定 baseline，记录：

- `source=0` 是否继续稳定
- sink / propagator 波动是否改变最终 `results=0`

#### `B oracle candidate`

这一步只做最小必要 candidate 注入验证，不应扩大范围。

如果 `B` 对 source/sink 形状没有决定性影响，应尽快结束该分支，不把时间耗在继续加 candidate 上。

#### `C oracle summary/path`

这是该 family 的核心步骤。

最小注入包应围绕：

- `IllegalArgumentException`
- `Throwable.getMessage()`
- `buildConstraintViolationWithTemplate`

目标是验证异常对象到异常消息字符串的 bridge 一旦进入 summary/path，是否能恢复 target-aligned result。

#### `D oracle slice`

只有当 `C` 失败且怀疑 build/slice 缺失异常路径相关文件时，才进入 `D`。

当前先验上，`D` 不是该 family 的优先动作。

## 10. Pilot 执行清单

首个 pilot 固定为：

- `family = SSRF-JA-REPO-001`

执行清单：

1. 建立 `artifacts/architecture_attribution/E1/<run_id>/`
2. 写 `run_manifest.json`
3. 复制或引用 baseline 输入契约
4. 执行 `A original`
5. 执行 `B oracle candidate`
6. 若 `B` 未恢复结果，执行 `C oracle summary/path`
7. 若 `C` 未恢复结果，执行 `D oracle slice`
8. 写 `family_matrix.tsv`
9. 写该 family 的 `README.md`

pilot 成功标准：

1. 四个版本的输入边界与产物都能独立复盘
2. `primary_break_layer` 可写成一句明确判断
3. 证据目录命名与字段结构可直接复用于后两个 family

如果 pilot 没达到这 3 条，不应继续扩到 `SSRF-3432` 或 `cron-utils`

## 11. 版本命名建议

建议使用：

- `AAE1_SSRF001_A_ORIG`
- `AAE1_SSRF001_B_CAND`
- `AAE1_SSRF001_C_PATH`
- `AAE1_SSRF001_D_SLICE`

其它 family 类推：

- `AAE1_SSRF3432V_A_ORIG`
- `AAE1_SSRF3432F_C_PATH`
- `AAE1_CRONUTILS_C_PATH`

要求：

- `run_id` 与 family-level `variant_id` 分开记录
- 不复用 `IRIS` 历史 run id

## 12. 结束条件

对单个 family，满足以下任一条件即可停止继续扩样：

1. `B` 已恢复 target-aligned result，且证据足够支持 `candidate_selection` 主断点
2. `C` 已恢复 target-aligned result，且证据足够支持 `summary/path modeling` 主断点
3. `D` 已恢复 target-aligned result，且证据足够支持 `build/slice boundary` 主断点
4. `D` 仍失败，且证据足够支持“需要进入 DeepAudit 或 E2”

对整个 `E1` 第一轮，满足以下条件即可结束：

1. 3 个 family 都写出了 `primary_break_layer`
2. 至少 1 个 family 证明 `candidate gate` 可以单独决定成败
3. 至少 1 个 family 证明更下游 `summary/path` 是主断点
4. 至少 1 个 family 为后续 `DeepAudit` 或 `E2` 提供了明确分流入口
