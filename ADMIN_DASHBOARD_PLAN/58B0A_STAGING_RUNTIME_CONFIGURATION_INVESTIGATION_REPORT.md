# 58B0A_STAGING_RUNTIME_CONFIGURATION_INVESTIGATION_REPORT

**Document ID:** 58B0A_STAGING_RUNTIME_CONFIGURATION_INVESTIGATION_REPORT  
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
**Status:** STAGING RUNTIME CONFIGURATION INVESTIGATION COMPLETE — ROOT CAUSE VERIFIED

------------------------------------------------------------------------

## 1. Documents Reviewed

The following mandatory governance documents were read completely before this investigation. No section was skipped.

| # | Document | Role in Investigation |
|---|---|---|
| 00 | `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` | Program charter, lifecycle, transition rules, current status |
| 12 | `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md` | Master Plan status, quality gates, roadmap, final decision |
| 57 | `57_ADMIN_DASHBOARD_WAVE-04_STAGING_DEPLOYMENT_SYNCHRONIZATION.md` | Stage 1 deployment authorization and scope |
| 57A | `57A_STAGING_DEPLOYMENT_SYNCHRONIZATION_REPORT.md` | Stage 1 deployment evidence and traceability |
| 58 | `58_ADMIN_DASHBOARD_WAVE-04_STAGING_DEPLOYMENT_VALIDATION.md` | Stage 2 validation gate and GO WITH OBSERVATIONS |
| 58A | `58A_STAGING_DEPLOYMENT_VALIDATION_REPORT.md` | Stage 2 detailed validation evidence |
| 58B | `58B_ADMIN_DASHBOARD_ENTERPRISE_BROWSER_RUNTIME_VALIDATION.md` | Stage 58B FAIL gate and blocking issue |
| 58BA | `58BA_ENTERPRISE_BROWSER_RUNTIME_VALIDATION_REPORT.md` | Detailed browser runtime evidence, HAR, and failure analysis |

------------------------------------------------------------------------

## 2. Codebase Memory MCP Verification

**Tool:** `codebase-memory` MCP server  
**Action:** `index_repository` (fast mode) on `C:\PROJECT\vietsalepro`  
**Result:** `indexed` — 28,629 nodes, 42,299 edges, 0 skipped  

| Verification Check | Method | Result |
|---|---|---|
| Project | `index_repository` result | `C-PROJECT-vietsalepro` |
| Indexed nodes | `index_repository` result | 28,629 |
| Indexed edges | `index_repository` result | 42,299 |
| Source drift `ce87b9d7..HEAD` | `git diff` | None outside `ADMIN_DASHBOARD_PLAN` and `.codebase-memory` |
| Persistent artifact | `index_repository` `persistence=true` | `.codebase-memory/graph.db.zst` updated |
| Supabase client source | `read` `lib/supabase.ts` | Reads `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` from `import.meta.env` |
| Read replica source | `read` `lib/supabaseReadReplica.ts` | Reads `VITE_SUPABASE_READ_REPLICA_URL` and `VITE_SUPABASE_ANON_KEY` |
| Vite build source | `read` `vite.config.ts` | No custom `envDir`; no mode-specific staging configuration |

**Codebase Memory Verdict:** The repository graph is fresh. No application-source drift detected between the authorized commit `ce87b9d7` and `HEAD`. The environment variables relevant to the browser Supabase client are consumed in `lib/supabase.ts` and `lib/supabaseReadReplica.ts`.

------------------------------------------------------------------------

## 3. Git Verification

| Check | Method | Result |
|---|---|---|
| HEAD commit | `git rev-parse HEAD` | `a12ed302` — governance-only update after `57`/`58`/`58B` |
| Authorized source commit | `git rev-parse ce87b9d7` | `ce87b9d7` present and reachable |
| Current branch | `git branch --show-current` | `master` |
| Source changes `ce87b9d7..HEAD` | `git diff --stat ce87b9d7..HEAD -- . ':!ADMIN_DASHBOARD_PLAN' ':!.codebase-memory'` | 0 lines — no source drift |
| Working-tree source changes | `git diff HEAD -- . ':!ADMIN_DASHBOARD_PLAN' ':!.codebase-memory'` | 0 lines |
| Working-tree modifications | `git status --short` | `.codebase-memory/*` (MCP re-index), `ADMIN_DASHBOARD_PLAN/*.md` governance deliverables |

