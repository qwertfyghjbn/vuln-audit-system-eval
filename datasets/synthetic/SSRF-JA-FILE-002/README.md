# SSRF-JA-FILE-002 — SSRF (Near-Miss)

**Language:** Java  
**Vuln type:** SSRF  
**Label:** near_miss  
**Severity:** N/A (no valid finding)  
**Input mode:** file

## What this case tests

Tests whether the system avoids false positives when the surface pattern
(`@RequestParam → RestTemplate.getForObject()`) is present but a real guard
sits in the private helper method `isSafeUrl()`.

## Surface pattern (looks vulnerable)

```
@RequestParam String url               ← line 60
  └─► isSafeUrl(url)                  ← line 64  (system must enter this)
        └─► getForObject(url, ...)     ← line 67
```

## Why it is actually safe

`isSafeUrl()` (lines 23–45) applies a three-layer defense chain, and
`buildNoRedirectTemplate()` (lines 47–57) prevents redirect-based bypass:

| Lines | Control | Bypasses |
|-------|---------|---------|
| 26–28 | Scheme allowlist (`https` only) | blocks `http://`, `file://`, `gopher://` |
| 30–32 | Domain allowlist | blocks arbitrary external/internal hostnames |
| 35–37 | IP-range blocklist | blocks 127.x, 10.x, 192.168.x, 169.254.x |
| 53    | `setInstanceFollowRedirects(false)` | prevents 3xx redirect bypass |

## False-positive trigger

A system matching `@RequestParam → RestTemplate.getForObject()` without
tracing into `isSafeUrl()` will flag line 67 as a High-severity SSRF finding.
A correct system must analyze all four controls.

## What a correct system should output

No findings, or at most an Informational note confirming the pattern was
reviewed and determined to be guarded.
