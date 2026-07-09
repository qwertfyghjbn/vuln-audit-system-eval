#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/deepaudit_prepare_and_preflight.sh"

ARTIFACT_ROOT="${DEEPAUDIT_REPO_RUNNER_ARTIFACT_ROOT:-$REPO_ROOT/artifacts/deepaudit_repo_experiments}"
SHARED_INPUT_DIR="${DEEPAUDIT_REPO_RUNNER_SHARED_INPUT_DIR:-/tmp/deepaudit/repo_runner_inputs}"
LOCAL_INPUT_WORKDIR="${DEEPAUDIT_REPO_RUNNER_LOCAL_INPUT_WORKDIR:-/tmp/deepaudit_repo_runner_inputs}"
RUN_ID="${DEEPAUDIT_REPO_RUNNER_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
RUN_DIR="$ARTIFACT_ROOT/$RUN_ID"
RUNNER_EMAIL="${DEEPAUDIT_REPO_RUNNER_EMAIL:-deepaudit-repo-runner@example.com}"
RUNNER_PASSWORD="${DEEPAUDIT_REPO_RUNNER_PASSWORD:-DeepAuditRepoRunner123!}"
RUNNER_FULL_NAME="${DEEPAUDIT_REPO_RUNNER_FULL_NAME:-DeepAudit Repo Runner}"
POLL_INTERVAL_SECONDS="${DEEPAUDIT_REPO_RUNNER_POLL_INTERVAL:-10}"

SPEC_PATH=""
SPEC_BASENAME=""
SPEC_ENV_FILE=""
SPEC_TARGET_FILES_FILE=""
SPEC_SUBSET_FILES_FILE=""

EXPERIMENT_ID=""
CASE_ID=""
CASE_DIR=""
INPUT_PATH=""
LANGUAGE=""
TARGET_VULNERABILITY=""
SHAPE=""
LAYER=""
RUN_CLASS=""
DESCRIPTION=""
CONSTRAINT_SUMMARY=""
MAX_ITERATIONS=""
TASK_TIMEOUT_SECONDS=""
POLL_LIMIT_SECONDS=""

TOKEN=""
PROJECT_ID=""
TASK_ID=""

usage() {
  cat <<'EOF'
Usage:
  scripts/run_deepaudit_repo_experiment.sh run <spec.json>
  scripts/run_deepaudit_repo_experiment.sh prepare-input <spec.json>
  scripts/run_deepaudit_repo_experiment.sh cleanup-input <spec.json>
  scripts/run_deepaudit_repo_experiment.sh validate-spec <spec.json>

Spec requirements:
  - experiment_id
  - case_id
  - case_dir
  - input_path
  - language
  - target_vulnerability
  - shape
  - layer
  - run_class
  - description
  - constraint_summary
  - max_iterations
  - timeout_seconds
  - poll_limit_seconds
Optional:
  - target_files: ["path/a.py", ...]
  - subset_files: ["repo/a.py", ...]
EOF
  print_network_context_notice
}

ensure_dirs() {
  mkdir -p "$RUN_DIR"
  mkdir -p "$SHARED_INPUT_DIR"
  mkdir -p "$LOCAL_INPUT_WORKDIR"
}

init_auth_result_dir() {
  write_result_header
}

