# SSRF-JA-REPO-001 — SSRF (Vulnerable, Repo Mode)

**Language:** Java  
**Vuln type:** SSRF  
**Label:** vulnerable  
**Severity:** High  
**Input mode:** repo

## Project layout

```
src/main/java/com/example/demo/
├── controller/
│   └── ProxyController.java   # HTTP layer — source of tainted input
├── service/
│   └── ProxyService.java      # Business logic layer — passthrough
└── util/
    └── HttpUtil.java          # I/O layer — RestTemplate.getForObject() sink
```

## What this case tests

Cross-file SSRF taint tracing across three Java package layers. The
vulnerability exists in the util layer but the taint originates in the
controller layer. A system inspecting files in isolation will see
`REST_TEMPLATE.getForObject(url, ...)` in `HttpUtil.java` but cannot know
the argument is user-controlled without tracing back through the call chain.

## Taint flow

```
controller/ProxyController.java  L15   @RequestParam String url          ← source
controller/ProxyController.java  L19   proxyService.fetchRemote(url)
                                         │
service/ProxyService.java        L8    HttpUtil.getUrl(url)              ← passthrough, no validation
                                         │
util/HttpUtil.java               L11   REST_TEMPLATE.getForObject(url,..) ← sink
```

## What a correct system should report

- One High-severity SSRF finding
- Source: `controller/ProxyController.java` L15
- Sink: `util/HttpUtil.java` L11 (minimum match: L10–L12)
- Two-step propagation chain across all layers

## What is intentionally absent

- No URL parsing or scheme check at any layer
- No domain or host restriction
- No IP-range blocklist
- `RestTemplate` uses default redirect-following behaviour
- `ProxyService` is a pure passthrough — taint unbroken across all layers
