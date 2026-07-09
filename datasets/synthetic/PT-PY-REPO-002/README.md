# PT-PY-REPO-002 — Path Traversal (Near-Miss, Repo Mode)

**Language:** Python  
**Vuln type:** Path Traversal  
**Label:** near_miss  
**Difficulty:** hard  
**Input mode:** repo

## Project layout

```
src/
├── app.py                     # Flask app entry point
├── routes/
│   └── file_routes.py         # HTTP layer — source of tainted input (identical to REPO-001)
├── services/
│   └── file_service.py        # Business logic layer — guard lives here
└── utils/
    └── file_utils.py          # I/O layer — open() with no path check (looks vulnerable)
```

## What this case tests

Tests two distinct failure modes in cross-layer analysis:

1. **Isolated-file analysis**: a system inspecting `utils/file_utils.py` alone
   sees `open(path)` with an argument it cannot trace — and flags it.

2. **Incomplete inter-procedural tracing**: a system that follows the call
   chain from the route layer but does not enter `_resolve_safe_path()` inside
   `get_file_content()` will still reach `open()` with an apparently-tainted
   path — and flags it.

A correct system must trace *into* `_resolve_safe_path()` and recognize all
four controls before concluding the path is safe.

## Taint flow with guard

```
routes/file_routes.py   L10   request.args.get('filename')   ← source
routes/file_routes.py   L14   _service.get_file_content(filename)
                                │
services/file_service.py L22  _resolve_safe_path(filename)   ← guard (must enter)
  ├── L10  normpath()           normalizes separators; non-leading '..' only
  ├── L11  isabs() check        rejects absolute paths
  ├── L14  realpath()           resolves symlinks
  └── L16  startswith() check   enforces BASE_DIR prefix
                                │
services/file_service.py L25  read_file(safe_path)           ← safe_path is canonicalized
                                │
utils/file_utils.py     L3    open(path, 'rb')               ← receives pre-validated path
```

## Comparison with PT-PY-REPO-001

| Aspect | REPO-001 (vulnerable) | REPO-002 (near-miss) |
|--------|----------------------|----------------------|
| Route layer | identical | identical |
| Service layer | pure passthrough | guard in `_resolve_safe_path()` |
| Utils layer | `os.path.join` + `open` | bare `open(path)` — trusts caller |
| False-positive trigger | N/A | isolated utils analysis OR incomplete service tracing |

## What a correct system should output

No findings, or at most an Informational note confirming the utils-layer
`open()` was reviewed and determined to receive only pre-validated paths.
