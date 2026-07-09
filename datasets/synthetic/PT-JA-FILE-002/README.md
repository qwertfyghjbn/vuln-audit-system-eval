# PT-JA-FILE-002 — Path Traversal (Near-Miss)

**Language:** Java  
**Vuln type:** Path Traversal  
**Label:** near_miss  
**Severity:** N/A (no valid finding)  
**Input mode:** file

## What this case tests

Tests whether the system avoids false positives when the vulnerable surface
pattern (`@RequestParam → Paths/Files API → Files.readAllBytes()`) is present
but a real guard sits in a private helper method `resolveSafePath()`.

## Surface pattern (looks vulnerable)

```
@RequestParam String filename            ← line 31
  └─► resolveSafePath(filename)          ← line 38  (system must enter this)
        └─► Files.readAllBytes(safePath) ← line 43
```

## Why it is actually safe

`resolveSafePath()` (lines 20–28) applies a three-step defense chain:

| Line | Control | Bypasses |
|------|---------|---------|
| 21 | `BASE_DIR.resolve(filename).normalize()` | collapses `..` segments logically |
| 22 | `resolved.toRealPath()` | resolves symlinks to canonical path |
| 24 | `real.startsWith(realBase)` | enforces strict BASE_DIR containment |

## Java-specific nuance

`normalize()` eliminates `..` at the logical level but does **not** resolve
symlinks. `toRealPath()` is required to obtain a canonical filesystem path.
Both are present here — the combination is effective.

## False-positive trigger

A system that matches `@RequestParam → Files.readAllBytes()` without tracing
into `resolveSafePath()` will flag line 43 as a High-severity finding.
A correct system must analyze all three controls inside the helper.

## What a correct system should output

No findings, or at most an Informational note confirming the pattern was
reviewed and determined to be guarded.
