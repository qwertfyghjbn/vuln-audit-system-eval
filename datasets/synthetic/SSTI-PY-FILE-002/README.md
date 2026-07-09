# SSTI-PY-FILE-002 — SSTI (Near-Miss)

**Language:** Python  
**Vuln type:** SSTI / Template Injection  
**Label:** near_miss  
**Severity:** N/A (no valid finding)  
**Input mode:** file

## What this case tests

Tests whether the system distinguishes between two fundamentally different
usage patterns of `render_template_string()`:

1. **Vulnerable**: user input concatenated into the template *source*
2. **Safe**: user input passed as a context *variable* to a static template

The surface pattern here looks risky: user input is accepted and a call to
`render_template_string()` is present. A system without semantic understanding
of the source-vs-context distinction will produce a false positive.

## Surface pattern (looks vulnerable)

```
request.args['name']                                    ← line 19
  └─► _sanitize_name(raw_name)                          ← line 20
        └─► render_template_string(_GREETING_TEMPLATE,  ← line 24
                                   name=name)
```

## Why it is actually safe

Two independent controls prevent SSTI:

| Control | Location | Why it matters |
|---------|----------|----------------|
| Static template constant `_GREETING_TEMPLATE` | line 5 | Template source never contains user data; `{{ name }}` is a safe placeholder |
| Strict regex allowlist in `_sanitize_name` | lines 9–14 | Blocks all Jinja2 control characters (`{`, `}`, `%`, `#`) |

The primary defense is the static template. The regex is defense-in-depth.

## False-positive trigger

A system that flags `render_template_string()` whenever any user-derived
variable is reachable — without checking whether it enters the *template
source* or only the *render context* — will flag line 24 as High SSTI.

## What a correct system should output

No findings, or at most an Informational note confirming the static template
pattern was reviewed.
