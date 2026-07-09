#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/iris_prepare_and_preflight.sh"

IRIS_SMOKE_ARTIFACT_ROOT="${IRIS_SMOKE_ARTIFACT_ROOT:-$REPO_ROOT/artifacts/iris_smoke}"
IRIS_SMOKE_LOCAL_INPUT_ROOT="${IRIS_SMOKE_LOCAL_INPUT_ROOT:-/tmp/iris_smoke_inputs}"
RUN_ID="${IRIS_SMOKE_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
RUN_DIR="$IRIS_SMOKE_ARTIFACT_ROOT/$RUN_ID"
RUN_MANIFEST_FILE="$RUN_DIR/run_manifest.json"
SMOKE_DERIVED_ENV_FILE="$RUN_DIR/iris.env"
SUMMARY_FILE="$RUN_DIR/summary.tsv"
RUNNER_STATUS_FILE="$RUN_DIR/run_status.env"

usage() {
  cat <<'EOF'
Usage:
  scripts/run_iris_smoke_cases.sh prepare-inputs
  scripts/run_iris_smoke_cases.sh plan
  scripts/run_iris_smoke_cases.sh run
  scripts/run_iris_smoke_cases.sh cleanup-inputs

Commands:
  prepare-inputs  Prepare clean input directories for the five fixed IRIS smoke cases.
  plan            Prepare inputs and write per-case execution plans without invoking IRIS.
  run             Prepare inputs, write execution plans, execute them case-by-case, and capture artifacts.
  cleanup-inputs  Remove generated local smoke inputs for the current run id.
EOF
}

ensure_dirs() {
  mkdir -p "$RUN_DIR"
  mkdir -p "$IRIS_SMOKE_LOCAL_INPUT_ROOT/$RUN_ID"
}

