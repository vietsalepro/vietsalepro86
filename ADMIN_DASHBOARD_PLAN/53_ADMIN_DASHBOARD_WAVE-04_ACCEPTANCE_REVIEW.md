# 53_ADMIN_DASHBOARD_WAVE-04_ACCEPTANCE_REVIEW

**Document ID:** 53_ADMIN_DASHBOARD_WAVE-04_ACCEPTANCE_REVIEW  
**Date:** 2026-07-22  
**Project:** VietSalePro  
**Sub Project:** Admin Dashboard  
**Program:** Admin Dashboard System Remediation Program  
**Phase:** B — System Remediation  
**Wave:** Wave-04  
**Acting Capacity:** Enterprise Program Management Office (PMO) together with the Principal Software Architect  
**Baseline:** AD-Baseline-1.0  
**Repository Scope:** `C:\PROJECT\vietsalepro` @ `ce87b9d7`  
**Repository Artifacts Modified:** `53_ADMIN_DASHBOARD_WAVE-04_ACCEPTANCE_REVIEW.md` and status sections of `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` and `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md`  
**Status:** Wave-04 Acceptance COMPLETE — **ACCEPTED WITH OBSERVATIONS**

------------------------------------------------------------------------

# 1. Executive Summary

This document is the formal **independent Wave-04 Acceptance Review** for the Admin Dashboard System Remediation Program. It is an acceptance-only gate; it does not perform implementation, verification, or deployment.

Wave-04 is the final residual hardening wave. The approved, bounded implementation scope was:

1. Replace the direct `.from('tenant_subscriptions')` read in `services/tenantService.ts:getTenantSubscription` with the canonical read RPC `get_tenant_subscription`.
2. Replace the direct `.from('tenant_memberships')` read in `services/admin/tenantAdminService.ts:getUserAccounts` with the canonical read RPC `get_user_accounts`.
3. Add an explicit `verify_jwt = false` configuration for the `check-subdomain` Edge Function in `supabase/config.toml`.
4. Deliver the migration `supabase/migrations/20260801000000_wave04_canonical_read_rpcs.sql`.

Repository evidence confirms that all four deliverables are present and correct in the committed source. `npm run lint` (`tsc --noEmit`) passes. The Codebase Memory graph is refreshed and synchronized. The governance chain from Phase A through Wave-04 Verification is intact.

Three deployment-synchronization observations remain:

- The Wave-04 migration has **not** been applied to the remote Supabase project.
- The two canonical read RPCs are therefore **not** present in the remote database.
- The `check-subdomain` Edge Function is still deployed with `verify_jwt: true` and the latest Vercel production deployment is still at the sealed baseline commit `3a06a6d9`.

These are not implementation defects. The committed source is accepted. The observations must be resolved before runtime behavior matches the committed source, but they do not block the Wave-04 Acceptance gate.

**Acceptance Decision:**

``` text
ACCEPTED WITH OBSERVATIONS
```

**Next Governance Gate:** Wave-04 Closeout (NOT authorized by this document; requires formal Program Owner authorization).

------------------------------------------------------------------------

# 2. Governance Chain Review

The Wave-03 through Wave-04 governance chain was reconstructed and independently verified against the source documents. No gate was skipped.

| Gate | Expected Status | Current Status | Evidence |
|---|---|---|---|
| Phase A | CLOSED | **CLOSED** | `10B_ADMIN_DASHBOARD_PHASE_A_CLOSEOUT.md` |
| Baseline | SEALED | **SEALED (AD-Baseline-1.0)** | `10B` Section 11; `12` Section 4 |
| Phase B | OPEN | **OPEN** | `11` Section 1 |
| Remediation Master Plan | COMPLETE | **COMPLETE** | `12` Section 14 |
| Wave-04 Authorization | AUTHORIZED WITH OBSERVATIONS | **AUTHORIZED WITH OBSERVATIONS** | `47` Section 1 |
| Wave-04 Engineering Kickoff | COMPLETE WITH OBSERVATIONS | **COMPLETE WITH OBSERVATIONS** | `48` Section 1 |
| Wave-04 Repository Readiness Remediation | COMPLETE | **COMPLETE** | `49` Section 1 |
| Wave-04 Implementation Readiness Review | COMPLETE | **COMPLETE (50)** | `50` Section 1 |
| Wave-04 Implementation | COMPLETE | **COMPLETE (51)** | `51` Section 1 |
| Wave-04 Verification | PASS WITH OBSERVATIONS | **PASS WITH OBSERVATIONS (52)** | `52` Section 1 |
| Wave-04 Acceptance | NOT STARTED | **ACCEPTED WITH OBSERVATIONS (this document)** | — |
| Wave-04 Closeout | NOT STARTED | **NOT STARTED** | This document |
| Program Certification | NOT STARTED | **NOT STARTED** | This document |

