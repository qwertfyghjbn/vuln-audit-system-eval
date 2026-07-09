# SSTI-PY-FILE-001 — SSTI (Vulnerable)

**Language:** Python  
**Vuln type:** SSTI / Template Injection  
**Label:** vulnerable  
**Severity:** High  
**Input mode:** file

## What this case tests

A Flask `/greet` endpoint concatenates a user-supplied name directly into a
Jinja2 template source string before calling `Environment.from_string()`.
The engine parses and evaluates the resulting string, including any Jinja2
expressions the attacker embeds.

## Vulnerable flow

```
request.args['name']                      ← source  (line 10)
  └─► "Hello, " + name + "!"             ← propagation (line 11, string concat)
        └─► jinja_env.from_string(...)    ← sink (line 12)
              └─► template.render()       ← evaluation (line 13)
```

## What a correct system should report

- One High-severity SSTI finding in `greet`
- Propagation at line 11 (concat into template source), sink at line 12
- Root cause: user data in template **source**, not in template **context**

## What is intentionally absent

- No static template constant
- No character filter or regex allowlist
- User input goes into the template string itself, not as a `render()` kwarg
