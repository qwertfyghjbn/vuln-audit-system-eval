# IRIS v2 官方数据字典（第一版）

## 1. 文档定位

这份文档整理 `IRIS v2` 仓库中与本轮学习批次直接相关的官方数据文件，重点回答两类问题：

1. 每个文件的字段到底表示什么。
2. 这些字段对“官方 case 是否足够可信”有什么作用。

本版优先覆盖：

1. `project_info.csv`
2. `build_info.csv`
3. `fix_info.csv`
4. `iclr-2025-results/*.csv`
5. 与上面几类直接相关的辅助文件

## 2. 文件分层图

按用途可以把 `IRIS v2/data` 和 `iclr-2025-results/` 分成四层：

1. `project registry`
   - `project_info.csv`
   - 定义“这个官方 case 是什么、从哪个 repo/commit 来”
2. `build contract`
   - `build_info.csv`
   - `build_cmds.csv`
   - 定义“这个官方 case 应该怎么 build / 建库”
3. `fix anchor`
   - `fix_info.csv`
   - `fix_info_source_sink.csv`
   - `source_sink_detect.csv`
   - 定义“官方如何表达修复位置、以及部分人工 source/sink 标注”
4. `official outcome`
   - `iclr-2025-results/*.csv`
   - 定义“官方论文版 IRIS / CodeQL 在 121 个 case 上报了什么结果”

## 3. `project_info.csv`

### 3.1 作用

`project_info.csv` 是官方 case 注册表。

它至少承担了三件事：

1. 把 `project_slug` 映射到 GitHub 仓库与 commit
2. 把官方 case 映射到 `CVE / CWE`
3. 为 `fetch_one.py`、`fetch_and_build.py`、`build_codeql_dbs.py` 提供抓取源

代码证据：

1. [fetch_one.py](/tmp/iris-v2/scripts/fetch_one.py:66)
2. [build_codeql_dbs.py](/tmp/iris-v2/scripts/build_codeql_dbs.py:135)
3. [config.py](/tmp/iris-v2/src/config.py:31)

### 3.2 字段说明

| 字段 | 含义 | 本轮用途 | 观察备注 |
|---|---|---|---|
| `id` | 官方数据集中该行的顺序编号 | 一般不用作 join key | 只是行号，不适合作为稳定主键 |
| `project_slug` | 官方 case 主键，格式为 `<author>__<repo>_<CVE>_<tag>` | 选择 case、抓源码、建库、命名产物 | 本轮最稳的 join key |
| `cve_id` | 对应 CVE 编号 | 和结果表、fix 信息对照 | 部分 case 只有同一个 `CVE`，但不同 `tag` |
| `cwe_id` | 对应 CWE 编号 | 选择 query、统计覆盖面 | 编码不完全统一，存在 `CWE-022` 与 `CWE-22`、`CWE-079` 与 `CWE-79` |
| `cwe_name` | CWE 英文名称 | 人读解释 | 主要用于结果注释 |
| `github_username` | GitHub owner / org | 还原仓库来源 | 与结果 CSV 的 `Author` 不总是完全一致 |
| `github_repository_name` | GitHub repo 名 | 还原仓库来源 | 与结果 CSV 的 `Package ` 不总是完全一致 |
| `github_tag` | 官方 case 对应版本标签 | 结果表 join、版本说明 | 是 join 结果表的重要组成部分 |
| `github_url` | 上游 repo URL | 拉取源码 | `fetch_one.py` 直接用它 clone |
| `advisory_id` | GHSA 或类似公告编号 | 辅助定位公告 | 对运行链不是硬依赖 |
| `buggy_commit_id` | 官方拉取的漏洞 commit | 拉取漏洞快照 | `fetch_one.py` 用它 checkout |
| `fix_commit_ids` | 修复 commit 列表，分号分隔 | 判断修复链、对照 fix 信息 | 是列表，不是单值；需要按 `;` 拆分 |

### 3.3 当前可信度备注

1. 该文件共有 `213` 行，对应 `213` 个官方项目条目。
2. `cwe_id` 编码存在零填充不一致问题：
   - `CWE-022` 与 `CWE-22`
   - `CWE-079` 与 `CWE-79`
