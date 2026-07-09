# DeepAudit WSL Smoke Runbook

This runbook is for the `experiment-first` setup agreed for this repository:

- `Windows Docker Desktop` runs the official DeepAudit release.
- `WSL` prepares shared files, injects the authoritative LLM configuration from `.env_deepseek`, and performs preflight checks over HTTP.
- This document stops at `preflight`. It does not cover running benchmark cases yet.

## Scope

This runbook is only for:

1. Starting DeepAudit on Windows with the official Docker Compose deployment.
2. Injecting the LLM configuration from WSL.
3. Verifying the service with a minimal end-to-end preflight.

This runbook is not for:

- WSL-native source deployment
- Local DeepAudit code modification
- Benchmark case execution

## Automation Entry Point

The WSL side of this runbook is automated by:

- [scripts/deepaudit_prepare_and_preflight.sh](/home/lqs/llm_audit_system_learning/scripts/deepaudit_prepare_and_preflight.sh:1)
- [scripts/mock_deepaudit_api.py](/home/lqs/llm_audit_system_learning/scripts/mock_deepaudit_api.py:1) for local script self-tests only
- [scripts/test_deepaudit_preflight_mock.sh](/home/lqs/llm_audit_system_learning/scripts/test_deepaudit_preflight_mock.sh:1) for one-command WSL-side regression testing

Supported commands:

```bash
scripts/deepaudit_prepare_and_preflight.sh prepare
scripts/deepaudit_prepare_and_preflight.sh preflight
scripts/deepaudit_prepare_and_preflight.sh all
scripts/deepaudit_prepare_and_preflight.sh cleanup
```

For the real experiment, keep the default shared path:

```bash
scripts/deepaudit_prepare_and_preflight.sh all
```

For local dry runs in a restricted environment, you may override the shared directory:

```bash
DEEPAUDIT_SHARED_DIR=/tmp/deepaudit_shared \
  scripts/deepaudit_prepare_and_preflight.sh all
```

For local script validation without a real DeepAudit service, you may start the mock API and point both backend and frontend URLs at it:

```bash
python3 scripts/mock_deepaudit_api.py --port 18000

DEEPAUDIT_SHARED_DIR=/tmp/deepaudit_shared \
DEEPAUDIT_BACKEND_URL=http://127.0.0.1:18000 \
DEEPAUDIT_FRONTEND_URL=http://127.0.0.1:18000 \
scripts/deepaudit_prepare_and_preflight.sh all
```

This mock path is only for validating the WSL script itself. It is not evidence that the real DeepAudit deployment is healthy.

For a one-command self-test of the WSL-side automation, use:

```bash
scripts/test_deepaudit_preflight_mock.sh
```

This script starts the mock API, runs `prepare + preflight`, verifies the generated artifacts, and exits non-zero if the WSL preflight flow regresses.

If you want to keep the generated mock-test artifacts for inspection:

```bash
DEEPAUDIT_MOCK_KEEP_ARTIFACTS=1 \
  scripts/test_deepaudit_preflight_mock.sh
```

## Prerequisites

Before starting, make sure:

1. `Docker Desktop` is installed on Windows and can run Linux containers.
2. Windows can pull images from GitHub Container Registry and reach your DeepSeek-compatible API endpoint.
3. The following ports are free on the host:
   - `3000` for DeepAudit frontend
   - `8000` for DeepAudit backend API
4. Your authoritative LLM settings already exist in [`.env_deepseek`](/home/lqs/llm_audit_system_learning/.env_deepseek:1).
5. WSL can write to `/mnt/c/tmp/deepaudit`.

## Fixed Conventions

- Shared host path on Windows: `C:\tmp\deepaudit`
- Shared path from WSL: `/mnt/c/tmp/deepaudit`
- Docker Compose project name: `deepaudit_smoke`
- DeepAudit version: `v3.0.0` official deployment file

## Operational Safety Rules

These rules are mandatory for every DeepAudit experiment in this repository.

1. Use only one shared directory between WSL and Windows:
   - Windows: `C:\tmp\deepaudit`
   - WSL: `/mnt/c/tmp/deepaudit`