**Governance Verdict:** The chain is intact. Wave-04 Acceptance is complete.

------------------------------------------------------------------------

# 3. Documents Reviewed

The following mandatory and supporting governance documents were read in full or referenced to reconstruct the decision chain and verify the approved scope.

| # | Document | Role in Acceptance Review | Read Status |
|---|---|---|---|
| 00 | `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` | Program charter, lifecycle, current status, transition rules | Read in full |
| 12 | `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md` | Strategic roadmap, Phase B status, quality gates | Read in full |
| 39 | `39_ADMIN_DASHBOARD_WAVE-03_PACKAGE-02_VERIFICATION_REPORT.md` | Residual direct `.from()` reads and `check-subdomain` observation | Referenced |
| 46 | `46_ADMIN_DASHBOARD_WAVE-03_CLOSEOUT.md` | Observations carried forward from Wave-03 closeout | Referenced |
| 47 | `47_ADMIN_DASHBOARD_WAVE-04_AUTHORIZATION.md` | Wave-04 scope and authorization | Read in full |
| 48 | `48_ADMIN_DASHBOARD_WAVE-04_ENGINEERING_KICKOFF.md` | Engineering constraints, quality gates, rollback, observations | Read in full |
| 49 | `49_ADMIN_DASHBOARD_WAVE-04_REPOSITORY_READINESS_REMEDIATION.md` | Repository disposition and readiness evidence | Read in full |
| 50 | `50_ADMIN_DASHBOARD_WAVE-04_IMPLEMENTATION_READINESS_REVIEW.md` | Frozen execution contract for Wave-04 | Read in full |
| 51 | `51_ADMIN_DASHBOARD_WAVE-04_IMPLEMENTATION.md` | Implementation evidence and claimed completion | Read in full |
| 52 | `52_ADMIN_DASHBOARD_WAVE-04_VERIFICATION.md` | Independent verification results and observations | Read in full |
| IC | `ISSUES_BEFORE_CLOSEOUT.md` | Pre-closeout issue resolution audit trail | Read in full |
| W03r | `WAVE03_CLOSEOUT_READINESS_REVIEW.md` | Pre-closeout working-tree summary | Read in full |
| RG | `REPOSITORY_GOVERNANCE_REALIGNMENT_REPORT.md` | Governance realignment evidence | Referenced |
| RH | `REPOSITORY_HYGIENE_DECISION_REGISTER.md` | Dead-artifact disposition decisions | Referenced |

No document in the mandatory set was skipped. All cross-references were verified against the documents themselves.

------------------------------------------------------------------------

# 4. Repository Acceptance Review

## 4.1 Git Verification

| Verification Check | Method | Result |
|---|---|---|
| HEAD commit | `git rev-parse HEAD` | `ce87b9d7` — `fix(services,config): Wave-04 residual hardening — canonical read RPCs and check-subdomain verify_jwt` |
| Current branch | `git branch --show-current` | `master` |
| Sealed baseline commit reachable | `git rev-parse 3a06a6d9` | `3a06a6d9` present and reachable |
| Source-code modifications since HEAD | `git diff --stat HEAD -- services/tenantService.ts services/admin/tenantAdminService.ts supabase/migrations/20260801000000_wave04_canonical_read_rpcs.sql supabase/config.toml` | **0 lines** — Wave-04 source changes are committed |
| TypeScript lint | `npm run lint` (`tsc --noEmit`) | **PASS** — exit code `0`, no output |
| Working-tree modifications | `git status --short` | ` M .codebase-memory/artifact.json` and ` M .codebase-memory/graph.db.zst` only (MCP re-index artifacts) |
| Untracked governance files | `git status --short` | `?? ADMIN_DASHBOARD_PLAN/52_ADMIN_DASHBOARD_WAVE-04_VERIFICATION.md` (verification deliverable) |

