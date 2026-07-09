#!/usr/bin/env python3

import argparse
import csv
import json
import os
import re
from pathlib import Path


DEFAULT_CASES = [
    "PT-JA-REPO-CVE-2024-53677-VULN",
    "SSRF-JA-REPO-CVE-2023-3432-VULN",
    "SSRF-JA-REPO-CVE-2023-3432-FIXED",
]

INTERESTING_FUNC_RE = re.compile(
    r"(getfile|getcontent|getparameter|getservletrequest|getinputstream|getbytes|"
    r"requestwith|openconnection|removeuserinfo|forbiddenurl|create|read|load)",
    re.IGNORECASE,
)
INTERESTING_SIGNATURE_RE = re.compile(
    r"(HttpServletRequest|UploadedFile|URL|InputStream|byte\[\]|String\[\]|Callable<byte\[\]>|Parameters)",
    re.IGNORECASE,
)


def read_csv_rows(path):
    with open(path, newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def read_json(path):
    with open(path, encoding="utf-8") as handle:
        return json.load(handle)


def api_key(row):
    return (
        row.get("package", ""),
        row.get("clazz", ""),
        row.get("func", ""),
        row.get("full_signature", ""),
    )


def api_label_key(row):
    return (
        row.get("package", ""),
        row.get("class", ""),
        row.get("method", ""),
        row.get("signature", ""),
    )


def format_api(row):
    package = row.get("package", "")
    clazz = row.get("clazz", row.get("class", ""))
    func = row.get("func", row.get("method", ""))
    signature = row.get("full_signature", row.get("signature", ""))
    return f"{package}.{clazz}.{func} :: {signature}"


def is_interesting_internal(row):
    haystack = " ".join(
        [
            row.get("func", ""),
            row.get("full_signature", ""),
            row.get("return_type", ""),
            row.get("doc", ""),
        ]
    )
    return bool(INTERESTING_FUNC_RE.search(haystack) or INTERESTING_SIGNATURE_RE.search(haystack))


def classify_risk(candidate_count, llm_sources, interesting_internal_count):
    if llm_sources == 0 and interesting_internal_count > 0:
        return "high"
    if candidate_count == 0:
        return "high"
    return "medium"


def build_case_summary(case_id, smoke_root, iris_root):
    case_root = smoke_root / case_id
    result = read_json(case_root / "result.json")
    project_slug = result["project_slug"]
    query_id = result["query_id"]

    raw_rows = read_csv_rows(case_root / "iris_output" / "fetch_external_apis" / "results.csv")
    candidate_rows = read_csv_rows(case_root / "iris_output" / "analysis" / "common" / "candidate_apis.csv")
    source_rows = read_json(next((case_root / "iris_output" / "analysis").glob("cwe-*/llm_labelled_source_apis.json")))
    sink_rows = read_json(next((case_root / "iris_output" / "analysis").glob("cwe-*/llm_labelled_sink_apis.json")))
    taint_rows = read_json(next((case_root / "iris_output" / "analysis").glob("cwe-*/llm_labelled_taint_prop_apis.json")))

    package_names_path = iris_root / "data" / "package-names" / f"{project_slug}.txt"
    internal_packages = {
        line.strip()
        for line in package_names_path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    }

    raw_unique = {}
    for row in raw_rows:
        raw_unique.setdefault(api_key(row), row)

    candidate_unique = {}
    for row in candidate_rows:
        candidate_unique.setdefault(api_key(row), row)

    internal_unique = [row for row in raw_unique.values() if row.get("package", "") in internal_packages]
    external_unique = [row for row in raw_unique.values() if row.get("package", "") not in internal_packages]
    interesting_internal = [row for row in internal_unique if is_interesting_internal(row)]

    labelled_sources = {api_label_key(row) for row in source_rows}
    labelled_sinks = {api_label_key(row) for row in sink_rows}
    labelled_taint = {api_label_key(row) for row in taint_rows}

    notes = []
    if len(source_rows) == 0:
        notes.append("llm_sources=0")
    if interesting_internal:
        notes.append("internal_wrapper_candidates_present")
    if len(candidate_rows) == 0:
        notes.append("stage3_received_empty_candidate_set")

    return {
        "case_id": case_id,
        "project_slug": project_slug,
        "query_id": query_id,
        "raw_total_rows": len(raw_rows),
        "raw_unique_apis": len(raw_unique),
        "internal_unique_apis": len(internal_unique),
        "external_unique_apis": len(external_unique),
        "candidate_apis": len(candidate_unique),
        "llm_sources": len(labelled_sources),
        "llm_sinks": len(labelled_sinks),
        "llm_taint_propagators": len(labelled_taint),
        "interesting_internal_count": len(interesting_internal),
        "candidate_selection_risk": classify_risk(
            len(candidate_unique),
            len(labelled_sources),
            len(interesting_internal),
        ),
        "candidate_sample": [format_api(row) for row in list(candidate_unique.values())[:12]],
        "interesting_internal_sample": [format_api(row) for row in interesting_internal[:12]],
        "labelled_sink_sample": [format_api(row) for row in sink_rows[:8]],
        "labelled_taint_sample": [format_api(row) for row in taint_rows[:8]],
        "notes": notes,
    }


def write_summary_tsv(path, diagnostic_run_id, smoke_run_id, summaries):
    fieldnames = [
        "diagnostic_run_id",
        "smoke_run_id",
        "case_id",
        "project_slug",
        "query_id",
        "raw_total_rows",
        "raw_unique_apis",
        "internal_unique_apis",
        "external_unique_apis",
        "candidate_apis",
        "llm_sources",
        "llm_sinks",
        "llm_taint_propagators",
        "interesting_internal_count",
        "candidate_selection_risk",
        "notes",
    ]
    with open(path, "w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, delimiter="\t")
        writer.writeheader()
        for summary in summaries:
            row = {
                "diagnostic_run_id": diagnostic_run_id,
                "smoke_run_id": smoke_run_id,
                **{key: summary[key] for key in fieldnames if key not in {"diagnostic_run_id", "smoke_run_id", "notes"}},
                "notes": "; ".join(summary["notes"]),
            }
            writer.writerow(row)


def write_markdown(path, diagnostic_run_id, smoke_run_id, summaries):
    lines = [
        "# IRIS Candidate Selection Baseline Diagnosis",
        "",
        f"- `diagnostic_run_id`: `{diagnostic_run_id}`",
        f"- `smoke_run_id`: `{smoke_run_id}`",
        "",
        "这份记录只描述 `OFFICIALSMOKE01` 的 baseline 诊断，不包含任何能力改动。",
        "",
    ]
    for summary in summaries:
        lines.extend(
            [
                f"## {summary['case_id']}",
                "",
                f"- `project_slug`: `{summary['project_slug']}`",
                f"- `query_id`: `{summary['query_id']}`",
                f"- `raw_unique_apis`: `{summary['raw_unique_apis']}`",
                f"- `internal_unique_apis`: `{summary['internal_unique_apis']}`",
                f"- `candidate_apis`: `{summary['candidate_apis']}`",
                f"- `llm_sources`: `{summary['llm_sources']}`",
                f"- `llm_sinks`: `{summary['llm_sinks']}`",
                f"- `llm_taint_propagators`: `{summary['llm_taint_propagators']}`",
                f"- `interesting_internal_count`: `{summary['interesting_internal_count']}`",
                f"- `candidate_selection_risk`: `{summary['candidate_selection_risk']}`",
                "",
                "Stage 3 实际候选样本：",
                "",
            ]
        )
        for item in summary["candidate_sample"]:
            lines.append(f"- `{item}`")
        lines.extend(["", "被 internal/external 包过滤挡掉的关键内部 API 样本：", ""])
        for item in summary["interesting_internal_sample"]:
            lines.append(f"- `{item}`")
        lines.extend(["", "已标注 sink 样本：", ""])
        for item in summary["labelled_sink_sample"]:
            lines.append(f"- `{item}`")
        lines.extend(["", "已标注 taint-propagator 样本：", ""])
        for item in summary["labelled_taint_sample"]:
            lines.append(f"- `{item}`")
        lines.extend(["", f"备注：`{'; '.join(summary['notes']) or 'none'}`", ""])

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--smoke-run-id", default="OFFICIALSMOKE01")
    parser.add_argument("--diagnostic-run-id", default="BASELINE_CANDSEL_DIAG01")
    parser.add_argument("--workspace-root", default=".")
    parser.add_argument("--iris-root", default=os.getenv("IRIS_ROOT", "/tmp/iris-v2"))
    parser.add_argument("--cases", nargs="*", default=DEFAULT_CASES)
    args = parser.parse_args()

    workspace_root = Path(args.workspace_root).resolve()
    smoke_root = workspace_root / "artifacts" / "iris_smoke" / args.smoke_run_id
    iris_root = Path(args.iris_root).resolve()
    output_root = workspace_root / "artifacts" / "iris_candidate_validation" / args.diagnostic_run_id
    output_root.mkdir(parents=True, exist_ok=True)

    summaries = [build_case_summary(case_id, smoke_root, iris_root) for case_id in args.cases]
    write_summary_tsv(output_root / "summary.tsv", args.diagnostic_run_id, args.smoke_run_id, summaries)
    write_markdown(output_root / "README.md", args.diagnostic_run_id, args.smoke_run_id, summaries)

    for summary in summaries:
        target = output_root / f"{summary['case_id']}.json"
        target.write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
