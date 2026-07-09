#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/deepaudit_prepare_and_preflight.sh"

ARTIFACT_ROOT="${DEEPAUDIT_DIAG2_ARTIFACT_ROOT:-$REPO_ROOT/artifacts/deepaudit_diagnosis}"
SHARED_INPUT_DIR="${DEEPAUDIT_DIAG2_SHARED_INPUT_DIR:-/tmp/deepaudit/diagnosis_inputs_round2}"
LOCAL_INPUT_WORKDIR="${DEEPAUDIT_DIAG2_LOCAL_INPUT_WORKDIR:-/tmp/deepaudit_diagnosis_inputs_round2}"
RUN_ID="${DEEPAUDIT_DIAG2_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
RUN_DIR="$ARTIFACT_ROOT/$RUN_ID"
DIAG_EMAIL="${DEEPAUDIT_DIAG2_EMAIL:-deepaudit-diagnosis@example.com}"
DIAG_PASSWORD="${DEEPAUDIT_DIAG2_PASSWORD:-DeepAuditDiagnosis123!}"
DIAG_FULL_NAME="${DEEPAUDIT_DIAG2_FULL_NAME:-DeepAudit Diagnosis}"
POLL_INTERVAL_SECONDS="${DEEPAUDIT_DIAG2_POLL_INTERVAL:-10}"

EXPERIMENT_IDS=(
  "A3-PT-PY-FILE-001"
  "A4-PT-PY-FILE-001"
  "C2-PT-PY-REPO-CVE-2024-32982-VULN"
  "B4-PT-PY-REPO-001"
)

declare -A EXP_KIND=(
  ["A3-PT-PY-FILE-001"]="agent_task"
  ["A4-PT-PY-FILE-001"]="instant_analysis"
  ["C2-PT-PY-REPO-CVE-2024-32982-VULN"]="agent_task"
  ["B4-PT-PY-REPO-001"]="local_analysis"
)

declare -A EXP_CASE_ID=(
  ["A3-PT-PY-FILE-001"]="PT-PY-FILE-001"
  ["A4-PT-PY-FILE-001"]="PT-PY-FILE-001"
  ["C2-PT-PY-REPO-CVE-2024-32982-VULN"]="PT-PY-REPO-CVE-2024-32982-VULN"
  ["B4-PT-PY-REPO-001"]="PT-PY-REPO-001"
)

declare -A EXP_RUN_CLASS=(
  ["A3-PT-PY-FILE-001"]="diagnostic only"
  ["A4-PT-PY-FILE-001"]="diagnostic only"
  ["C2-PT-PY-REPO-CVE-2024-32982-VULN"]="baseline-like"
  ["B4-PT-PY-REPO-001"]="diagnostic only"
)

declare -A EXP_DESCRIPTION=(
  ["A3-PT-PY-FILE-001"]="A3 把单文件包装为最小 repo 形态"
  ["A4-PT-PY-FILE-001"]="A4 对同一份文件执行 instant analysis"
  ["C2-PT-PY-REPO-CVE-2024-32982-VULN"]="C2 完整真实世界 repo 提高预算"
  ["B4-PT-PY-REPO-001"]="B4 检查目标 PT finding 的排序质量"
)

declare -A CASE_DIRS=(
  ["PT-PY-FILE-001"]="datasets/synthetic/PT-PY-FILE-001"
  ["PT-PY-REPO-CVE-2024-32982-VULN"]="datasets/real_world/PT-PY-REPO-CVE-2024-32982-VULN"
)

declare -A CASE_VULNS=(
  ["PT-PY-FILE-001"]="path_traversal"
  ["PT-PY-REPO-CVE-2024-32982-VULN"]="path_traversal"
)

declare -A EXP_MAX_ITERATIONS=(
  ["A3-PT-PY-FILE-001"]="24"
  ["C2-PT-PY-REPO-CVE-2024-32982-VULN"]="24"
)

declare -A EXP_TASK_TIMEOUTS=(
  ["A3-PT-PY-FILE-001"]="1800"
  ["C2-PT-PY-REPO-CVE-2024-32982-VULN"]="2400"
)

declare -A EXP_POLL_LIMITS=(
  ["A3-PT-PY-FILE-001"]="900"
  ["C2-PT-PY-REPO-CVE-2024-32982-VULN"]="1500"
)

TOKEN=""
PROJECT_ID=""
TASK_ID=""

