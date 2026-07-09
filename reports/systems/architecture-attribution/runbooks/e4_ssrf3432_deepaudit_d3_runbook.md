# E4 SSRF-3432 DeepAudit D3 Runbook

## 1. 作用

这个 runbook 用于执行 `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED` 的 `E4 D3`：

- 有 `CVE` 高层描述
- 有真实 `VULN -> FIXED` patch/diff
- 无 `target_files`

它回答的问题是：

- `D2` 里只有 `CVE hint` 时，`DeepAudit` 仍然无法稳定区分 `VULN/FIXED`
- 加入真实修复差分后，`DeepAudit` 是否开始表现出 differential semantic understanding

## 2. 条件定义

### 2.1 D3

输入约束：

- 使用与 `D2` 同一层级的 curated subset repo
- 不提供 `target_files`
- 提供 repo 根目录的 `CVE_CONTEXT.md`
- 提供 repo 根目录的 `FIX_PATCH.diff`

其中：

- `CVE_CONTEXT.md` 只提供高层漏洞语义，不给目标函数、目标文件、行号
- `FIX_PATCH.diff` 提供真实 `VULN -> FIXED` 代码差分
- 不再额外加人工路径解释

## 3. 输入落点

- [AAE4_SSRF3432_VULN_D3.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/specs/AAE4_SSRF3432_VULN_D3.json:1)
- [AAE4_SSRF3432_FIXED_D3.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/specs/AAE4_SSRF3432_FIXED_D3.json:1)
- [VULN D3 staging](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/staging/SSRF-JA-REPO-CVE-2023-3432-VULN_D3/CVE_CONTEXT.md:1)
- [FIXED D3 staging](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/staging/SSRF-JA-REPO-CVE-2023-3432-FIXED_D3/CVE_CONTEXT.md:1)

## 4. 运行约束

真实 `DeepAudit` 连通性检查与 runner 启动都必须使用提权网络上下文，不得在默认沙箱里探测。

固定检查顺序：

1. `curl http://127.0.0.1:8000/health`
2. `curl http://localhost:8000/health`
3. `curl http://172.27.144.1:8000/health`

如果三者之一返回 `200`，优先使用第一个成功地址作为 backend。

## 5. 执行顺序

固定顺序：

1. `VULN D3`
2. `FIXED D3`

先看：

- `VULN D3` 是否比 `D2` 更接近真实修复机制

再看：

- `FIXED D3` 是否开始显式解释为什么 fixed side 不再成立

## 6. 完成后要写回哪里

本轮 `D3` 结果的主产物仍写入：

- `artifacts/architecture_attribution/E4/`

但结果解读需要回填到：

- [e1_static_gate_oracle_progress_report.md](/home/lqs/llm_audit_system_learning/reports/systems/architecture-attribution/summaries/e1_static_gate_oracle_progress_report.md:1)

写法要求：

- 作为 `SSRF-3432 pair` 的 `E1` 后续分流记录
- 明确标注这是 `E4 D3` 参照，不混写成 `E1` 本体版本
