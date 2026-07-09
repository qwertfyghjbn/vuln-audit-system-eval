# PT-JA-FILE-001 — Path Traversal (Vulnerable)

**Language:** Java  
**Vuln type:** Path Traversal  
**Label:** vulnerable  
**Severity:** High  
**Input mode:** file

## What this case tests

A Spring Boot `@RestController` reads a filename from `@RequestParam` and
constructs the file path with `Paths.get(BASE_DIR, filename)`. No path
normalization or prefix restriction is applied before `Files.readAllBytes()`.

`Paths.get()` preserves `..` components literally — they are not collapsed.
An attacker can supply `../../etc/passwd` to read arbitrary files.

## Vulnerable flow

```
@RequestParam String filename          ← source  (line 18)
  └─► Paths.get(BASE_DIR, filename)   ← propagation (line 23, no normalize)
        └─► Files.readAllBytes(path)  ← sink (line 24)
```

## What a correct system should report

- One High-severity finding in `downloadFile`
- Propagation at line 23, sink at line 24
- Missing controls: `normalize()`, `toRealPath()`, `startsWith()` prefix check

## What is intentionally absent

- No `Path.normalize()` call
- No `toRealPath()` for symlink resolution
- No `startsWith(BASE_DIR)` prefix check
- Only guard is `isEmpty()` check (line 19), which only rejects blank input
