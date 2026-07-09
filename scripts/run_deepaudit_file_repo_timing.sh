#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/deepaudit_prepare_and_preflight.sh"

ARTIFACT_ROOT="${DEEPAUDIT_TIMING_ARTIFACT_ROOT:-$REPO_ROOT/artifacts/deepaudit_timing}"
SHARED_INPUT_DIR="${DEEPAUDIT_TIMING_SHARED_INPUT_DIR:-/tmp/deepaudit/timing_inputs}"
LOCAL_INPUT_WORKDIR="${DEEPAUDIT_TIMING_LOCAL_INPUT_WORKDIR:-/tmp/deepaudit_timing_inputs}"
RUN_ID="${DEEPAUDIT_TIMING_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
RUN_DIR="$ARTIFACT_ROOT/$RUN_ID"
DIAG_EMAIL="${DEEPAUDIT_TIMING_EMAIL:-deepaudit-timing@example.com}"
DIAG_PASSWORD="${DEEPAUDIT_TIMING_PASSWORD:-DeepAuditTiming123!}"
DIAG_FULL_NAME="${DEEPAUDIT_TIMING_FULL_NAME:-DeepAudit Timing}"
POLL_INTERVAL_SECONDS="${DEEPAUDIT_TIMING_POLL_INTERVAL:-2}"

CASE_ID="PT-PY-FILE-001"
CASE_DIR_REL="datasets/synthetic/PT-PY-FILE-001"
CASE_SOURCE_FILE="app.py"
TARGET_VULNERABILITY="path_traversal"
MAX_ITERATIONS="${DEEPAUDIT_TIMING_MAX_ITERATIONS:-24}"
TASK_TIMEOUT_SECONDS="${DEEPAUDIT_TIMING_TIMEOUT_SECONDS:-1800}"
POLL_LIMIT_SECONDS="${DEEPAUDIT_TIMING_POLL_LIMIT_SECONDS:-900}"

EXPERIMENT_IDS=(
  "F1-PT-PY-FILE-001"
  "R1-PT-PY-FILE-001"
  "F1-REPEAT-PT-PY-FILE-001"
  "R1-REPEAT-PT-PY-FILE-001"
  "I1-PT-PY-FILE-001"
  "I1-REPEAT-PT-PY-FILE-001"
)

declare -A EXP_DESCRIPTION=(
  ["F1-PT-PY-FILE-001"]="同案 file 形态 timing 诊断"
  ["R1-PT-PY-FILE-001"]="同案最小 repo 形态 timing 诊断"
  ["F1-REPEAT-PT-PY-FILE-001"]="同案 file 形态 timing 诊断 repeat"
  ["R1-REPEAT-PT-PY-FILE-001"]="同案最小 repo 形态 timing 诊断 repeat"
  ["I1-PT-PY-FILE-001"]="同案 instant analysis timing 对照"
  ["I1-REPEAT-PT-PY-FILE-001"]="同案 instant analysis timing 对照 repeat"
)

declare -A EXP_INPUT_MODE=(
  ["F1-PT-PY-FILE-001"]="file"
  ["R1-PT-PY-FILE-001"]="repo"
  ["F1-REPEAT-PT-PY-FILE-001"]="file"
  ["R1-REPEAT-PT-PY-FILE-001"]="repo"
  ["I1-PT-PY-FILE-001"]="instant"
  ["I1-REPEAT-PT-PY-FILE-001"]="instant"
)

declare -A EXP_PRIMARY_PATH=(
  ["F1-PT-PY-FILE-001"]="app.py"
  ["R1-PT-PY-FILE-001"]="src/app.py"
  ["F1-REPEAT-PT-PY-FILE-001"]="app.py"
  ["R1-REPEAT-PT-PY-FILE-001"]="src/app.py"
  ["I1-PT-PY-FILE-001"]="app.py"
  ["I1-REPEAT-PT-PY-FILE-001"]="app.py"
)

TOKEN=""
PROJECT_ID=""
TASK_ID=""

