# CURRENT_TASK-003 IMPLEMENTATION

**Task ID:** CURRENT_TASK-003  
**Title:** Release Preparation - Non-Production Migration Validation and CLI Gates  
**Program:** VietSalePro v7 — Production Deployment Program  
**Phase:** Phase 2 — Release Preparation  
**Date:** 2026-07-19  
**Executor:** Engineering Implementation Authority  
**Authority:** [CURRENT_TASK-003_PROGRAM_AUTHORIZATION.md](CURRENT_TASK-003_PROGRAM_AUTHORIZATION.md)

---

## 1. Scope Statement

This artifact records implementation-only work for CURRENT_TASK-003. It does not constitute verification, acceptance, production migration, deployment, release tagging, or SQL body modification. All work was performed against the local/development tooling or the Supabase CLI shadow database; no production database was accessed or changed.

---

## 2. Pre-Implementation Checks

| Check | Command | Result |
|---|---|---|
| Working tree | `git status --short` | Clean (no output) |
| Branch / upstream | `git status -sb` | `## master...origin/master` |
| Current commit | `git log -1 --oneline` | `2701717b docs: authorize task 003 release preparation` |

**Confirmation:**

- Working tree is clean.
- Branch is `master`.
- `HEAD` and `origin/master` are synchronized at `2701717b`.

---

## 3. Migration Review

### 3.1 `supabase/migrations/20260718000001_sp_7_1_set_tenant_subdomain.sql`

| Item | Finding |
|---|---|
| File exists | Yes |
| Purpose | Adds/replaces the `public.set_tenant_subdomain` RPC that lets a system admin update a tenant's normalized subdomain. |
| Objects / functions affected | `public.set_tenant_subdomain`, `public.tenants`, `public.audit_log` |
| Dependencies | `public.is_system_admin()`, `public.tenants`, `public.audit_log`, `auth.uid()` |
| Production-only secret/config required | No |
| SQL body modified | No |

### 3.2 `supabase/migrations/20260723000001_g1_add_max_storage_gb_to_tenant_subscriptions.sql`

| Item | Finding |
|---|---|
| File exists | Yes |
| Purpose | Adds `max_storage_gb` to `public.tenant_subscriptions` and evolves `public.update_tenant_subscription` to accept the new parameter. |
| Objects / tables / functions affected | `public.tenant_subscriptions.max_storage_gb` column, `public.update_tenant_subscription`, `public.tenants` |
| Dependencies | `public.is_system_admin()`, `public.is_valid_plan()`, `public.get_default_plan_limit_values()`, `public.tenant_subscriptions`, `public.tenants` |
| Production-only secret/config required | No |
| SQL body modified | No |

### 3.3 Common Dependency / Risk Notes

- Both migrations reference existing `public` objects and helper functions; they do not introduce circular dependencies or external secrets.
- Both use `SECURITY DEFINER` / `SECURITY INVOKER` with privilege checks; no new roles or secrets are embedded.
- The second migration drops the prior 7-parameter overload of `public.update_tenant_subscription` and replaces it with an 8-parameter version that defaults `p_max_storage_gb` to `NULL`. Downstream callers using named parameters or positional parameters up to the first 7 positions remain compatible.

---

## 4. CLI Gate Execution

| # | Command | Result | Output Summary | Pass / Fail / Blocked | Observation |
|---|---|---|---|---|---|
| C1 | `npx supabase --version` | Completed | `2.109.1` | Pass | — |
| C2 | `npx supabase migration list --local` | Failed at connect | `failed to connect to postgres: effect/sql/SqlError: PgClient: Failed to connect` | Blocked | M1 |
| C3 | `npx supabase db lint` | Failed at connect | Same PgClient connection error | Blocked | M1 |
| C4 | `npx supabase db diff --local` | Replay passed, final diff connection failed | 138 canonical migrations applied through `20260723000001_g1_add_max_storage_gb_to_tenant_subscriptions.sql`; final `Diffing schemas...` step failed with `connect ECONNREFUSED 127.0.0.1:54322` | Pass (replay) / Blocked (diff connection) | M1 |

### 4.1 `npx supabase migration list --local`

- **Command:** `npx supabase migration list --local`
- **Result:** BLOCKED
- **Output Summary:** CLI could not connect to the local Postgres instance.
- **Pass/Fail/Blocked:** Blocked (environment)
- **Observation ID:** M1

### 4.2 `npx supabase db lint`

