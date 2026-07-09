#!/usr/bin/env python3
import csv
import json
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent

SLOTS = [
    {
        "experiment_id": "A-synthetic-PT-PY-FILE-001",
        "shape": "A",
        "layer": "synthetic",
        "case_id": "PT-PY-FILE-001",
        "run_class": "diagnostic only",
        "constraint_summary": "单文件 instant analysis；无 repo 打包；无 target_files",
        "source_dir": REPO_ROOT / "artifacts/deepaudit_diagnosis/20260701T115134Z/A4-PT-PY-FILE-001",
        "source_kind": "instant",
        "judgment": {
            "target_signal": "clear",
            "noise_shape": "low",
            "ranking_quality": "good",
            "usability_tier": "usable",
            "notes": "首条 finding 直接命中 PT，辅噪主要是 debug 与实现层问题；instant analysis 约 35.8 秒返回，适合作为基础语义能力上界。",
        },
    },
    {
        "experiment_id": "A-synthetic-SSRF-PY-FILE-001",
        "shape": "A",
        "layer": "synthetic",
        "case_id": "SSRF-PY-FILE-001",
        "run_class": "diagnostic only",
        "constraint_summary": "单文件 instant analysis；无 repo 打包；无 target_files",
        "source_dir": REPO_ROOT / "artifacts/deepaudit_boundary_expansion/20260702T013845Z/A-synthetic-SSRF-PY-FILE-001",
        "source_kind": "instant",
        "judgment": {
            "target_signal": "clear",
            "noise_shape": "moderate",
            "ranking_quality": "good",
            "usability_tier": "usable",
            "notes": "首条 finding 直接命中 SSRF，后续主要是 debug、异常泄露和协议约束类扩展告警；44 秒内同步返回，可作为 synthetic/SSRF 的正式 A 记录。",
        },
    },
    {
        "experiment_id": "B-synthetic-PT-PY-FILE-001-mini-repo",
        "shape": "B",
        "layer": "synthetic",
        "case_id": "PT-PY-FILE-001",
        "run_class": "diagnostic only",
        "constraint_summary": "最小 repo 包装；无 target_files；agent task；主文件位于 src/app.py",
        "source_dir": REPO_ROOT / "artifacts/deepaudit_diagnosis/20260701T115134Z/A3-PT-PY-FILE-001",
        "source_kind": "agent",
        "judgment": {
            "target_signal": "partial",
            "noise_shape": "high",
            "ranking_quality": "poor",
            "usability_tier": "partially_usable",
            "notes": "虽然命中了 PT，但 findings 中出现与样本不完全贴合的 `/logs` 端点和 `app.py:54` 等内容；它证明了 repo 结构感有帮助，但输出不够干净。",
        },
    },
    {
        "experiment_id": "B-real-world-PT-PY-REPO-CVE-2024-32982-VULN",
        "shape": "B",
        "layer": "real-world",
        "case_id": "PT-PY-REPO-CVE-2024-32982-VULN",
        "run_class": "diagnostic only",
        "constraint_summary": "人工裁剪子集 repo；无 target_files；保留 static_files 相关局部文件",
        "source_dir": REPO_ROOT / "artifacts/deepaudit_diagnosis/20260701T123248Z/C4-PT-PY-REPO-CVE-2024-32982-VULN",
        "source_kind": "agent",
        "judgment": {
            "target_signal": "clear",
            "noise_shape": "moderate",
            "ranking_quality": "good",
            "usability_tier": "partially_usable",
            "notes": "裁剪小 repo 能稳定命中真实世界 PT，前 3 条以目标信号为主；但 443 秒、174056 tokens 的成本仍然偏高，说明“有 repo 结构感”仍不等于“低成本可用”。",
        },
    },
    {
        "experiment_id": "C-synthetic-PT-PY-REPO-001",
        "shape": "C",
        "layer": "synthetic",
        "case_id": "PT-PY-REPO-001",
        "run_class": "diagnostic only",
        "constraint_summary": "完整 synthetic repo；显式 target_files 收窄到目标路径文件",
        "source_dir": REPO_ROOT / "artifacts/deepaudit_diagnosis/20260701T110600Z/B2-PT-PY-REPO-001",
        "source_kind": "agent",
        "judgment": {
            "target_signal": "clear",
            "noise_shape": "moderate",
            "ranking_quality": "mixed",
            "usability_tier": "partially_usable",
            "notes": "显式收窄后能稳定命中 PT，但首条 finding 仍偏入口层辅助告警，而不是最佳漏洞总览；347 秒、255182 tokens 的成本也偏高。",
        },
    },
    {
        "experiment_id": "C-real-world-PT-PY-REPO-CVE-2024-32982-VULN",
        "shape": "C",
        "layer": "real-world",
        "case_id": "PT-PY-REPO-CVE-2024-32982-VULN",
        "run_class": "diagnostic only",
        "constraint_summary": "完整 real-world repo；显式 target_files 收窄到 static_files 相关文件",
        "source_dir": REPO_ROOT / "artifacts/deepaudit_diagnosis/20260701T110600Z/C3-PT-PY-REPO-CVE-2024-32982-VULN",
        "source_kind": "agent",
        "judgment": {
            "target_signal": "clear",
            "noise_shape": "low",
            "ranking_quality": "good",
            "usability_tier": "usable",
            "notes": "这是当前最接近“受控可用”的 repo 形态：前 3 条 findings 都围绕 CVE-2024-32982/PT 展开，排序稳定，噪声可控；成本仍不低，但结果质量成立。",
        },
    },
    {
        "experiment_id": "D-synthetic-PT-PY-REPO-001",
        "shape": "D",
        "layer": "synthetic",
        "case_id": "PT-PY-REPO-001",
        "run_class": "baseline-like",
        "constraint_summary": "完整 synthetic repo；agent task；无 target_files；boundary 阶段正式重跑",
        "source_dir": REPO_ROOT / "artifacts/deepaudit_boundary_expansion/20260702T013845Z/D-synthetic-PT-PY-REPO-001",
        "source_kind": "agent",
        "judgment": {
            "target_signal": "clear",
            "noise_shape": "high",
            "ranking_quality": "mixed",
            "usability_tier": "partially_usable",
            "notes": "目标 PT finding 排在第 2 条，前面有入口层辅助告警；整体呈现典型 broad-scan noise，且 217 秒、177167 tokens 的成本偏高。",
        },
    },
    {
        "experiment_id": "D-real-world-PT-PY-REPO-CVE-2024-32982-VULN",
        "shape": "D",
        "layer": "real-world",
        "case_id": "PT-PY-REPO-CVE-2024-32982-VULN",
        "run_class": "baseline-like",
        "constraint_summary": "完整 real-world repo；无 target_files；提高预算；长轮询",
        "source_dir": REPO_ROOT / "artifacts/deepaudit_diagnosis/20260701T115134Z/C2-PT-PY-REPO-CVE-2024-32982-VULN",
        "source_kind": "agent",
        "judgment": {
            "target_signal": "clear",
            "noise_shape": "high",
            "ranking_quality": "mixed",
            "usability_tier": "partially_usable",
            "notes": "完整大仓库在高预算下能拖到完成并命中 PT，但输出混有配置层和文件响应层扩展告警，还有 1 条已验证无实际影响项；成本最高，更多是在用代价硬换收敛。",
        },
    },
]


