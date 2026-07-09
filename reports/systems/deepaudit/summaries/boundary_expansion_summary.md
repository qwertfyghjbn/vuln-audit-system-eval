# DeepAudit Boundary Memo

## 总结

- 当前 8 个主记录中，`usable` 有 3 个：`A-synthetic-PT-PY-FILE-001`、`A-synthetic-SSRF-PY-FILE-001`、`C-real-world-PT-PY-REPO-CVE-2024-32982-VULN`。
- `partially_usable` 有 5 个，集中在 `B/C/D` 的 agent repo 形态。
- `not_usable` 当前为 0 个，但 `B-synthetic-PT-PY-FILE-001-mini-repo` 已接近边界下沿，主要问题是结果不够干净。

## 形态判断

- `A`：在 synthetic 单文件上最稳定，PT/SSRF 都能快速给出 clear target signal，属于当前最明确的 `usable` 边界。
- `B`：repo 结构感能帮助命中目标，但不自动带来干净输出；small repo 在 synthetic 上仍有 hallucination 风险，在 real-world 上成本仍偏高。
- `C`：是当前最接近真实可用的 repo 形态。尤其在 real-world + target_files 下，目标命中、排序和噪声控制最好。
- `D`：保留了现实压力，但当前主要表现为高成本、慢收敛和辅助噪声偏多，只能算 `partially_usable`。

## 分层判断

- `synthetic`：A 形态已经达到 `usable`；B/C/D 都能命中 PT，但仍不同程度受到噪声、排序或成本影响。
- `real-world`：C 形态是当前唯一明确达到 `usable` 的主记录；B/D 虽然能打到目标，但都还不够收敛。

## 真正可用边界

- 如果目标是观察基础漏洞语义能力，当前边界是：`A / instant analysis`。
- 如果目标是观察 repo 工作流里的受控可用性，当前边界是：`C / 完整 repo + target_files`。
- 如果不提供显式收窄，只给 repo 结构，DeepAudit 仍能命中目标，但更容易落入 `partially_usable`。

## 判级明细

- `A-synthetic-PT-PY-FILE-001`: `usable`
  解释：target_signal=clear，noise_shape=low，ranking_quality=good；首条 finding 直接命中 PT，辅噪主要是 debug 与实现层问题；instant analysis 约 35.8 秒返回，适合作为基础语义能力上界。
- `A-synthetic-SSRF-PY-FILE-001`: `usable`
  解释：target_signal=clear，noise_shape=moderate，ranking_quality=good；首条 finding 直接命中 SSRF，后续主要是 debug、异常泄露和协议约束类扩展告警；44 秒内同步返回，可作为 synthetic/SSRF 的正式 A 记录。
- `B-synthetic-PT-PY-FILE-001-mini-repo`: `partially_usable`
  解释：target_signal=partial，noise_shape=high，ranking_quality=poor；虽然命中了 PT，但 findings 中出现与样本不完全贴合的 `/logs` 端点和 `app.py:54` 等内容；它证明了 repo 结构感有帮助，但输出不够干净。
- `B-real-world-PT-PY-REPO-CVE-2024-32982-VULN`: `partially_usable`
  解释：target_signal=clear，noise_shape=moderate，ranking_quality=good；裁剪小 repo 能稳定命中真实世界 PT，前 3 条以目标信号为主；但 443 秒、174056 tokens 的成本仍然偏高，说明“有 repo 结构感”仍不等于“低成本可用”。
- `C-synthetic-PT-PY-REPO-001`: `partially_usable`
  解释：target_signal=clear，noise_shape=moderate，ranking_quality=mixed；显式收窄后能稳定命中 PT，但首条 finding 仍偏入口层辅助告警，而不是最佳漏洞总览；347 秒、255182 tokens 的成本也偏高。
- `C-real-world-PT-PY-REPO-CVE-2024-32982-VULN`: `usable`
  解释：target_signal=clear，noise_shape=low，ranking_quality=good；这是当前最接近“受控可用”的 repo 形态：前 3 条 findings 都围绕 CVE-2024-32982/PT 展开，排序稳定，噪声可控；成本仍不低，但结果质量成立。
- `D-synthetic-PT-PY-REPO-001`: `partially_usable`
  解释：target_signal=clear，noise_shape=high，ranking_quality=mixed；目标 PT finding 排在第 2 条，前面有入口层辅助告警；整体呈现典型 broad-scan noise，且 217 秒、177167 tokens 的成本偏高。
- `D-real-world-PT-PY-REPO-CVE-2024-32982-VULN`: `partially_usable`
  解释：target_signal=clear，noise_shape=high，ranking_quality=mixed；完整大仓库在高预算下能拖到完成并命中 PT，但输出混有配置层和文件响应层扩展告警，还有 1 条已验证无实际影响项；成本最高，更多是在用代价硬换收敛。

## 当前收口建议

- boundary v1 主表现在已经具备统一判级基础，可以进入“字段补全 + 主表冻结”阶段。
- 下一步不宜再补跑新形态，而应先把这 8 条主记录的 `target_signal / noise_shape / ranking_quality / usability_tier` 固化进统一表。
- near-miss 扩展应放到 boundary 主表收口之后，再作为第二层扩展进入。
