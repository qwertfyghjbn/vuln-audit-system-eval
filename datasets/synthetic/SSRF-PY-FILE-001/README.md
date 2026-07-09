# SSRF-PY-FILE-001 — SSRF (Vulnerable)

**Language:** Python  
**Vuln type:** SSRF  
**Label:** vulnerable  
**Severity:** High  
**Input mode:** file

## What this case tests

A Flask `/fetch` endpoint accepts a full URL from the query string and passes
it directly to `requests.get()`. No scheme, host, or IP-range validation is
applied, allowing an attacker to target internal services or cloud metadata
endpoints.

## Vulnerable flow

```
request.args['url']         ← source  (line 9)
  └─► (empty-string check)  ← propagation (line 10, only rejects '')
        └─► requests.get()  ← sink (line 14)
```

## What a correct system should report

- One High-severity SSRF finding in `fetch_url`
- Source at line 9, sink at line 14
- Missing controls: scheme allowlist, domain allowlist, IP-range blocklist, `allow_redirects=False`

## What is intentionally absent

- No URL parsing or scheme check
- No domain or host restriction
- No IP-range blocklist (internal, loopback, link-local)
- `allow_redirects` defaults to `True`