usage() {
  cat <<'EOF'
Usage:
  scripts/run_deepaudit_file_repo_timing.sh run
  scripts/run_deepaudit_file_repo_timing.sh prepare-inputs
  scripts/run_deepaudit_file_repo_timing.sh cleanup-inputs
  scripts/run_deepaudit_file_repo_timing.sh render
  scripts/run_deepaudit_file_repo_timing.sh run-instant-only

Commands:
  run             执行同案 file/repo timing 诊断实验。
  prepare-inputs  仅准备输入 ZIP。
  cleanup-inputs  清理本地和共享输入。
  render          基于现有轮询产物重算 metrics / summary / comparison。
  run-instant-only 仅执行 instant 首轮与 repeat，并重算汇总。
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
  "poll_limit_seconds": $POLL_LIMIT_SECONDS,
  "llm_provider": "$LLM_PROVIDER",
  "llm_model": "$LLM_MODEL",
  "llm_base_url": "$LLM_BASE_URL",
  "case_id": "$CASE_ID",
  "max_iterations": $MAX_ITERATIONS,
  "task_timeout_seconds": $TASK_TIMEOUT_SECONDS,
  "experiments": [
    "F1-PT-PY-FILE-001",
    "R1-PT-PY-FILE-001",
    "F1-REPEAT-PT-PY-FILE-001",
    "R1-REPEAT-PT-PY-FILE-001",
    "I1-PT-PY-FILE-001",
    "I1-REPEAT-PT-PY-FILE-001"
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

prepare_f1_input() {
  local experiment_id="$1"
  local local_case_dir="$LOCAL_INPUT_WORKDIR/$experiment_id"
  local shared_zip="$SHARED_INPUT_DIR/$experiment_id.zip"
  rm -rf "$local_case_dir"
  mkdir -p "$local_case_dir"
  cp "$REPO_ROOT/$CASE_DIR_REL/$CASE_SOURCE_FILE" "$local_case_dir/app.py"
  rm -f "$shared_zip"
  zip_dir "$local_case_dir" "$shared_zip"
}

prepare_r1_input() {
  local experiment_id="$1"
  local local_case_dir="$LOCAL_INPUT_WORKDIR/$experiment_id"
  local shared_zip="$SHARED_INPUT_DIR/$experiment_id.zip"
  rm -rf "$local_case_dir"
  mkdir -p "$local_case_dir/src"
  cp "$REPO_ROOT/$CASE_DIR_REL/$CASE_SOURCE_FILE" "$local_case_dir/src/app.py"
  rm -f "$shared_zip"
  zip_dir "$local_case_dir" "$shared_zip"
}

prepare_inputs() {
  require_commands
  ensure_dirs
  log "Preparing timing input for F1-PT-PY-FILE-001"
  prepare_f1_input "F1-PT-PY-FILE-001"
  log "Preparing timing input for R1-PT-PY-FILE-001"
  prepare_r1_input "R1-PT-PY-FILE-001"
  log "Preparing timing input for F1-REPEAT-PT-PY-FILE-001"
  prepare_f1_input "F1-REPEAT-PT-PY-FILE-001"
  log "Preparing timing input for R1-REPEAT-PT-PY-FILE-001"
  prepare_r1_input "R1-REPEAT-PT-PY-FILE-001"
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

register_or_login_diag_user() {
  local auth_dir="$RUN_DIR/_auth"
  mkdir -p "$auth_dir"
  local body pair code file detail

  body="$(cat <<EOF
{"email":"$DIAG_EMAIL","password":"$DIAG_PASSWORD","full_name":"$DIAG_FULL_NAME"}
EOF
)"
  pair="$(http_json POST "$BACKEND_URL/api/v1/auth/register" "$body" 2>"$auth_dir/register.stderr.log" || true)"
  if [[ -n "$pair" ]]; then
    code="${pair%% *}"
    file="${pair#* }"
    cp "$file" "$auth_dir/register_user.json"
    if [[ "$code" != "200" && "$code" != "400" ]]; then
      echo "Registration failed with HTTP $code" >&2
      exit 1
    fi
    if [[ "$code" == "400" ]]; then
      detail="$(cat "$file")"
      if ! grep -q "已被注册" <<<"$detail"; then
        echo "Registration failed with HTTP 400 but not an already-exists response" >&2
        exit 1
      fi
    fi
  fi

  pair="$(http_form POST "$BACKEND_URL/api/v1/auth/login" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode "username=$DIAG_EMAIL" \
    --data-urlencode "password=$DIAG_PASSWORD" 2>"$auth_dir/login.stderr.log")"
  code="${pair%% *}"
  file="${pair#* }"
  cp "$file" "$auth_dir/login_user.json"
  [[ "$code" == "200" ]] || {
    echo "Login failed with HTTP $code" >&2
    exit 1
  }
  TOKEN="$(extract_json_field "$file" "access_token")"
  [[ -n "$TOKEN" ]] || {
    echo "Access token is empty" >&2
    exit 1
  }
}

record_step_time() {
  local case_dir="$1"
  local key="$2"
  python3 - "$case_dir/step_times.json" "$key" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" <<'PY'
import json
import os
import sys

path, key, value = sys.argv[1:]
data = {}
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as fh:
        data = json.load(fh)
data[key] = value
with open(path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, ensure_ascii=False, indent=2)
PY
}

write_case_meta() {
  local case_dir="$1"
  local experiment_id="$2"
  cat >"$case_dir/case_meta.json" <<EOF
{
  "experiment_id": "$experiment_id",
  "case_id": "$CASE_ID",
  "description": "${EXP_DESCRIPTION[$experiment_id]}",
  "run_class": "diagnostic only",
  "input_mode": "${EXP_INPUT_MODE[$experiment_id]}",
  "primary_path": "${EXP_PRIMARY_PATH[$experiment_id]}",
  "source_case_dir": "$CASE_DIR_REL",
  "target_vulnerability": "$TARGET_VULNERABILITY",
  "shared_zip": "$SHARED_INPUT_DIR/$experiment_id.zip",
  "max_iterations": $MAX_ITERATIONS,
  "task_timeout_seconds": $TASK_TIMEOUT_SECONDS,
  "poll_interval_seconds": $POLL_INTERVAL_SECONDS,
  "poll_limit_seconds": $POLL_LIMIT_SECONDS,
  "target_files": null
}
EOF
}

write_case_meta_instant() {
  local case_dir="$1"
  local experiment_id="$2"
  cat >"$case_dir/case_meta.json" <<EOF
{
  "experiment_id": "$experiment_id",
  "case_id": "$CASE_ID",
  "description": "${EXP_DESCRIPTION[$experiment_id]}",
  "run_class": "diagnostic only",
  "kind": "instant_analysis",
  "input_mode": "instant",
  "primary_path": "${EXP_PRIMARY_PATH[$experiment_id]}",
  "source_case_dir": "$CASE_DIR_REL",
  "language": "python",
  "target_vulnerability": "$TARGET_VULNERABILITY"
}
EOF
}

create_case_project() {
  local case_dir="$1"
  local experiment_id="$2"
  local body pair code file
  body="$(cat <<EOF
{"name":"$experiment_id","source_type":"zip","repository_type":"other","description":"DeepAudit timing experiment $experiment_id for $CASE_ID","default_branch":"main","programming_languages":["python"]}
EOF
)"
  pair="$(http_json POST "$BACKEND_URL/api/v1/projects/" "$body" 2>"$case_dir/create_project.stderr.log")" || return 1
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
  local output_file code metadata_code
  record_step_time "$case_dir" "upload_started_at"
  output_file="$(mktemp)"
  code="$(curl -sS -o "$output_file" -w '%{http_code}' \
    -X POST "$BACKEND_URL/api/v1/projects/$PROJECT_ID/zip" \
    -H "Authorization: Bearer $TOKEN" \
    -F "file=@$zip_path")" || return 1
  record_step_time "$case_dir" "upload_completed_at"
  copy_response_to_case "$case_dir" "upload_zip" "$output_file"
  [[ "$code" == "200" ]] || return 1
  metadata_code="$(fetch_case_endpoint "$case_dir" "zip_metadata" "$BACKEND_URL/api/v1/projects/$PROJECT_ID/zip")" || return 1
  [[ "$metadata_code" == "200" ]] || return 1
}

create_case_task() {
  local case_dir="$1"
  local experiment_id="$2"
  local body pair code file
  body="$(cat <<EOF
{"project_id":"$PROJECT_ID","name":"$experiment_id task","description":"Timing run $experiment_id for $CASE_ID","target_vulnerabilities":["$TARGET_VULNERABILITY"],"verification_level":"analysis_only","max_iterations":$MAX_ITERATIONS,"timeout_seconds":$TASK_TIMEOUT_SECONDS}
EOF
)"
  pair="$(http_json POST "$BACKEND_URL/api/v1/agent-tasks/" "$body" 2>"$case_dir/create_task.stderr.log")" || return 1
  code="${pair%% *}"
  file="${pair#* }"
  copy_response_to_case "$case_dir" "create_task" "$file"
  [[ "$code" == "200" ]] || return 1
  TASK_ID="$(extract_json_field "$file" "id")"
  printf '%s\n' "$TASK_ID" >"$case_dir/task_id.txt"
  record_step_time "$case_dir" "task_created_at"
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

append_task_poll() {
  local case_dir="$1"
  local polled_at="$2"
  local status_code="$3"
  local source_file="$4"
  python3 - "$case_dir/task_poll.ndjson" "$polled_at" "$status_code" "$source_file" <<'PY'
import json
import os
import sys

output_path, polled_at, status_code, source_file = sys.argv[1:]
record = {
    "polled_at": polled_at,
    "http_status": int(status_code) if status_code.isdigit() else None,
    "task_status": None,
    "current_phase": None,
    "progress_percentage": None,
    "total_iterations": None,
    "tool_calls_count": None,
    "tokens_used": None,
    "findings_count": None,
    "started_at": None,
    "completed_at": None,
}
if os.path.exists(source_file) and os.path.getsize(source_file) > 0:
    with open(source_file, "r", encoding="utf-8") as fh:
        data = json.load(fh)
    record.update({
        "task_status": data.get("status"),
        "current_phase": data.get("current_phase"),
        "progress_percentage": data.get("progress_percentage"),
        "total_iterations": data.get("total_iterations"),
        "tool_calls_count": data.get("tool_calls_count"),
        "tokens_used": data.get("tokens_used"),
        "findings_count": data.get("findings_count"),
        "started_at": data.get("started_at"),
        "completed_at": data.get("completed_at"),
    })
with open(output_path, "a", encoding="utf-8") as fh:
    fh.write(json.dumps(record, ensure_ascii=False) + "\n")
PY
}

append_findings_poll() {
  local case_dir="$1"
  local polled_at="$2"
  local status_code="$3"
  local source_file="$4"
  python3 - "$case_dir/findings_poll.ndjson" "$polled_at" "$status_code" "$source_file" <<'PY'
import json
import os
import sys

output_path, polled_at, status_code, source_file = sys.argv[1:]
record = {
    "polled_at": polled_at,
    "http_status": int(status_code) if status_code.isdigit() else None,
    "findings_count": None,
    "titles_top3": [],
}
if os.path.exists(source_file) and os.path.getsize(source_file) > 0:
    with open(source_file, "r", encoding="utf-8") as fh:
        data = json.load(fh)
    if isinstance(data, list):
        record["findings_count"] = len(data)
        record["titles_top3"] = [item.get("title") for item in data[:3] if isinstance(item, dict)]
with open(output_path, "a", encoding="utf-8") as fh:
    fh.write(json.dumps(record, ensure_ascii=False) + "\n")
PY
}

append_summary_poll() {
  local case_dir="$1"
  local polled_at="$2"
  local status_code="$3"
  local source_file="$4"
  python3 - "$case_dir/summary_poll.ndjson" "$polled_at" "$status_code" "$source_file" <<'PY'
import json
import os
import sys

output_path, polled_at, status_code, source_file = sys.argv[1:]
record = {
    "polled_at": polled_at,
    "http_status": int(status_code) if status_code.isdigit() else None,
    "status": None,
    "duration_seconds": None,
    "total_findings": None,
    "verified_findings": None,
}
if os.path.exists(source_file) and os.path.getsize(source_file) > 0:
    with open(source_file, "r", encoding="utf-8") as fh:
        data = json.load(fh)
    if isinstance(data, dict):
        record.update({
            "status": data.get("status"),
            "duration_seconds": data.get("duration_seconds"),
            "total_findings": data.get("total_findings"),
            "verified_findings": data.get("verified_findings"),
        })
with open(output_path, "a", encoding="utf-8") as fh:
    fh.write(json.dumps(record, ensure_ascii=False) + "\n")
PY
}

poll_case_task() {
  local case_dir="$1"
  local elapsed=0
  local status=""
  local polled_at=""
  local pair code file
  local task_tmp="$case_dir/.task_object.poll.json"
  local findings_tmp="$case_dir/.task_findings.poll.json"
  local summary_tmp="$case_dir/.task_summary.poll.json"

  : >"$case_dir/task_poll.ndjson"
  : >"$case_dir/findings_poll.ndjson"
  : >"$case_dir/summary_poll.ndjson"

  while (( elapsed <= POLL_LIMIT_SECONDS )); do
    polled_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    pair="$(http_json GET "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID" 2>>"$case_dir/poll_errors.log" || true)"
    if [[ -n "$pair" ]]; then
      code="${pair%% *}"
      file="${pair#* }"
      cp "$file" "$task_tmp"
      append_task_poll "$case_dir" "$polled_at" "$code" "$task_tmp"
      if [[ "$code" == "200" ]]; then
        status="$(python3 - "$task_tmp" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    data = json.load(fh)
print(data.get("status", "unknown"))
PY
)"
        printf '%s\n' "$status" >"$case_dir/task_status.txt"
      fi
    fi

    pair="$(http_json GET "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/findings" 2>>"$case_dir/poll_errors.log" || true)"
    if [[ -n "$pair" ]]; then
      code="${pair%% *}"
      file="${pair#* }"
      cp "$file" "$findings_tmp"
      append_findings_poll "$case_dir" "$polled_at" "$code" "$findings_tmp"
    fi

    pair="$(http_json GET "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/summary" 2>>"$case_dir/poll_errors.log" || true)"
    if [[ -n "$pair" ]]; then
      code="${pair%% *}"
      file="${pair#* }"
      cp "$file" "$summary_tmp"
      append_summary_poll "$case_dir" "$polled_at" "$code" "$summary_tmp"
    fi

    if [[ "$status" == "completed" || "$status" == "failed" || "$status" == "cancelled" ]]; then
      return 0
    fi

    sleep "$POLL_INTERVAL_SECONDS"
    elapsed=$((elapsed + POLL_INTERVAL_SECONDS))
  done

  printf 'timeout\n' >"$case_dir/task_status.txt"
}