## 4.2 Implementation Commit Verification

| Artifact | Evidence |
|---|---|
| `services/tenantService.ts` | `getTenantSubscription` calls `supabase.rpc('get_tenant_subscription', { p_tenant_id: tenantId })` at lines 455-463. |
| `services/admin/tenantAdminService.ts` | `getUserAccounts` calls `supabase.rpc('get_user_accounts', { p_user_id: userId })` for arbitrary `userId` at lines 85-87. |
| `supabase/migrations/20260801000000_wave04_canonical_read_rpcs.sql` | Migration file present; creates `get_tenant_subscription(UUID)` and `get_user_accounts(UUID)` with `SECURITY DEFINER` and grants. |
| `supabase/config.toml` | `[functions.check-subdomain]` section sets `verify_jwt = false` at lines 581-582. |

## 4.3 Repository Integrity

- No unexpected source modifications.
- No unexpected migrations outside the approved file.
- No unexpected Edge Function source modifications.
- The only working-tree changes are the refreshed `.codebase-memory` AI-infrastructure artifacts and the new/updated governance deliverables.

**Repository Verdict:** The repository is clean. The approved Wave-04 source changes are committed and traceable.

------------------------------------------------------------------------

# 5. Codebase MCP Review

**Tool:** `codebase-memory`

| Verification Check | Method | Result |
|---|---|---|
| Index mode | `index_repository` (fast) | **Indexed** — `status: indexed` |
| Indexed nodes | `query_graph` | **28,375** |
| Indexed edges | `query_graph` | **42,059** |
| `getTenantSubscription` source node | `search_graph` | `C-PROJECT-vietsalepro.services.tenantService.getTenantSubscription` found at `services/tenantService.ts` |
| `getUserAccounts` source node | `search_graph` | `C-PROJECT-vietsalepro.services.admin.tenantAdminService.getUserAccounts` found at `services/admin/tenantAdminService.ts` |
| `getTenantSubscription` body tokens | `search_graph` fingerprint | Contains `supabase rpc p_tenant_id tenantId`; no direct `.from('tenant_subscriptions')` token |
| `getUserAccounts` body tokens | `search_graph` fingerprint | Contains `rpc p_user_id` for arbitrary `userId`; direct `.from('tenant_memberships')` token absent for the arbitrary-user path |
| `check-subdomain` | `search_graph` | Folder node and `index.ts` Module node present; `supabase.config.functions.check-subdomain` Class node present in `supabase/config.toml` |
| Graph health | `query_graph` and `search_graph` | Responded successfully; no orphan nodes detected |

**Codebase Memory Verdict:** The graph is healthy and synchronized to `ce87b9d7`. The two target functions now route through canonical RPCs, the `check-subdomain` configuration is represented, and the removed dead artifacts are not present as source modules.

------------------------------------------------------------------------

# 6. Supabase MCP Acceptance Review

**Tool:** `supabase-mcp-server`

| Verification Check | Method | Result |
|---|---|---|
| Project | `get_project` | `rsialbfjswnrkzcxarnj` — `QLBH`, `ap-northeast-1`, `ACTIVE_HEALTHY` |
| Remote migration history | `list_migrations` | **Wave-04 migration `20260801000000_wave04_canonical_read_rpcs.sql` is NOT present** in the remote migration list |
| RPC existence | `execute_sql` `SELECT proname, prosecdef FROM pg_proc WHERE proname IN ('get_tenant_subscription','get_user_accounts')` | **Empty result** — the two canonical read RPCs are not present in the remote database |
| Edge Function list | `list_edge_functions` | `check-subdomain` is **ACTIVE**, currently deployed with `verify_jwt: true` |
| Edge Function code review | `read` of `supabase/functions/check-subdomain/index.ts` | Intentionally public; implements IP-based rate limiting and `app_audit_log` writes |

**Supabase MCP Verdict:** The production project is healthy, but the Wave-04 migration has not been applied. Consequently, the two RPCs do not exist remotely and `check-subdomain` still requires a JWT. These are deployment-synchronization observations, not source-code defects.

------------------------------------------------------------------------

# 7. Vercel MCP Acceptance Review

**Tool:** `vercel`

