# IRIS 部署与 Preflight Runbook

## 1. 作用

这个 runbook 用于本仓库中的 `IRIS` 学习期部署。

这里的“部署”不是生产上线，而是：

- 在 `Native Evaluation Environment` 中准备 `IRIS`
- 从 [`.env_deepseek`](/home/lqs/llm_audit_system_learning/.env_deepseek:1) 派生 `Derived System Configuration`
- 执行 `Preflight`
- 准备首轮 `Smoke Experiment` 的 `Clean Input`

## 2. 适用范围

本 runbook 只覆盖：

- `WSL/Linux` 原生环境中的 `IRIS` 学习期部署
- Java repo case 的 preflight 与 smoke 骨架
- `PT + SSRF` 首轮 smoke 约束

本 runbook 不覆盖：

- Docker-first 的 `IRIS` 部署
- Python case
- `SSTI` 首轮评估
- 已冻结配置下的正式 `Diagnostic Evaluation`

## 3. 已确认的学习期决策

这 5 项已在当前轮次固定。

1. 运行形态：`Native Evaluation Environment`
2. 配置来源：复用仓库唯一 `Experiment-side Configuration`
3. 首轮漏洞范围：`PT + SSRF`
4. Java 构库策略：优先使用 `Compile Recipe`
5. 首轮 smoke case：
   - `PT-JA-REPO-001`
   - `SSRF-JA-REPO-001`
   - `PT-JA-REPO-CVE-2024-53677-VULN`
   - `SSRF-JA-REPO-CVE-2023-3432-VULN`
   - `SSRF-JA-REPO-CVE-2023-3432-FIXED`

## 4. 目录与产物边界

- `IRIS` 上游源码默认放在：`/tmp/iris-v2`
- preflight 原始证据默认放在：`artifacts/iris_preflight/<run_id>/`
- smoke 原始证据默认放在：`artifacts/iris_smoke/<run_id>/`
- 临时 clean input 默认放在：`/tmp/iris_smoke_inputs/<run_id>/`

安全边界要求：

- 不把完整 benchmark 根目录直接暴露给 `IRIS`
- 不把 `ground_truth.json`、带标签 `case.yaml`、README 标准答案段暴露给 `IRIS`
- 只为当前 case 准备显式 `Clean Input`

## 5. 自动化入口

当前 runbook 对应的自动化脚本骨架为：

- [scripts/iris_local_env.sh](/home/lqs/llm_audit_system_learning/scripts/iris_local_env.sh:1)
- [scripts/iris_prepare_and_preflight.sh](/home/lqs/llm_audit_system_learning/scripts/iris_prepare_and_preflight.sh:1)
- [scripts/run_iris_smoke_cases.sh](/home/lqs/llm_audit_system_learning/scripts/run_iris_smoke_cases.sh:1)

支持的命令：

```bash
scripts/iris_prepare_and_preflight.sh prepare
scripts/iris_prepare_and_preflight.sh preflight
scripts/iris_prepare_and_preflight.sh all
scripts/iris_prepare_and_preflight.sh cleanup

scripts/run_iris_smoke_cases.sh prepare-inputs
scripts/run_iris_smoke_cases.sh plan
scripts/run_iris_smoke_cases.sh run
scripts/run_iris_smoke_cases.sh cleanup-inputs
```

如果要在普通 shell 中直接复用本地工具路径，先执行：

```bash
source scripts/iris_local_env.sh
```

当前这些脚本的定位是：

- 先固定输入、输出、证据目录和约束
- 先把 preflight 结构检查跑通
- 把 smoke 的 clean input、CodeQL DB 构建命令和 `IRIS` CLI 调用固定下来
- 在真实环境中逐 case 执行并保留原始 stdout/stderr

## 6. 前置条件

在真实运行前，至少确认：

1. `IRIS` 上游源码已就位：`IRIS_ROOT=/tmp/iris-v2`
2. [`.env_deepseek`](/home/lqs/llm_audit_system_learning/.env_deepseek:1) 中存在：
   - `LLM_PROVIDER`
   - `LLM_MODEL`
   - `LLM_API_KEY`
   - `LLM_BASE_URL`
3. 本机可用：
   - `python3`
   - `git`
   - `java`
   - `javac`
   - `codeql`
