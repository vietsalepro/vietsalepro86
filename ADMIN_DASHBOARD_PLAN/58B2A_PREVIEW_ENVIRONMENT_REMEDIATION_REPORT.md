# 58B2A_PREVIEW_ENVIRONMENT_REMEDIATION_REPORT

**Document ID:** 58B2A_PREVIEW_ENVIRONMENT_REMEDIATION_REPORT  
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
**Status:** PREVIEW ENVIRONMENT REMEDIATION COMPLETE

------------------------------------------------------------------------

## 1. Documents Reviewed

The following mandatory governance documents were read completely before this remediation. No section was skipped.

| # | Document | Role in Remediation |
|---|---|---|
| 00 | `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` | Program charter, lifecycle, transition rules, current status |
| 12 | `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md` | Master Plan status, quality gates, roadmap, final decision |
| 58B0 | `58B0_STAGING_RUNTIME_CONFIGURATION_INVESTIGATION.md` | Investigation authorization, scope, and root cause finding |
| 58B0A | `58B0A_STAGING_RUNTIME_CONFIGURATION_INVESTIGATION_REPORT.md` | Detailed root cause evidence and recommended remediation |
| 58B1 | `58B1_PREVIEW_ENVIRONMENT_REMEDIATION_AUTHORIZATION.md` | Remediation authorization decision |
| 58B1A | `58B1A_PREVIEW_ENVIRONMENT_REMEDIATION_AUTHORIZATION_REPORT.md` | Detailed authorization evidence and approved scope |

In addition, the following repository files were reviewed to confirm the environment variable flow:

- `lib/supabase.ts`
- `lib/supabaseReadReplica.ts`
- `vite.config.ts`
- `package.json`
- `.env`
- `.env.staging`

------------------------------------------------------------------------

## 2. Codebase Memory MCP Verification

**Tool:** `codebase-memory` MCP server  
**Action:** `index_repository` (fast mode) on `C:\PROJECT\vietsalepro`  
**Result:** `indexed` — 28,700 nodes, 42,366 edges, 0 skipped

| Verification Check | Method | Result |
|---|---|---|
| Project | `index_repository` result | `C-PROJECT-vietsalepro` |
| Indexed nodes | `index_repository` result | 28,700 |
| Indexed edges | `index_repository` result | 42,366 |
| Source drift `ce87b9d7..HEAD` | `git diff --stat` excluding `ADMIN_DASHBOARD_PLAN` and `.codebase-memory` | 0 lines — no source drift |
| Persistent artifact | `index_repository` `persistence=true` | `.codebase-memory/graph.db.zst` updated |
| Supabase client source | `read` `lib/supabase.ts` | Reads `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` from `import.meta.env` |
| Read replica source | `read` `lib/supabaseReadReplica.ts` | Reads `VITE_SUPABASE_READ_REPLICA_URL` and `VITE_SUPABASE_ANON_KEY` (same key as primary) |
| Vite build source | `read` `vite.config.ts` | No custom `envDir`; no mode-specific staging configuration |

**Codebase Memory Verdict:** The repository graph is fresh. No application-source drift detected between the authorized commit `ce87b9d7` and `HEAD`. The environment variables relevant to the browser Supabase client are consumed in `lib/supabase.ts` and `lib/supabaseReadReplica.ts`. This remediation introduced no source modifications.

------------------------------------------------------------------------

## 3. Git Verification

| Check | Method | Result |
|---|---|---|
| HEAD commit | `git rev-parse HEAD` | `83d976a6` — governance-only update |
| Authorized source commit | `git rev-parse ce87b9d7` | `ce87b9d7` present and reachable |
| Current branch | `git branch --show-current` | `master` |
| Source changes `ce87b9d7..HEAD` | `git diff --stat ce87b9d7..HEAD -- . ':!ADMIN_DASHBOARD_PLAN' ':!.codebase-memory'` | 0 lines — no source drift |
| Working-tree source changes | `git diff HEAD -- . ':!ADMIN_DASHBOARD_PLAN' ':!.codebase-memory'` | `package.json` and `package-lock.json` contain Playwright validation-tooling diffs only; no application logic drift |
| Working-tree modifications | `git status --short` | `ADMIN_DASHBOARD_PLAN/*.md` governance deliverables; `.codebase-memory/*` MCP re-index artifacts; `package.json` / `package-lock.json` validation tooling diffs |