2. Treat DeepAudit as an external system under evaluation, not as an in-repo tool with direct access to the benchmark workspace.
3. Never mount or upload the raw benchmark repository root or a full case directory.
4. Only provide `clean input` artifacts prepared specifically for the current run.
5. Read [`.env_deepseek`](/home/lqs/llm_audit_system_learning/.env_deepseek:1) only from WSL and derive a minimal `backend.env` from it for the service.
6. Do not expose the following paths to DeepAudit containers:
   - `/home/lqs`
   - `/home/lqs/llm_audit_system_learning`
   - `/home/lqs/llm_audit_system_learning/.git`
   - `/home/lqs/.ssh`
   - `/home/lqs/.aws`
   - `/home/lqs/.config`
7. Do not let DeepAudit read:
   - `ground_truth.json`
   - labeled `case.yaml`
   - README answer sections
8. Prefer HTTP upload of ZIP inputs over bind-mounting benchmark source into the running service.
9. Remove temporary ZIPs and other copied artifacts after each experiment round.

## 执行上下文约束

这一条同样是强制要求。

1. 真实 DeepAudit 实验必须运行在真实 WSL shell，或等价的非沙箱/提权网络上下文中。
2. 受限沙箱执行环境可能处于不同的 network namespace。
3. 在该沙箱里，`localhost`、`127.0.0.1`、`172.x.x.x` 的 Windows 主机路由都可能不可达。
4. 因此，沙箱里出现的 `curl: (7) Couldn't connect to server` 不能直接判定为 DeepAudit 服务异常。
5. 对 Codex 工具调用而言，凡是需要真实访问 Windows Docker Desktop 上 DeepAudit 服务的步骤，都应使用非沙箱/提权执行。

本仓库已经实测到以下现象：

- 受限沙箱内访问 `http://127.0.0.1:8000/health`、`http://localhost:8000/health`、`http://172.27.144.1:8000/health` 全部失败
- 非沙箱/提权上下文访问同样 URL 返回 `200`
- 两者的 `/proc/self/ns/net` 不同，说明看到的不是同一个网络命名空间

## Why These Rules Exist

- `Path safety`: using one fixed shared path avoids mixing Linux paths with Windows paths in Docker commands and API uploads.
- `Permission safety`: ZIP copies keep the benchmark workspace read-only from DeepAudit's point of view.
- `Security boundary safety`: the system under test only sees what the evaluator explicitly uploads.
- `Benchmark integrity`: clean input preparation prevents label leakage and answer leakage.
- `Performance stability`: small ZIP uploads avoid repeated heavy scanning over `/mnt/c` or the full repository.
- `Reproducibility`: fixed paths and fixed transfer methods reduce host-specific drift.

## Step 1: Prepare Shared Files From WSL

Run these commands in WSL from the repository root.

```bash
mkdir -p /mnt/c/tmp/deepaudit

curl -fsSL \
  https://raw.githubusercontent.com/lintsinghua/DeepAudit/v3.0.0/docker-compose.prod.yml \
  -o /mnt/c/tmp/deepaudit/docker-compose.prod.yml

awk '
  /^export (LLM_PROVIDER|LLM_MODEL|LLM_API_KEY|LLM_BASE_URL)=/ {
    sub(/^export /, "");
    print;
  }
' .env_deepseek > /mnt/c/tmp/deepaudit/backend.env

cat >> /mnt/c/tmp/deepaudit/backend.env <<'EOF'
COMPOSE_PROJECT_NAME=deepaudit_smoke
EOF
```

This step is intentionally minimal:

- only `LLM_PROVIDER`, `LLM_MODEL`, `LLM_API_KEY`, and `LLM_BASE_URL` are copied out of `.env_deepseek`
- the benchmark repository itself is not copied into the shared directory
- no credentials other than the current LLM configuration should be written into `C:\tmp\deepaudit`

Verify the generated file only contains the expected variable names:

```bash
sed -E 's/=.*/=<redacted>/' /mnt/c/tmp/deepaudit/backend.env
```

Expected shape:

