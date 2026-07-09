# SSTI-PY-REPO-001 — SSTI (Vulnerable, Repo Mode)

**Language:** Python  
**Vuln type:** SSTI / Template Injection  
**Label:** vulnerable  
**Severity:** High  
**Input mode:** repo

## Project layout

```
src/
├── app.py                       # Flask app entry point
├── routes/
│   └── report_routes.py         # HTTP layer — source of tainted input
├── services/
│   └── report_service.py        # Business logic layer — passthrough
└── utils/
    └── template_utils.py        # Template layer — concat + from_string sink
```

## What this case tests

Cross-file SSTI taint tracing across three layers. The string concatenation
into the template source happens in the utils layer, but the tainted value
originates in the route layer. A system inspecting files in isolation will
see the concatenation in `template_utils.py` but cannot know the argument
is user-controlled without tracing back through the call chain.

## Taint flow

```
routes/report_routes.py    L10   request.args.get('title')          ← source
routes/report_routes.py    L14   _service.render_preview(title)
                                   │
services/report_service.py L6    render_report_template(title)      ← passthrough, no validation
                                   │
utils/template_utils.py    L7    "<h1>" + title + "</h1>..."        ← propagation (concat into source)
utils/template_utils.py    L8    _env.from_string(template_str)     ← sink (engine parses user input)
utils/template_utils.py    L9    template.render()                  ← evaluation
```

## What a correct system should report

- One High-severity SSTI finding
- Source: `routes/report_routes.py` L10
- Sink: `utils/template_utils.py` L8 (minimum match: L7–L9)
- Three-step propagation chain across all layers

## What is intentionally absent

- No validation at the route→service boundary
- No validation at the service→utils boundary
- No static template constant in `render_report_template()`
- The HTML tag wrapping (`<h1>` + title + `</h1>`) is a mild obfuscation of
  the direct concatenation pattern used in the FILE-mode case