**Git Verdict:** The accepted Wave-04 source revision `ce87b9d7` remains frozen. The only changes are governance documentation, MCP infrastructure artifacts, and working-tree validation-tooling dev dependencies. No application source has been modified by this remediation.

------------------------------------------------------------------------

## 4. Installed Skills Utilized

| Skill | Applicability | Execution |
|---|---|---|
| `agent-browser` | Browser network traffic capture for runtime target verification | Invoked — opened Preview URL and captured network requests to Supabase endpoints |
| `webapp-testing` | Playwright runtime checks; not required because `agent-browser` was used | Not invoked |
| `code-review` | Not applicable — no code changes | Not invoked |
| `doc-coauthoring` | Not invoked; this is a governed PMO report | Not invoked |
| `internal-comms` | Not applicable | Not invoked |

**Skills Verdict:** `agent-browser` was the only installed skill required beyond the Vercel, Supabase, and Codebase Memory MCP servers, the Vercel CLI, and the Git repository.

------------------------------------------------------------------------

## 5. Pre-Change Baseline

| Attribute | Value |
|---|---|
| Previous Preview deployment ID | `dpl_GXrhNbCnqAkZXaZyALmkVb78HUSV` |
| Previous Preview URL | `vietsalepro-8vzldgvj8-tanphat056-3795s-projects.vercel.app` |
| Previous Preview commit | `ce87b9d7` |
| `VITE_SUPABASE_URL` target | `preview`, `production` (shared) |
| `VITE_SUPABASE_ANON_KEY` target | `preview`, `production` (shared) |
| Previous Preview runtime target | `https://rsialbfjswnrkzcxarnj.supabase.co` (PRODUCTION Supabase) |
| Evidence source | `58BA_ENTERPRISE_BROWSER_RUNTIME_VALIDATION_REPORT.md` HAR |

**Pre-Change Baseline Verdict:** The Preview environment was wired to the PRODUCTION Supabase project (`rsialbfjswnrkzcxarnj.supabase.co`) because the Vercel Preview environment variables were shared with Production and contained production credentials.

------------------------------------------------------------------------

## 6. Preview Environment Variable Update

**Authorized staging values (from `.env.staging`):**

| Variable | `.env.staging` value (redacted) |
|---|---|
| `VITE_SUPABASE_URL` | `https://shbmzvfcenbybvyzclem.supabase.co` |
| `VITE_SUPABASE_ANON_KEY` | `[REDACTED]` |

**Vercel CLI commands executed:**

```text
vercel env add VITE_SUPABASE_URL production --value [REDACTED] --sensitive --yes --project prj_UdCbqGpXxsBXVNGfz0fz02obBS6x --scope team_5jIBUrVn2CmOrkSojeJZZqoP --non-interactive
vercel env add VITE_SUPABASE_URL preview --value [REDACTED] --sensitive --yes --project prj_UdCbqGpXxsBXVNGfz0fz02obBS6x --scope team_5jIBUrVn2CmOrkSojeJZZqoP --non-interactive
vercel env add VITE_SUPABASE_ANON_KEY production --value [REDACTED] --sensitive --yes --project prj_UdCbqGpXxsBXVNGfz0fz02obBS6x --scope team_5jIBUrVn2CmOrkSojeJZZqoP --non-interactive
vercel env add VITE_SUPABASE_ANON_KEY preview --value [REDACTED] --sensitive --yes --project prj_UdCbqGpXxsBXVNGfz0fz02obBS6x --scope team_5jIBUrVn2CmOrkSojeJZZqoP --non-interactive
```

**Post-update verification (`vercel env list preview -F json` and `vercel env list production -F json`):**

| Environment | `VITE_SUPABASE_URL` target | `VITE_SUPABASE_ANON_KEY` target |
|---|---|---|
| Preview | `preview` only | `preview` only |
| Production | `production` only | `production` only |

