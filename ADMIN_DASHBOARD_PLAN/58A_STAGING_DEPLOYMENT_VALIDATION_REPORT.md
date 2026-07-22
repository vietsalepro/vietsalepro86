# 58A_STAGING_DEPLOYMENT_VALIDATION_REPORT

**Document ID:** 58A_STAGING_DEPLOYMENT_VALIDATION_REPORT
**Date:** 2026-07-22
**Project:** VietSalePro
**Sub Project:** Admin Dashboard
**Program:** Admin Dashboard System Remediation Program
**Phase:** B — System Remediation
**Wave:** Wave-04
**Acting Capacity:** Enterprise Program Management Office (PMO) together with the Principal Software Architect
**Baseline:** AD-Baseline-1.0
**Repository Scope:** `C:\PROJECT\vietsalepro` @ `ce87b9d7`
**Authorized Commit:** `ce87b9d7` (`fix(services,config): Wave-04 residual hardening — canonical read RPCs and check-subdomain verify_jwt`)
**Status:** STAGING DEPLOYMENT VALIDATION COMPLETE — **GO WITH OBSERVATIONS**

------------------------------------------------------------------------

## 1. Documents Reviewed

The following mandatory governance documents were read completely before validation. No section was skipped.

| # | Document | Role in Validation | Read Status |
|---|---|---|---|
| 00 | `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` | Program charter, lifecycle, transition rules, current status | Read in full |
| 12 | `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md` | Master Plan status, quality gates, roadmap, final decision | Read in full |
| 52 | `52_ADMIN_DASHBOARD_WAVE-04_VERIFICATION.md` | Wave-04 verification and deployment observations | Read in full |
| 53 | `53_ADMIN_DASHBOARD_WAVE-04_ACCEPTANCE_REVIEW.md` | Wave-04 acceptance decision and deployment observations | Read in full |
| 54 | `54_PRE_WAVE04_DEPLOYMENT_SYNCHRONIZATION_ROADMAP_UPDATE.md` | Deployment Synchronization gate definition and roadmap | Read in full |
| 54A | `54A_GOVERNANCE_DOCUMENT_CONSISTENCY_UPDATE.md` | Governance consistency verification | Read in full |
| 54B | `54B_MASTER_PLAN_SYNCHRONIZATION_REPORT.md` | Master Plan synchronization evidence | Read in full |
| 55 | `55_ADMIN_DASHBOARD_WAVE-04_DEPLOYMENT_SYNCHRONIZATION_AUTHORIZATION.md` | Authorized deployment scope, strategy, rollback, risks | Read in full |
| 55A | `55A_DEPLOYMENT_SYNCHRONIZATION_AUTHORIZATION_REPORT.md` | Detailed authorization evidence | Read in full |
| 56 | `56_ADMIN_DASHBOARD_WAVE-04_PRE_DEPLOYMENT_READINESS_REVIEW.md` | Pre-deployment readiness evidence and GO decision | Read in full |
| 56A | `56A_PRE_DEPLOYMENT_READINESS_REVIEW_REPORT.md` | Detailed readiness evidence | Read in full |
| 57 | `57_ADMIN_DASHBOARD_WAVE-04_STAGING_DEPLOYMENT_SYNCHRONIZATION.md` | Stage 1 authorization and GO decision | Read in full |
| 57A | `57A_STAGING_DEPLOYMENT_SYNCHRONIZATION_REPORT.md` | Stage 1 deployment evidence and traceability | Read in full |

All cross-references were verified against the documents themselves.

------------------------------------------------------------------------

## 2. Codebase Memory MCP Verification

**Tool:** `codebase-memory` MCP server
**Action:** `index_repository` (fast mode) on `C:\PROJECT\vietsalepro`
**Result:** `indexed` — 28,563 nodes, 42,237 edges, 0 skipped

