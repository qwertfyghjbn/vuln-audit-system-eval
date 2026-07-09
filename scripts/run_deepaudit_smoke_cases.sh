#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/deepaudit_prepare_and_preflight.sh"

ARTIFACT_ROOT="${DEEPAUDIT_SMOKE_ARTIFACT_ROOT:-$REPO_ROOT/artifacts/deepaudit_smoke}"
SHARED_INPUT_DIR="${DEEPAUDIT_SMOKE_SHARED_INPUT_DIR:-/mnt/c/tmp/deepaudit/smoke_inputs}"
LOCAL_INPUT_WORKDIR="${DEEPAUDIT_SMOKE_LOCAL_INPUT_WORKDIR:-/tmp/deepaudit_smoke_inputs}"
RUN_ID="${DEEPAUDIT_SMOKE_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
RUN_DIR="$ARTIFACT_ROOT/$RUN_ID"
SMOKE_EMAIL="${DEEPAUDIT_SMOKE_EMAIL:-deepaudit-smoke@example.com}"
SMOKE_PASSWORD="${DEEPAUDIT_SMOKE_PASSWORD:-DeepAuditSmoke123!}"
SMOKE_FULL_NAME="${DEEPAUDIT_SMOKE_FULL_NAME:-DeepAudit Smoke}"
TASK_VERIFICATION_LEVEL="${DEEPAUDIT_SMOKE_VERIFICATION_LEVEL:-analysis_only}"
TASK_MAX_ITERATIONS="${DEEPAUDIT_SMOKE_MAX_ITERATIONS:-8}"
TASK_CREATE_TIMEOUT="${DEEPAUDIT_SMOKE_TASK_TIMEOUT:-900}"
POLL_INTERVAL_SECONDS="${DEEPAUDIT_SMOKE_POLL_INTERVAL:-10}"
DEFAULT_POLL_LIMIT_SECONDS="${DEEPAUDIT_SMOKE_POLL_LIMIT:-600}"

CASE_IDS=(
  "PT-PY-FILE-001"
  "PT-PY-FILE-002"
  "SSRF-PY-FILE-001"
  "PT-PY-REPO-001"
  "PT-PY-REPO-CVE-2024-32982-VULN"
)

declare -A CASE_DIRS=(
  ["PT-PY-FILE-001"]="datasets/synthetic/PT-PY-FILE-001"
  ["PT-PY-FILE-002"]="datasets/synthetic/PT-PY-FILE-002"
  ["SSRF-PY-FILE-001"]="datasets/synthetic/SSRF-PY-FILE-001"
  ["PT-PY-REPO-001"]="datasets/synthetic/PT-PY-REPO-001"
  ["PT-PY-REPO-CVE-2024-32982-VULN"]="datasets/real_world/PT-PY-REPO-CVE-2024-32982-VULN"
)

declare -A CASE_MODES=(
  ["PT-PY-FILE-001"]="file"
  ["PT-PY-FILE-002"]="file"
  ["SSRF-PY-FILE-001"]="file"
  ["PT-PY-REPO-001"]="repo"
  ["PT-PY-REPO-CVE-2024-32982-VULN"]="repo"
)

declare -A CASE_INPUT_PATHS=(
  ["PT-PY-FILE-001"]="app.py"
  ["PT-PY-FILE-002"]="app.py"
  ["SSRF-PY-FILE-001"]="app.py"
  ["PT-PY-REPO-001"]="src"
  ["PT-PY-REPO-CVE-2024-32982-VULN"]="repo"
)

declare -A CASE_VULNS=(
  ["PT-PY-FILE-001"]="path_traversal"
  ["PT-PY-FILE-002"]="path_traversal"
  ["SSRF-PY-FILE-001"]="ssrf"
  ["PT-PY-REPO-001"]="path_traversal"
  ["PT-PY-REPO-CVE-2024-32982-VULN"]="path_traversal"
)

declare -A CASE_POLL_LIMITS=(
  ["PT-PY-FILE-001"]="120"
  ["PT-PY-FILE-002"]="120"
  ["SSRF-PY-FILE-001"]="120"
  ["PT-PY-REPO-001"]="300"
  ["PT-PY-REPO-CVE-2024-32982-VULN"]="480"
)

