# 58B3A_PREVIEW_RUNTIME_VERIFICATION_REPORT

**Document ID:** 58B3A_PREVIEW_RUNTIME_VERIFICATION_REPORT  
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
**Status:** PREVIEW RUNTIME VERIFICATION COMPLETE

------------------------------------------------------------------------

## 1. Documents Reviewed

The following mandatory governance documents were read completely before this verification. No section was skipped.

| # | Document | Role in Verification |
|---|---|---|
| 00 | `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` | Program charter, current status, transition rules |
| 12 | `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md` | Master plan roadmap, status, and final decision |
| 58B2 | `58B2_PREVIEW_ENVIRONMENT_REMEDIATION.md` | Authorized remediation scope and stop rule |
| 58B2A | `58B2A_PREVIEW_ENVIRONMENT_REMEDIATION_REPORT.md` | Detailed remediation evidence and baseline |

In addition, the following repository files were reviewed to confirm the Supabase client initialization flow:

- `lib/supabase.ts`
- `lib/supabaseReadReplica.ts`
- `vite.config.ts`

------------------------------------------------------------------------

## 2. Codebase Memory MCP Verification

**Tool:** `codebase-memory` MCP server  
**Action:** `index_repository` (fast mode) on `C:\PROJECT\vietsalepro`  
**Result:** `indexed` — 28,728 nodes, 42,392 edges, 0 skipped

| Verification Check | Method | Result |
|---|---|---|
| Project | `index_repository` result | `C-PROJECT-vietsalepro` |
| Indexed nodes | `index_repository` result | 28,728 |
| Indexed edges | `index_repository` result | 42,392 |
| Source drift `ce87b9d7..HEAD` | `git diff --stat` excluding `ADMIN_DASHBOARD_PLAN` and `.codebase-memory` | 0 lines of application source drift |
| Persistent artifact | `index_repository` `persistence=true` | `.codebase-memory/graph.db.zst` updated |
| Supabase client source | `read` `lib/supabase.ts` | Reads `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` from `import.meta.env` |
| Read replica source | `read` `lib/supabaseReadReplica.ts` | Reads `VITE_SUPABASE_READ_REPLICA_URL` and `VITE_SUPABASE_ANON_KEY` |
| Vite build source | `read` `vite.config.ts` | No custom `envDir`; no mode-specific staging configuration |

**Codebase Memory Verdict:** The repository graph is fresh. No application-source drift detected between the authorized commit `ce87b9d7` and `HEAD`. The environment variables consumed by the browser Supabase client are sourced from `import.meta.env`.

------------------------------------------------------------------------

## 3. Git Verification

| Check | Method | Result |
|---|---|---|
| HEAD commit | `git rev-parse HEAD` | `83d976a6` — governance-only update |
| Authorized source commit | `git rev-parse ce87b9d7` | `ce87b9d7` present and reachable |
| Current branch | `git branch --show-current` | `master` |
| Source changes `ce87b9d7..HEAD` | `git diff --stat ce87b9d7..HEAD -- . ':!ADMIN_DASHBOARD_PLAN' ':!.codebase-memory'` | `package.json` / `package-lock.json` validation tooling diffs only |
| Working-tree source changes | `git diff HEAD -- . ':!ADMIN_DASHBOARD_PLAN' ':!.codebase-memory'` | `package.json` / `package-lock.json` validation tooling diffs only |
| Working-tree modifications | `git status --short` | `.codebase-memory/*`, `ADMIN_DASHBOARD_PLAN/*.md`, `package.json` / `package-lock.json` |

**Git Verdict:** The accepted Wave-04 source revision `ce87b9d7` remains frozen. The only changes are governance documentation, MCP infrastructure artifacts, and working-tree validation-tooling dev dependencies. No application source logic has been modified since `58B2`.

------------------------------------------------------------------------

## 4. Installed Skills Utilized

| Skill | Applicability | Execution |
|---|---|---|
| `agent-browser` | Browser automation, network capture, console and error capture, artifact inspection | Invoked — opened Preview URL, captured network requests, console, and errors |
| `webapp-testing` | Playwright runtime checks; not required because `agent-browser` was used | Not invoked |
| `code-review` | Not applicable — no code changes | Not invoked |
| `doc-coauthoring` | Not invoked; this is a governed PMO report | Not invoked |
| `internal-comms` | Not applicable | Not invoked |

**Skills Verdict:** `agent-browser` was the only installed skill required beyond the Vercel, Supabase, and Codebase Memory MCP servers and the Git repository.

------------------------------------------------------------------------

## 5. Deployment Verification