**Git Verdict:** The accepted Wave-04 source revision `ce87b9d7` remains frozen. The only changes are governance documentation and MCP infrastructure artifacts. This investigation introduced no source modifications.

------------------------------------------------------------------------

## 4. Installed Skills Utilized

| Skill | Applicability | Execution |
|---|---|---|
| `agent-browser` | Browser automation; not needed for this configuration-only investigation | Not invoked |
| `webapp-testing` | Playwright runtime checks; not needed for this investigation | Not invoked |
| `code-review` | Not applicable — no code changes | Not invoked |
| `doc-coauthoring` | Not invoked; this is a governed PMO report | Not invoked |
| `internal-comms` | Not applicable — no internal communication artifact requested | Not invoked |

**Skills Verdict:** No installed skill provided a capability beyond the Vercel, Supabase, and Codebase Memory MCP servers and the Vercel CLI that improved this configuration investigation. The investigation relied on direct repository reads, MCP queries, and Vercel CLI read-only commands.

------------------------------------------------------------------------

## 5. Repository Environment Review

| File | Check | Value | Status |
|---|---|---|---|
| `.env` | Present | `VITE_SUPABASE_URL=https://rsialbfjswnrkzcxarnj.supabase.co` | Production Supabase URL |
| `.env` | Present | `VITE_SUPABASE_ANON_KEY` (redacted) | Production anon key |
| `.env.staging` | Present | `VITE_SUPABASE_URL=https://shbmzvfcenbybvyzclem.supabase.co` | Staging Supabase URL |
| `.env.staging` | Present | `VITE_SUPABASE_ANON_KEY` (redacted) | Staging anon key |
| `.env.example` | Present | Contains AI orchestrator template comments only; no Supabase variables | Not applicable |
| `.env.production` | Searched | Not present in repository | Confirmed via `find_file_by_name` |
| `.env.*` files | Searched | Only `.env`, `.env.example`, `.env.staging` found | No `.env.local`, `.env.development`, `.env.preview` |

**Repository Environment Verdict:** The repository contains a production `.env` file and a staging `.env.staging` file. There is no `.env.production` file and no environment selection logic that would cause `vite build` to load `.env.staging`.

------------------------------------------------------------------------

## 6. Codebase Environment Review

### 6.1 Browser Supabase Client (`lib/supabase.ts`)

```ts
const env = (import.meta as any).env ?? (typeof process !== 'undefined' ? process.env : {});
const supabaseUrl = env?.VITE_SUPABASE_URL as string | undefined;
const supabaseAnonKey = env?.VITE_SUPABASE_ANON_KEY as string | undefined;
```

The browser Supabase client is constructed from `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`. These are Vite-injected environment variables; the values are resolved at build time and embedded in the client bundle.

### 6.2 Read Replica Client (`lib/supabaseReadReplica.ts`)

```ts
const env = (import.meta as any).env ?? (typeof process !== 'undefined' ? process.env : {});
const readReplicaUrl = env?.VITE_SUPABASE_READ_REPLICA_URL as string | undefined;
const supabaseAnonKey = env?.VITE_SUPABASE_ANON_KEY as string | undefined;
```

The read replica client also depends on `VITE_SUPABASE_ANON_KEY`. This key must match the primary Supabase project key.

### 6.3 Vite Configuration (`vite.config.ts`)

- No `envDir` override.
- No `envPrefix` override.
- No custom mode (`staging`) configuration.
- `server.port` is `3000`; `host` is `0.0.0.0`.

### 6.4 Build Script (`package.json`)

```json
"build": "vite build"
```

The build command is the default `vite build` (mode `production`). Vite's default behavior for `vite build` is to load `.env` and `.env.production` (and their `.local` variants), not `.env.staging`.

**Codebase Environment Verdict:** The application expects `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` to be injected at build time. The repository does not contain logic to switch to `.env.staging` for preview builds, and the build command does not select a staging mode.

------------------------------------------------------------------------

## 7. Vercel Configuration Review

**MCP server:** `vercel`  
**Team:** `team_5jIBUrVn2CmOrkSojeJZZqoP`  
**Project:** `prj_UdCbqGpXxsBXVNGfz0fz02obBS6x` (`vietsalepro`, `vite`)

