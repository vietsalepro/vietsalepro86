# 37_ADMIN_DASHBOARD_WAVE-03_PACKAGE-02_IMPLEMENTATION_READINESS_REVIEW

**Document ID:** 37_ADMIN_DASHBOARD_WAVE-03_PACKAGE-02_IMPLEMENTATION_READINESS_REVIEW  
**Date:** 2026-07-21  
**Project:** VietSalePro  
**Sub Project:** Admin Dashboard  
**Program:** Admin Dashboard System Remediation Program  
**Phase:** B — System Remediation  
**Wave:** Wave-03  
**Package:** Package-02 — Execution, Edge Functions & Audit Logging  
**Acting Capacity:** Principal Software Architect / Enterprise Readiness Review Board / Independent Technical Reviewer / Enterprise Governance Board / Release Readiness Authority  
**Baseline:** AD-Baseline-1.0  
**Repository Scope:** `C:\PROJECT\vietsalepro` @ commit `c58fa592b99cce1cec5269bde844c46d93878c50`  
**Status:** Readiness Review COMPLETE — Package-02 Implementation AUTHORIZED

------------------------------------------------------------------------

# 1. Mission

This is the formal **Implementation Readiness Review (IRR)** for **Wave-03 Package-02** of the Admin Dashboard System Remediation Program. It is the final governance gate before any Package-02 implementation work begins and becomes the binding execution contract for the package.

This activity is:

- **NOT** implementation.
- **NOT** verification.
- **NOT** acceptance.
- **NOT** deployment.

No application source code, database schema, migration, RPC, Edge Function, or production deployment may be modified by this review.

------------------------------------------------------------------------

# 2. Governance Review

All mandatory governance documents `00` through `36` were reviewed in full before this Package-02 Implementation Readiness Review was produced. No document or section was skipped.

| # | Document | Role in Package-02 Readiness Review |
|---|---|---|
| 00 | `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` | Program charter, lifecycle, current roadmap, governance transition rules |
| 01 | `01_ADMIN_DASHBOARD_ARCHITECTURE_MODEL.md` | SSOT architecture baseline |
| 02 | `02_ADMIN_DASHBOARD_DEPENDENCY_MAP.md` | Dependency and layer direction baseline |
| 03 | `03_ADMIN_DASHBOARD_EXECUTION_MODEL.md` | Runtime execution baseline |
| 04 | `04_ADMIN_DASHBOARD_INVESTIGATION_PLAN.md` | Investigation methodology and capability domains |
| 05 | `05_ADMIN_DASHBOARD_FORENSIC_EXECUTION_PROTOCOL.md` | Evidence collection protocol |
| 06 | `06_ADMIN_DASHBOARD_FORENSIC_INVESTIGATION.md` | Forensic findings and traces |
| 07 | `07_ADMIN_DASHBOARD_ROOT_CAUSE_ANALYSIS.md` | Root cause candidates |
| 08 | `08_ADMIN_DASHBOARD_FINAL_RECOMMENDATIONS.md` | Enterprise recommendations |
| 09 | `09_ADMIN_DASHBOARD_SYSTEM_INCONSISTENCY_REPORT.md` | Sealed issue catalog |
| 10 | `10_ADMIN_DASHBOARD_INVESTIGATION_ACCEPTANCE_REVIEW.md` | Independent acceptance review |
| 10A | `10A_ADMIN_DASHBOARD_INVESTIGATION_ACCEPTANCE_IMPLEMENTATION.md` | Corrected baseline and duplicate reconciliation |
| 10B | `10B_ADMIN_DASHBOARD_PHASE_A_CLOSEOUT.md` | Baseline sealing (`AD-Baseline-1.0`) |
| 11 | `11_ADMIN_DASHBOARD_PHASE_B_OPENING_AUTHORIZATION.md` | Phase B opening authorization, entry rules |
| 12 | `12_ADMIN_DASHBOARD_REMEDIATION_MASTER_PLAN.md` | Strategic remediation portfolio and precedence |
| 13 | `13_ADMIN_DASHBOARD_PROGRAM_OWNER_DECISION_RECORD.md` | Program Owner Decisions 1–4 |
| 14–36 | Wave/Package/Program status and closeout documents `14` through `36` | Wave lifecycle, package boundaries, acceptance evidence, and Package-01 acceptance |

