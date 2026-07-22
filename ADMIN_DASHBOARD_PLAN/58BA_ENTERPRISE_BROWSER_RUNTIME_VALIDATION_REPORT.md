# 58BA_ENTERPRISE_BROWSER_RUNTIME_VALIDATION_REPORT

**Document ID:** 58BA_ENTERPRISE_BROWSER_RUNTIME_VALIDATION_REPORT  
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
**Status:** ENTERPRISE BROWSER RUNTIME VALIDATION COMPLETE — **FAIL**

------------------------------------------------------------------------

## 1. Documents Reviewed

The following mandatory governance documents were read or reviewed before execution:

| # | Document | Role in Validation |
|---|---|---|
| 00 | `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` | Program charter, lifecycle, transition rules, current status |
| 12 | `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md` | Master Plan status, quality gates, roadmap, final decision |
| 52 | `52_ADMIN_DASHBOARD_WAVE-04_VERIFICATION.md` | Wave-04 verification and deployment observations |
| 53 | `53_ADMIN_DASHBOARD_WAVE-04_ACCEPTANCE_REVIEW.md` | Wave-04 acceptance decision and deployment observations |
| 54 | `54_PRE_WAVE04_DEPLOYMENT_SYNCHRONIZATION_ROADMAP_UPDATE.md` | Deployment Synchronization gate definition and roadmap |
| 54A | `54A_GOVERNANCE_DOCUMENT_CONSISTENCY_UPDATE.md` | Governance consistency verification |
| 54B | `54B_MASTER_PLAN_SYNCHRONIZATION_REPORT.md` | Master Plan synchronization evidence |
| 55 | `55_ADMIN_DASHBOARD_WAVE-04_DEPLOYMENT_SYNCHRONIZATION_AUTHORIZATION.md` | Authorized deployment scope, strategy, rollback, risks |
| 55A | `55A_DEPLOYMENT_SYNCHRONIZATION_AUTHORIZATION_REPORT.md` | Detailed authorization evidence |
| 56 | `56_ADMIN_DASHBOARD_WAVE-04_PRE_DEPLOYMENT_READINESS_REVIEW.md` | Pre-deployment readiness evidence and GO decision |
| 56A | `56A_PRE_DEPLOYMENT_READINESS_REVIEW_REPORT.md` | Detailed readiness evidence |
| 57 | `57_ADMIN_DASHBOARD_WAVE-04_STAGING_DEPLOYMENT_SYNCHRONIZATION.md` | Stage 1 authorization and GO decision |
| 57A | `57A_STAGING_DEPLOYMENT_SYNCHRONIZATION_REPORT.md` | Stage 1 deployment evidence and traceability |
| 58 | `58_ADMIN_DASHBOARD_WAVE-04_STAGING_DEPLOYMENT_VALIDATION.md` | Stage 2 validation gate and GO WITH OBSERVATIONS |
| 58A | `58A_STAGING_DEPLOYMENT_VALIDATION_REPORT.md` | Stage 2 detailed validation evidence |

------------------------------------------------------------------------

## 2. Codebase Memory MCP Verification

**Tool:** `codebase-memory` MCP server  
**Action:** `index_repository` (fast mode) on `C:\PROJECT\vietsalepro`  
**Result:** `indexed` — 28,592 nodes, 42,264 edges, 0 skipped

| Verification Check | Method | Result |
|---|---|---|
| Project | `index_repository` result | `C-PROJECT-vietsalepro` |
| Indexed nodes | `index_repository` result | 28,592 |
| Indexed edges | `index_repository` result | 42,264 |
| Source drift `ce87b9d7..HEAD` | `git diff` | None outside `ADMIN_DASHBOARD_PLAN` and `.codebase-memory` |
| `getTenantSubscription` caller | `search_graph` | `services.tenantService.getTenantSubscription` at `services/tenantService.ts:455-463` |
| `getUserAccounts` caller | `search_graph` | `services.admin.tenantAdminService.getUserAccounts` at `services/admin/tenantAdminService.ts:78-96` |
| Canonical RPC call sites | `search_graph` / `read` | `supabase.rpc('get_tenant_subscription')` and `supabase.rpc('get_user_accounts')` are present |

**Codebase Memory Verdict:** The repository graph is fresh and the canonical RPC call sites are present in the accepted source. No application-source drift detected.

------------------------------------------------------------------------

## 3. Git Repository Verification

