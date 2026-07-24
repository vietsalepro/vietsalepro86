# Codebase Memory Relocation Audit

## 1. Audit Scope

Verify whether the `codebase-memory` MCP supports relocating its workspace from `C:\PROJECT\vietsalepro\.codebase-memory` to `C:\PROJECT\tailieu\.codebase-memory`.

## 2. Audit Steps

| # | Step | Evidence Source |
|---|---|---|
| 1 | Read required documents | `SEMANTIC_MEMORY.md`, `VALIDATION_REPORT.md`, `CODEBASE_MEMORY_BASELINE.md` |
| 2 | List MCP tools | `mcp_list_tools(codebase-memory)` |
| 3 | Query project registry | `mcp_call_tool(codebase-memory, list_projects, {})` |
| 4 | Inspect filesystem | `Get-ChildItem C:\PROJECT\vietsalepro\.codebase-memory` |
| 5 | Inspect target path | `Test-Path C:\PROJECT\tailieu\.codebase-memory` |
| 6 | Probe workspace tools | `mcp_call_tool(codebase-memory, get_workspace, {})` |
| 7 | Probe status tools | `mcp_call_tool(codebase-memory, get_status, {})` |
| 8 | Inspect git tracking | `git ls-files` and `git status --short` |
| 9 | Inspect `.gitignore` | `Select-String .gitignore codebase-memory` |

## 3. Evidence

### 3.1 Project registry

```json
{
  "projects": [
    {"name": "C-PROJECT-vietsalepro", "root_path": "C:/PROJECT/vietsalepro"},
    {"name": "vietsalepro", "root_path": "C:/PROJECT/vietsalepro"}
  ]
}
```

### 3.2 Unknown-tool responses

- `get_status` -> `unknown tool: get_status`
- `get_workspace` -> `unknown tool: get_workspace`

These responses prove the MCP does not expose workspace inspection or configuration endpoints.

### 3.3 Tracked `.codebase-memory` files

```
.codebase-memory/.gitattributes
.codebase-memory/artifact.json
.codebase-memory/graph.db.zst
memory-zone/.codebase-memory/.gitattributes
memory-zone/.codebase-memory/_config.db
memory-zone/.codebase-memory/artifact.json
```

### 3.4 `.gitignore` check

No `codebase-memory` entry in `c:/PROJECT/vietsalepro/.gitignore`.

## 4. Findings

- The `codebase-memory` MCP stores project metadata keyed to the repository root.
- The only persistence artifact output path is `.codebase-memory/graph.db.zst` relative to `repo_path`.
- No official mechanism exists to redirect indexing, graph generation, validation, or semantic search to an external directory.
- No filesystem changes were made by this program.

## 5. Risks of Unsupported Relocation

If relocation were attempted without official support:

- Future `index_repository` calls would recreate `.codebase-memory` inside `C:\PROJECT\vietsalepro`.
- The moved external directory would become stale or diverge from the live graph.
- Git would continue to track the regenerated artifacts unless `.gitignore` is also changed.

## 6. Recommendation

Do not relocate the workspace until the `codebase-memory` MCP officially supports a configurable storage location. In the interim, the safest supported alternative is to leave the workspace in the repository and, in a separate, explicitly scoped task, remove `.codebase-memory` from git tracking and add it to `.gitignore`.
