# Repository Guidelines

## 项目结构与模块组织

这个仓库是用于 LLM 漏洞审计的评估集与文档工作区，不是应用代码仓库。根目录主要包含：

- `llm_audit_system_learning_method.md`：评估方法与分阶段流程。
- `agent_eval_learning_rules.md`：agent 学习与评测的执行约束。
- `datasets/synthetic/`：手工构造的小型样本。
- `datasets/real_world/`：基于真实 CVE 整理的样本与仓库快照。

每个 case 目录应包含 `README.md`、`case.yaml`、`ground_truth.json`，以及对应源码文件或 `repo/` 目录。命名请沿用现有模式，如 `PT-PY-FILE-001`、`SSRF-JA-REPO-CVE-2023-3432-VULN`。

## 构建、测试与开发命令

当前仓库没有统一的构建或测试入口，编辑时以轻量校验为主：

- `find datasets -name case.yaml | wc -l`：统计样本数量。
- `python3 -m json.tool datasets/.../ground_truth.json >/dev/null`：检查 JSON 语法。
- `sed -n '1,80p' datasets/.../case.yaml`：快速查看样本元数据。
- `find datasets/<case-id> -maxdepth 2 -type f | sort`：确认必需文件是否齐全。

新增或修改 case 时，提交前应同时核对元数据和源码快照。

## 编码风格与命名约定

保持与仓库现有格式一致：

- Markdown：分节简短，表达直接，漏洞术语明确。
- 所有文档：统一使用中文撰写；如需保留英文术语，应以中文说明为主。
- YAML：使用 2 空格缩进；已有引号的 ID、标题保持引号风格。
- JSON：使用 2 空格缩进；字段顺序尽量稳定。
- Case 命名：遵循 `<VULN>-<LANG>-<MODE>-...`，并让 `VULN`、`FIXED`、`NEAR_MISS` 在目录名与内容中保持一致。

## 测试规范

这里的“测试”主要是标注完整性校验，不是单元测试覆盖率。每次新增或修改 case，至少检查：

1. `README.md`、`case.yaml`、`ground_truth.json` 中的漏洞类型、标签、输入模式是否一致。
2. 行号 anchor 是否与仓库内源码快照对应。
3. 对 `near_miss` case，`should_not_report` 是否清楚描述了 guard 或修复逻辑。

## 提交与 Pull Request 规范

当前工作区没有可用的 Git 历史，无法归纳项目既有提交规范。建议使用简短的祈使句提交标题，例如 `Add PT-PY near-miss case` 或 `Clarify repo-case anchor rules`。

PR 应说明变更范围、涉及的 case ID、执行过的校验命令，以及 benchmark 语义是否发生变化。

## Agent 相关说明

在盲评阶段，不要把 `ground_truth.json`、`case.yaml` 中的标签，或 README 里的标准答案暴露给 agent。学习性运行与冻结配置后的正式评测必须分离，具体约束见 `agent_eval_learning_rules.md`。
