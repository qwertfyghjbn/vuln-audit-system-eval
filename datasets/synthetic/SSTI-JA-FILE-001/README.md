# SSTI-JA-FILE-001 — SSTI (Vulnerable)

**Language:** Java  
**Vuln type:** SSTI / Template Injection  
**Label:** vulnerable  
**Severity:** High  
**Input mode:** file

## What this case tests

A Spring Boot `@RestController` concatenates a user-supplied name directly
into a Freemarker template source string, then constructs a `Template` object
from it. The Freemarker engine parses the full resulting string, including any
directives or expressions the attacker embeds.

## Vulnerable flow

```
@RequestParam String name                              ← source  (line 17)
  └─► "Hello, " + name + "!"                         ← propagation (line 21, concat into source)
        └─► new Template(..., new StringReader(str))  ← sink (line 22, engine parses attacker input)
              └─► template.process(...)               ← evaluation (line 25)
```

## What a correct system should report

- One High-severity SSTI finding in `greet`
- Propagation at line 21 (string concat into template source)
- Sink at line 22 (`new Template` constructor parses the attacker-controlled string)
- Root cause: user data in template **source**, not in template **model**

## What is intentionally absent

- No static template constant
- No character filter or regex allowlist
- User input goes into the template source string itself via `+` concatenation,
  not as a model variable passed to `process()`
