# Failure Taxonomy

轮次：`2026-06-28-round1`

基线输入：

- `openant_case_matrix.csv`
- `openant_vs_current_comparison.md`
- `manifests/openant_b2_stage2_backfill_template.json`

本文件不是泛化到全部评估集的最终 taxonomy，而是基于当前已回填的首批 8 个 Python case，总结“当前系统为什么失败、OpenAnt 为什么成功或为何仍会偏”的诊断分类。

## 一、当前样本面

Step 6A 的 `compare_bucket` 分布：

- `hit_vulnerable`: 2
- `miss_no_signal`: 3
- `fp_offtarget`: 2
- `clean_negative`: 1

Step 8 回填后，4 个进入 Stage2 的 case 结果为：

- `confirmed_vulnerable`: 2
- `needs_review_only`: 1
- `mixed_confirmed_and_needs_review`: 1

这说明当前问题不是单一“模型好坏”，而是至少同时存在四层差异：

1. 当前系统 strict gate 过强，真实命中也可能不发射。
2. OpenAnt Stage1 更敢报，但会把“可疑代码”与“标注锚点”混在一起。
3. Stage2 能削减一部分噪声，但不会自动把 off-target finding 迁移回 ground truth anchor。
4. 大仓库上两套系统的失败模式不同：当前系统更像“超时/不出结果”，OpenAnt 更像“能跑完但会泛化出很多非目标安全问题”。

## 二、分类表

| Taxonomy ID | 定义 | 代表 case | 当前系统信号 | OpenAnt 信号 | 诊断含义 |
|---|---|---|---|---|---|
| `T1_strict_semantic_veto_on_true_positive` | OpenAnt Stage1 已命中 ground truth anchor，但当前系统 strict 因 semantic gate 不发射 | `PT-PY-FILE-001`, `PT-PY-REPO-001` | `no_finding_emitted + conflicting_judgment` | `VULNERABLE` 且 `anchor_match=True` | 当前系统并非完全“没看见”，而是把真实候选卡死在 strict 判别门前 |
| `T2_stage1_offtarget_on_true_vulnerable` | OpenAnt 在真实漏洞 case 上给出 `VULNERABLE`，但首个强信号不落在 ground truth anchor | `SSRF-PY-REPO-001`, `SSTI-PY-REPO-001`, `SSRF-PY-REPO-CVE-2025-2828-VULN` | strict 多为 `no_finding_emitted`，balanced 可能也 `anchor_mismatch` 或 `timeout` | Stage1 有强阳性，但 `anchor_match=False` | OpenAnt 更偏“找仓库里的安全问题”，不天然等于“命中该 benchmark 的目标点” |
| `T3_stage1_clean_negative` | OpenAnt Stage1 在 near-miss 上不给危险 verdict | `SSRF-PY-REPO-002` | strict `clean_no_finding` | Stage1 top=`SAFE` | 这类 case 说明 OpenAnt 并非一味激进，负样本上可保持克制 |
| `T4_stage1_false_positive_on_near_miss` | near-miss 上出现 off-target 危险 verdict，且不落在 guard scope | `PT-PY-REPO-002`, `SSTI-PY-REPO-CVE-2024-45053-FIXED` | balanced 已出现 `guard_scope_miss`，后者更有 `100` 条误报 | Stage1 top=`VULNERABLE`, `guard_match=False` | 两套系统都会被“仓库里别的风险点”带偏，只是噪声形态不同 |
| `T5_stage2_prunes_but_does_not_reanchor` | Stage2 能削弱 Stage1 噪声，但不会自动把 finding 改写到 benchmark 目标锚点 | `PT-PY-REPO-002`, `SSTI-PY-REPO-001` | 当前系统无对应纠偏层 | Stage2 变成 `protected` / `needs_review`，或继续确认 off-target finding | Stage2 更像 verdict 校正器，不是 benchmark anchor 对齐器 |
| `T6_large_repo_timeout_vs_broad_scan` | 当前系统在大仓库上超时；OpenAnt 能跑完整体分析，但产出大量宽泛安全结论 | `SSRF-PY-REPO-CVE-2025-2828-VULN`, `SSTI-PY-REPO-CVE-2024-45053-FIXED` | strict/balanced `timeout`，或被 provider 噪声淹没 | Stage1 覆盖 500+ units，产生几十条 `VULNERABLE` | 两套系统的大仓库瓶颈不同：一个是吞吐失败，一个是 precision 失控 |
| `T7_provider_evidence_type_drift` | 当前系统把 Bandit 的通用安全告警，硬绑定成 benchmark 指定 vuln_type | `PT-PY-FILE-001`, `PT-PY-REPO-002`, `SSTI-PY-REPO-001` | balanced 用 `flask_debug_true` 产出 `path_traversal` / `ssti` finding | OpenAnt 直接按 `CWE-489` / debug 风险表达 | 当前系统失败不只是 semantic gate，还包括 provider evidence 到 vuln taxonomy 的映射漂移 |

