# 58B1A_PREVIEW_ENVIRONMENT_REMEDIATION_AUTHORIZATION_REPORT

**Document ID:** 58B1A_PREVIEW_ENVIRONMENT_REMEDIATION_AUTHORIZATION_REPORT  
**Date:** 2026-07-22  
**Project:** VietSalePro  
**Sub Project:** Admin Dashboard  
**Program:** Admin Dashboard System Remediation Program  
**Phase:** B — System Remediation  
**Wave:** Wave-04  
**Acting Capacity:** Enterprise Program Management Office (PMO)  
**Baseline:** AD-Baseline-1.0  
**Repository Scope:** `C:\PROJECT\vietsalepro` @ `ce87b9d7`  
**Authorized Commit:** `ce87b9d7` (`fix(services,config): Wave-04 residual hardening — canonical read RPCs and check-subdomain verify_jwt`)  
**Status:** PREVIEW ENVIRONMENT REMEDIATION AUTHORIZATION COMPLETE — AUTHORIZED

------------------------------------------------------------------------

## 1. Documents Reviewed

The following mandatory governance documents were read completely before this authorization. No document or section was skipped.

| # | Document | Role in Authorization |
|---|---|---|
| 00 | `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` | Program charter, lifecycle, transition rules, current status |
| 12 | `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md` | Master Plan status, quality gates, roadmap, final decision |
| 58B | `58B_ADMIN_DASHBOARD_ENTERPRISE_BROWSER_RUNTIME_VALIDATION.md` | Stage 58B FAIL gate and blocking issue |
| 58BA | `58BA_ENTERPRISE_BROWSER_RUNTIME_VALIDATION_REPORT.md` | Detailed browser runtime evidence, HAR, and failure analysis |
| 58B0 | `58B0_STAGING_RUNTIME_CONFIGURATION_INVESTIGATION.md` | Investigation authorization, scope, and root cause finding |
| 58B0A | `58B0A_STAGING_RUNTIME_CONFIGURATION_INVESTIGATION_REPORT.md` | Detailed root cause evidence and recommended remediation |

In addition, the following repository files were reviewed to confirm the environment variable flow:

- `lib/supabase.ts`
- `vite.config.ts`
- `package.json`
- `.env`
- `.env.staging`

------------------------------------------------------------------------

## 2. Codebase Memory MCP Verification

**Tool:** `codebase-memory` MCP server  
**Action:** `index_repository` (fast mode) on `C:\PROJECT\vietsalepro`  
**Result:** `indexed` — 28,667 nodes, 42,335 edges, 0 skipped

| Verification Check | Method | Result |
|---|---|---|
| Project | `index_repository` result | `C-PROJECT-vietsalepro` |
| Indexed nodes | `index_repository` result | 28,667 |
| Indexed edges | `index_repository` result | 42,335 |
| Source drift `ce87b9d7..HEAD` | `git diff --stat` excluding `ADMIN_DASHBOARD_PLAN` and `.codebase-memory` | 0 lines — no source drift |
| Persistent artifact | `index_repository` `persistence=true` | `.codebase-memory/graph.db.zst` updated |
| Supabase client source | `read` `lib/supabase.ts` | Reads `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` from `import.meta.env` |
| Read replica source | `read` `lib/supabaseReadReplica.ts` | Reads `VITE_SUPABASE_READ_REPLICA_URL` and `VITE_SUPABASE_ANON_KEY` (same key as primary) |
| Vite build source | `read` `vite.config.ts` | No custom `envDir`; no mode-specific staging configuration |

**Codebase Memory Verdict:** The repository graph is fresh. No application-source drift detected between the authorized commit `ce87b9d7` and `HEAD`. The environment variables relevant to the browser Supabase client are consumed in `lib/supabase.ts` and `lib/supabaseReadReplica.ts`. This authorization introduces no source modifications.

------------------------------------------------------------------------

## 3. Git Verification

| Check | Method | Result |
|---|---|---|
| HEAD commit | `git rev-parse HEAD` | `a12ed302` — governance-only consistency update |
| Authorized source commit | `git rev-parse ce87b9d7` | `ce87b9d7` present and reachable |
| Current branch | `git branch --show-current` | `master` |
| Source changes `ce87b9d7..HEAD` | `git diff --stat ce87b9d7..HEAD -- . ':!ADMIN_DASHBOARD_PLAN' ':!.codebase-memory'` | 0 lines — no source drift |
| Working-tree source changes | `git diff HEAD -- . ':!ADMIN_DASHBOARD_PLAN' ':!.codebase-memory'` | `package.json` and `package-lock.json` contain Playwright validation-tooling diffs only; no application logic drift |
| Working-tree modifications | `git status --short` | `ADMIN_DASHBOARD_PLAN/*.md` governance deliverables; `.codebase-memory/*` MCP re-index artifacts; `package.json` / `package-lock.json` validation tooling diffs |

**Git Verdict:** The accepted Wave-04 source revision `ce87b9d7` remains frozen. The only changes are governance documentation, MCP infrastructure artifacts, and working-tree validation-tooling dev dependencies. No application source has been modified by this stage.

