# Wave-01 Commit Scope Definition

**Project:** VietSalePro  
**Program:** Deletion & Audit Architecture Remediation Program  
**Wave:** Wave-01  
**Date:** 2026-07-23

---

## 1. Authorized Commit

Per `WAVE-01_PRODUCTION_OWNER_DECISION_RECORD.md` §5 and `WAVE-01_CLOSEOUT_IMPLEMENTATION_AUTHORIZATION.md` §2, the Wave-01 closeout commit is authorized as an isolated commit.

---

## 2. Included Scope

- **Path:** `ADMIN_DASHBOARD_PLAN_FIX_SPB/`
- **Files:** 73 governance artifacts (plans, specifications, reports, evidence, authorizations, audits, checklists, matrices, registers)
- **Git command to stage:** `git add ADMIN_DASHBOARD_PLAN_FIX_SPB/`
- **Commit message suggestion:** `docs(wave-01): closeout governance artifacts`

---

## 3. Excluded Scope

The following are explicitly excluded from the Wave-01 commit per `WAVE-01_PRODUCTION_OWNER_DECISION_RECORD.md` §4 O-03 and §5:

| Path | Reason |
|---|---|
| `.codebase-memory/artifact.json` | Pre-existing modification, excluded |
| `.codebase-memory/graph.db.zst` | Pre-existing modification, excluded |
| `.codebase-memory/CODEBASE_MEMORY_BASELINE.md` | Untracked codebase memory, excluded |
| `.codebase-memory/SEMANTIC_MEMORY.md` | Untracked codebase memory, excluded |
| `.codebase-memory/VALIDATION_REPORT.md` | Untracked codebase memory, excluded |
| `.codebase-memory/update-codebase-memory.txt` | Untracked codebase memory, excluded |
| `package.json` | Pre-existing modification, excluded |
| `package-lock.json` | Pre-existing modification, excluded |

---

## 4. Prohibited Scope

The following are NOT included and no action is authorized:

- Source code files (`src/`, `components/`, `pages/`, `hooks/`, `services/`, `utils/`, `types/`)
- Supabase migrations, schema, RPCs, Edge Functions
- Tests
- Vercel deployment configuration
- CI/CD files
- Any business logic or API changes

---

## 5. Verification

| Check | Result |
|---|---|
| `git status --porcelain` matches commit scope | Yes |
| Only `ADMIN_DASHBOARD_PLAN_FIX_SPB/` is intended to be committed | Yes |
| Excluded files are not staged | To be verified at commit time |
| No source changes staged | Yes |

---

## 6. Execution Note

The commit is NOT performed in this program. This definition is prepared for execution under a separate, explicit Production Owner authorization.