- **Command:** `npx supabase db lint`
- **Result:** BLOCKED
- **Output Summary:** Same `PgClient: Failed to connect` error.
- **Pass/Fail/Blocked:** Blocked (environment)
- **Observation ID:** M1

### 4.3 `npx supabase db diff --local`

- **Command:** `npx supabase db diff --local`
- **Replay result:** All 138 canonical migrations, including the two target migrations, applied without migration-ordering or SQL execution errors.
- **Final diff result:** BLOCKED by `connect ECONNREFUSED 127.0.0.1:54322` during the final schema-diff connection.
- **Pass/Fail/Blocked:** Replay pass; final diff blocked (environment)
- **Observation ID:** M1

---

## 5. Non-Production Validation

| Item | Detail |
|---|---|
| Environment used | Local shadow database created by `npx supabase db diff --local` |
| Migrations applied / replayed | Yes — the entire canonical migration chain, including `20260718000001_sp_7_1_set_tenant_subdomain.sql` and `20260723000001_g1_add_max_storage_gb_to_tenant_subscriptions.sql` |
| Migration-ordering error observed | No |
| Critical / High SQL issue observed | No |
| Evidence summary | CLI output shows `Applying migration 20260718000001_sp_7_1_set_tenant_subdomain.sql...` and `Applying migration 20260723000001_g1_add_max_storage_gb_to_tenant_subscriptions.sql...` completed immediately before `Diffing schemas...`. No errors were emitted for either target migration. |
| Blocker | M1 — local Postgres connectivity prevented `migration list --local`, `db lint`, and the final `db diff` comparison from completing. This is environmental, not a migration defect. |

### 5.1 `M1` — Local Supabase / Postgres Connectivity

- **Status:** Remains open.
- **Evidence:** `migration list --local` and `db lint` failed with `failed to connect to postgres: effect/sql/SqlError: PgClient: Failed to connect`; `db diff --local` replayed all migrations in the shadow database but could not finish the final diff because of `connect ECONNREFUSED 127.0.0.1:54322`.
- **Disposition:** Re-run once the local Supabase/Postgres stack is available; does not indicate a repository or migration defect.

### 5.2 `M2` — 2 Repository-Only Migrations Not Yet Validated

- **Status:** Resolved by shadow replay.
- **Evidence:** `npx supabase db diff --local` successfully applied both `20260718000001_sp_7_1_set_tenant_subdomain.sql` and `20260723000001_g1_add_max_storage_gb_to_tenant_subscriptions.sql` in order without errors. The full canonical chain of 138 migrations completed through the final target migration.
- **Caveat:** Final schema diff output could not be produced because the CLI could not connect to `127.0.0.1:54322` after replay.

---

## 6. Findings

### Critical

None.

### High

None.

### Medium

- **M1 — Local Supabase/Postgres connectivity blocked CLI gates and the final `db diff` comparison.** This is an environmental blocker, not a migration defect. It prevents full completion of `npx supabase migration list --local` and `npx supabase db lint` and prevents capture of the final `db diff` output.

### Low

None.

### Observations

- **O1 — M2 resolved via shadow replay.** Both target migrations were replayed in the `npx supabase db diff --local` shadow database with no migration-ordering or SQL errors.
- **O2 — `db diff --local` replay succeeded before the final connection failure.** The replay and diff steps are separate: the replay phase is authoritative for migration-ordering validation; the final `ECONNREFUSED` is a post-replay connectivity issue.
- **O3 — No SQL body was modified.** Both migration files were reviewed and executed as committed; no changes were made to migration SQL bodies.
- **O4 — No production resources were touched.** All commands were run with `--local` or against the local shadow database only.

---

## 7. Implementation Decision

```text
CURRENT_TASK-003 IMPLEMENTATION:

PARTIALLY COMPLETED WITH OBSERVATIONS
```

**Rationale:** The two repository-only migrations were successfully replayed in the local shadow database, resolving M2. However, the local Supabase/Postgres CLI gates (`migration list --local`, `db lint`) and the final `db diff` connection remain blocked by the same local connectivity issue (M1). No Critical or High findings were introduced, and no production deployment or SQL modification occurred.

---

## 8. Next Authorized Step

```text
CURRENT_TASK-003_VERIFICATION.md
```

The verification authority should review this implementation artifact and the evidence recorded above. If the local environment becomes available, the verification step should re-run `npx supabase migration list --local` and `npx supabase db lint` to close M1.