3. 这意味着本地若按字符串精确过滤 `CWE`，需要先做规范化。

## 4. `build_info.csv`

### 4.1 作用

`build_info.csv` 是官方构建契约表。

它告诉 `IRIS`：

1. 该项目理论上是否能 build
2. 需要什么 `JDK`
3. 需要什么 `Maven` / `Gradle`
4. 是否优先使用 `gradlew`

代码证据：

1. README 与 native setup 文档都直接引用该文件说明 JDK / Maven 版本
   - [README.md](/tmp/iris-v2/README.md:77)
2. `build_one.py` 会先查本地 build info，再查全局 `build_info.csv`
   - [build_one.py](/tmp/iris-v2/scripts/build_one.py:418)
3. `build_codeql_dbs.py` 会基于该文件配置 `JAVA_HOME` 与工具链
   - [build_codeql_dbs.py](/tmp/iris-v2/scripts/build_codeql_dbs.py:22)

### 4.2 字段说明

| 字段 | 含义 | 本轮用途 | 观察备注 |
|---|---|---|---|
| `project_slug` | 对应项目主键 | 与 `project_info.csv`、结果归档 join | 主键 |
| `status` | 官方 build 结果或构建状态备注 | case 选择时优先选 `success` | 这是自由文本，不是严格枚举 |
| `jdk_version` | 官方建议的 JDK 主版本 | 配置 `JAVA_HOME` | 如 `8`、`17` |
| `mvn_version` | 官方建议的 Maven 版本 | 配置 `PATH` / Maven | 空字符串通常表示“不用 Maven” |
| `gradle_version` | 官方建议的 Gradle 版本 | 配置 `PATH` / Gradle | 空字符串通常表示“不用 Gradle” |
| `use_gradlew` | 是否优先使用项目内 `gradlew` | 解释官方构建方式 | CSV 中是字符串 `True/False`，不是布尔 |

### 4.3 当前可信度备注

1. 该文件共有 `213` 行。
2. `status` 不是严格布尔，而是人工文本。
3. 当前观测到的状态值包括：
   - `success`：`201`
   - `failure (Ant)`：`5`
   - `failure (Cannot build entire repo; contains several seperate projects)`：`2`
   - `success (Kotlin)`：`2`
   - 以及少量其他失败文本
4. 因此，本地在选“低成本可信 case”时，不能只查 `status != failure`，而要优先查严格的 `success`。

## 5. `build_cmds.csv`

### 5.1 作用

`build_cmds.csv` 是官方对默认 CodeQL build 路径的覆盖表。

当某些项目不能靠默认 `codeql database create --language java` 自动推断时，官方会在这里给出自定义 build 命令。

代码证据：

1. [build_codeql_dbs.py](/tmp/iris-v2/scripts/build_codeql_dbs.py:13)

### 5.2 字段说明

| 字段 | 含义 | 本轮用途 | 观察备注 |
|---|---|---|---|
| `project_slug` | 项目主键 | 判断是否存在特殊 build 路径 | 主键 |
| `build_cmd` | 官方要求的自定义 build 命令 | 解释为什么官方 DB 能建、而本地默认命令可能失败 | 覆盖默认 build 路径 |

### 5.3 当前可信度备注

1. 这个文件不是每个项目都有记录。
2. 若某 case 命中该文件，本地复现时必须显式保留这条 build contract，否则“官方 case 不可信”的结论不成立。

## 6. `fix_info.csv`

### 6.1 作用

`fix_info.csv` 是官方修复锚点表。

它表达的是：

1. 修复 commit 是哪一个
2. 修复发生在什么文件 / 类 / 方法
3. 官方认为哪个方法与漏洞修复最相关

它不是最终的 ground truth 路径文件，但它是 `IRIS` 官方数据层里最接近“修复定位锚点”的表。

代码证据：

1. `src/config.py` 直接把它配置为 `ALL_METHOD_INFO_DIR`
   - [config.py](/tmp/iris-v2/src/config.py:24)

### 6.2 字段说明