def read_json(path: Path):
    if not path.exists() or path.stat().st_size == 0:
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def collect_row(slot: dict) -> dict:
    source_dir = slot["source_dir"]
    metrics = read_json(source_dir / "metrics.json")
    top_3 = metrics.get("top_3_findings", [])
    wall_clock = metrics.get("wall_clock_seconds")
    if wall_clock is None:
        wall_clock = metrics.get("duration_seconds")
    if wall_clock is None and slot["source_kind"] == "agent":
        summary = read_json(source_dir / "task_summary.json")
        wall_clock = summary.get("duration_seconds")
    if wall_clock is None and slot["source_kind"] == "instant":
        instant = read_json(source_dir / "instant_analysis.json")
        wall_clock = instant.get("analysis_time")

    return {
        "experiment_id": slot["experiment_id"],
        "shape": slot["shape"],
        "layer": slot["layer"],
        "case_id": slot["case_id"],
        "run_class": slot["run_class"],
        "constraint_summary": slot["constraint_summary"],
        "status": metrics.get("status", ""),
        "total_iterations": metrics.get("total_iterations"),
        "tool_calls_count": metrics.get("tool_calls_count"),
        "tokens_used": metrics.get("tokens_used"),
        "wall_clock_seconds": wall_clock,
        "findings_count": metrics.get("findings_count"),
        "top_3_findings": json.dumps(top_3, ensure_ascii=False),
        "target_signal": slot["judgment"]["target_signal"],
        "noise_shape": slot["judgment"]["noise_shape"],
        "ranking_quality": slot["judgment"]["ranking_quality"],
        "usability_tier": slot["judgment"]["usability_tier"],
        "notes": slot["judgment"]["notes"],
    }


