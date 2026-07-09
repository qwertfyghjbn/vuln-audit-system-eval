# PT-JA-REPO-001 — Path Traversal (Vulnerable, Repo Mode)

**Language:** Java  
**Vuln type:** Path Traversal  
**Label:** vulnerable  
**Severity:** High  
**Input mode:** repo

## Project layout

```
src/main/java/com/example/demo/
├── controller/
│   └── FileController.java    # HTTP layer — source of tainted input
├── service/
│   └── FileService.java       # Business logic layer — passthrough
└── util/
    └── FileUtil.java          # I/O layer — sink
```

## What this case tests

Cross-file inter-procedural taint tracing across three Java package layers.
The vulnerability exists in the util layer but the taint originates in the
controller layer. A system that only inspects individual files in isolation
will either miss the source or miss the connection to the sink.

## Taint flow

```
controller/FileController.java  L15   @RequestParam String filename    ← source
controller/FileController.java  L19   fileService.getFileContent(filename)
                                        │
service/FileService.java        L8    FileUtil.readFile(filename)       ← passthrough, no validation
                                        │
util/FileUtil.java              L13   Paths.get(BASE_DIR, filename)     ← propagation
util/FileUtil.java              L15   Files.readAllBytes(filePath)      ← sink
```

## What a correct system should report

- One High-severity finding
- Source: `controller/FileController.java` L15
- Sink: `util/FileUtil.java` L15 (minimum match: L13–L16)
- Three-step propagation chain across all layers

## What is intentionally absent

- No validation at the controller→service boundary
- No validation at the service→util boundary
- No `normalize()`, `toRealPath()`, or `startsWith()` in `FileUtil.readFile()`
- `FileService` is a pure passthrough — the taint is unbroken across all layers
