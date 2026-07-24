# Wave-01 Codebase Memory Update Plan

**Project:** VietSalePro  
**Program:** Deletion & Audit Architecture Remediation Program  
**Wave:** Wave-01  
**Date:** 2026-07-23

---

## 1. Gap to Address

`VALIDATION_REPORT.md` §7 / gap L8 documents that the `ADMIN_DASHBOARD_PLAN_FIX_SPB/` directory (73 governance artifacts) is not indexed in the Codebase Memory graph. After the Wave-01 closeout commit, the memory should reflect this major governance documentation directory.

---

## 2. Trigger

Execute this plan only after:

1. `ADMIN_DASHBOARD_PLAN_FIX_SPB/` is committed to the repository (per `WAVE-01_COMMIT_SCOPE_DEFINITION.md`).
2. The Production Owner explicitly requests a Codebase Memory update.

---

## 3. Update Options

### Option A — Incremental Section Update (Recommended)

1. Append a new section to `.codebase-memory/SEMANTIC_MEMORY.md` describing `ADMIN_DASHBOARD_PLAN_FIX_SPB/`:
   - Directory purpose
   - Artifact count (73)
   - Major artifact categories (governance, specifications, plans, reports, evidence)
   - Cross-references to Wave-01 decision and closeout documents
2. Update `VALIDATION_REPORT.md` §7 to close gap L8.
3. Update `CODEBASE_MEMORY_BASELINE.md` with a dated change note.
4. No full re-index required.

### Option B — Full Re-index

1. Run `index_repository` on `C:/PROJECT/vietsalepro` in `full` mode with `persistence: true`.
2. Re-run validation (PHASE_02 equivalent).
3. Produce a new baseline document superseding the current one.
4. Use only if a major architecture or repository restructuring accompanies the commit.

---

## 4. Recommended Choice

**Option A** unless Wave-02 introduces structural repository changes. Option A preserves the validated baseline and adds only the missing governance documentation context.

---

## 5. Verification Steps

- Confirm `ADMIN_DASHBOARD_PLAN_FIX_SPB/` appears in the Semantic Memory directory inventory.
- Confirm `VALIDATION_REPORT.md` gap L8 is marked resolved.
- Confirm no source code, schema, RPC, Edge Function, or deployment artifact was modified during the memory update.

---

## 6. Constraints

- No rebuild now.
- This plan is prepared; execution requires separate Production Owner authorization.