| Verification Check | Method | Result |
|---|---|---|
| Project | `index_repository` result | `C-PROJECT-vietsalepro` |
| Indexed nodes | `index_repository` result | 28,563 |
| Indexed edges | `index_repository` result | 42,237 |
| Source drift `ce87b9d7..HEAD` | `query_graph` / `git diff` | None outside `ADMIN_DASHBOARD_PLAN` and `.codebase-memory` |
| `getTenantSubscription` caller | `search_graph` | `services.tenantService.getTenantSubscription` at `services/tenantService.ts:455-463` |
| `getUserAccounts` caller | `search_graph` | `services.admin.tenantAdminService.getUserAccounts` at `services/admin/tenantAdminService.ts:78-96` |
| Billing re-export | `search_graph` | `services.admin.billingAdminService.getTenantSubscription` delegates to `services.tenantService.getTenantSubscription` |
| Canonical RPC call sites | `search_graph` / `read` | `supabase.rpc('get_tenant_subscription')` and `supabase.rpc('get_user_accounts')` are present |

**Codebase Memory Verdict:** The repository graph is fresh and the canonical RPC call sites are present in the accepted source. No application-source drift detected.

------------------------------------------------------------------------

## 3. Git Repository Verification

| Check | Method | Result |
|---|---|---|
| HEAD commit | `git rev-parse HEAD` | `a12ed302` — governance-only consistency update after `57` |
| Accepted source commit | `55` / `57` / `git rev-parse ce87b9d7` | `ce87b9d7` present and reachable |
| Current branch | `git branch --show-current` | `master` |
| Sealed baseline commit | `git rev-parse 3a06a6d9` | `3a06a6d9` present and reachable |
| Source changes `ce87b9d7..HEAD` | `git diff --stat ce87b9d7..HEAD -- . ':!ADMIN_DASHBOARD_PLAN' ':!.codebase-memory'` | 0 lines — no source drift |
| Working-tree source changes | `git diff HEAD -- . ':!ADMIN_DASHBOARD_PLAN' ':!.codebase-memory'` | 0 lines |
| Working-tree modifications | `git status --short` | `.codebase-memory/*` (MCP re-index), `ADMIN_DASHBOARD_PLAN/*.md` governance deliverables |

**Git Verdict:** The accepted Wave-04 source revision `ce87b9d7` remains frozen. The only changes are governance documentation and MCP infrastructure artifacts.

------------------------------------------------------------------------

## 4. Installed Skills Utilized

| Skill | Applicability | Execution |
|---|---|---|
| `webapp-testing` | Runtime validation and Playwright-based web checks | Invoked; Playwright runtime not installed in this environment, so not used for the live preview |
| `agent-browser` | Browser automation, console/network checks | Invoked; `agent-browser` CLI not installed in this environment, so not used |
| `code-review` | Not applicable — no code changes to review | Not invoked |
| `requesting-code-review` | Not applicable — not a pre-commit review | Not invoked |
| `doc-coauthoring` | Not applicable — governed program report | Not invoked |
| `internal-comms` | Not applicable — no internal communication artifact requested | Not invoked |

**Skills Verdict:** The two skills that could have improved runtime verification were invoked but are not executable in this environment. Runtime validation was therefore performed with the Vercel/Supabase MCP servers and direct HTTP probes. No other installed skill improved this validation gate.

------------------------------------------------------------------------

## 5. Supabase MCP Validation

**MCP server:** `supabase-mcp-server`  
**Target project:** `shbmzvfcenbybvyzclem` (QLBH Staging Multi-Tenant)

