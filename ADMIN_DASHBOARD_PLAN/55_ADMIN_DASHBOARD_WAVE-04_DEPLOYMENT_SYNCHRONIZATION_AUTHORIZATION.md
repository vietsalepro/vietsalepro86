# 55_ADMIN_DASHBOARD_WAVE-04_DEPLOYMENT_SYNCHRONIZATION_AUTHORIZATION

**Document ID:** 55_ADMIN_DASHBOARD_WAVE-04_DEPLOYMENT_SYNCHRONIZATION_AUTHORIZATION  
**Date:** 2026-07-22  
**Project:** VietSalePro  
**Sub Project:** Admin Dashboard  
**Program:** Admin Dashboard System Remediation Program  
**Phase:** B — System Remediation  
**Wave:** Wave-04  
**Acting Capacity:** Enterprise Program Management Office (PMO) together with the Principal Software Architect  
**Baseline:** AD-Baseline-1.0  
**Repository Scope:** `C:\PROJECT\vietsalepro` @ `ce87b9d7`  
**Repository Artifacts Modified:** `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md`, `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md`, `55_ADMIN_DASHBOARD_WAVE-04_DEPLOYMENT_SYNCHRONIZATION_AUTHORIZATION.md` (this document)  
**Status:** WAVE-04 DEPLOYMENT SYNCHRONIZATION AUTHORIZATION COMPLETE — WAVE-04 STAGING DEPLOYMENT SYNCHRONIZATION READY TO START

------------------------------------------------------------------------

# 1. Purpose

This document authorizes only the execution scope for Wave-04 Deployment Synchronization.

No deployment is executed by this document. No implementation, source-code modification, migration execution, database modification, Edge Function deployment, Vercel deployment, or runtime modification is performed. Authorization only.

Stage 1 (Staging Deployment Synchronization) is authorized to begin after explicit Program Owner go-ahead. Stage 2 (Production Deployment Synchronization) is not authorized by this document and requires separate Program Owner approval after the Stage 1 report is accepted.

------------------------------------------------------------------------

# 2. Governance Chain Review

The Wave-03 through Wave-04 governance chain was reconstructed and verified against the mandatory documents. No gate was skipped.

| Gate | Status | Evidence |
|---|---|---|
| Phase A | CLOSED | `10B_ADMIN_DASHBOARD_PHASE_A_CLOSEOUT.md` |
| Baseline | SEALED (AD-Baseline-1.0) | `10B` Section 11; `12` Section 4 |
| Phase B | OPEN | `11` Section 1 |
| Remediation Master Plan | COMPLETE | `12` Section 14 |
| Wave-04 Authorization | AUTHORIZED WITH OBSERVATIONS | `47` Section 1 |
| Wave-04 Engineering Kickoff | COMPLETE WITH OBSERVATIONS | `48` Section 1 |
| Wave-04 Repository Readiness Remediation | COMPLETE | `49` Section 1 |
| Wave-04 Implementation Readiness Review | COMPLETE | `50` Section 1 |
| Wave-04 Implementation | COMPLETE | `51` Section 1 |
| Wave-04 Verification | PASS WITH OBSERVATIONS | `52` Section 1 |
| Wave-04 Acceptance | ACCEPTED WITH OBSERVATIONS | `53` Section 1 |
| Wave-04 Deployment Synchronization Roadmap Update | COMPLETE | `54` Section 1 |
| Governance Document Consistency Update | COMPLETE | `54A` Section 6 |
| Master Plan Synchronization | COMPLETE | `54B` Section 6 |
| Wave-04 Deployment Synchronization Authorization | COMPLETE (this document) | — |
| Wave-04 Staging Deployment Synchronization | READY TO START | This document |
| Wave-04 Production Deployment Synchronization | NOT AUTHORIZED | This document |
| Wave-04 Closeout | BLOCKED BY DEPLOYMENT SYNCHRONIZATION | `00` Section 11A; `12` Section 13 |

**Governance Verdict:** The chain is intact. Wave-04 Deployment Synchronization is authorized to proceed to Stage 1 (Staging) only.

------------------------------------------------------------------------

# 3. Documents Reviewed

The following mandatory governance documents were read completely before this authorization was produced. No section was skipped.

