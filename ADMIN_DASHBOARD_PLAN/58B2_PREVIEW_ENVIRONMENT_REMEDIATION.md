# 58B2_PREVIEW_ENVIRONMENT_REMEDIATION

**Document ID:** 58B2_PREVIEW_ENVIRONMENT_REMEDIATION  
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

## 1. Purpose

Execute the authorized Preview Environment Remediation approved by `58B1_PREVIEW_ENVIRONMENT_REMEDIATION_AUTHORIZATION.md`.

This stage:

- Updated the Vercel Preview environment variables only.
- Redeployed the Preview deployment from the authorized commit `ce87b9d7`.
- Verified that the new Preview deployment embeds the authorized STAGING Supabase configuration.
- Did NOT modify application source code, `.env` files, Supabase configuration, or Production environment variables.
- Did NOT perform authenticated browser validation.

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
| Preview Environment Remediation Authorization | `58B1` / `58B1A` | AUTHORIZED |
| Preview Environment Remediation | This document | **COMPLETE** |

Program Owner approval to execute `58B2` was recorded in `58B1`.

------------------------------------------------------------------------

## 3. Authorized Scope

Only the following actions were authorized:

1. Update Preview-only `VITE_SUPABASE_URL` to the STAGING value from `.env.staging`.
2. Update Preview-only `VITE_SUPABASE_ANON_KEY` to the STAGING value from `.env.staging`.
3. Leave Production environment variables unchanged.
4. Redeploy Preview from the authorized source commit `ce87b9d7`.
5. No additional changes.

All actions were performed within this scope.

------------------------------------------------------------------------

## 4. Execution Summary

| Step | Action | Evidence |
|---|---|---|
| 1 | Capture pre-change baseline | Previous Preview deployment `dpl_GXrhNbCnqAkZXaZyALmkVb78HUSV`, previous Preview environment variables shared with Production |
| 2 | Update Vercel Preview `VITE_SUPABASE_URL` to STAGING | `vercel env add VITE_SUPABASE_URL preview` succeeded; `vercel env list preview` confirms `preview`-only target |
| 3 | Update Vercel Preview `VITE_SUPABASE_ANON_KEY` to STAGING | `vercel env add VITE_SUPABASE_ANON_KEY preview` succeeded; `vercel env list preview` confirms `preview`-only target |
| 4 | Restore/confirm Production variables isolated | `vercel env list production` confirms `production`-only targets with original production values |
| 5 | Redeploy Preview from `ce87b9d7` | New deployment `dpl_ERHp8Q5rSa5aSTssRWUCVptfCkZM` created from `git worktree` checkout of `ce87b9d7` |
| 6 | Wait for `READY` state | `vercel inspect --wait` returned `readyState: READY` |
| 7 | Verify runtime target | `agent-browser` network traffic shows POST to `https://shbmzvfcenbybvyzclem.supabase.co/auth/v1/token`; no traffic to `https://rsialbfjswnrkzcxarnj.supabase.co` |
| 8 | Synchronize roadmaps | `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` and `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md` updated |

Detailed evidence, build logs, and environment consistency checks are in `58B2A_PREVIEW_ENVIRONMENT_REMEDIATION_REPORT.md`.

------------------------------------------------------------------------

## 5. Final Decision

**DECISION: REMEDIATION COMPLETE**

The Preview Environment Remediation has been completed successfully. The new Preview deployment `dpl_ERHp8Q5rSa5aSTssRWUCVptfCkZM` targets the authorized STAGING Supabase project and does not target the PRODUCTION Supabase project. Production environment variables remain unchanged. No application source code was modified.

**Next governance action:** `58B3` Preview Runtime Verification. This stage SHALL NOT begin without explicit Program Owner approval.

------------------------------------------------------------------------

## 6. Stop Rule

This remediation is complete. Do NOT begin `58B3` Preview Runtime Verification. Do NOT begin `58B` Re-run. Do NOT request STAGING administrator credentials. Wait for explicit Program Owner approval before starting `58B3`.
