#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env_deepseek"
SHARED_DIR="${DEEPAUDIT_SHARED_DIR:-/mnt/c/tmp/deepaudit}"
COMPOSE_URL="${DEEPAUDIT_COMPOSE_URL:-https://raw.githubusercontent.com/lintsinghua/DeepAudit/v3.0.0/docker-compose.prod.yml}"
COMPOSE_FILE="$SHARED_DIR/docker-compose.prod.yml"
BACKEND_ENV_FILE="$SHARED_DIR/backend.env"
PREFLIGHT_ZIP="$SHARED_DIR/preflight.zip"
PREFLIGHT_WORKDIR="${DEEPAUDIT_PREFLIGHT_WORKDIR:-/tmp/deepaudit_preflight}"
BACKEND_URL="${DEEPAUDIT_BACKEND_URL:-http://localhost:8000}"
FRONTEND_URL="${DEEPAUDIT_FRONTEND_URL:-http://localhost:3000}"
PROJECT_NAME="${DEEPAUDIT_COMPOSE_PROJECT_NAME:-deepaudit_smoke}"
PREFLIGHT_EMAIL="${DEEPAUDIT_PREFLIGHT_EMAIL:-deepaudit-preflight@example.com}"
PREFLIGHT_PASSWORD="${DEEPAUDIT_PREFLIGHT_PASSWORD:-DeepAuditPreflight123!}"
PREFLIGHT_FULL_NAME="${DEEPAUDIT_PREFLIGHT_FULL_NAME:-DeepAudit Preflight}"
PREFLIGHT_VULN="${DEEPAUDIT_PREFLIGHT_VULN:-path_traversal}"
PREFLIGHT_TIMEOUT="${DEEPAUDIT_PREFLIGHT_TIMEOUT:-300}"
PREFLIGHT_MAX_ITERATIONS="${DEEPAUDIT_PREFLIGHT_MAX_ITERATIONS:-3}"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
RESULT_DIR="$SHARED_DIR/preflight_results/$RUN_ID"
RESULT_FILE="$RESULT_DIR/result.env"

TOKEN=""
PROJECT_ID=""
TASK_ID=""

usage() {
  cat <<'EOF'
Usage:
  scripts/deepaudit_prepare_and_preflight.sh prepare
  scripts/deepaudit_prepare_and_preflight.sh preflight
  scripts/deepaudit_prepare_and_preflight.sh all
  scripts/deepaudit_prepare_and_preflight.sh cleanup

Commands:
  prepare    Prepare shared files, backend.env, compose file, and preflight.zip.
  preflight  Run HTTP-based preflight checks against an already running DeepAudit service.
  all        Run prepare, then preflight.
  cleanup    Remove the temporary preflight workspace and shared preflight.zip.
EOF
  print_network_context_notice
}

print_network_context_notice() {
  cat <<'EOF'

执行上下文约束：
  - 真实 Windows Docker Desktop 上的 DeepAudit 服务，必须在真实 WSL shell 或非沙箱/提权网络上下文中访问。
  - 受限沙箱执行环境可能处于不同的 network namespace，导致 localhost、127.0.0.1、172.x Windows 主机路由全部不可达。
  - 这类 `curl: (7) Couldn't connect to server` 不能直接判定为 DeepAudit 服务异常。
  - 对 Codex 工具调用，凡是需要真实访问 DeepAudit 服务的运行，应使用非沙箱/提权模式。
EOF
}

require_commands() {
  local missing=0
  for cmd in curl python3 sed awk mktemp; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Missing required command: $cmd" >&2
      missing=1
    fi
  done
  if [[ $missing -ne 0 ]]; then
    exit 2
  fi
}

ensure_shared_dir() {
  if ! mkdir -p "$SHARED_DIR" 2>/dev/null; then
    echo "Cannot create shared directory: $SHARED_DIR" >&2
    echo "If this is a local dry run inside a restricted environment, set DEEPAUDIT_SHARED_DIR to a writable path such as /tmp/deepaudit." >&2
    exit 2
  fi
}

