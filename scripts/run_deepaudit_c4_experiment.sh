#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/deepaudit_prepare_and_preflight.sh"

ARTIFACT_ROOT="${DEEPAUDIT_C4_ARTIFACT_ROOT:-$REPO_ROOT/artifacts/deepaudit_diagnosis}"
SHARED_INPUT_DIR="${DEEPAUDIT_C4_SHARED_INPUT_DIR:-/tmp/deepaudit/diagnosis_inputs_c4}"
LOCAL_INPUT_WORKDIR="${DEEPAUDIT_C4_LOCAL_INPUT_WORKDIR:-/tmp/deepaudit_diagnosis_inputs_c4}"
RUN_ID="${DEEPAUDIT_C4_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
RUN_DIR="$ARTIFACT_ROOT/$RUN_ID"
EXPERIMENT_ID="C4-PT-PY-REPO-CVE-2024-32982-VULN"
CASE_ID="PT-PY-REPO-CVE-2024-32982-VULN"
DIAG_EMAIL="${DEEPAUDIT_C4_EMAIL:-deepaudit-diagnosis@example.com}"
DIAG_PASSWORD="${DEEPAUDIT_C4_PASSWORD:-DeepAuditDiagnosis123!}"
DIAG_FULL_NAME="${DEEPAUDIT_C4_FULL_NAME:-DeepAudit Diagnosis}"
POLL_INTERVAL_SECONDS="${DEEPAUDIT_C4_POLL_INTERVAL:-10}"
TASK_MAX_ITERATIONS="${DEEPAUDIT_C4_MAX_ITERATIONS:-12}"
TASK_TIMEOUT_SECONDS="${DEEPAUDIT_C4_TASK_TIMEOUT:-1200}"
POLL_LIMIT_SECONDS="${DEEPAUDIT_C4_POLL_LIMIT:-900}"
TARGET_VULN="path_traversal"

TOKEN=""
PROJECT_ID=""
TASK_ID=""

SUBSET_FILES=(
  "repo/litestar/__init__.py"
  "repo/litestar/file_system.py"
  "repo/litestar/response/__init__.py"
  "repo/litestar/response/file.py"
  "repo/litestar/static_files/__init__.py"
  "repo/litestar/static_files/base.py"
  "repo/litestar/static_files/config.py"
)

usage() {
  cat <<'EOF'
Usage:
  scripts/run_deepaudit_c4_experiment.sh run
  scripts/run_deepaudit_c4_experiment.sh prepare-inputs
  scripts/run_deepaudit_c4_experiment.sh cleanup-inputs
EOF
  print_network_context_notice
}

ensure_dirs() {
  mkdir -p "$RUN_DIR"
  mkdir -p "$SHARED_INPUT_DIR"
  mkdir -p "$LOCAL_INPUT_WORKDIR"
}

