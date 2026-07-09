# IRIS Candidate-Selection Baseline 诊断总结

## 1. 文档定位

这份总结只记录 `candidate-selection` 验证线的 baseline 阶段，不包含任何能力改动。

baseline 运行：

- `smoke_run_id = OFFICIALSMOKE01`
- `diagnostic_run_id = BASELINE_CANDSEL_DIAG01`

原始产物：

- [artifacts/iris_candidate_validation/BASELINE_CANDSEL_DIAG01/summary.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_candidate_validation/BASELINE_CANDSEL_DIAG01/summary.tsv:1)
- [artifacts/iris_candidate_validation/BASELINE_CANDSEL_DIAG01/README.md](/home/lqs/llm_audit_system_learning/artifacts/iris_candidate_validation/BASELINE_CANDSEL_DIAG01/README.md:1)

## 2. 核心发现

### 2.1 三个代表性 case 全部出现高 candidate-selection 风险

`summary.tsv` 显示：

- `PT-JA-REPO-CVE-2024-53677-VULN`
  - `raw_unique_apis = 80`
  - `internal_unique_apis = 56`
  - `candidate_apis = 19`
  - `llm_sources = 0`
  - `interesting_internal_count = 16`

- `SSRF-JA-REPO-CVE-2023-3432-VULN`
  - `raw_unique_apis = 113`
  - `internal_unique_apis = 41`
  - `candidate_apis = 71`
  - `llm_sources = 0`
  - `interesting_internal_count = 21`

- `SSRF-JA-REPO-CVE-2023-3432-FIXED`
  - `raw_unique_apis = 114`
  - `internal_unique_apis = 41`
  - `candidate_apis = 72`
  - `llm_sources = 0`
  - `interesting_internal_count = 21`

这说明“存在关键内部包装 API 被挡掉”不是单一 case 的偶发现象，而是跨 `PT` / `SSRF` 的稳定症状。

### 2.2 `PT` case 里，Stage 3 看不到最像 source 的 multipart 包装 API

`PT-JA-REPO-CVE-2024-53677-VULN` 的 Stage 3 候选样本主要是：

- `java.lang.String.split`
- `java.util.Arrays.asList`
- `java.util.Enumeration.nextElement`
- `java.util.ArrayList<UploadedFile>(int)`

而被 internal/external 边界挡掉的关键内部 API 包括：

- `ActionContext.getServletRequest`
- `MultiPartRequestWrapper.getFileParameterNames`
- `MultiPartRequestWrapper.getContentTypes`
- `MultiPartRequestWrapper.getFileNames`
- `MultiPartRequestWrapper.getFiles`
- `ActionContext.getParameters`

这意味着当前 `PT` case 的 Stage 3 候选集合已经偏离真正的输入边界。

### 2.3 `SSRF` case 里，Stage 3 看不到核心 `SURL` 包装层

`SSRF-3432` 的 Stage 3 候选主要保留了：

- `java.net.URL.openConnection`
- `java.net.URL(String)`
- `java.net.URLConnection.getInputStream`
- `java.net.HttpURLConnection.getResponseCode`

但被 internal/external 边界挡掉的关键内部 API 包括：

- `SURL.create(URL)`
- `SURL.removeUserInfo(URL)`
- `SURL.getBytes()`
- `SURL.isInUrlAllowList()`
- `SURL.forbiddenURL(String)`
- `SURL.requestWithGetAndResponse(...)`
- `SURL.requestWithPostAndResponse(...)`

这说明当前 `SSRF` 的 Stage 3 看到的是 JDK 网络原语，而不是项目内部真正承接风险语义的包装层。

### 2.4 `VULN / FIXED` 在 baseline 上共享同一类 source 缺失症状

`SSRF-JA-REPO-CVE-2023-3432-VULN` 与 `SSRF-JA-REPO-CVE-2023-3432-FIXED` 在 baseline 上都表现为：

- `llm_sources = 0`
- `llm_sinks = 6`
- `llm_taint_propagators = 16`

这说明当前阶段还不能用 `VULN / FIXED` 差异来解释 source 缺失；首先要验证的是候选边界本身。

## 3. 当前结论

截至当前，baseline 证据已经足以支持以下判断：

1. `source` 缺失不是“Stage 3 完全没跑起来”。
2. `source` 缺失也不只是某个单独 case 的 prompt 波动。
3. 当前最值得优先验证的变量是 `candidate-selection`，尤其是 internal wrapper API 是否应进入 Stage 3。

## 4. 建议的下一步

下一步应进入最小能力变体：

- `variant_id = iris-capability-candsel-001`

并只做一件事：

- 放宽一小类 internal wrapper API 的保留条件

在这之前，不建议先动 prompt 或 ranking，因为 baseline 还没有证明那是更主要的瓶颈。
