# IRIS 官方 Case 可信度对照学习批次规划

## 1. 文档定位

这份文档定义 `IRIS` 的下一轮主实验：

> `DeepSeek` 驱动下的 `IRIS` 官方 case 与自有 case 可信度对照学习批次

它仍然属于 `Learning Run`，不是 `Diagnostic Evaluation`，也不是能力改动实验。

这轮实验的目标不是复现官方 `IRIS+GPT-4` 分数，而是回答三个更基础的问题：

1. 在同一套 `DeepSeek + IRIS` 运行链下，官方 `IRIS v2` case 与自有 case 的表现差异主要落在哪里。
2. 官方高价值 case 的结论是否足够可信，还是明显依赖：
   - 特定官方 case 选择
   - 特定 build / database 条件
   - 特定 Stage 3 标签行为
   - 特定模型兼容性
3. 当前 `PT / SSRF` 问题与官方成功 case 相比，差异主要落在：
   - 官方资产链
   - build / database
   - Stage 3 标签行为
   - 最终 query 生成

## 2. 已冻结决策

这轮批次已经固定以下边界：

1. 批次身份：
   - `Learning Run`
   - 不称为 `Diagnostic Evaluation`
2. case 来源：
   - 只允许 `Official Asset-Chain Case`
   - 不混入本仓库自定义或改写 case
3. 执行边界：
   - 主线使用 upstream 未改动 `IRIS`
   - 默认使用 upstream native 原生命令链
   - 主线不使用能力改动版 `IRIS`
   - 允许使用 `iris-runtime-compat-001` 作为最小运行兼容层
   - 不使用自定义 wrapper 作为默认主路径
   - `--use-container` 仅作为官方文档明确支持时的单独分支记录
4. case 组织方式：
   - 对官方 case 使用 `Case Role`
   - 固定为 `anchor / contrast / differential / differential / control`
   - 自有 case 作为独立对照组，不混入官方 role 配额
5. 证据保存边界：
   - 每个 case 必须保存统一的 `Reproduction Evidence Package`
6. 模型边界：
   - 当前主模型固定为 `DeepSeek`
   - 本轮结论不表述为“官方 `GPT-4` 结果复现”

## 3. 非目标

这轮批次明确不做以下事情：

1. 不修补 `IRIS` 的 prompt、candidate selection、source/sink 语义、ranking、post-processing
2. 不把 `DeepSeek` 结果写成“官方 `IRIS+GPT-4` 结果复现”
3. 不把本地 benchmark 适配层 case 混入“官方 case 观察”结论
4. 不直接扩大成 `10-15` case 的诊断评估
5. 不把本轮结果写成“IRIS 总体能力画像”

## 4. 工作分解

### 4.1 工作包 A：官方数据字典

需要在 `IRIS v2` 仓库中梳理并落文：

1. `CWE-Bench-Java` 相关数据文件
2. `build_info.csv`
3. `project_info.csv`
4. `fix_info.csv`
5. `iclr-2025-results/*.csv`

每份文件至少说明：

1. 字段名
2. 字段含义
3. 与 case 选择或复现判断的关系
4. 已观察到的脏点或特殊值
   - 例如 `None`
   - 例如 `N/A`
   - 例如官方结果行能否稳定映射到 `project_slug`
5. 该字段对“官方 case 可信度判断”有什么作用

### 4.2 工作包 B：冻结 5 个官方 case

#### 角色法

本轮不按“题型配额”选 case，而按信息增益选 case：

1. `anchor`
   - 验证 upstream quickstart 命令链本身
2. `contrast`
   - 验证 quickstart 的成功是否只是单 case 特例
3. `differential-1`
   - 选择官方 `IRIS+GPT-4 recall=1 / CodeQL recall=0` 的增益位
   - 观察它在 `DeepSeek + IRIS` 下是否仍然显著优于自有问题 case
4. `differential-2`
   - 再选一个不同 CWE 的低成本增益位，避免只看 `CWE-022`
5. `control`
   - 选一个官方 `IRIS+GPT-4 recall=1 / CodeQL recall=1` 的非 PT 成功 case
   - 用来判断“连官方成功线都表现异常”时，问题更可能在环境、模型兼容或运行链

### 4.3 工作包 C：冻结自有对照 case

除了 5 个官方 case，还需要冻结一组自有对照 case。

自有 case 的作用不是参与“官方资产链复现”，而是回答：

1. `DeepSeek + IRIS` 在自有 case 上为什么表现更差或更不同
2. 官方 case 是否对 `IRIS` 更友好
3. 官方 case 的 build / slice / metadata 是否更有利于形成正结果

自有 case 建议至少覆盖：

1. 当前已知问题最突出的 `PT`
2. 当前已知问题最突出的 `SSRF`
3. 若预算允许，再补一个非 `PT/SSRF` 的自有 repo-level case

