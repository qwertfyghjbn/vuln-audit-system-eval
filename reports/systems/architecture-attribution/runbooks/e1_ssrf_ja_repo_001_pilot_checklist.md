# E1 Pilot Checklist: SSRF-JA-REPO-001

## 1. 作用

这份清单把 `E1 Static-gate Oracle` 的首个 pilot 收紧到单一 family：

- `SSRF-JA-REPO-001`

目标是先验证 `E1` 的执行骨架是否成立，再决定是否扩到：

- `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED`
- `jmrozanec__cron-utils_CVE-2021-41269_9.1.5`

## 2. 当前已知结论

这个 family 的既有证据已经足够支持它作为 pilot：

- 它是当前 7-family 正式结论中唯一 `candidate-selection dominant` 的 family
- baseline 的关键 sink `RestTemplate.getForObject` 出现在 raw API extraction 中，但在 Stage 3 前被 internal package 规则筛掉
- 既有 `forced candidate injection` 已经把 `sink=0` 改善成 `sink=1`
- 既有 `minimal oracle replay` 已经恢复了 target-aligned result

关键参考：

- [candidate coverage audit](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_first3_candidate_coverage_audit.tsv:1)
- [forced candidate injection](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_first3_forced_candidate_injection.tsv:1)
- [minimal oracle replay](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_candidate_selection_first3_minimal_target_adjacent_oracle.tsv:1)

## 3. 运行前约束

### 3.1 不启动 DeepAudit

这个 pilot 只跑 `IRIS-style static-gated workflow` 的 `A/B/C/D`。

当前不启动 `DeepAudit`。只有在 `D oracle slice` 仍然不能恢复 target-aligned result 时，才考虑把 `DeepAudit` 当作下一条参照分支。

### 3.2 先手工执行，不假设已有一键脚本

当前仓库里没有现成的 `candidate injection / oracle replay` 一键 runner。

因此本 pilot 的执行形态是：

- 复用现有 `IRIS` 输入准备和 baseline 证据
- 手工构造 `B/C/D` 注入包
- 手工保存统一证据目录

pilot 跑通后，再决定是否补自动化脚本。

## 4. 目录与命名

本次 pilot 建议使用：

- `run_id = AAE1_PILOT_SSRF001_<UTC timestamp>`

证据目录：

```text
artifacts/architecture_attribution/E1/<run_id>/
  run_manifest.json
  family_matrix.tsv
  SSRF-JA-REPO-001/
    README.md
    A_original/
    B_oracle_candidate/
    C_oracle_summary_path/
    D_oracle_slice/
```

版本名建议：

- `AAE1_SSRF001_A_ORIG`
- `AAE1_SSRF001_B_CAND`
- `AAE1_SSRF001_C_PATH`
- `AAE1_SSRF001_D_SLICE`

## 5. 需要准备的基线材料

开始前先把这些文件定位并记录进 `run_manifest.json`：

1. baseline `official_behavior` 证据
   - `artifacts/iris_smoke/OFFICIALSMOKE01/SSRF-JA-REPO-001/...`
2. compile recipe
   - `datasets/synthetic/SSRF-JA-REPO-001/build_support/java_compile_recipe.json`
3. target-adjacent API coverage 证据
   - `iris_candidate_selection_first3_candidate_coverage_audit.tsv`
4. 既有注回和 oracle 证据
   - `CANDDOMF3_SSRF001_INJECT1`
   - `CANDDOMF3_SSRF001_ORACLE1`

本 pilot 的最小 target-adjacent 集合先固定为：

- source:
  - `HttpUtil.getUrl(String)#url`
- sink:
  - `RestTemplate.getForObject(p0)`
- candidate-side sink API:
  - `RestTemplate()`
  - `RestTemplate.getForObject`

## 6. A/B/C/D 执行清单

### 6.1 A original

目标：

- 复现 baseline 的 `source=0, sink=0, results=0`

执行步骤：

1. 为 `A_original/` 建目录。
2. 写 `input_contract.json`：
   - 记录 case id、query id、compile recipe、clean input root、模型配置来源。
3. 写 `injection_manifest.json`：
   - `candidate_injected=false`
   - `summary_injected=false`
   - `slice_expanded=false`
4. 复用既有 baseline 证据，或在必要时重跑原始 `IRIS-style workflow`。
5. 保存：
   - `candidate_apis.csv`
   - `llm_labelled_source_*.json`
   - `llm_labelled_sink_apis.json`
   - `MySources.qll`
   - `MySinks.qll`
   - `MySummaries.qll`
   - `results.csv`
   - `posthoc_results.json` / `posthoc_stats.json`
   - stdout / stderr
6. 写 `run_summary.json`。

通过检查：

- `source=0`
- `sink=0`
- `results=0`
- `target_alignment=false`

如果 `A` 没能稳定复现 baseline，停止 pilot，先修复输入或运行边界。

### 6.2 B oracle candidate

目标：

- 只补 target-adjacent candidate 暴露，观察下游形状是否改善

执行步骤：

1. 复制 `A_original` 的输入约束到 `B_oracle_candidate/`。
2. 写 `injection_manifest.json`：
   - `candidate_injected=true`
   - `summary_injected=false`
   - `slice_expanded=false`
   - `injected_apis=["RestTemplate()", "RestTemplate.getForObject"]`
3. 显式记录为什么注入：
   - raw API extraction 中存在 `RestTemplate.getForObject`
   - internal package filter 把它在 Stage 3 前筛掉
