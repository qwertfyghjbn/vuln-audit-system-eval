#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/deepaudit_prepare_and_preflight.sh"

ARTIFACT_ROOT="${DEEPAUDIT_BOUNDARY_ARTIFACT_ROOT:-$REPO_ROOT/artifacts/deepaudit_boundary_expansion}"
SHARED_INPUT_DIR="${DEEPAUDIT_BOUNDARY_SHARED_INPUT_DIR:-/tmp/deepaudit/boundary_inputs}"
LOCAL_INPUT_WORKDIR="${DEEPAUDIT_BOUNDARY_LOCAL_INPUT_WORKDIR:-/tmp/deepaudit_boundary_inputs}"
RUN_ID="${DEEPAUDIT_BOUNDARY_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
RUN_DIR="$ARTIFACT_ROOT/$RUN_ID"
BOUNDARY_EMAIL="${DEEPAUDIT_BOUNDARY_EMAIL:-deepaudit-boundary@example.com}"
BOUNDARY_PASSWORD="${DEEPAUDIT_BOUNDARY_PASSWORD:-DeepAuditBoundary123!}"
BOUNDARY_FULL_NAME="${DEEPAUDIT_BOUNDARY_FULL_NAME:-DeepAudit Boundary}"
POLL_INTERVAL_SECONDS="${DEEPAUDIT_BOUNDARY_POLL_INTERVAL:-10}"

SLOT_IDS=(
  "D-synthetic-PT-PY-REPO-001"
)

declare -A SLOT_CASE_ID=(
  ["D-synthetic-PT-PY-REPO-001"]="PT-PY-REPO-001"
)

declare -A SLOT_CASE_DIR=(
  ["D-synthetic-PT-PY-REPO-001"]="datasets/synthetic/PT-PY-REPO-001"
)

declare -A SLOT_INPUT_PATH=(
  ["D-synthetic-PT-PY-REPO-001"]="src"
)

declare -A SLOT_TARGET_VULN=(
  ["D-synthetic-PT-PY-REPO-001"]="path_traversal"
)

declare -A SLOT_RUN_CLASS=(
  ["D-synthetic-PT-PY-REPO-001"]="baseline-like"
)

declare -A SLOT_DESCRIPTION=(
  ["D-synthetic-PT-PY-REPO-001"]="Boundary D：完整 synthetic repo，无 target_files"
)

declare -A SLOT_MAX_ITERATIONS=(
  ["D-synthetic-PT-PY-REPO-001"]="8"
)

declare -A SLOT_TIMEOUT_SECONDS=(
  ["D-synthetic-PT-PY-REPO-001"]="900"
)

declare -A SLOT_POLL_LIMITS=(
  ["D-synthetic-PT-PY-REPO-001"]="600"
)

TOKEN=""
PROJECT_ID=""
TASK_ID=""
RESULT_DIR=""
RESULT_FILE=""

usage() {
  cat <<'EOF'
Usage:
  scripts/run_deepaudit_boundary_agent_slots.sh run <slot-id>
  scripts/run_deepaudit_boundary_agent_slots.sh run-all

Supported slot ids:
  D-synthetic-PT-PY-REPO-001
EOF
  print_network_context_notice
}

ensure_dirs() {
  mkdir -p "$RUN_DIR"
  mkdir -p "$SHARED_INPUT_DIR"
  mkdir -p "$LOCAL_INPUT_WORKDIR"
}

init_auth_artifacts() {
  RESULT_DIR="$RUN_DIR/_auth"
  RESULT_FILE="$RESULT_DIR/result.env"
  mkdir -p "$RESULT_DIR"
  : >"$RESULT_FILE"
}

write_run_manifest() {
  load_env_source
  cat >"$RUN_DIR/run_manifest.json" <<EOF
{
  "run_id": "$RUN_ID",
  "backend_url": "$BACKEND_URL",
  "frontend_url": "$FRONTEND_URL",
  "llm_provider": "$LLM_PROVIDER",
  "llm_model": "$LLM_MODEL",
  "llm_base_url": "$LLM_BASE_URL",
  "poll_interval_seconds": $POLL_INTERVAL_SECONDS,
  "runbook_kind": "boundary_condition_agent_slot"
}
EOF
}

