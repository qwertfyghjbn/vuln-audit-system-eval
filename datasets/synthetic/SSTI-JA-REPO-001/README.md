# SSTI-JA-REPO-001 — SSTI (Vulnerable, Repo Mode)

**Language:** Java  
**Vuln type:** SSTI / Template Injection  
**Label:** vulnerable  
**Severity:** High  
**Input mode:** repo

## Project layout

```
src/main/java/com/example/demo/
├── controller/
│   └── ReportController.java  # HTTP layer — source of tainted input
├── service/
│   └── ReportService.java     # Business logic layer — passthrough
└── util/
    └── TemplateUtil.java      # Template layer — concat + Template constructor sink
```

## What this case tests

Cross-file SSTI taint tracing across three Java package layers. The string
concatenation into the Freemarker template source happens in the util layer,
but the tainted value originates in the controller layer. A system inspecting
files in isolation will see the concatenation in `TemplateUtil.java` but
cannot know the argument is user-controlled without tracing back through the
call chain.

## Taint flow

```
controller/ReportController.java  L15   @RequestParam String title       ← source
controller/ReportController.java  L19   reportService.renderPreview(title)
                                          │
service/ReportService.java        L8    TemplateUtil.renderReportTemplate(title)  ← passthrough
                                          │
util/TemplateUtil.java            L21   "<h1>" + title + "</h1>..."      ← propagation (concat into source)
util/TemplateUtil.java            L22   new Template(..., templateStr)   ← sink (Freemarker parses user input)
util/TemplateUtil.java            L24   template.process(...)            ← evaluation
```

## What a correct system should report

- One High-severity SSTI finding
- Source: `controller/ReportController.java` L15
- Sink: `util/TemplateUtil.java` L22 (minimum match: L21–L23)
- Three-step propagation chain across all layers

## What is intentionally absent

- No validation at the controller→service boundary
- No validation at the service→util boundary
- No static template constant in `TemplateUtil`
- User input is concatenated into template source (not passed as model variable)

## Java/Freemarker note

`new Template(name, reader, cfg)` **parses** the template source — this is
where user-injected syntax is compiled. `template.process(model, out)`
**evaluates** it. The sink is at line 22 (construction), not line 24.