------------------------------------------------------------------------

## 4. Installed Skills Utilized

The available installed skills were reviewed for applicability. None were invoked for this authorization because the required evidence came from the Codebase Memory, Vercel, and Supabase MCP servers, the Git repository, and the existing governance documents.

| Skill | Applicability | Execution |
|---|---|---|
| `agent-browser` | Browser automation; not needed for authorization-only stage | Not invoked |
| `webapp-testing` | Runtime validation; not needed for authorization-only stage | Not invoked |
| `doc-coauthoring` | Structured documentation; not used because this is a governed PMO authorization instrument | Not invoked |
| `internal-comms` | Internal communications; not applicable | Not invoked |
| `code-review` | Not applicable — no code changes to review | Not invoked |
| `requesting-code-review` | Not applicable — not a pre-commit review | Not invoked |

**Skills Verdict:** No installed skill added a capability beyond the MCP servers and repository reads required for this authorization.

------------------------------------------------------------------------

## 5. Root Cause Review

**Verified Root Cause:** Incorrect Preview Environment Variables.

The `58B` Enterprise Browser Runtime Validation found that the Wave-04 STAGING Vercel Preview deployment sent authentication traffic to the PRODUCTION Supabase project (`rsialbfjswnrkzcxarnj.supabase.co`) instead of the authorized STAGING Supabase project (`shbmzvfcenbybvyzclem.supabase.co`). The `58B0` investigation verified the cause: the Vercel Preview environment variables `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` are configured with production credentials.

The evidence chain is:

1. `lib/supabase.ts` reads `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` from `import.meta.env`.
2. `vite.config.ts` has no custom `envDir` or staging mode.
3. `package.json` runs `vite build` (default production mode).
4. Vite's default production mode loads `.env` and `.env.production`, not `.env.staging`.
5. `.env` contains the production Supabase URL.
6. `.env.staging` contains the staging Supabase URL but is not consumed by `vite build`.
7. Vercel injects project environment variables into the build at build time and overrides `.env` values.
8. The Vercel Preview environment variables are currently set to the production Supabase credentials.
9. The `58BA` HAR file confirms the deployed Preview bundle contains `rsialbfjswnrkzcxarnj.supabase.co` and not `shbmzvfcenbybvyzclem.supabase.co`.

This authorization independently confirms that the root cause has been objectively verified.

------------------------------------------------------------------------

## 6. Technical Review of Proposed Remediation

The proposed remediation is an environment-configuration change followed by a Preview redeployment. No source, database, migration, or Edge Function change is required.

| Step | Action | Expected Result |
|---|---|---|
| 1 | Update Vercel Preview `VITE_SUPABASE_URL` to `https://shbmzvfcenbybvyzclem.supabase.co` | Preview build embeds staging Supabase URL |
| 2 | Update Vercel Preview `VITE_SUPABASE_ANON_KEY` to the staging anon key | Preview build embeds staging anon key |
| 3 | Leave Production `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` unchanged | Production remains connected to `rsialbfjswnrkzcxarnj` |
| 4 | Redeploy Preview from `ce87b9d7` | New Preview deployment built with staging credentials |
| 5 | Re-run `58B` Enterprise Browser Runtime Validation | Confirm preview uses staging Supabase and passes browser checks |

This remediation is technically correct because:

- The application is not broken; it correctly consumes injected `VITE_` environment variables.
- The root cause is the values injected into the Preview build, not the source code.
- Changing the Vercel Preview variables to staging values is the smallest action that removes the production Supabase connection from the Preview deployment.
- The `vite build` command and Vite configuration can remain unchanged.
- Production variables are not modified, so production isolation is preserved.

------------------------------------------------------------------------

## 7. Scope Validation

The remediation scope has been validated as minimal and Preview-only.

| Included in Scope | Disposition |
|---|---|
| Vercel Preview `VITE_SUPABASE_URL` | Update to staging URL |
| Vercel Preview `VITE_SUPABASE_ANON_KEY` | Update to staging anon key |
| Preview redeployment from `ce87b9d7` | Allowed |
| `58B` Enterprise Browser Runtime Validation re-run | Allowed |

| Excluded from Scope | Disposition |
|---|---|
| Application source code | No modification |
| `.env`, `.env.staging`, `.env.example` | No modification |
| Database schema or migrations | No execution |
| Edge Functions | No deployment |
| Supabase project configuration | No change |
| Vercel Production environment variables | No change |
| Production deployment | Not authorized |

No additional changes are included.

------------------------------------------------------------------------

## 8. Risk Assessment