| Check | Method | Result |
|---|---|---|
| Project framework | `get_project` | `vite` |
| Project node version | `get_project` | `24.x` |
| Latest preview deployment | `get_project` / `get_deployment` | `dpl_GXrhNbCnqAkZXaZyALmkVb78HUSV` |
| Deployment URL | `get_deployment` | `vietsalepro-8vzldgvj8-tanphat056-3795s-projects.vercel.app` |
| Deployment state | `get_deployment` | `READY` |
| Deployment commit | `get_deployment` `githubCommitSha` | `ce87b9d787401a3591aa3242257a3173f3cd9174` (matches `ce87b9d7`) |
| Deployment source | `get_deployment` | `cli` |
| Deployment target | `get_deployment` `target` | `null` (Preview deployment) |
| Build command | Build logs | `vite build` |
| Vercel env vars | `vercel env list` (JSON) | `VITE_SUPABASE_URL` configured for `preview` and `production` |
| Vercel env vars | `vercel env list` (JSON) | `VITE_SUPABASE_ANON_KEY` configured for `preview` and `production` |
| Development env vars | `vercel env list development` | Empty |

### 7.1 Vercel Environment Variables Detail

```json
{
  "envs": [
    {
      "key": "VITE_SUPABASE_URL",
      "type": "sensitive",
      "target": ["preview", "production"],
      "configurationId": null,
      "createdAt": 1783584634660,
      "updatedAt": 1783584634660
    },
    {
      "key": "VITE_SUPABASE_ANON_KEY",
      "type": "sensitive",
      "target": ["preview", "production"],
      "configurationId": null,
      "createdAt": 1783584634660,
      "updatedAt": 1783584634660
    }
  ]
}
```

The values are encrypted and are the same across `preview` and `production` environments (single variable entry targets both). Vercel `env list` (human-readable) also reports these variables as `Encrypted` and assigned to `Preview, Production`.

**Vercel Configuration Verdict:** The Vercel project has `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` configured for Preview deployments. Because the values are shared with Production and encrypted, and because the runtime HAR points to the production Supabase project, the Preview environment is bound to production Supabase credentials.

------------------------------------------------------------------------

## 8. Supabase Configuration Review

**MCP server:** `supabase-mcp-server`

| Check | Method | Result |
|---|---|---|
| List projects | `list_projects` | `rsialbfjswnrkzcxarnj` (QLBH) and `shbmzvfcenbybvyzclem` (QLBH Staging Multi-Tenant) |
| Production project | `get_project` `rsialbfjswnrkzcxarnj` | `ACTIVE_HEALTHY`, Postgres `17.6.1.084`, region `ap-northeast-1` |
| Staging project | `get_project` `shbmzvfcenbybvyzclem` | `ACTIVE_HEALTHY`, Postgres `17.6.1.141`, region `ap-northeast-1` |
| Authorized staging URL | `.env.staging` / Supabase `get_project` | `https://shbmzvfcenbybvyzclem.supabase.co` |
| Production URL | `.env` / Supabase `get_project` | `https://rsialbfjswnrkzcxarnj.supabase.co` |

**Supabase Configuration Verdict:** Both Supabase projects are healthy. The staging project `shbmzvfcenbybvyzclem` is the authorized staging target per `.env.staging` and prior governance documents (`57A`, `58A`). The production project `rsialbfjswnrkzcxarnj` is the authorized production target per `.env` and the `SINGLE_OWNER_RELEASE_AUTHORIZATION.md`.

------------------------------------------------------------------------

## 9. Runtime Configuration Review

### 9.1 Vercel Deployment Build Logs

Build command executed on Vercel:

```text
> vietsales-pro-ver-2@0.0.0 build
> vite build

vite v6.4.1 building for production...
```

The build runs in Vite's default production mode. No `--mode staging` or custom env directory is used.

### 9.2 Browser Network Evidence (`58BA` HAR)

The HAR captured during `58B` Enterprise Browser Runtime Validation (`ADMIN_DASHBOARD_PLAN/58B_browser_artifacts/58B_pw_home.har`) contains the production Supabase project reference `rsialbfjswnrkzcxarnj.supabase.co` and does not contain the staging reference `shbmzvfcenbybvyzclem.supabase.co`.

This confirms that the JavaScript bundle served by the Vercel Preview deployment was built with `VITE_SUPABASE_URL` pointing to `rsialbfjswnrkzcxarnj.supabase.co`.

### 9.3 `58BA` Authentication Finding

`58BA` Section 8 states:

> The invalid-credential request was sent to the **production** Supabase project (`rsialbfjswnrkzcxarnj.supabase.co`) instead of the authorized **staging** project (`shbmzvfcenbybvyzclem.supabase.co`). This means the Vercel preview deployment is configured with the production `VITE_SUPABASE_URL`/`VITE_SUPABASE_ANON_KEY` values from `.env` rather than the staging values from `.env.staging`.

