# V3 Unit vs OpenAnt Unit 落盘文件对比报告

## 1. 实验目标

本轮只比较 Unit partition fidelity：比较两套系统如何把源码切成结构单元、anchor 是否被覆盖、span 是否紧凑、父子关系是否保留。
本报告不比较漏洞发现性能，也不把 OpenAnt 的 Stage1/Stage2 结论当作 unit 质量证明。

## 2. 数据来源

### V3 unit 产物

- 主来源：历史 V3 `run.db -> units` 表导出
- 使用到的 V3 数据源条目数：`18`

### OpenAnt unit 产物

- 主来源：`OpenAnt` scope-aligned parse 产物中的各 case `parse/functions.json` 与 `parse/dataset.json`
- 使用到的 OpenAnt 数据源条目数：`18`

### Ground truth

- 每个 case 使用 `ground_truth.json` 中的 `recall_anchor.minimum_match`、`expected_findings.location` 或 `case_target.minimum_match`。

### 缺失与 fallback

- PT-PY-FILE-001: V3 run.db 中未找到持久化 unit 表
- PT-PY-FILE-002: V3 run.db 中未找到持久化 unit 表
- SSRF-PY-FILE-001: V3 run.db 中未找到持久化 unit 表
- SSRF-PY-FILE-002: V3 run.db 中未找到持久化 unit 表
- SSTI-PY-FILE-001: V3 run.db 中未找到持久化 unit 表
- SSTI-PY-FILE-002: V3 run.db 中未找到持久化 unit 表
- fallback_used: 当前 benchmark 仓库中的 synthetic file cases
- fallback_cases: `PT-PY-FILE-001`, `PT-PY-FILE-002`, `SSRF-PY-FILE-001`, `SSRF-PY-FILE-002`, `SSTI-PY-FILE-001`, `SSTI-PY-FILE-002`

## 3. 最小公共字段

统一 schema 包括：`case_id / system / file_path / unit_key / unit_name / qualified_name / kind / line_start / line_end / span_lines / parent_key / raw_source_path / normalization_notes`。

字段投影说明：

- V3：直接来自 `run.db.units`，可稳定提供 `qualified_name`、`parent_unit_id`、`unit_kind`。
- OpenAnt：结构主表来自 `parse/functions.json` 与 `classes`；`parse/dataset.json` 只作为 `analysis_included` 提示，不替代结构主表。
- OpenAnt 缺少统一 `parent_key` 时，仅在 `class_name -> class unit` 可解析时补齐；否则保留为空。
- 某些 V3 file-mode case 没有完整持久化 unit 表时，使用 case 源码重建最小结构单元，并在 `normalization_notes` 中显式标注。

## 4. 总体统计

- case 数：`18`
- 文件数：`13050`
- V3 unit 总数：`83579`
- OpenAnt unit 总数：`72632`
- V3 平均 span：`37.31`，p95：`150.0`，tiny ratio：`0.1825`，large ratio：`0.0953`
- OpenAnt 平均 span：`26.77`，p95：`86.0`，tiny ratio：`0.1492`，large ratio：`0.056`
- anchor containment：`both=17` / `only_v3=1` / `only_openant=0` / `both_missing=0`

## 5. File-level 差异

V3 切得更细的代表文件：
- `SSRF-PY-REPO-CVE-2025-2828-FIXED:libs/core/tests/unit_tests/runnables/test_runnable.py` -> V3 `165` vs OpenAnt `100`
- `SSRF-PY-REPO-CVE-2025-2828-VULN:libs/core/tests/unit_tests/runnables/test_runnable.py` -> V3 `165` vs OpenAnt `100`
- `PT-PY-REPO-CVE-2024-32982-FIXED:tests/unit/test_dto/test_factory/test_integration.py` -> V3 `112` vs OpenAnt `53`
- `PT-PY-REPO-CVE-2024-32982-VULN:tests/unit/test_dto/test_factory/test_integration.py` -> V3 `112` vs OpenAnt `53`
- `SSRF-PY-REPO-CVE-2025-2828-FIXED:libs/core/tests/unit_tests/test_tools.py` -> V3 `108` vs OpenAnt `55`

OpenAnt 切得更细的代表文件：
- 未出现显著的 `openant_finer_partition` 文件。

整体上，V3 更稳定地保留显式父子关系；OpenAnt 更明显地区分“结构主表”和“分析纳入子集”，两者表达层次不同。

## 6. Anchor containment 对比

- 两边都覆盖：`17`
- 只有 V3 覆盖：`1`
- 只有 OpenAnt 覆盖：`0`
- 两边都没覆盖：`0`
- 由于本轮比较的是结构单元本身，anchor containment 更接近“是否存在一个可覆盖目标区域的结构单元”，而不是“最终 finding 是否会命中这里”。

## 7. Span overlap 分析

- `near_same`: `2193`
- `no_overlap`: `2965`
- `openant_contains_v3`: `5317`
- `same_boundary`: `67807`
- `v3_contains_openant`: `8918`

## 8. 典型 case deep dive

