# `SSRF-3432 pair` 的 `E2 differential freedom` 人读报告

## 1. 作用

这份报告用于集中记录 `Architecture Attribution Experiment` 中 `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED` 的 `E2 differential freedom ladder` 结果。

当前约定是：

- `M1` 先写入本报告
- 后续 `M3/M4/M5` 继续追加到同一份报告
- 不把这条 pair 的结果混写到 `cron-utils` 的 `E2` 报告里

## 2. 当前覆盖范围

### 2.1 目标模式

这条 pair 的 `E2` 第一轮固定为：

1. `M1_original`
2. `M3_differential_target_context_constrained`
3. `M4_differential_free_auditor`
4. `M5_differential_agentic_auditor`

本轮不做：

- `M2_candidate_source_window`

### 2.2 当前状态

截至目前：

- `M1` 已完成归档
- `M3` 已完成归档
- `M4` 已完成归档
- `M5` 当前不必执行

### 2.3 当前证据

- [E2 SSRF3432 runbook](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e2_ssrf3432_pair_differential_freedom_ladder_runbook.md:1)
- [E2 SSRF3432 checklist](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e2_ssrf3432_pair_execution_checklist.md:1)
- [E1 进展报告 `SSRF-3432 pair` 小节](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e1_static_gate_oracle_progress_report.md:183)
- [E4 独立人读报告](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e4_ssrf3432_deepaudit_information_control_report.md:172)
- [E2 run_manifest.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/run_manifest.json:1)
- [E2 family_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/family_matrix.tsv:1)

## 3. 共享判定规则

对这条 pair，只有同时满足以下 4 条，才记为恢复了 `pair-level differential understanding`：

1. 明确识别 `LoadJson.path` 或等价 `%load_json` 参数是目标外部输入。
2. 明确指出 `LoadJson -> SURL` 或等价 URL 访问链是 query 目标路径。
3. 明确解释 `VULN` 侧为何会落到 `userinfo/@ / allowlist / redirect` 差分语义。
4. 明确解释 `FIXED` 侧为何不再成立，而不是只给出 `0 path`。

以下情况都不记为成功：

- 只保留 generic `java.net` URL/URLConnection 面
- 只说 `VULN` 有 SSRF 风险
- 只说 `FIXED` 没出路径
- 只出现 `userinfo`、`openConnection` 这类局部词汇，但没有把它们组织成 pair-level 差分解释

## 4. 当前总表

| mode | status | output_format | target_alignment | differential_understanding | 当前说明 |
|---|---|---|---|---|---|
| `M1_original` | completed | structured_labels | false | false | `VULN/FIXED` 两侧都退化到 `MySources.qll = 1 = 0`；`VULN` 只保留 `URLConnection.getInputStream/getOutputStream` 与 `URL.getUserInfo/openConnection` 一类泛化网络面，`FIXED` 进一步扩到 `URL.openConnection` 与多条 `String` 归一化 propagator，但仍没有 `LoadJson.path`、没有 fixed guard、没有路径。 |
| `M3_differential_target_context_constrained` | completed | constrained_json | true | true | 加入 pair-level `target-context memo` 和固定 JSON schema 后，模型首次稳定恢复 `LoadJson.path -> SURL.getBytes()` 漏洞侧入口/网络链，并明确把 fixed 侧的 `@/userinfo` 拒绝逻辑解释为最小语义差分。 |
| `M4_differential_free_auditor` | completed | freeform_audit | true | true | 去掉显式 JSON schema 后，模型仍稳定写出 `LoadJson -> SURL -> @/userinfo guard` 的 pair-level differential audit；虽然回答自发包了一层单字段 JSON，但其核心内容已经是不受 schema 约束的自由审计文本。 |
| `M5_differential_agentic_auditor` | not_required | freeform_agentic | not_run | not_run | 按本轮停止规则，只有 `M4` 仍不能解释 fixed-side guard 时才进入 `M5`；当前不需要。 |