log() {
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

write_result_header() {
  mkdir -p "$RESULT_DIR"
  {
    echo "run_id=$RUN_ID"
    echo "started_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "backend_url=$BACKEND_URL"
    echo "frontend_url=$FRONTEND_URL"
    echo "shared_dir=$SHARED_DIR"
    echo "compose_file=$COMPOSE_FILE"
  } >"$RESULT_FILE"
}

append_result() {
  printf '%s=%s\n' "$1" "$2" >>"$RESULT_FILE"
}

trim_cr() {
  printf '%s' "$1" | tr -d '\r'
}

load_env_source() {
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "Missing env source: $ENV_FILE" >&2
    exit 2
  fi

  # shellcheck disable=SC1090
  source "$ENV_FILE"

  export LLM_PROVIDER="${LLM_PROVIDER:-}"
  export LLM_MODEL="${LLM_MODEL:-}"
  export LLM_API_KEY="$(trim_cr "${LLM_API_KEY:-}")"
  export LLM_BASE_URL="$(trim_cr "${LLM_BASE_URL:-}")"

  if [[ -z "$LLM_PROVIDER" || -z "$LLM_MODEL" || -z "$LLM_API_KEY" ]]; then
    echo "LLM_PROVIDER, LLM_MODEL, and LLM_API_KEY must be present in $ENV_FILE" >&2
    exit 2
  fi
}

download_compose_file() {
  if [[ -f "$COMPOSE_FILE" && "${DEEPAUDIT_REFRESH_COMPOSE:-0}" != "1" ]]; then
    log "Reusing existing compose file at $COMPOSE_FILE"
    return
  fi
  log "Downloading official DeepAudit compose file"
  curl -fsSL "$COMPOSE_URL" -o "$COMPOSE_FILE"
}

generate_backend_env() {
  log "Generating minimal backend.env from .env_deepseek"
  {
    printf 'LLM_PROVIDER=%s\n' "$LLM_PROVIDER"
    printf 'LLM_MODEL=%s\n' "$LLM_MODEL"
    printf 'LLM_API_KEY=%s\n' "$LLM_API_KEY"
    printf 'LLM_BASE_URL=%s\n' "$LLM_BASE_URL"
    printf 'COMPOSE_PROJECT_NAME=%s\n' "$PROJECT_NAME"
  } >"$BACKEND_ENV_FILE"
}

show_backend_env_shape() {
  log "backend.env variable shape"
  sed -E 's/=.*/=<redacted>/' "$BACKEND_ENV_FILE"
}

create_preflight_zip() {
  log "Creating isolated preflight.zip"
  rm -rf "$PREFLIGHT_WORKDIR"
  mkdir -p "$PREFLIGHT_WORKDIR/src"
  cat >"$PREFLIGHT_WORKDIR/src/app.py" <<'EOF'
from flask import Flask, request

app = Flask(__name__)

@app.get("/ping")
def ping():
    return {"ok": True, "echo": request.args.get("q", "")}
EOF
  if command -v zip >/dev/null 2>&1; then
    (
      cd "$PREFLIGHT_WORKDIR"
      zip -qr "$PREFLIGHT_ZIP" src
    )
  else
    python3 - "$PREFLIGHT_WORKDIR" "$PREFLIGHT_ZIP" <<'PY'
import os
import sys
import zipfile

root = sys.argv[1]
zip_path = sys.argv[2]

with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for current_root, _, files in os.walk(root):
        for name in files:
            full_path = os.path.join(current_root, name)
            arcname = os.path.relpath(full_path, root)
            zf.write(full_path, arcname)
PY
  fi
}

prepare() {
  require_commands
  ensure_shared_dir
  load_env_source
  download_compose_file
  generate_backend_env
  create_preflight_zip
  show_backend_env_shape
  log "Prepared:"
  log "  compose: $COMPOSE_FILE"
  log "  backend env: $BACKEND_ENV_FILE"
  log "  preflight zip: $PREFLIGHT_ZIP"
}

http_json() {
  local method="$1"
  local url="$2"
  local body="${3:-}"
  local content_type="${4:-application/json}"
  local output_file
  output_file="$(mktemp)"
  local curl_args=(
    -sS
    -o "$output_file"
    -w '%{http_code}'
    -X "$method"
    "$url"
  )

  if [[ -n "$TOKEN" ]]; then
    curl_args+=(-H "Authorization: Bearer $TOKEN")
  fi

  if [[ -n "$body" ]]; then
    local code
    curl_args+=(-H "Content-Type: $content_type" --data "$body")
    code="$(curl "${curl_args[@]}")"
    printf '%s %s\n' "$code" "$output_file"
  else
    local code
    code="$(curl "${curl_args[@]}")"
    printf '%s %s\n' "$code" "$output_file"
  fi
}

http_form() {
  local method="$1"
  local url="$2"
  shift 2
  local output_file
  output_file="$(mktemp)"
  local code
  code="$(curl -sS -o "$output_file" -w '%{http_code}' -X "$method" "$url" "$@")"
  printf '%s %s\n' "$code" "$output_file"
}

extract_json_field() {
  local file="$1"
  local field="$2"
  python3 - "$file" "$field" <<'PY'
import json
import sys

path = sys.argv[1]
field = sys.argv[2]
with open(path, "r", encoding="utf-8") as fh:
    data = json.load(fh)

value = data
for part in field.split("."):
    if isinstance(value, dict):
        value = value[part]
    else:
        raise KeyError(part)
if isinstance(value, (dict, list)):
    print(json.dumps(value))
else:
    print(value)
PY
}

record_response() {
  local name="$1"
  local file="$2"
  cp "$file" "$RESULT_DIR/$name.json"
}

fail_preflight() {
  local classification="$1"
  local detail="$2"
  append_result "status" "failed"
  append_result "failure_classification" "$classification"
  append_result "failure_detail" "$(printf '%s' "$detail" | tr '\n' ' ' | tr '\r' ' ')"
  log "Preflight failed: $classification"
  log "$detail"
  exit 1
}

check_backend_health() {
  log "Checking backend health"
  local pair code file
  pair="$(http_json GET "$BACKEND_URL/health")" || fail_preflight "service_unreachable" "Backend health request failed"
  code="${pair%% *}"
  file="${pair#* }"
  record_response "backend_health" "$file"
  if [[ "$code" != "200" ]]; then
    fail_preflight "service_unreachable" "Expected backend health 200, got $code"
  fi
  append_result "backend_health" "passed"
}

check_frontend_head() {
  log "Checking frontend reachability"
  local output
  if ! output="$(curl -sSI "$FRONTEND_URL" 2>/dev/null)"; then
    fail_preflight "service_unreachable" "Frontend HEAD request failed"
  fi
  printf '%s\n' "$output" >"$RESULT_DIR/frontend_head.txt"
  append_result "frontend_head" "passed"
}

register_user() {
  log "Registering or confirming preflight user"
  local body pair code file detail
  body="$(cat <<EOF
{"email":"$PREFLIGHT_EMAIL","password":"$PREFLIGHT_PASSWORD","full_name":"$PREFLIGHT_FULL_NAME"}
EOF
)"
  pair="$(http_json POST "$BACKEND_URL/api/v1/auth/register" "$body")" || fail_preflight "auth_failure" "User registration request failed"
  code="${pair%% *}"
  file="${pair#* }"
  record_response "register_user" "$file"
  if [[ "$code" == "200" ]]; then
    append_result "user_registration" "created"
    return
  fi
  if [[ "$code" == "400" ]]; then
    detail="$(cat "$file")"
    if grep -q "已被注册" <<<"$detail"; then
      append_result "user_registration" "already_exists"
      return
    fi
  fi
  fail_preflight "auth_failure" "Registration failed with HTTP $code"
}