| Check | Method | Result |
|---|---|---|
| Project health | `get_project` | `ACTIVE_HEALTHY`, Postgres `17.6.1.141`, region `ap-northeast-1` |
| Migration presence | `list_migrations` | `20260801000000_wave04_canonical_read_rpcs` present |
| RPC existence | `execute_sql` `pg_proc` | `get_tenant_subscription` and `get_user_accounts` exist, return `json`, `STABLE`, `SECURITY DEFINER`, `SET search_path TO 'public'` |
| RPC search_path | `execute_sql` `proconfig` / `pg_get_functiondef` | Both functions have `search_path=public` and `SET search_path TO 'public'` |
| RPC permissions | `execute_sql` `information_schema.routine_privileges` | `EXECUTE` granted to `authenticated` and `service_role` for both |
| `get_tenant_subscription` execution | `execute_sql` call with nil UUID | Function executed; correctly raised `insufficient_privilege` (`Không có quyền xem subscription của tenant này`) |
| `get_user_accounts` execution | `execute_sql` call with nil UUID | Function executed; correctly raised `insufficient_privilege` (`Không có quyền xem tài khoản người dùng khác`) |
| Edge Function list | `list_edge_functions` | `check-subdomain` is `ACTIVE`, version `9`, `verify_jwt = false` |
| Edge Function invocation logs | `get_logs` (`edge-function`) | `GET /check-subdomain?subdomain=testdeploy` returned `200` in 3023 ms |
| API request logs | `get_logs` (`api`) | Edge Function made successful `GET`/`POST` to `tenants`, `rate_limit_logs`, `app_audit_log` — no errors |
| Security advisors | `get_advisors` (`security`) | Returned many pre-existing `function_search_path_mutable` WARN-level lints; Wave-04 RPCs verified independently to have `SET search_path` configured |

**Supabase Verdict:** The staging database contains the Wave-04 migration, the two canonical read RPCs are correctly defined and permissioned, and the `check-subdomain` Edge Function is deployed with `verify_jwt = false` as authorized. No Supabase-side Wave-04 defects found.

------------------------------------------------------------------------

## 6. Vercel MCP Validation

**MCP server:** `vercel`  
**Team:** `team_5jIBUrVn2CmOrkSojeJZZqoP`  
**Project:** `prj_UdCbqGpXxsBXVNGfz0fz02obBS6x` (`vietsalepro`, `vite`)

| Check | Method | Result |
|---|---|---|
| Deployment state | `get_deployment` `dpl_GXrhNbCnqAkZXaZyALmkVb78HUSV` | `READY` |
| Deployment URL | `get_deployment` | `vietsalepro-8vzldgvj8-tanphat056-3795s-projects.vercel.app` |
| Commit hash | `get_deployment` `meta.githubCommitSha` | `ce87b9d787401a3591aa3242257a3173f3cd9174` = `ce87b9d7` |
| Commit message | `get_deployment` `meta.githubCommitMessage` | `fix(services,config): Wave-04 residual hardening — canonical read RPCs and check-subdomain verify_jwt` |
| Source | `get_deployment` | `cli` (authorized clean checkout) |
| Build logs | `get_deployment_build_logs` | `vite build` PASS — 3369 modules transformed, no errors |
| Runtime logs | `get_runtime_logs` (1h) | No logs found (no recent traffic) |
| HTTP root | `curl` | `200` |
| HTTP `/admin` | `curl` | `200` |

**Vercel Verdict:** The Vercel preview deployment is at the authorized commit, built cleanly, and serves both the root and `/admin` paths. No Vercel-side Wave-04 defects found.

------------------------------------------------------------------------

## 7. Deployment Integrity Validation

| Element | Authorized Value | Deployed Value | Status |
|---|---|---|---|
| Authorized commit | `ce87b9d7` | `ce87b9d7` (Vercel `githubCommitSha`) | OK |
| Migration version | `20260801000000_wave04_canonical_read_rpcs` | Present in `list_migrations` | OK |
| RPC signatures | `get_tenant_subscription(uuid)` and `get_user_accounts(uuid)`, `STABLE`, `SECURITY DEFINER`, `SET search_path = public` | Confirmed via `pg_get_functiondef` | OK |
| RPC permissions | `EXECUTE` for `authenticated` and `service_role` | Confirmed via `information_schema.routine_privileges` | OK |
| Edge Function version | `check-subdomain` with `verify_jwt = false` | Version `9`, `verify_jwt = false`, `ACTIVE` | OK |
| Environment configuration | `.env.staging`, `supabase/config.toml`, `vercel.json` | No source drift; values match authorized revision | OK |
| Vercel preview deployment | Build from `ce87b9d7` | `dpl_GXrhNbCnqAkZXaZyALmkVb78HUSV` `READY` | OK |
| Deployment metadata | Commit, migration, Edge Function, Vercel deployment traceable to `ce87b9d7` | All identifiers captured | OK |