**Runtime Configuration Verdict:** The deployed preview bundle is hard-wired to the production Supabase project. The staging Supabase project is not referenced in the bundle or in the browser network trace.

------------------------------------------------------------------------

## 10. Environment Variable Traceability

The browser Supabase URL and anon key flow as follows:

```text
Vercel Project Env (Preview) ─── VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY
         │
         │  Vercel injects into build env at `vite build` time
         ▼
       Vite bundles values into `import.meta.env`
         │
         ▼
   lib/supabase.ts reads values at runtime
         │
         ▼
   Browser POSTs auth request to the embedded Supabase URL
```

For the Wave-04 staging preview, the Vercel Preview environment provided production Supabase credentials, so the browser requested `https://rsialbfjswnrkzcxarnj.supabase.co`.

The repository `.env.staging` is not on this path for a default `vite build` because:

1. `vite build` default mode is `production`.
2. Vite loads `.env` and `.env.production` (and `.local` variants) for mode `production`.
3. `.env.production` does not exist, so only `.env` is loaded.
4. Vercel project environment variables override `.env` values.
5. Vercel Preview variables are shared with Production, so Preview receives the same values as Production.

Therefore the staging values in `.env.staging` are never consumed by the Preview build.

------------------------------------------------------------------------

## 11. Root Cause Analysis

**Verified Root Cause:** Incorrect Preview Environment Variables

The Vercel project environment variables `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` are configured for the `preview` environment with values that resolve to the **production** Supabase project (`rsialbfjswnrkzcxarnj`). Because the same variable entries also target `production`, Preview and Production share the same Supabase credentials.

This is not a source-code bug, a build-target error, or a branch-mapping defect. The `vite build` command and Vite configuration are standard. The issue is that the build-time environment provided to the Preview deployment is not isolated to the staging Supabase project.

Contributing observations:

- The repository `.env` file already contains production credentials; it is not overridden for Preview.
- The repository `.env.staging` file exists but is not consumed by `vite build` without a custom mode or build command.
- No `.env.production` file exists to override `.env`.
- Vercel's project environment variables are the authoritative source for the Preview build and currently point to production.

------------------------------------------------------------------------

## 12. Evidence

| # | Evidence | Source | Conclusion |
|---|---|---|---|
| 1 | `.env` contains `VITE_SUPABASE_URL=https://rsialbfjswnrkzcxarnj.supabase.co` | Repository file read | Production credentials in default env file |
| 2 | `.env.staging` contains `VITE_SUPABASE_URL=https://shbmzvfcenbybvyzclem.supabase.co` | Repository file read | Staging credentials present but not consumed |
| 3 | `lib/supabase.ts` reads `VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY` from `import.meta.env` | Repository file read | Browser client depends on Vite-injected variables |
| 4 | `vite.config.ts` has no env mode override | Repository file read | Default `vite build` loads `.env` and `.env.production` |
| 5 | `package.json` build script is `vite build` | Repository file read | No staging build mode |
| 6 | Vercel project `vietsalepro` framework `vite` | Vercel MCP `get_project` | Correct project, correct framework |
| 7 | Preview deployment `dpl_GXrhNbCnqAkZXaZyALmkVb78HUSV` is `READY` from `ce87b9d7` | Vercel MCP `get_deployment` | Authorized commit deployed to preview |
| 8 | Vercel env vars `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` target `preview` and `production` | Vercel CLI `vercel env list` (JSON) | Preview env is configured |
| 9 | Vercel env values are `sensitive` / `Encrypted` | Vercel CLI output | Values not visible, but runtime confirms project |
| 10 | Staging project `shbmzvfcenbybvyzclem` is `ACTIVE_HEALTHY` | Supabase MCP `get_project` | Authorized staging target exists and is healthy |
| 11 | Production project `rsialbfjswnrkzcxarnj` is `ACTIVE_HEALTHY` | Supabase MCP `get_project` | Production target is the one being reached |
| 12 | HAR `58B_pw_home.har` contains `rsialbfjswnrkzcxarnj.supabase.co` | `58BA` artifact | Preview browser reached production Supabase |
| 13 | HAR `58B_pw_home.har` does not contain `shbmzvfcenbybvyzclem` | `58BA` artifact | Preview browser did not reach staging Supabase |
| 14 | `58BA` report records login POST to `rsialbfjswnrkzcxarnj.supabase.co` | `58BA` Section 8 | Independent confirmation of runtime defect |