## 5. 方法边界

当前需要明确记录：

1. 本报告只接收写入 `artifacts/architecture_attribution/E2/` 的新证据。
2. `E1` 的 `DEEPSEEK_SELF01` 自跑证据仍然是前置背景，不直接算作本次 `E2 M1` 结果。
3. 本次 `M1` 是新跑的 IRIS 原始链路，且使用的是 IRIS 内部 `project_slug`，不是外部 case ID。
4. 因此，如果本次 `M1` 与 `E1 A_original` 的失败形状不同，应优先以本次 `E2` 归档包为准。

## 6. `M1_original`

### 6.1 Pair-level 总览

这次 `M1` 最关键的观察不是“VULN 和 FIXED 仍然 `0 path`”，而是：

- 两边的 `MySources.qll` 都直接退化成了 `1 = 0`

也就是说，这次 `M1` 比 `E1` 里复用的 `DEEPSEEK_SELF01` baseline 更接近 `IRIS` 原始 official 形状：

- `VULN` 不再像 `E1 A_original` 那样保留错误的 `System.getenv` source
- `FIXED` 继续保持 source-empty
- 两边都只剩 generic `java.net` 表面

这让本次 `M1` 对后续 `E2` 的意义更明确：

- `M1` 不是“保留一点错误 source 的弱失败”
- 而是“原始 structured-label workflow 直接把 pair 压回 empty-source/generic-network-surface”

对应证据：

- [VULN MySources.qll](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-VULN/M1_original/generated_queries/MySources.qll:1)
- [FIXED MySources.qll](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-FIXED/M1_original/generated_queries/MySources.qll:1)

### 6.2 `VULN`

当前状态：

- `completed`

当前结果：

1. 本次 `VULN M1` 使用 IRIS 内部 project slug：
   `bench__ssrf-ja-repo-cve-2023-3432_CVE-2023-3432_vuln`
2. 统计结果为：
   `num_external_api_calls = 199`
   `num_api_candidates = 77`
   `num_labelled_sources = 0`
   `num_labelled_sinks = 2`
   `num_labelled_taint_propagators = 7`
   `num_labelled_func_param_sources = 0`
   `num_results = 0`
   `num_paths = 0`
   `recall_method = false`
3. 生成的 source predicate 直接是：
   `1 = 0`
4. 保留下来的 sink 与 summary 都是 generic `java.net` 网络面：
   `URLConnection.getInputStream()`
   `URLConnection.getOutputStream()`
   `URL(String)`
   `URL.getUserInfo()`
   `URL.openConnection()`
   `URL.getHost()`
5. 这些标签虽然比普通 SSRF 噪声更接近真实域，但仍然没有恢复：
   `LoadJson.path`
   `LoadJson -> SURL`
   `userinfo/@ / allowlist / redirect` 差分语义

对应证据：

- [VULN run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-VULN/M1_original/run_summary.json:1)
- [VULN normalized_output.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-VULN/M1_original/normalized_output.json:1)
- [VULN final_results.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-VULN/M1_original/results/final_results.json:1)
- [VULN stdout.log](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-VULN/M1_original/logs/stdout.log:1)

当前结论：

1. `VULN M1` 没有恢复 target-aligned reasoning。
2. 这次失败比 `E1` 复用的 self baseline 更“硬”：
   不是错误 source 碎片，
   而是空 source predicate。
3. 因此，原始 structured-label workflow 对这条 pair 的压制，比“只差一个 source 短片段”更强。

### 6.3 `FIXED`

当前状态：

- `completed`

当前结果：

1. 本次 `FIXED M1` 使用 IRIS 内部 project slug：
   `bench__ssrf-ja-repo-cve-2023-3432_CVE-2023-3432_fixed`