| 字段 | 含义 | 本轮用途 | 观察备注 |
|---|---|---|---|
| `project_slug` | 项目主键 | 与 `project_info.csv` join | 主键 |
| `cve_id` | CVE 编号 | 辅助校验 | 与 `project_info.csv` 对照 |
| `github_username` | GitHub owner | 人读来源校验 | 可能与结果 CSV author 命名风格不完全一致 |
| `github_repository_name` | GitHub repo 名 | 人读来源校验 | 同上 |
| `commit` | 修复 commit | 与 `fix_commit_ids`、patch 对照 | 通常应属于 `fix_commit_ids` 集合 |
| `file` | 修复文件路径 | 定位修复点 | 文件级锚点 |
| `class` | 修复所在类名 | 类级锚点 | 可能为空或泛化 |
| `class_start` | 类起始行号 | 人读定位 | 行号是字符串 |
| `class_end` | 类结束行号 | 人读定位 | 行号是字符串 |
| `method` | 修复方法名 | 方法级锚点 | 有些 case 只到类，不一定有精确方法 |
| `method_start` | 方法起始行号 | 方法级定位 | 可能为空 |
| `method_end` | 方法结束行号 | 方法级定位 | 可能为空 |
| `signature` | 方法签名 | 稳定识别方法 | 是对方法名的重要补充 |
| `""` | 空列 | 无正式语义 | 说明 CSV 导出里残留了尾随分隔列 |

### 6.3 当前可信度备注

1. `fix_info.csv` 的最后一列是空列，不应当成有效字段使用。
2. `method_start / method_end` 不是每条都有值。
3. 因此本地若把它当成严格方法锚点，会过度自信；更合理的用法是：
   - 优先当文件 / 类 / 方法多级修复参考
   - 不把空方法行号 case 误当成“数据坏了”

## 7. `fix_info_source_sink.csv`

### 7.1 作用

这不是本轮主问题要求的核心文件，但它和 `fix_info.csv` 强相关，且对“官方 case 是否足够可信”很重要。

它看起来是：

1. 一批人工整理过的 source/sink 标注
2. 以 `fix_info` 的文件 / 方法锚点为载体
3. 额外加入人工 `Source / Sink / CodeQL Format / Check` 字段

### 7.2 字段说明（增量部分）

除 `fix_info.csv` 共有字段外，新增字段可理解为：

| 字段 | 含义 | 观察备注 |
|---|---|---|
| `Done` | 该条人工标注是否完成 | 通常为 `1` |
| `Link` | 指向上游源码的 commit URL | 人读校验用 |
| `Source` | 人工 source 描述 | 可能是变量、参数或表达式 |
| `Source Line` | source 所在行 | 字符串行号 |
| `Sink` | 人工 sink 描述 | 可能是调用或返回点 |
| `Sink Line` | sink 所在行 | 字符串行号 |
| `Source CodeQl  Format` | source 的 CodeQL 风格描述 | 可转成模型或规则输入 |
| `Sink CodeQl Format` | sink 的 CodeQL 风格描述 | 同上 |
| `Check` | 当前记录是否通过检查 | 文本布尔，示例中为 `True` |

### 7.3 当前可信度备注

1. 这是人工增强数据，不应和 `fix_info.csv` 混用成同一个层级的“官方基础注册表”。
2. 若后续要用它，只能作为“人工 source/sink 辅助资产”单独引用。

## 8. `source_sink_detect.csv`

### 8.1 作用

这也是 `fix_info` 近邻文件，用于记录某条修复锚点是否被判定“找到了 source / sink”。

从列结构看，它更像一个派生统计表，而不是基础注册表。

### 8.2 字段说明（增量部分）

| 字段 | 含义 | 观察备注 |
|---|---|---|
| `Found Source` | 是否检测到 source | 文本布尔 |
| `Found Sink` | 是否检测到 sink | 文本布尔 |
| `class_length` | 类体长度 | 用于粗略统计粒度 |
| `Found-Source` | 与 `Found Source` 含义接近的重复列 | 存在重复命名风格 |
| `Found-Sink` | 与 `Found Sink` 含义接近的重复列 | 存在重复命名风格 |

### 8.3 当前可信度备注

1. 该文件内部存在语义重复列，说明它更像中间产物导出。
2. 不建议把它当作第一层 truth source，只适合做辅助诊断。