4. 若要真正执行 `IRIS`，还需要可工作的 Python 环境与其依赖

## 7. Preflight 目标

`Preflight` 的通过标准不是“已经发现正确漏洞”，而是：

- `IRIS` 源码结构存在
- `Derived System Configuration` 已从 `.env_deepseek` 正确派生
- `CodeQL` 与 Java 工具链可见
- 首轮 5 个 Java smoke case 的目录契约存在
- 每个 case 的 `Compile Recipe`、源码根、证据目录都能被脚本正确识别

## 8. Clean Input 约束

### 8.1 为什么要显式准备

Java case 的评估稳定性不仅取决于源码本身，也取决于如何构库。

因此当前策略是：

- 有 `Compile Recipe` 时，先把它当成构库契约
- 对 synthetic case，显式复制 `src/main/java` 内容作为输入根
- 对 real-world curated subset，显式复制 `repo/` 内容作为输入根
- 若存在 `build_support/stubs`，一并复制

### 8.2 当前 5 个 smoke case 的输入根

- `PT-JA-REPO-001` -> `src/main/java`
- `SSRF-JA-REPO-001` -> `src/main/java`
- `PT-JA-REPO-CVE-2024-53677-VULN` -> `repo`
- `SSRF-JA-REPO-CVE-2023-3432-VULN` -> `repo`
- `SSRF-JA-REPO-CVE-2023-3432-FIXED` -> `repo`

## 9. 执行顺序

建议按下面顺序执行。

1. 先运行：

```bash
scripts/iris_prepare_and_preflight.sh all
```

2. 确认 `artifacts/iris_preflight/<run_id>/` 中出现：
   - `run_manifest.json`
   - `iris.env`
   - `preflight_checks.tsv`
   - `result.env`

3. 再运行：

```bash
scripts/run_iris_smoke_cases.sh prepare-inputs
scripts/run_iris_smoke_cases.sh plan
```

4. 在满足 preflight 前置条件后，运行：

```bash
scripts/run_iris_smoke_cases.sh run
```

## 10. 当前骨架的已知限制

这版脚本仍然保留两个现实边界：

- `IRIS` 上游 checkout、Python 依赖、CodeQL bundle 和 Java 工具链必须在本机真实可用
- `IRIS` 的 `--llm` 仍受 upstream 支持的模型别名约束，因此实验侧模型接入仍需在真实环境中完成最终别名校准

换句话说，当前已经冻结的是执行链路，不是“任意环境下都能立即成功”的假设。

## 11. 官方行为与变体边界

从当前阶段开始，`IRIS` 的学习记录必须显式区分“官方行为观察”和“变体实验”。

### 11.1 哪些修改仍算部署/接线层

以下修改可以归入 `runtime compatibility variant`：

- OpenAI-compatible provider 的接线修正
- `base_url`、模型名、环境变量 CRLF 清洗
- 不改变漏洞语义的请求参数兼容修正
- 本机工具路径与 `IRIS` 配置文件的对接

这类修改的目标是让 `IRIS` 在当前 `Native Evaluation Environment` 中按预期机制运行，不应直接表述为“IRIS 能力提升”。

### 11.2 哪些修改已经进入能力改动

以下修改必须归入 `capability-changing variant`：

- 改写 `external/internal` 候选过滤边界
- 修改 source / sink / taint-propagator 候选生成规则
- 修改 prompt 语义、ranking、解析或 post-processing
- 为特定漏洞类型新增额外 heuristic
- 为特定输入形态新增额外候选补充通道

一旦进行上述修改，就不能再把结果记为“官方 IRIS 学习运行结果”，而必须视为新的变体线。

### 11.3 记录要求

进行任何变体实验前，必须同时完成：

1. 在 `reports/systems/iris/registries/variant_registry.md` 中登记 `variant_id`
2. 记录修改类别：
   - `runtime_compat`
   - `capability_change`
3. 记录修改文件、动机、预期影响和对应 run id

### 11.4 结果解释要求

- `official upstream baseline` 只能回答“官方 IRIS 原始机制在该样本上的行为”
- `runtime compatibility variant` 只能回答“接线修复后是否能正常运行”
- `capability-changing variant` 才能回答“如果修改 IRIS 机制，它是否更适合该 benchmark 输入边界”

三者不得合并成一个结论表，也不得共用同一个版本说明。
