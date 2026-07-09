# IRIS 官方线 vs 自有线分叉层总判断

## 1. 文档定位

这份文档把 `Contrast Diagnostic Batch` 的实验 1/2/3 合并为一个批次级判断。

它回答的问题是：

> 在当前冻结运行边界下，`OFFICIALSMOKE01` 与 `DEEPSEEK_SELF01` 的主要分叉层究竟在哪里；这些分叉是否能被归结为单一原因？

这不是新运行结果，也不是能力改动报告。

## 2. 证据来源

本结论只汇总以下 3 份已完成结果：

- [iris_contrast_exp1_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_exp1_results.md:1)
- [iris_contrast_exp2_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_exp2_results.md:1)
- [iris_contrast_exp3_results.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_exp3_results.md:1)

配套结果表：

- [iris_contrast_exp1_matrix.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_contrast_exp1_matrix.tsv:1)
- [iris_contrast_exp2_pair_diagnosis.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_contrast_exp2_pair_diagnosis.tsv:1)
- [iris_contrast_exp3_pt_sink_diagnosis.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_contrast_exp3_pt_sink_diagnosis.tsv:1)

## 3. 总结论

1. 官方线 vs 自有线不存在一个统一的单一分叉层。
   - `PT` 与 `SSRF` 断在不同层
   - 不能再用“都是 LLM 不稳定”或“都是 path 不连”来统一概括

2. `PT` 的主分叉层在 `sink completeness`，更具体地说是：
   - `sink_not_in_candidate_set`

3. `SSRF vuln/fixed` 的主分叉层在 `path connectivity` 内部，更具体地说是：
   - `query_semantics_mismatch`

4. `shared cache` 与 `Stage 3 parse noise` 都是真实现象，但都不是这批对照中的主解释。

5. 因此，后续若进入能力改动，至少应拆成两条线：
   - `PT`：看 candidate selection 是否能把 file/path 暴露层带进 Stage 3
   - `SSRF`：看 source-side query semantics 是否能对准真实请求路径

## 4. 分叉层地图

| case family | official vs self 的批次级主分叉层 | 已完成的细化诊断 | 当前最稳的主判断 |
|---|---|---|---|
| `PT-JA-REPO-CVE-2024-53677` | `sink_completeness_layer` | 实验 3 | `sink_not_in_candidate_set` |
| `SSRF-JA-REPO-CVE-2023-3432-VULN` | `path_connectivity_layer` | 实验 2 | `query_semantics_mismatch` |
| `SSRF-JA-REPO-CVE-2023-3432-FIXED` | `path_connectivity_layer` | 实验 2 | `query_semantics_mismatch` |

这张表意味着：

- `PT` 与 `SSRF` 已经被明确分流
- `SSRF vuln` 与 `SSRF fixed` 也被证明是同层断裂，而不是两个互不相干的问题

## 5. 按漏洞家族看的总判断

### 5.1 PT 线

实验 1 先证明：

- 自有线把 `source` 从 `0` 恢复到 `6`
- 但官方线与自有线都还是 `sink=0`
- 所以主问题不是 path，而是 `sink completeness`

实验 3 再把这个层级收紧到：

- `sink_not_in_candidate_set`

也就是说，`PT` 线当前最核心的事实不是“LLM 看到了 sink 却没标”，而是：

- Stage 3 候选集只到 `MultiPartRequestWrapper.getFiles` / `Map.put` 这一层
- 没把 `UploadedFile.getAbsolutePath`、`getContent`、`setUpload(File)` 这类更像 file/path 暴露点的方法带进来

因此 `PT` 线的官方 vs 自有分叉，本质上更接近：

- candidate coverage boundary 的差异

而不是：

- path connectivity 差异
- 单纯的随机响应波动

### 5.2 SSRF 线

实验 1 先证明：

- 自有线两条 `SSRF` 都已经有 sink
- `paths` 仍然是 `0`
- 所以值得进入 `path non-connectivity diagnosis`

实验 2 再证明：

- `VULN` 与 `FIXED` 的主断点层相同
- 两者都应归到 `query_semantics_mismatch`

更具体地说：

1. `VULN`
   - 不是完全没有 source
   - 但唯一 source 落在 `System.getenv` 这一错误语义片段

2. `FIXED`
   - source 侧直接为空
   - 但 sink 与 summary 仍保留了主要请求路径

因此 `SSRF` 线的官方 vs 自有分叉，本质上更接近：

- source-side query semantics 没有对准真实 request-origin path

而不是：

- sink 不足
- summary edge 大面积缺失
- posthoc 阶段把已有 path 过滤掉

## 6. 哪些现象是次级差异

这批实验已经能把几个容易混淆的现象降级为“次级差异”：

1. `shared cache`
   - 只在 `official SSRF fixed` 上出现
   - 需要记录
   - 但不足以解释为什么两侧都还是 `0 paths`

2. `Stage 3 parse noise`
   - 只在自有 `SSRF` 两条上出现
   - 需要记录
   - 但不是当前主断点层

3. `partial sink materialization`
   - 在 `SSRF` 上真实存在
   - 但保留下来的 sink 已覆盖主请求路径
   - 所以不是当前最主导的失败解释

## 7. 对“官方线可信性”的含义

这 3 个实验合起来，能支持一个比“官方不可信”或“官方可信”更精确的判断：

1. 官方线与自有线的差异不能被压缩成单一原因。
2. 至少在这 `3 对 3` 视图里，官方线并没有提供一个稳定、统一、可直接外推的成功机制。
3. 如果后续要拿官方线当学习对象，必须按失败层拆开看：
   - `PT` 学 candidate boundary
   - `SSRF` 学 source-side query semantics
4. 如果后续要拿官方线当对照系统，也不能只看最终 `recall` 或 `results.csv`，而要同时看：
   - candidate 数量
   - source/sink/tp 标签结构
   - query 物化结果
   - 是否存在缓存或解析噪声

## 8. 对后续工作的直接指向

如果下一步继续做学习性能力改动，最值得优先进入的不是“泛泛继续修 IRIS”，而是两个明确落点：

1. `PT`：
   - candidate selection / API lifting
   - 目标是把 file/path 暴露层带进 Stage 3

2. `SSRF`：
   - source-side query semantics
   - 目标是让 source 对准真实 request-origin 到 network sink 的路径

如果下一步继续做评估而不是改系统，也应保持同样分流：

- `PT` 不要再误归到 `path non-connectivity`
- `SSRF` 不要再误归到 `sink completeness`

## 9. 一句话结论

这批实验的总判断是：

> 官方线 vs 自有线没有单一统一的分叉层；`PT` 主要分叉在 `sink completeness`，并已收紧到 `sink_not_in_candidate_set`，而 `SSRF vuln/fixed` 主要分叉在 `path connectivity` 内部，并已收紧到 `query_semantics_mismatch`。