**Deployment Integrity Verdict:** Deployment integrity has been preserved. The deployed staging environment matches the authorized commit `ce87b9d7`.

------------------------------------------------------------------------

## 8. Functional Validation

| Function | Expected Behavior | Validation Evidence | Status |
|---|---|---|---|
| Tenant subscription retrieval | `getTenantSubscription` calls `supabase.rpc('get_tenant_subscription')` | Codebase Memory confirms call site; SQL function exists and executes | OK |
| User account retrieval | `getUserAccounts` calls `supabase.rpc('get_user_accounts')` | Codebase Memory confirms call site; SQL function exists and executes | OK |
| Canonical RPC execution | Functions return `json` and enforce auth | `pg_get_functiondef` and direct invocation confirm execution and authorization checks | OK |
| `check-subdomain` | Unauthenticated `GET` returns availability | HTTP `200`, body `{"available":true}` | OK |
| Admin Dashboard loading | Vercel `/admin` path serves `index.html` | HTTP `200` on `/admin` | OK |

**Functional Verdict:** The Wave-04 functional changes are operational in the staging environment.

------------------------------------------------------------------------

## 9. Runtime Validation

| Check | Evidence | Result |
|---|---|---|
| Application startup | Vercel build logs show `vite build` completed without errors | PASS |
| Vercel preview root | `curl` to preview URL returned `200` | PASS |
| Critical page `/admin` | `curl` to `/admin` returned `200` | PASS |
| Supabase connectivity | `get_project`, `execute_sql`, `list_edge_functions` all returned data | PASS |
| Edge Function connectivity | `curl` to `check-subdomain` returned `200` | PASS |
| Error handling | RPCs correctly raised authorization errors for invalid UUIDs | PASS |
| Network failures | No 5xx or network errors observed in Edge Function or API logs | PASS |
| Browser console | Not checked — `agent-browser` / Playwright not installed in this environment | N/A |

**Runtime Verdict:** All reachable runtime checks pass. Browser-level console verification was not possible because the browser automation toolchains are not installed in this environment; this is recorded as an observation, not a defect.

------------------------------------------------------------------------

## 10. Regression Validation

- No source-code drift between `ce87b9d7` and `HEAD` outside governance and `.codebase-memory`.
- No unexpected migrations outside `20260801000000_wave04_canonical_read_rpcs`.
- No additional runtime failures in Vercel build logs, Edge Function logs, or API logs.
- No deployment drift: Vercel deployment commit matches `ce87b9d7`.
- No configuration drift: `supabase/config.toml`, `.env.staging`, and `vercel.json` values remain consistent with the authorized revision.

**Regression Verdict:** No regression introduced by Wave-04 staging deployment.

------------------------------------------------------------------------

## 11. Security Validation

| Check | Evidence | Verdict |
|---|---|---|
| RPC permissions | `EXECUTE` granted to `authenticated` and `service_role` only | OK |
| `get_tenant_subscription` auth | Rejected nil UUID with `insufficient_privilege` | OK |
| `get_user_accounts` auth | Rejected cross-user UUID with `insufficient_privilege` | OK |
| `check-subdomain` access | `verify_jwt = false` as authorized; unauthenticated request succeeded | OK (by design) |
| Other Edge Functions | `list_edge_functions` shows `verify_jwt = true` for all others | OK |
| Search path isolation | `pg_get_functiondef` shows `SET search_path TO 'public'` for both Wave-04 RPCs | OK |
| Privilege escalation | No unexpected grants or function behavior observed | None found |

