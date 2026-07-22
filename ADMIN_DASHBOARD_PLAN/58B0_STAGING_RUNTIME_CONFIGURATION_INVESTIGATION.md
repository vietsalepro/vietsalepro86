# 58B0_STAGING_RUNTIME_CONFIGURATION_INVESTIGATION

**Document ID:** 58B0_STAGING_RUNTIME_CONFIGURATION_INVESTIGATION  
**Date:** 2026-07-22  
**Project:** VietSalePro  
**Sub Project:** Admin Dashboard  
**Program:** Admin Dashboard System Remediation Program  
**Phase:** B — System Remediation  
**Wave:** Wave-04  
**Acting Capacity:** Enterprise Program Management Office (PMO)  
**Authorized Commit:** `ce87b9d7` (`fix(services,config): Wave-04 residual hardening — canonical read RPCs and check-subdomain verify_jwt`)  

------------------------------------------------------------------------

## 1. Purpose

Investigate the runtime configuration defect discovered during `58B` Enterprise Browser Runtime Validation, in which the authorized STAGING Vercel Preview deployment was observed communicating with the PRODUCTION Supabase project.

This activity is investigation only. No implementation, deployment, environment modification, or configuration change is performed. No Vercel variables are updated. No Supabase changes are made.

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
| Staging Runtime Configuration Investigation | This document | COMPLETE |

Program Owner approval to begin this investigation was received in the current session.

------------------------------------------------------------------------

## 3. Investigation Scope

Determine, with objective evidence, why the Wave-04 STAGING Vercel Preview deployment connects to the PRODUCTION Supabase project instead of the authorized STAGING Supabase project.

Scope:

| # | Area | Method |
|---|---|---|
| 1 | Mandatory governance document review | Read `00`, `12`, `57`, `57A`, `58`, `58A`, `58B`, `58BA` in full |
| 2 | Codebase Memory MCP verification | `index_repository` fast mode + graph drift check |
| 3 | Git repository verification | `git status`, `git diff` |
| 4 | Repository environment files | Read `.env`, `.env.staging`, `.env.example`, search `.env.*` |
| 5 | Codebase environment consumption | Read `lib/supabase.ts`, `lib/supabaseReadReplica.ts`, `vite.config.ts`, `package.json`, `vercel.json` |
| 6 | Vercel project and deployment configuration | Vercel MCP `get_project` / `get_deployment`; Vercel CLI `vercel env list` |
| 7 | Supabase project identity | Supabase MCP `get_project` for staging and production refs |
| 8 | Runtime network evidence | `58BA` HAR artifact and `58BA` report findings |
| 9 | Root cause determination | Trace `VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY` from source to browser request |

No remediation, redeployment, or source change is performed.

------------------------------------------------------------------------

## 4. Investigation Order Executed

1. Mandatory governance document review.
2. Codebase Memory MCP refresh and repository-state verification.
3. Git repository verification.
4. Repository environment file review (`.env`, `.env.staging`, `.env.example`).
5. Codebase environment variable consumption review (`lib/supabase.ts`, `lib/supabaseReadReplica.ts`, `vite.config.ts`, `package.json`).
6. Vercel project, deployment, and environment variable review.
7. Supabase staging and production project identity verification.
8. Runtime network evidence review (`58BA` HAR and report).
9. Environment variable traceability and root cause analysis.
10. Governance document synchronization (`00`, `12`).

------------------------------------------------------------------------

## 5. Investigation Evidence Summary

| Check | Evidence | Result |
|---|---|---|
| `.env` contents | `VITE_SUPABASE_URL=https://rsialbfjswnrkzcxarnj.supabase.co` | Production Supabase URL |
| `.env.staging` contents | `VITE_SUPABASE_URL=https://shbmzvfcenbybvyzclem.supabase.co` | Staging Supabase URL |
| `.env.production` | Not present in repository | Confirmed via `find` |
| `lib/supabase.ts` | Reads `import.meta.env.VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY` | Browser client consumes Vite-injected variables |
| `vite.config.ts` | No custom `envDir` or mode-specific configuration; build is `vite build` | Default Vite production build behavior |
| `package.json` | Build script is `vite build` | No staging build mode invoked |
| Vercel project | `prj_UdCbqGpXxsBXVNGfz0fz02obBS6x` (`vietsalepro`, framework `vite`) | Confirmed |
| Vercel deployment | `dpl_GXrhNbCnqAkZXaZyALmkVb78HUSV`, `READY`, commit `ce87b9d7`, target `null` (Preview) | Confirmed |
| Vercel env vars | `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` configured for `preview` and `production` environments | Encrypted; shared across Preview and Production |
| Supabase projects | `shbmzvfcenbybvyzclem` (Staging) and `rsialbfjswnrkzcxarnj` (Production) both `ACTIVE_HEALTHY` | Confirmed |
| `58BA` HAR | Contains `rsialbfjswnrkzcxarnj.supabase.co` | Preview browser request reached production Supabase |
| `58BA` HAR | No `shbmzvfcenbybvyzclem.supabase.co` references | Preview did not reach staging Supabase |

------------------------------------------------------------------------

## 6. Root Cause Determination

**Root Cause: Incorrect Preview Environment Variables**

The Vercel project environment variables `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` are configured for both `preview` and `production` environments. The values bound to the Preview environment are the production Supabase project credentials (`rsialbfjswnrkzcxarnj.supabase.co`) rather than the authorized staging credentials (`shbmzvfcenbybvyzclem.supabase.co`).

Because `vite build` (default production mode) consumes `VITE_` prefixed variables from the build environment and Vercel injects project environment variables into the Preview build, the browser bundle is compiled with the production Supabase URL and anon key. The repository `.env.staging` is not selected by the build command and is therefore not consumed.

------------------------------------------------------------------------

## 7. Final Decision

**DECISION: ROOT CAUSE VERIFIED**

The STAGING Vercel Preview deployment is wired to the PRODUCTION Supabase project because the Vercel Preview environment variables `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` are configured with production values.

Enterprise Browser Runtime Validation (`58B`) therefore remains **FAIL**. Wave-04 Production Deployment Authorization remains **BLOCKED**. A `58B` re-run is pending environment remediation and explicit Program Owner approval.

------------------------------------------------------------------------

## 8. Stop Rule

This investigation is complete. Do NOT modify Vercel environment variables, redeploy the Preview, modify `.env` files, edit source code, or re-run `58B` without explicit Program Owner approval.

The next governance action is Program Owner authorization of the remediation plan documented in `58B0A_STAGING_RUNTIME_CONFIGURATION_INVESTIGATION_REPORT.md`.