| Verification Check | Method | Result |
|---|---|---|
| Team | `list_teams` | `team_5jIBUrVn2CmOrkSojeJZZqoP` |
| Project | `list_projects` / `get_project` | `prj_UdCbqGpXxsBXVNGfz0fz02obBS6x` — `vietsalepro`, framework `vite`, Node `24.x` |
| Domains | `get_project` | `vietsalepro.com`, `*.vietsalepro.com`, `admin.vietsalepro.com`, `master.vietsalepro.com` |
| Latest production deployment | `list_deployments` / `get_project` | `dpl_8rhXQm3qLawzjUSyBNpB2fN33eM5`, target `production`, state `READY`, commit `3a06a6d9` |
| Deployment synchronization | Compare `latestDeployment` commit to `HEAD` | **Deployment is 28 commits behind `HEAD` (`ce87b9d7`)** and does not include the Wave-04 source changes |

**Vercel MCP Verdict:** Vercel project linkage and production deployment health are confirmed. The production deployment is synchronized to the sealed baseline `3a06a6d9`, not to the Wave-04 implementation commit. This is a deployment-synchronization observation.

------------------------------------------------------------------------

# 8. Skills Execution Report

The required enterprise skill set was checked against the locally installed skills.

| Required Skill | Installed | Execution |
|---|---|---|
| `quality-assurance` | **NOT INSTALLED** | Manual acceptance assessment documented in this report |
| `code-review` | Installed (`code-review`) | Manual final code review performed as part of this acceptance; no automated skill run was required |
| `dependency-analysis` | **NOT INSTALLED** | Manual dependency/RPC integrity checks documented in Sections 5 and 6 |
| `system-design` | **NOT INSTALLED** | Manual architecture/SSOT compliance review documented in Section 11 |
| `configuration-management` | **NOT INSTALLED** | Manual Supabase and Vercel configuration checks documented in Sections 6 and 7 |
| `technical-documentation` | **NOT INSTALLED** | Manual traceability/roadmap review documented in Sections 3 and 18 |
| `risk-analysis` | **NOT INSTALLED** | Manual risk assessment documented in Section 16 |
| `security-review` | **NOT INSTALLED** | Manual RPC security and `verify_jwt` review documented in Section 13 |
| `performance-analysis` | **NOT INSTALLED** | **NOT REQUIRED** — Wave-04 did not change runtime performance characteristics |
| `requesting-code-review` | Installed (`requesting-code-review`) | **NOT REQUIRED** — no other skill recommended it |

------------------------------------------------------------------------

# 9. Implementation Acceptance Assessment

| Scope Item | Expected | Evidence | Status |
|---|---|---|---|
| Canonical read RPC `get_tenant_subscription` | Replace `.from('tenant_subscriptions')` in `services/tenantService.ts:getTenantSubscription` | `services/tenantService.ts:455-463` calls `supabase.rpc('get_tenant_subscription')` | PASS |
| Canonical read RPC `get_user_accounts` | Replace `.from('tenant_memberships')` in `services/admin/tenantAdminService.ts:getUserAccounts` | `services/admin/tenantAdminService.ts:85-87` calls `supabase.rpc('get_user_accounts')` | PASS |
| `check-subdomain` `verify_jwt` configuration | Explicit `verify_jwt = false` in `supabase/config.toml` | `supabase/config.toml:581-582` sets `verify_jwt = false` | PASS |
| Migration delivery | `supabase/migrations/20260801000000_wave04_canonical_read_rpcs.sql` exists and is committed | File present with both RPCs, `SECURITY DEFINER`, search path, and grants | PASS |

**Implementation Verdict:** The approved Wave-04 implementation scope is complete in the committed source. No additional scope was introduced.

------------------------------------------------------------------------

# 10. Verification Acceptance Assessment

The independent Wave-04 Verification Report (`52_ADMIN_DASHBOARD_WAVE-04_VERIFICATION.md`) concluded `PASS WITH OBSERVATIONS`. This acceptance review independently confirms:

- The verification evidence was reviewed and is sufficient.
- The remaining observations are deployment-synchronization issues, not implementation defects.
- The same three observations were reproduced by independent Supabase and Vercel MCP checks.

**Verification Verdict:** Verification evidence accepted. The `PASS WITH OBSERVATIONS` determination remains valid.

------------------------------------------------------------------------

# 11. Architecture Acceptance Assessment

