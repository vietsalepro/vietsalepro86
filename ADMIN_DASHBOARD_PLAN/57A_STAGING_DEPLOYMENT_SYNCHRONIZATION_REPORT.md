# 57A_STAGING_DEPLOYMENT_SYNCHRONIZATION_REPORT

**Document ID:** 57A_STAGING_DEPLOYMENT_SYNCHRONIZATION_REPORT  
**Date:** 2026-07-22  
**Program:** Admin Dashboard System Remediation Program  
**Sub Project:** Admin Dashboard  
**Phase:** B — System Remediation  
**Wave:** Wave-04  
**Acting Capacity:** Enterprise Program Management Office (PMO)  
**Authorized Commit:** `ce87b9d7` (`fix(services,config): Wave-04 residual hardening — canonical read RPCs and check-subdomain verify_jwt`)

------------------------------------------------------------------------

## 1. Documents Reviewed

The following mandatory governance documents were read completely before execution:

- `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md`
- `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md`
- `52_ADMIN_DASHBOARD_WAVE-04_VERIFICATION.md`
- `53_ADMIN_DASHBOARD_WAVE-04_ACCEPTANCE_REVIEW.md`
- `54_PRE_WAVE04_DEPLOYMENT_SYNCHRONIZATION_ROADMAP_UPDATE.md`
- `54A_GOVERNANCE_DOCUMENT_CONSISTENCY_UPDATE.md`
- `54B_MASTER_PLAN_SYNCHRONIZATION_REPORT.md`
- `55_ADMIN_DASHBOARD_WAVE-04_DEPLOYMENT_SYNCHRONIZATION_AUTHORIZATION.md`
- `55A_DEPLOYMENT_SYNCHRONIZATION_AUTHORIZATION_REPORT.md`
- `56_ADMIN_DASHBOARD_WAVE-04_PRE_DEPLOYMENT_READINESS_REVIEW.md`
- `56A_PRE_DEPLOYMENT_READINESS_REVIEW_REPORT.md`

------------------------------------------------------------------------

## 2. Codebase Memory MCP Verification

- **MCP server:** `codebase-memory`
- **Action:** `index_repository` (fast mode) on `C:\PROJECT\vietsalepro`
- **Result:** `indexed` — 28,534 nodes, 42,210 edges, 0 skipped
- **Drift findings:**
  - No source-code drift relative to the accepted commit `ce87b9d7`.
  - The only tracked changes between `ce87b9d7` and `HEAD` (`a12ed302`) are governance documents in `ADMIN_DASHBOARD_PLAN`.
  - Canonical read RPCs `get_tenant_subscription` and `get_user_accounts` are present in the migration chain and are called from the service layer.

------------------------------------------------------------------------

## 3. Git Verification

| Check | Value | Status |
|---|---|---|
| Current branch | `master` | OK |
| `git rev-parse HEAD` | `a12ed302` | OK (governance-only commits after `ce87b9d7`) |
| Diff `ce87b9d7..HEAD` | Only `ADMIN_DASHBOARD_PLAN/*.md` | OK — no source drift |
| Working tree | Governance docs and `.codebase-memory` artifacts modified | Expected |
| Source-code cleanliness | Reset to `ce87b9d7` for Vercel build, then restored to `master` | OK |

The Vercel staging deployment was produced from a clean `ce87b9d7` checkout to ensure the deployment metadata matches the authorized commit.

------------------------------------------------------------------------

## 4. Installed Skills Utilized

No installed skill provided a deployment-orchestration capability that was not already covered by the Supabase and Vercel MCP servers and the authenticated Vercel CLI. The following were considered and not needed:

- `vercel-react-best-practices` — build already aligned with `vite build`.
- `requesting-code-review` — no code changes were introduced.
- `tdd` / `test-driven-development` — no new test-first implementation was requested.

------------------------------------------------------------------------

## 5. Supabase MCP Verification

