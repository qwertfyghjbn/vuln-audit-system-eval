#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/deepaudit_prepare_and_preflight.sh"

ARTIFACT_ROOT="${DEEPAUDIT_BOUNDARY_ARTIFACT_ROOT:-$REPO_ROOT/artifacts/deepaudit_boundary_expansion}"
RUN_ID="${DEEPAUDIT_BOUNDARY_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
RUN_DIR="$ARTIFACT_ROOT/$RUN_ID"
BOUNDARY_EMAIL="${DEEPAUDIT_BOUNDARY_EMAIL:-deepaudit-boundary@example.com}"
BOUNDARY_PASSWORD="${DEEPAUDIT_BOUNDARY_PASSWORD:-DeepAuditBoundary123!}"
BOUNDARY_FULL_NAME="${DEEPAUDIT_BOUNDARY_FULL_NAME:-DeepAudit Boundary}"

RESULT_DIR=""
RESULT_FILE=""

SLOT_IDS=(
  "A-synthetic-PT-PY-FILE-001"
  "A-synthetic-SSRF-PY-FILE-001"
)

declare -A SLOT_CASE_ID=(
  ["A-synthetic-PT-PY-FILE-001"]="PT-PY-FILE-001"
  ["A-synthetic-SSRF-PY-FILE-001"]="SSRF-PY-FILE-001"
)

declare -A SLOT_TARGET_VULN=(
  ["A-synthetic-PT-PY-FILE-001"]="path_traversal"
  ["A-synthetic-SSRF-PY-FILE-001"]="ssrf"
)

declare -A SLOT_SOURCE_FILE=(
  ["A-synthetic-PT-PY-FILE-001"]="datasets/synthetic/PT-PY-FILE-001/app.py"
  ["A-synthetic-SSRF-PY-FILE-001"]="datasets/synthetic/SSRF-PY-FILE-001/app.py"
)

declare -A SLOT_DESCRIPTION=(
  ["A-synthetic-PT-PY-FILE-001"]="Boundary A：对 PT-PY-FILE-001 执行 instant analysis"
  ["A-synthetic-SSRF-PY-FILE-001"]="Boundary A：对 SSRF-PY-FILE-001 执行 instant analysis"
)

usage() {
  cat <<'EOF'
Usage:
  scripts/run_deepaudit_boundary_instant_slots.sh run <slot-id>
  scripts/run_deepaudit_boundary_instant_slots.sh run-all

Supported slot ids:
  A-synthetic-PT-PY-FILE-001
  A-synthetic-SSRF-PY-FILE-001
EOF
  print_network_context_notice
}

ensure_dirs() {
  mkdir -p "$RUN_DIR"
}

init_auth_artifacts() {
  RESULT_DIR="$RUN_DIR/_auth"
  RESULT_FILE="$RESULT_DIR/result.env"
  mkdir -p "$RESULT_DIR"
  : >"$RESULT_FILE"
}