write_run_manifest() {
  load_env_source
  python3 - "$RUN_DIR/run_manifest.json" "$BACKEND_URL" "$FRONTEND_URL" "$SHARED_INPUT_DIR" "$POLL_INTERVAL_SECONDS" "$LLM_PROVIDER" "$LLM_MODEL" "$LLM_BASE_URL" "$TASK_MAX_ITERATIONS" "$TASK_TIMEOUT_SECONDS" "$POLL_LIMIT_SECONDS" <<'PY'
import json
import sys

output_path, backend_url, frontend_url, shared_input_dir, poll_interval_seconds, llm_provider, llm_model, llm_base_url, max_iterations, timeout_seconds, poll_limit_seconds = sys.argv[1:]
payload = {
    "run_id": output_path.split("/")[-2],
    "backend_url": backend_url,
    "frontend_url": frontend_url,
    "shared_input_dir": shared_input_dir,
    "poll_interval_seconds": int(poll_interval_seconds),
    "llm_provider": llm_provider,
    "llm_model": llm_model,
    "llm_base_url": llm_base_url,
    "experiments": ["C4-PT-PY-REPO-CVE-2024-32982-VULN"],
    "max_iterations": int(max_iterations),
    "task_timeout_seconds": int(timeout_seconds),
    "poll_limit_seconds": int(poll_limit_seconds),
}
with open(output_path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
PY
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

prepare_input() {
  local source_root="$REPO_ROOT/datasets/real_world/PT-PY-REPO-CVE-2024-32982-VULN"
  local local_case_dir="$LOCAL_INPUT_WORKDIR/$EXPERIMENT_ID"
  local shared_zip="$SHARED_INPUT_DIR/$EXPERIMENT_ID.zip"
  local relative_path

  rm -rf "$local_case_dir"
  mkdir -p "$local_case_dir"

  for relative_path in "${SUBSET_FILES[@]}"; do
    mkdir -p "$local_case_dir/$(dirname "$relative_path")"
    cp "$source_root/$relative_path" "$local_case_dir/$relative_path"
  done

  rm -f "$shared_zip"
  zip_dir "$local_case_dir" "$shared_zip"
}

prepare_inputs() {
  require_commands
  ensure_dirs
  log "Preparing curated subset input for $EXPERIMENT_ID"
  prepare_input
}

cleanup_inputs() {
  rm -rf "$LOCAL_INPUT_WORKDIR"
  rm -rf "$SHARED_INPUT_DIR"
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

register_or_login_diag_user() {
  PREFLIGHT_EMAIL="$DIAG_EMAIL"
  PREFLIGHT_PASSWORD="$DIAG_PASSWORD"
  PREFLIGHT_FULL_NAME="$DIAG_FULL_NAME"
  register_user
  login_user
}

write_case_meta() {
  local case_dir="$1"
  python3 - "$case_dir/case_meta.json" "$SHARED_INPUT_DIR/$EXPERIMENT_ID.zip" "$TASK_MAX_ITERATIONS" "$TASK_TIMEOUT_SECONDS" "$POLL_LIMIT_SECONDS" <<'PY'
import json
import sys

output_path, shared_zip, max_iterations, timeout_seconds, poll_limit_seconds = sys.argv[1:]
subset_files = [
    "repo/litestar/__init__.py",
    "repo/litestar/file_system.py",
    "repo/litestar/response/__init__.py",
    "repo/litestar/response/file.py",
    "repo/litestar/static_files/__init__.py",
    "repo/litestar/static_files/base.py",
    "repo/litestar/static_files/config.py",
]
payload = {
    "experiment_id": "C4-PT-PY-REPO-CVE-2024-32982-VULN",
    "case_id": "PT-PY-REPO-CVE-2024-32982-VULN",
    "description": "C4 人工裁剪子集 repo，无 target_files",
    "run_class": "diagnostic only",
    "kind": "agent_task",
    "shared_zip": shared_zip,
    "target_files": None,
    "subset_files": subset_files,
    "max_iterations": int(max_iterations),
    "task_timeout_seconds": int(timeout_seconds),
    "poll_limit_seconds": int(poll_limit_seconds),
}
with open(output_path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, ensure_ascii=False, indent=2)
PY
}

create_case_project() {
  local case_dir="$1"
  local body pair code file
  body="$(cat <<EOF
{"name":"$EXPERIMENT_ID","source_type":"zip","repository_type":"other","description":"DeepAudit diagnosis experiment $EXPERIMENT_ID for $CASE_ID","default_branch":"main","programming_languages":["python"]}
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
  local zip_path="$SHARED_INPUT_DIR/$EXPERIMENT_ID.zip"
  local output_file code
  output_file="$(mktemp)"
  code="$(curl -sS -o "$output_file" -w '%{http_code}' \
    -X POST "$BACKEND_URL/api/v1/projects/$PROJECT_ID/zip" \
    -H "Authorization: Bearer $TOKEN" \
    -F "file=@$zip_path")" || return 1
  copy_response_to_case "$case_dir" "upload_zip" "$output_file"
  [[ "$code" == "200" ]] || return 1
  local metadata_code
  metadata_code="$(fetch_case_endpoint "$case_dir" "zip_metadata" "$BACKEND_URL/api/v1/projects/$PROJECT_ID/zip")" || return 1
  [[ "$metadata_code" == "200" ]] || return 1
}

create_case_task() {
  local case_dir="$1"
  local body pair code file
  body="$(python3 - "$PROJECT_ID" "$TASK_MAX_ITERATIONS" "$TASK_TIMEOUT_SECONDS" <<'PY'
import json
import sys

project_id, max_iterations, timeout_seconds = sys.argv[1:]
payload = {
    "project_id": project_id,
    "name": "C4-PT-PY-REPO-CVE-2024-32982-VULN task",
    "description": "Diagnosis C4 curated subset repo for PT-PY-REPO-CVE-2024-32982-VULN",
    "target_vulnerabilities": ["path_traversal"],
    "verification_level": "analysis_only",
    "max_iterations": int(max_iterations),
    "timeout_seconds": int(timeout_seconds),
}
print(json.dumps(payload, ensure_ascii=True))
PY
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
  local elapsed=0
  local status=""
  local task_code=""

  while (( elapsed <= POLL_LIMIT_SECONDS )); do
    task_code="$(fetch_case_endpoint "$case_dir" "task_object" "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID" || true)"
    fetch_case_endpoint "$case_dir" "task_summary" "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/summary" >/dev/null || true
    fetch_case_endpoint "$case_dir" "task_findings" "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/findings" >/dev/null || true
    fetch_case_endpoint "$case_dir" "task_events" "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/events" >/dev/null || true

    if [[ "$task_code" == "200" ]]; then
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

write_case_metrics() {
  local case_dir="$1"
  python3 - "$case_dir" <<'PY'
import json
import os
import sys

case_dir = sys.argv[1]
task = {}
findings = []

task_object_path = os.path.join(case_dir, "task_object.json")
if os.path.exists(task_object_path):
    with open(task_object_path, "r", encoding="utf-8") as fh:
        task = json.load(fh)

findings_path = os.path.join(case_dir, "task_findings.json")
if os.path.exists(findings_path):
    with open(findings_path, "r", encoding="utf-8") as fh:
        findings = json.load(fh)

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

top = []
for item in findings[:3]:
    top.append({
        "title": item.get("title"),
        "severity": item.get("severity"),
        "file_path": item.get("file_path"),
        "vulnerability_type": item.get("vulnerability_type"),
        "confidence": item.get("confidence"),
    })

with open(os.path.join(case_dir, "failure_classification.txt"), "w", encoding="utf-8") as fh:
    fh.write(classification + "\n")

metrics = {
    "status": status,
    "classification": classification,
    "total_iterations": task.get("total_iterations"),
    "tool_calls_count": task.get("tool_calls_count"),
    "tokens_used": task.get("tokens_used"),
    "findings_count": task.get("findings_count"),
    "top_3_findings": top,
}
with open(os.path.join(case_dir, "metrics.json"), "w", encoding="utf-8") as fh:
    json.dump(metrics, fh, ensure_ascii=False, indent=2)
PY
}

write_summary() {
  local case_dir="$RUN_DIR/$EXPERIMENT_ID"
  python3 - "$RUN_DIR/summary.tsv" "$case_dir" <<'PY'
import json
import os
import sys

summary_path, case_dir = sys.argv[1:]

def read_text(path, default=""):
    if not os.path.exists(path):
        return default
    return open(path, "r", encoding="utf-8").read().strip()

metrics = {}
metrics_path = os.path.join(case_dir, "metrics.json")
if os.path.exists(metrics_path):
    with open(metrics_path, "r", encoding="utf-8") as fh:
        metrics = json.load(fh)

lines = [
    "experiment_id\tcase_id\trun_class\tstatus\tclassification\tproject_id\ttask_id\ttotal_iterations\ttool_calls_count\ttokens_used\tfindings_count",
    "\t".join([
        "C4-PT-PY-REPO-CVE-2024-32982-VULN",
        "PT-PY-REPO-CVE-2024-32982-VULN",
        "diagnostic only",
        read_text(os.path.join(case_dir, "task_status.txt"), "not_started"),
        read_text(os.path.join(case_dir, "failure_classification.txt"), "unknown"),
        read_text(os.path.join(case_dir, "project_id.txt")),
        read_text(os.path.join(case_dir, "task_id.txt")),
        "" if metrics.get("total_iterations") is None else str(metrics["total_iterations"]),
        "" if metrics.get("tool_calls_count") is None else str(metrics["tool_calls_count"]),
        "" if metrics.get("tokens_used") is None else str(metrics["tokens_used"]),
        "" if metrics.get("findings_count") is None else str(metrics["findings_count"]),
    ]),
]
with open(summary_path, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines) + "\n")
PY
}

write_observations() {
  local case_dir="$RUN_DIR/$EXPERIMENT_ID"
  python3 - "$RUN_DIR/observations.md" "$case_dir" <<'PY'
import json
import os
import sys

output_path, case_dir = sys.argv[1:]
meta = json.load(open(os.path.join(case_dir, "case_meta.json"), "r", encoding="utf-8"))
metrics = json.load(open(os.path.join(case_dir, "metrics.json"), "r", encoding="utf-8"))

lines = [
    "# DeepAudit C4 诊断实验观察",
    "",
    "## C4-PT-PY-REPO-CVE-2024-32982-VULN",
    "",
    f"- case_id: `{meta['case_id']}`",
    f"- kind: `{meta['kind']}`",
    f"- 运行类型: `{meta['run_class']}`",
    f"- 任务状态: `{metrics['status']}`",
    f"- 初步分类: `{metrics['classification']}`",
    f"- total_iterations: `{metrics['total_iterations']}`",
    f"- tool_calls_count: `{metrics['tool_calls_count']}`",
    f"- tokens_used: `{metrics['tokens_used']}`",
    f"- findings_count: `{metrics['findings_count']}`",
    "- subset_files:",
]
for path in meta["subset_files"]:
    lines.append(f"  - `{path}`")
if metrics.get("top_3_findings"):
    lines.append("- 前 3 条 finding:")
    for item in metrics["top_3_findings"]:
        lines.append(f"  - `{item.get('severity')}` | {item.get('title')}")
else:
    lines.append("- 前 3 条 finding: 无")

with open(output_path, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines) + "\n")
PY
}

run_experiment() {
  local case_run_dir="$RUN_DIR/$EXPERIMENT_ID"
  mkdir -p "$case_run_dir"
  write_case_meta "$case_run_dir"

  log "Running diagnosis experiment $EXPERIMENT_ID"
  if ! create_case_project "$case_run_dir"; then
    echo "project_creation_failure" >"$case_run_dir/failure_classification.txt"
    return
  fi
  if ! upload_case_zip "$case_run_dir"; then
    echo "zip_upload_failure" >"$case_run_dir/failure_classification.txt"
    return
  fi
  if ! create_case_task "$case_run_dir"; then
    echo "agent_task_creation_failure" >"$case_run_dir/failure_classification.txt"
    return
  fi
  poll_case_task "$case_run_dir"
  write_case_metrics "$case_run_dir"
}

run_all() {
  require_commands
  ensure_dirs
  write_run_manifest
  prepare_inputs
  RESULT_DIR="$RUN_DIR/_auth"
  RESULT_FILE="$RESULT_DIR/result.env"
  mkdir -p "$RESULT_DIR"
  : >"$RESULT_FILE"
  register_or_login_diag_user
  run_experiment
  write_summary
  write_observations
  log "C4 diagnosis artifacts written to $RUN_DIR"
}

main() {
  local command="${1:-run}"
  case "$command" in
    run)
      run_all
      ;;
    prepare-inputs)
      prepare_inputs
      ;;
    cleanup-inputs)
      cleanup_inputs
      ;;
    *)
      usage
      exit 2
      ;;
  esac
}

main "$@"
