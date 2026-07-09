# PT-PY-FILE-001 — Path Traversal (Vulnerable)

**Language:** Python  
**Vuln type:** Path Traversal  
**Label:** vulnerable  
**Severity:** High  
**Input mode:** file

## What this case tests

A Flask `/download` endpoint reads a file whose name comes directly from the
query string. `os.path.join(BASE_DIR, filename)` is called without any path
normalization, then the result is opened for reading.

A user-supplied value like `../../../../etc/passwd` resolves to a path outside
`BASE_DIR`, enabling arbitrary file read.

## Vulnerable flow

```
request.args['filename']          ← source  (line 10)
  └─► os.path.join(BASE_DIR, ..)  ← propagation (line 14)
        └─► open(file_path, 'rb') ← sink (line 17)
```

## What a correct system should report

- One High-severity finding in `download_file`
- Source identified at line 10, sink at line 17
- Missing controls: `os.path.realpath` + prefix check

## What is intentionally absent

- No path normalization (`os.path.realpath`, `os.path.abspath`)
- No prefix restriction
- The only guard (`if not filename`) only rejects empty strings
