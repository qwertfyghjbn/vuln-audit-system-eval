#!/usr/bin/env python3
import argparse
import json
import re
import sys
import uuid
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse


STATE = {
    "users": {},
    "tokens": {},
    "projects": {},
    "tasks": {},
}


def json_bytes(payload):
    return json.dumps(payload, ensure_ascii=False).encode("utf-8")


class MockDeepAuditHandler(BaseHTTPRequestHandler):
    server_version = "MockDeepAudit/0.1"

    def _send_json(self, status, payload):
        body = json_bytes(payload)
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_text(self, status, payload=""):
        body = payload.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_body(self):
        length = int(self.headers.get("Content-Length", "0"))
        return self.rfile.read(length)

    def _read_json(self):
        raw = self._read_body()
        if not raw:
            return {}
        return json.loads(raw.decode("utf-8"))

    def _require_auth(self):
        auth = self.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            self._send_json(HTTPStatus.UNAUTHORIZED, {"detail": "Missing bearer token"})
            return None
        token = auth.split(" ", 1)[1]
        user_id = STATE["tokens"].get(token)
        if not user_id:
            self._send_json(HTTPStatus.UNAUTHORIZED, {"detail": "Invalid token"})
            return None
        return user_id

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - - [%s] %s\n" % (
            self.address_string(),
            self.log_date_time_string(),
            fmt % args,
        ))

    def do_HEAD(self):
        parsed = urlparse(self.path)
        if parsed.path == "/" or parsed.path == "":
            self.send_response(HTTPStatus.OK)
            self.send_header("Content-Length", "0")
            self.end_headers()
            return
        self.send_response(HTTPStatus.NOT_FOUND)
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/health":
            self._send_json(HTTPStatus.OK, {"status": "ok"})
            return

        user_id = None
        if path.startswith("/api/v1/"):
            user_id = self._require_auth()
            if not user_id:
                return

        project_zip_match = re.fullmatch(r"/api/v1/projects/([^/]+)/zip", path)
        if project_zip_match:
            project_id = project_zip_match.group(1)
            project = STATE["projects"].get(project_id)
            if not project:
                self._send_json(HTTPStatus.NOT_FOUND, {"detail": "项目不存在"})
                return
            self._send_json(
                HTTPStatus.OK,
                {
                    "has_file": bool(project.get("zip_uploaded")),
                    "original_filename": project.get("zip_filename"),
                    "file_size": project.get("zip_size"),
                    "uploaded_at": project.get("zip_uploaded_at"),
                },
            )
            return

        task_match = re.fullmatch(r"/api/v1/agent-tasks/([^/]+)", path)
        if task_match:
            task_id = task_match.group(1)
            task = STATE["tasks"].get(task_id)
            if not task:
                self._send_json(HTTPStatus.NOT_FOUND, {"detail": "任务不存在"})
                return
            self._send_json(HTTPStatus.OK, task["task_object"])
            return

        events_match = re.fullmatch(r"/api/v1/agent-tasks/([^/]+)/events", path)
        if events_match:
            task_id = events_match.group(1)
            task = STATE["tasks"].get(task_id)
            if not task:
                self._send_json(HTTPStatus.NOT_FOUND, {"detail": "任务不存在"})
                return
            self._send_json(HTTPStatus.OK, task["events"])
            return

        findings_match = re.fullmatch(r"/api/v1/agent-tasks/([^/]+)/findings", path)
        if findings_match:
            task_id = findings_match.group(1)
            task = STATE["tasks"].get(task_id)
            if not task:
                self._send_json(HTTPStatus.NOT_FOUND, {"detail": "任务不存在"})
                return
            self._send_json(HTTPStatus.OK, task["findings"])
            return

        summary_match = re.fullmatch(r"/api/v1/agent-tasks/([^/]+)/summary", path)
        if summary_match:
            task_id = summary_match.group(1)
            task = STATE["tasks"].get(task_id)
            if not task:
                self._send_json(HTTPStatus.NOT_FOUND, {"detail": "任务不存在"})
                return
            self._send_json(HTTPStatus.OK, task["summary"])
            return

        self._send_json(HTTPStatus.NOT_FOUND, {"detail": "Not found"})

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/api/v1/auth/register":
            data = self._read_json()
            email = data["email"]
            if email in STATE["users"]:
                self._send_json(HTTPStatus.BAD_REQUEST, {"detail": "该邮箱已被注册"})
                return
            user_id = str(uuid.uuid4())
            STATE["users"][email] = {
                "id": user_id,
                "email": email,
                "password": data["password"],
                "full_name": data["full_name"],
            }
            self._send_json(
                HTTPStatus.OK,
                {
                    "id": user_id,
                    "email": email,
                    "full_name": data["full_name"],
                },
            )
            return

        if path == "/api/v1/auth/login":
            raw = self._read_body().decode("utf-8")
            form = parse_qs(raw)
            email = form.get("username", [""])[0]
            password = form.get("password", [""])[0]
            user = STATE["users"].get(email)
            if not user or user["password"] != password:
                self._send_json(HTTPStatus.BAD_REQUEST, {"detail": "邮箱或密码错误"})
                return
            token = str(uuid.uuid4())
            STATE["tokens"][token] = user["id"]
            self._send_json(HTTPStatus.OK, {"access_token": token, "token_type": "bearer"})
            return

        user_id = self._require_auth()
        if not user_id:
            return

        if path == "/api/v1/projects/":
            data = self._read_json()
            project_id = str(uuid.uuid4())
            STATE["projects"][project_id] = {
                "id": project_id,
                "owner_id": user_id,
                "name": data["name"],
                "source_type": data.get("source_type", "zip"),
                "zip_uploaded": False,
                "zip_filename": None,
                "zip_size": None,
                "zip_uploaded_at": None,
            }
            self._send_json(
                HTTPStatus.OK,
                {
                    "id": project_id,
                    "name": data["name"],
                    "owner_id": user_id,
                    "source_type": data.get("source_type", "zip"),
                },
            )
            return

        project_zip_match = re.fullmatch(r"/api/v1/projects/([^/]+)/zip", path)
        if project_zip_match:
            project_id = project_zip_match.group(1)
            project = STATE["projects"].get(project_id)
            if not project:
                self._send_json(HTTPStatus.NOT_FOUND, {"detail": "项目不存在"})
                return
            raw = self._read_body()
            project["zip_uploaded"] = True
            project["zip_filename"] = "preflight.zip"
            project["zip_size"] = len(raw)
            project["zip_uploaded_at"] = "2026-07-01T00:00:00Z"
            self._send_json(
                HTTPStatus.OK,
                {
                    "message": "ZIP文件上传成功",
                    "original_filename": project["zip_filename"],
                    "file_size": project["zip_size"],
                    "uploaded_at": project["zip_uploaded_at"],
                },
            )
            return

        if path == "/api/v1/agent-tasks/":
            data = self._read_json()
            task_id = str(uuid.uuid4())
            vuln = (data.get("target_vulnerabilities") or ["path_traversal"])[0]
            STATE["tasks"][task_id] = {
                "task_object": {
                    "id": task_id,
                    "project_id": data["project_id"],
                    "name": data.get("name"),
                    "status": "completed",
                    "current_phase": "analysis",
                    "findings_count": 1,
                    "verified_count": 0,
                    "quality_score": 0.0,
                },
                "events": [
                    {
                        "id": str(uuid.uuid4()),
                        "task_id": task_id,
                        "event_type": "phase_start",
                        "phase": "analysis",
                        "message": "Mock task started",
                        "sequence": 1,
                        "created_at": "2026-07-01T00:00:00Z",
                    }
                ],
                "findings": [
                    {
                        "id": str(uuid.uuid4()),
                        "task_id": task_id,
                        "vulnerability_type": vuln,
                        "severity": "medium",
                        "title": "Mock finding",
                        "description": "Mock preflight finding",
                        "file_path": "src/app.py",
                        "line_start": 1,
                        "line_end": 3,
                        "code_snippet": "from flask import Flask",
                        "is_verified": False,
                        "confidence": 0.5,
                        "status": "new",
                        "created_at": "2026-07-01T00:00:00Z",
                    }
                ],
                "summary": {
                    "task_id": task_id,
                    "status": "completed",
                    "security_score": 50,
                    "total_findings": 1,
                    "verified_findings": 0,
                    "severity_distribution": {"medium": 1},
                    "vulnerability_types": {vuln: 1},
                    "duration_seconds": 1,
                    "phases_completed": ["analysis"],
                },
            }
            self._send_json(HTTPStatus.OK, {"id": task_id, "status": "completed"})
            return

        self._send_json(HTTPStatus.NOT_FOUND, {"detail": "Not found"})


def main():
    parser = argparse.ArgumentParser(description="Minimal mock DeepAudit API for WSL preflight testing")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=18000)
    args = parser.parse_args()

    server = ThreadingHTTPServer((args.host, args.port), MockDeepAuditHandler)
    print(f"Mock DeepAudit API listening on http://{args.host}:{args.port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
