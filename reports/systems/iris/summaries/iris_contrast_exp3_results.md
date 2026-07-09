# IRIS 对比诊断实验 3 结果总结

## 1. 文档定位

这份文档记录 [iris_contrast_diagnostic_plan.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_contrast_diagnostic_plan.md:1) 中实验 3 的结果。

它回答的问题是：

> `PT-JA-REPO-CVE-2024-53677-VULN` 当前为什么在 `source` 已恢复的前提下仍然 `sink=0`？

这一步只使用现有归档做静态诊断，没有新增运行。

## 2. 证据范围

主证据：

- `sink completeness` 诊断表：
  - [iris_contrast_exp3_pt_sink_diagnosis.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_contrast_exp3_pt_sink_diagnosis.tsv:1)
- Stage 3 与主查询日志：
  - [command.stdout.log](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/fetch_build/command.stdout.log:22)
- 候选与标签：
  - [candidate_apis.csv](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/local_observation/candidate_apis.csv:1)
  - [llm_labelled_sink_apis.json](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/raw_responses/llm_labelled_sink_apis.json:1)
  - [MySources.qll](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/generated_queries/myqueries/cwe-022wLLM/MySources.qll:5)
  - [MySinks.qll](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/generated_queries/myqueries/cwe-022wLLM/MySinks.qll:5)
  - [results.csv](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/iris_run/results.csv:1)
- 代码中的 file/path 暴露点：
  - [FileUploadInterceptor.java](/home/lqs/llm_audit_system_learning/datasets/real_world/PT-JA-REPO-CVE-2024-53677-VULN/repo/core/src/main/java/org/apache/struts2/interceptor/FileUploadInterceptor.java:269)
  - [UploadedFile.java](/home/lqs/llm_audit_system_learning/datasets/real_world/PT-JA-REPO-CVE-2024-53677-VULN/repo/core/src/main/java/org/apache/struts2/dispatcher/multipart/UploadedFile.java:24)
  - [StrutsUploadedFile.java](/home/lqs/llm_audit_system_learning/datasets/real_world/PT-JA-REPO-CVE-2024-53677-VULN/repo/core/src/main/java/org/apache/struts2/dispatcher/multipart/StrutsUploadedFile.java:23)
  - [FileUploadAction.java](/home/lqs/llm_audit_system_learning/datasets/real_world/PT-JA-REPO-CVE-2024-53677-VULN/repo/apps/showcase/src/main/java/org/apache/struts2/showcase/fileupload/FileUploadAction.java:69)

## 3. 先给结论

1. `PT` 的唯一主分类是：
   - `sink_not_in_candidate_set`

2. 当前 `PT` 不能再被写成 `path non-connectivity`。
   - `source` 已经恢复到 `6`
   - 但 Stage 3 根本没有拿到任何 file/path 形态的 sink 候选
   - 所以后面不存在“已有 source/sink 但路径不连”的诊断前提

3. `sink_seen_but_not_labelled` 不是主解释。
   - `llm_labelled_sink_apis.json` 为空
   - 更关键的是，候选集中本身只看到 wrapper 级上传枚举和参数装配 API，没有看到明显的 file/path 暴露点

4. `sink_labelled_but_not_materialized` 和 `sink_materialized_but_semantically_unusable` 都可以排除。
   - `MySinks.qll` 直接是 `1 = 0`
   - 这对应“没有 sink 标签进入物化”，不是“物化后不可用”

## 4. 诊断表

完整表见 [iris_contrast_exp3_pt_sink_diagnosis.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/iris_contrast_exp3_pt_sink_diagnosis.tsv:1)。

这里给出可直接阅读的核心版本：

| case | candidate_count | source_labels | sink_labels | primary_break_layer |
|---|---|---|---|---|
| `PT-JA-REPO-CVE-2024-53677-VULN` | `25` | `6` | `0` | `sink_not_in_candidate_set` |

最关键的补充判断：

- 候选集中出现的是：
  - `MultiPartRequestWrapper.getFileParameterNames`
  - `MultiPartRequestWrapper.getContentTypes`
  - `MultiPartRequestWrapper.getFileNames`
  - `MultiPartRequestWrapper.getFiles`
  - `Map.put`
- 候选集中没有出现的是：
  - `UploadedFile.getAbsolutePath`
  - `UploadedFile.getContent`
  - `StrutsUploadedFile.getAbsolutePath`
  - `StrutsUploadedFile.getContent`
  - `FileUploadAction.setUpload(File)`

## 5. 为什么主分类是 `sink_not_in_candidate_set`

### 5.1 Stage 3 已经证明问题不在 source 侧

日志显示：

- Stage 3 一共查询了 `25` 个候选
  - [command.stdout.log:22](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/fetch_build/command.stdout.log:22)
- 最终 `#Source: 6, #Sink: 0, #Taint Propagators: 5`
  - [command.stdout.log:23](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/fetch_build/command.stdout.log:23)

而 `MySources.qll` 也确实把 `getFileParameterNames`、`getContentTypes`、`getFileNames`、`getFiles` 等上传入口 API 物化成了 source：

- [MySources.qll:12](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/generated_queries/myqueries/cwe-022wLLM/MySources.qll:12)
- [MySources.qll:27](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/generated_queries/myqueries/cwe-022wLLM/MySources.qll:27)

这说明当前主问题不是“完全没看到上传相关 API”，而是“看到的层级太浅，只停在 wrapper 级入口”。

