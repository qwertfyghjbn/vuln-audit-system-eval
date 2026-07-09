# SSRF-PY-REPO-001 — SSRF (Vulnerable, Repo Mode)

**Language:** Python  
**Vuln type:** SSRF  
**Label:** vulnerable  
**Severity:** High  
**Input mode:** repo

## Project layout

```
src/
├── app.py                     # Flask app entry point
├── routes/
│   └── proxy_routes.py        # HTTP layer — source of tainted input
├── services/
│   └── proxy_service.py       # Business logic layer — passthrough
└── utils/
    └── http_utils.py          # I/O layer — requests.get() sink
```

## What this case tests

Cross-file SSRF taint tracing across three layers. The vulnerability exists
in the utils layer but the taint originates in the route layer. A system
inspecting files in isolation will see `requests.get(url)` in `http_utils.py`
but cannot know the argument is user-controlled without tracing back through
the call chain.

## Taint flow

```
routes/proxy_routes.py    L10   request.args.get('url')       ← source
routes/proxy_routes.py    L14   _service.fetch_remote(url)
                                  │
services/proxy_service.py L6    get_url(url)                  ← passthrough, no validation
                                  │
utils/http_utils.py       L6    requests.get(url, timeout=5)  ← sink
```

## What a correct system should report

- One High-severity SSRF finding
- Source: `routes/proxy_routes.py` L10
- Sink: `utils/http_utils.py` L6 (minimum match: L5–L7)
- Two-step propagation chain across all layers

## What is intentionally absent

- No URL parsing or scheme check at any layer
- No domain or host restriction
- No IP-range blocklist
- `allow_redirects` defaults to `True`
- `ProxyService` is a pure passthrough — taint unbroken across all layers