login_user() {
  log "Logging in preflight user"
  local pair code file
  pair="$(http_form POST "$BACKEND_URL/api/v1/auth/login" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode "username=$PREFLIGHT_EMAIL" \
    --data-urlencode "password=$PREFLIGHT_PASSWORD")" || fail_preflight "auth_failure" "Login request failed"
  code="${pair%% *}"
  file="${pair#* }"
  record_response "login_user" "$file"
  if [[ "$code" != "200" ]]; then
    fail_preflight "auth_failure" "Login failed with HTTP $code"
  fi
  TOKEN="$(extract_json_field "$file" "access_token")" || fail_preflight "auth_failure" "Could not parse access token"
  if [[ -z "$TOKEN" ]]; then
    fail_preflight "auth_failure" "Access token is empty"
  fi
  append_result "login" "passed"
}

create_zip_project() {
  log "Creating ZIP project"
  local body pair code file
  body='{"name":"DeepAudit Preflight ZIP Project","source_type":"zip","repository_type":"other","description":"Preflight-only project","default_branch":"main","programming_languages":["python"]}'
  pair="$(http_json POST "$BACKEND_URL/api/v1/projects/" "$body")" || fail_preflight "zip_project_failure" "Create project request failed"
  code="${pair%% *}"
  file="${pair#* }"
  record_response "create_project" "$file"
  if [[ "$code" != "200" ]]; then
    fail_preflight "zip_project_failure" "Create project failed with HTTP $code"
  fi
  PROJECT_ID="$(extract_json_field "$file" "id")" || fail_preflight "zip_project_failure" "Could not parse project id"
  append_result "project_id" "$PROJECT_ID"
}

