# PT-PY-FILE-002 — Path Traversal (Near-Miss)

**Language:** Python  
**Vuln type:** Path Traversal  
**Label:** near_miss  
**Severity:** N/A (no valid finding)  
**Input mode:** file

## What this case tests

Tests whether the system avoids false positives when the vulnerable surface
pattern (`request.args → os.path.join → open()`) is present but a real guard
sits in a separate helper function.

## Surface pattern (looks vulnerable)

```
request.args['filename']                ← line 23
  └─► _resolve_safe_path(BASE_DIR, ..)  ← line 28  (system must enter this)
        └─► open(safe_path, 'rb')       ← line 32
```

## Why it is actually safe

`_resolve_safe_path` (lines 8–18) applies a defense-in-depth chain:

| Line | Control | Bypasses |
|------|---------|---------|
| 10 | `os.path.normpath` | strips `..` and redundant `/` |
| 11–12 | `isabs` check | rejects absolute paths post-normpath |
| 14 | `os.path.realpath` | resolves symlinks, remaining `..` |
| 16–17 | prefix check with `os.sep` | prevents partial-name bypass |

## False-positive trigger

A system relying on syntactic pattern matching (`user_input → join → open`)
without cross-function data-flow tracing will flag `open(safe_path)` at
line 32 as a High-severity finding. A correct system must trace into
`_resolve_safe_path` and recognize all four controls as effective.

## What a correct system should output

No findings, or at most an Informational note acknowledging the pattern
was reviewed and determined to be guarded.