**Security Verdict:** The Wave-04 security boundary is intact. The `check-subdomain` unauthenticated access is intentional and authorized. The two canonical RPCs enforce tenant/system-admin authorization.

------------------------------------------------------------------------

## 12. Rollback Readiness

| Artifact | Rollback Action | Status |
|---|---|---|
| Database | Re-create previous function definitions or restore from pre-deployment backup | Valid |
| Edge Function | Redeploy previous `check-subdomain` bundle or toggle `verify_jwt` and redeploy | Valid |
| Vercel preview | Production deployment `dpl_8rhXQm3qLawzjUSyBNpB2fN33eM5` remains live and unaffected; preview can be discarded | Valid |
| Configuration | Revert any changed environment variables to pre-deployment values | Valid |

No rollback was required during validation. Rollback artifacts and procedures remain executable.

------------------------------------------------------------------------

## 13. Production Readiness Assessment

The staging environment has been validated against the authorized Wave-04 scope. Deployment integrity, functional behavior, runtime connectivity, security boundaries, and rollback readiness are all satisfactory. The staging deployment supports advancing to **Wave-04 Production Deployment Authorization**.

Production deployment synchronization is **not authorized** by this report and requires separate Program Owner approval.

------------------------------------------------------------------------

## 14. Risk Assessment

| Risk | Level | Evidence / Mitigation |
|---|---|---|
| Supabase `function_search_path_mutable` advisor warnings | Low | Pre-existing; the two Wave-04 RPCs were individually verified to have `SET search_path TO 'public'`. |
| Limited preview traffic during validation | Low | Build logs pass; root and `/admin` respond `200`; full authenticated flows were not exercised. |
| `check-subdomain` unauthenticated access | Low | Authorized by `55`; rate-limit logging observed in API logs. |
| Production authorization not yet granted | Medium | Governance control; no production deployment performed. |

No blocking risks identified.

------------------------------------------------------------------------

## 15. Roadmap Updates

Updated documents:

- `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md`
  - `Wave-04 Staging Deployment Validation` → `COMPLETE (58)`
  - `Wave-04 Production Deployment Authorization` → `READY TO START`
  - `Overall Completion` and `Program Status` updated to reflect production authorization readiness.
- `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md`
  - Document status header updated.
  - `13. Program Status` updated with `COMPLETE (58)` and `READY TO START` states.
  - `14. Final Decision` updated with validation result and next action.
  - `15. PMO Certification` next governance action updated.
  - `12. Future Roadmap` diagram updated.

------------------------------------------------------------------------

## 16. Program Status Updates

| Milestone | New Status |
|---|---|
| Wave-04 Staging Deployment Synchronization | **COMPLETE (57)** |
| Wave-04 Staging Deployment Validation | **COMPLETE (58)** |
| Wave-04 Production Deployment Authorization | **READY TO START** |
| Wave-04 Production Deployment Synchronization | **NOT AUTHORIZED** |
| Wave-04 Closeout | **BLOCKED BY DEPLOYMENT SYNCHRONIZATION** |
| Program Certification | **NOT STARTED** |
| Overall Program Status | **READY FOR WAVE-04 PRODUCTION DEPLOYMENT AUTHORIZATION** |

------------------------------------------------------------------------

## 17. Final GO / NO-GO Decision

``` text
GO WITH OBSERVATIONS
```

Staging deployment integrity, functionality, runtime behavior, security, and rollback readiness have been validated against the authorized Wave-04 scope. The authorized commit `ce87b9d7` is present in the Vercel preview deployment; the Wave-04 canonical read RPCs and the `check-subdomain` Edge Function are deployed and verified in the staging Supabase project. No Wave-04 implementation defects were found. The only observations are pre-existing Supabase security-advisor warnings and the inability to exercise browser console checks due to missing local toolchains.

**Stop Rule:** Stage 2 is complete. Do NOT begin Wave-04 Production Deployment Authorization, Wave-04 Production Deployment Synchronization, or Wave-04 Closeout without explicit Program Owner approval.
