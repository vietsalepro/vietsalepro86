# VietSalePro — Codebase Memory Baseline

> **Phase**: Codebase Memory Baseline Registration
> **Date**: 2026-07-23
> **Mode**: READ ONLY — no implementation, commit, deploy, or database changes
> **Authority**: This document is the official entry point for every future engineering session on VietSalePro.

---

## 1. Project

**VietSalePro** — multi-tenant SaaS POS + inventory + retail-management platform for the Vietnamese SMB market.

- **Stack**: React 19 + Vite 6 + TypeScript + Tailwind 4 + PWA frontend; Supabase (Postgres 17 + Auth + Storage + Realtime + Edge Functions) backend; Vercel deployment.
- **Surfaces**: (1) Tenant app — per-tenant retail workflow resolved by subdomain/custom domain; (2) Admin platform — system-admin SaaS control plane at the `admin` subdomain.
- **Domain**: Vietnamese retail — VND currency, Vietnamese-language UI, e-invoice providers (Sapo/m-Invoice/VNPT/Viettel), Vietnamese payment providers (Momo, VNPay, bank transfer) plus Stripe.

---

## 2. Semantic Memory Registration

| Field | Value |
|---|---|
| **Document** | `.codebase-memory/SEMANTIC_MEMORY.md` |
| **Version** | 1.0 (initial build) |
| **Build Date** | 2026-07-23 |
| **Commit Hash** | `ec0f317b` (`ec0f317b7bf31a2f70a2a46627759afca748dc9d`) |
| **Graph Size** | 28,881 nodes / 42,874 edges |
| **Index Mode** | `full` (all files + similarity/semantic edges) |
| **MCP Project** | `vietsalepro` (codebase-memory MCP) |
| **Persistence Artifact** | `.codebase-memory/graph.db.zst` (7.8MB compressed / 43MB original) |
| **Graph Queryability** | `search_graph` (BM25 + name_pattern + semantic), `query_graph` (Cypher), `trace_path` (calls/data_flow/cross_service) — all confirmed operational |
| **Node Labels** | Function, Method, Class, Interface, Route, Variable, Module, Package, File, Folder |

---

## 3. Validation Registration

| Field | Value |
|---|---|
| **Document** | `.codebase-memory/VALIDATION_REPORT.md` |
| **Validation Date** | 2026-07-23 |
| **Validation Phase** | PHASE_02_CODEBASE_MEMORY_VALIDATION |
| **Validation Status** | **VALIDATED WITH OBSERVATIONS** |
| **Confidence Score** | **78% overall** — HIGH for semantic/architectural queries, MEDIUM for quantitative queries |
| **Cross-validation Sources** | Repository filesystem, Supabase MCP (production `rsialbfjswnrkzcxarnj` + staging `shbmzvfcenbybvyzclem`), Vercel MCP (project `prj_UdCbqGpXxsBXVNGfz0fz02obBS6x`) |
| **Recommendations Issued** | 10 (target the knowledge base, not source code) |

### Confidence by Area

| Area | Confidence |
|---|---|
| Architecture & topology | HIGH (95%) |
| Business domain & workflows | HIGH (90%) |
| Module responsibility mapping | HIGH (90%) |
| Edge function inventory | HIGH (97%) |
| Database table inventory | MEDIUM (85%) |
| RPC inventory | LOW (35%) |
| Quantitative counts | LOW (60%) |
| Deployment & config | MEDIUM (85%) |
| Governance documentation | MEDIUM (70%) |

---

## 4. Knowledge Status

**CERTIFIED WITH OBSERVATIONS**

The Codebase Memory is the official engineering knowledge foundation for VietSalePro.

- The Semantic Memory is a **trusted semantic source for architecture, business flow, and module responsibility**.
- The Semantic Memory is **NOT a trusted source for exact quantitative counts** — multiple counts are stale or understated (see Known Limitations).
- The Validation Report is the **authoritative correction layer** that must be consulted alongside the Semantic Memory.
- The repository remains the **ultimate source of truth** and is consulted only when existing semantic knowledge is insufficient.
- **No rebuild required** — the existing memory plus the validation report's corrections are sufficient.

---

## 5. Knowledge Priority

Future engineering sessions consume information in this order. Each layer is consulted only when the layer above is insufficient.

```
Priority 1 — Codebase Memory (SEMANTIC_MEMORY.md + graph)
    ↓
Priority 2 — Validation Report (VALIDATION_REPORT.md)
    ↓
Priority 3 — Repository (source, migrations, docs)
    ↓
Priority 4 — Supabase MCP (production + staging)
    ↓
Priority 5 — Vercel MCP
```

**Repository rescanning is the exception, not the default workflow.** Rescan only when one of the following is true:
- Requested by the Production Owner, OR
- Semantic memory is missing required knowledge for the task, OR
- The validation report identifies uncertainty in the area being worked on.

---

## 6. Known Limitations

These are the certified gaps. They do not invalidate the baseline; they define where the Validation Report must be consulted and where repository/MCP consultation is expected.

### High-severity gaps

| # | Gap | Impact |
|---|---|---|
| L1 | **RPC count severely understated** — memory says "100+"; production has 297 unique business RPCs. ~237 RPCs are undocumented by name. | Future sessions may believe most RPCs are documented. Consult `docs/admin-dashboard/RPC_CONTRACTS.md` for the canonical full list, or query the graph. |
| L2 | **10 edge functions deployed from non-repo paths** (8 from `C:\Users\SUACAUBA\Downloads\Project\vietsale-pro-v7\...`, 2 from inline editor). | Deployed code may not match the repo source. Source-of-truth risk for those functions. |