### 5.2 候选集停在 wrapper/参数装配层，没有进入 file/path 暴露层

[candidate_apis.csv](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/local_observation/candidate_apis.csv:1) 中与上传最相关的候选，主要是：

- `MultiPartRequestWrapper.getFileParameterNames`
- `MultiPartRequestWrapper.getContentTypes`
- `MultiPartRequestWrapper.getFileNames`
- `MultiPartRequestWrapper.getFiles`
- `Map.put`

见：

- [candidate_apis.csv:22](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/local_observation/candidate_apis.csv:22)
- [candidate_apis.csv:25](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/local_observation/candidate_apis.csv:25)
- [candidate_apis.csv:14](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/local_observation/candidate_apis.csv:14)

但代码里更接近 file/path 语义的点在更下游的位置：

- `FileUploadInterceptor` 先取出 `UploadedFile[] files`
  - [FileUploadInterceptor.java:283](/home/lqs/llm_audit_system_learning/datasets/real_world/PT-JA-REPO-CVE-2024-53677-VULN/repo/core/src/main/java/org/apache/struts2/interceptor/FileUploadInterceptor.java:283)
- 然后把这些对象经 `Parameter.File` 追加进参数映射
  - [FileUploadInterceptor.java:301](/home/lqs/llm_audit_system_learning/datasets/real_world/PT-JA-REPO-CVE-2024-53677-VULN/repo/core/src/main/java/org/apache/struts2/interceptor/FileUploadInterceptor.java:301)
- `UploadedFile` 接口显式暴露 `getAbsolutePath()` 和 `getContent()`
  - [UploadedFile.java:34](/home/lqs/llm_audit_system_learning/datasets/real_world/PT-JA-REPO-CVE-2024-53677-VULN/repo/core/src/main/java/org/apache/struts2/dispatcher/multipart/UploadedFile.java:34)
- `StrutsUploadedFile` 又把它们直接桥接到 `java.io.File`
  - [StrutsUploadedFile.java:52](/home/lqs/llm_audit_system_learning/datasets/real_world/PT-JA-REPO-CVE-2024-53677-VULN/repo/core/src/main/java/org/apache/struts2/dispatcher/multipart/StrutsUploadedFile.java:52)
  - [StrutsUploadedFile.java:57](/home/lqs/llm_audit_system_learning/datasets/real_world/PT-JA-REPO-CVE-2024-53677-VULN/repo/core/src/main/java/org/apache/struts2/dispatcher/multipart/StrutsUploadedFile.java:57)
- 展示 action 里还存在 `setUpload(File)` 这种直接接收 `File` 的下游点
  - [FileUploadAction.java:75](/home/lqs/llm_audit_system_learning/datasets/real_world/PT-JA-REPO-CVE-2024-53677-VULN/repo/apps/showcase/src/main/java/org/apache/struts2/showcase/fileupload/FileUploadAction.java:75)

这些更像 sink 的 file/path 暴露点都没有进入当前 candidate set。于是 Stage 3 即使恢复了 source，也没有任何足够像 sink 的对象可供标注。

## 6. 为什么不是另外 3 类

### 6.1 为什么不是 `sink_seen_but_not_labelled`

如果这是主解释，前提应是：

- 候选集中已经出现明显 sink 形态
- 但 LLM 没把它们标成 sink

当前证据不支持这个前提。`llm_labelled_sink_apis.json` 确实为空，但更关键的是候选集本身只覆盖到 `getFiles` 这种 wrapper 级入口，没有覆盖 `UploadedFile.getAbsolutePath`、`getContent` 或 `setUpload(File)` 这类更强的 file/path 暴露点。

所以“漏标”最多是次级可能性，不是主解释。

### 6.2 为什么不是 `sink_labelled_but_not_materialized`

`MySinks.qll` 直接退成：

- `1 = 0`
  - [MySinks.qll:5](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/generated_queries/myqueries/cwe-022wLLM/MySinks.qll:5)

这与：

- `llm_labelled_sink_apis.json = []`
  - [llm_labelled_sink_apis.json:1](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_SELF01/self/PT-JA-REPO-CVE-2024-53677-VULN/raw_responses/llm_labelled_sink_apis.json:1)

是一致的。当前没有“先标成 sink、再在物化阶段丢失”的证据。

### 6.3 为什么不是 `sink_materialized_but_semantically_unusable`

这类解释的前提是：

- sink 已进入 `MySinks.qll`
- 但参数位、调用形态或 query 语义不可用

而当前根本没有任何 sink 进入 `MySinks.qll`。因此这类解释可以直接排除。

## 7. 对后续实验的含义

实验 3 给出的边界很明确：

1. 这条 `PT` 线当前还没到“路径连不连”的分析层。
2. 如果后续要做能力改动，优先落点应是：
   - candidate selection 是否能把 file/path 暴露点带进 Stage 3
   - 而不是先去改 path connectivity 或 posthoc filtering
3. 在学习和评估语境下，这也说明官方线与自有线的 `PT` 差异，不能被笼统归入“LLM 随机性”。
   - 因为这里更核心的是 candidate 覆盖边界

## 8. 一句话结论

实验 3 证明：

> `PT-JA-REPO-CVE-2024-53677-VULN` 当前的主问题不是路径不连，而是 Stage 3 的 candidate set 没有把 file/path 暴露层带进来，因而应归类为 `sink_not_in_candidate_set`。
