# DeepAudit Registries

这个目录用于存放 `DeepAudit` 的规范化索引和主表。

当前已存在的阶段性 registry 位于：

- [artifacts/deepaudit_boundary_expansion/registry/README.md](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/registry/README.md:1)
- [canonical_boundary_slots.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/registry/canonical_boundary_slots.tsv:1)
- [legacy_experiment_registry.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/registry/legacy_experiment_registry.tsv:1)

后续如果要为 DeepAudit 建立仓库级统一主表，例如：

- `run_inventory.tsv`
- `canonical_results.tsv`
- `evidence_index.json`

应优先写入本目录，而不是继续散落在某个单独阶段的 `artifacts/` 子目录下。