| Check | Method | Result |
|---|---|---|
| HEAD commit | `git rev-parse HEAD` | `a12ed302` — governance-only consistency update after `57` |
| Authorized source commit | `55` / `57` / `git rev-parse ce87b9d7` | `ce87b9d7` present and reachable |
| Current branch | `git branch --show-current` | `master` |
| Source changes `ce87b9d7..HEAD` | `git diff --stat ce87b9d7..HEAD -- . ':!ADMIN_DASHBOARD_PLAN' ':!.codebase-memory'` | 0 lines — no source drift |
| Working-tree source changes | `git diff HEAD -- . ':!ADMIN_DASHBOARD_PLAN' ':!.codebase-memory'` | 0 lines |
| Working-tree modifications | `git status --short` | `.codebase-memory/*` (MCP re-index), `ADMIN_DASHBOARD_PLAN/*.md` governance deliverables |

**Git Verdict:** The accepted Wave-04 source revision `ce87b9d7` remains frozen. The only changes are governance documentation and MCP infrastructure artifacts.

------------------------------------------------------------------------

## 4. Installed Skills Utilized

| Skill | Applicability | Execution |
|---|---|---|
| `agent-browser` | Browser automation, console/network checks, screenshots, vitals | Invoked and used for all live browser validation |
| `webapp-testing` | Runtime validation and Playwright-based web checks | Invoked; Playwright (`npx playwright`) used to capture `/admin` and `/` screenshots and a HAR file |
| `code-review` | Not applicable — no code changes to review | Not invoked |
| `requesting-code-review` | Not applicable — not a pre-commit review | Not invoked |
| `doc-coauthoring` | Not applicable — governed program report | Not invoked |
| `internal-comms` | Not applicable — no internal communication artifact requested | Not invoked |

------------------------------------------------------------------------

## 5. Browser Environment

| Setting | Value |
|---|---|
| Primary tool | `agent-browser` 0.32.3 |
| Engine | Chromium (headless, default `chrome` engine) |
| Operating system | Windows |
| Session | `58b` |
| Screenshot directory | `C:\PROJECT\vietsalepro\ADMIN_DASHBOARD_PLAN\58B_browser_artifacts` |
| Supplementary tool | Playwright 1.61.1 (`npx playwright screenshot`) |
| Target preview URL | `https://vietsalepro-8vzldgvj8-tanphat056-3795s-projects.vercel.app` |
| HTTPS certificate | Valid (browser connected without `--ignore-https-errors`) |

------------------------------------------------------------------------

## 6. Playwright Execution Summary

| Step | Command / URL | Output |
|---|---|---|
| 1 | `npx playwright screenshot --wait-for-timeout=3000 --viewport-size=1280,720 "<preview>/admin" "58B_pw_admin.png"` | Screenshot captured |
| 2 | `npx playwright screenshot --wait-for-timeout=3000 --save-har "58B_pw_home.har" --viewport-size=1280,720 "<preview>/" "58B_pw_home.png"` | Screenshot and HAR captured |

Playwright confirmed that `/admin` serves the login page and `/` serves the landing page without JavaScript crashes. No further Playwright scripts were executed because the application could not be logged into.

------------------------------------------------------------------------

## 7. agent-browser Execution Summary

| # | Command / Action | Result |
|---|---|---|
| 1 | `open <preview>/` | Page loaded; title `VietSales Pro - Quản lý bán hàng` |
| 2 | `open <preview>/admin` | Login form rendered |
| 3 | `fill email/password` + `click "Đăng nhập hệ thống"` | `Invalid login credentials` displayed |
| 4 | `open <preview>/admin/tenants` | Redirected to login (protected route enforced) |
| 5 | `open https://shbmzvfcenbybvyzclem.supabase.co/functions/v1/check-subdomain?subdomain=testdeploy` | `{"available":true}` HTTP 200 |
| 6 | `console` | No JavaScript exceptions or unhandled rejections |
| 7 | `network requests` | Network log captured (see Section 13) |
| 8 | `vitals /` and `vitals /admin` | Performance values captured (see Section 14) |

------------------------------------------------------------------------

## 8. Authentication Validation

| Test | Expected | Result |
|---|---|---|
| Login page renders at `/admin` | Email and password inputs present | **PASS** — inputs for email and password visible |
| Invalid credentials rejected | Error message shown, no redirect | **PASS** — `Invalid login credentials` displayed, form remains |
| Protected route `/admin/tenants` unauthenticated | Redirect to login | **PASS** — login form shown at `/admin/tenants` |
| Valid login | Authenticated session created | **NOT TESTED** — no authorized test credentials available |
| Session persistence / token refresh / logout | Validated after login | **NOT TESTED** — blocked by valid-login limitation |