自有 case 组必须单独标注，不得写成 `Official Asset-Chain Case`。

当前冻结清单见：

- [iris_self_comparison_case_list.md](/home/lqs/llm_audit_system_learning/reports/systems/iris/summaries/iris_self_comparison_case_list.md:1)
- [../registries/self_case_trustworthiness_shortlist.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/self_case_trustworthiness_shortlist.tsv:1)

本轮默认主对照组固定为：

1. `PT-JA-REPO-CVE-2024-53677-VULN`
2. `SSRF-JA-REPO-CVE-2023-3432-VULN`
3. `SSRF-JA-REPO-CVE-2023-3432-FIXED`

当前不纳入第一轮主对照组，但保留为后续边界诊断预备样本：

1. `PT-JA-REPO-CVE-2024-53677-FIXED`

#### 推荐冻结 shortlist

对应机器可读表：

- [../registries/official_case_trustworthiness_shortlist.tsv](/home/lqs/llm_audit_system_learning/reports/systems/iris/registries/official_case_trustworthiness_shortlist.tsv:1)

首选 5 个 case 如下：

| 角色 | project_slug | CWE | 官方结果定位 | 选择理由 |
|---|---|---|---|---|
| `anchor` | `perwendel__spark_CVE-2018-9159_2.7.1` | `CWE-022` | quickstart；`GPT-4=1`，`CodeQL=1` | 官方 README/quickstart 直接点名；JDK8 + Maven 3.5.0；低成本 |
| `contrast` | `perwendel__spark_CVE-2016-9177_2.5.1` | `CWE-022` | `GPT-4=1`，`CodeQL=1` | 同 repo、同构建栈、不同 CVE；适合判断 quickstart 是否是特例 |
| `differential-1` | `vert-x3__vertx-web_CVE-2018-12542_3.5.3.CR1` | `CWE-022` | `GPT-4=1`，`CodeQL=0` | 官方 PT 增益位；JDK8 + Maven 3.5.0；低告警量 |
| `differential-2` | `jmrozanec__cron-utils_CVE-2021-41269_9.1.5` | `CWE-094` | `GPT-4=1`，`CodeQL=0` | 非 PT 的低成本差异样本；JDK8 + Maven 3.5.0；告警量低 |
| `control` | `rhuss__jolokia_CVE-2018-1000129_1.4.0` | `CWE-079` | `GPT-4=1`，`CodeQL=1` | 非 PT 官方成功线；JDK8 + Maven 3.5.0；`fix_info` 完整 |

#### 备选 case

若首选 case 因 fetch / build / DB 明显过重或官方资产异常而被替换，优先考虑：

1. `codehaus-plexus__plexus-archiver_CVE-2018-1002200_3.5`
   - 可替换 `differential-1`
2. `codehaus-plexus__plexus-utils_CVE-2017-1000487_3.0.15`
   - 可替换 `differential-2`
3. `undertow-io__undertow_CVE-2014-7816_1.0.16.Final`
   - 可替换 `control`

替换规则：

1. 只能在同一 `Case Role` 内替换
2. 替换原因必须写入批次 runbook
3. 替换后仍需满足 `Official Asset-Chain Case`

### 4.4 工作包 D：对每个 case 运行 upstream 原生命令链

默认命令链固定为：

```bash
python scripts/fetch_and_build.py --filter <project_slug>
python scripts/build_codeql_dbs.py --project <project_slug>
python src/iris.py --query <query_id> --run-id <run_id> --llm <recorded_deepseek_alias> <project_slug>
```

执行约束：

1. 默认 native
2. 默认不改 upstream 代码
3. 默认不引入本仓库自定义 clean-input / wrapper 脚本
4. 若必须走 `--use-container`：
   - 视为同一 case 的第二执行分支
   - 不覆盖 native 结论
5. 若某 case 只能在 `iris-runtime-compat-001` 下稳定执行：
   - 必须显式标记
   - 但仍视为主线允许范围
6. 本轮不把 `capability-changing variant` 当作主证据

### 4.5 工作包 E：统一保存 `Reproduction Evidence Package`

每个 case 的证据包分两层保存。

#### 第一层：官方原生产物

至少保存：

1. `fetch/build` 日志
2. CodeQL DB build 日志
3. IRIS stage log
4. `raw_user_prompt_*`
5. `raw_llm_response_*`
6. `MySources.qll`
7. `MySinks.qll`
8. `MySummaries.qll`
9. `results.csv`

#### 第二层：复现判定补充产物

至少保存：

1. 实际执行命令
2. 关键 env 摘要
   - 模型名
   - provider base URL
   - CodeQL / Java / Maven 路径
3. `project_info.csv` 对应行
4. `build_info.csv` 对应行
5. `fix_info.csv` 对应行或聚合摘要
6. `fetch_external_apis/results.csv`
7. `fetch_func_params/results.csv`
8. 若存在则保存：
   - `fetch_sources/.../results.csv`
   - `fetch_sinks/.../results.csv`