**Package-01 Acceptance Confirmation:** `36_ADMIN_DASHBOARD_WAVE-03_PACKAGE-01_ACCEPTANCE_REVIEW.md` records Wave-03 Package-01 as **ACCEPTED WITH OBSERVATIONS**. This review independently confirms that Package-01 has been accepted and that no Package-02 implementation has started.

**Governance Verdict:** Every prerequisite for the Wave-03 Package-02 Implementation Readiness Review is satisfied.

------------------------------------------------------------------------

# 3. Repository Validation

## 3.1 Git Validation

| Verification Check | Method | Result |
|---|---|---|
| HEAD commit | `git rev-parse HEAD` | `c58fa592b99cce1cec5269bde844c46d93878c50` — "docs(36): Wave-03 Package-01 acceptance review and charter status update" |
| Current branch | `git branch --show-current` | `master` |
| Sealed baseline commit reachable | `git rev-parse 3a06a6d9` | `3a06a6d9` present and reachable |
| Package-01 implementation commit | `git show --stat e2470ae5` | `fix(DEP-002,DEP-003,DEP-004,PERM-003,SVC-001-SVC-005): Wave-03 Package-01 service layer and permissions` |
| Post-Package-01 source drift | `git diff --stat e2470ae5..HEAD -- services/admin/ contexts/AuthContext.tsx pages/admin/InvitationsAccept.tsx supabase/functions/check-subdomain/ supabase/functions/billing-webhooks/ supabase/migrations/ lib/permissions.ts` | **0 lines** — no source changes since the Package-01 implementation commit |
| `supabase/schema.sql` drift | `git diff --stat a1bc8759..HEAD -- supabase/schema.sql` | **0 lines** — no direct schema edits |
| Tracked working-tree drift | `git diff --stat HEAD` | `.codebase-memory/artifact.json` and `.codebase-memory/graph.db.zst` only (MCP re-index performed during this review) |
| Untracked entries | `git status --short` | Governance deliverables in `ADMIN_DASHBOARD_PLAN/` (including this document), `PROJECT_MASTER_INDEX*`, `PDP-*`, `PRODUCTION_*`, `memory-zone/` scratch artifacts |

**Repository Verdict:** Only the four authorized Package-01 artifacts (three service files and one migration) were committed as source changes. No protected files were modified. No `supabase/schema.sql` edits occurred. The Package-02 implementation surface is untouched.

## 3.2 Repository Integrity

- No unexpected repository drift exists in the Package-02 source surface.
- The `.codebase-memory/` working-tree changes are tooling artifacts from the required Codebase Memory MCP re-index.
- The untracked governance and scratch artifacts do not affect the implementation baseline.

------------------------------------------------------------------------

# 4. Codebase Memory MCP Evidence

**Tool:** `codebase-memory`

| Verification Check | Method | Result |
|---|---|---|
| Project | `codebase-memory` artifact | `vietsalepro` |
| Indexed commit | `.codebase-memory/artifact.json` | `c58fa592b99cce1cec5269bde844c46d93878c50` (matches `HEAD`) |
| Nodes | `codebase-memory.query_graph` | 25,203 |
| Edges | `codebase-memory.query_graph` | 37,051 |
| Graph health | `query_graph` and `search_graph` | Responded successfully; labels include `Function`, `Route`, `Variable`, `File`, `Folder`, `Module`, `Section` |
| `check-subdomain` search | `search_graph(query="check-subdomain access controls")` | Located `supabase/functions/check-subdomain/index.ts`, `services/admin/tenantAdminService.ts`, `pages/admin/Tenants.tsx`, `utils/subdomain.ts` |
| `billing-webhooks` search | `search_graph(query="billing-webhooks audit log app_audit_log")` | Located `supabase/functions/billing-webhooks/index.ts`, `supabase/schema.sql` `write_audit_log` and `app_audit_log_login_enforcement`, `services/auditService.ts` |
| `InvitationsAccept` / `AuthContext` search | `search_graph(query="InvitationsAccept AuthContext AdminLayout")` | Located `pages/admin/InvitationsAccept.tsx`, `pages/admin/AdminLayout.tsx`, `contexts/AuthContext.tsx`, `services/admin/memberAdminService.ts` |
| `InvitationsAccept` call trace | `trace_path(outbound, depth 3)` | Calls `lookupInvitation` in `services/admin/memberAdminService.ts`, `useAuth` from `contexts/AuthContext.tsx`, and `getTenantUrl` from `lib/tenant.ts` |
| `AuthProvider` call trace | `trace_path(outbound, depth 3)` | Calls `writeAuditLog` (`services/auditService.ts`), `recordAdminLogin` (`services/loginHistoryService.ts`), `activateMembership` (`services/admin/memberAdminService.ts`), and `initializeSession` |
| Call / dependency graph | `query_graph` edge count above | Connected graph; no isolated Package-02 artifacts detected |