**Critical finding:** The invalid-credential request was sent to the **production** Supabase project (`rsialbfjswnrkzcxarnj.supabase.co`) instead of the authorized **staging** project (`shbmzvfcenbybvyzclem.supabase.co`). This means the Vercel preview deployment is configured with the production `VITE_SUPABASE_URL`/`VITE_SUPABASE_ANON_KEY` values from `.env` rather than the staging values from `.env.staging`.

------------------------------------------------------------------------

## 9. UI Validation

| Element | Check | Result |
|---|---|---|
| Application home (`/`) | Loads; static content rendered | **PASS** |
| Page title | `VietSales Pro - Quản lý bán hàng` | **PASS** |
| Favicon | `/icon.svg` returned HTTP 200 | **PASS** |
| Application shell | Header, footer, navigation, feature sections visible | **PASS** |
| Static assets | All JS/CSS/font/manifest requests returned 200 | **PASS** |
| Login form | Email, password, submit button, show-password toggle | **PASS** |
| Error state | Invalid-credentials message appears | **PASS** |
| Loading / skeleton / toast states | Not exercised (requires authenticated session) | **NOT TESTED** |
| Dashboard / Tenant / User / Billing / Settings pages | Not reachable without login | **NOT TESTED** |

------------------------------------------------------------------------

## 10. RPC Runtime Validation

| RPC | Expected | Result |
|---|---|---|
| `get_tenant_subscription` | Called by UI after login; returns subscription data | **NOT TESTED** — no authenticated session |
| `get_user_accounts` | Called by UI after login; returns user accounts | **NOT TESTED** — no authenticated session |

The existence, signatures, permissions, and SQL-level execution of both RPCs were previously validated in `58A_STAGING_DEPLOYMENT_VALIDATION_REPORT.md`. Browser-level RPC runtime validation is blocked by the authentication configuration defect.

------------------------------------------------------------------------

## 11. Edge Function Validation

| Function | URL | Expected | Result |
|---|---|---|---|
| `check-subdomain` | `https://shbmzvfcenbybvyzclem.supabase.co/functions/v1/check-subdomain?subdomain=testdeploy` | HTTP 200, `{"available":true}` | **PASS** |

The staging `check-subdomain` Edge Function is reachable and returns the expected availability response. No console errors were produced when the browser loaded the JSON response.

------------------------------------------------------------------------

## 12. Browser Console Review

| Check | Method | Result |
|---|---|---|
| JavaScript exceptions | `agent-browser console` | None observed |
| Unhandled promise rejections | `agent-browser console` | None observed |
| CORS errors | `agent-browser console` / `network requests` | None observed |
| CSP violations | `agent-browser console` | None observed |
| Module loading failures | `agent-browser console` / `network requests` | None observed |
| React runtime errors | `agent-browser console` / rendered pages | None observed |
| Unexpected warnings | `agent-browser console` | None observed |

**Console Verdict:** The landing and login pages load without console errors. The only network-level error is the expected `400` Supabase auth response for invalid credentials.

------------------------------------------------------------------------

## 13. Network Review

### 13.1 Vercel static assets

All static assets loaded from `vietsalepro-8vzldgvj8-tanphat056-3795s-projects.vercel.app` returned HTTP 200:
- Document (`/` and `/admin`)
- Scripts and CSS chunks
- Fonts from `fonts.gstatic.com`
- `/icon.svg` and `manifest.webmanifest`

### 13.2 Authentication request

```
POST https://rsialbfjswnrkzcxarnj.supabase.co/auth/v1/token?grant_type=password -> 400 Bad Request
POST https://rsialbfjswnrkzcxarnj.supabase.co/rest/v1/rpc/record_admin_login -> 200 OK
```

The auth endpoint is the **production** Supabase project, not the authorized **staging** project. This is a runtime configuration defect.

### 13.3 Edge Function request

```
GET https://shbmzvfcenbybvyzclem.supabase.co/functions/v1/check-subdomain?subdomain=testdeploy -> 200 OK
body: {"available":true}
```

### 13.4 No unexpected failures

- No HTTP 500 responses observed.
- No HTTP 404 responses observed.
- No unexpected HTTP 401/403 responses observed.
- No failed RPC or Edge Function requests to the staging project.

------------------------------------------------------------------------

## 14. Performance Observations

| Page | TTFB | FCP | LCP | CLS |
|---|---|---|---|---|
| `https://...vercel.app/` | 1.7 ms | 128 ms | 580 ms | 0 |
| `https://...vercel.app/admin` | 1.6 ms | — | — | 0 |

The landing page has excellent FCP/LCP. The `/admin` login page does not produce a measurable LCP in this run because it is dominated by the auth-shell rendering.

Large assets observed:
- `assets/index-BncvMZwc.js` ~ 1 MB (gzipped traffic not reflected in agent-browser log)
- Multiple vendor chunks loaded on demand