```env
LLM_PROVIDER=<redacted>
LLM_MODEL=<redacted>
LLM_API_KEY=<redacted>
LLM_BASE_URL=<redacted>
COMPOSE_PROJECT_NAME=<redacted>
```

## Step 2: Start DeepAudit From Windows PowerShell

Open `PowerShell` on Windows and run:

```powershell
New-Item -ItemType Directory -Force C:\tmp\deepaudit | Out-Null

docker compose `
  --env-file C:\tmp\deepaudit\backend.env `
  -f C:\tmp\deepaudit\docker-compose.prod.yml `
  up -d
```

Check service status:

```powershell
docker compose `
  --env-file C:\tmp\deepaudit\backend.env `
  -f C:\tmp\deepaudit\docker-compose.prod.yml `
  ps
```

If startup fails, inspect logs before proceeding:

```powershell
docker compose `
  --env-file C:\tmp\deepaudit\backend.env `
  -f C:\tmp\deepaudit\docker-compose.prod.yml `
  logs --tail=200
```

## Step 3: Record the Frozen Service Configuration

Before preflight, record the service-side configuration used for this run.

At minimum, write down:

- DeepAudit version: `v3.0.0`
- `LLM_PROVIDER`
- `LLM_MODEL`
- `LLM_BASE_URL`
- Config source: repository `.env_deepseek`
- Start timestamp

Do not continue if the actually injected values differ from `.env_deepseek`.

## Step 4: Backend and Frontend Reachability Check From WSL

Run these checks from WSL:

```bash
curl -fsS http://localhost:8000/health
curl -I http://localhost:3000
```

Expected backend response:

```json
{"status":"ok"}
```

约束说明：

- 这里的“Run these checks from WSL”指真实 WSL shell，不包括受限沙箱工具上下文。
- 如果某次探测来自受限沙箱并返回 `curl: (7) Couldn't connect to server`，该结果只能说明沙箱网络视图不可达，不能单独作为服务故障判据。
- 只有当真实 WSL shell 或非沙箱/提权上下文也复现失败时，才能把它归类为 `service_unreachable`。

If backend health fails, stop here. Preflight is not passed.

## Step 5: Create a Minimal Preflight ZIP Input

This ZIP is only for service verification. It is not a benchmark case.

It must stay isolated from the benchmark dataset:

- do not generate it under `datasets/`
- do not include any repository metadata
- do not include any answer-bearing files

```bash
rm -rf /tmp/deepaudit_preflight
mkdir -p /tmp/deepaudit_preflight/src

cat > /tmp/deepaudit_preflight/src/app.py <<'EOF'
from flask import Flask, request

app = Flask(__name__)

@app.get("/ping")
def ping():
    return {"ok": True, "echo": request.args.get("q", "")}
EOF

cd /tmp/deepaudit_preflight
zip -qr /mnt/c/tmp/deepaudit/preflight.zip src
cd /home/lqs/llm_audit_system_learning
```

Verify the ZIP exists:

```bash
ls -lh /mnt/c/tmp/deepaudit/preflight.zip
```

## Step 6: Register a Preflight User

Register a dedicated preflight account through the official backend API.

```bash
curl -fsS \
  -X POST http://localhost:8000/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "deepaudit-preflight@example.com",
    "password": "DeepAuditPreflight123!",
    "full_name": "DeepAudit Preflight"
  }'
```

If the user already exists, that is acceptable. Continue to login.

## Step 7: Login and Export a Bearer Token

```bash
TOKEN="$(
  curl -fsS \
    -X POST http://localhost:8000/api/v1/auth/login \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'username=deepaudit-preflight@example.com' \
    --data-urlencode 'password=DeepAuditPreflight123!' \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'
)"

test -n "$TOKEN" && echo "TOKEN acquired"
```

If token acquisition fails, stop here. Preflight is not passed.

## Step 8: Create a ZIP Project

```bash
PROJECT_ID="$(
  curl -fsS \
    -X POST http://localhost:8000/api/v1/projects/ \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{
      "name": "DeepAudit Preflight ZIP Project",
      "source_type": "zip",
      "repository_type": "other",
      "description": "Preflight-only project",
      "default_branch": "main",
      "programming_languages": ["python"]
    }' \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])'
)"

test -n "$PROJECT_ID" && echo "$PROJECT_ID"
```

