# DeepAudit 全面学习报告

## 1. 研究目标与范围

本报告用于收口当前针对 DeepAudit 的整轮 `Learning Run`，目标不是产出可比较分数，而是回答以下问题：

1. DeepAudit 在当前固定实验环境下是否可稳定运行。
2. 它更像什么类型的系统：
   - 单文件快速 verifier
   - repo-oriented broad scanner
   - 还是受控 repo 工作流下的 target-aware auditor
3. 在哪些输入形态下，它还能保持 `usable`。
4. 其主要失败模式、工程约束和成本边界是什么。
5. 当前是否已经足够结束 `Learning Run`，转而整理结论，或进一步进入正式 `Diagnostic Evaluation`。

本报告覆盖的实验层级包括：

- `Preflight / 部署验证`
- `Smoke Experiment`
- `Boundary-Condition Diagnostic Expansion`
- `最小扩样`
- `同案 file/repo 编排耗时辅助诊断`

本报告**不**是：

- 冻结配置下的大样本正式 `Diagnostic Evaluation`
- 不同系统之间的可比分数报告
- 覆盖全漏洞家族、全输入模式、全 near-miss 族谱的穷尽评测

## 2. 部署与实验约束

### 2.1 实验环境

当前 DeepAudit 学习使用的是：

- Windows 主机启动的官方 DeepAudit 服务
- WSL 侧通过 ZIP 上传工作流调用
- `.env_deepseek` 作为唯一 `Experiment-side Configuration`
- `verification_level=analysis_only`
- 不向系统暴露 `ground_truth.json`、答案型 README、带标签 `case.yaml`

相关操作文档：

- [deepaudit_wsl_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/runbooks/deepaudit_wsl_runbook.md:1)

### 2.2 保持固定的约束

整轮学习尽量保持以下条件固定：

- `Official Version`，不本地魔改产品逻辑
- 固定模型配置与 API 接入方式
- 固定 ZIP 输入工作流
- 统一记录 run manifest、task object、summary、findings、metrics

这保证了本轮结论主要来自：

- 输入形态差异
- 收窄策略差异
- repo 规模差异

而不是来自工具本身版本漂移。

## 3. DeepAudit 工作流理解

### 3.1 从当前实验看，它更像什么

基于整轮学习，DeepAudit 更接近：

> 一个 `repo-oriented`、带 agent 编排的、在受控收窄条件下能给出较强目标语义的审计器；但在无收窄完整大仓库下，会明显退化为高成本 broad scan。

这一定义比 smoke 阶段更精确。smoke 阶段只能说它“像 broad repo scanner”；经过 boundary 和最小扩样后，可以进一步拆成两种状态：

- `A / instant analysis`：基础漏洞语义能力上界
- `C / 完整 repo + target_files`：当前最接近受控可用的 repo 工作流
- `D / 完整 repo，无 target_files`：高成本压力基线

### 3.2 输入形态地图

当前已经稳定形成 4 种输入形态语言：

- `A. instant analysis / 单文件或关键片段`
- `B. 小 repo / 裁剪 repo，不给 target_files`
- `C. 完整 repo + target_files`
- `D. 完整 repo，不给 target_files`

对应主结论产物：

- [boundary_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/20260702T013845Z/boundary_matrix.tsv:1)
- [boundary_expansion_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/summaries/boundary_expansion_summary.md:1)

### 3.3 关键 caller/模块图

如果从当前仓库的实验调用链往上看，DeepAudit 学习相关模块关系可以简化为：

- 运行约束与术语层
  - [CONTEXT.md](/home/lqs/llm_audit_system_learning/CONTEXT.md:1)
  - [llm_audit_system_learning_method.md](/home/lqs/llm_audit_system_learning/llm_audit_system_learning_method.md:1)
  - [agent_eval_learning_rules.md](/home/lqs/llm_audit_system_learning/agent_eval_learning_rules.md:1)
- 环境/预检层
  - [deepaudit_wsl_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/runbooks/deepaudit_wsl_runbook.md:1)
  - [scripts/deepaudit_prepare_and_preflight.sh](/home/lqs/llm_audit_system_learning/scripts/deepaudit_prepare_and_preflight.sh:1)
- 固定槽位 runner 层
  - [scripts/run_deepaudit_boundary_instant_slots.sh](/home/lqs/llm_audit_system_learning/scripts/run_deepaudit_boundary_instant_slots.sh:1)
  - [scripts/run_deepaudit_boundary_agent_slots.sh](/home/lqs/llm_audit_system_learning/scripts/run_deepaudit_boundary_agent_slots.sh:1)
