# `SSRF-3432 pair` 的 `E3 tool authority ablation` 人读报告

## 1. 作用

这份报告用于集中记录 `Architecture Attribution Experiment` 中 `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED` 的 `E3 tool authority ablation` 结果。

当前约定是：

- 第一轮只做 `SSRF-3432 pair`
- 固定执行 `A/B/C` 三档
- 不把这条 pair 的 `E3` 结果混写到 `E2` 或 `E4` 报告里

## 2. 当前覆盖范围

### 2.1 目标条件

这条 pair 的 `E3` 第一轮固定为：

1. `A_strong_authority`
2. `B_weak_authority`
3. `C_faulty_tool_injection`

### 2.2 当前状态

截至目前：

- `A` 已完成归档
- `B` 已完成归档
- `C` 已完成归档

### 2.3 当前证据

- [E3 SSRF3432 runbook](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e3_ssrf3432_pair_tool_authority_ablation_runbook.md:1)
- [E3 SSRF3432 checklist](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e3_ssrf3432_pair_execution_checklist.md:1)
- [E1 进展报告 `SSRF-3432 pair` 小节](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e1_static_gate_oracle_progress_report.md:183)
- [E2 独立人读报告](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e2_ssrf3432_pair_differential_freedom_report.md:1)
- [E4 独立人读报告](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e4_ssrf3432_deepaudit_information_control_report.md:172)
- [E3 run_manifest.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/AAE3_PAIR_SSRF3432_20260708T010411Z/run_manifest.json:1)
- [E3 family_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/AAE3_PAIR_SSRF3432_20260708T010411Z/family_matrix.tsv:1)

## 3. 共享判定规则

`E3` 关注的不是“有没有报 SSRF”，而是以下两层是否同时成立：

1. 是否恢复 `LoadJson.path -> SURL -> fixed guard` 这条 pair-level differential chain。
2. 是否把工具输出当作可质疑证据，而不是近似最终结论。

因此，本轮最关键的记录字段是：

- `authority_compliance`
- `tool_output_challenged`
- `target_alignment`
- `fixed_guard_explained`

以下情况都不记为支持 authority-ablation 假设：

- 只是报出 generic SSRF 风险
- 只是复述工具候选列表
- 只是说 `FIXED` 没路径
- 只恢复 `VULN`，不解释 fixed-side guard

## 4. 当前总表

| mode | status | authority_strength | tool_output_challenged | target_alignment | fixed_guard_explained | 当前说明 |
|---|---|---|---|---|---|---|
| `A_strong_authority` | completed | strong | true | true | true | 即使显式注入 `no path / source empty` 的高权威工具先验，模型仍然明确写出“工具结论必须被挑战”，并恢复完整差分链。 |
| `B_weak_authority` | completed | weak | true | true | true | 降低工具权威后，模型同样指出工具候选不完整，并恢复与 `A` 本质一致的 source/path/guard 解释。 |
| `C_faulty_tool_injection` | completed | weak_but_faulty | true | true | true | 面对故意缺失的候选表，模型显式命名缺失的 source 与 fixed-guard 节点，并主动修补工具输出。 |

## 5. 方法边界

当前需要明确记录：

1. 本报告只接收写入 `artifacts/architecture_attribution/E3/` 的证据。
2. `E2` 的成功结果只作为前置背景，不直接算作 `E3` 结果。
3. 本轮 `E3` 不测试 repo-level agentic search，也不混入 patch/diff/官方修复说明。
4. 因此，`E3` 的结论只能回答“工具权威是否压制模型”，不能回答“更自由检索是否还会继续增强表现”。

## 6. `A_strong_authority`

### 6.1 当前结果

1. `A` 明确注入了高权威工具先验：
   `no path`
   `source predicate 为空`
   以及“候选 surfaces 可视为主要证据”的表述。
2. 但模型没有顺从这个结论，反而第一句就明确说：
   工具结论必须被挑战。
3. 它随后恢复了：
   `LoadJson.loadStringData(path)` 作为外部输入，
   `SURL.create(path) -> getBytes()` 作为本地网络链，
   以及 `forbiddenURL` / `isInUrlAllowList` 里的 `@` 拒绝作为 fixed-side 差分。

对应证据：