| Risk | Severity | Likelihood | Evaluation | Mitigation |
|---|---|---|---|---|
| **Deployment risk** (Preview fails to build/deploy) | Low | Low | Minor delay in `58B` re-run | Use authorized commit `ce87b9d7`; verify `READY` state and URL before validation |
| **Configuration risk** (wrong env scope or value) | Medium | Low | Could reintroduce defect or affect production | Update only `preview` scoped variables; verify with `vercel env list` before save |
| **Rollback risk** (new Preview does not behave correctly) | Low | Low | Can restore previous values and redeploy prior Preview revision | Record pre-remediation variable values; Vercel retains deployment history |
| **Production isolation risk** (Production accidentally changed) | High impact | Low | Production traffic could be disrupted if `production` env is edited | Do not modify `production` env; scope variables to `preview` only |
| **Environment isolation risk** (Staging data pollution) | Low | Low | Staging project may receive test auth attempts | Staging is separate from production; intended for validation |
| **Credential exposure risk** (keys in reports/logs) | Medium | Low | Anon keys are public by design but should still be redacted | Redact all keys from reports, HAR, screenshots, and logs |
| **Repository integrity risk** (unintended source change) | Low | Low | No source change is required | Commit only governance documents; do not commit `.env` or source files |

Overall risk is **LOW** because the change is limited to two Preview environment variables and a Preview redeployment, with straightforward rollback and no Production impact.

------------------------------------------------------------------------

## 9. Rollback Assessment

The rollback strategy is:

1. **Environment rollback:** Restore the previous Vercel Preview `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` values if the new values are incorrect.
2. **Deployment rollback:** Redeploy the previous healthy Preview revision (e.g., the current `dpl_GXrhNbCnqAkZXaZyALmkVb78HUSV` or any other known-good Preview) if the new Preview deployment is unhealthy.
3. **Production rollback:** Not required. Production environment variables and deployment are not part of this remediation.

The rollback does not require source-code, database, migration, or Edge Function changes. It is a standard Vercel Preview environment and deployment operation.

------------------------------------------------------------------------

## 10. Governance Review

This authorization has been reviewed against the Program Charter (`00`) and the Remediation Master Plan (`12`):

- The `58B0` investigation is complete and its root cause is verified.
- The proposed remediation is technically correct, minimal, and Preview-only.
- No application source code, database schema, migrations, Edge Functions, or Supabase configuration are changed.
- Production environment variables remain unchanged.
- Risks and rollback have been documented.
- The Wave-04 governance chain is preserved; `58B` must pass before Production Deployment Authorization can be reconsidered.

No governance gate is bypassed and no additional scope is authorized.

------------------------------------------------------------------------

## 11. Roadmap Updates

| Item | Prior Value | Updated Value |
|---|---|---|
| Current milestone | `58B0` Staging Runtime Configuration Investigation COMPLETE; `58B` FAIL root cause verified | `58B1` Preview Environment Remediation Authorization COMPLETE |
| Current blocker | Vercel Preview `VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY` configured with production values | Remediation authorized; awaiting `58B2` execution and `58B` re-run |
| Next milestone | Program Owner approval to remediate Vercel Preview env variables | `58B2` Preview Environment Remediation |
| Next governance action after `58B2` | N/A | Re-run `58B` Enterprise Browser Runtime Validation |
| `58B` status | FAIL | FAIL (pending environment remediation and re-run) |
| Wave-04 Production Deployment Authorization | BLOCKED BY 58B FAIL | BLOCKED BY 58B FAIL (remediation now authorized) |
| Wave-04 Production Deployment Synchronization | NOT AUTHORIZED | NOT AUTHORIZED |
| Wave-04 Closeout | BLOCKED BY DEPLOYMENT SYNCHRONIZATION | BLOCKED BY DEPLOYMENT SYNCHRONIZATION |

------------------------------------------------------------------------

## 12. Program Status Updates

`00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` and `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md` are synchronized with the following status:

- `58B1` Preview Environment Remediation Authorization: **COMPLETE**.
- `58B` Enterprise Browser Runtime Validation: **COMPLETE (FAIL)**; root cause is **VERIFIED**.
- `58B2` Preview Environment Remediation: **READY TO START** (subject to Program Owner execution approval).
- `58B` Re-run: **PENDING ENVIRONMENT REMEDIATION**.
- Wave-04 Production Deployment Authorization: **BLOCKED BY 58B FAIL**.
- Wave-04 Production Deployment Synchronization: **NOT AUTHORIZED**.
- Wave-04 Closeout: **BLOCKED BY DEPLOYMENT SYNCHRONIZATION**.
- Overall Program Status: **READY FOR PREVIEW ENVIRONMENT REMEDIATION**.

------------------------------------------------------------------------

## 13. Final Authorization Decision

**DECISION: AUTHORIZED**

The Preview Environment Remediation is authorized to proceed to execution stage `58B2` under the following conditions:

1. Update only the `preview` Vercel environment variables `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` to the authorized staging values.
2. Leave all `production` Vercel environment variables unchanged.
3. Redeploy Preview from the authorized commit `ce87b9d7`.
4. Re-run `58B` Enterprise Browser Runtime Validation and obtain a PASS.
5. Do not begin Wave-04 Production Deployment Authorization, Wave-04 Production Deployment Synchronization, or Wave-04 Closeout until `58B` passes.

This authorization does **NOT** authorize any implementation, source-code modification, migration, Edge Function deployment, Supabase change, or Production deployment.

This authorization stage is complete. No Vercel Environment Variables, Preview redeployment, `58B` re-run, or Production deployment activity has been performed.