No slow or failed requests were observed in the static-asset layer.

------------------------------------------------------------------------

## 15. Regression Review

| Area | Result |
|---|---|
| UI regression (unauthenticated pages) | None observed |
| Runtime regression (static loading) | None observed |
| Deployment regression (commit hash) | Vercel preview is still at `ce87b9d7` per `58A` |
| Configuration drift | **DEFECT DETECTED** — Vercel preview uses `.env` (production Supabase) instead of `.env.staging` (staging Supabase) |
| Functional regression | Cannot fully assess without authenticated session |

------------------------------------------------------------------------

## 16. Security Review

| Check | Result |
|---|---|
| Authentication required for `/admin/*` | **PASS** — unauthenticated users see login |
| Protected route enforcement | **PASS** — `/admin/tenants` redirects to login |
| Login error feedback | **PASS** — invalid credentials produce a visible error |
| Session management | **NOT TESTED** — no valid session obtained |
| Staging/production separation | **FAIL** — browser auth traffic is directed to the production Supabase project |

The staging preview deployment is **not** isolated from production data at runtime. This is a blocking security/separation issue.

------------------------------------------------------------------------

## 17. Screenshot Inventory

| File | Description |
|---|---|
| `58B_00_home.png` | Landing page (`/`) |
| `58B_01_admin_login.png` | Login page at `/admin` |
| `58B_02_login_invalid.png` | Login form with `Invalid login credentials` error |
| `58B_pw_home.png` | Playwright screenshot of `/` |
| `58B_pw_admin.png` | Playwright screenshot of `/admin` |
| `58B_pw_home.har` | Playwright HAR of `/` network activity |

All artifacts are stored in `C:\PROJECT\vietsalepro\ADMIN_DASHBOARD_PLAN\58B_browser_artifacts`.

------------------------------------------------------------------------

## 18. Roadmap Updates

This supplemental gate is added to the Wave-04 flow **after** `58` and **before** `Wave-04 Production Deployment Authorization`.

Updated sequence:

```
Wave-04 Staging Deployment Validation (58) -> COMPLETE (GO WITH OBSERVATIONS)
Enterprise Browser Runtime Validation (58B) -> COMPLETE (FAIL)
Wave-04 Production Deployment Authorization -> BLOCKED BY 58B FAIL
```

The `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` and `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md` are updated to reflect this result and the blocked production authorization.

------------------------------------------------------------------------

## 19. Program Status Updates

- **Enterprise Browser Runtime Validation:** COMPLETE — **FAIL**
- **Wave-04 Production Deployment Authorization:** **BLOCKED BY 58B FAIL**
- **Wave-04 Production Deployment Synchronization:** NOT AUTHORIZED
- **Wave-04 Closeout:** BLOCKED BY DEPLOYMENT SYNCHRONIZATION
- **Overall Program Status:** **NOT READY FOR WAVE-04 PRODUCTION DEPLOYMENT AUTHORIZATION**

Production deployment authorization must not proceed until the staging Vercel preview is reconfigured to use the staging Supabase credentials (`.env.staging`) and the browser runtime validation is re-executed.

------------------------------------------------------------------------

## 20. Final PASS / FAIL Decision

**DECISION: FAIL**

Enterprise Browser Runtime Validation is complete. The deployed Vercel preview loads cleanly, static assets serve correctly, the login form works, protected routes are enforced, and the staging `check-subdomain` Edge Function responds as expected. However, the Vercel preview build is wired to the production Supabase project (`rsialbfjswnrkzcxarnj`) rather than the authorized staging project (`shbmzvfcenbybvyzclem`). This means the staging application is not isolated from production data and cannot be used to validate staging-specific authentication or the Wave-04 RPCs through the browser.

**Blocking issue:**
- `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in the Vercel preview are sourced from `.env` (production) instead of `.env.staging` (staging). The build pipeline does not select `.env.staging` for preview deployments.

**Required remediation:**
1. Reconfigure the staging Vercel preview build to load `.env.staging` (e.g., via `vite build --mode staging` or by setting the environment variables in the Vercel preview environment).
2. Redeploy the preview from the authorized commit `ce87b9d7`.
3. Re-run Stage 58B Enterprise Browser Runtime Validation to confirm the staging frontend calls only `shbmzvfcenbybvyzclem.supabase.co` and that authenticated flows execute against staging.

**Stop Rule:** Do NOT begin Wave-04 Production Deployment Authorization, Wave-04 Production Deployment Synchronization, or Wave-04 Closeout until the blocking configuration defect is remediated and Stage 58B is re-executed with a PASS result.