**Environment Variable Update Verdict:** The Preview environment variables are now bound to the authorized STAGING Supabase project. The Production variables are isolated and unchanged. Sensitive values are stored encrypted and redacted from this report.

------------------------------------------------------------------------

## 7. Deployment Execution

| Step | Action | Result |
|---|---|---|
| Source checkout | `git worktree add` of `ce87b9d7` to `C:\Users\Admin\AppData\Local\Temp\vietsalepro-ce87b9d7` | Successful (detached HEAD at `ce87b9d7`) |
| Preview redeploy | `vercel deploy <worktree> --target preview --project prj_UdCbqGpXxsBXVNGfz0fz02obBS6x --scope team_5jIBUrVn2CmOrkSojeJZZqoP --yes --non-interactive -F json --no-wait` | Deployment created |
| Deployment ID | Vercel output | `dpl_ERHp8Q5rSa5aSTssRWUCVptfCkZM` |
| Deployment URL | Vercel output | `vietsalepro-miau3xaha-tanphat056-3795s-projects.vercel.app` |
| Commit SHA | `get_deployment` MCP result | `ce87b9d787401a3591aa3242257a3173f3cd9174` |
| Build command | `vite build` | Completed |
| Build duration | `get_deployment` `ready` - `buildingAt` | ~40.94 seconds |
| Final state | `vercel inspect ... --wait` | `READY` |

**Deployment Execution Verdict:** A new Preview deployment was built from the authorized commit `ce87b9d7` using the updated Preview environment variables.

------------------------------------------------------------------------

## 8. Deployment Verification

| Check | Method | Result |
|---|---|---|
| Deployment state | Vercel MCP `get_deployment` | `READY` |
| Target | Vercel `vercel inspect` JSON | `preview` |
| Deployment URL | `get_deployment` | `vietsalepro-miau3xaha-tanphat056-3795s-projects.vercel.app` |
| Commit SHA | `get_deployment` `meta.githubCommitSha` | `ce87b9d787401a3591aa3242257a3173f3cd9174` |
| Build logs | Vercel MCP `get_deployment_build_logs` | `vite build` succeeded; 3369 modules transformed; `dist/` emitted |
| Aliases | `get_deployment` | `vietsalepro-tanphat056-3795-tanphat056-3795s-projects.vercel.app` |

**Deployment Verification Verdict:** The new Preview deployment is healthy, built from the authorized commit, and has the correct Preview target.

------------------------------------------------------------------------

## 9. Runtime Target Verification

### 9.1 Browser Network Traffic

Using `agent-browser`, the Preview deployment was opened, an unauthenticated login form interaction was performed with invalid credentials, and network requests were captured.

**Captured Supabase requests (filtered):**

```text
[518C0D0C5FB91D1C0B04ED87242C264F] OPTIONS https://shbmzvfcenbybvyzclem.supabase.co/auth/v1/token?grant_type=password (Other) 200
[11756.363] POST https://shbmzvfcenbybvyzclem.supabase.co/auth/v1/token?grant_type=password (Fetch) 400
[11756.364] POST https://shbmzvfcenbybvyzclem.supabase.co/rest/v1/rpc/record_admin_login (Fetch) 401
[0EAAF02295981F1ACB02D1374EED4274] OPTIONS https://shbmzvfcenbybvyzclem.supabase.co/rest/v1/rpc/record_admin_login (Other) 200
```

**Absent requests:** No network requests to `https://rsialbfjswnrkzcxarnj.supabase.co` were observed.

### 9.2 Build Artifact Inspection

The main application JavaScript chunk that initializes the Supabase client (`assets/app-services-CK71rOjq.js`) was downloaded and inspected:

| Host | Present in `app-services-CK71rOjq.js` |
|---|---|
| `https://shbmzvfcenbybvyzclem.supabase.co` (STAGING) | Yes |
| `https://rsialbfjswnrkzcxarnj.supabase.co` (PRODUCTION) | No |

**Runtime Target Verdict:** The Preview deployment now targets the authorized STAGING Supabase project (`shbmzvfcenbybvyzclem.supabase.co`). No production Supabase host is present in build artifacts or browser network traffic.

