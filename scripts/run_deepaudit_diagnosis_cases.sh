#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/deepaudit_prepare_and_preflight.sh"

ARTIFACT_ROOT="${DEEPAUDIT_DIAG_ARTIFACT_ROOT:-$REPO_ROOT/artifacts/deepaudit_diagnosis}"
SHARED_INPUT_DIR="${DEEPAUDIT_DIAG_SHARED_INPUT_DIR:-/mnt/c/tmp/deepaudit/diagnosis_inputs}"
LOCAL_INPUT_WORKDIR="${DEEPAUDIT_DIAG_LOCAL_INPUT_WORKDIR:-/tmp/deepaudit_diagnosis_inputs}"
RUN_ID="${DEEPAUDIT_DIAG_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
RUN_DIR="$ARTIFACT_ROOT/$RUN_ID"
DIAG_EMAIL="${DEEPAUDIT_DIAG_EMAIL:-deepaudit-diagnosis@example.com}"
DIAG_PASSWORD="${DEEPAUDIT_DIAG_PASSWORD:-DeepAuditDiagnosis123!}"
DIAG_FULL_NAME="${DEEPAUDIT_DIAG_FULL_NAME:-DeepAudit Diagnosis}"
POLL_INTERVAL_SECONDS="${DEEPAUDIT_DIAG_POLL_INTERVAL:-10}"

EXPERIMENT_IDS=(
  "A2-PT-PY-FILE-001"
  "B2-PT-PY-REPO-001"
  "C3-PT-PY-REPO-CVE-2024-32982-VULN"
)

declare -A CASE_DIRS=(
  ["PT-PY-FILE-001"]="datasets/synthetic/PT-PY-FILE-001"
  ["PT-PY-REPO-001"]="datasets/synthetic/PT-PY-REPO-001"
  ["PT-PY-REPO-CVE-2024-32982-VULN"]="datasets/real_world/PT-PY-REPO-CVE-2024-32982-VULN"
)

declare -A CASE_MODES=(
  ["PT-PY-FILE-001"]="file"
  ["PT-PY-REPO-001"]="repo"
  ["PT-PY-REPO-CVE-2024-32982-VULN"]="repo"
)

declare -A CASE_INPUT_PATHS=(
  ["PT-PY-FILE-001"]="app.py"
  ["PT-PY-REPO-001"]="src"
  ["PT-PY-REPO-CVE-2024-32982-VULN"]="repo"
)

declare -A CASE_VULNS=(
  ["PT-PY-FILE-001"]="path_traversal"
  ["PT-PY-REPO-001"]="path_traversal"
  ["PT-PY-REPO-CVE-2024-32982-VULN"]="path_traversal"
)

declare -A EXP_CASE_ID=(
  ["A2-PT-PY-FILE-001"]="PT-PY-FILE-001"
  ["B2-PT-PY-REPO-001"]="PT-PY-REPO-001"
  ["C3-PT-PY-REPO-CVE-2024-32982-VULN"]="PT-PY-REPO-CVE-2024-32982-VULN"
)

declare -A EXP_RUN_CLASS=(
  ["A2-PT-PY-FILE-001"]="baseline-like"
  ["B2-PT-PY-REPO-001"]="diagnostic only"
  ["C3-PT-PY-REPO-CVE-2024-32982-VULN"]="diagnostic only"
)

declare -A EXP_DESCRIPTION=(
  ["A2-PT-PY-FILE-001"]="A2 提高预算，不改变任务形态"
  ["B2-PT-PY-REPO-001"]="B2 将 target_files 限制到目标路径文件"
  ["C3-PT-PY-REPO-CVE-2024-32982-VULN"]="C3 收窄到 static_files 相关文件"
)

declare -A EXP_MAX_ITERATIONS=(
  ["A2-PT-PY-FILE-001"]="24"
  ["B2-PT-PY-REPO-001"]="8"
  ["C3-PT-PY-REPO-CVE-2024-32982-VULN"]="8"
)

