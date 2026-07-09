# DeepAudit 最小扩样 Memo

## 总结

- 本轮 5 个最小扩样实验均已完成并进入 [expansion_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_minimal_expansion/20260702T061515Z/expansion_matrix.tsv:1)。
- 当前判级分布：
  - `usable`: 1
  - `partially_usable`: 4
  - `not_usable`: 0
- 这 5 条记录不是独立替代 boundary v1 主表，而是用于补强三类证据：
  - 非 `PT` synthetic repo 泛化
  - 第二条 real-world 项目线泛化
  - 关键 `C-real-world PT` 结论的稳定性

## 最重要的新结论

- `C-real-world` 的可用性不再只建立在 `Litestar / PT / CVE-2024-32982` 一条线上。
  - `C-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN` 明确达到 `usable`
  - 首条 finding 直接命中 `CVE-2024-45053 / SSTI`
  - 前 3 条 findings 仍围绕 `_render`、`Environment().from_string()` 与 `MessagingTemplate.content` 展开
- `D-real-world` 在第二条 real-world 项目线上再次暴露出明显的高成本退化。
  - `D-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN` 最终能收敛到真实目标链路
  - 但代价达到 `47 iterations / 41 tool calls / 748569 tokens / 596s`
  - 这不是“更强能力”，而是“以高成本硬换目标信号”
- `C-real-world PT` 的 repeat 支持“target signal 稳定”，但不支持“排序与 framing 完全稳定”。
  - repeat 仍命中 `PT`
  - 成本量级与原始 `C3` 主记录接近甚至略高
  - 但 top findings 从 `commonpath/CVE framing` 漂移到 `handle/path 规范化` framing

## 分组判断

- `C-synthetic-SSRF-PY-REPO-001`
  - 说明 `C` 的优势不只存在于 `PT`
  - 但对 3 文件 synthetic repo 来说，`278s / 159260 tokens` 仍偏高，因此暂不判 `usable`
- `D-synthetic-SSRF-PY-REPO-001`
  - 同样命中 `SSRF`
  - 与 `C` 相比，更容易展开到 service / app 注册 / 结构层说明
  - 在这个小 case 上，`D` 不一定更慢，但更发散
- `C-real-world-PT-PY-REPO-CVE-2024-32982-VULN-repeat1`
  - 说明 `C-real-world PT` 不是一次性偶然命中
  - 但也说明这条线的输出 framing 仍会漂移
- `C-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN`
  - 是本轮最强的新证据
  - 证明 `C-real-world` 的 `usable` 可迁移到第二个 Python real-world 项目与第二类漏洞家族
- `D-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN`
  - 是本轮最强的 `D-real-world` 负面证据
  - 证明完整大仓库下不显式收窄时，DeepAudit 会出现非常明显的 agent 编排与广扫描代价

## 对 boundary v1 的修正

- boundary v1 中“`C` 是当前最接近受控可用的 repo 形态”这一结论被增强，而不是被推翻。
  - 现在它不再只依赖 `PT / Litestar` 个案
  - `C-real-world-SSTI` 让这条结论获得第二条 real-world 项目线支撑
- 同时，boundary v1 中对 `C` 的描述需要增加一个约束：
  - `C` 仍是最强 repo 形态
  - 但“target signal 稳定”不等于“排序与表述稳定”
- boundary v1 中“`D` 更接近现实压力，但高成本、慢收敛、噪声更多”这一结论被显著增强。
  - 第二条 real-world 项目线复现了同样的模式

## 收口表述

把 boundary v1 与最小扩样合并后，更稳妥的结论是：

- `A` 仍然代表基础语义能力上界
- `C` 仍然是当前最接近受控可用的 repo 工作流形态
- `C-real-world usable` 不再是单个项目特例，但其输出 framing 仍存在波动
- `D` 能命中目标，但在完整 real-world 大仓库上通常通过高成本 agent 编排才收敛，因此更适合当压力基线，而不是日常可用形态