------------------------------------------------------------------------

## 10. Environment Consistency Review

| Check | Method | Result |
|---|---|---|
| Preview `VITE_SUPABASE_URL` target | `vercel env list preview` | `preview` only, staging URL |
| Preview `VITE_SUPABASE_ANON_KEY` target | `vercel env list preview` | `preview` only, staging key |
| Production `VITE_SUPABASE_URL` target | `vercel env list production` | `production` only, production URL |
| Production `VITE_SUPABASE_ANON_KEY` target | `vercel env list production` | `production` only, production key |
| Repository source drift | `git diff ce87b9d7..HEAD` excluding `ADMIN_DASHBOARD_PLAN` and `.codebase-memory` | 0 lines |
| `.env` files | Read `.env`, `.env.staging` | Unchanged from baseline |
| Supabase project identity | Supabase MCP `get_project` (staging and production) | `shbmzvfcenbybvyzclem` and `rsialbfjswnrkzcxarnj` both `ACTIVE_HEALTHY` |
| Production deployment | `get_project` `live` flag | `live: false` — no production redeployment occurred |

**Environment Consistency Verdict:** Preview uses STAGING Supabase. Production variables are isolated and unchanged. Repository source is unchanged. No configuration drift or deployment drift detected.

------------------------------------------------------------------------

## 11. Rollback Verification

**Rollback procedure:**

1. The previous Preview deployment `dpl_GXrhNbCnqAkZXaZyALmkVb78HUSV` remains available at `vietsalepro-8vzldgvj8-tanphat056-3795s-projects.vercel.app`.
2. If required, the Preview environment variables can be restored by running:
   - `vercel env rm VITE_SUPABASE_URL preview --yes` and `vercel env add VITE_SUPABASE_URL preview,production --value [REDACTED] --sensitive --yes`
   - `vercel env rm VITE_SUPABASE_ANON_KEY preview --yes` and `vercel env add VITE_SUPABASE_ANON_KEY preview,production --value [REDACTED] --sensitive --yes`
3. The previous Preview deployment can be re-aliased or redeployed from `ce87b9d7` if necessary.

**Rollback Verdict:** Rollback path is documented and the previous Preview deployment remains available.

------------------------------------------------------------------------

## 12. Roadmap Updates

The following governance documents were synchronized:

| Document | Updates Applied |
|---|---|
| `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` | `58B2 Preview Environment Remediation` marked `COMPLETE`; `58B3 Preview Runtime Verification` marked `READY TO START`; `Program Status` updated to `READY FOR PREVIEW RUNTIME VERIFICATION` |
| `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md` | Roadmap, status table, final decision, and next governance action updated to reflect `58B2 COMPLETE` and `58B3 READY TO START` |

------------------------------------------------------------------------

## 13. Program Status Updates

| Gate | New Status |
|---|---|
| 58B2 Preview Environment Remediation | **COMPLETE** |
| 58B3 Preview Runtime Verification | **READY TO START** |
| Program Status | **READY FOR PREVIEW RUNTIME VERIFICATION** |

**Stop Rule:** Do NOT begin `58B3` Preview Runtime Verification without explicit Program Owner approval. Do NOT begin `58B` Re-run. Do NOT request STAGING administrator credentials.

------------------------------------------------------------------------

## 14. Final Decision

**DECISION: REMEDIATION COMPLETE**

The authorized Preview Environment Remediation has been executed successfully:

- Preview-only `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` have been updated to the authorized STAGING Supabase values from `.env.staging`.
- Production environment variables remain unchanged and isolated.
- The Preview has been redeployed from the authorized commit `ce87b9d7`.
- The new Preview deployment reached `READY` state.
- Browser network traffic confirms the Preview runtime now targets `https://shbmzvfcenbybvyzclem.supabase.co` and does not target `https://rsialbfjswnrkzcxarnj.supabase.co`.
- No application source code, `.env` files, Supabase configuration, or Production environment variables were modified.
- Roadmaps and the Program Charter are synchronized.

The next governance action is `58B3` Preview Runtime Verification, which requires explicit Program Owner authorization before it can begin.