zip_dir() {
  local source_dir="$1"
  local zip_path="$2"
  if command -v zip >/dev/null 2>&1; then
    (
      cd "$source_dir"
      zip -qr "$zip_path" .
    )
  else
    python3 - "$source_dir" "$zip_path" <<'PY'
import os
import sys
import zipfile

source_dir = sys.argv[1]
zip_path = sys.argv[2]

with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for current_root, _, files in os.walk(source_dir):
        for name in files:
            full_path = os.path.join(current_root, name)
            arcname = os.path.relpath(full_path, source_dir)
            zf.write(full_path, arcname)
PY
  fi
}

prepare_slot_input() {
  local slot_id="$1"
  local case_dir="$REPO_ROOT/${SLOT_CASE_DIR[$slot_id]}"
  local input_path="${SLOT_INPUT_PATH[$slot_id]}"
  local local_case_dir="$LOCAL_INPUT_WORKDIR/$slot_id"
  local shared_zip="$SHARED_INPUT_DIR/$slot_id.zip"

  rm -rf "$local_case_dir"
  mkdir -p "$local_case_dir"
  cp -r "$case_dir/$input_path" "$local_case_dir/"
  rm -f "$shared_zip"
  zip_dir "$local_case_dir" "$shared_zip"
}

copy_response_to_case() {
  local case_dir="$1"
  local name="$2"
  local source_file="$3"
  cp "$source_file" "$case_dir/$name.json"
}

fetch_case_endpoint() {
  local case_dir="$1"
  local name="$2"
  local url="$3"
  local pair code file
  pair="$(http_json GET "$url" 2>"$case_dir/$name.stderr.log")" || return 1
  code="${pair%% *}"
  file="${pair#* }"
  copy_response_to_case "$case_dir" "$name" "$file"
  printf '%s\n' "$code"
}

register_or_login_boundary_user() {
  PREFLIGHT_EMAIL="$BOUNDARY_EMAIL"
  PREFLIGHT_PASSWORD="$BOUNDARY_PASSWORD"
  PREFLIGHT_FULL_NAME="$BOUNDARY_FULL_NAME"
  register_user
  login_user
}

write_slot_meta() {
  local case_dir="$1"
  local slot_id="$2"
  cat >"$case_dir/case_meta.json" <<EOF
{
  "experiment_id": "$slot_id",
  "case_id": "${SLOT_CASE_ID[$slot_id]}",
  "shape": "D",
  "layer": "synthetic",
  "run_class": "${SLOT_RUN_CLASS[$slot_id]}",
  "kind": "agent_task",
  "target_vulnerability": "${SLOT_TARGET_VULN[$slot_id]}",
  "source_case_dir": "${SLOT_CASE_DIR[$slot_id]}",
  "clean_input_path": "${SLOT_INPUT_PATH[$slot_id]}",
  "shared_zip": "$SHARED_INPUT_DIR/$slot_id.zip",
  "max_iterations": ${SLOT_MAX_ITERATIONS[$slot_id]},
  "task_timeout_seconds": ${SLOT_TIMEOUT_SECONDS[$slot_id]},
  "poll_limit_seconds": ${SLOT_POLL_LIMITS[$slot_id]},
  "target_files": null,
  "description": "${SLOT_DESCRIPTION[$slot_id]}"
}
EOF
}

create_case_project() {
  local case_dir="$1"
  local slot_id="$2"
  local body pair code file
  body="$(cat <<EOF
{"name":"$slot_id","source_type":"zip","repository_type":"other","description":"DeepAudit boundary slot $slot_id","default_branch":"main","programming_languages":["python"]}
EOF
)"
  pair="$(http_json POST "$BACKEND_URL/api/v1/projects/" "$body")" || return 1
  code="${pair%% *}"
  file="${pair#* }"
  copy_response_to_case "$case_dir" "create_project" "$file"
  [[ "$code" == "200" ]] || return 1
  PROJECT_ID="$(extract_json_field "$file" "id")"
  printf '%s\n' "$PROJECT_ID" >"$case_dir/project_id.txt"
}

