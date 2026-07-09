# SSRF-PY-FILE-002 — SSRF (Near-Miss)

**Language:** Python  
**Vuln type:** SSRF  
**Label:** near_miss  
**Severity:** N/A (no valid finding)  
**Input mode:** file

## What this case tests

Tests whether the system avoids false positives when the surface pattern
(`request.args → requests.get()`) is present but a real guard sits in a
separate helper function `_is_safe_url()`.

## Surface pattern (looks vulnerable)

```
request.args['url']              ← line 44
  └─► _is_safe_url(url)          ← line 48  (system must enter this)
        └─► requests.get(url, allow_redirects=False)  ← line 52
```

## Why it is actually safe

`_is_safe_url` (lines 12–39) applies a defense-in-depth chain:

| Lines | Control | Bypasses |
|-------|---------|---------|
| 22–23 | Scheme allowlist (`https` only) | blocks `file://`, `gopher://`, `http://` |
| 29–30 | Domain allowlist | blocks arbitrary external/internal hostnames |
| 33–35 | IP-range blocklist | blocks 127.x, 10.x, 192.168.x, 169.254.x |
| 52    | `allow_redirects=False` | prevents redirect-based bypass |

## False-positive trigger

A system relying on the pattern `request.args → requests.get()` without
tracing into `_is_safe_url()` will flag `requests.get()` at line 52 as a
High-severity SSRF finding. A correct system must analyze all four controls
inside the helper and recognize them as effective.

## What a correct system should output

No findings, or at most an Informational note that the pattern was reviewed
and determined to be guarded.