**Codebase Memory Verdict:** The Codebase Memory graph is healthy and synchronized to the current `HEAD`. The Package-02 surfaces (`AuthContext`, `InvitationsAccept`, `check-subdomain`, `billing-webhooks`, and the affected `services/admin/` call sites) are present in the graph, traceable, and show no hidden or circular dependencies.

------------------------------------------------------------------------

# 5. Engineering Skills Applied

| Skill | Reason | Evidence | Contribution |
|---|---|---|---|
| `code-review` | Validate that no post-Package-01 implementation changes exist and that the Package-02 surface aligns with the frozen execution contract. | `git diff --stat e2470ae5..HEAD -- services/admin/ contexts/AuthContext.tsx pages/admin/InvitationsAccept.tsx supabase/functions/check-subdomain/ supabase/functions/billing-webhooks/`; `32` Section 8.3. | Confirmed Package-02 source surface is unchanged; exact file list matches the frozen contract. |
| `system-design` | Confirm the architecture-first package decomposition and service-layer contract boundaries for the 10 Package-02 remediation issues. | `31` Section 8.4.2; `32` Sections 8.1 and 8.3; `33` Section 9.3. | Preserved dependency order: Package-02 depends on Package-01 and precedes Package-03. |
| `dependency-analysis` | Verify the Package-02 dependency graph and impact radius across contexts, pages, services, Edge Functions, and migrations. | Codebase Memory `search_graph` and `trace_path` results above. | No hidden or circular dependencies detected for the Package-02 surface. |
| `risk-analysis` | Evaluate whether Edge Function `verify_jwt` settings, audit-logging gaps, and staging/production boundaries are blockers. | `33` Section 6; `30` Section 9.7; current `list_edge_functions` baseline. | Classified observations as non-blocking risks carried forward with mitigations. |
| `quality-assurance` | Confirm the frozen contract, completion criteria, and verification gates are legible and testable. | `33` Section 9.3 completion criteria and exact test list. | QA entry criteria for Package-02 implementation are defined. |
| `technical-documentation` | Synthesize governance, repository, and platform evidence into this authoritative readiness artifact. | All sections of this document. | Provides the traceable, frozen execution contract required by the program charter. |
| `configuration-management` | Track working-tree cleanliness and artifact scope so implementation starts from a clean baseline. | `git status --short`, `git diff --stat HEAD`. | Documented working-tree drift and freeze requirement before implementation. |
| `requesting-code-review` | Establish the peer-review gates that must pass before Package-02 can be accepted. | Readiness Review decision table and Verification Strategy section. | Codifies mandatory independent review for Package-02. |
| `release-management` (evaluated) | Confirm deployment baseline and staging/production boundary controls before Package-02. | `33` Section 6; `36` Section 6; Vercel deployment history. | Verified production remains pinned to the pre-Wave-02 baseline. |
| `systematic-debugging` (evaluated) | Trace the dependency path from the 10 canonical issues through services and Edge Functions to confirm impact ordering. | Codebase Memory traces; `32` Section 8.1 issue list. | Validated that Package-02 fixes must build on Package-01 service contracts. |

------------------------------------------------------------------------

# 6. Package-02 Scope Review

## 6.1 Authorized Issues