### Medium-severity gaps

| # | Gap | Impact |
|---|---|---|
| L3 | **E-invoice domain missing** — 2 tables (`einvoice_config`, `einvoice_orders`) + 3 RPCs exist in production but are absent from §3/§5.1/§5.2. | Business domain gap; e-invoice is a Vietnamese compliance requirement. |
| L4 | **3 phantom tables documented** — `admin_2fa_backup_code_attempts`, `tenant_restore_snapshots`, `tenant_backup_jobs` are in memory but NOT in production. | Future sessions may write queries against non-existent tables. |
| L5 | **Staging Supabase project undocumented** — `shbmzvfcenbybvyzclem` (QLBH Staging Multi-Tenant) is not in §9.2. | Deployment/testing workflow context missing. |
| L6 | **3 edge functions verify_jwt=false in prod not documented** — `send-template-email`, `admin-health-check`, `webhook-delivery` accept unauthenticated calls in production but are not in §6.3/§9.2. | Security review gap. |

### Low-severity gaps

| # | Gap | Impact |
|---|---|---|
| L7 | **Page count inflated** (38 tenant vs 24 actual). | Navigation confusion; memory overstates surface area. |
| L8 | **ADMIN_DASHBOARD_PLAN/ (135 MD files) undocumented.** | Investigation context missing for future debugging. |
| L9 | **Quantitative counts systematically stale** — migrations 137 vs 147, root services 31 vs 32, tests 67 vs 70, utils 14 vs 17, root governance MDs 80+ vs 110. | Erosion of trust in memory's numeric claims. Treat all counts as approximate. |
| L10 | **"Other (8)" labels 12 tables** in §5.1. | Internal inconsistency. |
| L11 | **Component-level internals** — 140+ components categorized by folder/name only, not read individually. | Component semantic intent is inferred from naming, not verified. |
| L12 | **Edge function deployment state** — §6.3 reflects local `config.toml`, not production deployment state. | Local ≠ prod for verify_jwt on 3 functions (see L6). |

The full gap inventory, risk register (R1–R10), and 10 improvement recommendations are in `VALIDATION_REPORT.md` §10 and §11.

---

## 7. Update Policy

The Semantic Memory evolves incrementally. Do NOT rebuild the knowledge base for routine work.

### Minor Changes — NO baseline update required

Examples: bug fixes, UI changes, small refactors, dependency bumps, copy edits.

**Action:** Work from the existing memory. No baseline update. No rescan.

### Medium Changes — Run CODEBASE MEMORY INCREMENTAL UPDATE

Examples: new module, new service, new migration, new RPC, new Edge Function, new table.

**Action:** Update the affected sections of `SEMANTIC_MEMORY.md` only. Append a dated change note. Do not rebuild. Re-validate the touched area if the change alters architecture, business flow, or module responsibility.

### Major Changes — Run PHASE 01 → PHASE 02 again

Examples: architecture redesign, multi-tenant redesign, platform restructuring, technology migration.

**Action:** Full re-index via `index_repository` (mode `full`, persistence `true`), then re-run validation. Produce a new baseline document superseding this one.

---

## 8. Future Session Instructions

Every future engineering session on VietSalePro begins by consulting, in order:

1. **`.codebase-memory/SEMANTIC_MEMORY.md`** — architecture, business modules, workflows, schema, edge functions, services, routing, deployment.
2. **`.codebase-memory/VALIDATION_REPORT.md`** — known gaps, corrected counts, risk register, confidence by area.

Only consult the repository (Priority 3) when the existing semantic knowledge is insufficient for the task or the validation report flags uncertainty in the relevant area. Only consult Supabase MCP (Priority 4) and Vercel MCP (Priority 5) for live production/staging state that the memory does not capture.

When in doubt about a quantitative claim in the memory, trust the Validation Report's correction over the memory's figure. When in doubt about an architectural or business-flow claim, the memory is authoritative.

---

## 9. Exit Criteria

| Criterion | Status |
|---|---|
| A single official baseline exists | **PASS** — this document is the sole baseline; no prior baseline found. |
| Future engineering sessions understand how to consume the Codebase Memory | **PASS** — §5 (priority), §8 (instructions), §7 (update policy) define consumption. |
| Repository rescanning becomes the exception rather than the default | **PASS** — §5 limits rescanning to three explicit triggers. |
| The existing Semantic Memory becomes the official engineering knowledge foundation | **PASS** — §4 certifies it WITH OBSERVATIONS; §2 registers its provenance. |

---

## 10. Certification

**Certified With Observations** on 2026-07-23.

The VietSalePro Codebase Memory — comprising `SEMANTIC_MEMORY.md` (v1.0, built 2026-07-23 from commit `ec0f317b`, 28,881 nodes / 42,874 edges, `full` index mode) and `VALIDATION_REPORT.md` (validated 2026-07-23, 78% overall confidence, VALIDATED WITH OBSERVATIONS) — is registered as the official engineering knowledge baseline.

The Semantic Memory is the primary knowledge source. The Validation Report is the authoritative correction layer. The repository is the ultimate source of truth, consulted only when semantic knowledge is insufficient. No rebuild is required.