upload_preflight_zip() {
  log "Uploading preflight.zip"
  if [[ ! -f "$PREFLIGHT_ZIP" ]]; then
    fail_preflight "zip_upload_failure" "Missing preflight zip at $PREFLIGHT_ZIP. Run prepare first."
  fi
  local output_file code
  output_file="$(mktemp)"
  code="$(curl -sS -o "$output_file" -w '%{http_code}' \
    -X POST "$BACKEND_URL/api/v1/projects/$PROJECT_ID/zip" \
    -H "Authorization: Bearer $TOKEN" \
    -F "file=@$PREFLIGHT_ZIP")" || fail_preflight "zip_upload_failure" "ZIP upload request failed"
  record_response "upload_zip" "$output_file"
  if [[ "$code" != "200" ]]; then
    fail_preflight "zip_upload_failure" "ZIP upload failed with HTTP $code"
  fi

  local pair meta_code meta_file
  pair="$(http_json GET "$BACKEND_URL/api/v1/projects/$PROJECT_ID/zip")" || fail_preflight "zip_upload_failure" "ZIP metadata lookup failed"
  meta_code="${pair%% *}"
  meta_file="${pair#* }"
  record_response "zip_metadata" "$meta_file"
  if [[ "$meta_code" != "200" ]]; then
    fail_preflight "zip_upload_failure" "ZIP metadata failed with HTTP $meta_code"
  fi
  append_result "zip_upload" "passed"
}

create_agent_task() {
  log "Creating minimal agent task"
  local body pair code file
  body="$(cat <<EOF
{"project_id":"$PROJECT_ID","name":"Preflight Agent Task","description":"Preflight-only task","target_vulnerabilities":["$PREFLIGHT_VULN"],"verification_level":"analysis_only","max_iterations":$PREFLIGHT_MAX_ITERATIONS,"timeout_seconds":$PREFLIGHT_TIMEOUT}
EOF
)"
  pair="$(http_json POST "$BACKEND_URL/api/v1/agent-tasks/" "$body")" || fail_preflight "agent_task_creation_failure" "Create task request failed"
  code="${pair%% *}"
  file="${pair#* }"
  record_response "create_task" "$file"
  if [[ "$code" != "200" ]]; then
    fail_preflight "agent_task_creation_failure" "Create task failed with HTTP $code"
  fi
  TASK_ID="$(extract_json_field "$file" "id")" || fail_preflight "agent_task_creation_failure" "Could not parse task id"
  append_result "task_id" "$TASK_ID"
}

check_task_observability() {
  log "Checking task observability"
  local success=0
  local pair code file

  pair="$(http_json GET "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID")" || true
  if [[ -n "$pair" ]]; then
    code="${pair%% *}"
    file="${pair#* }"
    record_response "task_object" "$file"
    if [[ "$code" == "200" ]]; then
      success=1
    fi
  fi

  pair="$(http_json GET "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/events")" || true
  if [[ -n "$pair" ]]; then
    code="${pair%% *}"
    file="${pair#* }"
    record_response "task_events" "$file"
    if [[ "$code" == "200" ]]; then
      success=1
    fi
  fi

  pair="$(http_json GET "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/findings")" || true
  if [[ -n "$pair" ]]; then
    code="${pair%% *}"
    file="${pair#* }"
    record_response "task_findings" "$file"
    if [[ "$code" == "200" ]]; then
      success=1
    fi
  fi

  pair="$(http_json GET "$BACKEND_URL/api/v1/agent-tasks/$TASK_ID/summary")" || true
  if [[ -n "$pair" ]]; then
    code="${pair%% *}"
    file="${pair#* }"
    record_response "task_summary" "$file"
    if [[ "$code" == "200" ]]; then
      success=1
    fi
  fi

  if [[ "$success" -ne 1 ]]; then
    fail_preflight "agent_observability_failure" "Could not get any structured task response from task object, events, findings, or summary"
  fi
  append_result "task_observability" "passed"
}

preflight() {
  require_commands
  ensure_shared_dir
  write_result_header
  check_backend_health
  check_frontend_head
  register_user
  login_user
  create_zip_project
  upload_preflight_zip
  create_agent_task
  check_task_observability
  append_result "status" "passed"
  append_result "finished_at" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  log "Preflight passed"
  log "Result file: $RESULT_FILE"
}

cleanup() {
  log "Cleaning up preflight temp artifacts"
  rm -rf "$PREFLIGHT_WORKDIR"
  rm -f "$PREFLIGHT_ZIP"
}

main() {
  local command="${1:-}"
  case "$command" in
    prepare)
      prepare
      ;;
    preflight)
      preflight
      ;;
    all)
      prepare
      preflight
      ;;
    cleanup)
      cleanup
      ;;
    *)
      usage
      exit 2
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