load_spec() {
  SPEC_PATH="$1"
  if [[ ! -f "$SPEC_PATH" ]]; then
    echo "Spec not found: $SPEC_PATH" >&2
    exit 2
  fi

  SPEC_BASENAME="$(basename "$SPEC_PATH")"
  mkdir -p "$RUN_DIR/_spec"
  SPEC_ENV_FILE="$RUN_DIR/_spec/${SPEC_BASENAME}.env"
  SPEC_TARGET_FILES_FILE="$RUN_DIR/_spec/${SPEC_BASENAME}.target_files"
  SPEC_SUBSET_FILES_FILE="$RUN_DIR/_spec/${SPEC_BASENAME}.subset_files"

  python3 - "$SPEC_PATH" "$SPEC_ENV_FILE" "$SPEC_TARGET_FILES_FILE" "$SPEC_SUBSET_FILES_FILE" <<'PY'
import json
import pathlib
import re
import shlex
import sys

spec_path = pathlib.Path(sys.argv[1])
env_path = pathlib.Path(sys.argv[2])
target_files_path = pathlib.Path(sys.argv[3])
subset_files_path = pathlib.Path(sys.argv[4])

spec = json.loads(spec_path.read_text(encoding="utf-8"))

required = [
    "experiment_id",
    "case_id",
    "case_dir",
    "input_path",
    "language",
    "target_vulnerability",
    "shape",
    "layer",
    "run_class",
    "description",
    "constraint_summary",
    "max_iterations",
    "timeout_seconds",
    "poll_limit_seconds",
]
missing = [key for key in required if key not in spec]
if missing:
    raise SystemExit(f"Missing required spec fields: {', '.join(missing)}")

for key in ("target_files", "subset_files"):
    value = spec.get(key)
    if value is not None and not isinstance(value, list):
        raise SystemExit(f"{key} must be a list when present")

for key in ("experiment_id", "case_id", "case_dir", "input_path", "language", "target_vulnerability"):
    if not isinstance(spec[key], str) or not spec[key].strip():
        raise SystemExit(f"{key} must be a non-empty string")

for key in ("max_iterations", "timeout_seconds", "poll_limit_seconds"):
    value = spec[key]
    if not isinstance(value, int) or value <= 0:
        raise SystemExit(f"{key} must be a positive integer")

if not re.fullmatch(r"[A-Za-z0-9._-]+", spec["experiment_id"]):
    raise SystemExit("experiment_id may only contain letters, digits, dot, underscore, and dash")

def emit_scalar(name: str, value) -> str:
    return f"{name}={shlex.quote(str(value))}\n"

with env_path.open("w", encoding="utf-8") as fh:
    fh.write(emit_scalar("EXPERIMENT_ID", spec["experiment_id"]))
    fh.write(emit_scalar("CASE_ID", spec["case_id"]))
    fh.write(emit_scalar("CASE_DIR", spec["case_dir"]))
    fh.write(emit_scalar("INPUT_PATH", spec["input_path"]))
    fh.write(emit_scalar("LANGUAGE", spec["language"]))
    fh.write(emit_scalar("TARGET_VULNERABILITY", spec["target_vulnerability"]))
    fh.write(emit_scalar("SHAPE", spec["shape"]))
    fh.write(emit_scalar("LAYER", spec["layer"]))
    fh.write(emit_scalar("RUN_CLASS", spec["run_class"]))
    fh.write(emit_scalar("DESCRIPTION", spec["description"]))
    fh.write(emit_scalar("CONSTRAINT_SUMMARY", spec["constraint_summary"]))
    fh.write(emit_scalar("MAX_ITERATIONS", spec["max_iterations"]))
    fh.write(emit_scalar("TASK_TIMEOUT_SECONDS", spec["timeout_seconds"]))
    fh.write(emit_scalar("POLL_LIMIT_SECONDS", spec["poll_limit_seconds"]))
    fh.write(emit_scalar("SPEC_SOURCE", str(spec_path)))
    fh.write(emit_scalar("HAS_TARGET_FILES", 1 if spec.get("target_files") else 0))
    fh.write(emit_scalar("HAS_SUBSET_FILES", 1 if spec.get("subset_files") else 0))

target_files = spec.get("target_files") or []
subset_files = spec.get("subset_files") or []
target_files_path.write_text("\n".join(target_files) + ("\n" if target_files else ""), encoding="utf-8")
subset_files_path.write_text("\n".join(subset_files) + ("\n" if subset_files else ""), encoding="utf-8")
PY

  # shellcheck disable=SC1090
  source "$SPEC_ENV_FILE"
}