- 参数化实验 runner 层
  - [scripts/run_deepaudit_repo_experiment.sh](/home/lqs/llm_audit_system_learning/scripts/run_deepaudit_repo_experiment.sh:1)
  - [scripts/spec_templates/deepaudit_minimal_expansion/](/home/lqs/llm_audit_system_learning/scripts/spec_templates/deepaudit_minimal_expansion:1)
- 证据与结论层
  - `artifacts/deepaudit_smoke/...`
  - `artifacts/deepaudit_diagnosis/...`
  - `artifacts/deepaudit_boundary_expansion/...`
  - `artifacts/deepaudit_minimal_expansion/...`

也就是说，当前仓库里 DeepAudit 学习的“调用者”并不是应用代码，而是：

- runbook 定义实验语义
- runner 负责把 `Case` 转成 `Clean Input`
- artifacts 负责沉淀 `Learning Run` 证据

## 4. Smoke 结论

### 4.1 smoke 已经证明了什么

主证据：

- [learning_summary.md](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_smoke/20260701T083143Z/learning_summary.md:1)
- [observations.md](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_smoke/20260701T083143Z/observations.md:1)

smoke 阶段已经证明：

- DeepAudit 在真实 Windows 主机服务 + WSL 调用环境下是 `runnable` 的。
- 它值得继续学习，问题不再是“能不能跑起来”，而是“它在 benchmark-style 约束下呈现什么审计行为”。

### 4.2 smoke 的核心现象

smoke 最早暴露出三个高信号现象：

1. `repo` 能完成，而 `file` 在 smoke 预算下全超时。
2. `PT-PY-REPO-001` 能完成，并给出有价值的 cross-file PT 解释。
3. `PT-PY-REPO-CVE-2024-32982-VULN` 在 real-world repo 下预算不收敛。

smoke 阶段因此得到的工作假设是：

> DeepAudit 更像 repo-oriented broad scanner，而不是紧凑的 file-mode target verifier。

后续 boundary 与最小扩样基本都建立在这个假设的细化上。

## 5. Boundary v1 结论

主证据：

- [boundary_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_boundary_expansion/20260702T013845Z/boundary_matrix.tsv:1)
- [boundary_expansion_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/summaries/boundary_expansion_summary.md:1)
- [deepaudit_boundary_condition_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/runbooks/deepaudit_boundary_condition_runbook.md:1)

### 5.1 边界主结论

boundary v1 给出了 8 条主记录，并统一判成：

- `usable`: 3
- `partially_usable`: 5
- `not_usable`: 0

高层结论是：

- `A`：当前最明确的 `usable` 边界
- `B`：repo 结构感有帮助，但不自动带来干净输出
- `C`：当前最接近受控可用的 repo 形态
- `D`：最接近现实压力，但代价、噪声和慢收敛问题明显

### 5.2 最重要的 boundary 判断

boundary v1 形成了两个极重要的学习判断：

1. **基础语义能力边界**
   - `A / instant analysis`
   - 适合观察 DeepAudit 是否“理解漏洞”
2. **repo 工作流可用边界**
   - `C / 完整 repo + target_files`
   - 适合观察 DeepAudit 是否“在 repo 工作流里可控地给出目标信号”

这也是为什么后续最小扩样没有去补更多 `A/B`，而是集中补 `C/D`。

## 6. 最小扩样结论

主证据：

- [expansion_matrix.tsv](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_minimal_expansion/20260702T061515Z/expansion_matrix.tsv:1)
- [minimal_expansion_summary.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/summaries/minimal_expansion_summary.md:1)
- [deepaudit_minimal_expansion_runbook.md](/home/lqs/llm_audit_system_learning/reports/systems/deepaudit/runbooks/deepaudit_minimal_expansion_runbook.md:1)

### 6.1 为什么需要最小扩样

boundary v1 的主要弱点在于：

- 主记录仍偏 `PT`
- `C-real-world usable` 主要建立在 `Litestar / CVE-2024-32982` 上
- 关键结论缺少 repeat

因此最小扩样补了：

- 1 组非 `PT` synthetic repo 对照
- 1 组第二 real-world 项目线
- 1 个关键 repeat

### 6.2 最小扩样后的核心修正

最小扩样的最重要结论有三个：

1. `C` 的优势不是只在 `PT` 上成立
   - `C-synthetic-SSRF-PY-REPO-001` 提供了非 `PT` synthetic repo 证据
2. `C-real-world usable` 不再只建立在 `Litestar/PT` 一条线上
   - `C-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN` 达到 `usable`
