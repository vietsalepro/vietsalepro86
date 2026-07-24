# VietSalePro — Codebase Memory Validation Report

> **Phase**: PHASE_02_CODEBASE_MEMORY_VALIDATION
> **Date**: 2026-07-23
> **Mode**: READ ONLY — no implementation, commit, deploy, or database changes
> **Memory validated**: `.codebase-memory/SEMANTIC_MEMORY.md` (built 2026-07-23, commit `ec0f317b`)
> **Graph**: codebase-memory MCP project `vietsalepro` — 28,881 nodes / 42,874 edges
> **Cross-validation sources**: Repository filesystem, Supabase MCP (production `rsialbfjswnrkzcxarnj` + staging `shbmzvfcenbybvyzclem`), Vercel MCP (project `prj_UdCbqGpXxsBXVNGfz0fz02obBS6x`)

---

## 1. Overall Coverage

| Dimension | Score | Notes |
|---|---|---|
| **Architecture** | HIGH (95%) | Accurate stack, topology, isolation model, intent |
| **Business modules** | HIGH (90%) | All modules mapped; e-invoice domain missing |
| **Database tables** | MEDIUM (85%) | 85 of 88 prod tables documented; 3 phantom; 2 missing |
| **RPC coverage** | LOW (35%) | Memory says "100+"; actual 297 unique business RPCs |
| **Edge functions** | HIGH (97%) | All 29 slugs match; verify_jwt list incomplete for prod |
| **Migrations** | MEDIUM (80%) | Narrative accurate; count wrong (137 vs 147) |
| **Services** | HIGH (95%) | Structure accurate; 1 root service undercounted |
| **Routing/UI** | MEDIUM (75%) | Routes accurate; page count inflated (38 vs 24) |
| **State/hooks** | HIGH (100%) | All 11 hooks, 2 contexts match |
| **Deployment** | HIGH (90%) | Vercel + Supabase config accurate; staging project missing |
| **Governance docs** | MEDIUM (70%) | Root MD count understated (80+ vs 110); ADMIN_DASHBOARD_PLAN dir missing |
| **Tests** | HIGH (90%) | Structure accurate; count slightly low (67 vs 70) |

**Overall confidence: HIGH for architectural and business intent, MEDIUM for quantitative accuracy.**

The memory is a **trusted semantic source for architecture, business flow, and module responsibility questions**. It is **not a trusted source for exact counts** — multiple counts are stale or understated. The graph itself (28,881 nodes) remains structurally accurate and queryable.

---

## 2. Business Coverage

**Accurate:**
- Two-surface model (tenant app + admin platform) ✓
- Vietnamese retail domain (VND, e-invoice providers, payment providers) ✓
- All 16 tenant modules and 12 admin modules mapped with service→RPC chains ✓
- 7 cross-module workflow diagrams (tenant lifecycle, POS checkout, return/exchange, member invitation, billing, audit, permissions) ✓
- E-invoice providers mentioned in §0 summary (Sapo/m-Invoice/VNPT/Viettel) ✓

**Missing:**
- **E-invoice business domain implementation** — 2 tables (`einvoice_config`, `einvoice_orders`) and 3 RPCs (`check_single_einvoice_config`, `update_einvoice_config_updated_at`, `update_einvoice_orders_updated_at`) exist in production but are completely absent from §3 module mapping, §5.1 table inventory, and §5.2 RPC documentation. The §0 summary mentions e-invoice providers but the actual database implementation is undocumented.

---

## 3. Database Coverage

**Production tables: 88** (queried via `information_schema.tables`)

| Memory §5.1 Category | Memory Count | Prod Match | Notes |
|---|---|---|---|
| Tenant/Core | 11 | 11 ✓ | |
| Catalog | 4 | 4 ✓ | |
| Inventory | 8 | 8 ✓ | |
| Sales | 6 | 6 ✓ | |
| Customers/Loyalty | 10 | 10 ✓ | |
| Suppliers | 5 | 5 ✓ | |
| Billing | 13 | 13 ✓ | |
| Admin/Platform | 13 | 13 ✓ | |
| Security/Audit | 7 | 6 | `admin_2fa_backup_code_attempts` is phantom |
| Other | "(8)" but lists 12 | 10 | Internal label mismatch; 2 phantom, 2 missing |

**Phantom tables (in memory, NOT in production):**
1. `admin_2fa_backup_code_attempts` — documented in §5.1 Security/Audit, does not exist in prod
2. `tenant_restore_snapshots` — documented in §5.1 Other, does not exist in prod
3. `tenant_backup_jobs` — documented in §5.1 Other, does not exist in prod

**Missing tables (in production, NOT in memory):**
1. `einvoice_config` — e-invoice provider configuration
2. `einvoice_orders` — e-invoice order mapping

**Internal inconsistency:** §5.1 labels the "Other" category as "(8)" but lists 12 table names.

