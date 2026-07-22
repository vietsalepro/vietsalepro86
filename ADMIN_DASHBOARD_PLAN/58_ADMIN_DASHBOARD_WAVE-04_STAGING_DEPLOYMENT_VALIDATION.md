# 58_ADMIN_DASHBOARD_WAVE-04_STAGING_DEPLOYMENT_VALIDATION

**Document ID:** 58_ADMIN_DASHBOARD_WAVE-04_STAGING_DEPLOYMENT_VALIDATION
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

Validate the Wave-04 deployment that has already been synchronized to the STAGING environment.

This stage SHALL validate operational behavior.  
This stage SHALL NOT perform any new implementation.  
This stage SHALL NOT introduce additional source changes.  
This stage SHALL NOT deploy new artifacts.  
This stage SHALL only verify the deployed staging environment.

Production deployment remains prohibited.

------------------------------------------------------------------------

## 2. Governance Authorization

| Gate | Document | Status |
|---|---|---|
| Phase A | `10B_ADMIN_DASHBOARD_PHASE_A_CLOSEOUT.md` | CLOSED |
| Baseline | `10B` Section 11; `12` Section 4 | SEALED (`AD-Baseline-1.0`) |
| Phase B | `11_ADMIN_DASHBOARD_PHASE_B_OPENING_AUTHORIZATION.md` | OPEN |
| Remediation Master Plan | `12` Section 14 | COMPLETE |
| Wave-04 Authorization | `47_ADMIN_DASHBOARD_WAVE-04_AUTHORIZATION.md` | AUTHORIZED WITH OBSERVATIONS |
| Wave-04 Engineering Kickoff | `48_ADMIN_DASHBOARD_WAVE-04_ENGINEERING_KICKOFF.md` | COMPLETE WITH OBSERVATIONS |
| Wave-04 Repository Readiness Remediation | `49_ADMIN_DASHBOARD_WAVE-04_REPOSITORY_READINESS_REMEDIATION.md` | COMPLETE |
| Wave-04 Implementation Readiness Review | `50_ADMIN_DASHBOARD_WAVE-04_IMPLEMENTATION_READINESS_REVIEW.md` | COMPLETE |
| Wave-04 Implementation | `51_ADMIN_DASHBOARD_WAVE-04_IMPLEMENTATION.md` | COMPLETE |
| Wave-04 Verification | `52_ADMIN_DASHBOARD_WAVE-04_VERIFICATION.md` | PASS WITH OBSERVATIONS |
| Wave-04 Acceptance Review | `53_ADMIN_DASHBOARD_WAVE-04_ACCEPTANCE_REVIEW.md` | ACCEPTED WITH OBSERVATIONS |
| Pre-Wave-04 Deployment Synchronization Roadmap Update | `54_PRE_WAVE04_DEPLOYMENT_SYNCHRONIZATION_ROADMAP_UPDATE.md` | COMPLETE |
| Governance Document Consistency Update | `54A_GOVERNANCE_DOCUMENT_CONSISTENCY_UPDATE.md` | COMPLETE |
| Master Plan Synchronization Report | `54B_MASTER_PLAN_SYNCHRONIZATION_REPORT.md` | COMPLETE |
| Deployment Synchronization Authorization | `55_ADMIN_DASHBOARD_WAVE-04_DEPLOYMENT_SYNCHRONIZATION_AUTHORIZATION.md` | COMPLETE |
| Deployment Synchronization Authorization Report | `55A_DEPLOYMENT_SYNCHRONIZATION_AUTHORIZATION_REPORT.md` | COMPLETE |
| Pre-Deployment Readiness Review | `56_ADMIN_DASHBOARD_WAVE-04_PRE_DEPLOYMENT_READINESS_REVIEW.md` | COMPLETE |
| Pre-Deployment Readiness Review Report | `56A_PRE_DEPLOYMENT_READINESS_REVIEW_REPORT.md` | COMPLETE |
| Staging Deployment Synchronization | `57_ADMIN_DASHBOARD_WAVE-04_STAGING_DEPLOYMENT_SYNCHRONIZATION.md` | COMPLETE |
| Staging Deployment Synchronization Report | `57A_STAGING_DEPLOYMENT_SYNCHRONIZATION_REPORT.md` | COMPLETE |
| Staging Deployment Validation | This document | COMPLETE |

Program Owner approval to begin Stage 2 was received in the current session.

------------------------------------------------------------------------

## 3. Validation Scope

Validate **ONLY** the approved Wave-04 staging deployment:

| # | Artifact | Source | Target | Validation Method |
|---|---|---|---|---|
| 1 | Supabase migration `20260801000000_wave04_canonical_read_rpcs.sql` | `supabase/migrations/20260801000000_wave04_canonical_read_rpcs.sql` | Staging Supabase project | `list_migrations` + `execute_sql` |
| 2 | Canonical read RPCs `get_tenant_subscription` and `get_user_accounts` | Same migration | Staging database | `execute_sql` `pg_proc` + direct invocation |
| 3 | `check-subdomain` Edge Function | `supabase/functions/check-subdomain/index.ts` | Staging Edge Functions | `list_edge_functions` + `get_logs` + `curl` |
| 4 | Vercel frontend build | `ce87b9d7` source tree | Vercel preview | `get_deployment` + build logs + `curl` |
| 5 | Environment configuration | `.env.staging`, `supabase/config.toml`, `vercel.json` | Staging environment | `git diff` + file presence |

No implementation, deployment, migration, database change, Edge Function change, or Vercel redeployment was performed.

------------------------------------------------------------------------

## 4. Validation Order Executed

1. Mandatory governance document review.
2. Codebase Memory MCP refresh and repository-state verification.
3. Git repository verification.
4. Supabase MCP validation:
   - project health
   - migration status
   - RPC existence, signature, grants, and execution
   - Edge Function deployment and logs
5. Vercel MCP validation:
   - deployment metadata and commit hash
   - build logs
   - runtime logs
6. Direct HTTP runtime checks:
   - Vercel preview root and `/admin`
   - `check-subdomain` endpoint
7. Deployment integrity, functional, runtime, regression, security, and rollback review.
8. Roadmap and program status synchronization.

------------------------------------------------------------------------

## 5. Final Validation Decision

**DECISION: GO WITH OBSERVATIONS**

All Stage 2 validation checks have been performed against the deployed staging environment. The authorized commit `ce87b9d7` is present in the Vercel preview deployment. The Wave-04 canonical read RPCs and the `check-subdomain` Edge Function are deployed and operational in the staging Supabase project. No Wave-04 implementation defects were found. Two observations are recorded:

- Supabase security advisor returned many pre-existing `function_search_path_mutable` warnings; the two Wave-04 RPCs were verified independently to have `SET search_path TO 'public'`.
- Browser console and full authenticated UI flows could not be exercised because `agent-browser` / Playwright are not installed in this environment.

**Next governance action:** Begin Wave-04 Production Deployment Authorization upon explicit Program Owner approval. Do not begin Wave-04 Production Deployment Synchronization or Wave-04 Closeout until production is separately authorized.

------------------------------------------------------------------------

## 6. Stop Rule

Stage 2 is complete. Do NOT perform Wave-04 Production Deployment Authorization, Wave-04 Production Deployment Synchronization, or Wave-04 Closeout without explicit Program Owner approval.