fetch_final_artifacts() {
  local case_dir="$1"
  fetch_case_endpoint "$case_dir" "task_object_final" "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID" >/dev/null || true
  fetch_case_endpoint "$case_dir" "task_summary_final" "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/summary" >/dev/null || true
  fetch_case_endpoint "$case_dir" "task_findings_final" "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/findings" >/dev/null || true
  fetch_case_endpoint "$case_dir" "task_events_final" "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/events" >/dev/null || true
}

run_instant_experiment() {
  local experiment_id="$1"
  local case_run_dir="$RUN_DIR/$experiment_id"
  local code_file="$REPO_ROOT/$CASE_DIR_REL/$CASE_SOURCE_FILE"
  local body pair code file start_ts end_ts
  mkdir -p "$case_run_dir"
  write_case_meta_instant "$case_run_dir" "$experiment_id"
  log "Running timing experiment $experiment_id"

  start_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
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
  pair="$(http_json POST "$BACKEND_URL/api/v1/scan/instant" "$body" 2>"$case_run_dir/instant_analysis.stderr.log")" || {
    echo "instant_analysis_failure" >"$case_run_dir/failure_classification.txt"
    return
  }
  end_ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  code="${pair%% *}"
  file="${pair#* }"
  copy_response_to_case "$case_run_dir" "instant_analysis" "$file"
  printf '%s\n' "$code" >"$case_run_dir/http_status.txt"

  python3 - "$case_run_dir" "$start_ts" "$end_ts" <<'PY'
import json
import os
import sys
from datetime import datetime

case_dir, start_ts, end_ts = sys.argv[1:]
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

def parse_ts(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00"))

duration = round((parse_ts(end_ts) - parse_ts(start_ts)).total_seconds(), 3)
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
    "duration_seconds": duration,
    "dominant_phase": "instant_sync",
    "total_iterations": None,
    "tool_calls_count": None,
    "tokens_used": None,
    "findings_count": len(findings),
    "poll_count": 1,
    "top_3_findings": [normalize_item(item) for item in findings[:3]],
    "timing": {
        "instant_started_at": start_ts,
        "instant_completed_at": end_ts,
        "wall_clock_total_seconds": duration,
    },
}
with open(os.path.join(case_dir, "metrics.json"), "w", encoding="utf-8") as fh:
    json.dump(metrics, fh, ensure_ascii=False, indent=2)

lines = ["# Timing Analysis", ""]
lines.append(f"- status: `{status}`")
lines.append(f"- classification: `{classification}`")
lines.append(f"- duration_seconds: `{duration}`")
lines.append(f"- dominant_phase: `instant_sync`")
lines.append("")
lines.append("## 阶段时间")
lines.append("")
lines.append(f"- wall_clock_total_seconds: `{duration}`")
lines.append("")
lines.append("## 前 3 条 finding")
lines.append("")
if findings:
    for item in findings[:3]:
        norm = normalize_item(item)
        lines.append(f"- `{norm.get('severity')}` | {norm.get('title')}")
else:
    lines.append("- 无")
with open(os.path.join(case_dir, "timing_analysis.md"), "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines) + "\n")
PY
}

write_case_outputs() {
  local case_dir="$1"
  python3 - "$case_dir" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone

case_dir = sys.argv[1]

def read_json(path, default):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return default
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)

def read_ndjson(path):
    items = []
    if not os.path.exists(path):
        return items
    with open(path, "r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            items.append(json.loads(line))
    return items

def parse_ts(value):
    if not value:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00"))

def to_iso(value):
    if value is None:
        return None
    return value.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")

def seconds_between(a, b):
    if a is None or b is None:
        return None
    return round((b - a).total_seconds(), 3)

task_polls = read_ndjson(os.path.join(case_dir, "task_poll.ndjson"))
findings_polls = read_ndjson(os.path.join(case_dir, "findings_poll.ndjson"))
summary_polls = read_ndjson(os.path.join(case_dir, "summary_poll.ndjson"))
step_times = read_json(os.path.join(case_dir, "step_times.json"), {})
final_task = read_json(os.path.join(case_dir, "task_object_final.json"), {})
final_findings = read_json(os.path.join(case_dir, "task_findings_final.json"), [])
final_summary = read_json(os.path.join(case_dir, "task_summary_final.json"), {})

timeline_rows = []
summary_by_poll = {item.get("polled_at"): item for item in summary_polls}
findings_by_poll = {item.get("polled_at"): item for item in findings_polls}
for item in task_polls:
    polled_at = item.get("polled_at")
    summary_item = summary_by_poll.get(polled_at, {})
    findings_item = findings_by_poll.get(polled_at, {})
    timeline_rows.append([
        polled_at or "",
        item.get("task_status") or "",
        item.get("current_phase") or "",
        "" if item.get("progress_percentage") is None else str(item.get("progress_percentage")),
        "" if item.get("total_iterations") is None else str(item.get("total_iterations")),
        "" if item.get("tool_calls_count") is None else str(item.get("tool_calls_count")),
        "" if item.get("tokens_used") is None else str(item.get("tokens_used")),
        "" if item.get("findings_count") is None else str(item.get("findings_count")),
        "" if findings_item.get("findings_count") is None else str(findings_item.get("findings_count")),
        "" if summary_item.get("duration_seconds") is None else str(summary_item.get("duration_seconds")),
    ])

with open(os.path.join(case_dir, "timeline.tsv"), "w", encoding="utf-8") as fh:
    fh.write("polled_at\ttask_status\tcurrent_phase\tprogress_percentage\ttotal_iterations\ttool_calls_count\ttokens_used\ttask_findings_count\tfindings_endpoint_count\tsummary_duration_seconds\n")
    for row in timeline_rows:
        fh.write("\t".join(row) + "\n")

T0 = parse_ts(step_times.get("upload_started_at"))
T1 = parse_ts(step_times.get("upload_completed_at"))
T2 = parse_ts(step_times.get("task_created_at"))
T3 = parse_ts(final_task.get("started_at"))
T7 = parse_ts(final_task.get("completed_at"))

T4 = None
T5 = None
T6 = None
for item in task_polls:
    ts = parse_ts(item.get("polled_at"))
    if T4 is None and item.get("current_phase") == "analysis":
        T4 = ts
    if T6 is None and item.get("current_phase") == "reporting":
        T6 = ts
for item in findings_polls:
    ts = parse_ts(item.get("polled_at"))
    if T5 is None and (item.get("findings_count") or 0) > 0:
        T5 = ts

T5_effective = T5
T6_effective = T6
if T5_effective is not None and T7 is not None and T5_effective > T7:
    T5_effective = T7
if T6_effective is not None and T7 is not None and T6_effective > T7:
    T6_effective = T7

status = "unknown"
status_path = os.path.join(case_dir, "task_status.txt")
if os.path.exists(status_path):
    status = open(status_path, "r", encoding="utf-8").read().strip()

classification = "unknown"
if status == "completed" and (final_task.get("findings_count") or 0) > 0:
    classification = "completed_with_findings"
elif status == "completed":
    classification = "completed_no_findings"
elif status == "timeout" and (final_task.get("findings_count") or 0) > 0:
    classification = "timeout_with_partial_signal"
elif status == "timeout":
    classification = "timeout_no_findings"
elif status in {"failed", "cancelled"}:
    classification = "runtime_failure"

top = []
for item in final_findings[:3]:
    if isinstance(item, dict):
        top.append({
            "title": item.get("title"),
            "severity": item.get("severity"),
            "file_path": item.get("file_path"),
            "vulnerability_type": item.get("vulnerability_type"),
            "confidence": item.get("confidence"),
        })

timing = {
    "T0_upload_started_at": to_iso(T0),
    "T1_upload_completed_at": to_iso(T1),
    "T2_task_created_at": to_iso(T2),
    "T3_task_started_at": to_iso(T3),
    "T4_first_analysis_phase_at": to_iso(T4),
    "T5_first_finding_seen_at_observed": to_iso(T5),
    "T6_first_reporting_phase_at_observed": to_iso(T6),
    "T7_task_completed_at": to_iso(T7),
    "upload_time_seconds": seconds_between(T0, T1),
    "queue_time_seconds": seconds_between(T2, T3),
    "planning_time_seconds": seconds_between(T3, T4),
    "analysis_before_first_finding_seconds": seconds_between(T4, T5_effective),
    "time_to_first_finding_seconds": seconds_between(T3, T5_effective),
    "analysis_tail_seconds": seconds_between(T5_effective, T6_effective),
    "reporting_time_seconds": seconds_between(T6_effective, T7),
    "wall_clock_total_seconds": seconds_between(T2, T7),
}

iterations = final_task.get("total_iterations")
tokens = final_task.get("tokens_used")
analysis_window = seconds_between(T4, T6_effective)
timing["avg_tokens_per_iteration"] = round(tokens / iterations, 3) if tokens and iterations else None
timing["avg_seconds_per_iteration"] = round(analysis_window / iterations, 3) if analysis_window is not None and iterations else None
timing["avg_tokens_per_second"] = round(tokens / seconds_between(T3, T7), 3) if tokens and seconds_between(T3, T7) not in (None, 0) else None

phase_candidates = [
    ("upload", timing["upload_time_seconds"]),
    ("queue", timing["queue_time_seconds"]),
    ("planning", timing["planning_time_seconds"]),
    ("analysis_before_first_finding", timing["analysis_before_first_finding_seconds"]),
    ("analysis_tail", timing["analysis_tail_seconds"]),
    ("reporting", timing["reporting_time_seconds"]),
]
phase_candidates = [item for item in phase_candidates if item[1] is not None]
dominant_phase = None
if phase_candidates:
    dominant_phase = max(phase_candidates, key=lambda item: item[1])[0]

with open(os.path.join(case_dir, "failure_classification.txt"), "w", encoding="utf-8") as fh:
    fh.write(classification + "\n")

metrics = {
    "status": status,
    "classification": classification,
    "duration_seconds": final_summary.get("duration_seconds"),
    "dominant_phase": dominant_phase,
    "total_iterations": final_task.get("total_iterations"),
    "tool_calls_count": final_task.get("tool_calls_count"),
    "tokens_used": final_task.get("tokens_used"),
    "findings_count": final_task.get("findings_count"),
    "poll_count": len(task_polls),
    "top_3_findings": top,
    "timing": timing,
}
with open(os.path.join(case_dir, "metrics.json"), "w", encoding="utf-8") as fh:
    json.dump(metrics, fh, ensure_ascii=False, indent=2)

lines = ["# Timing Analysis", ""]
lines.append(f"- status: `{status}`")
lines.append(f"- classification: `{classification}`")
lines.append(f"- duration_seconds: `{final_summary.get('duration_seconds')}`")
lines.append(f"- dominant_phase: `{dominant_phase}`")
lines.append("")
lines.append("## 阶段时间")
lines.append("")
for key in [
    "upload_time_seconds",
    "queue_time_seconds",
    "planning_time_seconds",
    "analysis_before_first_finding_seconds",
    "time_to_first_finding_seconds",
    "analysis_tail_seconds",
    "reporting_time_seconds",
    "wall_clock_total_seconds",
]:
    lines.append(f"- {key}: `{timing.get(key)}`")
lines.append("")
lines.append("## 效率指标")
lines.append("")
for key in [
    "avg_tokens_per_iteration",
    "avg_seconds_per_iteration",
    "avg_tokens_per_second",
]:
    lines.append(f"- {key}: `{timing.get(key)}`")
lines.append("")
lines.append("## 前 3 条 finding")
lines.append("")
if top:
    for item in top:
        lines.append(f"- `{item.get('severity')}` | {item.get('title')}")
else:
    lines.append("- 无")
with open(os.path.join(case_dir, "timing_analysis.md"), "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines) + "\n")
PY
}

run_agent_experiment() {
  local experiment_id="$1"
  local case_run_dir="$RUN_DIR/$experiment_id"
  mkdir -p "$case_run_dir"
  write_case_meta "$case_run_dir" "$experiment_id"
  log "Running timing experiment $experiment_id"
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
  poll_case_task "$case_run_dir"
  fetch_final_artifacts "$case_run_dir"
  write_case_outputs "$case_run_dir"
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
    "F1-PT-PY-FILE-001",
    "R1-PT-PY-FILE-001",
    "F1-REPEAT-PT-PY-FILE-001",
    "R1-REPEAT-PT-PY-FILE-001",
    "I1-PT-PY-FILE-001",
    "I1-REPEAT-PT-PY-FILE-001",
]
lines = [
    "experiment_id\tinput_mode\tstatus\tclassification\tduration_seconds\tdominant_phase\ttotal_iterations\ttool_calls_count\ttokens_used\tfindings_count\tupload_time_seconds\tplanning_time_seconds\tanalysis_before_first_finding_seconds\ttime_to_first_finding_seconds\treporting_time_seconds\twall_clock_total_seconds"
]

for experiment_id in experiments:
    case_dir = os.path.join(run_dir, experiment_id)
    meta = json.load(open(os.path.join(case_dir, "case_meta.json"), "r", encoding="utf-8"))
    metrics = json.load(open(os.path.join(case_dir, "metrics.json"), "r", encoding="utf-8"))
    timing = metrics.get("timing", {})
    row = [
        experiment_id,
        meta.get("input_mode"),
        metrics.get("status", ""),
        metrics.get("classification", ""),
        "" if metrics.get("duration_seconds") is None else str(metrics.get("duration_seconds")),
        metrics.get("dominant_phase", "") or "",
        "" if metrics.get("total_iterations") is None else str(metrics.get("total_iterations")),
        "" if metrics.get("tool_calls_count") is None else str(metrics.get("tool_calls_count")),
        "" if metrics.get("tokens_used") is None else str(metrics.get("tokens_used")),
        "" if metrics.get("findings_count") is None else str(metrics.get("findings_count")),
        "" if timing.get("upload_time_seconds") is None else str(timing.get("upload_time_seconds")),
        "" if timing.get("planning_time_seconds") is None else str(timing.get("planning_time_seconds")),
        "" if timing.get("analysis_before_first_finding_seconds") is None else str(timing.get("analysis_before_first_finding_seconds")),
        "" if timing.get("time_to_first_finding_seconds") is None else str(timing.get("time_to_first_finding_seconds")),
        "" if timing.get("reporting_time_seconds") is None else str(timing.get("reporting_time_seconds")),
        "" if timing.get("wall_clock_total_seconds") is None else str(timing.get("wall_clock_total_seconds")),
    ]
    lines.append("\t".join(row))

with open(summary_file, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines) + "\n")
PY
}

