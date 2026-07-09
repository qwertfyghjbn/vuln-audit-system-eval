# SSTI-JA-FILE-002 — SSTI (Near-Miss)

**Language:** Java  
**Vuln type:** SSTI / Template Injection  
**Label:** near_miss  
**Severity:** N/A (no valid finding)  
**Input mode:** file

## What this case tests

Tests whether the system distinguishes between two fundamentally different
Freemarker usage patterns:

1. **Vulnerable**: user input concatenated into the template *source* string
2. **Safe**: user input passed as a *model variable* to a static template

The surface pattern looks risky: user input is accepted and `template.process()`
is called. A system without semantic understanding of source-vs-model
injection will produce a false positive.

## Surface pattern (looks vulnerable)

```
@RequestParam String name                              ← line 29
  └─► sanitizeName(name)                              ← line 30
        └─► new Template(..., GREETING_TEMPLATE, ...) ← line 38  (static source!)
              model.put("name", safeName)             ← line 40  (user data as model var)
              template.process(model, out)            ← line 43
```

## Why it is actually safe

Two independent controls prevent SSTI:

| Control | Location | Why it matters |
|---------|----------|----------------|
| Static template constant `GREETING_TEMPLATE` | line 19 | Template source is `"Hello, ${name}!"` — fixed at compile time, user data cannot alter it |
| Strict regex allowlist in `sanitizeName` | lines 22–26 | Blocks all Freemarker control characters (`$`, `{`, `}`, `#`, `<`) |

The primary defense is the static template. The regex is defense-in-depth.

## Java/Freemarker-specific note

In Freemarker, `${name}` inside a template renders the model variable as a
string value. Even without auto-escaping, this is a **value interpolation**,
not a code injection point — the variable content is treated as data, not as
template syntax. Concatenating user input into the template source (as in
SSTI-JA-FILE-001) is fundamentally different and is the actual vulnerability.

## False-positive trigger

A system that flags `template.process()` whenever any user-derived variable
is reachable — without checking whether user data entered the *template source*
or only the *model map* — will flag line 43 as High SSTI.

## What a correct system should output

No findings, or at most an Informational note confirming the static template
pattern was reviewed.
