# SSRF-JA-REPO-002 — SSRF (Near-Miss, Repo Mode)

**Language:** Java  
**Vuln type:** SSRF  
**Label:** near_miss  
**Difficulty:** hard  
**Input mode:** repo

## Project layout

```
src/main/java/com/example/demo/
├── controller/
│   └── ProxyController.java   # HTTP layer — source (identical to REPO-001)
├── service/
│   └── ProxyService.java      # Business logic layer — guard lives here
└── util/
    └── HttpUtil.java          # I/O layer — getForObject() with no URL check
```

## What this case tests

Tests two distinct false-positive failure modes in cross-layer Java SSRF
analysis:

1. **Isolated-file analysis**: a system inspecting `HttpUtil.java` alone sees
   `REST_TEMPLATE.getForObject(url, ...)` with an externally supplied `String`
   argument — no way to verify it is safe without tracing into the caller.

2. **Incomplete inter-procedural tracing**: a system that follows the call
   chain from the controller but does not enter `isSafeUrl()` inside
   `fetchRemote()` will still reach `getForObject()` with an apparently-tainted
   URL and incorrectly flag it.

A correct system must trace into `isSafeUrl()`, recognize all three controls,
and also note `setInstanceFollowRedirects(false)` in the util static initializer.

## Taint flow with guard

```
controller/ProxyController.java  L15   @RequestParam String url          ← source
controller/ProxyController.java  L19   proxyService.fetchRemote(url)
                                         │
service/ProxyService.java        L42   isSafeUrl(url)                    ← guard (must enter)
  ├── L19  scheme allowlist             blocks http://, file://, gopher://
  ├── L23  domain allowlist             blocks arbitrary/internal hostnames
  └── L28  IP-range check (allowlisted hosts only, DNS failures ignored) blocks 127.x, 10.x, 169.254.x
                                         │
service/ProxyService.java        L45   HttpUtil.getUrl(url)              ← pre-validated URL
                                         │
util/HttpUtil.java               L26   REST_TEMPLATE.getForObject(url,..) ← receives pre-validated URL
                                        (RestTemplate has no-redirect factory)
```

## Comparison with SSRF-JA-REPO-001

| Aspect | REPO-001 (vulnerable) | REPO-002 (near-miss) |
|--------|----------------------|----------------------|
| Controller layer | identical | identical |
| Service layer | pure passthrough | `isSafeUrl()` 3-layer guard |
| Util RestTemplate | default (follows redirects) | `setInstanceFollowRedirects(false)` |
| False-positive trigger | N/A | isolated util analysis OR incomplete service tracing |

## What a correct system should output

No findings, or at most an Informational note confirming the util-layer
`getForObject()` was reviewed and determined to receive only pre-validated
URLs from the service layer.