------------------------------------------------------------------------

## 13. Recommended Remediation

**This investigation does NOT perform remediation.** The following actions are recommended for Program Owner approval and subsequent execution:

1. **Update Vercel Preview environment variables.**
   - Set `VITE_SUPABASE_URL` for the `preview` environment to `https://shbmzvfcenbybvyzclem.supabase.co` (matching `.env.staging`).
   - Set `VITE_SUPABASE_ANON_KEY` for the `preview` environment to the staging anon key (matching `.env.staging`).
   - Ensure these values are scoped **only** to `preview` and do not affect the `production` environment.

2. **Preserve Production environment variables.**
   - Keep `VITE_SUPABASE_URL` for `production` pointing to `https://rsialbfjswnrkzcxarnj.supabase.co`.
   - Keep `VITE_SUPABASE_ANON_KEY` for `production` unchanged.

3. **Redeploy the preview.**
   - Redeploy from the authorized commit `ce87b9d7` to a new Preview deployment.
   - Verify the new deployment ID and URL before proceeding to validation.

4. **Re-run `58B` Enterprise Browser Runtime Validation.**
   - Before attempting authenticated browser validation, display `PROGRAM OWNER ACTION REQUIRED` and request valid STAGING System Administrator credentials.
   - Do not invent, reuse, or expose credentials.
   - Use the provided credentials only for the current validation session.
   - Redact all sensitive values from reports, screenshots, logs, HAR files, and generated documentation.

5. **Consider future build hygiene (optional).**
   - If the team wants the repository to drive staging builds without Vercel env overrides, introduce a `build:staging` script (e.g., `vite build --mode staging`) and ensure `.env.staging` is used. This is outside the scope of the immediate remediation.

------------------------------------------------------------------------

## 14. Roadmap Updates

| Item | Prior Value | Updated Value |
|---|---|---|
| Current milestone | `58B` Enterprise Browser Runtime Validation COMPLETE (FAIL) | `58B0` Staging Runtime Configuration Investigation COMPLETE; `58B` FAIL root cause verified |
| Current blocker | Staging preview wired to production Supabase (unknown cause) | Vercel Preview `VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY` configured with production values |
| Next governance action | Investigate staging runtime configuration | Program Owner approval to remediate Vercel Preview env variables and re-run `58B` |
| `58B` status | FAIL | FAIL (pending environment remediation and re-run) |
| Wave-04 Production Deployment Authorization | BLOCKED | BLOCKED (remediation and passing `58B` re-run required) |
| Wave-04 Production Deployment Synchronization | NOT AUTHORIZED | NOT AUTHORIZED |
| Wave-04 Closeout | BLOCKED BY DEPLOYMENT SYNCHRONIZATION | BLOCKED BY DEPLOYMENT SYNCHRONIZATION |

------------------------------------------------------------------------

## 15. Program Status Updates

`00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` and `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md` are synchronized with the following status:

- `58B0` Staging Runtime Configuration Investigation: **COMPLETE**.
- `58B` Enterprise Browser Runtime Validation: **COMPLETE (FAIL)**; root cause is **VERIFIED**.
- `58B` Re-run: **PENDING ENVIRONMENT REMEDIATION**.
- Wave-04 Production Deployment Authorization: **BLOCKED BY 58B FAIL**.
- Wave-04 Production Deployment Synchronization: **NOT AUTHORIZED**.
- Wave-04 Closeout: **BLOCKED BY DEPLOYMENT SYNCHRONIZATION**.
- Overall Program Status: **NOT READY FOR WAVE-04 PRODUCTION DEPLOYMENT AUTHORIZATION**.

------------------------------------------------------------------------

## 16. Final Conclusion

**ROOT CAUSE VERIFIED**

The STAGING Vercel Preview deployment is communicating with the PRODUCTION Supabase project because the Vercel Preview environment variables `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` are configured with production Supabase credentials. The repository `.env.staging` staging credentials are not consumed by the default `vite build` command, and the Vercel Preview build does not override the production values with staging values.

No source-code defect was found. The remediation is an environment-configuration change in Vercel, followed by a Preview redeployment and a `58B` re-run.

This investigation is complete. No Vercel variables, `.env` files, source code, or Supabase configuration have been modified. Program Owner approval is required before any remediation activity.