## 9. `iclr-2025-results/*.csv`

### 9.1 作用

`iclr-2025-results/` 是官方论文结果摘要目录。

它不是全量 `213` case，而是 `121` 个论文版 case 的结果快照。

当前目录下至少包括：

1. `IRIS+GPT-4.csv`
2. `CodeQL.csv`
3. 以及其他模型 CSV

文档证据：

1. [results.md](/tmp/iris-v2/docs/architecture/results.md:1)

### 9.2 字段说明

| 字段 | 含义 | 本轮用途 | 观察备注 |
|---|---|---|---|
| `CWE ID` | 结果所属 CWE | 按漏洞类型筛选结果 | 与 `project_info.csv` 一样，可能有编码风格差异 |
| `CVE` | CVE 编号 | 与 `project_info.csv` join | 不是单独稳定主键 |
| `Author` | 上游项目 owner / author | join 结果表 | 与 `github_username` 命名风格不总一致 |
| `Package ` | 项目名 | join 结果表 | 列名尾部真的带空格 |
| `Tag` | 版本标签 | join 结果表 | 与 `github_tag` 对照 |
| `Recall` | 该 case 是否命中官方目标 | 本轮最关键的结果字段 | 当前值看起来是 `0/1` 二值 |
| `Alerts` | 告警数 | 比较噪声与召回差异 | 不等于 target hit 数 |
| `Paths` | 路径数 | 比较结果规模 | 不等于 TP path 数 |
| `TP Alerts` | true-positive alerts 数 | 比较有效命中 | 只在部分结果中非零 |
| `TP Paths` | true-positive paths 数 | 比较有效路径命中 | 只在部分结果中非零 |
| `Precision` | 精确率 | 论文结果摘要 | 可能是 `0`、`1`、小数、`N/A` |
| `F1` | F1 分数 | 论文结果摘要 | 可能是 `0`、`1`、小数、`N/A` |

### 9.3 当前可信度备注

1. 每个结果 CSV 当前是 `121` 行，不是 `213` 行。
2. 这意味着：
   - 结果目录代表的是论文评估子集
   - 不是整个 `CWE-Bench-Java` 的全量结果
3. 结果行不能稳定直接映射到 `project_slug`：
   - 当前按 `(CVE, Author, Package, Tag)` 粗 join，会有 `17` 行映射不上
4. 典型原因包括：
   - `Author` 命名不同，如 `asf` vs `apache`
   - `Package` 命名不同，如 `hapi-fhir` vs 仓库内更具体的 slug 组成
   - `Tag` 细节不完全一致
5. 因此，本地若要做自动对照，必须先做命名归一化或人工映射。

### 9.4 本轮 5 个官方 case 的 join 状态

对本轮已经冻结的 5 个官方 case，可以直接使用精确 join：

- join key：
  - `(CVE, Author, Package, Tag)`
- result files：
  - `IRIS+GPT-4.csv`
  - `CodeQL.csv`

已冻结的 join 映射见：

- [official_results_join_map.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/official_results_join_map.tsv:1)

这意味着：

1. 本轮 5 个官方 case 不需要先做人名 / 包名归一化
2. 但不能把这种“精确 join 可行”错误推广到全部 `121` 行结果

## 10. Query 选择映射

虽然 query 映射不属于严格意义上的“数据文件”，但它是把 case 选择表真正变成可执行命令的必要一层。

本轮冻结 case 的 query id 如下：

| CWE | query id | 说明 |
|---|---|---|
| `CWE-022` | `cwe-022wLLM` | Path Traversal / Zip Slip |
| `CWE-079` | `cwe-079wLLM` | XSS |
| `CWE-094` | `cwe-094wLLM` | Code Injection |
| `CWE-918` | `cwe-918wLLM` | SSRF |

代码证据：

1. [queries.py: cwe-022](/tmp/iris-v2/src/queries.py:99)
2. [queries.py: cwe-079](/tmp/iris-v2/src/queries.py:290)
3. [queries.py: cwe-094](/tmp/iris-v2/src/queries.py:443)
4. [queries.py: cwe-918](/tmp/iris-v2/src/queries.py:535)

### 10.1 当前值得注意的 query 元数据异常