| Issue ID | Primary Domain | Description | Affected Artifacts |
|---|---|---|---|
| `BL-001` | Business Logic | Billing lifecycle shortcuts use direct `.from()` updates instead of `update_tenant_subscription` RPC. | `services/admin/billingAdminService.ts` |
| `BL-002` | Business Logic | `createTenantWithCredentials` invokes the `create-tenant` Edge Function directly; no atomic `create_tenant_with_credentials` RPC. | `services/admin/tenantAdminService.ts`, `contexts/AuthContext.tsx` |
| `BL-003` | Business Logic | `update_tenant`, `delete_tenant_safe`, and `update_tenant_subscription` RPCs are `SECURITY INVOKER` instead of `SECURITY DEFINER`. | `supabase/migrations/` (call-site / migration alignment) |
| `DIR-001` | Data Integrity | `create-tenant` Edge Function tenant creation is not atomic across `auth.admin.createUser` and multiple `INSERT`s. | `services/admin/tenantAdminService.ts`, `contexts/AuthContext.tsx` |
| `VAL-001` | Validation / UI | `InvitationsAccept` is not in `AdminLayout` `ADMIN_ROUTE_MAP` / `PAGE_TITLES`; `getActiveId('/admin/invitations/accept')` falls back to `'invitations'`. | `pages/admin/InvitationsAccept.tsx`, `pages/admin/AdminLayout.tsx` |
| `VAL-002` | Validation / Business | Billing lifecycle shortcuts bypass canonical validation RPC. | `services/admin/billingAdminService.ts` |
| `EDG-002` | Edge Functions | `check-subdomain` access controls are not documented or hardened beyond IP rate limiting. | `supabase/functions/check-subdomain/index.ts` |
| `EDG-003` | Edge Functions | `billing-webhooks` access controls are signature-only; generic auth model is not enforced. | `supabase/functions/billing-webhooks/index.ts` |
| `EDG-004` | Edge Functions | `billing-webhooks` does not write to `app_audit_log`. | `supabase/functions/billing-webhooks/index.ts` |
| `EDG-005` | Edge Functions | Widespread Edge Function audit logging gaps (e.g., `check-subdomain`, `billing-webhooks`). | `supabase/functions/check-subdomain/index.ts`, `supabase/functions/billing-webhooks/index.ts` |

## 6.2 Implementation Boundary

| Boundary | Value |
|---|---|
| **Repository scope** | `contexts/AuthContext.tsx`, `pages/admin/InvitationsAccept.tsx`, `services/admin/*.ts`, `supabase/functions/check-subdomain/`, `supabase/functions/billing-webhooks/`, `supabase/migrations/` |
| **Exact file list** | `contexts/AuthContext.tsx`, `pages/admin/InvitationsAccept.tsx`, `services/admin/*.ts` (call-site alignment only), `supabase/functions/check-subdomain/index.ts`, `supabase/functions/billing-webhooks/index.ts` |
| **Exact primary modules** | `contexts/AuthContext.tsx`, `pages/admin/InvitationsAccept.tsx`, `services/admin/tenantAdminService.ts`, `services/admin/billingAdminService.ts`, `supabase/functions/check-subdomain/index.ts`, `supabase/functions/billing-webhooks/index.ts` |
| **Exact primary services** | Tenant creation validation, billing lifecycle validation, canonical RPC wrappers consumed by Package-01 |
| **Exact Edge Functions** | `check-subdomain`, `billing-webhooks` |
| **Exact RPCs** | Canonical validation RPCs for tenant creation and billing lifecycle; `app_audit_log` write helpers (existing RPCs referenced; no new RPCs may be added) |
| **Exact migrations** | One new migration under `supabase/migrations/YYYYMMDDHHMMSS_wave03_package02_edge_audit.sql` (created at implementation time) |
| **Exact tests** | `tests/smoke/admin-dashboard-create-tenant.test.ts`, `tests/smoke/admin-dashboard-p3-member-management.test.ts`, `tests/edge-functions/domain-verification.test.ts`, `tests/admin-dashboard/CustomDomainPanel.test.tsx`, `tests/admin-dashboard/Members.test.tsx`, `npm run lint`, `npm run build`, Edge Function runtime verification in Staging |
| **Exact verification targets** | Tenant and billing lifecycles use canonical RPCs; `check-subdomain` and `billing-webhooks` access controls are explicit and documented; all privileged Edge Functions write to `app_audit_log`; `AuthContext` and `InvitationsAccept` flows validate through `AdminLayout` |
| **Rollback point** | Revert the Package-02 commit; restore to the Package-01 accepted commit if the Package-02 migration is applied |
| **Completion criteria** | Execution flow alignment; hardened Edge Function auth and audit logging; migration files committed; Package-01 service contracts remain intact |

