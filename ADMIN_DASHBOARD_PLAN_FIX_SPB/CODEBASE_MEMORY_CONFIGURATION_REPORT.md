# Codebase Memory Configuration Report

## 1. MCP Project Registry

`list_projects` returned the following indexed projects:

```json
{
  "projects": [
    {
      "name": "C-PROJECT-vietsalepro",
      "root_path": "C:/PROJECT/vietsalepro",
      "nodes": 29426,
      "edges": 43038,
      "size_bytes": 43188224
    },
    {
      "name": "vietsalepro",
      "root_path": "C:/PROJECT/vietsalepro",
      "nodes": 28881,
      "edges": 42874,
      "size_bytes": 43581440
    }
  ]
}
```

Both projects are rooted in `C:/PROJECT/vietsalepro`. There is no project entry for `C:/PROJECT/tailieu`.

## 2. Filesystem Workspace

`C:\PROJECT\vietsalepro\.codebase-memory` contains:

| File | Size (bytes) | Purpose |
|---|---|---|
| `.gitattributes` | 123 | Git attributes |
| `artifact.json` | 288 | Index metadata |
| `CODEBASE_MEMORY_BASELINE.md` | 10515 | Baseline registration |
| `graph.db.zst` | 7802519 | Compressed graph artifact |
| `SEMANTIC_MEMORY.md` | 32613 | Semantic memory |
| `update-codebase-memory.txt` | 428 | Update note |
| `VALIDATION_REPORT.md` | 13664 | Validation report |

`C:\PROJECT\tailieu\.codebase-memory` does not exist.

## 3. Tool Surface

The `codebase-memory` MCP exposes at least these tools:

- `index_repository`
- `search_graph`
- `query_graph`
- `trace_path`
- `get_code_snippet`
- `list_projects`

No tools named `get_workspace`, `set_workspace`, `configure_storage`, `get_status`, or similar were discovered.

## 4. Index Repository Schema

`index_repository` accepts:

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `repo_path` | string | yes | Path to the repository to be indexed |
| `mode` | enum | no | `full`, `moderate`, `fast`, `cross-repo-intelligence` |
| `name` | string | no | Override project name |
| `persistence` | boolean | no | Write `.codebase-memory/graph.db.zst` for sharing |
| `target_projects` | string[] | no | Cross-repo mode only |

The `persistence` flag writes the artifact to `.codebase-memory/graph.db.zst` relative to `repo_path`. It does not accept an arbitrary output directory.

## 5. Search / Query / Trace Schemas

All graph operations require a `project` parameter. The project name maps back to the `root_path` registered during `index_repository`. There is no parameter to redirect graph storage or to point to an external `.codebase-memory` directory.

## 6. Workspace Configuration Conclusion

The `codebase-memory` MCP has no configurable workspace, storage path, cache path, or semantic graph location. The workspace is implicitly defined by the `repo_path` passed to `index_repository`. Therefore, relocating the workspace to `C:\PROJECT\tailieu\.codebase-memory` is not supported through the official MCP interface.