## 三、逐类说明

### T1 `strict_semantic_veto_on_true_positive`

代表现象：

- `PT-PY-FILE-001` 中，OpenAnt Stage1/Stage2 都稳定命中 `app.py:download_file`。
- 当前系统 strict 仍是 `no_finding_emitted`，主因 `conflicting_judgment`。

这类 case 最重要的结论不是“OpenAnt 比当前系统更聪明”，而是：

- 当前系统的 upstream candidate 未必为空。
- 真实问题可能已经在候选层出现，但被 strict 策略直接否决。

这类样本最适合后续做“去掉 semantic gate 后 recall 是否回升”的定向实验。

### T2 `stage1_offtarget_on_true_vulnerable`

代表现象：

- `SSTI-PY-REPO-001` 的 GT 在 `src/utils/template_utils.py:render_report_template`。
- OpenAnt Stage1/Stage2 却把 `app.py:__module__` 的 `debug=True` 作为主要阳性。
- verify explanation 已经口头指出真实 SSTI 路径，但结果仍确认了 debug finding。

这说明 OpenAnt 的 Stage2 在当前流程里回答的是：

- “Stage1 这个 finding 是否也成立？”

而不是：

- “这个 case 的 benchmark target 是不是这里？”

所以它可以在“事实层面正确”与“benchmark 对齐层面错误”同时成立。

### T3 `stage1_clean_negative`

`SSRF-PY-REPO-002` 是目前最干净的负样本：

- 当前系统 strict 为 `clean_no_finding`
- OpenAnt Stage1 top 为 `SAFE`

这类 case 应该在后续 round 中持续保留，作为“OpenAnt 是否会在 near-miss 上泛化误报”的稳定观测点。

### T4 `stage1_false_positive_on_near_miss`

`PT-PY-REPO-002` 与 `SSTI-PY-REPO-CVE-2024-45053-FIXED` 共同说明：

- near-miss 不等于“仓库内不存在任何别的风险点”
- 一旦评估目标是 benchmark 目标漏洞，off-target 风险也应计为失败

两套系统在这里都暴露出 guard/scope 问题：

- 当前系统 balanced 会把非目标告警直接发射出来
- OpenAnt Stage1 会给出危险 verdict，Stage2 只能部分收缩

### T5 `stage2_prunes_but_does_not_reanchor`

当前回填样本里，Stage2 做了两类事：

- 把一些 `VULNERABLE` 降成 `SAFE` / `PROTECTED`
- 保留少量 `VULNERABLE` 或 `NEEDS_REVIEW`

但它没有做的一件事是：

- 当 Stage1 命错锚点时，主动迁移到 GT anchor

因此 Stage2 更适合作为“危险性复核器”，不适合作为“benchmark 对齐器”。

### T6 `large_repo_timeout_vs_broad_scan`

大仓库 case 的核心差异：

- 当前系统更容易停在 `timeout`
- OpenAnt 更容易给出大量宽泛安全结论

例如：

- `SSRF-PY-REPO-CVE-2025-2828-VULN` 上，当前系统 strict/balanced 都是 `timeout`
- OpenAnt Stage1 成功分析 `575` 个 unit，并给出 `93` 个 `VULNERABLE`

这不是“OpenAnt 直接赢了”，而是两套系统在不同环节失控：

- 当前系统输在吞吐与调度
- OpenAnt 输在 target precision

### T7 `provider_evidence_type_drift`

这是当前系统特有且很关键的一类错误。

在多个 case 中，Bandit 的 `B201 flask_debug_true` 被映射进 benchmark 的目标 vuln_type，结果出现：

- Path Traversal case 发射了 debug finding
- SSTI case 发射了 debug finding

这会造成两个后果：

1. 即使关闭 semantic verification，也只会更快地产生 off-target finding。
2. “当前系统失败是不是因为 semantic gate 太严格”这个结论会被高估，因为还有更上游的 evidence taxonomy 漂移。

## 四、对后续实验的直接启发

优先级最高的后续动作：

1. 在 `T1` 样本上做“strict 去门控 / 降门控”对照，确认真实 recall 提升幅度。
2. 在 `T7` 样本上检查 Bandit rule 到内部 `vuln_type` 的映射与绑定策略，否则放松 gate 只会放大误报。
3. 对 `T2` / `T5` 样本，把“finding 是否成立”和“是否命中 benchmark target”拆成两个维度单独统计。
4. 对 `T6` 样本，单独记录吞吐指标与 top-k vulnerable 分布，避免把“能跑完”误读成“命中正确”。

## 五、关联深挖

- `case_deep_dives/PT-PY-FILE-001.md`
- `case_deep_dives/PT-PY-REPO-002.md`
- `case_deep_dives/SSTI-PY-REPO-001.md`
- `case_deep_dives/SSRF-PY-REPO-CVE-2025-2828-VULN.md`
- `case_deep_dives/SSTI-PY-REPO-CVE-2024-45053-FIXED.md`