当前 `queries.py` 里至少有两个会影响解释的异常：

1. `cwe-079wLLM`
   - `cwe_id_tag` 用的是 `CWE-79`
   - prompt 内字段名是 `cwe-id`
2. `cwe-094wLLM`
   - prompt 中的 `cwe-id` 当前写成了 `CWE-079`

这不直接等于“IRIS 一定失效”，但它是本轮在解释 `CWE-094` 表现时必须记账的运行风险。

## 11. `IRIS_docker_build_durations.csv`

### 10.1 作用

该文件记录官方 Docker build 的耗时观测。

它不直接参与 `IRIS` 主流程，但对本轮“挑低成本可信 case”很有价值。

### 10.2 字段说明

| 字段 | 含义 | 观察备注 |
|---|---|---|
| `project-slug` | 项目主键 | 这里用的是连字符命名，不是 `project_slug` |
| `start-timestamp` | Docker build 开始时间 | 时间格式是人工时间串 |
| `end-timestamp` | Docker build 结束时间 | 同上 |
| `duration-seconds` | Docker build 秒数 | 浮点数 |
| `duration-minutes` | Docker build 分钟数 | 浮点数 |

### 10.3 当前可信度备注

1. 列命名风格与其他 CSV 不统一。
2. 它更适合作为构建成本旁证，不适合作为主 join 表。

## 12. 可直接驱动 case 选择的表

截至当前，以下三张表已经可以直接驱动本轮 case 选择：

1. [official_case_trustworthiness_shortlist.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/official_case_trustworthiness_shortlist.tsv:1)
2. [self_case_trustworthiness_shortlist.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/self_case_trustworthiness_shortlist.tsv:1)
3. [official_results_join_map.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/official_results_join_map.tsv:1)

它们各自承担：

1. `official_case_trustworthiness_shortlist.tsv`
   - 冻结官方 5 case
   - 绑定 `role / project_slug / query_id / build_info / 官方 recall`
2. `self_case_trustworthiness_shortlist.tsv`
   - 冻结自有对照组
   - 绑定 `case_id / query_id / 输入契约状态 / 对照目标`
3. `official_results_join_map.tsv`
   - 把官方结果 CSV 的 5 行精确映射到本轮 5 个官方 `project_slug`

## 13. 可直接驱动结果 join 的操作规则

### 13.1 官方 case

对本轮 5 个官方 case，推荐 join 步骤：

1. 从 `official_case_trustworthiness_shortlist.tsv` 读取 `project_slug`
2. 用 `project_info.csv` 取：
   - `cve_id`
   - `github_username`
   - `github_repository_name`
   - `github_tag`
3. 按 `(CVE, Author, Package, Tag)` 到：
   - `IRIS+GPT-4.csv`
   - `CodeQL.csv`
   做精确匹配
4. 用 `official_results_join_map.tsv` 验证匹配是否落在预期行

### 13.2 自有 case

自有 case 不与 `iclr-2025-results/*.csv` 直接 join。

推荐做法：

1. 先从 `self_case_trustworthiness_shortlist.tsv` 读取：
   - `case_id`
   - `query_id`
   - `compare_target`
2. 再按 `compare_target` 选择最接近的官方 case 作为人工对照锚点
3. 比较：
   - build contract
   - candidate coverage
   - source / sink / propagator 结构
   - final `results.csv`

## 14. 当前对本轮实验最重要的结论

截至当前，这份字典已经能支撑本轮 case 选择与可信度判断的几个关键动作：

1. 选官方 case 时，优先使用：
   - `project_info.csv`
   - `build_info.csv`
   - `iclr-2025-results/*.csv`
2. 判断官方 case 是否“容易成功”时，需要同时看：
   - `build_info.csv`
   - `build_cmds.csv`
   - `fix_info.csv`
3. 对照官方结果时，不能假设 `IRIS+GPT-4.csv` 能直接无损 join 到 `project_slug`
4. 对自有 case 与官方 case 的可信度比较里，最应该警惕的不是单个分数字段，而是：
   - 命名映射误差
   - 构建契约完整度差异
   - 修复锚点粒度差异
   - 结果子集并非全量 `213` case