## 6.3 Protected / Out-of-Scope Artifacts

- `src/` business logic outside the Admin Dashboard surface.
- `supabase/schema.sql` — all schema/RLS/RPC/permission changes must flow through `supabase/migrations/`.
- Production environment configuration, secrets, or deployment targets.
- Sealed SSOT documents (`01`–`08`) and the Program Charter without formal amendment.
- Package-03 issues (`ARCH-003`–`ARCH-006`, `DEAD-001`–`DEAD-004`, `PERF-001`, `PERF-002`).
- Any issue not in the `AD-Baseline-1.0` Wave-03 22-issue set.

------------------------------------------------------------------------

# 7. Implementation Readiness Assessment

## 7.1 Frozen Execution Contract

The frozen execution contract for Package-02 is taken from `33_ADMIN_DASHBOARD_WAVE-03_IMPLEMENTATION_READINESS_REVIEW.md` Section 9.3 and has been independently verified against the current repository.

| Contract Attribute | Frozen Value | Independent Verification | Status |
|---|---|---|---|
| Authorized issues | `BL-001`, `BL-002`, `BL-003`, `DIR-001`, `VAL-001`, `VAL-002`, `EDG-002`, `EDG-003`, `EDG-004`, `EDG-005` | `32` Section 8.1; `33` Section 9.3 | PASS |
| Repository scope | `contexts/AuthContext.tsx`, `pages/admin/InvitationsAccept.tsx`, `services/admin/*.ts`, `supabase/functions/check-subdomain/`, `supabase/functions/billing-webhooks/`, `supabase/migrations/` | `git status` and `git diff` show zero changes in this scope | PASS |
| Exact primary modules | `contexts/AuthContext.tsx`, `pages/admin/InvitationsAccept.tsx`, `services/admin/tenantAdminService.ts`, `services/admin/billingAdminService.ts`, `supabase/functions/check-subdomain/index.ts`, `supabase/functions/billing-webhooks/index.ts` | Codebase Memory `search_graph` confirms all exist and are connected | PASS |
| Exact Edge Functions | `check-subdomain`, `billing-webhooks` | Codebase Memory located both `index.ts` files | PASS |
| Exact tests | `tests/smoke/admin-dashboard-create-tenant.test.ts`, `tests/smoke/admin-dashboard-p3-member-management.test.ts`, `tests/edge-functions/domain-verification.test.ts`, `tests/admin-dashboard/CustomDomainPanel.test.tsx`, `tests/admin-dashboard/Members.test.tsx`, `npm run lint`, `npm run build`, Edge Function runtime verification in Staging | Test list present and executable | PASS |
| Rollback point | Revert Package-02 commit; restore to Package-01 accepted commit | Git baseline is clean and tagged by commit `c58fa592` | PASS |
| Completion criteria | Execution flow alignment; hardened Edge Function auth and audit logging; migration files committed; Package-01 service contracts remain intact | Criteria are measurable and match verification targets | PASS |

## 7.2 Dependency Readiness

- Package-01 is accepted and its service contracts are intact.
- Package-02 depends only on Package-01 and does not require any out-of-scope artifacts.
- Codebase Memory traces confirm the Package-02 surfaces are reachable and non-circular.

## 7.3 Rollback Strategy

| Stage | Rollback Action |
|---|---|
| Before migration push | `git reset --hard c58fa592b99cce1cec5269bde844c46d93878c50` or revert the Package-02 commit. |
| After migration push to Staging | Revert the Package-02 commit, then run `supabase migration repair` to mark the Package-02 migration reverted on Staging. |
| After Edge Function deploy to Staging | Redeploy the previous Edge Function versions from the Package-01 accepted commit. |

## 7.4 Readiness Verdict

- **Implementation scope:** Defined and frozen.
- **Repository readiness:** Clean; no Package-02 implementation has started.
- **Dependency readiness:** Package-01 accepted; Package-02 surfaces traceable.
- **Rollback point:** Defined.
- **Migration strategy:** New migration under `supabase/migrations/`; no direct `supabase/schema.sql` edits.
- **RPC strategy:** Consume existing canonical RPCs and `app_audit_log` helpers; no new RPCs.
- **Testing strategy:** Unit, smoke, Edge Function runtime, lint, and build gates defined.
- **Deployment strategy:** Staging-only; production remains pinned to pre-Wave-02 baseline.