init_run_status() {
  {
    printf 'run_id=%s\n' "$RUN_ID"
    printf 'started_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } >"$RUNNER_STATUS_FILE"
}

append_run_status() {
  printf '%s=%s\n' "$1" "$2" >>"$RUNNER_STATUS_FILE"
}

write_run_manifest() {
  load_env_source
  cat >"$RUN_MANIFEST_FILE" <<EOF
{
  "run_id": "$RUN_ID",
  "system_name": "iris",
  "run_stage": "smoke",
  "native_evaluation_environment": true,
  "iris_root": "$IRIS_ROOT",
  "derived_env_source": "$ENV_FILE",
  "derived_env_file": "$SMOKE_DERIVED_ENV_FILE",
  "llm_provider": "$LLM_PROVIDER",
  "llm_model": "$LLM_MODEL",
  "llm_base_url": "$LLM_BASE_URL",
  "case_count": ${#CASE_IDS[@]}
}
EOF
}

write_smoke_derived_env() {
  load_env_source
  {
    printf 'IRIS_LLM_PROVIDER=%s\n' "$LLM_PROVIDER"
    printf 'IRIS_LLM_MODEL=%s\n' "$LLM_MODEL"
    printf 'IRIS_LLM_BASE_URL=%s\n' "$LLM_BASE_URL"
    printf 'OPENAI_API_KEY=%s\n' "$LLM_API_KEY"
    printf 'OPENAI_BASE_URL=%s\n' "$LLM_BASE_URL"
    printf 'OPENAI_MODEL=%s\n' "$LLM_MODEL"
  } >"$SMOKE_DERIVED_ENV_FILE"
  chmod 600 "$SMOKE_DERIVED_ENV_FILE"
}

init_summary() {
  {
    printf 'case_id\tvuln_type\tquery_id\tprepared_input_dir\tstatus\tnotes\n'
  } >"$SUMMARY_FILE"
}

append_summary() {
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" "$6" >>"$SUMMARY_FILE"
}

copy_tree_contents() {
  local source_dir="$1"
  local dest_dir="$2"
  mkdir -p "$dest_dir"
  cp -R "$source_dir"/. "$dest_dir"/
}

prepare_case_input() {
  local case_id="$1"
  local case_root="$REPO_ROOT/${CASE_DIRS[$case_id]}"
  local source_root="$case_root/${CASE_SOURCE_ROOTS[$case_id]}"
  local local_case_root="$IRIS_SMOKE_LOCAL_INPUT_ROOT/$RUN_ID/$case_id"
  local input_root="$local_case_root/input"
  local artifact_dir="$RUN_DIR/$case_id"

  rm -rf "$local_case_root"
  mkdir -p "$input_root"
  mkdir -p "$artifact_dir"

  copy_tree_contents "$source_root" "$input_root"

  if [[ -d "$case_root/build_support" ]]; then
    copy_tree_contents "$case_root/build_support" "$input_root/build_support"
  fi

  cat >"$artifact_dir/case_meta.json" <<EOF
{
  "case_id": "$case_id",
  "project_slug": "${CASE_PROJECT_SLUGS[$case_id]}",
  "case_dir": "${CASE_DIRS[$case_id]}",
  "vuln_type": "${CASE_VULNS[$case_id]}",
  "query_id": "${CASE_QUERY_IDS[$case_id]}",
  "source_root": "${CASE_SOURCE_ROOTS[$case_id]}",
  "compile_recipe": "${CASE_COMPILE_RECIPE_PATHS[$case_id]}",
  "prepared_input_dir": "$input_root",
  "run_class": "smoke experiment"
}
EOF

  cat >"$artifact_dir/input_contract.json" <<EOF
{
  "clean_input_root": "$input_root",
  "compile_recipe_present": $(if [[ -f "$input_root/${CASE_COMPILE_RECIPE_PATHS[$case_id]}" ]]; then printf 'true'; else printf 'false'; fi),
  "fallback_strategy": "copy_case_source_root_if_no_compile_recipe"
}
EOF
}

prepare_inputs() {
  require_base_commands
  ensure_dirs
  write_run_manifest
  write_smoke_derived_env
  local case_id
  for case_id in "${CASE_IDS[@]}"; do
    log "Preparing clean input for $case_id"
    prepare_case_input "$case_id"
  done
}

render_case_execution_plan() {
  local case_id="$1"
  local artifact_dir="$RUN_DIR/$case_id"
  local input_root="$IRIS_SMOKE_LOCAL_INPUT_ROOT/$RUN_ID/$case_id/input"
  local plan_file="$artifact_dir/planned_command.sh"
  local project_slug="${CASE_PROJECT_SLUGS[$case_id]}"

  cat >"$plan_file" <<EOF
#!/usr/bin/env bash
set -euo pipefail

set -a
source "$SMOKE_DERIVED_ENV_FILE"
set +a

CASE_ID="$case_id"
PROJECT_SLUG="$project_slug"
INPUT_ROOT="$input_root"
QUERY_ID="${CASE_QUERY_IDS[$case_id]}"
IRIS_ROOT="${IRIS_ROOT}"
IRIS_PYTHON_BIN="${IRIS_PYTHON_BIN}"
IRIS_JAVA_HOME="${IRIS_JAVA_HOME}"
RUN_ID="$RUN_ID"
ARTIFACT_DIR="$artifact_dir"
IRIS_LLM_ALIAS="\${IRIS_LLM_ALIAS:-gpt-4}"
IRIS_NUM_THREADS="\${IRIS_NUM_THREADS:-3}"
IRIS_CODEQL_BIN="\${IRIS_CODEQL_BIN:-${IRIS_CODEQL_BIN}}"
IRIS_BUILD_ROOT="\${IRIS_BUILD_ROOT:-/tmp/iris_build/\$PROJECT_SLUG}"
IRIS_SOURCE_DEST="\$IRIS_ROOT/data/project-sources/\$PROJECT_SLUG"
IRIS_DB_DEST="\$IRIS_ROOT/data/codeql-dbs/\$PROJECT_SLUG"
IRIS_PACKAGE_FILE="\$IRIS_ROOT/data/package-names/\$PROJECT_SLUG.txt"
IRIS_OUTPUT_DIR="\$IRIS_ROOT/output/\$PROJECT_SLUG/\$RUN_ID"
CLASSES_DIR="\$IRIS_BUILD_ROOT/classes"

if [[ -d "\$IRIS_JAVA_HOME/bin" ]]; then
  export JAVA_HOME="\$IRIS_JAVA_HOME"
  export PATH="\$IRIS_JAVA_HOME/bin:\$PATH"
fi

if [[ -z "\$IRIS_CODEQL_BIN" ]]; then
  IRIS_CODEQL_BIN="\$(command -v codeql || true)"
fi

if [[ -z "\$IRIS_CODEQL_BIN" ]]; then
  echo "Could not resolve codeql binary" >&2
  exit 2
fi

IRIS_CODEQL_DIR="\${IRIS_CODEQL_DIR:-\$(cd "\$(dirname "\$IRIS_CODEQL_BIN")" && pwd)}"
export IRIS_ROOT IRIS_PYTHON_BIN IRIS_JAVA_HOME IRIS_CODEQL_BIN IRIS_CODEQL_DIR IRIS_LLM_ALIAS IRIS_NUM_THREADS

mkdir -p "\$IRIS_ROOT/data/project-sources" "\$IRIS_ROOT/data/codeql-dbs" "\$IRIS_ROOT/data/package-names" "\$IRIS_BUILD_ROOT"
rm -rf "\$IRIS_SOURCE_DEST" "\$IRIS_DB_DEST" "\$IRIS_OUTPUT_DIR" "\$CLASSES_DIR"
mkdir -p "\$IRIS_SOURCE_DEST" "\$CLASSES_DIR" "\$ARTIFACT_DIR"
cp -R "\$INPUT_ROOT"/. "\$IRIS_SOURCE_DEST"/

"\$IRIS_PYTHON_BIN" - "\$IRIS_SOURCE_DEST" "\$IRIS_PACKAGE_FILE" <<'PY'
import os
import re
import sys

source_root = sys.argv[1]
package_file = sys.argv[2]
packages = set()

for current_root, _, files in os.walk(source_root):
    for name in files:
        if not name.endswith(".java"):
            continue
        path = os.path.join(current_root, name)
        try:
            with open(path, "r", encoding="utf-8") as fh:
                for line in fh:
                    match = re.match(r"\\s*package\\s+([a-zA-Z0-9_.]+)\\s*;", line)
                    if match:
                        packages.add(match.group(1))
                        break
        except OSError:
            continue

with open(package_file, "w", encoding="utf-8") as fh:
    for item in sorted(packages):
        fh.write(item + "\\n")
PY

BUILD_COMMAND="\$("\$IRIS_PYTHON_BIN" - "\$IRIS_SOURCE_DEST" "\$CLASSES_DIR" <<'PY'
import json
import os
import shlex
import sys

source_root = sys.argv[1]
classes_dir = sys.argv[2]
recipe_path = os.path.join(source_root, "build_support", "java_compile_recipe.json")

selected = []
if os.path.exists(recipe_path):
    with open(recipe_path, "r", encoding="utf-8") as fh:
        recipe = json.load(fh)
    selected.extend(recipe.get("source_files", []))
    for stub_root in recipe.get("stub_source_roots", []):
        abs_stub_root = os.path.join(source_root, stub_root)
        if os.path.isdir(abs_stub_root):
            for current_root, _, files in os.walk(abs_stub_root):
                for name in files:
                    if name.endswith(".java"):
                        selected.append(os.path.relpath(os.path.join(current_root, name), source_root))
else:
    for current_root, _, files in os.walk(source_root):
        if "build_support/stubs" in current_root:
            continue
        for name in files:
            if name.endswith(".java"):
                selected.append(os.path.relpath(os.path.join(current_root, name), source_root))

ordered = []
seen = set()
for item in selected:
    if item not in seen:
        seen.add(item)
        ordered.append(item)

if not ordered:
    raise SystemExit("No Java sources selected for CodeQL build")

command = ["javac", "-proc:none", "-d", classes_dir]
command.extend(os.path.join(source_root, item) for item in ordered)
print(" ".join(shlex.quote(part) for part in command))
PY
)"

(
  cd "\$IRIS_ROOT"
  "\$IRIS_CODEQL_BIN" database create "\$IRIS_DB_DEST" \\
    --source-root "\$IRIS_SOURCE_DEST" \\
    --language java \\
    --overwrite \\
    --command "\$BUILD_COMMAND"

  "\$IRIS_PYTHON_BIN" src/iris.py "\$PROJECT_SLUG" \\
    --query "\$QUERY_ID" \\
    --run-id "\$RUN_ID" \\
    --llm "\$IRIS_LLM_ALIAS" \\
    --num-threads "\$IRIS_NUM_THREADS" \\
    --skip-evaluation \\
    --overwrite
)

if [[ -d "\$IRIS_OUTPUT_DIR" ]]; then
  rm -rf "\$ARTIFACT_DIR/iris_output"
  cp -R "\$IRIS_OUTPUT_DIR" "\$ARTIFACT_DIR/iris_output"
fi
EOF
  chmod +x "$plan_file"
}

render_all_plans() {
  local case_id
  for case_id in "${CASE_IDS[@]}"; do
    render_case_execution_plan "$case_id"
  done
}

write_case_result() {
  local case_id="$1"
  local status="$2"
  local notes="$3"
  local artifact_dir="$RUN_DIR/$case_id"
  local input_root="$IRIS_SMOKE_LOCAL_INPUT_ROOT/$RUN_ID/$case_id/input"

  cat >"$artifact_dir/result.json" <<EOF
{
  "case_id": "$case_id",
  "status": "$status",
  "system_name": "iris",
  "project_slug": "${CASE_PROJECT_SLUGS[$case_id]}",
  "query_id": "${CASE_QUERY_IDS[$case_id]}",
  "vuln_type": "${CASE_VULNS[$case_id]}",
  "prepared_input_dir": "$input_root",
  "planned_command": "$artifact_dir/planned_command.sh",
  "notes": "$notes"
}
EOF
}

execute_case_plan() {
  local case_id="$1"
  local artifact_dir="$RUN_DIR/$case_id"
  local plan_file="$artifact_dir/planned_command.sh"
  local stdout_file="$artifact_dir/command.stdout.log"
  local stderr_file="$artifact_dir/command.stderr.log"
  local status notes exit_code input_root

  input_root="$IRIS_SMOKE_LOCAL_INPUT_ROOT/$RUN_ID/$case_id/input"

  if [[ ! -x "$plan_file" ]]; then
    status="runtime_failure"
    notes="missing planned command"
    write_case_result "$case_id" "$status" "$notes"
    append_summary "$case_id" "${CASE_VULNS[$case_id]}" "${CASE_QUERY_IDS[$case_id]}" "$input_root" "$status" "$notes"
    return
  fi

  set +e
  bash "$plan_file" >"$stdout_file" 2>"$stderr_file"
  exit_code=$?
  set -e

  if [[ $exit_code -eq 0 ]]; then
    status="completed"
    notes="execution succeeded"
  else
    status="runtime_failure"
    notes="planned command exited with code $exit_code"
  fi

  write_case_result "$case_id" "$status" "$notes"
  append_summary "$case_id" "${CASE_VULNS[$case_id]}" "${CASE_QUERY_IDS[$case_id]}" "$input_root" "$status" "$notes"
}

plan() {
  prepare_inputs
  init_run_status
  render_all_plans
  append_run_status "mode" "plan_only"
  append_run_status "finished_at" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

run() {
  prepare_inputs
  init_run_status
  init_summary
  render_all_plans

  local case_id
  for case_id in "${CASE_IDS[@]}"; do
    execute_case_plan "$case_id"
  done

  append_run_status "mode" "run"
  append_run_status "finished_at" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

cleanup_inputs() {
  rm -rf "$IRIS_SMOKE_LOCAL_INPUT_ROOT/$RUN_ID"
}

main() {
  local command="${1:-}"
  case "$command" in
    prepare-inputs)
      prepare_inputs
      ;;
    plan)
      plan
      ;;
    run)
      run
      ;;
    cleanup-inputs)
      cleanup_inputs
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