---

## 4. RPC Coverage

**Production unique business RPCs: 297** (excluding pg_trgm extension functions)

Memory states "100+" in §1, §2, and §5.2. The actual count is **~3x the documented figure**. This is the single largest coverage gap.

**Missing RPC domains (in production, not referenced in memory):**
- E-invoice: `check_single_einvoice_config`, `update_einvoice_config_updated_at`, `update_einvoice_orders_updated_at`
- The memory's §3 module tables list ~60 named RPCs; the remaining ~237 are undocumented by name.

**Accurate patterns documented:**
- SECURITY DEFINER for privileged ops ✓
- SECURITY INVOKER for read RPCs ✓
- Helper functions (current_tenant_id, is_system_admin, etc.) ✓

**Recommendation:** The memory should either (a) update the count to "~300" and reference `docs/admin-dashboard/RPC_CONTRACTS.md` as the canonical full list, or (b) acknowledge that the semantic memory intentionally covers only the ~60 business-critical RPCs by name and the rest are discoverable via the graph.

---

## 5. Edge Function Coverage

**Production: 29 edge functions, all ACTIVE** — exact slug match with memory §6.2. ✓

**verify_jwt discrepancy:**

| Function | Memory §6.3 | config.toml (local) | Production |
|---|---|---|---|
| send-billing-email | false ✓ | false ✓ | false ✓ |
| send-ticket-email | false ✓ | false ✓ | false ✓ |
| billing-webhooks | false ✓ | false ✓ | false ✓ |
| cron-admin-tasks | false ✓ | false ✓ | false ✓ |
| check-subdomain | false ✓ | false ✓ | false ✓ |
| send-template-email | **not listed** | not listed | **false** |
| admin-health-check | **not listed** | not listed | **false** |
| webhook-delivery | **not listed** | not listed | **false** |

Memory says "5 with verify_jwt=false" (§9.2). Production has **8**. The memory accurately reflects the local `config.toml` but not the production deployment state. Memory §11 gap #8 acknowledges this risk but §9.2 states the count as fact.

**Deployment path inconsistency (not documented in memory):**
10 of 29 edge functions have `entrypoint_path` pointing to non-repo locations:
- 8 functions: `C:\Users\SUACAUBA\Downloads\Project\vietsale-pro-v7\...`
- 2 functions: `C:\tmp\user_fn_...` (inline editor deployments)

These functions were deployed from a different machine or the Supabase inline editor and may not match the current repo source. This is a deployment hygiene risk the memory should document.

---

## 6. Migration Coverage

**Actual: 147 SQL migration files** (64 from 2025, 81 from 2026)
**Memory: 137** — understated by 10.

The migration evolution narrative in §5.6 is **qualitatively accurate** (phases, date ranges, content descriptions all match). Only the total count is wrong. The latest migration `20260801000000_wave04_canonical_read_rpcs.sql` is correctly referenced in the Wave02-04 narrative.

---

## 7. Documentation Coverage

| Source | Memory says | Actual | Status |
|---|---|---|---|
| Root governance MD files | "80+" | 110 | Understated |
| docs/admin-dashboard/ | 12 files (runbooks + RPC_CONTRACTS) | 12 files | ✓ |
| ADMIN_DASHBOARD_PLAN/ | **not mentioned** | 135 MD files | **Missing** |
| archive/ | mentioned as out-of-scope | exists | ✓ |

**Missing:** The `ADMIN_DASHBOARD_PLAN/` directory contains 135 markdown files covering the admin dashboard investigation, execution model, dependency maps, forensic protocols, and inconsistency reports. This is a major documentation directory that the memory does not reference at all.

---

## 8. Architecture Coverage

**HIGH confidence.** All architectural claims verified:
- React 19 + Vite 6 + Tailwind 4 + PWA ✓
- Supabase Postgres 17 (confirmed: 17.6.1.084) ✓
- Subdomain-based tenant isolation via `get_tenant_by_subdomain` RPC ✓
- RLS pattern `tenant_id = current_tenant_id() OR is_system_admin()` ✓
- RPCs for atomicity (SECURITY DEFINER) ✓
- Edge Functions for service_role operations ✓
- `_legacy*` fallback pattern in supabaseService.ts ✓
- Graph queryability confirmed: `search_graph`, `query_graph`, `trace_path` all operational ✓

**Missing from architecture documentation:**
- **Staging Supabase project** (`shbmzvfcenbybvyzclem` / "QLBH Staging Multi-Tenant", created 2026-07-04, ap-northeast-1, Postgres 17.6.1.141) — the memory documents only the production project. The existence of a staging environment is a significant architectural fact for deployment and testing workflows.

---

## 9. Confidence Score

