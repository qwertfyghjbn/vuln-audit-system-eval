#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env_deepseek"
LOCAL_ENV_FILE="$REPO_ROOT/scripts/iris_local_env.sh"

if [[ -f "$LOCAL_ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$LOCAL_ENV_FILE"
fi

IRIS_LOCAL_TOOLS_ROOT="${IRIS_LOCAL_TOOLS_ROOT:-/tmp/iris-local-tools}"
IRIS_ROOT="${IRIS_ROOT:-/tmp/iris-v2}"
IRIS_VERSION_REF="${IRIS_VERSION_REF:-v2}"
IRIS_PYTHON_BIN="${IRIS_PYTHON_BIN:-python3}"
IRIS_JAVA_HOME="${IRIS_JAVA_HOME:-$IRIS_LOCAL_TOOLS_ROOT/jdk}"
IRIS_CODEQL_BIN="${IRIS_CODEQL_BIN:-}"
IRIS_PREFLIGHT_ARTIFACT_ROOT="${IRIS_PREFLIGHT_ARTIFACT_ROOT:-$REPO_ROOT/artifacts/iris_preflight}"
IRIS_PREFLIGHT_WORKDIR="${IRIS_PREFLIGHT_WORKDIR:-/tmp/iris_preflight}"
RUN_ID="${IRIS_PREFLIGHT_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
RUN_DIR="$IRIS_PREFLIGHT_ARTIFACT_ROOT/$RUN_ID"
DERIVED_ENV_FILE="$RUN_DIR/iris.env"
MANIFEST_FILE="$RUN_DIR/run_manifest.json"
CHECKS_FILE="$RUN_DIR/preflight_checks.tsv"
RESULT_FILE="$RUN_DIR/result.env"

CASE_IDS=(
  "PT-JA-REPO-001"
  "SSRF-JA-REPO-001"
  "PT-JA-REPO-CVE-2024-53677-VULN"
  "SSRF-JA-REPO-CVE-2023-3432-VULN"
  "SSRF-JA-REPO-CVE-2023-3432-FIXED"
)

declare -A CASE_DIRS=(
  ["PT-JA-REPO-001"]="datasets/synthetic/PT-JA-REPO-001"
  ["SSRF-JA-REPO-001"]="datasets/synthetic/SSRF-JA-REPO-001"
  ["PT-JA-REPO-CVE-2024-53677-VULN"]="datasets/real_world/PT-JA-REPO-CVE-2024-53677-VULN"
  ["SSRF-JA-REPO-CVE-2023-3432-VULN"]="datasets/real_world/SSRF-JA-REPO-CVE-2023-3432-VULN"
  ["SSRF-JA-REPO-CVE-2023-3432-FIXED"]="datasets/real_world/SSRF-JA-REPO-CVE-2023-3432-FIXED"
)

declare -A CASE_SOURCE_ROOTS=(
  ["PT-JA-REPO-001"]="src/main/java"
  ["SSRF-JA-REPO-001"]="src/main/java"
  ["PT-JA-REPO-CVE-2024-53677-VULN"]="repo"
  ["SSRF-JA-REPO-CVE-2023-3432-VULN"]="repo"
  ["SSRF-JA-REPO-CVE-2023-3432-FIXED"]="repo"
)

declare -A CASE_COMPILE_RECIPE_PATHS=(
  ["PT-JA-REPO-001"]="build_support/java_compile_recipe.json"
  ["SSRF-JA-REPO-001"]="build_support/java_compile_recipe.json"
  ["PT-JA-REPO-CVE-2024-53677-VULN"]="build_support/java_compile_recipe.json"
  ["SSRF-JA-REPO-CVE-2023-3432-VULN"]="build_support/java_compile_recipe.json"
  ["SSRF-JA-REPO-CVE-2023-3432-FIXED"]="build_support/java_compile_recipe.json"
)

declare -A CASE_QUERY_IDS=(
  ["PT-JA-REPO-001"]="cwe-022wLLM"
  ["SSRF-JA-REPO-001"]="cwe-918wLLM"
  ["PT-JA-REPO-CVE-2024-53677-VULN"]="cwe-022wLLM"
  ["SSRF-JA-REPO-CVE-2023-3432-VULN"]="cwe-918wLLM"
  ["SSRF-JA-REPO-CVE-2023-3432-FIXED"]="cwe-918wLLM"
)

declare -A CASE_PROJECT_SLUGS=(
  ["PT-JA-REPO-001"]="bench__pt-ja-repo-001_SYNTHETIC_smoke"
  ["SSRF-JA-REPO-001"]="bench__ssrf-ja-repo-001_SYNTHETIC_smoke"
  ["PT-JA-REPO-CVE-2024-53677-VULN"]="bench__pt-ja-repo-cve-2024-53677_CVE-2024-53677_vuln"
  ["SSRF-JA-REPO-CVE-2023-3432-VULN"]="bench__ssrf-ja-repo-cve-2023-3432_CVE-2023-3432_vuln"
  ["SSRF-JA-REPO-CVE-2023-3432-FIXED"]="bench__ssrf-ja-repo-cve-2023-3432_CVE-2023-3432_fixed"
)

declare -A CASE_VULNS=(
  ["PT-JA-REPO-001"]="path_traversal"
  ["SSRF-JA-REPO-001"]="ssrf"
  ["PT-JA-REPO-CVE-2024-53677-VULN"]="path_traversal"
  ["SSRF-JA-REPO-CVE-2023-3432-VULN"]="ssrf"
  ["SSRF-JA-REPO-CVE-2023-3432-FIXED"]="ssrf"
)

if [[ -n "${IRIS_SMOKE_CASE_IDS:-}" ]]; then
  IFS=',' read -r -a REQUESTED_CASE_IDS <<<"$IRIS_SMOKE_CASE_IDS"
  FILTERED_CASE_IDS=()
  for case_id in "${REQUESTED_CASE_IDS[@]}"; do
    case_id="$(printf '%s' "$case_id" | xargs)"
    [[ -z "$case_id" ]] && continue
    if [[ -z "${CASE_DIRS[$case_id]+x}" ]]; then
      echo "Unknown IRIS smoke case id: $case_id" >&2
      exit 2
    fi
    FILTERED_CASE_IDS+=("$case_id")
  done
  if [[ ${#FILTERED_CASE_IDS[@]} -eq 0 ]]; then
    echo "IRIS_SMOKE_CASE_IDS did not resolve to any valid case ids" >&2
    exit 2
  fi
  CASE_IDS=("${FILTERED_CASE_IDS[@]}")
fi

FAILED_CHECKS=0

if [[ -z "$IRIS_CODEQL_BIN" && -x "$IRIS_LOCAL_TOOLS_ROOT/codeql/codeql" ]]; then
  IRIS_CODEQL_BIN="$IRIS_LOCAL_TOOLS_ROOT/codeql/codeql"
fi

if [[ -d "$IRIS_JAVA_HOME/bin" ]]; then
  export JAVA_HOME="$IRIS_JAVA_HOME"
  export PATH="$IRIS_JAVA_HOME/bin:$PATH"
fi

if [[ -n "$IRIS_CODEQL_BIN" ]]; then
  export PATH="$(dirname "$IRIS_CODEQL_BIN"):$PATH"
fi

usage() {
  cat <<'EOF'
Usage:
  scripts/iris_prepare_and_preflight.sh prepare
  scripts/iris_prepare_and_preflight.sh preflight
  scripts/iris_prepare_and_preflight.sh all
  scripts/iris_prepare_and_preflight.sh cleanup

Commands:
  prepare    Create artifact workspace, derive iris.env from .env_deepseek, and write the run manifest.
  preflight  Validate local toolchain, IRIS repo layout, and smoke-case contracts.
  all        Run prepare, then preflight.
  cleanup    Remove the current preflight run directory and temp workspace.
EOF
}

log() {
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

trim_cr() {
  printf '%s' "$1" | tr -d '\r'
}

require_base_commands() {
  local missing=0
  local cmd
  for cmd in python3 git sed awk; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Missing required command: $cmd" >&2
      missing=1
    fi
  done
  if [[ $missing -ne 0 ]]; then
    exit 2
  fi
}

ensure_run_dir() {
  mkdir -p "$RUN_DIR"
  mkdir -p "$IRIS_PREFLIGHT_WORKDIR"
}

load_env_source() {
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "Missing env source: $ENV_FILE" >&2
    exit 2
  fi

  # shellcheck disable=SC1090
  source "$ENV_FILE"

  export LLM_PROVIDER="$(trim_cr "${LLM_PROVIDER:-}")"
  export LLM_MODEL="$(trim_cr "${LLM_MODEL:-}")"
  export LLM_API_KEY="$(trim_cr "${LLM_API_KEY:-}")"
  export LLM_BASE_URL="$(trim_cr "${LLM_BASE_URL:-}")"

  if [[ -z "$LLM_PROVIDER" || -z "$LLM_MODEL" || -z "$LLM_API_KEY" ]]; then
    echo "LLM_PROVIDER, LLM_MODEL, and LLM_API_KEY must be present in $ENV_FILE" >&2
    exit 2
  fi
}

write_run_manifest() {
  cat >"$MANIFEST_FILE" <<EOF
{
  "run_id": "$RUN_ID",
  "system_name": "iris",
  "run_stage": "preflight",
  "native_evaluation_environment": true,
  "iris_root": "$IRIS_ROOT",
  "iris_version_ref": "$IRIS_VERSION_REF",
  "env_source": "$ENV_FILE",
  "derived_env_file": "$DERIVED_ENV_FILE",
  "iris_python_bin": "$IRIS_PYTHON_BIN",
  "codeql_bin_requested": "$IRIS_CODEQL_BIN",
  "smoke_case_count": ${#CASE_IDS[@]}
}
EOF
}

derive_iris_env() {
  log "Deriving iris.env from .env_deepseek"
  {
    printf 'IRIS_LLM_PROVIDER=%s\n' "$LLM_PROVIDER"
    printf 'IRIS_LLM_MODEL=%s\n' "$LLM_MODEL"
    printf 'IRIS_LLM_BASE_URL=%s\n' "$LLM_BASE_URL"
    printf 'OPENAI_API_KEY=%s\n' "$LLM_API_KEY"
    printf 'OPENAI_BASE_URL=%s\n' "$LLM_BASE_URL"
    printf 'OPENAI_MODEL=%s\n' "$LLM_MODEL"
  } >"$DERIVED_ENV_FILE"
  chmod 600 "$DERIVED_ENV_FILE"
}

init_checks() {
  {
    printf 'check\tstatus\tdetails\n'
  } >"$CHECKS_FILE"
  {
    printf 'run_id=%s\n' "$RUN_ID"
    printf 'started_at=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf 'iris_root=%s\n' "$IRIS_ROOT"
    printf 'derived_env_file=%s\n' "$DERIVED_ENV_FILE"
  } >"$RESULT_FILE"
}

append_result() {
  printf '%s=%s\n' "$1" "$2" >>"$RESULT_FILE"
}

record_check() {
  local name="$1"
  local status="$2"
  local details="$3"
  printf '%s\t%s\t%s\n' "$name" "$status" "$details" >>"$CHECKS_FILE"
  if [[ "$status" == "fail" ]]; then
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
  fi
}

resolved_codeql_bin() {
  if [[ -n "$IRIS_CODEQL_BIN" ]]; then
    printf '%s\n' "$IRIS_CODEQL_BIN"
    return
  fi
  command -v codeql 2>/dev/null || true
}

check_repo_layout() {
  if [[ ! -d "$IRIS_ROOT" ]]; then
    record_check "iris_root" "fail" "missing_dir:$IRIS_ROOT"
    return
  fi

  if [[ -f "$IRIS_ROOT/src/iris.py" && -f "$IRIS_ROOT/environment.yml" ]]; then
    record_check "iris_layout" "pass" "found_src_iris_py_and_environment_yml"
  else
    record_check "iris_layout" "fail" "missing_expected_files"
  fi

  if git -C "$IRIS_ROOT" rev-parse HEAD >/dev/null 2>&1; then
    local head
    head="$(git -C "$IRIS_ROOT" rev-parse HEAD)"
    append_result "iris_git_head" "$head"
    record_check "iris_git_head" "pass" "$head"
  else
    record_check "iris_git_head" "warn" "not_a_git_checkout_or_head_unavailable"
  fi
}

check_python() {
  if command -v "$IRIS_PYTHON_BIN" >/dev/null 2>&1; then
    local version
    version="$("$IRIS_PYTHON_BIN" --version 2>&1 | tr '\n' ' ')"
    record_check "iris_python" "pass" "$version"
  else
    record_check "iris_python" "fail" "missing_python_bin:$IRIS_PYTHON_BIN"
  fi
}

check_codeql() {
  local codeql_bin
  codeql_bin="$(resolved_codeql_bin)"
  if [[ -n "$codeql_bin" && -x "$codeql_bin" ]]; then
    local version
    version="$("$codeql_bin" version 2>/dev/null | head -n 1 || true)"
    record_check "codeql" "pass" "${version:-bin:$codeql_bin}"
    append_result "codeql_bin" "$codeql_bin"
  else
    record_check "codeql" "fail" "missing_codeql_binary"
  fi
}

check_java_toolchain() {
  local cmd
  for cmd in java javac; do
    if command -v "$cmd" >/dev/null 2>&1; then
      local version
      version="$("$cmd" -version 2>&1 | head -n 1 | tr '\n' ' ')"
      record_check "$cmd" "pass" "$version"
    else
      record_check "$cmd" "fail" "missing_$cmd"
    fi
  done

  if command -v mvn >/dev/null 2>&1; then
    record_check "maven" "pass" "$(mvn -version 2>/dev/null | head -n 1)"
  else
    record_check "maven" "warn" "missing_maven"
  fi

  if command -v gradle >/dev/null 2>&1; then
    record_check "gradle" "pass" "$(gradle -version 2>/dev/null | awk 'NR==1 {print; exit}')"
  else
    record_check "gradle" "warn" "missing_gradle"
  fi
}

check_env_derivation() {
  if [[ -f "$DERIVED_ENV_FILE" ]]; then
    record_check "derived_env" "pass" "present"
  else
    record_check "derived_env" "fail" "missing:$DERIVED_ENV_FILE"
  fi
}

check_smoke_case_contracts() {
  local case_id case_root source_root recipe_rel
  for case_id in "${CASE_IDS[@]}"; do
    case_root="$REPO_ROOT/${CASE_DIRS[$case_id]}"
    source_root="$case_root/${CASE_SOURCE_ROOTS[$case_id]}"
    recipe_rel="${CASE_COMPILE_RECIPE_PATHS[$case_id]}"

    if [[ -d "$case_root" ]]; then
      record_check "case:$case_id:root" "pass" "$case_root"
    else
      record_check "case:$case_id:root" "fail" "missing_case_dir"
    fi

    if [[ -d "$source_root" ]]; then
      record_check "case:$case_id:source_root" "pass" "$source_root"
    else
      record_check "case:$case_id:source_root" "fail" "missing_source_root"
    fi

    if [[ -f "$case_root/$recipe_rel" ]]; then
      record_check "case:$case_id:compile_recipe" "pass" "$recipe_rel"
    else
      record_check "case:$case_id:compile_recipe" "fail" "missing_compile_recipe"
    fi
  done
}

finalize_preflight() {
  local status="ready"
  if [[ $FAILED_CHECKS -ne 0 ]]; then
    status="blocked"
  fi
  append_result "finished_at" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  append_result "overall_status" "$status"
  append_result "failed_checks" "$FAILED_CHECKS"
  log "Preflight $status"
}

prepare() {
  require_base_commands
  ensure_run_dir
  load_env_source
  write_run_manifest
  derive_iris_env
  log "Prepared:"
  log "  manifest: $MANIFEST_FILE"
  log "  derived env: $DERIVED_ENV_FILE"
}

preflight() {
  require_base_commands
  ensure_run_dir
  load_env_source
  if [[ ! -f "$DERIVED_ENV_FILE" || ! -f "$MANIFEST_FILE" ]]; then
    write_run_manifest
    derive_iris_env
  fi
  init_checks
  check_repo_layout
  check_python
  check_codeql
  check_java_toolchain
  check_env_derivation
  check_smoke_case_contracts
  finalize_preflight
}

cleanup() {
  log "Removing current preflight run directory"
  rm -rf "$RUN_DIR"
  rm -rf "$IRIS_PREFLIGHT_WORKDIR"
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
      usage >&2
      exit 1
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
