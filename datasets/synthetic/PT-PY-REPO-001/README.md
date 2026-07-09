# PT-PY-REPO-001 — Path Traversal (Vulnerable, Repo Mode)

**Language:** Python  
**Vuln type:** Path Traversal  
**Label:** vulnerable  
**Severity:** High  
**Input mode:** repo

## Project layout

```
src/
├── app.py                     # Flask app entry point
├── routes/
│   └── file_routes.py         # HTTP layer — source of tainted input
├── services/
│   └── file_service.py        # Business logic layer — passthrough
└── utils/
    └── file_utils.py          # I/O layer — sink
```

## What this case tests

Cross-file inter-procedural taint tracing across three layers.
The vulnerability exists in the utils layer but the taint originates in the
route layer. A system that only inspects individual files in isolation will
either miss the source or miss the connection to the sink.

## Taint flow

```
routes/file_routes.py  L10   request.args.get('filename')    ← source
routes/file_routes.py  L14   _service.get_file_content(filename)
                                │
services/file_service.py L5   read_file(filename)            ← passthrough, no validation
                                │
utils/file_utils.py    L7    os.path.join(BASE_DIR, filename) ← propagation
utils/file_utils.py    L9    open(file_path, 'rb')            ← sink
```

## What a correct system should report

- One High-severity finding
- Source: `routes/file_routes.py` L10
- Sink: `utils/file_utils.py` L9 (minimum match: L7–L10)
- Three-step propagation chain across all layers

## What is intentionally absent

- No validation at the route→service boundary
- No validation at the service→utils boundary
- No `os.path.realpath()` or prefix check in `read_file()`
- `FileService` is a pure passthrough — the taint is unbroken across all layers