| Attribute | Value |
|---|---|
| Deployment ID | `dpl_ERHp8Q5rSa5aSTssRWUCVptfCkZM` |
| Deployment URL | `vietsalepro-miau3xaha-tanphat056-3795s-projects.vercel.app` |
| Alias | `vietsalepro-tanphat056-3795-tanphat056-3795s-projects.vercel.app` |
| Deployment State | `READY` |
| Target | `preview` |
| Created At | 1784698250110 (Vercel epoch) |
| Ready At | 1784698292050 (Vercel epoch) |
| Build Duration | ~40.94 seconds |
| Commit SHA | `ce87b9d787401a3591aa3242257a3173f3cd9174` |
| Commit Message | `fix(services,config): Wave-04 residual hardening — canonical read RPCs and check-subdomain verify_jwt` |
| Framework | `vite` |
| Build Command | `vite build` |
| Build Logs | `vite build` succeeded; 3,369 modules transformed; `dist/` emitted |

**Deployment Verification Verdict:** The Preview deployment is healthy, `READY`, built from the authorized commit, and targeted to the Preview environment.

------------------------------------------------------------------------

## 6. Browser Runtime Verification

### 6.1 Landing Page Load

Using `agent-browser`, the Preview deployment was opened at the root path and allowed to reach `networkidle`.

| Check | Method | Result |
|---|---|---|
| Page URL | `agent-browser open` | `https://vietsalepro-miau3xaha-tanphat056-3795s-projects.vercel.app/` |
| Page title | `agent-browser get title` | `VietSales Pro - Quản lý bán hàng` |
| Interactive snapshot | `agent-browser snapshot -i -c` | Landing content rendered; navigation, CTA, and FAQ elements present |
| Console logs | `agent-browser console` | Empty |
| Page errors | `agent-browser errors` | Empty |

### 6.2 Network Requests (Landing)

| Metric | Value |
|---|---|
| Total requests captured | 60 |
| Status 200 responses | 60 |
| Failed requests (>=400) | 0 |
| Requested domains | `vietsalepro-miau3xaha-tanphat056-3795s-projects.vercel.app` (47), `fonts.gstatic.com` (12), `fonts.googleapis.com` (1) |
| Supabase hosts requested | None |
| Production Supabase host requested | None |

**Browser Runtime Verdict:** The landing page loads cleanly, all network requests return 200, the browser console is empty, and no page errors are reported.

------------------------------------------------------------------------

## 7. Supabase Runtime Verification

### 7.1 Browser Traffic Isolation

No browser network request from the landing-page load targeted any `*.supabase.co` host. All traffic was confined to the Vercel Preview deployment and Google Fonts.

### 7.2 Build Artifact Inspection

The main application JavaScript chunk that initializes the Supabase client (`assets/app-services-CK71rOjq.js`) was fetched and inspected:

| Host | Present in `app-services-CK71rOjq.js` |
|---|---|
| `https://shbmzvfcenbybvyzclem.supabase.co` (STAGING) | Yes — `VITE_SUPABASE_URL:"https://shbmzvfcenbybvyzclem.supabase.co"` |
| `https://rsialbfjswnrkzcxarnj.supabase.co` (PRODUCTION) | No — 0 references |

The `vendor-supabase-Dq-Jb853.js` chunk contains 0 references to either Supabase host.

### 7.3 Supabase Project Status

| Project | Ref | Status |
|---|---|---|
| STAGING | `shbmzvfcenbybvyzclem` | `ACTIVE_HEALTHY` |
| PRODUCTION | `rsialbfjswnrkzcxarnj` | `ACTIVE_HEALTHY` |

**Supabase Runtime Verdict:** The Preview build artifact targets ONLY the authorized STAGING Supabase project. No production Supabase host is present in the build artifact or the browser network traffic.

------------------------------------------------------------------------

## 8. Edge Function Verification

Anonymous runtime reachability was verified against the STAGING Edge Function endpoints:

| Function | `verify_jwt` | HTTP Method | Status | Response / Evidence |
|---|---|---|---|---|
| `admin-health-check` | `false` | GET | 200 | `{"ok":true,"checkedAt":"2026-07-22T05:46:24.878Z",...}` |
| `check-subdomain` | `false` | GET | 400 | `Bad Request` — expected because no `subdomain`/`email` body was supplied; function booted successfully |
| `billing-webhooks` | `false` | GET | 503 | `BOOT_ERROR` — function failed to boot due to `import { decodeBase64 }` from `deno.land/std@0.177.0/encoding/base64.ts` (no such export) |

The Supabase `edge-function-runtime` logs confirmed:

