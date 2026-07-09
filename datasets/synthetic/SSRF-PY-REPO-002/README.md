# SSRF-PY-REPO-002 — SSRF (Near-Miss, Repo Mode)

**Language:** Python  
**Vuln type:** SSRF  
**Label:** near_miss  
**Difficulty:** hard  
**Input mode:** repo

## Project layout

```
src/
├── app.py                     # Flask app entry point
├── routes/
│   └── proxy_routes.py        # HTTP layer — source (identical to REPO-001)
├── services/
│   └── proxy_service.py       # Business logic layer — guard lives here
└── utils/
    └── http_utils.py          # I/O layer — requests.get() with no URL check
```

## What this case tests

Tests two distinct false-positive failure modes in cross-layer SSRF analysis:

1. **Isolated-file analysis**: a system inspecting `utils/http_utils.py` alone
   sees `requests.get(url)` with an externally supplied argument — no way to
   verify it is safe without tracing into the caller.

2. **Incomplete inter-procedural tracing**: a system that follows the call
   chain from the route layer but does not enter `_is_safe_url()` inside
   `fetch_remote()` will still reach `requests.get()` with an apparently-
   tainted URL and incorrectly flag it.

A correct system must trace into `_is_safe_url()` and recognize all three
controls, plus note `allow_redirects=False` in the utils layer.

## Taint flow with guard

```
routes/proxy_routes.py    L10   request.args.get('url')        ← source
routes/proxy_routes.py    L14   _service.fetch_remote(url)
                                  │
services/proxy_service.py L34   _is_safe_url(url)              ← guard (must enter)
  ├── L17  scheme allowlist       blocks http://, file://, gopher://
  ├── L21  domain allowlist       blocks internal/arbitrary hostnames
  └── L26  IP-range blocklist     blocks raw IP literals: 127.x, 10.x, 169.254.x (no DNS resolution)
                                  │
services/proxy_service.py L36   get_url(url)                   ← pre-validated URL
                                  │
utils/http_utils.py       L6    requests.get(url, ...,         ← receives pre-validated URL
                                             allow_redirects=False)
```

## Comparison with SSRF-PY-REPO-001

| Aspect | REPO-001 (vulnerable) | REPO-002 (near-miss) |
|--------|----------------------|----------------------|
| Route layer | identical | identical |
| Service layer | pure passthrough | `_is_safe_url()` 3-layer guard |
| Utils `requests.get` | `allow_redirects` default (True) | `allow_redirects=False` |
| False-positive trigger | N/A | isolated utils analysis OR incomplete service tracing |

## What a correct system should output

No findings, or at most an Informational note confirming the utils-layer
`requests.get()` was reviewed and determined to receive only pre-validated
URLs from the service layer.