def render_matrix(output_dir: Path) -> list[dict]:
    rows = [collect_row(slot) for slot in SLOTS]
    fieldnames = [
        "experiment_id",
        "shape",
        "layer",
        "case_id",
        "run_class",
        "constraint_summary",
        "status",
        "total_iterations",
        "tool_calls_count",
        "tokens_used",
        "wall_clock_seconds",
        "findings_count",
        "top_3_findings",
        "target_signal",
        "noise_shape",
        "ranking_quality",
        "usability_tier",
        "notes",
    ]
    with (output_dir / "boundary_matrix.tsv").open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames, delimiter="\t", extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow(row)
    return rows


def render_memo(output_dir: Path, rows: list[dict]) -> None:
    usable = [row for row in rows if row["usability_tier"] == "usable"]
    partially = [row for row in rows if row["usability_tier"] == "partially_usable"]
    not_usable = [row for row in rows if row["usability_tier"] == "not_usable"]

    def pick(shape: str) -> list[dict]:
        return [row for row in rows if row["shape"] == shape]

    lines = ["# DeepAudit Boundary Memo", ""]
    lines.append("## 总结")
    lines.append("")
    lines.append("- 当前 8 个主记录中，`usable` 有 3 个：`A-synthetic-PT-PY-FILE-001`、`A-synthetic-SSRF-PY-FILE-001`、`C-real-world-PT-PY-REPO-CVE-2024-32982-VULN`。")
    lines.append("- `partially_usable` 有 5 个，集中在 `B/C/D` 的 agent repo 形态。")
    lines.append("- `not_usable` 当前为 0 个，但 `B-synthetic-PT-PY-FILE-001-mini-repo` 已接近边界下沿，主要问题是结果不够干净。")
    lines.append("")
    lines.append("## 形态判断")
    lines.append("")
    lines.append("- `A`：在 synthetic 单文件上最稳定，PT/SSRF 都能快速给出 clear target signal，属于当前最明确的 `usable` 边界。")
    lines.append("- `B`：repo 结构感能帮助命中目标，但不自动带来干净输出；small repo 在 synthetic 上仍有 hallucination 风险，在 real-world 上成本仍偏高。")
    lines.append("- `C`：是当前最接近真实可用的 repo 形态。尤其在 real-world + target_files 下，目标命中、排序和噪声控制最好。")
    lines.append("- `D`：保留了现实压力，但当前主要表现为高成本、慢收敛和辅助噪声偏多，只能算 `partially_usable`。")
    lines.append("")
    lines.append("## 分层判断")
    lines.append("")
    lines.append("- `synthetic`：A 形态已经达到 `usable`；B/C/D 都能命中 PT，但仍不同程度受到噪声、排序或成本影响。")
    lines.append("- `real-world`：C 形态是当前唯一明确达到 `usable` 的主记录；B/D 虽然能打到目标，但都还不够收敛。")
    lines.append("")
    lines.append("## 真正可用边界")
    lines.append("")
    lines.append("- 如果目标是观察基础漏洞语义能力，当前边界是：`A / instant analysis`。")
    lines.append("- 如果目标是观察 repo 工作流里的受控可用性，当前边界是：`C / 完整 repo + target_files`。")
    lines.append("- 如果不提供显式收窄，只给 repo 结构，DeepAudit 仍能命中目标，但更容易落入 `partially_usable`。")
    lines.append("")
    lines.append("## 判级明细")
    lines.append("")
    for row in rows:
        lines.append(f"- `{row['experiment_id']}`: `{row['usability_tier']}`")
        lines.append(f"  解释：target_signal={row['target_signal']}，noise_shape={row['noise_shape']}，ranking_quality={row['ranking_quality']}；{row['notes']}")
    lines.append("")
    lines.append("## 当前收口建议")
    lines.append("")
    lines.append("- boundary v1 主表现在已经具备统一判级基础，可以进入“字段补全 + 主表冻结”阶段。")
    lines.append("- 下一步不宜再补跑新形态，而应先把这 8 条主记录的 `target_signal / noise_shape / ranking_quality / usability_tier` 固化进统一表。")
    lines.append("- near-miss 扩展应放到 boundary 主表收口之后，再作为第二层扩展进入。")
    (output_dir / "boundary_memo.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    output_dir = REPO_ROOT / "artifacts/deepaudit_boundary_expansion/20260702T013845Z"
    output_dir.mkdir(parents=True, exist_ok=True)
    rows = render_matrix(output_dir)
    render_memo(output_dir, rows)


if __name__ == "__main__":
    main()
