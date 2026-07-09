# E4 SSRF-3432 DeepAudit D1/D2 Runbook

## 1. 作用

这个 runbook 用于执行 `Architecture Attribution Experiment` 中 `SSRF-JA-REPO-CVE-2023-3432-VULN/FIXED` 的第一轮 `DeepAudit` 低信息参照：

- `D1`：无 `CVE` 描述，无 `patch/diff`，无 `target_files`
- `D2`：只有 `CVE` 描述，无 `patch/diff`，无 `target_files`

它回答的问题是：

- 当 `IRIS-style static-gated workflow` 的 `E1-D` 仍然失败后，`DeepAudit` 在低信息条件下是否能恢复 `target vulnerability`
- `DeepAudit` 的优势是否至少部分来自更自由的 repo-level 语义审计，而不是 `target_files` 或 `diff` 优势

## 2. 不做什么

本 runbook 不负责：

- `D3` 或 `D4`
- 给 `DeepAudit` 注入 `patch/fixed diff`
- 给 `DeepAudit` 提供 `target_files`
- 改写 `DeepAudit` 服务部署或提示词
- 把结果写回 `artifacts/deepaudit_*`

## 3. 条件定义

### 3.1 D1

输入约束：

- 使用 case 自带的 curated subset repo
- 不提供 `target_files`
- 不附加 `CVE` 说明文件
- 不提供 patch、diff、修复说明

实现方式：

- `case_dir` 直接指向数据集目录
- `input_path=repo`
- `target_files` 缺省

### 3.2 D2

输入约束：

- 使用与 `D1` 同一份 curated subset repo
- 不提供 `target_files`
- 不提供 patch、diff、目标文件或行号
- 只增加一份 repo 根目录的 `CVE_CONTEXT.md`

`CVE_CONTEXT.md` 只允许包含：

- `CVE-2023-3432`
- 漏洞类型是 `SSRF`
- 高层语义：`userinfo/@` 相关的 URL allowlist bypass

`CVE_CONTEXT.md` 不允许包含：

- 修复提交
- fixed diff
- 目标函数名
- 目标文件路径
- 行号 anchor

## 4. 输入落点

### 4.1 D1 spec

- [AAE4_SSRF3432_VULN_D1.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/specs/AAE4_SSRF3432_VULN_D1.json:1)
- [AAE4_SSRF3432_FIXED_D1.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/specs/AAE4_SSRF3432_FIXED_D1.json:1)

### 4.2 D2 spec

- [AAE4_SSRF3432_VULN_D2.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/specs/AAE4_SSRF3432_VULN_D2.json:1)
- [AAE4_SSRF3432_FIXED_D2.json](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/specs/AAE4_SSRF3432_FIXED_D2.json:1)

### 4.3 D2 staging bundle

- [VULN D2 staging](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/staging/SSRF-JA-REPO-CVE-2023-3432-VULN_D2/CVE_CONTEXT.md:1)
- [FIXED D2 staging](/home/lqs/llm_audit_system_learning/artifacts/architecture_attribution/E4/staging/SSRF-JA-REPO-CVE-2023-3432-FIXED_D2/CVE_CONTEXT.md:1)

## 5. 运行约束

### 5.1 网络访问

真实 `DeepAudit` 连通性检查必须使用提权网络上下文，不得在默认 `exec_command` 沙箱内探测。

固定检查顺序：

1. `curl http://127.0.0.1:8000/health`
2. `curl http://localhost:8000/health`
3. `curl http://172.27.144.1:8000/health`

主机选择规则：

- 使用第一个返回 `200` 的 backend URL
- 后续 runner 全部绑定到同一个 backend URL
- frontend URL 采用同主机、端口 `3000`

### 5.2 runner

使用：

- [scripts/run_deepaudit_repo_experiment.sh](/home/lqs/llm_audit_system_learning/scripts/run_deepaudit_repo_experiment.sh:1)

结果落点必须覆写到：

- `artifacts/architecture_attribution/E4/`

不得使用默认：

- `artifacts/deepaudit_repo_experiments/`

## 6. 建议运行顺序

按 pair 交错运行：

1. `VULN D1`
2. `FIXED D1`
3. `VULN D2`
4. `FIXED D2`

原因：

- 先看 `D1` 是否已经足够恢复 `VULN`
- 再看 `FIXED D1` 是否自然保持不报或解释 guard
- 然后再观察 `D2` 的 `CVE` hint 是否抬升 `VULN`，以及是否同时污染 `FIXED`

## 7. 成功判定

### 7.1 VULN

至少记录：

- 是否出现与 `SSRF` 相关的主 finding
- top findings 是否把问题锚定到 `SURL` allowlist / userinfo bypass 语义
- 是否能提到 `%load_json` / `LoadJson` / `SURL` / allowlist 其中至少两个关键概念

### 7.2 FIXED

至少记录：

- 是否仍然报同类 `SSRF`
- 是否解释 `@` 拒绝、allowlist 收紧或 userinfo 处理变化
- 如果仍报漏洞，是否只是被 `CVE` hint 带偏，而没有引用修复后的 guard 语义

## 8. 产物要求

每次 run 至少保存：

- runner `run_manifest.json`
- `spec.json`
- `case_meta.json`
- `create_project.json`
- `upload_zip.json`
- `create_task.json`
- `task_object.json`
- `task_findings.json`
- `task_summary.json`
- `metrics.json`
- `failure_classification.txt`

此外补一份本实验线的 pair-level 总结，明确：

- `D1` 与 `D2` 是否优于 `E1-D`
- `D2` 是否只提高了 `VULN`，还是同时带高了 `FIXED` 误报风险
- 下一步是否需要进入 `D4` 或转向 `E2`
