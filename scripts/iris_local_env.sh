#!/usr/bin/env bash

export IRIS_ROOT="${IRIS_ROOT:-/tmp/iris-v2}"
export IRIS_LOCAL_TOOLS_ROOT="${IRIS_LOCAL_TOOLS_ROOT:-/tmp/iris-local-tools}"
export IRIS_JAVA_HOME="${IRIS_JAVA_HOME:-$IRIS_LOCAL_TOOLS_ROOT/jdk}"
export IRIS_CODEQL_BIN="${IRIS_CODEQL_BIN:-$IRIS_LOCAL_TOOLS_ROOT/codeql/codeql}"
export IRIS_CODEQL_DIR="${IRIS_CODEQL_DIR:-$(cd "$(dirname "$IRIS_CODEQL_BIN")" && pwd)}"
export IRIS_PYTHON_BIN="${IRIS_PYTHON_BIN:-$IRIS_LOCAL_TOOLS_ROOT/venv/bin/python}"

if [[ -d "$IRIS_JAVA_HOME/bin" ]]; then
  export JAVA_HOME="$IRIS_JAVA_HOME"
  export PATH="$IRIS_JAVA_HOME/bin:$PATH"
fi

if [[ -x "$IRIS_PYTHON_BIN" ]]; then
  export PATH="$(dirname "$IRIS_PYTHON_BIN"):$PATH"
fi

if [[ -x "$IRIS_CODEQL_BIN" ]]; then
  export PATH="$(dirname "$IRIS_CODEQL_BIN"):$PATH"
fi
