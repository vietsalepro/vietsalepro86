# 58B_ADMIN_DASHBOARD_ENTERPRISE_BROWSER_RUNTIME_VALIDATION

**Document ID:** 58B_ADMIN_DASHBOARD_ENTERPRISE_BROWSER_RUNTIME_VALIDATION  
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

Perform a complete browser-based operational validation of the Wave-04 STAGING deployment. This is a supplemental validation gate (58B) intended to replace the environment-related observation in `58A` with direct browser evidence.

This stage SHALL NOT perform any new implementation.  
This stage SHALL NOT modify application source code.  
This stage SHALL NOT execute database migrations.  
This stage SHALL NOT deploy Edge Functions.  
This stage SHALL NOT deploy Vercel.  
This stage SHALL only validate the existing STAGING deployment through real browser execution.

------------------------------------------------------------------------

## 2. Governance Authorization

| Gate | Document | Status |
|---|---|---|
| Phase A | `10B_ADMIN_DASHBOARD_PHASE_A_CLOSEOUT.md` | CLOSED |
| Baseline | `10B` Section 11; `12` Section 4 | SEALED (`AD-Baseline-1.0`) |
| Phase B | `11_ADMIN_DASHBOARD_PHASE_B_OPENING_AUTHORIZATION.md` | OPEN |
| Wave-04 Staging Deployment Synchronization | `57` / `57A` | COMPLETE |
| Wave-04 Staging Deployment Validation | `58` / `58A` | COMPLETE (GO WITH OBSERVATIONS) |
| Enterprise Browser Runtime Validation | This document | COMPLETE (FAIL) |

------------------------------------------------------------------------

## 3. Validation Scope

Validate the already deployed Wave-04 staging Vercel preview:

| # | Area | Method |
|---|---|---|
| 1 | Browser loading (`/`, `/admin`, `/admin/tenants`) | `agent-browser` + Playwright |
| 2 | Application shell, title, favicon, static assets | `agent-browser` snapshot + `network requests` |
| 3 | Login form and invalid-credential handling | `agent-browser` fill + click |
| 4 | Protected route enforcement | `agent-browser` navigation |
| 5 | `check-subdomain` Edge Function | Direct browser GET to staging Edge Function URL |
| 6 | Browser console | `agent-browser console` |
| 7 | Network traffic | `agent-browser network requests` + Playwright HAR |
| 8 | Performance | `agent-browser vitals` |

------------------------------------------------------------------------

## 4. Validation Order Executed

1. Mandatory governance document review.
2. Codebase Memory MCP refresh and repository-state verification.
3. Git repository verification.
4. `agent-browser` setup and staging preview navigation.
5. Playwright capture of `/` and `/admin` screenshots and `/` HAR.
6. Login form inspection and invalid-credential submission.
7. Protected route `/admin/tenants` navigation.
8. Direct browser invocation of `check-subdomain` staging Edge Function.
9. Console, network, and performance evidence collection.
10. Roadmap and program status synchronization.

------------------------------------------------------------------------

## 5. Validation Evidence Summary

| Check | Evidence | Result |
|---|---|---|
| `/` loads | Title `VietSales Pro - Quản lý bán hàng`; LCP 580 ms | PASS |
| `/admin` loads | Login form with email, password, submit button | PASS |
| Invalid login | `Invalid login credentials` message displayed | PASS |
| `/admin/tenants` unauthenticated | Redirected to login | PASS |
| `check-subdomain` | `{"available":true}` HTTP 200 from staging | PASS |
| Console | No JavaScript exceptions or warnings | PASS |
| Static assets | All Vercel assets HTTP 200 | PASS |
| Configuration | Auth POST sent to **production** Supabase `rsialbfjswnrkzcxarnj.supabase.co` | **FAIL** |

The Vercel preview deployment is using the production Supabase credentials from `.env` instead of the staging credentials from `.env.staging`. This prevents staging authentication and authenticated browser validation from executing against the staging project.

------------------------------------------------------------------------

## 6. Final Decision

**DECISION: FAIL**

Enterprise Browser Runtime Validation has been executed. The unauthenticated browser surface behaves correctly, but a critical runtime configuration defect was discovered: the staging Vercel preview is connected to the production Supabase project. Authenticated browser validation of the Wave-04 staging environment is therefore not possible, and production deployment authorization must not proceed.

**Blocking issue:**
- Staging preview build is wired to `rsialbfjswnrkzcxarnj.supabase.co` (production) rather than `shbmzvfcenbybvyzclem.supabase.co` (staging).

**Next governance action:** Remediate the staging build configuration, redeploy the preview, and re-run `58B` until it passes. Do NOT begin Wave-04 Production Deployment Authorization, Wave-04 Production Deployment Synchronization, or Wave-04 Closeout until `58B` passes.

------------------------------------------------------------------------

## 7. Stop Rule

Stage 58B is complete with a **FAIL** result. Do NOT proceed to Wave-04 Production Deployment Authorization, Wave-04 Production Deployment Synchronization, or Wave-04 Closeout without explicit Program Owner approval and a passing re-run of Stage 58B.