| # | Document | Role in Authorization | Read Status |
|---|----------|-----------------------|-------------|
| 00 | `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` | Program charter, lifecycle, Deployment Synchronization gate, current status | Read in full |
| 12 | `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md` | Master Plan status, quality gates, roadmap | Read in full |
| 52 | `52_ADMIN_DASHBOARD_WAVE-04_VERIFICATION.md` | Wave-04 verification and deployment observations | Read in full |
| 53 | `53_ADMIN_DASHBOARD_WAVE-04_ACCEPTANCE_REVIEW.md` | Wave-04 acceptance and deployment observations | Read in full |
| 54 | `54_PRE_WAVE04_DEPLOYMENT_SYNCHRONIZATION_ROADMAP_UPDATE.md` | Deployment Synchronization gate definition and roadmap | Read in full |
| 54A | `54A_GOVERNANCE_DOCUMENT_CONSISTENCY_UPDATE.md` | Consistency of governance documents | Read in full |
| 54B | `54B_MASTER_PLAN_SYNCHRONIZATION_REPORT.md` | Master Plan synchronization evidence | Read in full |

In addition, `47`, `48`, `49`, `50`, and `51` were referenced to confirm the approved Wave-04 implementation scope.

------------------------------------------------------------------------

# 4. Authorized Deployment Scope

Nothing outside the scope below may be deployed or synchronized.

| Artifact Class | Authorized Artifact | Evidence |
|---|---|---|
| **Repository revision** | `ce87b9d7` on `master` | `git rev-parse HEAD` = `ce87b9d7`; accepted by `53` |
| **Git commit** | `ce87b9d7` — `fix(services,config): Wave-04 residual hardening — canonical read RPCs and check-subdomain verify_jwt` | `git log --oneline -1` |
| **Supabase migrations** | `supabase/migrations/20260801000000_wave04_canonical_read_rpcs.sql` | File present; adds `get_tenant_subscription(UUID)` and `get_user_accounts(UUID)` |
| **Database schema / RPCs** | `public.get_tenant_subscription(UUID)` and `public.get_user_accounts(UUID)` with `SECURITY DEFINER`, `STABLE`, grants to `authenticated` and `service_role` | Migration file lines 8–67 |
| **Edge Functions** | `check-subdomain` — re-deploy with `verify_jwt = false` | `supabase/config.toml` lines 581–582 |
| **Environment Configuration** | `.env`, `.env.staging`, `.env.example`, `supabase/config.toml` (target environment variables must match the accepted revision; no secret values are disclosed in this document) | Files present in repository root |
| **Vercel deployment** | Frontend build from `ce87b9d7` with `vercel.json` rewrites to `index.html` | `package.json` build script `vite build`; `vercel.json` |
| **Runtime behaviour** | `services/tenantService.ts:getTenantSubscription` calls `supabase.rpc('get_tenant_subscription', { p_tenant_id: tenantId })`; `services/admin/tenantAdminService.ts:getUserAccounts` calls `supabase.rpc('get_user_accounts', { p_user_id: userId })` for arbitrary `userId` | `services/tenantService.ts` lines 455–463; `services/admin/tenantAdminService.ts` lines 85–87 |
| **Configuration dependencies** | Supabase project URL and anon key; service role key (if used for RPC grants verification); Vercel team/project access; Edge Function endpoint URLs | Required by `supabase/config.toml`, `.env`, and deployment commands |
| **Deployment dependencies** | Supabase CLI, Vercel CLI, authenticated access to staging and production Supabase projects and Vercel team, `npm`/`node` for build | Tooling present in `package.json` / dev environment |
| **Rollback dependencies** | Vercel previous production deployment; database backup before migration; previous `check-subdomain` Edge Function bundle; ability to re-apply or remove the Wave-04 migration if needed | Operational responsibility of the Enterprise Release Manager |

------------------------------------------------------------------------

# 5. Deployment Strategy

## 5.1 Authorized Stages

``` text
Stage 1: Staging Deployment Synchronization  (authorized by this document)
        ↓
Program Owner review of Stage 1 Deployment Synchronization Report
        ↓
Stage 2: Production Deployment Synchronization  (requires separate Program Owner approval)
        ↓
Wave-04 Deployment Synchronization Report (final) and Closeout readiness
```

## 5.2 Execution Order (Stage 1 — Staging)

1. **Pre-flight**
   - Confirm the accepted commit is `ce87b9d7` and the staging target Supabase project and Vercel app are identified.
   - Verify staging environment variables match the accepted revision.
2. **Build verification**
   - Run `npm run lint` (`tsc --noEmit`) on `ce87b9d7`.
   - Run `npm run build` (`vite build`) on `ce87b9d7`.