write_comparison() {
  python3 - "$RUN_DIR" <<'PY'
import json
import os
import sys

run_dir = sys.argv[1]
pairs = [
    ("首轮", "F1-PT-PY-FILE-001", "R1-PT-PY-FILE-001"),
    ("repeat", "F1-REPEAT-PT-PY-FILE-001", "R1-REPEAT-PT-PY-FILE-001"),
]
instant_pairs = [
    ("首轮", "I1-PT-PY-FILE-001"),
    ("repeat", "I1-REPEAT-PT-PY-FILE-001"),
]
metrics_by_experiment = {}
for _, file_id, repo_id in pairs:
    for experiment_id in (file_id, repo_id):
        if experiment_id not in metrics_by_experiment:
            metrics_by_experiment[experiment_id] = json.load(
                open(os.path.join(run_dir, experiment_id, "metrics.json"), "r", encoding="utf-8")
            )
for _, instant_id in instant_pairs:
    if instant_id not in metrics_by_experiment:
        metrics_by_experiment[instant_id] = json.load(
            open(os.path.join(run_dir, instant_id, "metrics.json"), "r", encoding="utf-8")
        )

def fmt(value):
    return "null" if value is None else str(value)

def pick_reason(metrics):
    phase = metrics.get("dominant_phase")
    mapping = {
        "upload": "上传/ZIP 处理",
        "queue": "任务排队或启动等待",
        "planning": "前期规划/侦察",
        "analysis_before_first_finding": "首个 finding 之前的分析阶段",
        "analysis_tail": "分析阶段后半程",
        "reporting": "报告收尾",
        "instant_sync": "同步 instant analysis",
    }
    return mapping.get(phase, phase or "未知")

lines = ["# File/Repo Timing Comparison", ""]
lines.append("## 摘要")
lines.append("")
repo_slower_count = 0
file_slower_count = 0
for pair_label, file_id, repo_id in pairs:
    file_metrics = metrics_by_experiment[file_id]
    repo_metrics = metrics_by_experiment[repo_id]
    instant_metrics = metrics_by_experiment[f"I1{'-REPEAT' if pair_label == 'repeat' else ''}-PT-PY-FILE-001"]
    file_total = file_metrics.get("timing", {}).get("wall_clock_total_seconds")
    repo_total = repo_metrics.get("timing", {}).get("wall_clock_total_seconds")
    instant_total = instant_metrics.get("timing", {}).get("wall_clock_total_seconds")
    if file_total is not None and repo_total is not None:
        if repo_total > file_total:
            repo_slower_count += 1
        elif file_total > repo_total:
            file_slower_count += 1
    lines.append(f"- {pair_label} file 总时长: `{fmt(file_total)}` 秒")
    lines.append(f"- {pair_label} repo 总时长: `{fmt(repo_total)}` 秒")
    lines.append(f"- {pair_label} instant 总时长: `{fmt(instant_total)}` 秒")
    lines.append(f"- {pair_label} file 主耗时阶段: `{pick_reason(file_metrics)}`")
    lines.append(f"- {pair_label} repo 主耗时阶段: `{pick_reason(repo_metrics)}`")
    lines.append(f"- {pair_label} instant 主耗时阶段: `{pick_reason(instant_metrics)}`")
lines.append("")
lines.append("## 分轮关键指标")
lines.append("")
for pair_label, file_id, repo_id in pairs:
    instant_id = f"I1{'-REPEAT' if pair_label == 'repeat' else ''}-PT-PY-FILE-001"
    for label, experiment_id in [("file", file_id), ("repo", repo_id), ("instant", instant_id)]:
        metrics = metrics_by_experiment[experiment_id]
        timing = metrics.get("timing", {})
        lines.append(f"### {pair_label} / {label}")
        lines.append("")
        lines.append(f"- experiment_id: `{experiment_id}`")
        lines.append(f"- duration_seconds: `{fmt(metrics.get('duration_seconds'))}`")
        lines.append(f"- total_iterations: `{fmt(metrics.get('total_iterations'))}`")
        lines.append(f"- tool_calls_count: `{fmt(metrics.get('tool_calls_count'))}`")
        lines.append(f"- tokens_used: `{fmt(metrics.get('tokens_used'))}`")
        lines.append(f"- planning_time_seconds: `{fmt(timing.get('planning_time_seconds'))}`")
        lines.append(f"- analysis_before_first_finding_seconds: `{fmt(timing.get('analysis_before_first_finding_seconds'))}`")
        lines.append(f"- time_to_first_finding_seconds: `{fmt(timing.get('time_to_first_finding_seconds'))}`")
        lines.append(f"- reporting_time_seconds: `{fmt(timing.get('reporting_time_seconds'))}`")
        lines.append(f"- avg_tokens_per_iteration: `{fmt(timing.get('avg_tokens_per_iteration'))}`")
        lines.append("")

lines.append("## 稳定性判断")
lines.append("")
lines.append(f"- repo 更慢次数: `{repo_slower_count}` / `{len(pairs)}`")
lines.append(f"- file 更慢次数: `{file_slower_count}` / `{len(pairs)}`")

if repo_slower_count == len(pairs):
    lines.append("- 在当前最小重复集上，`repo 更慢` 是稳定复现现象。")
elif repo_slower_count > 0:
    lines.append("- `repo 更慢` 只部分复现，说明该现象存在波动，不能视为完全稳定。")
elif file_slower_count == len(pairs):
    lines.append("- 在当前最小重复集上，反而是 `file 更慢` 更稳定。")
else:
    lines.append("- 当前最小重复集没有形成单边稳定优势，说明运行时抖动或任务形态差异交织存在。")

lines.append("")
lines.append("## 初步解释")
lines.append("")
if repo_slower_count > 0:
    lines.append("- 至少有一轮显示 repo 形态即使不增加迭代数，也会在单轮分析上花更久、消耗更多 token。")
if file_slower_count > 0:
    lines.append("- 至少有一轮显示 file 形态并不更快，说明 `repo 偏好` 不是简单的墙钟时间优势。")
instant_much_faster = True
for pair_label, file_id, repo_id in pairs:
    instant_id = f"I1{'-REPEAT' if pair_label == 'repeat' else ''}-PT-PY-FILE-001"
    instant_total = metrics_by_experiment[instant_id].get("timing", {}).get("wall_clock_total_seconds")
    file_total = metrics_by_experiment[file_id].get("timing", {}).get("wall_clock_total_seconds")
    repo_total = metrics_by_experiment[repo_id].get("timing", {}).get("wall_clock_total_seconds")
    if None in (instant_total, file_total, repo_total):
        instant_much_faster = False
        continue
    if not (instant_total < file_total / 3 and instant_total < repo_total / 3):
        instant_much_faster = False
if any(
    metrics_by_experiment[file_id].get("timing", {}).get("analysis_before_first_finding_seconds") is not None and
    metrics_by_experiment[repo_id].get("timing", {}).get("analysis_before_first_finding_seconds") is not None and
    metrics_by_experiment[repo_id]["timing"]["analysis_before_first_finding_seconds"] >
    metrics_by_experiment[file_id]["timing"]["analysis_before_first_finding_seconds"]
    for _, file_id, repo_id in pairs
):
    lines.append("- 多数成本仍集中在首个 finding 之前的分析阶段，而不是上传、排队或报告收尾。")
if instant_much_faster:
    lines.append("- instant analysis 在两轮里都远快于 agent file / repo，这强烈支持慢主要来自 agent 编排层，而不是基础语义识别本身。")
else:
    lines.append("- instant analysis 没有稳定形成数量级优势，因此“慢主要来自 agent 编排层”的结论仍需更谨慎。")

with open(os.path.join(run_dir, "comparison.md"), "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines) + "\n")
PY
}

run_all() {
  require_commands
  ensure_dirs
  write_run_manifest
  prepare_inputs
  register_or_login_diag_user
  run_agent_experiment "F1-PT-PY-FILE-001"
  run_agent_experiment "R1-PT-PY-FILE-001"
  run_agent_experiment "F1-REPEAT-PT-PY-FILE-001"
  run_agent_experiment "R1-REPEAT-PT-PY-FILE-001"
  run_instant_experiment "I1-PT-PY-FILE-001"
  run_instant_experiment "I1-REPEAT-PT-PY-FILE-001"
  write_run_summary
  write_comparison
  log "Timing artifacts written to $RUN_DIR"
}

run_instant_only() {
  require_commands
  ensure_dirs
  write_run_manifest
  register_or_login_diag_user
  run_instant_experiment "I1-PT-PY-FILE-001"
  run_instant_experiment "I1-REPEAT-PT-PY-FILE-001"
  write_run_summary
  write_comparison
  log "Instant timing artifacts written to $RUN_DIR"
}

render_existing() {
  local experiment_id
  for experiment_id in "${EXPERIMENT_IDS[@]}"; do
    write_case_outputs "$RUN_DIR/$experiment_id"
  done
  write_run_summary
  write_comparison
  log "Timing artifacts re-rendered in $RUN_DIR"
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
    render)
      render_existing
      ;;
    run-instant-only)
      run_instant_only
      ;;
    *)
      usage
      exit 2
      ;;
  esac
}

main "$@"