4. 运行注入后版本。
5. 保存和 `A` 同样的产物。
6. 对比 `A` 与 `B`：
   - Stage 3 candidate 是否新增 `RestTemplate.getForObject`
   - `llm_labelled_sink_apis.json` 是否从空变成非空
   - `MySinks.qll` 是否仍然退化为 `1 = 0`
   - `results.csv` 是否仍为空

通过检查：

- 候选集出现 `RestTemplate.getForObject`
- `sink` 从 `0` 改善到 `1`
- 但 `results` 仍然是 `0`

如果 `B` 已直接恢复 target-aligned result，则：

- 记录 `primary_break_layer = candidate_selection`
- pilot 可以结束，不再进入 `C/D`

如果 `B` 只改善形状但仍无结果，则进入 `C`。

### 6.3 C oracle summary/path

目标：

- 在 `B` 基础上补最小 path 物化语义，验证断点是否已经下沉到 QLL 物化层

执行步骤：

1. 复制 `B_oracle_candidate` 输入约束到 `C_oracle_summary_path/`。
2. 写 `injection_manifest.json`：
   - `candidate_injected=true`
   - `summary_injected=true`
   - `slice_expanded=false`
   - `oracle_sources=["HttpUtil.getUrl(String)#url"]`
   - `oracle_sinks=["RestTemplate.getForObject(p0)"]`
   - `oracle_summaries=[]`
3. 明确本步不扩大 slice，只修正最小 source/sink 物化语义。
4. 运行 `C`。
5. 保存：
   - `llm_labelled_source_func_params.json`
   - `llm_labelled_sink_apis.json`
   - `MySources.qll`
   - `MySinks.qll`
   - `results.csv`
6. 重点检查：
   - `MySources.qll` 是否变为非空
   - `MySinks.qll` 是否使用位置参数 `p0`
   - `results.csv` 是否恢复 target-aligned result

通过检查：

- `MySources_nonempty`
- `MySinks_nonempty`
- `results=1`
- `target_alignment=true`

如果 `C` 恢复结果，则：

- 记录 `primary_break_layer = summary/path modeling`
- 在 `family_matrix.tsv` 里注明：
  baseline 不是纯 candidate gate，真正决定恢复的是 source/sink QLL 物化语义

如果 `C` 仍无结果，进入 `D`。

### 6.4 D oracle slice

目标：

- 只在 `C` 失败时，验证 compile/slice 边界是否仍裁掉了决定性 caller-side 语义

对 `SSRF-JA-REPO-001` 来说，`D` 不是高优先级预期分支。

执行步骤：

1. 只有 `C` 失败时才创建 `D_oracle_slice/`。
2. 写 `injection_manifest.json`：
   - `candidate_injected=true`
   - `summary_injected=true`
   - `slice_expanded=true`
3. 记录额外加入的 caller-side 文件、入口与依赖。
4. 运行 `D`。
5. 保存与前面一致的产物。
6. 重点检查：
   - compile recipe 外新增文件是否真正进入 DB
   - source/sink/path 形状是否继续改善
   - 是否首次恢复 target-aligned result

如果 `D` 仍失败，则：

- 记录 `needs_followup = DeepAudit_or_E2`
- 不在这个 pilot 内继续扩样

## 7. 每一步都要填的文件

### 7.1 `run_summary.json`

至少包含：

- `variant_id`
- `query_id`
- `candidate_injected`
- `summary_injected`
- `slice_expanded`
- `llm_sources`
- `llm_sinks`
- `llm_taint_propagators`
- `num_vulnerable_paths`
- `target_alignment`
- `cost_tokens`
- `wall_time_seconds`
- `parse_error_count`
- `primary_observation`

### 7.2 `README.md`

`SSRF-JA-REPO-001/README.md` 至少写：

- baseline 失败现象
- `B` 的形状改善
- `C` 是否恢复结果
- 最终 `primary_break_layer`
- 是否需要进入 `D`

### 7.3 `family_matrix.tsv`

至少填这一行：

- `family_id=SSRF-JA-REPO-001`
- `variant_reached=A|B|C|D`
- `candidate_injected=true/false`
- `summary_injected=true/false`
- `slice_expanded=true/false`
- `primary_break_layer`
- `notes`

## 8. Pilot 成功标准

满足以下 3 条才算 pilot 跑通：

1. `A/B/C/D` 的输入边界与注入内容都能从证据目录独立复盘。
2. 至少能清楚地区分：
   - `B` 只是形状改善
   - `C` 恢复 target-aligned result
3. 可以写出一句不含模糊词的结论：
   - `SSRF-JA-REPO-001` 的 baseline miss 先表现为 candidate gate，但真正恢复 target-aligned result 仍依赖最小 source/sink 物化语义修正。

如果做完后结论仍然不清楚，不应直接扩到 `SSRF-3432`。

## 9. 完成后立即做的事

1. 更新 [family_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/README.md:1) 对应位置的字段设计。
   目标文件位置：`artifacts/architecture_attribution/E1/<run_id>/family_matrix.tsv`
2. 在 `SSRF-JA-REPO-001/README.md` 写 5-10 行 family memo。
3. 在 `E1` 总结里记录：
   - `pilot_passed = true/false`
   - `can_expand_to_ssrf3432 = true/false`
4. 如果 `C` 已恢复结果，则继续规划 `SSRF-3432`。
5. 如果 `D` 仍失败，则转入是否启动 `DeepAudit` 的判断，而不是继续对 `SSRF-001` 加更多 ad hoc 注入。