3. **Supabase migration (staging)**
   - Apply `20260801000000_wave04_canonical_read_rpcs.sql` to the staging Supabase project (`supabase db push` or equivalent).
4. **RPC verification (staging)**
   - Confirm `get_tenant_subscription(UUID)` and `get_user_accounts(UUID)` exist and have grants to `authenticated` and `service_role`.
5. **Edge Function deploy (staging)**
   - Re-deploy `check-subdomain` to staging so the `verify_jwt = false` setting in `supabase/config.toml` takes effect (`supabase functions deploy check-subdomain`).
6. **Edge Function config verification (staging)**
   - Confirm an unauthenticated request to the staging `check-subdomain` endpoint succeeds where appropriate.
7. **Vercel deploy (staging)**
   - Deploy the `ce87b9d7` build to the Vercel staging target.
8. **Runtime verification (staging)**
   - Exercise the Admin Dashboard flows that call `getTenantSubscription` and `getUserAccounts`.
   - Confirm the services call the RPCs and do not fall back to direct `.from('tenant_subscriptions')` or `.from('tenant_memberships')` reads.
   - Confirm `check-subdomain` behavior matches the accepted configuration.
9. **Stage 1 report**
   - Produce the Wave-04 Stage 1 (Staging) Deployment Synchronization Report with evidence and any observations.

## 5.3 Production Strategy

Production Deployment Synchronization is **not** authorized by this document. It may begin only after:

- Stage 1 report is approved by the Program Owner.
- The same execution order is repeated against the production Supabase project and Vercel production target.
- A maintenance window or low-traffic window is confirmed.

## 5.4 Artifact Ordering

Database RPCs must be applied before the Vercel frontend that depends on them is promoted, because the new `services/tenantService.ts` and `services/admin/tenantAdminService.ts` call the RPCs at runtime. Edge Function `check-subdomain` may be deployed independently before or after the Vercel deploy, but must be verified before runtime checks.

Recommended order per environment:

``` text
Supabase migration  →  RPC verification  →  Edge Function deploy  →  Edge Function verification  →  Vercel deploy  →  Runtime verification
```

## 5.5 Rollback Strategy

- **Database:** Back up the target Supabase database before applying the migration. If the migration causes errors, restore from the backup or manually drop/recreate the previous function definitions under engineering supervision.
- **Edge Function:** Redeploy the previous `check-subdomain` bundle or revert `supabase/config.toml` and redeploy.
- **Vercel:** Roll back to the previous Vercel deployment via the Vercel dashboard or CLI (`vercel rollback`).
- **Configuration:** Revert any changed environment variables to the pre-deployment values before rolling back the Vercel deployment.

## 5.6 Verification Checkpoints

| # | Checkpoint | Acceptance |
|---|---|---|
| 1 | `git rev-parse HEAD` on build source | `ce87b9d7` |
| 2 | Migration applied to target database | `get_tenant_subscription` and `get_user_accounts` exist and grant execute to `authenticated` and `service_role` |
| 3 | Edge Function deployed | `check-subdomain` responds to an unauthenticated request in line with `verify_jwt = false` |
| 4 | Vercel deployment revision | Deployment metadata points to `ce87b9d7` |
| 5 | Runtime behavior | `getTenantSubscription` and `getUserAccounts` return data through the RPCs without direct `.from` reads |

## 5.7 Failure Handling and Recovery Path

- If the migration fails, stop. Do not deploy Vercel or Edge Function. Repair the migration state, restore from backup if necessary, and re-attempt.
- If the Edge Function deploy fails but the migration succeeds, pause Vercel deploy, diagnose the function error, redeploy, and re-verify.
- If Vercel deploy succeeds but runtime verification fails, rollback Vercel first, then investigate whether the RPCs or Edge Function are misconfigured.
- Record every deviation as an observation. Any unresolved implementation defect is returned to implementation, not accepted as an observation.

------------------------------------------------------------------------

# 6. Risk Review

