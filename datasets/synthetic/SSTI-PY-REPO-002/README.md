# SSTI-PY-REPO-002 — SSTI (Near-Miss, Repo Mode)

**Language:** Python  
**Vuln type:** SSTI / Template Injection  
**Label:** near_miss  
**Difficulty:** hard  
**Input mode:** repo

## Project layout

```
src/
├── app.py                       # Flask app entry point
├── routes/
│   └── report_routes.py         # HTTP layer — source (nearly identical to REPO-001)
├── services/
│   └── report_service.py        # Business logic layer — regex allowlist guard
└── utils/
    └── template_utils.py        # Template layer — static template + context variable
```

## What this case tests

Tests two compounding false-positive failure modes in cross-layer SSTI analysis:

1. **Incomplete service tracing**: system follows `title → render_preview(title)` but
   does not enter `_validate_title()`, missing the regex allowlist.

2. **Source-vs-context confusion in utils**: system sees `from_string()` called near
   a user-derived variable and flags it, without verifying that `from_string()` receives
   the static constant `_REPORT_TEMPLATE` — not the user input.

A correct system must trace all three layers **and** understand that user data
enters only as a `render()` context variable, never as template source.

## Taint flow with guards

```
routes/report_routes.py    L10   request.args.get('title')            ← source
routes/report_routes.py    L14   _service.render_preview(title)
                                   │
services/report_service.py L16   _validate_title(title)               ← guard 1 (must enter)
  └── L11  regex fullmatch         blocks {{ }} % # and other Jinja2 syntax
                                   │
services/report_service.py L19   render_report_template(safe_title)
                                   │
utils/template_utils.py    L8    _env.from_string(_REPORT_TEMPLATE)   ← static source (not user input!)
utils/template_utils.py    L9    template.render(title=safe_title)    ← context variable, not source
```

## Comparison with SSTI-PY-REPO-001

| Aspect | REPO-001 (vulnerable) | REPO-002 (near-miss) |
|--------|----------------------|----------------------|
| Route layer | identical | nearly identical |
| Service layer | pure passthrough | `_validate_title()` regex guard |
| Utils: template source | `"<h1>" + title + "..."` | `_REPORT_TEMPLATE` static constant |
| Utils: user data path | concatenated into source | `render(title=title)` context kwarg |
| `from_string()` arg | attacker-controlled string | compile-time constant |

## False-positive triggers (two independent)

| Trigger | Location | What system incorrectly concludes |
|---------|----------|----------------------------------|
| Skips `_validate_title()` | services/report_service.py L16 | regex guard not recognized |
| Sees `from_string()` + `title` reachable | utils/template_utils.py L8–L9 | flags as SSTI without source-vs-context check |

## What a correct system should output

No findings, or at most an Informational note confirming `from_string()` was
reviewed and determined to receive only a static template constant, with user
data flowing only as a context variable.