```text
case_id: PT-PY-FILE-001
观察文件: app.py
GT anchor: download_file:14-18
V3 covering unit: download_file (function, span=12)
OpenAnt covering unit: download_file (route_handler, span=12)
主要差异: category=OpenAnt anchor hit / V3 未明显命中; tighter=tie; symbol_match=tie; file_observation=comparable
可能影响: 若较小且符号更贴近 anchor 的 unit 能减少无关上下文，后续 evidence binding 可能更稳定；这只是结构层假设，不代表最终 finding 一定更好。
是否值得迁移到 V3: needs_review
迁移建议: 优先迁移可独立验证的结构机制：父子关系、函数/方法边界、module 包装策略；不要直接迁移 ranking 或 verdict 流程。
```

```text
case_id: SSTI-PY-REPO-001
观察文件: utils/template_utils.py
GT anchor: render_report_template:7-9
V3 covering unit: render_report_template (function, span=4)
OpenAnt covering unit: render_report_template (function, span=4)
主要差异: category=OpenAnt off-target archetype; tighter=tie; symbol_match=tie; file_observation=openant_tighter_spans
可能影响: 若较小且符号更贴近 anchor 的 unit 能减少无关上下文，后续 evidence binding 可能更稳定；这只是结构层假设，不代表最终 finding 一定更好。
是否值得迁移到 V3: needs_review
迁移建议: 优先迁移可独立验证的结构机制：父子关系、函数/方法边界、module 包装策略；不要直接迁移 ranking 或 verdict 流程。
```

```text
case_id: PT-PY-REPO-002
观察文件: services/file_service.py
GT anchor: _resolve_safe_path:9-18
V3 covering unit: _resolve_safe_path (method, span=10)
OpenAnt covering unit: _resolve_safe_path (method, span=10)
主要差异: category=当前系统 candidate 漂移 archetype; tighter=tie; symbol_match=tie; file_observation=openant_tighter_spans
可能影响: 若较小且符号更贴近 anchor 的 unit 能减少无关上下文，后续 evidence binding 可能更稳定；这只是结构层假设，不代表最终 finding 一定更好。
是否值得迁移到 V3: needs_review
迁移建议: 优先迁移可独立验证的结构机制：父子关系、函数/方法边界、module 包装策略；不要直接迁移 ranking 或 verdict 流程。
```

```text
case_id: SSRF-PY-REPO-CVE-2025-2828-VULN
观察文件: libs/community/langchain_community/agent_toolkits/openapi/toolkit.py
GT anchor: get_tools:45-53
V3 covering unit: get_tools (method, span=9)
OpenAnt covering unit: get_tools (method, span=9)
主要差异: category=大仓库 archetype; tighter=tie; symbol_match=tie; file_observation=openant_tighter_spans
可能影响: 若较小且符号更贴近 anchor 的 unit 能减少无关上下文，后续 evidence binding 可能更稳定；这只是结构层假设，不代表最终 finding 一定更好。
是否值得迁移到 V3: needs_review
迁移建议: 优先迁移可独立验证的结构机制：父子关系、函数/方法边界、module 包装策略；不要直接迁移 ranking 或 verdict 流程。
```

## 9. 可以吸收的 OpenAnt 经验

- 结构主表与分析纳入子集解耦：`functions.json/classes` 保留全量结构，`dataset.json` 单独记录实际纳入分析的 units。
- route / function / module 的 kind 命名更直接，有利于后续 evidence binding 与人工复核。
- class-method owner 关系即使不完整，也会在函数记录中显式保留 `class_name`，便于恢复父子关系。
- module-level unit 单独建模，有助于解释配置风险、顶层副作用与入口逻辑，但需要防止它吞掉函数级目标。

## 10. 对 V3 的修改建议

- P0: 把 file-mode case 的完整 unit 表稳定落盘；当前只在 debug / evidence 报告里看到被绑定 unit，无法复现整文件 unit partition。
- P1: 在 V3 导出里显式提供 `analysis_included` 或等价字段，区分“结构存在”与“下游工作流是否实际消费”。
- P1: 补充面向报告消费的 unit 导出接口，避免每次都回查 `run.db` 或依赖临时 repo_root。
- P2: 保留一个最小公共投影接口，专门服务后续 controlled replacement experiment，而不是直接复用 finding 结果格式。

## 11. 后续实验

本轮只能证明结构差异、anchor 覆盖与 span 紧凑度差异。
如果要证明 unit 划分对漏洞审计有效，需要后续做 controlled replacement experiment：固定 provider、candidate、verifier 与 emission policy，只替换 unit partition。

## 12. 结论边界

可以证明：

- 两套 unit 在结构上的差异。
- 哪些 anchor 被覆盖、没被覆盖，或由更大/更小的 unit 覆盖。
- 哪些文件存在更细或更粗的切分差异。
- 哪些父子关系 / kind 表达值得迁移。

不能证明：

- 哪套系统漏洞发现更强。
- 哪套系统误报更少。
- 只替换 unit 就一定能提升最终 recall。
- OpenAnt 全链路优于 V3。
- V3 只要换 unit 就能解决当前所有问题。