declare -A EXP_TASK_TIMEOUTS=(
  ["A2-PT-PY-FILE-001"]="1800"
  ["B2-PT-PY-REPO-001"]="900"
  ["C3-PT-PY-REPO-CVE-2024-32982-VULN"]="900"
)

declare -A EXP_POLL_LIMITS=(
  ["A2-PT-PY-FILE-001"]="900"
  ["B2-PT-PY-REPO-001"]="420"
  ["C3-PT-PY-REPO-CVE-2024-32982-VULN"]="480"
)

declare -A EXP_TARGET_FILES=(
  ["A2-PT-PY-FILE-001"]=""
  ["B2-PT-PY-REPO-001"]=$'src/routes/file_routes.py\nsrc/services/file_service.py\nsrc/utils/file_utils.py'
  ["C3-PT-PY-REPO-CVE-2024-32982-VULN"]=$'repo/litestar/static_files/__init__.py\nrepo/litestar/static_files/base.py\nrepo/litestar/static_files/config.py'
)

usage() {
  cat <<'EOF'
Usage:
  scripts/run_deepaudit_diagnosis_cases.sh run
  scripts/run_deepaudit_diagnosis_cases.sh prepare-inputs
  scripts/run_deepaudit_diagnosis_cases.sh cleanup-inputs

Commands:
  run             执行 A2 / B2 / C3 三个诊断实验并保存产物。
  prepare-inputs  仅准备诊断输入 ZIP。
  cleanup-inputs  清理本地和共享诊断输入。
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
  cat >"$RUN_DIR/run_manifest.json" <<EOF
{
  "run_id": "$RUN_ID",
  "backend_url": "$BACKEND_URL",
  "frontend_url": "$FRONTEND_URL",
  "shared_input_dir": "$SHARED_INPUT_DIR",
  "poll_interval_seconds": $POLL_INTERVAL_SECONDS,
  "llm_provider": "$LLM_PROVIDER",
  "llm_model": "$LLM_MODEL",
  "llm_base_url": "$LLM_BASE_URL",
  "experiments": [
    "A2-PT-PY-FILE-001",
    "B2-PT-PY-REPO-001",
    "C3-PT-PY-REPO-CVE-2024-32982-VULN"
  ]
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

prepare_case_input() {
  local case_id="$1"
  local case_dir="$REPO_ROOT/${CASE_DIRS[$case_id]}"
  local mode="${CASE_MODES[$case_id]}"
  local input_path="${CASE_INPUT_PATHS[$case_id]}"
  local local_case_dir="$LOCAL_INPUT_WORKDIR/$case_id"
  local shared_zip="$SHARED_INPUT_DIR/$case_id.zip"

  rm -rf "$local_case_dir"
  mkdir -p "$local_case_dir"

  if [[ "$mode" == "file" ]]; then
    cp "$case_dir/$input_path" "$local_case_dir/"
  else
    cp -r "$case_dir/$input_path" "$local_case_dir/"
  fi

  rm -f "$shared_zip"
  zip_dir "$local_case_dir" "$shared_zip"
}

prepare_inputs() {
  require_commands
  ensure_dirs
  local prepared_cases=()
  local experiment_id case_id
  for experiment_id in "${EXPERIMENT_IDS[@]}"; do
    case_id="${EXP_CASE_ID[$experiment_id]}"
    if [[ " ${prepared_cases[*]} " == *" $case_id "* ]]; then
      continue
    fi
    log "Preparing diagnostic input for $case_id"
    prepare_case_input "$case_id"
    prepared_cases+=("$case_id")
  done
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

create_case_project() {
  local case_dir="$1"
  local experiment_id="$2"
  local case_id="${EXP_CASE_ID[$experiment_id]}"
  local body pair code file
  body="$(cat <<EOF
{"name":"$experiment_id","source_type":"zip","repository_type":"other","description":"DeepAudit diagnosis experiment $experiment_id for $case_id","default_branch":"main","programming_languages":["python"]}
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
  local experiment_id="$2"
  local case_id="${EXP_CASE_ID[$experiment_id]}"
  local zip_path="$SHARED_INPUT_DIR/$case_id.zip"
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

json_array_from_lines() {
  local raw="${1:-}"
  python3 - "$raw" <<'PY'
import json
import sys

items = [line.rstrip("\n") for line in sys.argv[1].splitlines() if line.strip()]
print(json.dumps(items, ensure_ascii=True))
PY
}

create_case_task() {
  local case_dir="$1"
  local experiment_id="$2"
  local case_id="${EXP_CASE_ID[$experiment_id]}"
  local vuln="${CASE_VULNS[$case_id]}"
  local max_iterations="${EXP_MAX_ITERATIONS[$experiment_id]}"
  local timeout_seconds="${EXP_TASK_TIMEOUTS[$experiment_id]}"
  local target_files_raw="${EXP_TARGET_FILES[$experiment_id]}"
  local target_files_json
  local body pair code file

  if [[ -n "$target_files_raw" ]]; then
    target_files_json="$(json_array_from_lines "$target_files_raw")"
  else
    target_files_json="null"
  fi

  body="$(python3 - "$PROJECT_ID" "$experiment_id" "$case_id" "$vuln" "$max_iterations" "$timeout_seconds" "$target_files_json" <<'PY'
import json
import sys

project_id, experiment_id, case_id, vuln, max_iterations, timeout_seconds, target_files_json = sys.argv[1:]

payload = {
    "project_id": project_id,
    "name": f"{experiment_id} task",
    "description": f"Diagnosis run {experiment_id} for {case_id}",
    "target_vulnerabilities": [vuln],
    "verification_level": "analysis_only",
    "max_iterations": int(max_iterations),
    "timeout_seconds": int(timeout_seconds),
}

target_files = json.loads(target_files_json)
if target_files is not None:
    payload["target_files"] = target_files

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
  local experiment_id="$2"
  local poll_limit="${EXP_POLL_LIMITS[$experiment_id]}"
  local elapsed=0
  local status=""
  local task_code=""

  while (( elapsed <= poll_limit )); do
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
  return 0
}

write_case_meta() {
  local case_dir="$1"
  local experiment_id="$2"
  local case_id="${EXP_CASE_ID[$experiment_id]}"
  local target_files_raw="${EXP_TARGET_FILES[$experiment_id]}"
  local target_files_json

  if [[ -n "$target_files_raw" ]]; then
    target_files_json="$(json_array_from_lines "$target_files_raw")"
  else
    target_files_json="null"
  fi

  cat >"$case_dir/case_meta.json" <<EOF
{
  "experiment_id": "$experiment_id",
  "case_id": "$case_id",
  "description": "${EXP_DESCRIPTION[$experiment_id]}",
  "run_class": "${EXP_RUN_CLASS[$experiment_id]}",
  "source_case_dir": "${CASE_DIRS[$case_id]}",
  "input_mode": "${CASE_MODES[$case_id]}",
  "clean_input_path": "${CASE_INPUT_PATHS[$case_id]}",
  "target_vulnerability": "${CASE_VULNS[$case_id]}",
  "shared_zip": "$SHARED_INPUT_DIR/$case_id.zip",
  "max_iterations": ${EXP_MAX_ITERATIONS[$experiment_id]},
  "task_timeout_seconds": ${EXP_TASK_TIMEOUTS[$experiment_id]},
  "poll_limit_seconds": ${EXP_POLL_LIMITS[$experiment_id]},
  "target_files": $target_files_json
}
EOF
}

write_case_metrics() {
  local case_dir="$1"
  python3 - "$case_dir" <<'PY'
import json
import os
import sys

case_dir = sys.argv[1]
task_object_path = os.path.join(case_dir, "task_object.json")
findings_path = os.path.join(case_dir, "task_findings.json")
status_path = os.path.join(case_dir, "task_status.txt")
classification_path = os.path.join(case_dir, "failure_classification.txt")
metrics_path = os.path.join(case_dir, "metrics.json")

status = "unknown"
if os.path.exists(status_path):
    status = open(status_path, "r", encoding="utf-8").read().strip()

classification = "unknown"
if os.path.exists(classification_path):
    classification = open(classification_path, "r", encoding="utf-8").read().strip()

task = {}
if os.path.exists(task_object_path):
    with open(task_object_path, "r", encoding="utf-8") as fh:
        task = json.load(fh)

findings = []
if os.path.exists(findings_path):
    with open(findings_path, "r", encoding="utf-8") as fh:
        payload = json.load(fh)
    if isinstance(payload, list):
        findings = payload
    elif isinstance(payload, dict):
        for key in ("items", "findings", "data", "results"):
            if isinstance(payload.get(key), list):
                findings = payload[key]
                break

top_findings = []
for item in findings[:3]:
    if isinstance(item, dict):
        top_findings.append({
            "title": item.get("title"),
            "severity": item.get("severity"),
            "file_path": item.get("file_path"),
            "rule_id": item.get("rule_id"),
        })
    else:
        top_findings.append({"raw": item})

metrics = {
    "status": status,
    "classification": classification,
    "total_iterations": task.get("total_iterations"),
    "tool_calls_count": task.get("tool_calls_count"),
    "tokens_used": task.get("tokens_used"),
    "findings_count": task.get("findings_count"),
    "top_3_findings": top_findings,
}

with open(metrics_path, "w", encoding="utf-8") as fh:
    json.dump(metrics, fh, ensure_ascii=False, indent=2)
PY
}

classify_case_result() {
  local case_dir="$1"
  python3 - "$case_dir" <<'PY'
import json
import os
import sys

case_dir = sys.argv[1]
status = "unknown"
status_path = os.path.join(case_dir, "task_status.txt")
task_object_path = os.path.join(case_dir, "task_object.json")

if os.path.exists(status_path):
    status = open(status_path, "r", encoding="utf-8").read().strip()

findings_count = 0
if os.path.exists(task_object_path):
    with open(task_object_path, "r", encoding="utf-8") as fh:
        task = json.load(fh)
    findings_count = int(task.get("findings_count") or 0)

if status == "completed" and findings_count > 0:
    print("completed_with_findings")
elif status == "completed":
    print("completed_no_findings")
elif status == "failed":
    print("runtime_failure")
elif status == "cancelled":
    print("runtime_failure")
elif status == "timeout" and findings_count > 0:
    print("timeout_with_partial_signal")
elif status == "timeout":
    print("timeout_no_findings")
else:
    print("unknown")
PY
}

run_experiment() {
  local experiment_id="$1"
  local case_run_dir="$RUN_DIR/$experiment_id"
  mkdir -p "$case_run_dir"
  write_case_meta "$case_run_dir" "$experiment_id"

  log "Running diagnosis experiment $experiment_id"
  if ! create_case_project "$case_run_dir" "$experiment_id"; then
    echo "project_creation_failure" >"$case_run_dir/failure_classification.txt"
    return
  fi
  if ! upload_case_zip "$case_run_dir" "$experiment_id"; then
    echo "zip_upload_failure" >"$case_run_dir/failure_classification.txt"
    return
  fi
  if ! create_case_task "$case_run_dir" "$experiment_id"; then
    echo "agent_task_creation_failure" >"$case_run_dir/failure_classification.txt"
    return
  fi
  poll_case_task "$case_run_dir" "$experiment_id"
  classify_case_result "$case_run_dir" >"$case_run_dir/failure_classification.txt"
  write_case_metrics "$case_run_dir"
}

write_run_summary() {
  local summary_file="$RUN_DIR/summary.tsv"
  python3 - "$RUN_DIR" "$summary_file" <<'PY'
import json
import os
import sys

run_dir = sys.argv[1]
summary_file = sys.argv[2]
experiments = [
    ("A2-PT-PY-FILE-001", "PT-PY-FILE-001", "baseline-like"),
    ("B2-PT-PY-REPO-001", "PT-PY-REPO-001", "diagnostic only"),
    ("C3-PT-PY-REPO-CVE-2024-32982-VULN", "PT-PY-REPO-CVE-2024-32982-VULN", "diagnostic only"),
]

lines = [
    "experiment_id\tcase_id\trun_class\tstatus\tclassification\tproject_id\ttask_id\ttotal_iterations\ttool_calls_count\ttokens_used\tfindings_count"
]

def read_text(path, default=""):
    if not os.path.exists(path):
        return default
    return open(path, "r", encoding="utf-8").read().strip()

for experiment_id, case_id, run_class in experiments:
    case_dir = os.path.join(run_dir, experiment_id)
    status = read_text(os.path.join(case_dir, "task_status.txt"), "not_started")
    classification = read_text(os.path.join(case_dir, "failure_classification.txt"), "unknown")
    project_id = read_text(os.path.join(case_dir, "project_id.txt"))
    task_id = read_text(os.path.join(case_dir, "task_id.txt"))
    metrics = {}
    metrics_path = os.path.join(case_dir, "metrics.json")
    if os.path.exists(metrics_path):
      with open(metrics_path, "r", encoding="utf-8") as fh:
          metrics = json.load(fh)
    row = [
        experiment_id,
        case_id,
        run_class,
        status,
        classification,
        project_id,
        task_id,
        "" if metrics.get("total_iterations") is None else str(metrics["total_iterations"]),
        "" if metrics.get("tool_calls_count") is None else str(metrics["tool_calls_count"]),
        "" if metrics.get("tokens_used") is None else str(metrics["tokens_used"]),
        "" if metrics.get("findings_count") is None else str(metrics["findings_count"]),
    ]
    lines.append("\t".join(row))

with open(summary_file, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines) + "\n")
PY
}

write_observations() {
  python3 - "$RUN_DIR" <<'PY'
import json
import os
import sys

run_dir = sys.argv[1]
experiments = [
    "A2-PT-PY-FILE-001",
    "B2-PT-PY-REPO-001",
    "C3-PT-PY-REPO-CVE-2024-32982-VULN",
]

lines = ["# DeepAudit 诊断实验观察", ""]

for experiment_id in experiments:
    case_dir = os.path.join(run_dir, experiment_id)
    meta = json.load(open(os.path.join(case_dir, "case_meta.json"), "r", encoding="utf-8"))
    metrics = json.load(open(os.path.join(case_dir, "metrics.json"), "r", encoding="utf-8"))

    lines.append(f"## {experiment_id}")
    lines.append("")
    lines.append(f"- case_id: `{meta['case_id']}`")
    lines.append(f"- 运行类型: `{meta['run_class']}`")
    lines.append(f"- 任务状态: `{metrics['status']}`")
    lines.append(f"- 初步分类: `{metrics['classification']}`")
    lines.append(f"- total_iterations: `{metrics['total_iterations']}`")
    lines.append(f"- tool_calls_count: `{metrics['tool_calls_count']}`")
    lines.append(f"- tokens_used: `{metrics['tokens_used']}`")
    lines.append(f"- findings_count: `{metrics['findings_count']}`")
    if meta["target_files"] is None:
        lines.append("- target_files: `null`")
    else:
        lines.append("- target_files:")
        for path in meta["target_files"]:
            lines.append(f"  - `{path}`")
    if metrics["top_3_findings"]:
        lines.append("- 前 3 条 finding:")
        for item in metrics["top_3_findings"]:
            title = item.get("title")
            severity = item.get("severity")
            file_path = item.get("file_path")
            lines.append(f"  - `{severity}` | `{file_path}` | {title}")
    else:
        lines.append("- 前 3 条 finding: 无")
    lines.append("")

with open(os.path.join(run_dir, "observations.md"), "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines) + "\n")
PY
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
  local experiment_id
  for experiment_id in "${EXPERIMENT_IDS[@]}"; do
    run_experiment "$experiment_id"
  done
  write_run_summary
  write_observations
  log "Diagnosis run artifacts written to $RUN_DIR"
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