- **MCP server:** `supabase-mcp-server`
- **List organizations:** accessible.
- **List projects:** found two projects:
  - `rsialbfjswnrkzcxarnj` (QLBH)
  - `shbmzvfcenbybvyzclem` (QLBH Staging Multi-Tenant)
- **Staging target (from `.env.staging`):** `shbmzvfcenbybvyzclem` (`VITE_SUPABASE_URL=https://shbmzvfcenbybvyzclem.supabase.co`)
- **Staging project status:** `ACTIVE_HEALTHY`
- **Migration state before apply:** `20260801000000_wave04_canonical_read_rpcs.sql` not present

------------------------------------------------------------------------

## 6. Vercel MCP Verification

- **MCP server:** `vercel`
- **List teams:** found `team_5jIBUrVn2CmOrkSojeJZZqoP`
- **List projects:** found `prj_UdCbqGpXxsBXVNGfz0fz02obBS6x` (`vietsalepro`, framework `vite`)
- **Latest production deployment:** `dpl_8rhXQm3qLawzjUSyBNpB2fN33eM5` (untouched)
- **Vercel CLI authentication:** `tanphat056-3795` confirmed

------------------------------------------------------------------------

## 7. Repository Deployment

- **Deployed commit:** `ce87b9d7`
- **Deployment method for Vercel:** authenticated `vercel` CLI from a clean `ce87b9d7` checkout, target `preview`
- **Source drift:** none in application code
- **First preview attempt** (`dpl_6hevmtybijarxjGGcDVQ7fRe1g5B`) was from the `master` working tree and showed `gitDirty=1`; it was superseded by a clean `ce87b9d7` deployment.

------------------------------------------------------------------------

## 8. Migration Deployment

- **Migration file:** `supabase/migrations/20260801000000_wave04_canonical_read_rpcs.sql`
- **Target project:** `shbmzvfcenbybvyzclem`
- **MCP tool:** `apply_migration`
- **Result:** success
- **Functions created/updated:**
  - `public.get_tenant_subscription(p_tenant_id UUID)` — `STABLE`, `SECURITY DEFINER`, `SET search_path = public`
  - `public.get_user_accounts(p_user_id UUID)` — `STABLE`, `SECURITY DEFINER`, `SET search_path = public`

------------------------------------------------------------------------

## 9. RPC Deployment Verification

SQL verification against the staging database confirmed:

- Both `get_tenant_subscription` and `get_user_accounts` exist in `pg_proc`.
- `EXECUTE` privilege is granted to `authenticated` and `service_role` for both functions.

```
SELECT proname FROM pg_proc WHERE proname IN ('get_tenant_subscription','get_user_accounts');
-- returns both names

SELECT grantee, privilege_type, routine_name
FROM information_schema.routine_privileges
WHERE routine_name IN ('get_tenant_subscription','get_user_accounts')
  AND privilege_type = 'EXECUTE';
-- grantees include authenticated and service_role
```

------------------------------------------------------------------------

## 10. Edge Function Deployment

- **Function:** `check-subdomain`
- **MCP tool:** `deploy_edge_function`
- **Target project:** `shbmzvfcenbybvyzclem`
- **Deployment result:**
  - `id`: `64f187ce-59b9-4bfb-8f60-10d08ce3443e`
  - `version`: `9`
  - `status`: `ACTIVE`
  - `verify_jwt`: `false`
- **Config.toml setting:** `[functions.check-subdomain] verify_jwt = false`

------------------------------------------------------------------------

## 11. Environment Verification

| File | Check | Status |
|---|---|---|
| `.env.staging` | Present; references staging Supabase project | OK |
| `supabase/config.toml` | `project_id` set; `check-subdomain` `verify_jwt = false` | OK |
| `vercel.json` | Rewrites SPA routes to `index.html` | OK |
| `package.json` | Build script `vite build`, lint `tsc --noEmit` | OK |

No secret values are disclosed in this report.

------------------------------------------------------------------------

## 12. Runtime Smoke Validation