2. 统计结果为：
   `num_external_api_calls = 201`
   `num_api_candidates = 78`
   `num_labelled_sources = 0`
   `num_labelled_sinks = 4`
   `num_labelled_taint_propagators = 12`
   `num_labelled_func_param_sources = 0`
   `num_results = 0`
   `num_paths = 0`
   `recall_method = false`
3. 生成的 source predicate 同样直接是：
   `1 = 0`
4. `FIXED` 比 `VULN` 保留了更宽的 generic 表面：
   除了 `URL.openConnection()` / `URLConnection.getInputStream()`，
   还加入了 `String.substring/toLowerCase/trim/replace/split/getBytes` 一类归一化 propagator。
5. 但这种扩张没有转化成 fixed-side 差分理解：
   仍然没有 `forbiddenURL()`
   没有 `isInUrlAllowList()`
   没有 `userinfo/@` 拒绝语义

对应证据：

- [FIXED run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-FIXED/M1_original/run_summary.json:1)
- [FIXED normalized_output.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-FIXED/M1_original/normalized_output.json:1)
- [FIXED final_results.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-FIXED/M1_original/results/final_results.json:1)
- [FIXED stdout.log](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-FIXED/M1_original/logs/stdout.log:1)

当前结论：

1. `FIXED M1` 同样没有恢复 differential semantics。
2. 这里的失败不能被解释成 `fix-aware no path`。
3. 当前更准确的描述是：
   原始 structured-label workflow 只保留了 generic network surfaces，却没有任何可用 source，也没有 fixed-side guard explanation。

### 6.4 当前对 `M1` 的合并判断

把 `VULN/FIXED` 合在一起看，这次 `M1` 支持三个判断：

1. `M1` 不只是重复 `E1 A_original`，而是把 pair 压回了更强的 empty-source 失败形状。
2. `VULN` 与 `FIXED` 都能保留一部分 `java.net` 相关 surface，但这类 surface 既不足以恢复 `LoadJson.path -> SURL`，也不足以解释 fixed-side guard。
3. 因此，对 `SSRF-3432 pair` 来说，后续最高价值的下一步仍然是 `M3 differential target-context constrained`，而不是回头补 `M2`。

## 7. `M3_differential_target_context_constrained`

### 7.1 当前状态

- `completed`

### 7.2 当前结果

1. `M3` 不再分别跑 `VULN/FIXED` 两个 IRIS structured-label 流程，而是改成一个 pair-level 受控单轮调用：
   把 `M1` 基线摘要、目标 API 候选、目标 source function-parameter 候选、fixed-side guard 候选，以及 `LoadJson/SURL` 相关源码窗口一起打包到同一次 prompt。
2. 这次输出被限制为固定 JSON schema，要求模型同时回答：
   漏洞侧 source、
   漏洞侧 sink、
   fixed 侧 guard、
   最小语义差分、
   以及“为什么 fixed 不是单纯没出 path”。
3. 模型一次成功解析后明确给出：
   `LoadJson.loadStringData(String path, String charset)` 是漏洞侧入口，
   `SURL.getBytes()` 是触发网络请求的 sink，
   `SURL.forbiddenURL` 与 `SURL.isInUrlAllowList` 中新增的 `full.contains("@")` 检查是 fixed 侧 guard。
4. `vulnerable_path_hypothesis.is_plausible = true`，并把核心链条组织为：
   `LoadJson.loadStringData(path)`
   -> `SURL.create(path)`
   -> `SURL.getBytes()`
   -> `isUrlOk()`
   -> `forbiddenURL(cleanPath(internal.toString()))`
   -> `URL.openConnection()`
   -> `network request`
5. 模型同时明确回答：
   `FIXED` 并不是“根本没有 LoadJson -> SURL 流程”，
   而是“相同入口链仍然存在，但新增的 `@/userinfo` 拒绝逻辑阻断了可利用性”。

对应证据：

