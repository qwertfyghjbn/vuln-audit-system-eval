# `SSRF-3432` 的 `E4` 独立人读报告

## 1. 目的

这份报告汇总 `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED` 在 `E4 DeepAudit 信息优势控制实验` 下的 `D1/D2/D3/D4` 结果，回答两个问题：

- `DeepAudit` 相对 `IRIS/OpenAnt` 的优势，究竟有多少来自更自由的审计架构
- 这种优势又有多少来自额外信息输入，如 `CVE hint`、`patch/fixed diff`、`target_files`

本报告只整理 `SSRF-3432 pair` 的 `E4` 结果，不混写其他 case，也不替代总报告。

## 2. 条件定义

| 条件 | 给 `CVE` 描述 | 给真实 `FIX_PATCH.diff` | 给 `target_files` | 目标 |
|---|---|---|---|---|
| `D1` | 否 | 否 | 否 | 观察纯 repo 审计能力 |
| `D2` | 是 | 否 | 否 | 观察高层漏洞 hint 是否足以抬升目标命中 |
| `D3` | 是 | 是 | 否 | 观察 `diff` 是否足以恢复修复差分理解 |
| `D4` | 是 | 是 | 是 | 观察 `target_files` 是否能把注意力收敛回真实修复文件 |

对应 runbook：

- [D1/D2 runbook](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e4_ssrf3432_deepaudit_d1_d2_runbook.md:1)
- [D3 runbook](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e4_ssrf3432_deepaudit_d3_runbook.md:1)
- [D4 runbook](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/runbooks/e4_ssrf3432_deepaudit_d4_runbook.md:1)

## 3. 结果总览

### 3.1 指标表

| 条件 | Iter | Tool calls | Tokens | Findings | 最显眼输出 |
|---|---:|---:|---:|---:|---|
| `VULN D1` | 26 | 20 | 301975 | 8 | 命中 `LoadJson -> SURL` SSRF 入口，但偏泛化 SSRF 面枚举 |
| `FIXED D1` | 37 | 27 | 367407 | 6 | top-1 直接报 `HTTP 302 redirect` 绕过，未理解 fixed side |
| `VULN D2` | 31 | 27 | 407604 | 8 | top-1 直接打到 `HTTP redirect following`，更接近目标机制 |
| `FIXED D2` | 27 | 20 | 295330 | 9 | 仍大量报 `allowlist / cleanPath / LoadJson` 问题 |
| `VULN D3` | 30 | 25 | 370115 | 7 | 注意力偏到 `LEGACY` 默认模式和 `TContext.executeInclude()` |
| `FIXED D3` | 31 | 27 | 436815 | 7 | 仍报 `LEGACY`、`forbiddenURL()`、`%load_json` 相关风险 |
| `VULN D4` | 30 | 28 | 479619 | 10 | 注意力回到 `LoadJson / SURL`，重获 `HTTP redirect` finding |
| `FIXED D4` | 31 | 23 | 400247 | 11 | 仍未解释 fixed 为何不成立，反而 findings 更多 |

核心证据：

- [D1/D2 run_manifest](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D1D2_20260707T004749Z/run_manifest.json:1)
- [D3 run_manifest](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D3_20260707T013951Z/run_manifest.json:1)
- [D4 run_manifest](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D4_20260707T020239Z/run_manifest.json:1)

### 3.2 `VULN/FIXED` 配对解读

| 条件 | `VULN` 侧表现 | `FIXED` 侧表现 | 当前判断 |
|---|---|---|---|
| `D1` | 能发现 repo 内存在 SSRF 面，但没有稳定收敛到真实修复差分 | 同样继续报强 SSRF finding | 纯 repo 审计有能力找到“某种 SSRF”，但无差分区分能力 |
| `D2` | `CVE hint` 明显抬升目标机制命中，开始稳定提到 `HTTP redirect` | `FIXED` 也被同类语义带偏，误报仍高 | `CVE hint` 主要改变注意力，不自动带来 fixed 解释 |
| `D3` | 加入真实 `diff` 后，反而被 `TContext.executeInclude()` 等泛化入口吸走 | 仍未解释修复后为何安全 | `diff` 本身不足以约束模型收敛到真实修复点 |
| `D4` | `target_files` 把注意力重新拉回 patch 文件 | 仍继续报 patch 文件上的风险，而不是解释 guard 生效 | `target_files` 约束有效，但只解决“看哪里”，不解决“如何做差分理解” |

