# IRIS Registries

这个目录预留给 `IRIS` 的人读索引和规范化表。

当前已写入：

- [canonical_results.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/canonical_results.tsv:1)
- [variant_registry.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/variant_registry.md:1)
- [official_case_trustworthiness_shortlist.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/official_case_trustworthiness_shortlist.tsv:1)
- [self_case_trustworthiness_shortlist.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/self_case_trustworthiness_shortlist.tsv:1)
- [official_results_join_map.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/official_results_join_map.tsv:1)

后续应继续在这里放置：

- `run_inventory.tsv`
- `evidence_index.json`

其中：

- `canonical_results.tsv`
  - 用于把每一轮 `run_id` 的 case 级结果固化成统一表结构
- `variant_registry.md`
  - 用于明确记录：

  - 哪些运行属于 `official upstream baseline`
  - 哪些运行属于 `runtime compatibility variant`
  - 哪些运行属于 `capability-changing variant`
- `official_case_trustworthiness_shortlist.tsv`
  - 用于冻结本轮 5 个官方 case 的角色、query id、构建契约和官方结果摘要
- `self_case_trustworthiness_shortlist.tsv`
  - 用于冻结本轮自有对照 case 及其输入契约状态
- `official_results_join_map.tsv`
  - 用于把官方结果 CSV 行稳定映射到本轮 5 个官方 `project_slug`

任何后续修改，只要会影响 `IRIS` 的候选生成、prompt、解析、ranking、后处理或预算边界，都必须先登记后运行。