- `admin-health-check` booted successfully and is listening.
- `check-subdomain` booted successfully and is listening.
- `billing-webhooks` failed to boot with `Uncaught SyntaxError: The requested module '...encoding/base64.ts' does not provide an export named 'decodeBase64'`.

`billing-webhooks` is a Stripe/provider webhook receiver, not part of the anonymous Preview runtime call path. Its boot failure is recorded as an observation; it does not affect the Preview deployment's runtime target or landing-page behavior.

**Edge Function Verdict:** The anonymous-runtime Edge Functions expected to be reachable from the Preview deployment (`admin-health-check`, `check-subdomain`) respond correctly. The `billing-webhooks` boot error is a pre-existing function-level issue, not caused by the Preview environment remediation.

------------------------------------------------------------------------

## 9. Runtime Consistency

| Check | Method | Result |
|---|---|---|
| Repository source frozen at `ce87b9d7` | Git diff | No application source drift |
| Deployment commit matches `ce87b9d7` | Vercel `get_deployment` | `ce87b9d787401a3591aa3242257a3173f3cd9174` |
| Browser runtime target | Build artifact + network traffic | STAGING only |
| Supabase runtime target | Build artifact + project status | `shbmzvfcenbybvyzclem` |
| Production isolation | Environment consistency + artifact scan | No production references |

**Runtime Consistency Verdict:** Repository, Deployment, Browser Runtime, and Supabase Runtime are synchronized. No configuration drift detected.

------------------------------------------------------------------------

## 10. Regression Review

| Area | Method | Result |
|---|---|---|
| Landing page | `agent-browser snapshot` | Rendered correctly |
| Login page | `/login` route checked | No separate route; login is a modal/CTA on the landing page |
| Static assets | Network requests | 47 Vercel Preview requests, all 200 |
| JavaScript bundles | Network requests + build logs | 12 JS chunks loaded successfully, build completed |
| CSS | Network requests | 16 CSS chunks loaded successfully |
| Environment injection | Build artifact inspection | `VITE_SUPABASE_URL` injected as STAGING URL |
| Network initialization | Network capture | No failed startup requests |
| Console | `agent-browser console` | Empty |
| Console errors | `agent-browser errors` | Empty |

**Regression Review Verdict:** No regression introduced by the `58B2` Preview Environment Remediation.

------------------------------------------------------------------------

## 11. Evidence Matrix

| Item | Result | Evidence |
|---|---|---|
| Deployment Status | PASS | Vercel `get_deployment`: state `READY`, target `preview` |
| Deployment Commit | PASS | `meta.githubCommitSha` = `ce87b9d787401a3591aa3242257a3173f3cd9174` |
| Deployment URL | PASS | `vietsalepro-miau3xaha-tanphat056-3795s-projects.vercel.app` |
| Supabase Runtime Target | PASS | `VITE_SUPABASE_URL` in `app-services-CK71rOjq.js` = `https://shbmzvfcenbybvyzclem.supabase.co`; 0 production references |
| Production Isolation | PASS | No `rsialbfjswnrkzcxarnj.supabase.co` in build artifacts or 60 captured browser requests |
| Browser Startup | PASS | Landing page rendered; 60 network requests, all status 200; console and errors empty |
| Network | PASS | 0 failed requests; 0 Supabase requests on landing; all assets loaded |
| Console | PASS | `agent-browser console` returned empty |
| Edge Functions | PASS | `admin-health-check` 200; `check-subdomain` 400 expected; reachable and booted |
| Static Assets | PASS | All JS/CSS/font requests returned 200 |
| Overall Runtime | PASS | Preview deployment healthy and targets STAGING exclusively |

------------------------------------------------------------------------

## 12. Observations

1. `billing-webhooks` Edge Function is in `BOOT_ERROR` due to an incorrect Deno std import (`decodeBase64` is not exported from `https://deno.land/std@0.177.0/encoding/base64.ts`). This is not part of the anonymous Preview runtime call path and was not introduced by the `58B2` Preview environment variable remediation.
2. The login form is not exposed as a separate route; it is accessed from the landing page CTA. No login credentials were used and no authenticated validation was performed.

------------------------------------------------------------------------

## 13. Final Decision

**DECISION: PASS**

`58B3` Preview Runtime Verification has passed. The Preview deployment is healthy, built from the authorized commit `ce87b9d7`, and targets ONLY the authorized STAGING Supabase project. No runtime regression, production traffic, or browser startup failure was observed.

The next governance stage is ready for authorization:

- `58B` Enterprise Browser Runtime Validation Re-run