upload_case_zip() {
  local case_dir="$1"
  local slot_id="$2"
  local zip_path="$SHARED_INPUT_DIR/$slot_id.zip"
  local output_file code meta_code
  output_file="$(mktemp)"
  code="$(curl -sS -o "$output_file" -w '%{http_code}' \
    -X POST "$BACKEND_URL/api/v1/projects/$PROJECT_ID/zip" \
    -H "Authorization: Bearer $TOKEN" \
    -F "file=@$zip_path")" || return 1
  copy_response_to_case "$case_dir" "upload_zip" "$output_file"
  [[ "$code" == "200" ]] || return 1
  meta_code="$(fetch_case_endpoint "$case_dir" "zip_metadata" "$BACKEND_URL/api/v1/projects/$PROJECT_ID/zip")" || return 1
  [[ "$meta_code" == "200" ]] || return 1
}

create_case_task() {
  local case_dir="$1"
  local slot_id="$2"
  local body pair code file
  body="$(cat <<EOF
{"project_id":"$PROJECT_ID","name":"$slot_id task","description":"Boundary run $slot_id","target_vulnerabilities":["${SLOT_TARGET_VULN[$slot_id]}"],"verification_level":"analysis_only","max_iterations":${SLOT_MAX_ITERATIONS[$slot_id]},"timeout_seconds":${SLOT_TIMEOUT_SECONDS[$slot_id]}}
EOF
)"
  pair="$(http_json POST "$BACKEND_URL/api/v1/agent-tasks/" "$body")" || return 1
  code="${pair%% *}"
  file="${pair#* }"
  copy_response_to_case "$case_dir" "create_task" "$file"
  [[ "$code" == "200" ]] || return 1
  TASK_ID="$(extract_json_field "$file" "id")"
  printf '%s\n' "$TASK_ID" >"$case_dir/task_id.txt"
}

poll_case_task() {
  local case_dir="$1"
  local slot_id="$2"
  local poll_limit="${SLOT_POLL_LIMITS[$slot_id]}"
  local elapsed=0
  local status=""
  while (( elapsed <= poll_limit )); do
    fetch_case_endpoint "$case_dir" "task_object" "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID" >/dev/null || true
    fetch_case_endpoint "$case_dir" "task_summary" "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/summary" >/dev/null || true
    fetch_case_endpoint "$case_dir" "task_findings" "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/findings" >/dev/null || true
    fetch_case_endpoint "$case_dir" "task_events" "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/events" >/dev/null || true
    if [[ -f "$case_dir/task_object.json" ]]; then
      status="$(python3 - "$case_dir/task_object.json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    data = json.load(fh)
print(data.get("status", "unknown"))
PY
)"
      printf '%s\n' "$status" >"$case_dir/task_status.txt"
      if [[ "$status" == "completed" || "$status" == "failed" || "$status" == "cancelled" ]]; then
        return 0
      fi
    fi
    sleep "$POLL_INTERVAL_SECONDS"
    elapsed=$((elapsed + POLL_INTERVAL_SECONDS))
  done
  printf 'timeout\n' >"$case_dir/task_status.txt"
}

write_case_outputs() {
  local case_dir="$1"
  python3 - "$case_dir" <<'PY'
import json
import os
import sys
from datetime import datetime

case_dir = sys.argv[1]

def read_json(path, default):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return default
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)

task = read_json(os.path.join(case_dir, "task_object.json"), {})
summary = read_json(os.path.join(case_dir, "task_summary.json"), {})
findings = read_json(os.path.join(case_dir, "task_findings.json"), [])

status = "unknown"
status_path = os.path.join(case_dir, "task_status.txt")
if os.path.exists(status_path):
    status = open(status_path, "r", encoding="utf-8").read().strip()

classification = "unknown"
if status == "completed" and (task.get("findings_count") or 0) > 0:
    classification = "completed_with_findings"
elif status == "completed":
    classification = "completed_no_findings"
elif status == "timeout" and (task.get("findings_count") or 0) > 0:
    classification = "timeout_with_partial_signal"
elif status == "timeout":
    classification = "timeout_no_findings"
elif status in {"failed", "cancelled"}:
    classification = "runtime_failure"

with open(os.path.join(case_dir, "failure_classification.txt"), "w", encoding="utf-8") as fh:
    fh.write(classification + "\n")