write_run_manifest() {
  load_env_source
  python3 - "$RUN_DIR/run_manifest.json" "$RUN_ID" "$BACKEND_URL" "$FRONTEND_URL" "$LLM_PROVIDER" "$LLM_MODEL" "$LLM_BASE_URL" <<'PY'
import json
import sys

output_path, run_id, backend_url, frontend_url, llm_provider, llm_model, llm_base_url = sys.argv[1:]
payload = {
    "run_id": run_id,
    "backend_url": backend_url,
    "frontend_url": frontend_url,
    "llm_provider": llm_provider,
    "llm_model": llm_model,
    "llm_base_url": llm_base_url,
    "runbook_kind": "boundary_condition_instant_slot",
}
with open(output_path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
PY
}

copy_response_to_case() {
  local case_dir="$1"
  local name="$2"
  local source_file="$3"
  cp "$source_file" "$case_dir/$name.json"
}

write_slot_meta() {
  local case_dir="$1"
  local slot_id="$2"
  local case_id="${SLOT_CASE_ID[$slot_id]}"
  local source_file="${SLOT_SOURCE_FILE[$slot_id]}"
  local target_vuln="${SLOT_TARGET_VULN[$slot_id]}"

  python3 - "$case_dir/case_meta.json" "$slot_id" "$case_id" "$source_file" "$target_vuln" "${SLOT_DESCRIPTION[$slot_id]}" <<'PY'
import json
import sys

output_path, slot_id, case_id, source_file, target_vuln, description = sys.argv[1:]
payload = {
    "experiment_id": slot_id,
    "case_id": case_id,
    "shape": "A",
    "layer": "synthetic",
    "run_class": "diagnostic only",
    "kind": "instant_analysis",
    "language": "python",
    "target_vulnerability": target_vuln,
    "source_file": source_file,
    "description": description,
}
with open(output_path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
PY
}

register_or_login_boundary_user() {
  PREFLIGHT_EMAIL="$BOUNDARY_EMAIL"
  PREFLIGHT_PASSWORD="$BOUNDARY_PASSWORD"
  PREFLIGHT_FULL_NAME="$BOUNDARY_FULL_NAME"
  register_user
  login_user
}

run_instant_slot() {
  local slot_id="$1"
  local case_run_dir="$RUN_DIR/$slot_id"
  local code_file="$REPO_ROOT/${SLOT_SOURCE_FILE[$slot_id]}"
  local body pair code file started_at finished_at

  mkdir -p "$case_run_dir"
  write_slot_meta "$case_run_dir" "$slot_id"
  log "Running boundary instant slot $slot_id"

  started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  body="$(python3 - "$code_file" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    code = fh.read()

payload = {
    "code": code,
    "language": "python",
}
print(json.dumps(payload, ensure_ascii=False))
PY
)"

  pair="$(http_json POST "$BACKEND_URL/api/v1/scan/instant" "$body")" || {
    echo "runtime_failure" >"$case_run_dir/task_status.txt"
    echo "instant_analysis_failure" >"$case_run_dir/failure_classification.txt"
    return 1
  }
  finished_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  code="${pair%% *}"
  file="${pair#* }"
  copy_response_to_case "$case_run_dir" "instant_analysis" "$file"
  printf '%s\n' "$code" >"$case_run_dir/http_status.txt"

  python3 - "$case_run_dir" "$started_at" "$finished_at" <<'PY'
import json
import os
import sys
from datetime import datetime

case_dir, started_at, finished_at = sys.argv[1:]
path = os.path.join(case_dir, "instant_analysis.json")
with open(path, "r", encoding="utf-8") as fh:
    data = json.load(fh)

findings = []
if isinstance(data, dict):
    for key in ("findings", "issues", "results", "data"):
        if isinstance(data.get(key), list):
            findings = data[key]
            break

def normalize_item(item):
    if isinstance(item, dict):
        return {
            "title": item.get("title") or item.get("name") or item.get("type"),
            "severity": item.get("severity"),
            "file_path": item.get("file_path"),
            "vulnerability_type": item.get("vulnerability_type") or item.get("rule_code"),
            "confidence": item.get("confidence"),
        }
    return {"raw": item}

def parse_ts(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00"))

wall_clock_seconds = round((parse_ts(finished_at) - parse_ts(started_at)).total_seconds(), 3)
status = "completed"
classification = "completed_no_findings"
if findings:
    classification = "completed_with_findings"

with open(os.path.join(case_dir, "task_status.txt"), "w", encoding="utf-8") as fh:
    fh.write(status + "\n")
with open(os.path.join(case_dir, "failure_classification.txt"), "w", encoding="utf-8") as fh:
    fh.write(classification + "\n")

metrics = {
    "status": status,
    "classification": classification,
    "http_status": open(os.path.join(case_dir, "http_status.txt"), "r", encoding="utf-8").read().strip(),
    "wall_clock_seconds": wall_clock_seconds,
    "findings_count": len(findings),
    "top_3_findings": [normalize_item(item) for item in findings[:3]],
    "raw_keys": sorted(data.keys()) if isinstance(data, dict) else [],
}
with open(os.path.join(case_dir, "metrics.json"), "w", encoding="utf-8") as fh:
    json.dump(metrics, fh, ensure_ascii=False, indent=2)
PY
}

write_boundary_matrix() {
  local summary_file="$RUN_DIR/boundary_matrix.tsv"
  python3 - "$RUN_DIR" "$summary_file" <<'PY'
import json
import os
import sys

run_dir = sys.argv[1]
summary_file = sys.argv[2]
lines = [
    "experiment_id\tshape\tlayer\tcase_id\trun_class\tconstraint_summary\tstatus\ttotal_iterations\ttool_calls_count\ttokens_used\twall_clock_seconds\tfindings_count\ttop_3_findings"
]

def read_json(path):
    if not os.path.exists(path):
        return {}
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)

for slot_id in sorted(os.listdir(run_dir)):
    case_dir = os.path.join(run_dir, slot_id)
    if not os.path.isdir(case_dir) or slot_id.startswith("_"):
        continue
    meta = read_json(os.path.join(case_dir, "case_meta.json"))
    metrics = read_json(os.path.join(case_dir, "metrics.json"))
    if not meta or not metrics:
        continue
    top3 = json.dumps(metrics.get("top_3_findings", []), ensure_ascii=False)
    row = [
        meta.get("experiment_id", slot_id),
        meta.get("shape", ""),
        meta.get("layer", ""),
        meta.get("case_id", ""),
        meta.get("run_class", ""),
        meta.get("description", ""),
        metrics.get("status") or "",
        "" if metrics.get("total_iterations") is None else str(metrics["total_iterations"]),
        "" if metrics.get("tool_calls_count") is None else str(metrics["tool_calls_count"]),
        "" if metrics.get("tokens_used") is None else str(metrics["tokens_used"]),
        "" if metrics.get("wall_clock_seconds") is None else str(metrics["wall_clock_seconds"]),
        "" if metrics.get("findings_count") is None else str(metrics["findings_count"]),
        top3,
    ]
    lines.append("\t".join(row))

with open(summary_file, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines) + "\n")
PY
}

run_one() {
  local slot_id="$1"
  if [[ -z "${SLOT_CASE_ID[$slot_id]:-}" ]]; then
    echo "Unsupported slot id: $slot_id" >&2
    exit 2
  fi
  require_commands
  ensure_dirs
  init_auth_artifacts
  write_run_manifest
  register_or_login_boundary_user
  run_instant_slot "$slot_id"
  write_boundary_matrix
  log "Boundary instant slot artifacts written to $RUN_DIR"
}

run_all() {
  local slot_id
  require_commands
  ensure_dirs
  init_auth_artifacts
  write_run_manifest
  register_or_login_boundary_user
  for slot_id in "${SLOT_IDS[@]}"; do
    run_instant_slot "$slot_id"
  done
  write_boundary_matrix
  log "Boundary instant slot artifacts written to $RUN_DIR"
}

main() {
  local command="${1:-}"
  case "$command" in
    run)
      if [[ $# -ne 2 ]]; then
        usage
        exit 2
      fi
      run_one "$2"
      ;;
    run-all)
      run_all
      ;;
    *)
      usage
      exit 2
      ;;
  esac
}

main "$@"