3. `D-real-world` 的高成本退化在第二条 real-world 项目线上再次复现
   - `D-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN` 以极高成本换来有限目标信号

### 6.3 repeat 带来的细化

`C-real-world-PT-PY-REPO-CVE-2024-32982-VULN-repeat1` 给出的不是“完全稳定”，而是更细的结论：

- `target signal` 稳定
- 成本量级稳定
- 但排序与 framing 会漂移

这意味着：

> `C-real-world` 可以被认为是“可用”，但不能被描述成“稳定、严格、完全一致的 target verifier”。

## 7. 成本与编排行为

辅助证据：

- [file_repo_timing_experiment.md](/home/lqs/llm_audit_system_learning/artifacts/deepaudit_smoke/20260701T083143Z/file_repo_timing_experiment.md:1)
- `artifacts/deepaudit_timing/...`

### 7.1 file/repo 偏好不是抽象感受

经过同案 file/repo 对照与后续 `C/D` 配对，可以更具体地说：

- DeepAudit 的 agent 编排更偏好 repo 结构输入，而不是孤立 file 输入。
- 这种“偏好 repo”不一定表现为 wall clock 一定更短。
- 它更常表现为：
  - 迭代结构不同
  - tool call 分布不同
  - target signal 与结构层说明的比例不同

### 7.2 D 形态的真实代价

`D-real-world-SSTI-PY-REPO-CVE-2024-45053-VULN` 是本轮最强成本证据之一：

- `3412` files
- `47` iterations
- `41` tool calls
- `748569` tokens
- `596s`
- 最终只有 `2` 条 findings

这说明：

> 在完整 real-world 大仓库且不显式收窄时，DeepAudit 会非常明显地用 agent 编排和广扫描代价来换取目标信号。

## 8. 总体学习结论

### 8.1 DeepAudit 的优势场景

当前最明确的优势场景有两个：

1. `A / instant analysis`
   - 能较快给出基础漏洞语义信号
   - 适合观察它是否理解 `PT / SSRF`
2. `C / 完整 repo + target_files`
   - 是当前最接近受控可用的 repo 工作流形态
   - 在第二条 real-world 项目线上也已经成立

### 8.2 DeepAudit 的主要失败模式

当前最稳定出现的失败模式包括：

- `broad_scan_noise`
- `timeout`
- ranking / framing drift
- 成本过高导致“能做但不够可用”

更具体地说：

- `D` 形态经常不是“找不到目标”
- 而是“要付出非常高的成本后才收敛到目标”

### 8.3 工程约束

当前 DeepAudit 学习里已经明确的工程约束有：

- 更依赖 repo 结构而不是孤立 file
- 完整大仓库下必须非常关注候选收窄
- `target_files` 对控制成本和输出质量极其关键
- `task_events` 在当前环境下不是可靠主信号
- 输出常有 `file_path: null` 或以 prose 为主，不总是天然适合 benchmark-native anchor 打分

## 9. 是否进入正式 Diagnostic Evaluation

当前判断是：

- **可以结束 DeepAudit 的 `Learning Run`**
- **但还不建议直接把当前这批结果当成正式 `Diagnostic Evaluation`**

原因：

1. 这轮工作已经足够回答机制、边界和失败模式问题。
2. 但还没有大样本、冻结配置、统一 failure taxonomy 主表下的正式批量评估。
3. `near_miss` / negative control 在 DeepAudit 线上还没有形成同等强度的主证据。

因此，更合适的下一步是二选一：

1. **整理并冻结本轮学习报告**
   - 用于系统学习、横向比较、架构借鉴
2. **如果确实要做正式比较**
   - 另起一轮冻结版 `Diagnostic Evaluation`
   - 明确样本集、预算、判定规则和失败归因口径

## 10. 最终判断

可以把本轮 DeepAudit 工作总结为：

> DeepAudit 已经完成了“值得研究吗”到“在哪些输入形态下还可用、代价如何、为何退化”的学习闭环。

当前最稳妥的总判断是：

- `A` 代表基础语义能力上界
- `C` 是当前最接近受控可用的 repo 工作流形态
- `C-real-world usable` 不再只是单个项目特例
- 但 `C` 的 target signal 稳定，不等于排序与 framing 完全稳定
- `D` 能命中目标，但在完整 real-world 大仓库上更像“高成本压力基线”，而不是日常可用形态

因此：

- **对 DeepAudit 的学习可以认为基本结束**
- **现在整理全面学习报告是合理且及时的**
- **除非目标切换为正式 `Diagnostic Evaluation`，否则不建议继续追加零散实验**