| Criterion | Evidence | Status |
|---|---|---|
| Canonical RPC pattern | Both service functions now use `supabase.rpc(...)` | PASS |
| SECURITY DEFINER | Migration defines `SECURITY DEFINER` for both RPCs | PASS |
| search_path | Migration sets `SET search_path = public` for both RPCs | PASS |
| Permission guard | `get_tenant_subscription` checks `is_tenant_member` or `is_system_admin`; `get_user_accounts` checks `auth.uid()` or `is_system_admin` | PASS |
| SSOT compliance | Changes are bounded to the two residual direct reads identified in `39` and `50` | PASS |

**Architecture Verdict:** The implementation is consistent with the approved architectural pattern.

------------------------------------------------------------------------

# 12. Configuration Acceptance Assessment

| Configuration Item | Committed State | Remote/Deployed State | Status |
|---|---|---|---|
| `supabase/config.toml` `[functions.check-subdomain] verify_jwt` | `false` | `true` (requires redeploy) | **PASS WITH OBSERVATION** |
| `supabase/migrations/20260801000000_wave04_canonical_read_rpcs.sql` | Present and committed | Not applied to remote | **PASS WITH OBSERVATION** |

**Configuration Verdict:** The committed configuration is correct. Runtime deployment synchronization remains an accepted observation.

------------------------------------------------------------------------

# 13. Security Acceptance Assessment

| Criterion | Evidence | Status |
|---|---|---|
| RPC security model | `get_tenant_subscription` and `get_user_accounts` use `SECURITY DEFINER` and explicit entitlement checks | PASS |
| RPC grants | Migration grants `EXECUTE` to `authenticated` and `service_role` | PASS |
| `check-subdomain` intent | `supabase/functions/check-subdomain/index.ts` is intentionally public, rate-limited, and writes audit rows | PASS |
| `verify_jwt` remote mismatch | Remote `check-subdomain` still deployed with `verify_jwt: true`; redeploy with `config.toml` change required | **OBSERVATION** |

**Security Verdict:** The committed security posture is correct. The remote `verify_jwt` observation is a deployment synchronization issue, not a security defect in source.

------------------------------------------------------------------------

# 14. Documentation Acceptance Assessment

| Deliverable | Path | Status |
|---|---|---|
| Implementation Report | `51_ADMIN_DASHBOARD_WAVE-04_IMPLEMENTATION.md` | Present and complete |
| Verification Report | `52_ADMIN_DASHBOARD_WAVE-04_VERIFICATION.md` | Present and complete |
| Acceptance Review | `53_ADMIN_DASHBOARD_WAVE-04_ACCEPTANCE_REVIEW.md` (this document) | Produced |

**Documentation Verdict:** All required Wave-04 documentation is present and internally consistent.

------------------------------------------------------------------------

# 15. Knowledge Preservation Review

Wave-04 adds the following permanent engineering knowledge:

1. **Canonical read RPC pattern for residual service-layer `.from()` reads** — the final two residual direct reads were replaced by `get_tenant_subscription` and `get_user_accounts`.
2. **Deployment synchronization is a distinct acceptance observation** — the source may be accepted while the remote migration/Edge Function redeploy remains pending. This distinction is now explicitly recorded.
3. **Repository baseline classification remains stable** — `.codebase-memory` artifacts, governance deliverables, and scratch folders are classified and preserved per `12` Section 12A.

No updates to `REPOSITORY_GOVERNANCE_REALIGNMENT_REPORT.md`, `REPOSITORY_HYGIENE_DECISION_REGISTER.md`, or `ISSUES_BEFORE_CLOSEOUT.md` are required; those records remain closed and valid.

------------------------------------------------------------------------

# 16. Risk Assessment

| Risk | Classification | Finding |
|---|---|---|
| Critical | — | None identified |
| High | — | None identified |
| Medium | Accepted Observation | Wave-04 migration not applied; `get_tenant_subscription` and `get_user_accounts` RPCs absent from remote database. Mitigation: run `supabase migrations push` or equivalent deployment before relying on the new code paths. |
| Medium | Accepted Observation | `check-subdomain` still deployed with `verify_jwt: true`. Mitigation: redeploy the Edge Function so the committed `config.toml` setting takes effect. |
| Medium | Accepted Observation | Vercel production deployment is at baseline `3a06a6d9`, 28 commits behind `ce87b9d7`. Mitigation: deploy the latest `master` commit to production when the Program Owner authorizes. |
| Low | Observation | `.codebase-memory/artifact.json` and `.codebase-memory/graph.db.zst` are modified tracked files from the mandatory MCP refresh; they are not application source and can be committed or reset as part of final closeout housekeeping. |