| # | Check | Evidence | Result |
|---|---|---|---|
| 1 | TypeScript lint | `npm run lint` (`tsc --noEmit`) | PASS |
| 2 | Production build | `npm run build` (`vite build`) | PASS |
| 3 | RPC contract audit | `npm run audit:rpc` | PASS — all service-layer RPC calls are defined in the canonical migration chain |
| 4 | `check-subdomain` unauthenticated request | `https://shbmzvfcenbybvyzclem.supabase.co/functions/v1/check-subdomain?subdomain=testdeploy` | PASS — returned `{"available":true}` |
| 5 | Vercel preview deployment | `https://vietsalepro-8vzldgvj8-tanphat056-3795s-projects.vercel.app` | PASS — `READY` state, commit `ce87b9d7...` |

------------------------------------------------------------------------

## 13. Deployment Evidence

| Artifact | Identifier / URL |
|---|---|
| Authorized commit | `ce87b9d7` (`ce87b9d787401a3591aa3242257a3173f3cd9174`) |
| Supabase staging project | `shbmzvfcenbybvyzclem` (QLBH Staging Multi-Tenant) |
| Applied migration | `20260801000000_wave04_canonical_read_rpcs` |
| Edge Function | `check-subdomain` v9, `verify_jwt = false` |
| Vercel staging preview | `https://vietsalepro-8vzldgvj8-tanphat056-3795s-projects.vercel.app` |
| Vercel deployment ID | `dpl_GXrhNbCnqAkZXaZyALmkVb78HUSV` |
| Vercel inspect URL | `https://vercel.com/tanphat056-3795s-projects/vietsalepro/GXrhNbCnqAkZXaZyALmkVb78HUSV` |

------------------------------------------------------------------------

## 14. Rollback Readiness

| Artifact | Rollback Action |
|---|---|
| Database | Re-create previous function definitions or restore from a pre-deployment backup if required. |
| Edge Function | Redeploy the previous `check-subdomain` bundle or toggle `verify_jwt` and redeploy. |
| Vercel preview | The production deployment `dpl_8rhXQm3qLawzjUSyBNpB2fN33eM5` remains live and unaffected. The preview deployment can be discarded. |
| Configuration | Revert any changed environment variables to pre-deployment values. |

No rollback was required during Stage 1 execution.

------------------------------------------------------------------------

## 15. Roadmap Updates

Updated documents:

- `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md`
  - `Wave-04 Staging Deployment Synchronization` → `COMPLETE (57)`
  - `Wave-04 Staging Deployment Validation` → `READY TO START`
  - `Overall Completion` and `Program Status` updated to reflect staging validation readiness.
- `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md`
  - Document status header updated.
  - Roadmap table updated with `COMPLETE (57)` and `READY TO START` states.
  - Final decision and next governance action updated.

------------------------------------------------------------------------

## 16. Program Status Updates

| Milestone | New Status |
|---|---|
| Wave-04 Staging Deployment Synchronization | **COMPLETE (57)** |
| Wave-04 Staging Deployment Validation | **READY TO START** |
| Wave-04 Production Deployment Synchronization | **NOT AUTHORIZED** |
| Wave-04 Closeout | **BLOCKED BY DEPLOYMENT SYNCHRONIZATION** |
| Overall Program Status | **READY FOR WAVE-04 STAGING DEPLOYMENT VALIDATION** |

------------------------------------------------------------------------

## 17. Final Deployment Decision

**GO — STAGING ONLY**

All Stage 1 deployment artifacts were synchronized to the staging environment. The authorized commit `ce87b9d7` was used for the Vercel preview deployment. The Wave-04 canonical read RPCs and the `check-subdomain` Edge Function were deployed and verified in the staging Supabase project. No production deployment occurred.

**Stop Rule:** Stage 1 is complete. Do not begin Wave-04 Staging Deployment Validation, Wave-04 Production Deployment Synchronization, or Wave-04 Closeout without explicit Program Owner approval.