write_run_manifest() {
  load_env_source
  python3 - "$RUN_DIR/run_manifest.json" "$RUN_ID" "$BACKEND_URL" "$FRONTEND_URL" "$SHARED_INPUT_DIR" "$POLL_INTERVAL_SECONDS" "$LLM_PROVIDER" "$LLM_MODEL" "$LLM_BASE_URL" <<'PY'
import json
import sys

output_path, run_id, backend_url, frontend_url, shared_input_dir, poll_interval_seconds, llm_provider, llm_model, llm_base_url = sys.argv[1:]
payload = {
    "run_id": run_id,
    "backend_url": backend_url,
    "frontend_url": frontend_url,
    "shared_input_dir": shared_input_dir,
    "poll_interval_seconds": int(poll_interval_seconds),
    "llm_provider": llm_provider,
    "llm_model": llm_model,
    "llm_base_url": llm_base_url,
    "runner_kind": "parameterized_repo_experiment",
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

register_or_login_runner_user() {
  PREFLIGHT_EMAIL="$RUNNER_EMAIL"
  PREFLIGHT_PASSWORD="$RUNNER_PASSWORD"
  PREFLIGHT_FULL_NAME="$RUNNER_FULL_NAME"
  register_user
  login_user
}

prepare_experiment_input() {
  local source_root="$REPO_ROOT/$CASE_DIR"
  local source_path="$source_root/$INPUT_PATH"
  local local_case_dir="$LOCAL_INPUT_WORKDIR/$EXPERIMENT_ID"
  local shared_zip="$SHARED_INPUT_DIR/$EXPERIMENT_ID.zip"
  local relative_path

  if [[ ! -e "$source_path" ]]; then
    echo "Input path not found: $source_path" >&2
    exit 2
  fi

  rm -rf "$local_case_dir"
  mkdir -p "$local_case_dir"

  if [[ "${HAS_SUBSET_FILES:-0}" == "1" ]]; then
    while IFS= read -r relative_path; do
      [[ -n "$relative_path" ]] || continue
      mkdir -p "$local_case_dir/$(dirname "$relative_path")"
      cp "$source_root/$relative_path" "$local_case_dir/$relative_path"
    done <"$SPEC_SUBSET_FILES_FILE"
  else
    cp -r "$source_path" "$local_case_dir/"
  fi

  rm -f "$shared_zip"
  zip_dir "$local_case_dir" "$shared_zip"
}

cleanup_experiment_input() {
  rm -rf "$LOCAL_INPUT_WORKDIR/$EXPERIMENT_ID"
  rm -f "$SHARED_INPUT_DIR/$EXPERIMENT_ID.zip"
}

write_case_meta() {
  local case_dir="$1"
  python3 - "$SPEC_PATH" "$case_dir/case_meta.json" "$SHARED_INPUT_DIR/$EXPERIMENT_ID.zip" <<'PY'
import json
import pathlib
import sys

spec_path = pathlib.Path(sys.argv[1])
output_path = pathlib.Path(sys.argv[2])
shared_zip = sys.argv[3]

spec = json.loads(spec_path.read_text(encoding="utf-8"))
payload = {
    "experiment_id": spec["experiment_id"],
    "case_id": spec["case_id"],
    "shape": spec["shape"],
    "layer": spec["layer"],
    "run_class": spec["run_class"],
    "kind": "agent_task",
    "language": spec["language"],
    "target_vulnerability": spec["target_vulnerability"],
    "source_case_dir": spec["case_dir"],
    "input_path": spec["input_path"],
    "shared_zip": shared_zip,
    "target_files": spec.get("target_files"),
    "subset_files": spec.get("subset_files"),
    "max_iterations": spec["max_iterations"],
    "task_timeout_seconds": spec["timeout_seconds"],
    "poll_limit_seconds": spec["poll_limit_seconds"],
    "description": spec["description"],
    "constraint_summary": spec["constraint_summary"],
    "spec_source": str(spec_path),
}
output_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
PY
}

copy_spec_to_artifacts() {
  local case_dir="$1"
  cp "$SPEC_PATH" "$case_dir/spec.json"
}

create_case_project() {
  local case_dir="$1"
  local body pair code file
  body="$(python3 - "$EXPERIMENT_ID" "$LANGUAGE" "$DESCRIPTION" <<'PY'
import json
import sys

experiment_id, language, description = sys.argv[1:]
payload = {
    "name": experiment_id,
    "source_type": "zip",
    "repository_type": "other",
    "description": description,
    "default_branch": "main",
    "programming_languages": [language],
}
print(json.dumps(payload, ensure_ascii=True))
PY
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
  local output_file code metadata_code
  output_file="$(mktemp)"
  code="$(curl -sS -o "$output_file" -w '%{http_code}' \
    -X POST "$BACKEND_URL/api/v1/projects/$PROJECT_ID/zip" \
    -H "Authorization: Bearer $TOKEN" \
    -F "file=@$zip_path")" || return 1
  copy_response_to_case "$case_dir" "upload_zip" "$output_file"
  [[ "$code" == "200" ]] || return 1
  metadata_code="$(fetch_case_endpoint "$case_dir" "zip_metadata" "$BACKEND_URL/api/v1/projects/$PROJECT_ID/zip")" || return 1
  [[ "$metadata_code" == "200" ]] || return 1
}

json_array_from_file() {
  local list_file="$1"
  python3 - "$list_file" <<'PY'
import json
import pathlib
import sys

items = [line.strip() for line in pathlib.Path(sys.argv[1]).read_text(encoding="utf-8").splitlines() if line.strip()]
print(json.dumps(items, ensure_ascii=True))
PY
}

create_case_task() {
  local case_dir="$1"
  local body pair code file
  local target_files_json="null"

  if [[ "${HAS_TARGET_FILES:-0}" == "1" ]]; then
    target_files_json="$(json_array_from_file "$SPEC_TARGET_FILES_FILE")"
  fi

  body="$(python3 - "$PROJECT_ID" "$EXPERIMENT_ID" "$CASE_ID" "$TARGET_VULNERABILITY" "$MAX_ITERATIONS" "$TASK_TIMEOUT_SECONDS" "$target_files_json" <<'PY'
import json
import sys

project_id, experiment_id, case_id, vuln, max_iterations, timeout_seconds, target_files_json = sys.argv[1:]
payload = {
    "project_id": project_id,
    "name": f"{experiment_id} task",
    "description": f"Parameterized repo run {experiment_id} for {case_id}",
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
  local elapsed=0
  local status=""
  while (( elapsed <= POLL_LIMIT_SECONDS )); do
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

write_summary_matrix() {
  local summary_file="$RUN_DIR/experiment_matrix.tsv"
  python3 - "$RUN_DIR" "$summary_file" <<'PY'
import csv
import json
import os
import sys

run_dir = sys.argv[1]
summary_file = sys.argv[2]

fieldnames = [
    "experiment_id",
    "shape",
    "layer",
    "case_id",
    "run_class",
    "constraint_summary",
    "status",
    "total_iterations",
    "tool_calls_count",
    "tokens_used",
    "wall_clock_seconds",
    "findings_count",
    "top_3_findings",
    "target_signal",
    "noise_shape",
    "ranking_quality",
    "usability_tier",
    "notes",
]

def read_json(path):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return {}
    with open(path, "r", encoding="utf-8") as fh:
        return json.load(fh)

rows = []
for name in sorted(os.listdir(run_dir)):
    case_dir = os.path.join(run_dir, name)
    if not os.path.isdir(case_dir) or name.startswith("_"):
        continue
    meta = read_json(os.path.join(case_dir, "case_meta.json"))
    metrics = read_json(os.path.join(case_dir, "metrics.json"))
    if not meta or not metrics:
        continue
    rows.append({
        "experiment_id": meta.get("experiment_id", name),
        "shape": meta.get("shape", ""),
        "layer": meta.get("layer", ""),
        "case_id": meta.get("case_id", ""),
        "run_class": meta.get("run_class", ""),
        "constraint_summary": meta.get("constraint_summary", meta.get("description", "")),
        "status": metrics.get("status", ""),
        "total_iterations": metrics.get("total_iterations"),
        "tool_calls_count": metrics.get("tool_calls_count"),
        "tokens_used": metrics.get("tokens_used"),
        "wall_clock_seconds": metrics.get("wall_clock_seconds"),
        "findings_count": metrics.get("findings_count"),
        "top_3_findings": json.dumps(metrics.get("top_3_findings", []), ensure_ascii=False),
        "target_signal": "",
        "noise_shape": "",
        "ranking_quality": "",
        "usability_tier": "",
        "notes": "",
    })

with open(summary_file, "w", encoding="utf-8", newline="") as fh:
    writer = csv.DictWriter(fh, fieldnames=fieldnames, delimiter="\t", extrasaction="ignore")
    writer.writeheader()
    for row in rows:
        writer.writerow(row)
PY
}

validate_spec() {
  load_spec "$1"
  printf 'experiment_id=%s\n' "$EXPERIMENT_ID"
  printf 'case_id=%s\n' "$CASE_ID"
  printf 'case_dir=%s\n' "$CASE_DIR"
  printf 'input_path=%s\n' "$INPUT_PATH"
  printf 'language=%s\n' "$LANGUAGE"
  printf 'target_vulnerability=%s\n' "$TARGET_VULNERABILITY"
  printf 'shape=%s\n' "$SHAPE"
  printf 'layer=%s\n' "$LAYER"
  printf 'run_class=%s\n' "$RUN_CLASS"
  printf 'max_iterations=%s\n' "$MAX_ITERATIONS"
  printf 'timeout_seconds=%s\n' "$TASK_TIMEOUT_SECONDS"
  printf 'poll_limit_seconds=%s\n' "$POLL_LIMIT_SECONDS"
}

prepare_one() {
  load_spec "$1"
  require_commands
  ensure_dirs
  prepare_experiment_input
  log "Prepared input zip for $EXPERIMENT_ID at $SHARED_INPUT_DIR/$EXPERIMENT_ID.zip"
}

cleanup_one() {
  load_spec "$1"
  cleanup_experiment_input
  log "Cleaned input artifacts for $EXPERIMENT_ID"
}

run_one() {
  local case_run_dir
  load_spec "$1"
  require_commands
  ensure_dirs
  init_auth_result_dir
  write_run_manifest
  prepare_experiment_input
  register_or_login_runner_user

  case_run_dir="$RUN_DIR/$EXPERIMENT_ID"
  mkdir -p "$case_run_dir"
  copy_spec_to_artifacts "$case_run_dir"
  write_case_meta "$case_run_dir"

  log "Running repo experiment $EXPERIMENT_ID"
  if ! create_case_project "$case_run_dir"; then
    echo "project_creation_failure" >"$case_run_dir/failure_classification.txt"
    return 1
  fi
  if ! upload_case_zip "$case_run_dir"; then
    echo "zip_upload_failure" >"$case_run_dir/failure_classification.txt"
    return 1
  fi
  if ! create_case_task "$case_run_dir"; then
    echo "agent_task_creation_failure" >"$case_run_dir/failure_classification.txt"
    return 1
  fi
  poll_case_task "$case_run_dir"
  write_case_outputs "$case_run_dir"
  write_summary_matrix
  log "Repo experiment artifacts written to $RUN_DIR"
}

main() {
  local command="${1:-}"
  case "$command" in
    run|prepare-input|cleanup-input|validate-spec)
      if [[ $# -ne 2 ]]; then
        usage
        exit 2
      fi
      ;;
    *)
      usage
      [[ -n "$command" ]] || exit 2
      exit 2
      ;;
  esac

  case "$command" in
    run)
      run_one "$2"
      ;;
    prepare-input)
      prepare_one "$2"
      ;;
    cleanup-input)
      cleanup_one "$2"
      ;;
    validate-spec)
      validate_spec "$2"
      ;;
  esac
}

main "$@"