**No blocking risks identified.** All medium risks are deployment-synchronization observations that can be resolved in the closeout/deployment phase.

------------------------------------------------------------------------

# 17. Observations Classification

| # | Observation | Source | Classification | Blocks Closeout |
|---|---|---|---|---|
| 1 | Wave-04 migration `20260801000000_wave04_canonical_read_rpcs.sql` not applied to remote Supabase project | `list_migrations` | **Accepted Observation** | No |
| 2 | Canonical RPCs `get_tenant_subscription` and `get_user_accounts` not present in remote database | `execute_sql` | **Accepted Observation** (consequence of #1) | No |
| 3 | `check-subdomain` Edge Function still deployed with `verify_jwt: true` | `list_edge_functions` | **Accepted Observation** | No |
| 4 | Vercel production deployment still at baseline commit `3a06a6d9` | `list_deployments` / `get_project` | **Accepted Observation** | No |

All observations are classified as **Accepted Observations**. None are blocking for the Wave-04 Acceptance gate. They must be resolved before the runtime environment matches the committed source, but they do not invalidate the source-level acceptance.

------------------------------------------------------------------------

# 18. Roadmap Consistency Review

The following roadmap and governance documents were reviewed and updated to maintain internal consistency:

- `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` — current status section updated to reflect `Wave-04 Acceptance: ACCEPTED WITH OBSERVATIONS (53)` and `Overall Program Status: WAVE-04 ACCEPTANCE ACCEPTED WITH OBSERVATIONS — READY FOR CLOSEOUT`.
- `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md` — program status table, Wave-04 lifecycle diagram, and final decision table updated to reflect `Wave-04 Acceptance: ACCEPTED WITH OBSERVATIONS (53)`.

No contradictory milestones remain. Wave-04 Closeout is the next governance gate and requires formal Program Owner authorization before it begins.

------------------------------------------------------------------------

# 19. Acceptance Decision

| Dimension | Assessment |
|---|---|
| Implementation Scope | **PASS** |
| Implementation Quality | **PASS** |
| Verification Evidence | **PASS** |
| Architecture | **PASS** |
| Repository Integrity | **PASS** |
| Configuration | **PASS WITH OBSERVATIONS** |
| Security | **PASS WITH OBSERVATIONS** |
| Documentation | **PASS** |
| Roadmap | **PASS** |
| Deployment Synchronization | **PASS WITH OBSERVATIONS** |

**Final Acceptance Decision:**

``` text
ACCEPTED WITH OBSERVATIONS
```

**Justification:**

- The approved Wave-04 implementation scope is fully present and correct in the committed source.
- `npm run lint` passes and the Codebase Memory graph is healthy.
- The governance chain from Phase A through Wave-04 Verification is intact.
- The remaining observations are exclusively deployment-synchronization issues (unapplied migration, missing remote RPCs, pending Edge Function redeploy, and a Vercel deployment behind `HEAD`).
- No implementation defects, verification defects, or source-code drift were found.
- The observations do not prevent Wave-04 Closeout planning, but they must be resolved before any production runtime relies on the Wave-04 changes.

Wave-04 may be formally accepted. Wave-04 Closeout must not begin until the Program Owner provides explicit authorization.

------------------------------------------------------------------------

# 20. Recommendations

1. **Apply the Wave-04 migration to the remote Supabase project** so `get_tenant_subscription` and `get_user_accounts` are created with the correct `SECURITY DEFINER`, search path, and grants.
2. **Redeploy the `check-subdomain` Edge Function** so the committed `verify_jwt = false` setting in `supabase/config.toml` is reflected in production.
3. **Deploy the latest `master` commit (`ce87b9d7`) to Vercel production** so the frontend runtime matches the accepted source baseline.
4. **Commit the refreshed `.codebase-memory` artifacts and the new governance deliverables** (`52` and `53`) during the formal Wave-04 Closeout commit.
5. **Do not begin Wave-04 Closeout** until the Program Owner explicitly authorizes it.