9. `official_csv_row` 与 `local_observation` 对照页
10. `official_case` 与 `self_case` 的同构对照备注

#### 建议落盘目录

建议为这轮批次单开目录：

```text
artifacts/iris_case_trustworthiness/<run_id>/<case_group>/<project_slug>/
```

其中：

- `case_group = official`
- `case_group = self`

不要把这轮结果混入已有 smoke 目录。

当前已冻结并启用的执行入口：

- [artifacts/iris_case_trustworthiness/README.md](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/README.md:1)
- [artifacts/iris_case_trustworthiness/DEEPSEEK_TRUST01/README.md](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_TRUST01/README.md:1)
- [artifacts/iris_case_trustworthiness/DEEPSEEK_TRUST01/case_inventory.tsv](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/DEEPSEEK_TRUST01/case_inventory.tsv:1)

对应的规划骨架仍保留在：

- [artifacts/iris_case_trustworthiness/PLAN_DEEPSEEK_TRUST01/README.md](/home/lqs/llm_audit_system_learning/artifacts/iris_case_trustworthiness/PLAN_DEEPSEEK_TRUST01/README.md:1)

### 4.6 工作包 F：官方 CSV 与本地结果对照

对官方 case，每个 case 至少回答：

1. 官方 `Recall` 是否在本地复现
2. `Alerts / Paths / TP Alerts / TP Paths` 是否显著偏离
3. `source / sink / propagator` 数量是否异常
4. 是否出现空 `LLM response`
5. 是否存在 build / database / recipe 差异
6. 若失败，主要落在哪一层：
   - `fetch/build`
   - `CodeQL DB`
   - `Stage 3`
   - `query generation`
   - `posthoc filtering`

对自有 case，每个 case 至少回答：

1. 它与最相近官方 case 的差异在哪里
2. 差异主要来自：
   - build / metadata
   - code slice
   - candidate coverage
   - source / sink / propagator 标签
   - empty `LLM response`
3. 若官方 case 成功而自有 case 失败，哪一层最先分叉

### 4.7 工作包 G：可信度判断

这轮批次最终不是只做“是否跑通”的判断，而是做官方 case 可信度判断。

至少要回答：

1. 官方 case 是否明显比自有 case 更容易被 `IRIS` 处理
2. 这种“更容易”主要来自：
   - 官方构建契约更完整
   - 官方 metadata 更充分
   - 官方 case 本身更贴合 `IRIS` 假设
   - `DeepSeek` 对某类 prompt 更稳定
3. 因此官方 case 能否支撑“IRIS 值得继续学习”的判断
4. 还是只能支撑“IRIS 在特定官方 case 上可工作”的有限判断

## 5. 输出物

这轮批次结束后，至少产出三份文档：

1. `IRIS v2` 官方数据字典
2. 官方 case 与自有 case 的对照执行记录
3. 最终可信度判断报告

最终总结报告必须回答：

1. `DeepSeek + IRIS` 在官方 case 与自有 case 上的差异是什么
2. 当前 `PT / SSRF` 问题与官方成功 case 的主要差异
3. 官方 case 是否足够可信，可以作为继续学习 `IRIS` 的证据
4. `IRIS` 是否值得继续作为重点学习对象
5. 还是只保留为对照系统

## 6. 建议执行顺序

建议严格按以下顺序推进：

1. 先写官方数据字典
2. 冻结 5 个官方 case
3. 冻结自有对照 case
4. 先跑 `anchor`
5. 再跑 `contrast`
6. 再跑两个 `differential`
7. 再跑 `control`
8. 再跑自有对照 case
9. 汇总官方 CSV 与本地结果差异
10. 再写总报告

理由：

1. `anchor` 可以最早发现 quickstart 级别的环境问题
2. `contrast` 可以快速验证 quickstart 是否只是幸运样本
3. `differential` 是这轮最有价值的官方增益位
4. `control` 用来收尾判断整体官方成功链条是否健康
5. 自有对照 case 放在后面，便于直接和已完成的官方证据逐项比对

## 7. 退出条件

这轮学习批次的退出条件是：

1. 五个冻结官方 case 都至少完成一轮可审计运行
2. 自有对照 case 也完成同模型、同命令链运行
3. 每个 case 都生成完整 `Reproduction Evidence Package`
4. 官方 CSV 与本地结果已经逐 case 对照
5. 已能写出明确结论：
   - `官方 case 可信`
   - `官方 case 部分可信`
   - `官方 case 不足以支撑泛化判断`
6. 已能说明当前 `PT / SSRF` 异常更像是：
   - 官方 case 选择差异
   - build / DB 差异
   - LLM / prompt 稳定性问题
   - `IRIS` 机制性局限
