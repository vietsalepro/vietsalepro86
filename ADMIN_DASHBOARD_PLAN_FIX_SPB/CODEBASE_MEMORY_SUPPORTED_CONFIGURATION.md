# Codebase Memory Supported Configuration

## 1. Officially Supported Operations

Based on the `codebase-memory` MCP tool surface and schemas:

| Tool | Purpose | Configurable Storage? |
|---|---|---|
| `index_repository` | Index a repository into the knowledge graph | No |
| `search_graph` | BM25 / regex / semantic search over the graph | No |
| `query_graph` | Cypher queries against the graph | No |
| `trace_path` | Call / data-flow / cross-service traces | No |
| `get_code_snippet` | Read source for a symbol | No |
| `list_projects` | List indexed projects and roots | No |

## 2. `index_repository` Parameters (Official)

```json
{
  "repo_path": "string (required)",
  "mode": "full | moderate | fast | cross-repo-intelligence",
  "name": "string (project name override)",
  "persistence": "boolean",
  "target_projects": ["string"]
}
```

- `repo_path` is the only filesystem path accepted.
- `persistence` writes `graph.db.zst` to `<repo_path>/.codebase-memory/graph.db.zst`.

## 3. Unsupported Configuration Parameters

The following parameters are **not** present in any official tool schema:

- `workspace_path`
- `storage_path`
- `cache_path`
- `graph_db_path`
- `memory_directory`
- `output_directory`

## 4. Workspace Relocation Support Status

| Capability | Status |
|---|---|
| Index to an external directory | Unsupported |
| Configure graph storage location | Unsupported |
| Configure cache/artifact location | Unsupported |
| Move an existing project root | Unsupported |
| Symlink or mount configuration | Not exposed in MCP |

## 5. Safest Officially Supported Alternative

Until the MCP exposes a storage-location setting:

1. Continue using the workspace at `C:\PROJECT\vietsalepro\.codebase-memory`.
2. Do not run `index_repository` with `persistence: true` unless the resulting `.codebase-memory/graph.db.zst` is intended to be shared or tracked.
3. In a separate, scoped git-maintenance task, consider:
   - Adding `.codebase-memory/` to `.gitignore`.
   - Running `git rm --cached` on tracked `.codebase-memory` files if they should not be versioned.

This keeps Codebase Memory operational while preventing git contamination, without relying on an unsupported relocation mechanism.