- [M3 run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-pair/M3_differential_target_context_constrained/run_summary.json:1)
- [M3 normalized_output.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-pair/M3_differential_target_context_constrained/normalized_output.json:1)
- [M3 parsed_output.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-pair/M3_differential_target_context_constrained/llm_run/parsed_output.json:1)
- [M3 target_context_memo.md](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-pair/M3_differential_target_context_constrained/context_bundle/target_context_memo.md:1)
- [M3 pair_source_window.java.txt](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-pair/M3_differential_target_context_constrained/context_bundle/pair_source_window.java.txt:1)

### 7.3 当前结论

1. `M3` 首次恢复了这条 pair 需要的 `pair-level differential understanding`。
2. 触发恢复的关键，不是把 structured-label 再扩一点，而是把模型显式锚定到：
   `LoadJson.path -> SURL network path -> fixed-side @/userinfo guard`
   这条局部目标链。
3. 这说明对 `SSRF-3432 pair` 而言，真正缺失的不是一般 SSRF 常识，而是“要回答哪一条差分链”的任务约束。
4. 因此，后续 `M4/M5` 的价值主要变成：
   检查在放松输出约束后，这个差分理解是否还能稳定保留。

## 8. `M4_differential_free_auditor`

### 8.1 当前状态

- `completed`

### 8.2 当前结果

1. `M4` 保持与 `M3` 完全相同的上下文包：
   相同 `target-context memo`、
   相同 `M1` pair baseline summary、
   相同 target candidates、
   相同 `LoadJson / SURL` 局部源码窗口。
2. 唯一有意变化是：
   不再请求固定 JSON schema，
   改成 freeform differential audit。
3. 实际回答虽然自发包成了一个单字段 JSON，
   但字段值本体已经是自由文本审计说明，
   不再受 `M3` 那种显式字段约束驱动。
4. 这份审计文本明确写出：
   `LoadJson.loadStringData(path)` 是攻击者控制入口，
   `path` 进入 `SURL.create(path)`，
   `getBytes()` 在 `isUrlOk()` 通过后触发网络请求，
   `VULN` 侧缺少对 `@` 的拒绝，
   因而会出现 `userinfo` 造成的主机混淆与 SSRF。
5. 它也明确解释了 `FIXED` 侧为什么不再成立：
   `forbiddenURL()` 新增 `full.contains("@")` 立即拒绝，
   `isInUrlAllowList()` 也拒绝带 `@` 的 URL，
   因而同一 `LoadJson -> SURL` 路径对这个攻击向量不再可利用。
6. 模型还显式说明：
   这不是 generic `java.net` sink 枚举，
   而是针对 `userinfo/@` 绕过语义的 pair-level 修复解释。

对应证据：

- [M4 run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-pair/M4_differential_free_auditor/run_summary.json:1)
- [M4 normalized_output.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-pair/M4_differential_free_auditor/normalized_output.json:1)
- [M4 response.txt](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-pair/M4_differential_free_auditor/llm_run/response.txt:1)
- [M4 run_meta.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E2/AAE2_PAIR_SSRF3432_20260707T123717Z/SSRF-JA-REPO-CVE-2023-3432-pair/M4_differential_free_auditor/llm_run/run_meta.json:1)

### 8.3 当前结论

1. `M4` 保持了 `M3` 的 pair-level differential understanding。
2. 这说明对这条 pair 而言，
   真正关键的不是“必须用结构化 JSON 才能逼出正确答案”，
   而是先把模型显式锚定到正确的局部差分链。
3. 一旦这个差分目标被框定清楚，
   去掉 schema 并不会把模型重新打回 generic SSRF surface enumeration。
4. 按当前 stopping rule，
   `M4` 已经满足成功标准，
   所以本轮不需要继续进入 `M5`。

## 9. 下一步

本轮 `E2 SSRF-3432 pair` 可以先停在 `M4`。

只有在后续想专门验证“额外 repo 内检索是否还能再提高稳定性”时，才需要补跑 `M5_differential_agentic_auditor`。
