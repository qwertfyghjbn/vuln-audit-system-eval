# SSTI-JA-REPO-002 — SSTI (Near-Miss, Repo Mode)

**Language:** Java  
**Vuln type:** SSTI / Template Injection  
**Label:** near_miss  
**Difficulty:** hard  
**Input mode:** repo

## Project layout

```
src/main/java/com/example/demo/
├── controller/
│   └── ReportController.java  # HTTP layer — source (nearly identical to REPO-001)
├── service/
│   └── ReportService.java     # Business logic layer — regex allowlist guard
└── util/
    └── TemplateUtil.java      # Template layer — static template + model variable
```

## What this case tests

Tests two compounding false-positive failure modes in cross-layer Java SSTI
analysis:

1. **Incomplete service tracing**: system follows `title → renderPreview(title)`
   but does not enter `validateTitle()`, missing the regex allowlist.

2. **Source-vs-model confusion in util**: system sees `new Template()` called
   near a user-derived variable and flags it, without verifying that
   `new Template()` receives the static constant `REPORT_TEMPLATE` — not the
   user input.

A correct system must trace all three layers **and** confirm that user data
enters only as a `process()` model variable, never as template source.

## Taint flow with guards

```
controller/ReportController.java  L15   @RequestParam String title           ← source
controller/ReportController.java  L19   reportService.renderPreview(title)
                                          │
service/ReportService.java        L19   validateTitle(title)                  ← guard 1 (must enter)
  └── L15  regex matches()               blocks $, {, }, #, < and FTL syntax
                                          │
service/ReportService.java        L23   TemplateUtil.renderReportTemplate(safeTitle)
                                          │
util/TemplateUtil.java            L23   new Template(..., REPORT_TEMPLATE, .) ← static source (not user input!)
util/TemplateUtil.java            L25   template.process(Map.of("title",title)) ← model variable, not source
```

## Comparison with SSTI-JA-REPO-001

| Aspect | REPO-001 (vulnerable) | REPO-002 (near-miss) |
|--------|----------------------|----------------------|
| Controller layer | identical | nearly identical |
| Service layer | pure passthrough | `validateTitle()` regex guard |
| Util: template source | `"<h1>" + title + "..."` | `REPORT_TEMPLATE` static constant |
| Util: user data path | concatenated into source | `Map.of("title", title)` model map |
| `new Template()` arg | attacker-controlled string | compile-time constant |

## False-positive triggers (two independent)

| Trigger | Location | What system incorrectly concludes |
|---------|----------|----------------------------------|
| Skips `validateTitle()` | service/ReportService.java L19 | regex guard not recognized |
| Sees `new Template()` + `title` reachable | util/TemplateUtil.java L23–L25 | flags as SSTI without source-vs-model check |

## What a correct system should output

No findings, or at most an Informational note confirming `new Template()` was
reviewed and determined to receive only the static constant `REPORT_TEMPLATE`,
with user data flowing only as a model variable to `template.process()`.