| Risk | Severity | Mitigation |
|---|---|---|
| **Repository risk** — deploying a commit other than `ce87b9d7` | HIGH | Tag `ce87b9d7` as `wave-04-accepted`; verify `git rev-parse HEAD` before every deploy command. |
| **Database risk** — migration locks or errors on live database | HIGH | Apply during low traffic; back up before migration; test on staging first. |
| **Migration risk** — migration applied out of order or partially applied | MEDIUM | Use `supabase db push` or `supabase migrations up` with explicit target; verify applied list after. |
| **RPC risk** — functions not created or grants missing | HIGH | Query `pg_proc` and `information_schema.routine_privileges` after apply; exercise both RPCs from a test client. |
| **Edge Function risk** — `verify_jwt = false` not applied in remote | HIGH | Deploy `check-subdomain` explicitly; call the endpoint without a JWT to verify. |
| **Configuration drift** — `.env`/`.env.staging` differ from accepted revision | MEDIUM | Diff environment variables against repository `.env.example` before deploy; reject deploy if unknown drift is found. |
| **Environment drift** — staging or production schema already diverges from `ce87b9d7` | HIGH | Capture pre-deployment `supabase db dump` / schema snapshot; compare with committed migration history. |
| **Runtime drift** — browser/CDN caches serve old bundle or API client ignores RPC | MEDIUM | Force Vercel build with no cache; verify network calls in runtime checks. |
| **Rollback failure** — no down migration or backup missing | CRITICAL | Back up before migration; document exact previous function definitions; verify Vercel rollback target. |
| **Deployment interruption** — CLI/network failure mid-deploy | MEDIUM | Run commands idempotently where possible; verify state after each command; do not proceed until previous step passes. |
| **Dependency failure** — Supabase CLI or Vercel CLI unavailable or unauthenticated | MEDIUM | Verify `supabase --version`, `vercel --version`, and login status before Stage 1. |
| **Recovery complexity** — multiple artifacts out of sync after a partial failure | HIGH | Follow the fixed execution order; stop on first failure; record state at each checkpoint. |

------------------------------------------------------------------------

# 7. Authorization Conditions

## 7.1 Entry Criteria

- Wave-04 Acceptance is complete (`53`).
- Accepted repository revision `ce87b9d7` is frozen.
- Target staging Supabase project and Vercel staging app are identified.
- Deployment credentials and access are available and authorized.
- This Authorization document has been produced and reviewed.
- Program Owner go-ahead is given for Stage 1.

## 7.2 Execution Constraints

- Only commit `ce87b9d7` may be deployed.
- No source-code changes are permitted during Deployment Synchronization.
- No migration other than `20260801000000_wave04_canonical_read_rpcs.sql` may be applied.
- Stage 1 must complete and be approved before Stage 2 is requested.
- No production deployment may be triggered by this document.

## 7.3 Execution Rules

1. Staging first, always.
2. Verify the previous step before starting the next.
3. Record evidence at every checkpoint.
4. Stop on any failure and report before continuing.
5. Treat only pre-accepted artifacts; no new scope.

## 7.4 Authorized Activities

- Apply the Wave-04 migration to the target database in staging.
- Deploy the `check-subdomain` Edge Function to staging with `verify_jwt = false`.
- Deploy the `ce87b9d7` Vercel build to staging.
- Run `npm run lint` and `npm run build` for verification.
- Execute runtime verification checks and record evidence.
- Produce the Stage 1 Deployment Synchronization Report.

## 7.5 Prohibited Activities

- Modifying any source, migration, RPC, or Edge Function code.
- Applying any migration other than the one listed in this scope.
- Deploying to production.
- Manually editing database objects outside the migration.
- Changing `vercel.json`, `package.json`, or `supabase/config.toml` values not already in `ce87b9d7`.
- Revealing or logging secrets.
- Skipping verification checkpoints.

## 7.6 Exit Criteria

- Stage 1 Deployment Synchronization has been attempted for every artifact class in the scope.
- Evidence confirms the staging environment matches the accepted revision, or deviations are explicitly recorded as observations.
- The Stage 1 report is complete and approved by the Enterprise Release Manager or PMO.
- Program status is updated to `Wave-04 Staging Deployment Synchronization COMPLETE` and `Wave-04 Production Deployment Synchronization READY TO START` (after staging approval).

## 7.7 Required Evidence

- `git rev-parse HEAD` = `ce87b9d7`.
- Applied migration list for the target database.
- RPC existence and grants verification.
- Edge Function deploy log and unauthenticated endpoint test result.
- Vercel staging deployment URL and commit metadata.
- Runtime verification logs for `getTenantSubscription` and `getUserAccounts`.

## 7.8 Success Criteria

- All artifacts in the authorized scope are synchronized with the staging environment.
- No unauthorized changes are introduced.
- Runtime behavior matches the accepted source.

