# PT-JA-REPO-002 — Path Traversal (Near-Miss, Repo Mode)

**Language:** Java  
**Vuln type:** Path Traversal  
**Label:** near_miss  
**Difficulty:** hard  
**Input mode:** repo

## Project layout

```
src/main/java/com/example/demo/
├── controller/
│   └── FileController.java    # HTTP layer — source (identical to REPO-001)
├── service/
│   └── FileService.java       # Business logic layer — guard lives here
└── util/
    └── FileUtil.java          # I/O layer — Files.readAllBytes() with no path check
```

## What this case tests

Tests two distinct false-positive failure modes in cross-layer analysis:

1. **Isolated-file analysis**: a system inspecting `FileUtil.java` alone sees
   `Files.readAllBytes(path)` with an externally supplied `Path` argument — no
   way to verify it is safe without tracing into the caller.

2. **Incomplete inter-procedural tracing**: a system that follows the call
   chain from the controller but does not enter `resolveSafePath()` inside
   `getFileContent()` will still reach `Files.readAllBytes()` with an
   apparently-tainted argument and incorrectly flag it.

A correct system must trace into `resolveSafePath()` and recognize all four
controls before concluding the path is safe.

## Taint flow with guard

```
controller/FileController.java  L15   @RequestParam String filename    ← source
controller/FileController.java  L19   fileService.getFileContent(filename)
                                        │
service/FileService.java        L30   resolveSafePath(filename)         ← guard (must enter)
  ├── L15  normalize()                  collapses '..' logically
  ├── L16  pre-symlink startsWith()     early reject if outside BASE_DIR
  ├── L19  toRealPath()                 resolves symlinks canonically
  └── L21  post-symlink startsWith()    final prefix check on real path
                                        │
service/FileService.java        L34   FileUtil.readFile(safePath)       ← safePath is canonical Path
                                        │
util/FileUtil.java              L11   Files.readAllBytes(path)          ← receives pre-validated Path
```

## Java-specific design note

`FileUtil.readFile()` accepts a `Path` object (not `String`). This is a
deliberate API design signal: callers are expected to have already resolved
and validated the path. However, this alone is not proof of safety — a
correct system must still trace that only `resolveSafePath()`-validated paths
are passed here.

The service layer applies a **two-stage** prefix check:
- Stage 1 (L16): after `normalize()` — catches logical `..` traversal
- Stage 2 (L21): after `toRealPath()` — catches symlink-based traversal

## Comparison with PT-JA-REPO-001

| Aspect | REPO-001 (vulnerable) | REPO-002 (near-miss) |
|--------|----------------------|----------------------|
| Controller layer | identical | identical |
| Service layer | pure passthrough | guard in `resolveSafePath()` |
| Util layer | `Paths.get(String)` + `readAllBytes` | `readAllBytes(Path)` — trusts caller |
| Util param type | `String filename` | `Path path` (pre-resolved) |
| False-positive trigger | N/A | isolated util analysis OR incomplete service tracing |

## What a correct system should output

No findings, or at most an Informational note confirming the util-layer
`Files.readAllBytes()` was reviewed and determined to receive only
pre-validated paths.