------------------------------------------------------------------------

# 8. Implementation Preparation Plan

## 8.1 Execution Order

1. **Freeze working tree.** Commit or discard the `.codebase-memory/` re-index artifacts before implementation begins.
2. **Create Package-02 migration** with timestamp `YYYYMMDDHHMMSS_wave03_package02_edge_audit.sql` under `supabase/migrations/`.
3. **Align execution flows** in `contexts/AuthContext.tsx` and `pages/admin/InvitationsAccept.tsx` to use canonical validation and `AdminLayout` route validation.
4. **Align service call sites** in `services/admin/tenantAdminService.ts` and `services/admin/billingAdminService.ts` to canonical RPCs.
5. **Harden `check-subdomain` Edge Function** access controls and document the public-rate-limited model.
6. **Harden `billing-webhooks` Edge Function** access controls and add `app_audit_log` writes.
7. **Run lint, build, and test suites.**
8. **Stage and deploy Edge Functions to Staging for runtime verification.**
9. **Commit** with message `fix(BL-001,BL-002,BL-003,DIR-001,VAL-001,VAL-002,EDG-002-EDG-005): Wave-03 Package-02 execution, edge, and audit` including the migration.

## 8.2 Repository Touch Points

| Order | File / Folder | Purpose |
|---|---|---|
| 1 | `supabase/migrations/YYYYMMDDHHMMSS_wave03_package02_edge_audit.sql` | Access-control / audit helper migration |
| 2 | `services/admin/tenantAdminService.ts` | Tenant creation canonical RPC alignment |
| 3 | `services/admin/billingAdminService.ts` | Billing lifecycle canonical RPC alignment |
| 4 | `contexts/AuthContext.tsx` | Remove business-logic shortcuts; surface activation failures |
| 5 | `pages/admin/InvitationsAccept.tsx` | Validate through `AdminLayout` route map |
| 6 | `supabase/functions/check-subdomain/index.ts` | Harden / document access controls |
| 7 | `supabase/functions/billing-webhooks/index.ts` | Harden access controls; write `app_audit_log` |

## 8.3 Migration Sequence

1. Create `supabase/migrations/YYYYMMDDHHMMSS_wave03_package02_edge_audit.sql`.
2. Add helper functions / triggers required for `check-subdomain` and `billing-webhooks` audit logging and access control, if the implementation determines they are needed.
3. Validate locally with `supabase db push --dry-run` (or equivalent) against Staging.
4. Apply to Staging only after the implementation commit is complete.

## 8.4 RPC Sequence

1. Identify existing canonical validation RPCs for tenant creation and billing lifecycle.
2. Refactor `tenantAdminService.ts` and `billingAdminService.ts` call sites to consume those RPCs.
3. Identify existing `app_audit_log` write RPC/helpers for Edge Function usage.
4. Update `check-subdomain` and `billing-webhooks` to write audit entries where privileged.

## 8.5 Testing Sequence

| Step | Command / Test | Gate |
|---|---|---|
| 1 | `npm run lint` | No new lint errors in changed files |
| 2 | `npm run build` | Production build passes |
| 3 | `npm run audit:rpc` | All service-layer RPC calls are defined in canonical migrations |
| 4 | `npx vitest run tests/smoke/admin-dashboard-create-tenant.test.ts tests/smoke/admin-dashboard-p3-member-management.test.ts` | Tenant / member smoke tests pass |
| 5 | `npx vitest run tests/edge-functions/domain-verification.test.ts` | Edge Function domain verification passes |
| 6 | `npx vitest run tests/admin-dashboard/CustomDomainPanel.test.tsx tests/admin-dashboard/Members.test.tsx` | UI regression tests pass |
| 7 | Edge Function runtime verification in Staging | `check-subdomain` and `billing-webhooks` respond correctly and write audit logs |

## 8.6 Verification Checkpoints