## 4. 分条件观察

### 4.1 `D1`：无任何提示时，`DeepAudit` 已能做自由 repo 审计，但无法区分 pair

`VULN D1` 已能命中：

- `%load_json / LoadJson` 作为用户可控 URL 入口
- `SURL` 的 `forbiddenURL()`、allowlist、重定向等 SSRF 相关风险

对应证据：

- [VULN D1 metrics](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D1D2_20260707T004749Z/AAE4_SSRF3432_VULN_D1/metrics.json:1)
- [VULN D1 findings](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D1D2_20260707T004749Z/AAE4_SSRF3432_VULN_D1/task_findings.json:1)

但 `FIXED D1` 依然给出强 `HTTP 302 redirect` SSRF 结论：

- top-1 就是 `HTTP 302重定向SSRF绕过 - 重定向目标未经过安全验证`

对应证据：

- [FIXED D1 metrics](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D1D2_20260707T004749Z/AAE4_SSRF3432_FIXED_D1/metrics.json:1)
- [FIXED D1 findings](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D1D2_20260707T004749Z/AAE4_SSRF3432_FIXED_D1/task_findings.json:1)

这说明：

- `DeepAudit` 的自由搜索能力，确实比静态 gate workflow 更容易在大仓库里找到 SSRF 面
- 但只靠这种自由搜索，还不能自然恢复 `VULN/FIXED` 差分语义

### 4.2 `D2`：`CVE hint` 能提升目标命中，但也同步污染 `FIXED`

`VULN D2` 的 top-1 直接变成：

- `SSRF via HTTP Redirect Following - Bypasses All Security Checks`

这比 `D1` 更接近 `SSRF-3432` 真实机制，说明高层 `CVE` 描述确实能把模型从“泛化 SSRF 面扫描”拉向“更像目标漏洞”的方向。

对应证据：

- [VULN D2 metrics](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D1D2_20260707T004749Z/AAE4_SSRF3432_VULN_D2/metrics.json:1)
- [VULN D2 findings](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D1D2_20260707T004749Z/AAE4_SSRF3432_VULN_D2/task_findings.json:1)

但 `FIXED D2` 仍然报：

- `allowlist` 前缀匹配
- `cleanPath()` 规范化不足
- `LoadJson` 入口风险

并没有显式说明 fixed side 的 guard 为何已经改变结论。

对应证据：

- [FIXED D2 metrics](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D1D2_20260707T004749Z/AAE4_SSRF3432_FIXED_D2/metrics.json:1)
- [FIXED D2 findings](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D1D2_20260707T004749Z/AAE4_SSRF3432_FIXED_D2/task_findings.json:1)

这说明：

- `CVE hint` 的主要作用是提升命中目标语义的概率
- 但它并不会自动让模型具备“修复后为什么不成立”的解释能力

### 4.3 `D3`：只补 `diff`，不足以稳定收敛到真实修复点

按原计划，`D3` 用来验证真实 `FIX_PATCH.diff` 是否足以带来差分理解。

结果并不支持这一点：

- `VULN D3` top-1/2 重新转向 `LEGACY` 默认模式和 `TContext.executeInclude()`
- 注意力离开了 `LoadJson / SURL / allowlist / userinfo` 这条真实 patch 机制

对应证据：

- [VULN D3 metrics](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D3_20260707T013951Z/AAE4_SSRF3432_VULN_D3/metrics.json:1)
- [VULN D3 findings](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D3_20260707T013951Z/AAE4_SSRF3432_VULN_D3/task_findings.json:1)

`FIXED D3` 也仍在报：