## 7.9 Failure Criteria

- A commit other than `ce87b9d7` is deployed.
- An unauthorized migration is applied.
- Production is deployed without Program Owner approval.
- An unresolved implementation defect is accepted as a deployment observation.

------------------------------------------------------------------------

# 8. Governance Validation

- No governance document conflicts were found between `00`, `12`, `52`, `53`, `54`, `54A`, and `54B`.
- No roadmap conflicts were found.
- No status conflicts were found.
- No lifecycle conflicts were found; the Deployment Synchronization gate sits between Wave Acceptance and Wave Closeout as defined in `00` Section 11A.
- No deployment may begin before explicit Program Owner approval for Stage 1.

------------------------------------------------------------------------

# 9. Roadmap Update

| Milestone | Previous Status | Updated Status |
|---|---|---|
| Wave-04 Acceptance | COMPLETE | COMPLETE |
| Wave-04 Deployment Synchronization Authorization | READY TO START | **COMPLETE** |
| Wave-04 Staging Deployment Synchronization | READY TO START | **READY TO START** |
| Wave-04 Production Deployment Synchronization | NOT AUTHORIZED | **NOT AUTHORIZED (requires separate approval)** |
| Wave-04 Closeout | BLOCKED BY DEPLOYMENT SYNCHRONIZATION | BLOCKED BY DEPLOYMENT SYNCHRONIZATION |

------------------------------------------------------------------------

# 10. Program Status

``` text
Knowledge Baseline                       : COMPLETE
Repository Investigation                 : COMPLETE
Independent Acceptance Review            : COMPLETE
Acceptance Conditions Implementation     : COMPLETE
Phase A Closeout                         : COMPLETE
Baseline                                 : SEALED
Phase B Opening Authorization            : COMPLETE
Phase B                                  : OPEN
Remediation Master Plan                  : COMPLETE
Program Owner Decisions                  : COMPLETE
Wave Planning                            : COMPLETE
Wave-04 Authorization                    : AUTHORIZED WITH OBSERVATIONS
Wave-04 Engineering Kickoff              : COMPLETE WITH OBSERVATIONS
Wave-04 Repository Readiness Remediation : COMPLETE
Wave-04 Implementation Readiness Review  : COMPLETE (50)
Wave-04 Implementation                   : COMPLETE (51)
Wave-04 Verification                     : PASS WITH OBSERVATIONS (52)
Wave-04 Acceptance                       : COMPLETE
Wave-04 Deployment Synchronization Authorization : COMPLETE (55)
Wave-04 Staging Deployment Synchronization : READY TO START
Wave-04 Production Deployment Synchronization : NOT AUTHORIZED
Wave-04 Closeout                         : BLOCKED BY DEPLOYMENT SYNCHRONIZATION
Overall Completion                       : Wave-04 Deployment Synchronization Authorization COMPLETE; Wave-04 Staging Deployment Synchronization READY TO START
Program Status                           : READY FOR WAVE-04 STAGING DEPLOYMENT SYNCHRONIZATION
(Updated by 55_ADMIN_DASHBOARD_WAVE-04_DEPLOYMENT_SYNCHRONIZATION_AUTHORIZATION.md, 2026-07-22)
```

------------------------------------------------------------------------

# 11. Final Authorization Decision

``` text
Wave-04 Deployment Synchronization is AUTHORIZED to proceed to Stage 1 (Staging) only.

Stage 1 authorized scope:
- Apply supabase/migrations/20260801000000_wave04_canonical_read_rpcs.sql to the staging Supabase project.
- Re-deploy the check-subdomain Edge Function to staging with verify_jwt = false.
- Deploy the ce87b9d7 Vercel build to staging.
- Perform runtime verification and produce the Stage 1 Deployment Synchronization Report.

Stage 2 (Production) is NOT AUTHORIZED by this document.
```

**Stop:** Do NOT begin Stage 1 until the Program Owner explicitly approves it. Do NOT begin Stage 2 until the Stage 1 report is approved and the Program Owner explicitly authorizes production deployment.

------------------------------------------------------------------------

# 12. Stopping Rule

No staging deployment, no production deployment, no migration execution, no database modification, no Edge Function deployment, no Vercel deployment, no source-code modification, and no runtime modification shall be performed until the Program Owner explicitly approves the start of Stage 1 (Staging Deployment Synchronization) in writing or via the next authorized action.