- Tenant and billing lifecycles use canonical RPCs.
- `check-subdomain` and `billing-webhooks` access controls are explicit and documented.
- All privileged Edge Functions in scope write to `app_audit_log`.
- `AuthContext` and `InvitationsAccept` flows validate through `AdminLayout`.
- `npm run lint` and `npm run build` pass.
- Staging-only deployment; production untouched.

## 8.7 Deployment Checkpoints

- Supabase migration pushed to Staging only.
- `supabase functions deploy check-subdomain billing-webhooks` to Staging only.
- Vercel production remains pinned to the pre-Wave-02 baseline.
- No production Supabase migration push, Edge Function deployment, or Vercel production deployment is authorized.

------------------------------------------------------------------------

# 9. Supabase MCP Preparation

Package-02 implementation **will require** the `supabase-mcp-server` MCP for the following activities. If the `supabase-mcp-server` MCP cannot be accessed, the Implementation Engineer **MUST STOP** immediately and request the Program Owner to provide a Supabase Access Key before continuing.

| Activity | Expected Supabase MCP Tool / Method | Purpose During Implementation |
|---|---|---|
| Project discovery / authentication | `list_projects` | Confirm Staging and Production project access before any change. |
| Project health check | `get_project` | Verify Staging project `ACTIVE_HEALTHY` status. |
| Migration inventory | `list_migrations` | Confirm Staging migration state before applying Package-02 migration. |
| Database validation | `execute_sql` on `information_schema.routines`, `information_schema.triggers`, `information_schema.table_privileges` | Verify canonical RPCs, triggers, and privileges exist before and after migration. |
| Security validation | `get_advisors(type: security)` | Check for new CRITICAL/HIGH findings before/after Edge Function changes. |
| Edge Function inventory | `list_edge_functions` | Confirm `check-subdomain` and `billing-webhooks` versions and `verify_jwt` flags. |
| Edge Function deployment | `deploy_function` (or equivalent Supabase MCP deploy tool) | Deploy hardened `check-subdomain` and `billing-webhooks` to Staging. |
| Migration application | `apply_migration` / `push_migration` (or equivalent) | Apply `YYYYMMDDHHMMSS_wave03_package02_edge_audit.sql` to Staging. |
| Audit verification | `execute_sql` against `app_audit_log` | Confirm `billing-webhooks` and `check-subdomain` write audit entries. |

**No workaround, no assumption, and no bypass are permitted.**

------------------------------------------------------------------------

# 10. Vercel MCP Preparation

Package-02 implementation **will require** the `vercel` MCP for the following read-only validation and boundary-control activities.

| Activity | Expected Vercel MCP Tool / Method | Purpose During Implementation |
|---|---|---|
| Project discovery | `list_projects` / `get_project` | Confirm `vietsalepro` project linkage and `master` branch. |
| Deployment baseline | `list_deployments` | Verify no unauthorized production deployments occur during Package-02. |
| Production protection | `get_project` / `list_deployments` | Confirm production remains pinned to the pre-Wave-02 baseline commit. |
| Git linkage validation | `get_project` | Confirm `master` branch and GitHub repository linkage. |
| Preview deployment | `list_deployments` (preview filter) | If a preview build is generated for verification, confirm it targets preview, not production. |

Package-02 is a Supabase-heavy package (Edge Functions, migrations, RPC alignment). No Vercel production deployment is expected. Vercel MCP is used for boundary control and evidence collection only.

------------------------------------------------------------------------

# 11. Risk Assessment

