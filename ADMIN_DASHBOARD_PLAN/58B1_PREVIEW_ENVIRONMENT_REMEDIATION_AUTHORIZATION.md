# 58B1_PREVIEW_ENVIRONMENT_REMEDIATION_AUTHORIZATION

**Document ID:** 58B1_PREVIEW_ENVIRONMENT_REMEDIATION_AUTHORIZATION  
**Date:** 2026-07-22  
**Project:** VietSalePro  
**Sub Project:** Admin Dashboard  
**Program:** Admin Dashboard System Remediation Program  
**Phase:** B — System Remediation  
**Wave:** Wave-04  
**Acting Capacity:** Enterprise Program Management Office (PMO)  
**Authorized Commit:** `ce87b9d7` (`fix(services,config): Wave-04 residual hardening — canonical read RPCs and check-subdomain verify_jwt`)  
**Current Governance Status:** 58B0 Staging Runtime Configuration Investigation COMPLETE; 58B FAIL root cause VERIFIED  

------------------------------------------------------------------------

## 1. Purpose

Review the verified runtime configuration defect discovered during `58B` Enterprise Browser Runtime Validation and authorize (or reject) the Preview Environment Remediation.

This stage:

- Does **NOT** modify any environment.
- Does **NOT** update Vercel Environment Variables.
- Does **NOT** redeploy Preview.
- Does **NOT** modify repository application source code.
- Does **ONLY** produce an authorization decision.

------------------------------------------------------------------------

## 2. Governance Authorization

| Gate | Document | Status |
|---|---|---|
| Phase A | `10B_ADMIN_DASHBOARD_PHASE_A_CLOSEOUT.md` | CLOSED |
| Baseline | `10B` Section 11; `12` Section 4 | SEALED (`AD-Baseline-1.0`) |
| Phase B | `11_ADMIN_DASHBOARD_PHASE_B_OPENING_AUTHORIZATION.md` | OPEN |
| Wave-04 Staging Deployment Synchronization | `57` / `57A` | COMPLETE |
| Wave-04 Staging Deployment Validation | `58` / `58A` | COMPLETE (GO WITH OBSERVATIONS) |
| Enterprise Browser Runtime Validation | `58B` / `58BA` | COMPLETE (FAIL) |
| Staging Runtime Configuration Investigation | `58B0` / `58B0A` | COMPLETE — ROOT CAUSE VERIFIED |
| Preview Environment Remediation Authorization | This document | AUTHORIZED |

Program Owner approval to proceed to `58B2` Preview Environment Remediation is recorded in this document.

------------------------------------------------------------------------

## 3. Documents Reviewed

The following mandatory governance documents were read completely before authorization. No section was skipped.

| # | Document | Role in Authorization |
|---|---|---|
| 00 | `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` | Program charter, lifecycle, transition rules, current status |
| 12 | `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md` | Master Plan status, quality gates, roadmap, final decision |
| 58B | `58B_ADMIN_DASHBOARD_ENTERPRISE_BROWSER_RUNTIME_VALIDATION.md` | Stage 58B FAIL gate and blocking issue |
| 58BA | `58BA_ENTERPRISE_BROWSER_RUNTIME_VALIDATION_REPORT.md` | Detailed browser runtime evidence, HAR, and failure analysis |
| 58B0 | `58B0_STAGING_RUNTIME_CONFIGURATION_INVESTIGATION.md` | Investigation authorization, scope, and root cause finding |
| 58B0A | `58B0A_STAGING_RUNTIME_CONFIGURATION_INVESTIGATION_REPORT.md` | Detailed root cause evidence and recommended remediation |

------------------------------------------------------------------------

## 4. Codebase Memory MCP Verification

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

**Codebase Memory Verdict:** The repository graph is fresh. No application-source drift detected between the authorized commit `ce87b9d7` and `HEAD`. This authorization introduces no source modifications.

------------------------------------------------------------------------

## 5. Git Verification

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

## 6. Installed Skills Utilized

The available installed skills were reviewed for applicability. None were invoked for this authorization because the required evidence came from the Codebase Memory, Vercel, and Supabase MCP servers, the Git repository, and the existing governance documents.

| Skill | Applicability | Execution |
|---|---|---|
| `agent-browser` | Browser automation; not needed for authorization-only stage | Not invoked |
| `webapp-testing` | Runtime validation; not needed for authorization-only stage | Not invoked |
| `doc-coauthoring` | Structured documentation; not used because this is a governed PMO authorization instrument | Not invoked |
| `internal-comms` | Internal communications; not applicable | Not invoked |
| `code-review` | Not applicable — no code changes to review | Not invoked |

**Skills Verdict:** No installed skill added a capability beyond the MCP servers and repository reads required for this authorization.

------------------------------------------------------------------------

## 7. Root Cause Review

**Verified Root Cause:** Incorrect Preview Environment Variables.

The `58B0` investigation determined that the Wave-04 STAGING Vercel Preview deployment (`dpl_GXrhNbCnqAkZXaZyALmkVb78HUSV`) was communicating with the PRODUCTION Supabase project (`rsialbfjswnrkzcxarnj`) instead of the authorized STAGING Supabase project (`shbmzvfcenbybvyzclem`).