top = []
for item in findings[:3]:
    if isinstance(item, dict):
        top.append({
            "title": item.get("title"),
            "severity": item.get("severity"),
            "file_path": item.get("file_path"),
            "vulnerability_type": item.get("vulnerability_type"),
            "confidence": item.get("confidence"),
        })

wall_clock_seconds = summary.get("duration_seconds")
if wall_clock_seconds is None:
    started_at = task.get("started_at")
    completed_at = task.get("completed_at")
    if started_at and completed_at:
        start_dt = datetime.fromisoformat(started_at.replace("Z", "+00:00"))
        end_dt = datetime.fromisoformat(completed_at.replace("Z", "+00:00"))
        wall_clock_seconds = round((end_dt - start_dt).total_seconds(), 3)

metrics = {
    "status": status,
    "classification": classification,
    "total_iterations": task.get("total_iterations"),
    "tool_calls_count": task.get("tool_calls_count"),
    "tokens_used": task.get("tokens_used"),
    "wall_clock_seconds": wall_clock_seconds,
    "findings_count": task.get("findings_count"),
    "top_3_findings": top,
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
    row = [
        meta.get("experiment_id", slot_id),
        meta.get("shape", ""),
        meta.get("layer", ""),
        meta.get("case_id", ""),
        meta.get("run_class", ""),
        meta.get("description", ""),
        metrics.get("status", ""),
        "" if metrics.get("total_iterations") is None else str(metrics["total_iterations"]),
        "" if metrics.get("tool_calls_count") is None else str(metrics["tool_calls_count"]),
        "" if metrics.get("tokens_used") is None else str(metrics["tokens_used"]),
        "" if metrics.get("wall_clock_seconds") is None else str(metrics["wall_clock_seconds"]),
        "" if metrics.get("findings_count") is None else str(metrics["findings_count"]),
        json.dumps(metrics.get("top_3_findings", []), ensure_ascii=False),
    ]
    lines.append("\t".join(row))

with open(summary_file, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines) + "\n")
PY
}

run_one() {
  local slot_id="$1"
  local case_run_dir="$RUN_DIR/$slot_id"
  if [[ -z "${SLOT_CASE_ID[$slot_id]:-}" ]]; then
    echo "Unsupported slot id: $slot_id" >&2
    exit 2
  fi
  require_commands
  ensure_dirs
  init_auth_artifacts
  write_run_manifest
  prepare_slot_input "$slot_id"
  register_or_login_boundary_user
  mkdir -p "$case_run_dir"
  write_slot_meta "$case_run_dir" "$slot_id"
  log "Running boundary agent slot $slot_id"
  if ! create_case_project "$case_run_dir" "$slot_id"; then
    echo "project_creation_failure" >"$case_run_dir/failure_classification.txt"
    return 1
  fi
  if ! upload_case_zip "$case_run_dir" "$slot_id"; then
    echo "zip_upload_failure" >"$case_run_dir/failure_classification.txt"
    return 1
  fi
  if ! create_case_task "$case_run_dir" "$slot_id"; then
    echo "agent_task_creation_failure" >"$case_run_dir/failure_classification.txt"
    return 1
  fi
  poll_case_task "$case_run_dir" "$slot_id"
  write_case_outputs "$case_run_dir"
  write_boundary_matrix
  log "Boundary agent slot artifacts written to $RUN_DIR"
}

run_all() {
  local slot_id
  require_commands
  ensure_dirs
  init_auth_artifacts
  write_run_manifest
  register_or_login_boundary_user
  for slot_id in "${SLOT_IDS[@]}"; do
    prepare_slot_input "$slot_id"
    mkdir -p "$RUN_DIR/$slot_id"
    write_slot_meta "$RUN_DIR/$slot_id" "$slot_id"
    log "Running boundary agent slot $slot_id"
    create_case_project "$RUN_DIR/$slot_id" "$slot_id"
    upload_case_zip "$RUN_DIR/$slot_id" "$slot_id"
    create_case_task "$RUN_DIR/$slot_id" "$slot_id"
    poll_case_task "$RUN_DIR/$slot_id" "$slot_id"
    write_case_outputs "$RUN_DIR/$slot_id"
  done
  write_boundary_matrix
  log "Boundary agent slot artifacts written to $RUN_DIR"
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