usage() {
  cat <<'EOF'
Usage:
  scripts/run_deepaudit_smoke_cases.sh run
  scripts/run_deepaudit_smoke_cases.sh prepare-inputs
  scripts/run_deepaudit_smoke_cases.sh cleanup-inputs

Commands:
  run             Prepare clean ZIP inputs, execute the five smoke cases, and capture artifacts.
  prepare-inputs  Only prepare clean ZIP inputs for the fixed smoke cases.
  cleanup-inputs  Remove generated local and shared smoke inputs.
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
  "task_verification_level": "$TASK_VERIFICATION_LEVEL",
  "task_max_iterations": $TASK_MAX_ITERATIONS,
  "task_create_timeout_seconds": $TASK_CREATE_TIMEOUT,
  "poll_interval_seconds": $POLL_INTERVAL_SECONDS,
  "default_poll_limit_seconds": $DEFAULT_POLL_LIMIT_SECONDS,
  "llm_provider": "$LLM_PROVIDER",
  "llm_model": "$LLM_MODEL",
  "llm_base_url": "$LLM_BASE_URL"
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
  for case_id in "${CASE_IDS[@]}"; do
    log "Preparing clean input for $case_id"
    prepare_case_input "$case_id"
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

register_or_login_smoke_user() {
  PREFLIGHT_EMAIL="$SMOKE_EMAIL"
  PREFLIGHT_PASSWORD="$SMOKE_PASSWORD"
  PREFLIGHT_FULL_NAME="$SMOKE_FULL_NAME"
  register_user
  login_user
}

create_case_project() {
  local case_dir="$1"
  local case_id="$2"
  local body pair code file
  body="$(cat <<EOF
{"name":"$case_id","source_type":"zip","repository_type":"other","description":"DeepAudit smoke case $case_id","default_branch":"main","programming_languages":["python"]}
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
  local case_id="$2"
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

create_case_task() {
  local case_dir="$1"
  local case_id="$2"
  local vuln="${CASE_VULNS[$case_id]}"
  local body pair code file
  body="$(cat <<EOF
{"project_id":"$PROJECT_ID","name":"$case_id smoke task","description":"Smoke run for $case_id","target_vulnerabilities":["$vuln"],"verification_level":"$TASK_VERIFICATION_LEVEL","max_iterations":$TASK_MAX_ITERATIONS,"timeout_seconds":$TASK_CREATE_TIMEOUT}
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
  local case_id="$2"
  local poll_limit="${CASE_POLL_LIMITS[$case_id]:-$DEFAULT_POLL_LIMIT_SECONDS}"
  local elapsed=0
  local status=""
  local task_code=""
  local summary_code=""
  local findings_code=""
  local events_code=""

  while (( elapsed <= poll_limit )); do
    task_code="$(fetch_case_endpoint "$case_dir" "task_object" "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID" || true)"
    summary_code="$(fetch_case_endpoint "$case_dir" "task_summary" "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/summary" || true)"
    findings_code="$(fetch_case_endpoint "$case_dir" "task_findings" "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/findings" || true)"
    events_code="$(fetch_case_endpoint "$case_dir" "task_events" "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/events" || true)"

    if [[ "$task_code" == "200" ]]; then
      status="$(python3 - "$case_dir/task_object.json" <<'PY'
import json, sys
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
  local case_id="$2"
  cat >"$case_dir/case_meta.json" <<EOF
{
  "case_id": "$case_id",
  "source_case_dir": "${CASE_DIRS[$case_id]}",
  "input_mode": "${CASE_MODES[$case_id]}",
  "clean_input_path": "${CASE_INPUT_PATHS[$case_id]}",
  "target_vulnerability": "${CASE_VULNS[$case_id]}",
  "shared_zip": "$SHARED_INPUT_DIR/$case_id.zip",
  "poll_limit_seconds": ${CASE_POLL_LIMITS[$case_id]:-$DEFAULT_POLL_LIMIT_SECONDS}
}
EOF
}

classify_case_result() {
  local case_dir="$1"
  local status="unknown"
  if [[ -f "$case_dir/task_status.txt" ]]; then
    status="$(cat "$case_dir/task_status.txt")"
  fi
  case "$status" in
    completed)
      echo "completed"
      ;;
    failed)
      echo "runtime_failure"
      ;;
    cancelled)
      echo "runtime_failure"
      ;;
    timeout)
      echo "timeout"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

run_case() {
  local case_id="$1"
  local case_run_dir="$RUN_DIR/$case_id"
  mkdir -p "$case_run_dir"
  write_case_meta "$case_run_dir" "$case_id"

  log "Running smoke case $case_id"
  if ! create_case_project "$case_run_dir" "$case_id"; then
    echo "project_creation_failure" >"$case_run_dir/failure_classification.txt"
    return
  fi
  if ! upload_case_zip "$case_run_dir" "$case_id"; then
    echo "zip_upload_failure" >"$case_run_dir/failure_classification.txt"
    return
  fi
  if ! create_case_task "$case_run_dir" "$case_id"; then
    echo "agent_task_creation_failure" >"$case_run_dir/failure_classification.txt"
    return
  fi
  poll_case_task "$case_run_dir" "$case_id"
  classify_case_result "$case_run_dir" >"$case_run_dir/failure_classification.txt"
}

write_run_summary() {
  local summary_file="$RUN_DIR/summary.tsv"
  {
    printf 'case_id\tstatus\tclassification\tproject_id\ttask_id\n'
    for case_id in "${CASE_IDS[@]}"; do
      local case_dir="$RUN_DIR/$case_id"
      local status classification project_id task_id
      status="$(cat "$case_dir/task_status.txt" 2>/dev/null || echo "not_started")"
      classification="$(cat "$case_dir/failure_classification.txt" 2>/dev/null || echo "unknown")"
      project_id="$(cat "$case_dir/project_id.txt" 2>/dev/null || echo "")"
      task_id="$(cat "$case_dir/task_id.txt" 2>/dev/null || echo "")"
      printf '%s\t%s\t%s\t%s\t%s\n' "$case_id" "$status" "$classification" "$project_id" "$task_id"
    done
  } >"$summary_file"
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
  register_or_login_smoke_user
  for case_id in "${CASE_IDS[@]}"; do
    run_case "$case_id"
  done
  write_run_summary
  log "Smoke run artifacts written to $RUN_DIR"
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
