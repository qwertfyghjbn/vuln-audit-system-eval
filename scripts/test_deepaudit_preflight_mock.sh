#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED_DIR="$(mktemp -d /tmp/deepaudit-mock-test.XXXXXX)"
PORT="${DEEPAUDIT_MOCK_PORT:-18000}"
BACKEND_URL="http://127.0.0.1:$PORT"
FRONTEND_URL="$BACKEND_URL"
KEEP_ARTIFACTS="${DEEPAUDIT_MOCK_KEEP_ARTIFACTS:-0}"
MOCK_PID=""

cleanup() {
  if [[ -n "$MOCK_PID" ]] && kill -0 "$MOCK_PID" 2>/dev/null; then
    kill "$MOCK_PID" 2>/dev/null || true
    wait "$MOCK_PID" 2>/dev/null || true
  fi
  if [[ "$KEEP_ARTIFACTS" == "1" ]]; then
    log "Keeping artifacts in $SHARED_DIR"
  else
    rm -rf "$SHARED_DIR"
  fi
}

trap cleanup EXIT

log() {
  printf '[mock-test] %s\n' "$*"
}

assert_contains() {
  local file="$1"
  local expected="$2"
  if ! grep -q "^${expected}$" "$file"; then
    echo "Assertion failed: expected '$expected' in $file" >&2
    exit 1
  fi
}

prepare_local_compose_placeholder() {
  cat >"$SHARED_DIR/docker-compose.prod.yml" <<'EOF'
services:
  backend:
    image: mock/deepaudit:latest
EOF
}

start_mock() {
  log "Starting mock DeepAudit API on $BACKEND_URL"
  python3 "$REPO_ROOT/scripts/mock_deepaudit_api.py" --port "$PORT" >"$SHARED_DIR/mock.stdout.log" 2>"$SHARED_DIR/mock.stderr.log" &
  MOCK_PID="$!"
  sleep 1
  if ! kill -0 "$MOCK_PID" 2>/dev/null; then
    echo "Mock API failed to start" >&2
    cat "$SHARED_DIR/mock.stderr.log" >&2 || true
    exit 1
  fi
}

run_preflight() {
  log "Running prepare + preflight against mock service"
  DEEPAUDIT_SHARED_DIR="$SHARED_DIR" \
  DEEPAUDIT_BACKEND_URL="$BACKEND_URL" \
  DEEPAUDIT_FRONTEND_URL="$FRONTEND_URL" \
  DEEPAUDIT_REFRESH_COMPOSE=0 \
  "$REPO_ROOT/scripts/deepaudit_prepare_and_preflight.sh" all
}

verify_result() {
  local latest_run
  latest_run="$(find "$SHARED_DIR/preflight_results" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)"
  if [[ -z "$latest_run" ]]; then
    echo "No preflight result directory produced" >&2
    exit 1
  fi
  local result_file="$latest_run/result.env"
  log "Verifying result file $result_file"
  assert_contains "$result_file" "status=passed"
  assert_contains "$result_file" "backend_health=passed"
  assert_contains "$result_file" "frontend_head=passed"
  assert_contains "$result_file" "login=passed"
  assert_contains "$result_file" "zip_upload=passed"
  assert_contains "$result_file" "task_observability=passed"

  for artifact in \
    backend_health.json \
    register_user.json \
    login_user.json \
    create_project.json \
    zip_metadata.json \
    create_task.json \
    task_summary.json
  do
    if [[ ! -f "$latest_run/$artifact" ]]; then
      echo "Missing expected artifact: $latest_run/$artifact" >&2
      exit 1
    fi
  done

  log "Mock preflight self-test passed"
  log "Artifacts verified in $latest_run"
}

main() {
  prepare_local_compose_placeholder
  start_mock
  run_preflight
  verify_result
}

main "$@"