| Area | Confidence |
|---|---|
| Architecture & topology | **HIGH** (95%) |
| Business domain & workflows | **HIGH** (90%) |
| Module responsibility mapping | **HIGH** (90%) |
| Edge function inventory | **HIGH** (97%) |
| Database table inventory | **MEDIUM** (85%) |
| RPC inventory | **LOW** (35%) |
| Quantitative counts | **LOW** (60%) |
| Deployment & config | **MEDIUM** (85%) |
| Governance documentation | **MEDIUM** (70%) |

**Overall: 78% — HIGH for semantic/architectural queries, MEDIUM for quantitative queries.**

---

## 10. Risks

| # | Risk | Severity | Impact |
|---|---|---|---|
| R1 | RPC count severely understated (100+ vs 297) | HIGH | Future sessions may believe most RPCs are documented when ~237 are not |
| R2 | E-invoice domain (2 tables + 3 RPCs) missing | MEDIUM | Business domain gap; e-invoice is a Vietnamese compliance requirement |
| R3 | 3 phantom tables documented | MEDIUM | Future sessions may write queries against non-existent tables |
| R4 | Staging Supabase project undocumented | MEDIUM | Deployment/testing workflow context missing |
| R5 | 3 edge functions verify_jwt=false in prod not documented | MEDIUM | Security review gap; these functions accept unauthenticated calls |
| R6 | 10 edge functions deployed from non-repo paths | HIGH | Source-of-truth risk; deployed code may not match repo |
| R7 | Page count inflated (38 vs 24) | LOW | Navigation confusion; memory overstates surface area |
| R8 | ADMIN_DASHBOARD_PLAN/ (135 files) undocumented | LOW | Investigation context missing for future debugging |
| R9 | Quantitative counts systematically stale | LOW | Erosion of trust in memory's numeric claims |
| R10 | "Other (8)" labels 12 tables | LOW | Internal inconsistency |

---

## 11. Recommendations to Improve Knowledge Quality

> These recommendations target the **knowledge base** (SEMANTIC_MEMORY.md), not source code.

1. **Update RPC count and add e-invoice RPCs** — Change "100+" to "~300 unique business RPCs" in §1, §2, §5.2. Add `check_single_einvoice_config`, `update_einvoice_config_updated_at`, `update_einvoice_orders_updated_at` to the RPC documentation. Reference `docs/admin-dashboard/RPC_CONTRACTS.md` as the canonical full list.

2. **Add e-invoice tables to §5.1** — Add `einvoice_config` and `einvoice_orders` to the schema inventory, either as a new "E-Invoice (2)" category or under "Other". Document the business domain in §3.

3. **Remove phantom tables** — Delete `admin_2fa_backup_code_attempts`, `tenant_restore_snapshots`, `tenant_backup_jobs` from §5.1, or mark them as "planned in migrations but not applied to production".

4. **Fix "Other (8)" → "Other (12)"** or recount to match the actual list length.

5. **Document staging Supabase project** — Add `shbmzvfcenbybvyzclem` (QLBH Staging Multi-Tenant) to §9.2 with its project ID, region, and purpose.

6. **Update verify_jwt documentation** — In §6.3 and §9.2, distinguish between local config.toml (5 functions) and production deployment (8 functions). Add `send-template-email`, `admin-health-check`, `webhook-delivery` to the production verify_jwt=false list.

7. **Document edge function deployment path inconsistency** — Add a note in §6 or §9 that 10 of 29 functions were deployed from non-repo paths and may need redeployment from the canonical repo to ensure source consistency.

8. **Update quantitative counts** — Migrations 137→147, root services 31→32, pages 38 tenant→24 root (clarify what counts as a "page"), admin pages 16→17, tests 67→70, utils 14→17, root governance MDs 80+→110.

9. **Reference ADMIN_DASHBOARD_PLAN/** — Add to §10.2 governance docs: "ADMIN_DASHBOARD_PLAN/ (135 MD files): admin dashboard investigation, execution model, dependency maps, forensic protocols, inconsistency reports."

10. **Add a "Validation Report" cross-reference** — Link this report from §11 or §12 so future sessions know the memory was validated and where the known gaps are.

---

## 12. Exit Criteria Assessment

| Criterion | Status |
|---|---|
| Codebase Memory is a trusted semantic source for architecture | **PASS** — architectural intent, workflows, module mapping all verified accurate |
| Codebase Memory is a trusted semantic source for business logic | **PASS with gap** — e-invoice domain missing but all other business flows verified |
| Codebase Memory is a trusted semantic source for planning | **PASS with caveats** — quantitative counts need updating; staging environment missing |
| No source code modified | **PASS** — READ ONLY mode maintained throughout |
| Graph queryable for future sessions | **PASS** — search_graph, query_graph, trace_path all confirmed operational |

**Verdict: VALIDATED WITH OBSERVATIONS.** The Codebase Memory is a trusted semantic source for architecture and business intent. 10 recommendations are provided to close quantitative and coverage gaps. No rebuild required — the existing memory plus this report's corrections are sufficient.