- [A run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/AAE3_PAIR_SSRF3432_20260708T010411Z/SSRF-JA-REPO-CVE-2023-3432-pair/A_strong_authority/run_summary.json:1)
- [A normalized_output.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/AAE3_PAIR_SSRF3432_20260708T010411Z/SSRF-JA-REPO-CVE-2023-3432-pair/A_strong_authority/normalized_output.json:1)
- [A response.txt](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/AAE3_PAIR_SSRF3432_20260708T010411Z/SSRF-JA-REPO-CVE-2023-3432-pair/A_strong_authority/llm_run/response.txt:1)

### 6.2 当前结论

`A` 单独已经说明：

- 这条 pair 上，强 authority 并没有把模型直接压回 `source-empty / no-path` 顺从形状。

## 7. `B_weak_authority`

### 7.1 当前结果

1. `B` 保持与 `A` 同一批局部证据，但把工具表述降级为“辅助候选，不是完整 oracle”。
2. 模型明确指出：
   工具候选不完整，
   它漏掉了 `LoadJson.loadStringData(path)`、
   `LoadJson -> SURL -> getBytes()`，
   以及 fixed-side guard 语义。
3. 它给出的漏洞侧与 fixed 侧解释，与 `A` 的实质内容几乎一致。

对应证据：

- [B run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/AAE3_PAIR_SSRF3432_20260708T010411Z/SSRF-JA-REPO-CVE-2023-3432-pair/B_weak_authority/run_summary.json:1)
- [B normalized_output.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/AAE3_PAIR_SSRF3432_20260708T010411Z/SSRF-JA-REPO-CVE-2023-3432-pair/B_weak_authority/normalized_output.json:1)
- [B response.txt](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/AAE3_PAIR_SSRF3432_20260708T010411Z/SSRF-JA-REPO-CVE-2023-3432-pair/B_weak_authority/llm_run/response.txt:1)

### 7.2 当前结论

`B` 没有比 `A` 展现出本质不同的语义恢复能力。

因此目前看不到：

- “只要把 authority 降下来，模型才第一次恢复目标链”

这种形状。

## 8. `C_faulty_tool_injection`

### 8.1 当前结果

1. `C` 故意给了一份不完整的候选表：
   保留了一些 URL-facing surfaces，
   但漏掉了最关键的 source 与 fixed guard 节点。
2. 模型明确指出：
   这份 injected candidate list 不完整，
   它缺了 `LoadJson.loadStringData(path)`，
   也缺了 `forbiddenURL()` 与 `isInUrlAllowList()`。
3. 它不仅恢复了缺失节点，还明确解释：
   why vulnerable side holds，
   why fixed side no longer holds，
   and what the minimal semantic delta is.

对应证据：

- [C run_summary.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/AAE3_PAIR_SSRF3432_20260708T010411Z/SSRF-JA-REPO-CVE-2023-3432-pair/C_faulty_tool_injection/run_summary.json:1)
- [C normalized_output.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/AAE3_PAIR_SSRF3432_20260708T010411Z/SSRF-JA-REPO-CVE-2023-3432-pair/C_faulty_tool_injection/normalized_output.json:1)
- [C response.txt](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E3/AAE3_PAIR_SSRF3432_20260708T010411Z/SSRF-JA-REPO-CVE-2023-3432-pair/C_faulty_tool_injection/llm_run/response.txt:1)

### 8.2 当前结论

`C` 提供了本轮最强 authority-ablation 证据：

- 模型不只是“不顺从工具”，
- 而是会显式修补错误工具输出。

## 9. 当前合并判断

把 `A/B/C` 合在一起看，目前 `E3` 支持 4 个判断：

1. `SSRF-3432 pair` 上的模型并不会因为强 `no path / source empty` authority prior 就自动停止恢复目标链。
2. 降低 authority 强度，并没有带来从失败到成功的相变；`A` 和 `B` 都已经成功恢复 target differential。
3. 当工具输出被故意做错时，模型仍然会显式指出缺失 source / guard，并主动修补。
4. 因此，这条 pair 当前并不支持“tool authority 是主瓶颈”的假设。

更准确的描述是：

- 这条 pair 上更强的因子仍然是 task framing 与 local differential anchoring，
- 而不是单纯把静态工具 authority 再削弱一点。

## 10. 下一步

这轮 `E3 SSRF-3432 pair` 可以先收口。

如果后续还要继续扩：

1. 可以把 `E3` 横向补到 `SSRF-JA-REPO-001`，看 authority 结论是否只对这条 pair 成立。
2. 也可以把当前 `E3` 结果并回最终总报告，与 `E2/E4` 共同收口“framing vs authority vs information advantage”。