| Risk Category | Level | Rationale | Mitigation |
|---|---|---|---|
| Architecture risk | LOW | Package-02 is bounded to existing execution paths and does not introduce new architecture. | Follow `33` Section 9.3 exact file list; no new modules. |
| Repository risk | LOW | No source drift in Package-02 scope; only `.codebase-memory/` tooling artifacts are uncommitted. | Freeze `.codebase-memory/` artifacts before implementation. |
| Migration risk | MEDIUM | A new migration will be created and applied to Staging; rollback must repair migration state. | Rollback plan in Section 7.3; `supabase migration repair` available on Staging. |
| RPC risk | MEDIUM | Service call sites must be refactored to canonical RPCs; any missed call remains a shortcut. | `npm run audit:rpc` and unit/smoke tests as gates. |
| Permission risk | MEDIUM | `billing-webhooks` signature-only model and `check-subdomain` public model must be explicitly documented; no privilege escalation. | Document access-control decisions in code comments and Edge Function README; verify `verify_jwt` flags. |
| Security risk | MEDIUM | Edge Function audit logging closes trust-boundary gaps; any missing audit write is a security regression. | Edge Function runtime verification in Staging; `execute_sql` audit count checks. |
| Regression risk | MEDIUM | Changes touch `AuthContext`, tenant/billing services, and Edge Functions used by signup/onboarding flows. | Run full lint, build, RPC audit, smoke tests, and Edge Function runtime tests. |
| Deployment risk | LOW | Staging-only deployment; production pinned and untouched. | `list_migrations` and `list_deployments` checks before and after Staging push. |
| Operational risk | MEDIUM | `check-subdomain` and `billing-webhooks` must remain available for signup and payment flows after hardening. | Staging runtime verification with real request shapes before accepting. |
| Maintainability | LOW | Fixes canonicalize existing patterns rather than introducing new abstractions. | Follow existing service/Edge Function style; no new dependencies. |

**Overall Risk Level:** MEDIUM. All identified risks have mitigations and checkpoints.

------------------------------------------------------------------------

# 12. Readiness Recommendation

## 12.1 Final Decision

```text
READY FOR IMPLEMENTATION WITH OBSERVATIONS
```

## 12.2 Supporting Evidence

- **Governance evidence:** Documents `00` through `36` have been reviewed. `36` confirms Package-01 is **ACCEPTED WITH OBSERVATIONS**. All Wave-03 governance gates through Engineering Kickoff are complete.
- **Repository evidence:** `git diff --stat` over the Package-02 source surface shows **0 lines** changed since the Package-01 implementation commit `e2470ae5`. `supabase/schema.sql` has 0 edits. Tracked working-tree changes are limited to `.codebase-memory/` artifacts from this review.
- **Git evidence:** HEAD is `c58fa592` on `master`; the sealed baseline `3a06a6d9` is reachable; no commits exist after `c58fa592`.
- **Codebase Memory MCP evidence:** Project `vietsalepro` is indexed to `c58fa592` with 25,203 nodes and 37,051 edges. `search_graph` and `trace_path` located and traced all Package-02 surfaces with no hidden or circular dependencies.
- **Architecture evidence:** Package-02 is bounded to `contexts/AuthContext.tsx`, `pages/admin/InvitationsAccept.tsx`, `services/admin/tenantAdminService.ts`, `services/admin/billingAdminService.ts`, `supabase/functions/check-subdomain/index.ts`, and `supabase/functions/billing-webhooks/index.ts`. Protected files and out-of-scope issues are explicitly excluded.
- **Dependency evidence:** Package-02 depends on the accepted Package-01 service contracts and must precede Package-03. No missing dependencies were identified.
- **Risk evidence:** All risks are MEDIUM or lower; mitigation and rollback plans are defined.
- **Roadmap evidence:** `00_ADMIN_DASHBOARD_SYSTEM_REMEDIATION_PROGRAM_CHARTER.md` Section 10 will be updated to reflect `Wave-03 Package-02 Implementation Readiness Review : COMPLETE` and `Wave-03 Package-02 Implementation : READY TO START`.

## 12.3 Observations

1. `.codebase-memory/` working-tree artifacts from the required MCP re-index are uncommitted. These must be frozen (committed or discarded) before implementation begins.
2. Package-01 was accepted with observations (audit test mock gap, remaining direct `.from()` calls, migration timestamp traceability). Package-02 must not regress these accepted states.
3. Pre-existing `verify_jwt: false` Edge Functions (`check-subdomain`, `admin-health-check`) and the `billing-webhooks` signature-only model are known and will be documented/hardened within the Package-02 scope.
4. The Package-02 implementation must remain Staging-only; production remains pinned to the pre-Wave-02 baseline.

## 12.4 Next Governance Action

Wave-03 Package-02 Implementation may now begin. The next governance deliverable is the Wave-03 Package-02 Post-Implementation Review.

------------------------------------------------------------------------

*Updated by 37_ADMIN_DASHBOARD_WAVE-03_PACKAGE-02_IMPLEMENTATION_READINESS_REVIEW.md, 2026-07-21*