If project creation fails, stop here. Preflight is not passed.

## Step 9: Upload the Preflight ZIP

```bash
curl -fsS \
  -X POST "http://localhost:8000/api/v1/projects/$PROJECT_ID/zip" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/mnt/c/tmp/deepaudit/preflight.zip"
```

Then verify ZIP metadata exists:

```bash
curl -fsS \
  -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/v1/projects/$PROJECT_ID/zip"
```

If upload or ZIP metadata lookup fails, stop here. Preflight is not passed.

Do not replace this upload flow with a direct bind mount of benchmark material. For this repository, ZIP upload is the default safe path because it keeps the benchmark workspace outside the DeepAudit container boundary.

## Step 10: Start a Minimal Agent Task

Start an Agent task through the official API. For preflight, use a narrow configuration and `analysis_only`.

```bash
TASK_ID="$(
  curl -fsS \
    -X POST http://localhost:8000/api/v1/agent-tasks/ \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d "{
      \"project_id\": \"$PROJECT_ID\",
      \"name\": \"Preflight Agent Task\",
      \"description\": \"Preflight-only task\",
      \"target_vulnerabilities\": [\"path_traversal\"],
      \"verification_level\": \"analysis_only\",
      \"max_iterations\": 3,
      \"timeout_seconds\": 300
    }" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])'
)"

test -n "$TASK_ID" && echo "$TASK_ID"
```

If task creation fails, stop here. Preflight is not passed.

## Step 11: Verify Task Observability

At preflight stage, you do not need a good finding. You only need proof that the official task flow is alive and observable.

Check the task object:

```bash
curl -fsS \
  -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/v1/agent-tasks/$TASK_ID"
```

Check task events:

```bash
curl -fsS \
  -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/v1/agent-tasks/$TASK_ID/events"
```

Check task findings:

```bash
curl -fsS \
  -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/v1/agent-tasks/$TASK_ID/findings"
```

Check task summary:

```bash
curl -fsS \
  -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/api/v1/agent-tasks/$TASK_ID/summary"
```

## Preflight Pass Criteria

Preflight is passed only if all of the following are true:

1. `http://localhost:8000/health` returns success.
2. Login returns a bearer token.
3. ZIP project creation succeeds.
4. ZIP upload succeeds.
5. Agent task creation succeeds.
6. At least one of these task-observability checks succeeds with a structured response:
   - task object
   - events
   - findings
   - summary

If any item fails, do not run benchmark cases yet.

## Failure Handling

If preflight fails, classify the blocker before touching any benchmark input:

- `service_unreachable`
- `auth_failure`
- `zip_project_failure`
- `zip_upload_failure`
- `agent_task_creation_failure`
- `agent_observability_failure`
- `llm_provider_failure`

补充约束：

- 不要把受限沙箱中的单次 `curl` 失败直接记成 `service_unreachable`。
- 先在真实 WSL shell 或非沙箱/提权上下文复核一次，再决定是否记录为服务不可达。

Record the failure with:

- timestamp
- Docker Compose status
- backend logs tail
- the exact failing API call

## Known Risk: Embedding Configuration

DeepAudit separates chat-model configuration from embedding configuration. If the Agent task fails during indexing or retrieval even though authentication and project upload work, treat that as an environment blocker first, not as a benchmark failure.

For this runbook, the correct response is:

1. stop after preflight failure,
2. record the blocker,
3. decide the embedding-provider strategy before any smoke case execution.

## Stop and Cleanup

To stop the stack from Windows PowerShell:

```powershell
docker compose `
  --env-file C:\tmp\deepaudit\backend.env `
  -f C:\tmp\deepaudit\docker-compose.prod.yml `
  down
```

To remove the preflight ZIP and temp files from WSL:

```bash
rm -rf /tmp/deepaudit_preflight
rm -f /mnt/c/tmp/deepaudit/preflight.zip
```

If a later run copies benchmark-derived artifacts into `/mnt/c/tmp/deepaudit`, remove those copies after the run as well. The shared directory should contain only the current run's minimal operational files.