The browser Supabase client in `lib/supabase.ts` reads `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` from `import.meta.env` at build time. The Vite configuration (`vite.config.ts`) has no custom `envDir` or mode-specific staging configuration, and `package.json` build script is `vite build` (default production mode). Vercel Preview environment variables are the authoritative source for the Preview build. Those variables are currently configured with the production Supabase credentials, so the preview bundle embeds `https://rsialbfjswnrkzcxarnj.supabase.co`.

The repository `.env.staging` contains the correct staging values, but because `vite build` does not load `.env.staging` in the default production mode, those values are not consumed.

This authorization independently confirms that the root cause has been objectively verified.

------------------------------------------------------------------------

## 8. Technical Review of Proposed Remediation

The proposed remediation from `58B0A` is:

1. Update Vercel Preview environment variable `VITE_SUPABASE_URL` to `https://shbmzvfcenbybvyzclem.supabase.co` (matching `.env.staging`).
2. Update Vercel Preview environment variable `VITE_SUPABASE_ANON_KEY` to the staging anon key (matching `.env.staging`).
3. Preserve Production environment variables unchanged (`https://rsialbfjswnrkzcxarnj.supabase.co` and its anon key).
4. Redeploy the Preview using the authorized commit `ce87b9d7`.
5. Re-run `58B` Enterprise Browser Runtime Validation.
6. No source code, migration, Edge Function, or Supabase configuration changes.

This remediation is technically correct because it addresses the root cause at its source: the build-time environment injected into the Preview deployment. It does not require source code changes because the application correctly consumes injected `VITE_` variables; only the injected values need correction.

------------------------------------------------------------------------

## 9. Scope Validation

The remediation scope is limited to Preview environment configuration:

| Allowed Scope | Change |
|---|---|
| Preview `VITE_SUPABASE_URL` | Update to staging URL |
| Preview `VITE_SUPABASE_ANON_KEY` | Update to staging anon key |
| Preview redeployment | Redeploy from `ce87b9d7` |
| `58B` re-run | Validate the corrected preview |

| Explicitly Excluded Scope | Status |
|---|---|
| Application source code | No change |
| `.env` files | No change |
| Supabase schema / migrations | No change |
| Edge Functions | No change |
| Production environment variables | No change |
| Production deployment | Not authorized |

The scope is minimal and isolated to the Preview environment.

------------------------------------------------------------------------

## 10. Risk Assessment

| Risk | Evaluation | Mitigation |
|---|---|---|
| **Deployment risk** | Low — redeploying an already-authorized commit to Preview | Use authorized commit `ce87b9d7` only; verify new deployment ID before validation |
| **Configuration risk** | Low — two Preview variables updated; no Production change | Update only `preview` scoped variables; double-check target environment before save |
| **Rollback risk** | Low — previous values can be restored and a prior preview revision redeployed | Record pre-remediation values; Vercel keeps deployment history |
| **Production isolation** | High confidence — Production env vars are untouched; preview and production targets are separate Supabase projects | Do not modify `production` environment variables |
| **Environment isolation** | Preview is a separate Vercel deployment and Supabase project; production traffic not affected | Verify new preview URL and HAR contain only `shbmzvfcenbybvyzclem` before any production authorization |
| **Credential exposure** | Anon keys are public by design in the browser bundle; still redact from reports and logs | Do not record keys in governance documents; redact HAR/screenshots |
| **Repository integrity** | No source change; only Vercel environment variables change | Do not modify repository files except governance documents for this authorization |

No additional risks were identified beyond those already mitigated above.

------------------------------------------------------------------------

## 11. Rollback Assessment

The rollback strategy is:

1. **Restore previous Preview Environment Variables** if the new values cause failure.
2. **Redeploy a previous Preview revision** if the new Preview deployment is unhealthy.
3. **No Production rollback is required** because Production environment variables and deployment are not affected.

This rollback is standard Vercel environment/deployment management and does not require source or database changes.

------------------------------------------------------------------------

## 12. Governance Review

This authorization complies with the program charter and the Wave-04 governance chain:

- The root cause has been independently verified.
- The remediation is technically correct and minimal.
- No application source code, database schema, Edge Functions, or Supabase configuration is changed.
- Only Preview environment variables are affected.
- Production isolation is preserved.
- Risks and rollback have been documented.

No governance gate is bypassed.

------------------------------------------------------------------------

## 13. Authorization Decision

**DECISION: AUTHORIZED**

The Preview Environment Remediation is authorized to proceed to execution stage `58B2` under the following conditions:

1. Update only the `preview` Vercel environment variables `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` to the authorized staging values.
2. Leave all `production` Vercel environment variables unchanged.
3. Redeploy Preview from the authorized commit `ce87b9d7`.
4. Re-run `58B` Enterprise Browser Runtime Validation and obtain a PASS.
5. Do not begin Wave-04 Production Deployment Authorization, Wave-04 Production Deployment Synchronization, or Wave-04 Closeout until `58B` passes.

This authorization does **NOT** authorize any implementation, source-code modification, migration, Edge Function deployment, Supabase change, or Production deployment.

------------------------------------------------------------------------

## 14. Stop Rule

This authorization stage is complete. Do **NOT** modify Vercel Environment Variables, redeploy Preview, re-run `58B`, or begin Wave-04 Production Deployment Authorization until `58B2` Preview Environment Remediation is explicitly started by the Program Owner.
