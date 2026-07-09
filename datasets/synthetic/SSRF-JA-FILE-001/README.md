# SSRF-JA-FILE-001 — SSRF (Vulnerable)

**Language:** Java  
**Vuln type:** SSRF  
**Label:** vulnerable  
**Severity:** High  
**Input mode:** file

## What this case tests

A Spring Boot `@RestController` accepts a full URL from `@RequestParam` and
passes it directly to `RestTemplate.getForObject()`. No scheme, host, or
IP-range validation is applied, allowing an attacker to target internal
services or cloud metadata endpoints.

## Vulnerable flow

```
@RequestParam String url                    ← source  (line 14)
  └─► isEmpty() check only                 ← propagation (line 15, rejects blank only)
        └─► restTemplate.getForObject(url)  ← sink (line 18)
```

## What a correct system should report

- One High-severity SSRF finding in `fetchUrl`
- Source at line 14, sink at line 18
- Missing controls: scheme allowlist, domain allowlist, IP-range blocklist,
  redirect following disabled

## What is intentionally absent

- No URL parsing or scheme check
- No domain or host restriction
- No IP-range blocklist (loopback, site-local, link-local)
- RestTemplate uses default redirect-following behaviour