usage() {
  cat <<'EOF'
Usage:
  scripts/run_deepaudit_diagnosis_round2.sh run
  scripts/run_deepaudit_diagnosis_round2.sh prepare-inputs
  scripts/run_deepaudit_diagnosis_round2.sh cleanup-inputs
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
    "A3-PT-PY-FILE-001",
    "A4-PT-PY-FILE-001",
    "C2-PT-PY-REPO-CVE-2024-32982-VULN",
    "B4-PT-PY-REPO-001"
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

prepare_a3_input() {
  local local_case_dir="$LOCAL_INPUT_WORKDIR/A3-PT-PY-FILE-001"
  local shared_zip="$SHARED_INPUT_DIR/A3-PT-PY-FILE-001.zip"
  rm -rf "$local_case_dir"
  mkdir -p "$local_case_dir/src"
  cp "$REPO_ROOT/datasets/synthetic/PT-PY-FILE-001/app.py" "$local_case_dir/src/app.py"
  rm -f "$shared_zip"
  zip_dir "$local_case_dir" "$shared_zip"
}

prepare_c2_input() {
  local local_case_dir="$LOCAL_INPUT_WORKDIR/C2-PT-PY-REPO-CVE-2024-32982-VULN"
  local shared_zip="$SHARED_INPUT_DIR/C2-PT-PY-REPO-CVE-2024-32982-VULN.zip"
  rm -rf "$local_case_dir"
  mkdir -p "$local_case_dir"
  cp -r "$REPO_ROOT/datasets/real_world/PT-PY-REPO-CVE-2024-32982-VULN/repo" "$local_case_dir/"
  rm -f "$shared_zip"
  zip_dir "$local_case_dir" "$shared_zip"
}

prepare_inputs() {
  require_commands
  ensure_dirs
  log "Preparing diagnostic input for A3-PT-PY-FILE-001"
  prepare_a3_input
  log "Preparing diagnostic input for C2-PT-PY-REPO-CVE-2024-32982-VULN"
  prepare_c2_input
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

write_case_meta_agent() {
  local case_dir="$1"
  local experiment_id="$2"
  local case_id="${EXP_CASE_ID[$experiment_id]}"
  local wrapped_path="null"
  if [[ "$experiment_id" == "A3-PT-PY-FILE-001" ]]; then
    wrapped_path="\"src/app.py\""
  fi
  cat >"$case_dir/case_meta.json" <<EOF
{
  "experiment_id": "$experiment_id",
  "case_id": "$case_id",
  "description": "${EXP_DESCRIPTION[$experiment_id]}",
  "run_class": "${EXP_RUN_CLASS[$experiment_id]}",
  "kind": "agent_task",
  "shared_zip": "$SHARED_INPUT_DIR/$experiment_id.zip",
  "wrapped_primary_path": $wrapped_path,
  "max_iterations": ${EXP_MAX_ITERATIONS[$experiment_id]},
  "task_timeout_seconds": ${EXP_TASK_TIMEOUTS[$experiment_id]},
  "poll_limit_seconds": ${EXP_POLL_LIMITS[$experiment_id]}
}
EOF
}

write_case_meta_instant() {
  local case_dir="$1"
  local experiment_id="$2"
  local case_id="${EXP_CASE_ID[$experiment_id]}"
  cat >"$case_dir/case_meta.json" <<EOF
{
  "experiment_id": "$experiment_id",
  "case_id": "$case_id",
  "description": "${EXP_DESCRIPTION[$experiment_id]}",
  "run_class": "${EXP_RUN_CLASS[$experiment_id]}",
  "kind": "instant_analysis",
  "language": "python",
  "source_file": "datasets/synthetic/PT-PY-FILE-001/app.py"
}
EOF
}

write_case_meta_local() {
  local case_dir="$1"
  local experiment_id="$2"
  local case_id="${EXP_CASE_ID[$experiment_id]}"
  cat >"$case_dir/case_meta.json" <<EOF
{
  "experiment_id": "$experiment_id",
  "case_id": "$case_id",
  "description": "${EXP_DESCRIPTION[$experiment_id]}",
  "run_class": "${EXP_RUN_CLASS[$experiment_id]}",
  "kind": "local_analysis",
  "baseline_findings_source": "artifacts/deepaudit_smoke/20260701T083143Z/PT-PY-REPO-001/task_findings.json",
  "narrowed_findings_source": "artifacts/deepaudit_diagnosis/20260701T110600Z/B2-PT-PY-REPO-001/task_findings.json"
}
EOF
}

create_case_project() {
  local case_dir="$1"
  local experiment_id="$2"
  local case_id="${EXP_CASE_ID[$experiment_id]}"
  local body pair code file
  body="$(cat <<EOF
{"name":"$experiment_id","source_type":"zip","repository_type":"other","description":"DeepAudit diagnosis round2 experiment $experiment_id for $case_id","default_branch":"main","programming_languages":["python"]}
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
  local zip_path="$SHARED_INPUT_DIR/$experiment_id.zip"
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
  local experiment_id="$2"
  local case_id="${EXP_CASE_ID[$experiment_id]}"
  local vuln="${CASE_VULNS[$case_id]}"
  local body pair code file
  body="$(python3 - "$PROJECT_ID" "$experiment_id" "$case_id" "$vuln" "${EXP_MAX_ITERATIONS[$experiment_id]}" "${EXP_TASK_TIMEOUTS[$experiment_id]}" <<'PY'
import json
import sys

project_id, experiment_id, case_id, vuln, max_iterations, timeout_seconds = sys.argv[1:]
payload = {
    "project_id": project_id,
    "name": f"{experiment_id} task",
    "description": f"Diagnosis round2 {experiment_id} for {case_id}",
    "target_vulnerabilities": [vuln],
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
}

write_agent_metrics() {
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

run_agent_experiment() {
  local experiment_id="$1"
  local case_run_dir="$RUN_DIR/$experiment_id"
  mkdir -p "$case_run_dir"
  write_case_meta_agent "$case_run_dir" "$experiment_id"
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
  write_agent_metrics "$case_run_dir"
}

run_instant_experiment() {
  local experiment_id="$1"
  local case_run_dir="$RUN_DIR/$experiment_id"
  mkdir -p "$case_run_dir"
  write_case_meta_instant "$case_run_dir" "$experiment_id"
  log "Running diagnosis experiment $experiment_id"

  local code_file="$REPO_ROOT/datasets/synthetic/PT-PY-FILE-001/app.py"
  local body pair code file
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
    echo "instant_analysis_failure" >"$case_run_dir/failure_classification.txt"
    return
  }
  code="${pair%% *}"
  file="${pair#* }"
  copy_response_to_case "$case_run_dir" "instant_analysis" "$file"
  printf '%s\n' "$code" >"$case_run_dir/http_status.txt"

  python3 - "$case_run_dir" <<'PY'
import json
import os
import sys

case_dir = sys.argv[1]
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
            "vulnerability_type": item.get("vulnerability_type"),
            "confidence": item.get("confidence"),
        }
    return {"raw": item}

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
    "findings_count": len(findings),
    "top_3_findings": [normalize_item(item) for item in findings[:3]],
    "raw_keys": sorted(data.keys()) if isinstance(data, dict) else [],
}
with open(os.path.join(case_dir, "metrics.json"), "w", encoding="utf-8") as fh:
    json.dump(metrics, fh, ensure_ascii=False, indent=2)
PY
}

run_b4_analysis() {
  local experiment_id="$1"
  local case_run_dir="$RUN_DIR/$experiment_id"
  mkdir -p "$case_run_dir"
  write_case_meta_local "$case_run_dir" "$experiment_id"
  log "Running diagnosis experiment $experiment_id"
  python3 - "$case_run_dir" "$REPO_ROOT" <<'PY'
import json
import os
import sys

case_dir = sys.argv[1]
repo_root = sys.argv[2]
baseline_path = os.path.join(repo_root, "artifacts/deepaudit_smoke/20260701T083143Z/PT-PY-REPO-001/task_findings.json")
narrowed_path = os.path.join(repo_root, "artifacts/deepaudit_diagnosis/20260701T110600Z/B2-PT-PY-REPO-001/task_findings.json")

with open(baseline_path, "r", encoding="utf-8") as fh:
    baseline = json.load(fh)
with open(narrowed_path, "r", encoding="utf-8") as fh:
    narrowed = json.load(fh)

def summarize(findings):
    pt_ranks = []
    for idx, item in enumerate(findings, start=1):
        if item.get("vulnerability_type") == "path_traversal":
            pt_ranks.append(idx)
    first_pt_rank = pt_ranks[0] if pt_ranks else None
    return {
        "total_findings": len(findings),
        "first_pt_rank": first_pt_rank,
        "pt_ranks": pt_ranks,
        "top_3_titles": [item.get("title") for item in findings[:3]],
    }

baseline_summary = summarize(baseline)
narrowed_summary = summarize(narrowed)

if baseline_summary["first_pt_rank"] == 1:
    assessment = "target_top_ranked_with_noise"
else:
    assessment = "target_not_top_ranked"

result = {
    "status": "completed",
    "classification": assessment,
    "baseline": baseline_summary,
    "narrowed": narrowed_summary,
    "interpretation": "baseline 中目标 PT finding 排名首位，但同时伴随多条辅助噪声；B2 收窄后 debug 类噪声消失，但第 1 条 finding 仍可能是入口层辅助告警，而不是最完整的 PT 总结。",
}

with open(os.path.join(case_dir, "task_status.txt"), "w", encoding="utf-8") as fh:
    fh.write("completed\n")
with open(os.path.join(case_dir, "failure_classification.txt"), "w", encoding="utf-8") as fh:
    fh.write(assessment + "\n")
with open(os.path.join(case_dir, "rank_check.json"), "w", encoding="utf-8") as fh:
    json.dump(result, fh, ensure_ascii=False, indent=2)

metrics = {
    "status": "completed",
    "classification": assessment,
    "findings_count": baseline_summary["total_findings"],
    "top_3_findings": [{"title": title} for title in baseline_summary["top_3_titles"]],
}
with open(os.path.join(case_dir, "metrics.json"), "w", encoding="utf-8") as fh:
    json.dump(metrics, fh, ensure_ascii=False, indent=2)
PY
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
    ("A3-PT-PY-FILE-001", "PT-PY-FILE-001", "diagnostic only"),
    ("A4-PT-PY-FILE-001", "PT-PY-FILE-001", "diagnostic only"),
    ("C2-PT-PY-REPO-CVE-2024-32982-VULN", "PT-PY-REPO-CVE-2024-32982-VULN", "baseline-like"),
    ("B4-PT-PY-REPO-001", "PT-PY-REPO-001", "diagnostic only"),
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
    metrics = {}
    metrics_path = os.path.join(case_dir, "metrics.json")
    if os.path.exists(metrics_path):
        with open(metrics_path, "r", encoding="utf-8") as fh:
            metrics = json.load(fh)
    row = [
        experiment_id,
        case_id,
        run_class,
        read_text(os.path.join(case_dir, "task_status.txt"), "not_started"),
        read_text(os.path.join(case_dir, "failure_classification.txt"), "unknown"),
        read_text(os.path.join(case_dir, "project_id.txt")),
        read_text(os.path.join(case_dir, "task_id.txt")),
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
    "A3-PT-PY-FILE-001",
    "A4-PT-PY-FILE-001",
    "C2-PT-PY-REPO-CVE-2024-32982-VULN",
    "B4-PT-PY-REPO-001",
]

lines = ["# DeepAudit 第二轮诊断实验观察", ""]
for experiment_id in experiments:
    case_dir = os.path.join(run_dir, experiment_id)
    meta = json.load(open(os.path.join(case_dir, "case_meta.json"), "r", encoding="utf-8"))
    metrics = json.load(open(os.path.join(case_dir, "metrics.json"), "r", encoding="utf-8"))
    lines.append(f"## {experiment_id}")
    lines.append("")
    lines.append(f"- case_id: `{meta['case_id']}`")
    lines.append(f"- kind: `{meta['kind']}`")
    lines.append(f"- 运行类型: `{meta['run_class']}`")
    lines.append(f"- 任务状态: `{metrics['status']}`")
    lines.append(f"- 初步分类: `{metrics['classification']}`")
    if metrics.get("total_iterations") is not None:
        lines.append(f"- total_iterations: `{metrics['total_iterations']}`")
    if metrics.get("tool_calls_count") is not None:
        lines.append(f"- tool_calls_count: `{metrics['tool_calls_count']}`")
    if metrics.get("tokens_used") is not None:
        lines.append(f"- tokens_used: `{metrics['tokens_used']}`")
    lines.append(f"- findings_count: `{metrics.get('findings_count')}`")
    if metrics.get("top_3_findings"):
        lines.append("- 前 3 条 finding:")
        for item in metrics["top_3_findings"]:
            lines.append(f"  - `{item.get('severity')}` | {item.get('title')}")
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

  run_agent_experiment "A3-PT-PY-FILE-001"
  run_instant_experiment "A4-PT-PY-FILE-001"
  run_agent_experiment "C2-PT-PY-REPO-CVE-2024-32982-VULN"
  run_b4_analysis "B4-PT-PY-REPO-001"

  write_run_summary
  write_observations
  log "Diagnosis round2 artifacts written to $RUN_DIR"
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