- `LEGACY` 默认模式不安全
- `forbiddenURL()` 绕过
- `%load_json` 入口问题

对应证据：

- [FIXED D3 metrics](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D3_20260707T013951Z/AAE4_SSRF3432_FIXED_D3/metrics.json:1)
- [FIXED D3 findings](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D3_20260707T013951Z/AAE4_SSRF3432_FIXED_D3/task_findings.json:1)

结论是：

- 真实 `diff` 信息本身，并不足以防止模型被仓库中更显眼的泛化风险吸走
- `diff` 不是无效，而是缺少与之配套的注意力边界

### 4.4 `D4`：`target_files` 能收敛注意力，但仍不能恢复 fixed-guard 理解

`D4` 在 `D3` 基础上补入真实 patch 文件列表后：

- `VULN D4` 注意力明显回到 `LoadJson`、`SURL`、`SecurityProfile`
- `HTTP redirect` 再次回到前列

对应证据：

- [VULN D4 metrics](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D4_20260707T020239Z/AAE4_SSRF3432_VULN_D4/metrics.json:1)
- [VULN D4 findings](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D4_20260707T020239Z/AAE4_SSRF3432_VULN_D4/task_findings.json:1)

这说明 `target_files` 的确有效，它把模型从 `TContext.executeInclude()` 这类泛化入口重新拉回真实 patch 文件。

但 `FIXED D4` 仍然没有给出“fixed side 为什么不再成立”的清晰解释，反而 findings 数上升到 `11`：

- [FIXED D4 metrics](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D4_20260707T020239Z/AAE4_SSRF3432_FIXED_D4/metrics.json:1)
- [FIXED D4 findings](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/AAE4_SSRF3432_D4_20260707T020239Z/AAE4_SSRF3432_FIXED_D4/task_findings.json:1)

因此 `D4` 只能支持较弱结论：

- `target_files` 能改善“看哪里”
- 但仍不足以单独改善“为什么 fixed 已经安全”

## 5. 综合结论

`SSRF-3432 pair` 的 `E4` 结果可以收敛为四点：

1. `DeepAudit` 的 repo-level 自由搜索能力是真实存在的。
   即使在 `D1`，它也已经比静态 gate workflow 更容易找到 SSRF 面和攻击入口。
2. 但这种自由能力不等于自然具备差分理解。
   `D1` 到 `D4` 全部都没有稳定解释 `FIXED` 为什么不成立。
3. `CVE hint`、`diff`、`target_files` 的作用是不同层级的。
   `CVE hint` 主要改变高层语义方向，`diff` 提供修复证据，`target_files` 提供注意力边界。
4. 在这条 pair 上，最缺的仍是“修复语义解释器”，不是单纯更多信息。
   即便 `D4` 已同时给出 `CVE + diff + target_files`，系统仍然更擅长报 patch 周边风险，而不是输出可靠的 `vulnerable/fixed` 差分解释。

## 6. 对架构归因主线的含义

这份 `E4` 单独报告对总假设的约束是：

- `IRIS/OpenAnt` 失败，确实不能简单解释成“模型太弱”
- 但也不能反过来简单解释成“只要换成 agentic auditor 就能自然恢复正确答案”

更稳妥的结论是：

- `static-gated workflow` 会限制模型，但放开工作流之后，系统仍然需要足够强的差分语义约束
- 对 `SSRF-3432 pair` 而言，`DeepAudit` 目前更像是“能找到很多相关风险的自由审计器”，还不是“能稳定解释补丁前后语义差异的差分审计器”

## 7. 与已有报告的关系

这份文档把原先嵌在 `E1` 进度报告里的 `SSRF-3432 E4` 观察独立出来，便于后续继续补：

- `E5 vulnerable/fixed differential` 结果
- 与 `cron-utils` 等其它 family 的横向比较
- 最终总报告中的“信息优势 vs 架构优势”收口

此前的嵌入式记录仍保留在：

- [e1_static_gate_oracle_progress_report.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e1_static_gate_oracle_progress_report.md:197)
