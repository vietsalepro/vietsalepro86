# Architecture Specification Index

**Project:** VietSalePro
**Subsystem:** Enterprise Architecture Governance
**Program:** Deletion & Audit Architecture Remediation Program
**Document Name:** Architecture Specification Index
**Version:** 1.1
**Status:** Active Governance Standard
**Effective Date:** 2026-07-23
**Owner:** Chief Technical Advisor (Architecture Governance)
**Classification:** Governance Specification
**Parent Documents:**
- `Deletion_Audit_Architecture_Remediation_Program.md` (Master Program, v1.0)
- `01_Governance/Architecture_Specification_Program.md` (Specification Program, v1.1)
**Authority Model:** Production Owner → Chief Technical Advisor → Engineering Execution Agent

---

## 1. Purpose

This **Architecture Specification Index** (the Index) is the single navigation entry point for every Architecture Specification governed by the Architecture Specification Program. It is the **Enterprise Portfolio and Navigation Catalog** that organizes, classifies, and routes readers to all Architecture Specifications produced under the Deletion & Audit Architecture Remediation Program.

The Index defines **what** Specifications exist, **how** they are organized, and **how** they relate to one another and to the wider governance artifact chain. It does **not** define **how** Specifications are written — that is the exclusive responsibility of the Architecture Specification Program (Sections 1–40). It does **not** define program vision, principles, workstreams, or delivery sequencing — that is the exclusive responsibility of the Master Program.

### 1.1 Relationship with the Master Program

The Master Program establishes **why** the remediation exists, the guiding principles, the in-scope domains, the workstreams, the milestones, and the architecture exit criteria. The Index **shall** reference the Master Program as its parent and **shall not** duplicate its vision, principles, workstream definitions, or governance rules. Every Specification registered in this Index **shall** trace back to one or more Master Program workstreams (Master Program Section 10).

### 1.2 Relationship with the Architecture Specification Program

The Architecture Specification Program is the "Specification Constitution" governing how Specifications are written, reviewed, approved, versioned, traced, and accepted. The Index is a governed artifact **under** that Program. Specifically, the Index is the readable projection governed by **Section 36 (Index Governance)** of the Specification Program. The Index **shall** comply with Sections 31–40 of the Specification Program (identifier registry, status model, classification, dependency framework, registry, index governance, navigation, consistency, approval clarification, and expansion).

### 1.3 Relationship with the Registry

The **Architecture Specification Registry** (Specification Program Section 35) is the authoritative source of truth for Specification records. The Index is the **readable, navigable projection** of the Registry (Specification Program Section 36.8). The Registry is authoritative; the Index is derivative. Where the Registry exists, the Index **shall** be derived from it and **shall** be synchronized in the same change that updates the Registry (Section 36.3). Where the Registry has not yet been instantiated, this Index serves as the **initial portfolio catalog**; upon Registry instantiation, the Registry **shall** be back-populated from this Index and the Index **shall** thereafter remain a strict projection.

### 1.4 Relationship with Roadmaps, Implementation Plans, Verification, Acceptance, and ADRs

The Index **shall** provide navigation to, but **shall not** duplicate, the following downstream artifact classes (Specification Program Sections 4–8, 22, 37):

- **Roadmaps** — time-ordered delivery plans derived from one or more Specifications.
- **Implementation Plans** — engineering translation of baselined Specifications.
- **Verification** — conformance evidence against Specification requirement identifiers.
- **Acceptance** — formal acceptance records filed in the governance register.
- **ADRs** — decision rationale for significant choices inside a Specification.

The Index **shall** link to these artifacts where they exist and **shall** record their absence explicitly (e.g., "None recorded") rather than omitting the reference.

---

## 2. Repository Position

The Index occupies a fixed position in the governance hierarchy. It sits below the Governance layer (Specification Program) and above individual Specifications, acting as the routing layer between governance and the specification corpus.

```
Master Program
    │
    ▼
Governance
    ├── Architecture Specification Program (how Specifications are written)
    └── Architecture Specification Index   ← this document (portfolio & navigation)
        │
        ▼
Specifications (SPEC-NNN)
        │
        ▼
Roadmaps
        │
        ▼
Implementation Plans
        │
        ▼
Verification
        │
        ▼
Acceptance
        │
        ▼
ADRs
        │
        ▼
Evidence
```

The Index is the **only** artifact permitted to enumerate the full Specification portfolio. No other document **shall** claim to be the canonical catalog of Architecture Specifications (Specification Program Section 35.3 reserves that role for the Registry, of which this Index is the projection).

---

## 3. Enterprise Portfolio Overview

The Architecture Specification portfolio is the complete set of Architecture Specifications produced under the Master Program. The portfolio is organized to satisfy four concurrent needs:

1. **Discovery** — any reader (architect, reviewer, engineer, auditor, or future AI Agent) **shall** be able to locate every Specification from a single entry point.
2. **Classification** — every Specification **shall** carry a Classification (Specification Program Section 33) so that consumers can reason about expected content, dependencies, and consumers.
3. **Dependency reasoning** — the portfolio **shall** expose the dependency graph so that change impact can be assessed without traversing every document.
4. **Lifecycle visibility** — the portfolio **shall** expose the current Document Status (Specification Program Section 32) of every Specification so that program health is visible at a glance.

### 3.1 Why Specifications Are Separated

Specifications are separated by architectural concern, not by organizational team. Separation enforces the Master Program's principle that deletion, audit, transaction ownership, trigger governance, foreign-key policy, observability, and regression are distinct architectural domains, each owning its own invariants, contracts, and failure models. A single monolithic Specification would couple concerns that the Master Program explicitly decouples (Master Program Sections 3, 7, 10) and would make change impact untraceable.

### 3.2 How Navigation Works

Navigation is **top-down from this Index**. A reader enters via the Index, selects a Specification by ID or Classification, and descends through the artifact chain (Specification → Roadmap → Implementation Plan → Verification → Acceptance → ADR → Evidence). Every Specification **shall** link back to this Index (Specification Program Section 37.2), making navigation bidirectional. The Index **shall** use relative paths to all referenced artifacts (Specification Program Section 36.10).

---

## 4. Portfolio Structure

The portfolio is partitioned into logical groups aligned with the Classification Framework (Specification Program Section 33). Each group is a navigation bucket, not a governance layer; classification governance remains owned by the Specification Program.

### 4.1 Core Specifications

Foundational architectural domains that other Specifications depend on. They establish domain models, invariants, contracts, and failure/recovery models for a core concern. Core Specifications **may** be depended on by Supporting, Operational, and Platform Specifications. They consume the full mandatory template (Specification Program Section 16).

### 4.2 Supporting Specifications

Detail, extension, or refinement of a Core Specification. A Supporting Specification **shall** declare a mandatory dependency on its parent Core Specification and **shall not** duplicate the parent's domain model (Specification Program Section 33.2).

### 4.3 Operational Specifications

Define how an architecture is deployed, monitored, and operated. They map architectural components to operational responsibilities, runbooks, and observability. They depend on the Core Specification(s) they operationalize (Specification Program Section 33.4).

### 4.4 Migration Specifications

Define how to move from a current architecture to a target architecture. They **shall** declare mandatory dependencies on both the target and current-state Specifications (Specification Program Section 33.5).

### 4.5 Platform Specifications

Define shared platform capabilities consumed by multiple domains. They expose stable platform interfaces and avoid domain-specific logic (Specification Program Section 33.6).

### 4.6 Governance Specifications

Define governance itself — standards, processes, and rules for Specifications and artifacts. They remain meta-level and **shall not** prescribe domain architecture (Specification Program Section 33.7). This Index and the Architecture Specification Program are Governance Specifications.

### 4.7 Reference Specifications

Capture cross-cutting reference material (glossaries, patterns, conventions) used by many Specifications. They remain stable and avoid prescriptive requirements that belong in Core Specifications (Specification Program Section 33.3).

---

## 5. Master Specification Catalog

This section is the **initial official catalog** of Architecture Specifications. It registers Specifications by permanent Specification ID (Specification Program Section 31). Registration **does not** create, draft, or approve any Specification. A registered Specification is in the `Registered` or `Planned` Document Status (Specification Program Section 32) until an author drafts it through the approval flow (Section 11).

> **Note on the Registry:** The Architecture Specification Registry (Specification Program Section 35) is the authoritative source of truth. Until the Registry is instantiated as a separate artifact, this catalog is the canonical record of Specification IDs. Upon Registry instantiation, the Registry **shall** be back-populated from this catalog and this Index **shall** become its readable projection (Section 36.4).

### 5.1 Catalog Fields

Each Specification entry records the fields mandated by Specification Program Section 36.5 (Index mandatory fields) plus portfolio fields required for dependency reasoning and lifecycle visibility.

### 5.2 Catalog — SPEC-001 to SPEC-007

#### SPEC-001 — Delete Framework

| Field | Value |
|-------|-------|
| **Specification ID** | SPEC-001 |
| **Name** | Delete Framework Architecture Specification |
| **Classification** | Core |
| **Status** | Baselined |
| **Owner** | Chief Technical Advisor |
| **Priority** | P1 — Critical |
| **Current Phase** | Baselined |
| **Dependencies** | Mandatory: SPEC-002 (Audit Architecture), SPEC-003 (Transaction Architecture), SPEC-005 (Foreign Key Governance) |
| **Target Folder** | `02_Specifications/` |
| **Version** | 1.1 |
| **Baseline Date** | 2026-07-24 |
| **Short Description** | Canonical, reusable deletion pipeline for all in-scope domains; defines deletion lifecycle states, modes, and the single database-owned delete boundary. |

#### SPEC-002 — Audit Architecture

| Field | Value |
|-------|-------|
| **Specification ID** | SPEC-002 |
| **Name** | Audit Architecture Specification |
| **Classification** | Core |
| **Status** | Baselined |
| **Baseline Date** | 2026-07-24 |
| **Owner** | Chief Technical Advisor (to assign at Registered) |
| **Priority** | P1 — Critical |
| **Current Phase** | Not yet initiated |
| **Dependencies** | Mandatory: none (Master Program). Optional: SPEC-005 (Foreign Key Governance) for audit-independence reasoning. |
| **Target Folder** | `02_Specifications/` |
| **Version** | — (not yet drafted) |
| **Short Description** | Independent, append-only audit model where audit records survive the entities they describe; decouples audit from operational foreign keys. |

#### SPEC-003 — Transaction Architecture

| Field | Value |
|-------|-------|
| **Specification ID** | SPEC-003 |
| **Name** | Transaction Architecture Specification |
| **Classification** | Core |
| **Status** | Baselined |
| **Owner** | Chief Technical Advisor |
| **Priority** | P1 — Critical |
| **Current Phase** | Baselined |
| **Dependencies** | Mandatory: none (Master Program). |
| **Target Folder** | `02_Specifications/` |
| **Version** | 1.0 |
| **Baseline Date** | 2026-07-24 |
| **Short Description** | Canonical transaction ownership model for deletions; atomicity, rollback, and idempotent/compensatable side-effect handling outside the critical transaction. |

#### SPEC-004 — Trigger Governance

| Field | Value |
|-------|-------|
| **Specification ID** | SPEC-004 |
| **Name** | Trigger Governance Architecture Specification |
| **Classification** | Core |
| **Status** | Baselined |
| **Owner** | Chief Technical Advisor |
| **Priority** | P2 — Major |
| **Current Phase** | Baselined |
| **Dependencies** | Mandatory: SPEC-001 (Delete Framework). |
| **Target Folder** | `02_Specifications/` |
| **Version** | 1.0 |
| **Baseline Date** | 2026-07-24 |
| **Short Description** | Trigger classification, minimization, and removal of business-workflow logic from triggers; restricts triggers to low-level invariant guardrails. |

#### SPEC-005 — Foreign Key Governance

| Field | Value |
|-------|-------|
| **Specification ID** | SPEC-005 |
| **Name** | Foreign Key Governance Architecture Specification |
| **Classification** | Core |
| **Status** | Baselined |
| **Owner** | Chief Technical Advisor |
| **Priority** | P1 — Critical |
| **Current Phase** | Baselined |
| **Dependencies** | Mandatory: none (Master Program). |
| **Target Folder** | `02_Specifications/` |
| **Version** | 1.0 |
| **Baseline Date** | 2026-07-24 |
| **Short Description** | Explicit, reviewed `ON DELETE` contract for every foreign key; risk register and per-table policy preventing cascade surprises and undeletable subgraphs. |

#### SPEC-006 — Observability

| Field | Value |
|-------|-------|
| **Specification ID** | SPEC-006 |
| **Name** | Observability Architecture Specification |
| **Classification** | Operational |
| **Status** | Baselined |
| **Owner** | Chief Technical Advisor |
| **Priority** | P2 — Major |
| **Current Phase** | Baselined |
| **Dependencies** | Mandatory: SPEC-001 (Delete Framework). Optional: SPEC-002 (Audit Architecture). |
| **Target Folder** | `02_Specifications/` |
| **Version** | 1.1 |
| **Baseline Date** | 2026-07-24 |
| **Short Description** | Delete-lifecycle observability: correlation IDs, step-level tracking, structured errors, metrics, traces, logs, alerts, and dashboards tied to the failure model. |

#### SPEC-007 — Regression & Verification

| Field | Value |
|-------|-------|
| **Specification ID** | SPEC-007 |
| **Name** | Regression & Verification Architecture Specification |
| **Classification** | Reference |
| **Status** | Baselined |
| **Owner** | Chief Technical Advisor |
| **Priority** | P2 — Major |
| **Current Phase** | Baselined |
| **Dependencies** | Mandatory: SPEC-001 (Delete Framework). Optional: SPEC-002, SPEC-003, SPEC-004, SPEC-005, SPEC-006. |
| **Target Folder** | `02_Specifications/` |
| **Version** | 1.0 |
| **Baseline Date** | 2026-07-24 |
| **Short Description** | Mandatory regression coverage model for every delete path: integration, database, trigger, transaction, edge-function, real-database, and failure-recovery tests. |

### 5.3 Catalog Summary Table

| ID | Name | Classification | Status | Priority |
|----|-------|----------------|--------|----------|
| SPEC-001 | Delete Framework | Core | Baselined | P1 |
| SPEC-002 | Audit Architecture | Core | Planned | P1 |
| SPEC-003 | Transaction Architecture | Core | Baselined | P1 |
| SPEC-004 | Trigger Governance | Core | Baselined | P2 |
| SPEC-005 | Foreign Key Governance | Core | Baselined | P1 |
| SPEC-006 | Observability | Operational | Baselined | P2 |
| SPEC-007 | Regression & Verification | Reference | Baselined | P2 |

---

## 6. Dependency Overview

Dependencies follow the Specification Dependency Framework (Specification Program Section 34). The graph below uses the symbols defined in Section 34.1: `→` mandatory, `~>` optional. The graph **shall** remain acyclic (Section 34.4). No cycles are present in the initial portfolio.

### 6.1 Dependency Graph

```
                    Master Program
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
   SPEC-002          SPEC-003          SPEC-005
   (Audit)        (Transaction)         (FK)
        │                 │               │
        │   ~> (optional) │            ~> │ (optional, audit→FK)
        │                 │               │
        └────────┬────────┴───────┬───────┘
                 ▼                │
            SPEC-001  (Delete Framework)
                 │
        ┌────────┼─────────────────────┐
        ▼        ▼                     ▼
   SPEC-004   SPEC-006            SPEC-007
  (Trigger) (Observability)   (Regression & Verification)
                 │                     │
                 └──~> SPEC-002        └──~> SPEC-002/003/004/005/006
```

### 6.2 Dependency Matrix

| Specification | Mandatory Dependencies | Optional Dependencies |
|---------------|------------------------|------------------------|
| SPEC-001 | SPEC-002, SPEC-003, SPEC-005 | — |
| SPEC-002 | — | SPEC-005 |
| SPEC-003 | — | — |
| SPEC-004 | SPEC-001 | — |
| SPEC-005 | — | — |
| SPEC-006 | SPEC-001 | SPEC-002 |
| SPEC-007 | SPEC-001 | SPEC-002, SPEC-003, SPEC-004, SPEC-005, SPEC-006 |

### 6.3 Acyclicity Statement

The dependency graph contains no cycles. The three foundation Specifications (SPEC-002, SPEC-003, SPEC-005) have no mandatory dependencies and form the roots. SPEC-001 depends on the foundation set. SPEC-004, SPEC-006, and SPEC-007 depend on SPEC-001. Any future dependency addition **shall** be validated for acyclicity at every quality gate (Specification Program Section 34.6).

---

## 7. Specification Creation Order

This section recommends the enterprise authoring sequence. It is **advisory**; it does not override the Master Program's recommended implementation order (Master Program Section 19) or the Specification Program's lifecycle gating (Section 32). Authoring may begin only after a Specification ID is allocated and the Specification is in `Registered` status (Section 31.2).

### 7.1 Recommended Authoring Sequence

1. **SPEC-005 — Foreign Key Governance** (no mandatory dependencies). Establishes the explicit `ON DELETE` contract surface that audit independence and the delete framework rely on.
2. **SPEC-002 — Audit Architecture** (no mandatory dependencies). Establishes audit independence, which constrains delete design. Per Master Program Section 19, audit design precedes delete design.
3. **SPEC-003 — Transaction Architecture** (no mandatory dependencies). Establishes the atomicity and side-effect model the delete framework must operate within.
4. **SPEC-001 — Delete Framework** (mandatory: SPEC-002, SPEC-003, SPEC-005). The reusable pipeline; cannot be approved until its three foundation dependencies are baselined (Section 34.5).
5. **SPEC-004 — Trigger Governance** (mandatory: SPEC-001). Trigger rationalization is defined against the canonical delete framework.
6. **SPEC-006 — Observability** (mandatory: SPEC-001). Observability instruments the delete lifecycle defined by SPEC-001.
7. **SPEC-007 — Regression & Verification** (mandatory: SPEC-001). Verification requirements are defined against the contracts in SPEC-001 and reference the other Specifications as optional inputs.

### 7.2 Why Dependencies Matter

A Specification **shall not** declare a mandatory dependency on a Specification that is not yet `Baselined` (Specification Program Section 34.5). Therefore SPEC-001 cannot be approved before SPEC-002, SPEC-003, and SPEC-005 are baselined. Authoring the foundation Specifications first avoids a draft-state dependency that would block approval. The sequence above minimizes blocked states and aligns with the Master Program's principle that audit and transaction models constrain the delete design before it is fixed.

---

## 8. Lifecycle Dashboard

The Index exposes the Document Status (Specification Program Section 32) of every Specification. The Index **shall not** redefine the status model; it references Section 32 as the authoritative source. The dashboard is a read-only projection.

### 8.1 Status Set (Reference to Specification Program Section 32)

| Status | Meaning (summary) |
|--------|-------------------|
| Planned | Need identified; no ID allocated yet. |
| Registered | ID allocated; drafting not begun. |
| Draft | Author populating the mandatory template. |
| Review | Structured review in progress. |
| Revision Requested | Review findings require substantive author action. |
| Approved | Approval flow complete; Production Owner signed off. |
| Baselined | Approved version immutable except via Change Control. |
| Implementation Ready | Traceable to Roadmap and Implementation Plans. |
| Implementation Active | Implementation Plans executing. |
| Verified | Implemented system proven to conform. |
| Accepted | Formal acceptance recorded. |
| Deprecated | Superseded or no longer recommended for new use. |
| Archived | Permanently retired; retained for history. |

### 8.2 Current Portfolio Dashboard

| ID | Status | Owner | Last Review | Next Review |
|----|--------|-------|-------------|-------------|
| SPEC-001 | Baselined | Chief Technical Advisor | 2026-07-24 | At Implementation Plan |
| SPEC-002 | Baselined | Chief Technical Advisor | 2026-07-24 | At Implementation Plan |
| SPEC-003 | Baselined | Chief Technical Advisor | 2026-07-24 | At Implementation Plan |
| SPEC-004 | Baselined | Chief Technical Advisor | 2026-07-24 | At Implementation Plan |
| SPEC-005 | Baselined | Chief Technical Advisor | 2026-07-24 | At Implementation Plan |
| SPEC-006 | Baselined | Chief Technical Advisor | 2026-07-24 | At Implementation Plan |
| SPEC-007 | Baselined | Chief Technical Advisor | 2026-07-24 | At Implementation Plan |

The dashboard **shall** be refreshed at every status transition, every baseline, and every Program review (Specification Program Section 36.7).

---

## 9. Repository Navigation

This section restates the navigation rules applicable to the Index. The authoritative navigation rules are Specification Program Section 37; this section **shall not** contradict them.

### 9.1 Folder Hierarchy

```
ADMIN_DASHBOARD_PLAN_FIX_SPB/
├── 01_Governance/
│   ├── Architecture_Specification_Program.md
│   └── ARCHITECTURE_SPECIFICATION_INDEX.md   ← this document
├── 02_Specifications/
│   └── <ShortDomain>_Architecture_Specification_v<Major>_<Minor>.md
├── 03_Roadmaps/
├── 04_Implementation_Plans/
├── 05_Verification/
├── 06_ADRs/
└── index.md  (master artifact index, if instantiated)
```

### 9.2 Cross-Reference Rules

- Every cross-reference to a Specification **shall** use the form `SPEC-NNN vX.Y` (Specification Program Section 31.9).
- References using only a file name or Short Identifier **shall** be treated as defects.
- A Specification **shall not** reference a Specification ID that does not exist in this Index (and, when instantiated, the Registry).

### 9.3 Relative References

The Index **shall** use relative paths to all referenced artifacts (Specification Program Section 36.10). Absolute paths and host-specific paths **shall not** be used in normative navigation links.

### 9.4 Bidirectional Links

All traceability links **shall** be bidirectional (Specification Program Section 37.3). If the Index links to a Specification, that Specification **shall** link back to the Index. Broken bidirectional links **shall** be treated as defects and corrected in the next revision of the artifact that owns the broken side.

---

## 10. Traceability Matrix

The Index is the routing hub of the end-to-end traceability chain. The chain below is the authoritative shape (Specification Program Sections 22, 37.1).

```
Master Program
    │
    ▼
Architecture Specification Program
    │
    ▼
Architecture Specification Index   ← this document
    │
    ▼
Specification (SPEC-NNN)
    │
    ▼
Roadmap
    │
    ▼
Implementation Plan
    │
    ▼
Verification
    │
    ▼
Acceptance
    │
    ▼
ADR
    │
    ▼
Evidence
```

### 10.1 Per-Specification Traceability (Initial State)

| ID | Roadmap | Implementation Plan | Verification | Acceptance | ADRs |
|----|---------|---------------------|--------------|------------|------|
| SPEC-001 | None recorded | None recorded | None recorded | None recorded | None recorded |
| SPEC-002 | None recorded | None recorded | None recorded | None recorded | None recorded |
| SPEC-003 | None recorded | None recorded | None recorded | None recorded | None recorded |
| SPEC-004 | None recorded | None recorded | None recorded | None recorded | None recorded |
| SPEC-005 | None recorded | None recorded | None recorded | None recorded | None recorded |
| SPEC-006 | None recorded | None recorded | None recorded | None recorded | None recorded |
| SPEC-007 | None recorded | None recorded | None recorded | None recorded | None recorded |

"None recorded" is the explicit absence marker required by Specification Program Section 38, rule 6. It **shall not** be silently omitted.

---

## 11. Portfolio Governance

### 11.1 Portfolio Ownership

The Index **shall** be owned by the Chief Technical Advisor and maintained alongside the Registry (Specification Program Section 36.2). The Production Owner remains the sole final approval authority for any governance change to the Index (Specification Program Section 39; Authority Model).

### 11.2 Portfolio Updates

The Index **shall** be updated whenever the Registry is updated, in the same change, without deferral (Specification Program Section 36.3). Until the Registry exists, Index updates **shall** be performed by the Chief Technical Advisor and recorded in the program governance register.

### 11.3 Portfolio Review

The Index **shall** be reviewed at every Program review and at every baseline event (Specification Program Section 36.7). Broken navigation links **shall** be treated as defects.

### 11.4 Portfolio Versioning

The Index follows the Specification Program versioning policy (Section 12): Major for scope/structure change, Minor for clarification or added entries, Patch for editorial fixes. The first approved version is `1.0`.

### 11.5 Portfolio Change Control

Changes to the portfolio — adding, removing, reclassifying, or altering dependencies of a registered Specification — **shall** follow the Change Control classification (Specification Program Section 26, 34.8). Adding a mandatory dependency is a Major change; adding a new Specification entry is a Minor change to the Index.

### 11.6 Relationship with the Registry

The Registry is the source of truth; the Index is the readable projection (Specification Program Section 36.8). Any divergence is a defect and **shall** be corrected immediately (Section 36.4).

### 11.7 Relationship with the Specification Program

The Index is governed by the Specification Program (Sections 31–40). The Index **shall not** contradict the Specification Program and **shall not** redefine identifier, status, classification, or dependency rules.

### 11.8 Relationship with the Master Program

The Index references the Master Program as parent and **shall not** duplicate its content (Specification Program Section 36.9). Portfolio coverage **shall** map to Master Program workstreams.

---

## 12. Portfolio Expansion Strategy

The portfolio is designed to scale to at least 100 Architecture Specifications without structural redesign (Specification Program Section 40.1).

### 12.1 Adding New Specifications

1. A need is identified and linked to a Master Program workstream or architecture goal.
2. The Chief Technical Advisor allocates the next sequential `SPEC-NNN` from the single monotonic counter (Specification Program Section 31.2).
3. The Specification enters `Planned`, then `Registered` once an owner is assigned.
4. The Index **shall** be updated with the new entry in the same change that allocates the ID.
5. When the Registry exists, the Registry entry **shall** be created in the same change.

### 12.2 ID Allocation

- IDs **shall** be allocated in ascending order with no gaps introduced by rejection or withdrawal (Specification Program Section 31.2).
- `SPEC-000` is reserved and **shall not** be assigned (Section 31.3).
- The range `SPEC-900`–`SPEC-999` is reserved for governance, meta, and program-level documents; allocation from this range **shall** be approved by the Production Owner (Section 31.3).
- From `SPEC-1000` onward, four digits are used without re-padding earlier identifiers (Section 31.1).

### 12.3 Category Evolution

New Classifications **shall** be added only by revision of the Specification Program (Section 33), not by Index action. The Index **may** propose a new Classification to the Chief Technical Advisor but **shall not** introduce one unilaterally.

### 12.4 Future Workstream Registration

Future workstreams (e.g., bulk delete, soft-delete/archive, audit export, data residency, privacy-driven customer deletion — Master Program Section 17) **shall** be registered as new Specification entries with IDs allocated per Section 12.2 and dependencies declared per Section 34. Each future entry **shall** trace to a Master Program workstream.

### 12.5 Index Partitioning

At higher volumes, the Index **may** be split into per-Classification or per-domain sub-indexes, provided the top-level Index links to every sub-index and the synchronization rules (Specification Program Section 36.4) continue to hold (Section 40.2, rule 3).

### 12.6 Archived Specifications Remain Discoverable

Archived Specifications **shall** remain listed in the Index with status `Archived` and **shall** retain their Specification ID for historical traceability (Specification Program Section 31.8). Archived entries **shall** record the superseding Specification ID, if any.

---

## 13. Risks

Enterprise governance risks specific to portfolio and navigation are listed below. Each risk **shall** have an owner, likelihood, impact, and mitigation per Specification Program Section 16.20.

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Repository drift** — Index and Registry diverge over time. | Medium | High | Enforce same-change synchronization (Section 36.3); treat divergence as a defect. |
| **Duplicate Specifications** — Two entries cover the same concern. | Low | High | Single monotonic ID counter; Classification and dependency review at every quality gate. |
| **Broken references** — Index links to moved or renamed files. | Medium | Medium | Relative paths only (Section 36.10); bidirectional link checks at every review. |
| **Missing traceability** — Specifications lack Roadmap/Verification/Acceptance links. | Medium | High | Explicit "None recorded" markers (Section 38, rule 6); block progression until populated. |
| **Orphan Specifications** — A Specification exists but is not in the Index. | Low | High | Governance consistency rule: every Specification **shall** appear in the Index (Section 38, rule 2). |
| **Incorrect dependencies** — A declared dependency is missing, wrong-typed, or cyclical. | Medium | High | Dependency Review at every Review phase (Section 34.9); acyclicity validation at every quality gate. |
| **Portfolio inconsistency** — Status in Index differs from status in Specification metadata. | Medium | Medium | Index derived from Registry (Section 36.4); status transitions recorded in both. |
| **Premature implementation** — Implementation begins against a non-baselined Specification. | Low | Critical | Lifecycle gating (Section 32); only `Implementation Ready` may authorize implementation. |
| **Identifier reuse** — A retired ID is reassigned. | Low | Critical | Retired IDs **shall not** be reused (Section 31.8); Registry retains retired IDs as historical records. |

---

## 14. Acceptance Criteria

This Index is acceptable when all of the following measurable criteria are satisfied:

1. The Index resides in the designated governance folder and uses relative paths to all referenced artifacts.
2. Every Specification in the portfolio carries a permanent `SPEC-NNN` identifier allocated per Section 31.
3. Every Specification entry records: Specification ID, Name, Classification, Status, Owner, Priority, Current Phase, Dependencies, Target Folder, Version, and Short Description.
4. The dependency graph is acyclic and matches the dependency matrix.
5. The lifecycle dashboard reflects the current Document Status of every Specification.
6. The traceability matrix uses explicit "None recorded" markers where downstream artifacts do not yet exist.
7. No content duplicates the Master Program vision, principles, workstreams, or governance rules.
8. No content duplicates the Specification Program's identifier, status, classification, or dependency rules; the Index references them instead.
9. The Index contains no implementation details, API designs, database designs, Edge Function designs, or workflows.
10. The document uses normative language (shall, must, must not, should, may) consistent with the Specification Program style.
11. The portfolio structure scales to additional Specifications without structural redesign.

---

## 15. Evidence

### 15.1 Executive Summary

This document is the Architecture Specification Index for the Deletion & Audit Architecture Remediation Program. It is the single navigation entry point and enterprise portfolio for all Architecture Specifications. It registers seven Specifications (SPEC-001 through SPEC-007), classifies them, declares their dependencies, exposes their lifecycle status, and routes readers through the full governance artifact chain. It is a Governance Specification under the Architecture Specification Program and a derivative projection of the Architecture Specification Registry.

### 15.2 Portfolio Summary

- **Total Specifications registered:** 7
- **Core:** 5 (SPEC-001, SPEC-002, SPEC-003, SPEC-004, SPEC-005)
- **Operational:** 1 (SPEC-006)
- **Reference:** 1 (SPEC-007)
- **Supporting:** 0
- **Migration:** 0
- **Platform:** 0
- **Governance:** this Index (not numbered in the SPEC-NNN domain series; reserved range SPEC-900–SPEC-999 available if a governance document requires a domain ID).
- **Baselined:** 7 (SPEC-001, SPEC-002, SPEC-003, SPEC-004, SPEC-005, SPEC-006, SPEC-007)
- **Planned:** 0

### 15.3 Repository Diagram

```
Master Program
    │
    ▼
Governance
    ├── Architecture Specification Program (v1.1)
    └── Architecture Specification Index (v1.0)  ← this document
        │
        ▼
02_Specifications/
    ├── SPEC-001  Delete Framework          (Core)
    ├── SPEC-002  Audit Architecture        (Core)
    ├── SPEC-003  Transaction Architecture  (Core)
    ├── SPEC-004  Trigger Governance        (Core)
    ├── SPEC-005  Foreign Key Governance    (Core)
    ├── SPEC-006  Observability             (Operational)
    └── SPEC-007  Regression & Verification (Reference)
        │
        ▼
03_Roadmaps/ → 04_Implementation_Plans/ → 05_Verification/ → Acceptance → 06_ADRs/ → Evidence
```

### 15.4 Specification Inventory

See Section 5 (Master Specification Catalog) and Section 5.3 (Catalog Summary Table).

### 15.5 Dependency Summary

See Section 6 (Dependency Overview), Section 6.2 (Dependency Matrix), and Section 6.3 (Acyclicity Statement). The portfolio has three foundation roots (SPEC-002, SPEC-003, SPEC-005), one integrator (SPEC-001), and three dependents (SPEC-004, SPEC-006, SPEC-007). The graph is acyclic.

### 15.6 Risk Summary

See Section 13. The highest-impact risks are premature implementation against non-baselined Specifications, identifier reuse, and repository drift between Index and Registry. All are mitigated by existing Specification Program rules (Sections 32, 31.8, 36).

### 15.7 Assumptions

1. The Master Program (v1.0) and Architecture Specification Program (v1.1) remain the authoritative sources for program vision and specification governance respectively.
2. The Architecture Specification Registry (Specification Program Section 35) has not yet been instantiated as a separate artifact; this Index serves as the initial canonical catalog until the Registry is created, at which point the Index becomes its derivative projection.
3. The Production Owner and Chief Technical Advisor roles described in the Authority Model exist and hold the authority defined.
4. All Specifications will be authored in Markdown and stored under `02_Specifications/` per the folder structure (Specification Program Section 14).
5. The Index placement in `01_Governance/` alongside the Architecture Specification Program is consistent with the governance-folder convention; Specification Program Section 36.10 states the Index "shall reside at the repository root of the program directory." This Index is placed in the governance folder per the issuing directive. If a future review determines the program-directory root is required, the Index **shall** be relocated via Change Control without altering its content or ID.

### 15.8 Future Evolution

1. **Registry instantiation** — A separate Architecture Specification Registry artifact **should** be created to hold the full mandatory field set (Section 35.2); the Index **shall** then become its synchronized projection.
2. **Sub-index partitioning** — As the portfolio grows beyond an estimated 30–50 Specifications, per-Classification or per-domain sub-indexes **may** be introduced (Section 12.5).
3. **Future workstream registration** — Bulk delete, soft-delete/archive, audit export, data residency, and privacy-driven deletion workstreams (Master Program Section 17) **shall** be registered as new Specification entries when authorized.
4. **Tooling neutrality** — The Registry and Index **may** be backed by a tool or database at scale, provided the artifact format and mandatory fields remain unchanged (Specification Program Section 40.2, rule 5).
5. **Back-registration** — Any Specifications drafted before Registry instantiation **shall** be back-registered in the Registry in order of their existing baseline date (Specification Program v1.1 Impact Assessment).

---

## 16. Enterprise Architecture Repository Map

This section provides the complete map of the enterprise governance repository. It illustrates every governed artifact class, its position relative to the Master Program, and the boundaries that separate one artifact class from another. The map is **navigational and descriptive**; it **shall not** redefine the artifact templates, mandatory fields, or governance rules owned by the Specification Program (Sections 14–40) or the Master Program.

### 16.1 Repository Map

```
Enterprise Repository
    │
    ▼
Master Program
    │
    ▼
Governance
    ├── Architecture Specification Program
    ├── Architecture Specification Index          ← this document
    ├── Architecture Specification Registry
    ├── Naming Standard
    ├── Approval Standard
    ├── Review Standard
    └── Change Control
        │
        ▼
Specifications (SPEC-NNN)
        │
        ▼
Roadmaps
        │
        ▼
Implementation Plans
        │
        ▼
Verification
        │
        ▼
Acceptance
        │
        ▼
ADR
        │
        ▼
Evidence
        │
        ▼
Archive
```

### 16.2 Purpose

The Repository Map exists so that any reader — architect, reviewer, engineer, auditor, or future AI Agent — **shall** be able to orient themselves within the full governance repository from a single diagram. It prevents readers from entering the repository at an arbitrary artifact and mistaking a derivative artifact (e.g., a Roadmap) for an authoritative one (e.g., a baselined Specification). The map is the **spatial index** that complements the **logical index** in Section 5.

### 16.3 Navigation

Navigation **shall** proceed top-down from the Enterprise Repository root. A reader **shall** enter via the Master Program to understand **why**, descend into Governance to understand **how Specifications are written and governed**, enter this Index to discover **which Specifications exist**, then descend through the artifact chain (Specification → Roadmap → Implementation Plan → Verification → Acceptance → ADR → Evidence). The Archive is reachable from any artifact class that has been superseded or retired. Lateral navigation between sibling Specifications **shall** pass through this Index, not directly between Specifications, except where a declared dependency (Section 6) authorizes a direct cross-reference.

### 16.4 Ownership

| Artifact Class | Owner | Authority Reference |
|----------------|-------|---------------------|
| Master Program | Production Owner | Master Program; Authority Model |
| Architecture Specification Program | Chief Technical Advisor | Specification Program Sections 1–40 |
| Architecture Specification Index | Chief Technical Advisor | This document; Specification Program Section 36 |
| Architecture Specification Registry | Chief Technical Advisor | Specification Program Section 35 |
| Naming Standard | Chief Technical Advisor | Specification Program Section 31 |
| Approval Standard | Chief Technical Advisor | Specification Program Section 39 |
| Review Standard | Chief Technical Advisor | Specification Program Sections 24–25 |
| Change Control | Chief Technical Advisor | Specification Program Section 26 |
| Specifications | Specification Owner (assigned at Registered) | Specification Program Section 16 |
| Roadmaps | Specification Owner | Specification Program Section 4 |
| Implementation Plans | Engineering Execution Agent | Specification Program Section 5 |
| Verification | Engineering Execution Agent | Specification Program Section 6 |
| Acceptance | Production Owner | Specification Program Section 7 |
| ADR | Specification Owner | Specification Program Section 22 |
| Evidence | Engineering Execution Agent | Specification Program Section 8 |
| Archive | Chief Technical Advisor | Specification Program Section 31.8 |

The Production Owner remains the sole final approval authority for any change to governance-class artifacts (Authority Model). The Chief Technical Advisor maintains operational custody of all governance artifacts. Specification Owners maintain custody of their assigned domain Specifications and downstream artifacts.

### 16.5 Relationships

The repository is a **strict hierarchy with declared lateral dependencies**. Vertical relationships are parent-to-child (governs, derives, projects). Lateral relationships are dependency relationships declared per the Specification Dependency Framework (Specification Program Section 34) and recorded in Section 6 of this Index. The relationships are:

- The **Master Program governs** the Architecture Specification Program and this Index.
- The **Architecture Specification Program governs** how every Specification and governance artifact is written, reviewed, approved, versioned, and traced.
- The **Registry is the authoritative source of truth**; this Index is its readable projection (Section 1.3).
- A **Specification derives** a Roadmap; a Roadmap derives an Implementation Plan; an Implementation Plan produces Verification evidence; Verification supports Acceptance; ADRs record decisions inside a Specification; Evidence underpins the entire chain.
- The **Archive** receives retired or superseded artifacts but **shall not** sever their historical traceability links (Specification Program Section 31.8).
- The **Naming, Approval, Review, and Change Control standards** are cross-cutting governance instruments that apply to every artifact class below Governance.

### 16.6 Repository Boundaries

Each artifact class owns a non-overlapping responsibility. Boundary violations **shall** be treated as defects:

- The Master Program **shall not** contain Specification-level detail, API design, or implementation guidance.
- The Specification Program **shall not** contain domain architecture content; it is meta-level only.
- This Index **shall not** duplicate Specification content, Registry records, or Program rules (Section 1.2, 1.3).
- A Specification **shall not** duplicate the domain model of a Specification it depends on (Specification Program Section 33.2).
- A Roadmap **shall not** redefine Specification requirements; it sequences them.
- An Implementation Plan **shall not** contradict a baselined Specification; it translates it.
- Verification **shall not** introduce new requirements; it proves conformance to existing requirement identifiers.
- Acceptance **shall not** re-open Specification content; it records formal acceptance of the verified system.
- An ADR **shall not** override a Specification; it records rationale for choices made within the Specification's scope.
- Evidence **shall not** be authored as narrative; it **shall** reference concrete, reproducible artifacts.
- The Archive **shall not** be edited; archived artifacts are immutable historical records.

---

## 17. Portfolio Metrics Dashboard

This section defines the enterprise portfolio metrics that **shall** be computed from the Registry (authoritative) and projected in this Index. The metrics provide quantitative visibility into portfolio health, lifecycle progression, dependency integrity, and repository growth. The metrics are **read-only indicators**; they **shall not** alter the status model, governance rules, or artifact content.

### 17.1 Metric Set

| Metric | Definition | Source |
|--------|------------|--------|
| Registered Specifications | Count of Specifications with an allocated `SPEC-NNN`. | Registry / Section 5 |
| Draft | Count of Specifications in `Draft` status. | Registry / Section 8 |
| Review | Count of Specifications in `Review` or `Revision Requested` status. | Registry / Section 8 |
| Approved | Count of Specifications in `Approved` status. | Registry / Section 8 |
| Baselined | Count of Specifications in `Baselined` status. | Registry / Section 8 |
| Implementation Ready | Count of Specifications in `Implementation Ready` status. | Registry / Section 8 |
| Implementation Active | Count of Specifications in `Implementation Active` status. | Registry / Section 8 |
| Verified | Count of Specifications in `Verified` status. | Registry / Section 8 |
| Accepted | Count of Specifications in `Accepted` status. | Registry / Section 8 |
| Deprecated | Count of Specifications in `Deprecated` status. | Registry / Section 8 |
| Archived | Count of Specifications in `Archived` status. | Registry / Section 8 |
| Coverage % | Ratio of Specifications with a complete artifact chain (Roadmap → Evidence) to total registered Specifications. | Section 18 |
| Average Review Cycle | Mean elapsed time from `Review` entry to `Approved` exit, across all Specifications that have completed the cycle. | Registry |
| Average Approval Cycle | Mean elapsed time from `Approved` entry to `Baselined` exit, across all Specifications that have completed the cycle. | Registry |
| Open Risks | Count of risks in Section 13 (and per-Specification risk registers) with status Open. | Section 13 / Specifications |
| Closed Risks | Count of risks with status Closed. | Section 13 / Specifications |
| Broken References | Count of cross-references that fail bidirectional-link validation (Section 9.4). | Repository audit |
| Missing Traceability | Count of artifact-chain links marked "None recorded" (Section 10.1) beyond the initial portfolio state. | Section 10 |
| Dependency Count | Total declared dependencies (mandatory + optional) across the portfolio. | Section 6.2 |
| Repository Growth | Net change in registered Specification count since the last review. | Registry |
| Portfolio Health Score | Composite indicator derived from Coverage %, Broken References, Missing Traceability, and Open Risks (Section 17.3). | Section 17.3 |

### 17.2 Purpose

The metrics dashboard exists so that the Production Owner, Chief Technical Advisor, and reviewers **shall** have a single, quantitative view of portfolio state. It converts the qualitative portfolio overview (Section 3) into measurable indicators that support review decisions (Section 20), escalation (Section 21), and continuous improvement. The dashboard **shall not** replace the authoritative status records in the Registry; it **shall** be derived from them.

### 17.3 Portfolio Health Score Calculation

The Portfolio Health Score is a composite indicator in the range 0–100, where 100 represents a fully healthy portfolio. It **shall** be calculated as:

```
Health Score = 100
              − (Broken References × 5)
              − (Missing Traceability × 3)
              − (Open Risks × 2)
              + (Coverage % × 0.5)
```

The score **shall** be clamped to the range 0–100. A score below 60 **shall** trigger escalation per Section 21.3. The weights are initial defaults; the Chief Technical Advisor **may** recalibrate them by revision of this section, subject to Production Owner approval.

### 17.4 Review Frequency

The metrics dashboard **shall** be refreshed at every status transition, every baseline event, every Program review, and at minimum once per calendar quarter (Specification Program Section 36.7). Stale metrics older than one quarter **shall** be flagged as `Needs Update` in the Document Health Dashboard (Section 21).

---

## 18. Specification Coverage Matrix

This section defines governance for coverage mapping — the discipline of verifying that every registered Specification is supported by a complete artifact chain from Specification through Evidence, and that every Master Program workstream is covered by at least one Specification. Coverage is **structural completeness**, not content quality; content quality is governed by the Review Standard (Section 20, Specification Program Sections 24–25).

### 18.1 Coverage Chain

```
Master Program
    │
    ▼
Workstream
    │
    ▼
Specification (SPEC-NNN)
    │
    ▼
Roadmap
    │
    ▼
Implementation Plan
    │
    ▼
Verification
    │
    ▼
Acceptance
    │
    ▼
Evidence
```

A Specification is **fully covered** when every link in the chain above exists and is populated. A Specification is **partially covered** when one or more links are marked "None recorded" (Section 10.1). A Master Program workstream is **covered** when at least one registered Specification traces to it (Master Program Section 10).

### 18.2 Coverage Completeness

Coverage completeness **shall** be assessed per Specification and per Workstream:

- **Per Specification:** every link in the chain (Specification → Roadmap → Implementation Plan → Verification → Acceptance → Evidence) **shall** exist or be explicitly marked "None recorded." Silent omission is a defect (Specification Program Section 38, rule 6).
- **Per Workstream:** every Master Program workstream **shall** be traced to by at least one registered Specification. An uncovered workstream **shall** be recorded as a coverage gap (Section 18.4).

### 18.3 Coverage Validation

Coverage **shall** be validated at every quality gate (Specification Program Section 25), at every baseline event, and at every Program review (Section 20). Validation **shall** confirm:

1. Every registered Specification appears in this Index (Section 5).
2. Every Specification entry in this Index appears in the Registry (when instantiated).
3. Every cross-reference uses the `SPEC-NNN vX.Y` form (Section 9.2).
4. Every dependency declared in Section 6 is reflected in the dependent Specification's metadata.
5. Every artifact-chain link is either populated or explicitly marked "None recorded."
6. Every Master Program workstream has at least one tracing Specification or a recorded gap.

### 18.4 Gap Identification

A coverage gap is any missing link or uncovered workstream identified during validation (Section 18.3). Gaps **shall** be recorded with:

| Field | Value |
|-------|-------|
| **Gap ID** | GAP-NNN (sequential, never reused) |
| **Type** | Missing artifact / Uncovered workstream / Broken reference |
| **Affected Specification** | SPEC-NNN or "Workstream-level" |
| **Affected Workstream** | Master Program workstream name |
| **Severity** | Critical / Major / Minor |
| **Owner** | Specification Owner or Chief Technical Advisor |
| **Status** | Open / In Remediation / Closed |
| **Target Resolution** | Phase or date |

Gaps **shall** be reviewed at every Program review (Section 20) until closed. A Critical gap **shall** block progression of the affected Specification to the next lifecycle state.

### 18.5 Coverage Ownership

- The **Chief Technical Advisor** owns portfolio-level coverage (workstream-to-Specification mapping, Index-Registry synchronization).
- The **Specification Owner** owns per-Specification coverage (artifact-chain completeness for their assigned Specification).
- The **Production Owner** owns approval of any decision to accept a coverage gap as a permanent exception.

---

## 19. Portfolio Ownership Matrix

This section defines the ownership roles for the enterprise portfolio. It **shall not** redefine the Authority Model (Production Owner → Chief Technical Advisor → Engineering Execution Agent); it elaborates the responsibilities, authority, boundaries, and required actions of each role **within** that model. Where this section and the Authority Model conflict, the Authority Model prevails.

### 19.1 Portfolio Owner

| Attribute | Definition |
|-----------|------------|
| **Role** | Production Owner |
| **Responsibilities** | Final approval authority for all governance changes; approval of Specification baseline, acceptance, deprecation, and archival; approval of new workstream registration. |
| **Authority** | Sole authority to approve, reject, or defer any governance or Specification change. |
| **Boundaries** | **Shall not** author Specifications, Roadmaps, or Implementation Plans. **Shall not** override the Authority Model. |
| **Required Actions** | Review and sign off on baseline, acceptance, deprecation, archival, and Change Control decisions (Specification Program Section 39). |
| **Relationship with Authority Model** | Apex of the Authority Model. |

### 19.2 Specification Owner

| Attribute | Definition |
|-----------|------------|
| **Role** | Assigned at `Registered` status by the Chief Technical Advisor. |
| **Responsibilities** | Author and maintain the assigned Specification through Draft, Review, Revision, Approved, and Baselined; maintain the Specification's ADRs and risk register; ensure artifact-chain completeness (Section 18). |
| **Authority** | Authority to draft and revise the Specification within its Classification and dependency scope; authority to propose ADRs. |
| **Boundaries** | **Shall not** approve their own Specification. **Shall not** declare dependencies on non-baselined Specifications (Section 7.2). **Shall not** modify governance rules. |
| **Required Actions** | Respond to review findings; maintain traceability links; update the Specification at every relevant lifecycle transition. |
| **Relationship with Authority Model** | Reports to the Chief Technical Advisor; subject to Production Owner approval. |

### 19.3 Reviewer

| Attribute | Definition |
|-----------|------------|
| **Role** | Designated reviewer(s) assigned during the Review phase (Specification Program Section 24). |
| **Responsibilities** | Review the Specification against the mandatory template, classification rules, dependency framework, and traceability requirements; file review findings. |
| **Authority** | Authority to request revisions, approve progression to `Approved`, or reject with cause. |
| **Boundaries** | **Shall not** author the Specification under review. **Shall not** approve a Specification with unresolved Critical findings. |
| **Required Actions** | Complete the review within the Review Standard cycle; record findings with severity and required action. |
| **Relationship with Authority Model** | Reports to the Chief Technical Advisor; review authority delegated by the Production Owner. |

### 19.4 Maintainer

| Attribute | Definition |
|-----------|------------|
| **Role** | Engineering Execution Agent or designated engineer responsible for Implementation Plans, Verification, and Evidence. |
| **Responsibilities** | Translate baselined Specifications into Implementation Plans; produce Verification evidence against requirement identifiers; maintain Evidence artifacts. |
| **Authority** | Authority to implement and verify within the scope of a baselined Specification and its Roadmap. |
| **Boundaries** | **Shall not** modify a baselined Specification (Change Control required). **Shall not** begin implementation before `Implementation Ready` (Section 13). |
| **Required Actions** | Produce reproducible Evidence; update Verification status; report implementation blockers. |
| **Relationship with Authority Model** | Reports to the Chief Technical Advisor; implementation authority delegated by the Production Owner. |

### 19.5 Custodian

| Attribute | Definition |
|-----------|------------|
| **Role** | Chief Technical Advisor (operational custody of governance artifacts). |
| **Responsibilities** | Maintain the Index, Registry, Naming Standard, Approval Standard, Review Standard, and Change Control; perform same-change synchronization (Section 11.2); maintain the Archive. |
| **Authority** | Authority to update governed artifacts within approved governance rules; authority to allocate Specification IDs (Section 12.2). |
| **Boundaries** | **Shall not** approve governance changes (Production Owner authority). **Shall not** author domain Specifications. |
| **Required Actions** | Synchronize Index and Registry; maintain bidirectional links (Section 9.4); preserve archived artifacts immutably. |
| **Relationship with Authority Model** | Middle tier of the Authority Model; operational custody with Production Owner approval gate. |

### 19.6 Approver

| Attribute | Definition |
|-----------|------------|
| **Role** | Production Owner (for governance and baseline decisions); Reviewer (for Review-phase progression). |
| **Responsibilities** | Render approval or rejection decisions at each defined gate (Specification Program Section 39). |
| **Authority** | Binding approval authority at the gate they own. |
| **Boundaries** | **Shall not** approve artifacts for which they are also the author (separation of authorship and approval). |
| **Required Actions** | Record approval decisions with rationale and date in the governance register. |
| **Relationship with Authority Model** | Production Owner is the apex approver; Reviewer authority is delegated. |

### 19.7 Archive Owner

| Attribute | Definition |
|-----------|------------|
| **Role** | Chief Technical Advisor. |
| **Responsibilities** | Maintain the Archive; ensure retired IDs are not reused (Section 13); ensure archived artifacts retain historical traceability links; ensure superseding Specification IDs are recorded. |
| **Authority** | Authority to move artifacts to the Archive upon Production Owner approval of deprecation/archival. |
| **Boundaries** | **Shall not** edit archived artifacts. **Shall not** sever historical links. |
| **Required Actions** | Record archival date, superseding ID, and archival rationale. |
| **Relationship with Authority Model** | Operational custody under Production Owner approval. |

### 19.8 Repository Administrator

| Attribute | Definition |
|-----------|------------|
| **Role** | Chief Technical Advisor. |
| **Responsibilities** | Maintain repository structure (Section 9.1); enforce relative-path rules (Section 9.3); perform repository, navigation, traceability, and dependency audits (Section 20). |
| **Authority** | Authority to restructure the repository within approved governance rules; authority to flag and correct broken references. |
| **Boundaries** | **Shall not** alter artifact content during structural maintenance. **Shall not** renumber Specifications. |
| **Required Actions** | Conduct audits per the Review Schedule (Section 20); report findings to the Production Owner. |
| **Relationship with Authority Model** | Operational custody under Production Owner approval for structural changes. |

---

## 20. Portfolio Review Schedule

This section defines the review governance for the portfolio. It establishes the cadence, triggers, owners, and deliverables for each review type. Reviews **shall not** re-open approved content except through Change Control (Specification Program Section 26); their purpose is to verify continued consistency, integrity, and health of the repository.

### 20.1 Quarterly Review

| Attribute | Definition |
|-----------|------------|
| **Purpose** | Verify portfolio health, coverage, and metrics freshness; confirm no drift between Index and Registry; review open risks and gaps. |
| **Owner** | Chief Technical Advisor. |
| **Trigger** | Calendar quarter boundary. |
| **Deliverables** | Updated metrics dashboard (Section 17); updated health dashboard (Section 21); open risk and gap status; recommendation to the Production Owner. |

### 20.2 Annual Review

| Attribute | Definition |
|-----------|------------|
| **Purpose** | Comprehensive portfolio review; confirm continued alignment with the Master Program; review Classification framework adequacy; assess expansion strategy (Section 12). |
| **Owner** | Production Owner (with Chief Technical Advisor). |
| **Trigger** | Calendar year boundary. |
| **Deliverables** | Annual portfolio report; Classification framework review; expansion recommendation; approval of any governance revision. |

### 20.3 Phase Review

| Attribute | Definition |
|-----------|------------|
| **Purpose** | Review the portfolio at the boundary of a Master Program phase or milestone; confirm exit criteria satisfaction. |
| **Owner** | Chief Technical Advisor. |
| **Trigger** | Master Program phase or milestone boundary. |
| **Deliverables** | Phase coverage report; lifecycle progression summary; phase risk assessment. |

### 20.4 Milestone Review

| Attribute | Definition |
|-----------|------------|
| **Purpose** | Review the portfolio at a specific Master Program milestone; confirm that milestone-relevant Specifications have reached the required lifecycle state. |
| **Owner** | Chief Technical Advisor. |
| **Trigger** | Master Program milestone declared. |
| **Deliverables** | Milestone readiness report; list of Specifications at required state; list of blockers. |

### 20.5 Emergency Review

| Attribute | Definition |
|-----------|------------|
| **Purpose** | Address a Critical risk, broken reference, or governance defect that threatens portfolio integrity or production safety. |
| **Owner** | Chief Technical Advisor (convenes); Production Owner (approves remediation). |
| **Trigger** | Critical risk escalation (Section 21.3); production incident traceable to a Specification defect; detected cyclical dependency. |
| **Deliverables** | Emergency remediation plan; root cause record; Change Control request if Specification content is affected. |

### 20.6 Repository Audit

| Attribute | Definition |
|-----------|------------|
| **Purpose** | Verify repository structure, file placement, and naming conformance (Section 9, Specification Program Section 14). |
| **Owner** | Repository Administrator (Chief Technical Advisor). |
| **Trigger** | Quarterly Review; any structural change. |
| **Deliverables** | Repository structure report; list of misplaced or misnamed artifacts; remediation actions. |

### 20.7 Navigation Audit

| Attribute | Definition |
|-----------|------------|
| **Purpose** | Verify that all cross-references use the `SPEC-NNN vX.Y` form (Section 9.2), all paths are relative (Section 9.3), and all links are bidirectional (Section 9.4). |
| **Owner** | Repository Administrator (Chief Technical Advisor). |
| **Trigger** | Quarterly Review; any Specification addition, reclassification, or archival. |
| **Deliverables** | Navigation report; list of broken references; list of missing bidirectional links. |

### 20.8 Traceability Audit

| Attribute | Definition |
|-----------|------------|
| **Purpose** | Verify that every registered Specification has a complete or explicitly marked artifact chain (Section 10, Section 18). |
| **Owner** | Repository Administrator (Chief Technical Advisor). |
| **Trigger** | Quarterly Review; any baseline or acceptance event. |
| **Deliverables** | Traceability report; list of missing traceability links; coverage gap update (Section 18.4). |

### 20.9 Dependency Audit

| Attribute | Definition |
|-----------|------------|
| **Purpose** | Verify that the dependency graph (Section 6) remains acyclic, matches Specification metadata, and that no mandatory dependency targets a non-baselined Specification (Section 7.2). |
| **Owner** | Repository Administrator (Chief Technical Advisor). |
| **Trigger** | Quarterly Review; any dependency declaration or change. |
| **Deliverables** | Dependency report; acyclicity confirmation; list of dependency defects. |

---

## 21. Document Health Dashboard

This section defines the enterprise health indicators applied to every governed artifact in the repository. Health is **structural and lifecycle integrity**, not content quality; content quality is governed by the Review Standard (Section 20, Specification Program Sections 24–25). The dashboard is a read-only projection derived from the metrics (Section 17), coverage matrix (Section 18), and audits (Section 20).

### 21.1 Health Indicators

| Indicator | Meaning |
|-----------|---------|
| Healthy | Artifact is current, correctly placed, fully traced, and free of broken references. |
| Needs Review | Artifact has not been reviewed within the Review Schedule cadence (Section 20). |
| Needs Update | Artifact's metrics or status are stale beyond one quarter (Section 17.4). |
| Broken References | Artifact contains cross-references that fail validation (Section 9.2–9.4). |
| Missing Dependencies | Artifact declares a dependency on a Specification that is not baselined or not registered. |
| Missing Traceability | Artifact has artifact-chain links marked "None recorded" beyond the initial portfolio state. |
| Deprecated | Artifact is in `Deprecated` status; retained but not recommended for new use. |
| Archived | Artifact is in `Archived` status; immutable historical record. |
| Blocked | Artifact cannot progress to the next lifecycle state due to an open Critical risk or gap. |
| Incomplete | Artifact is missing mandatory template fields (Specification Program Section 16). |

### 21.2 Detection

Health indicators **shall** be detected by:

- **Automated validation** (where tooling exists): bidirectional link checks, relative-path checks, `SPEC-NNN vX.Y` form checks, acyclicity checks, mandatory-field presence checks.
- **Audit findings** (Section 20.6–20.9): repository, navigation, traceability, and dependency audits.
- **Review findings** (Specification Program Section 24): reviewer-recorded defects.
- **Metrics computation** (Section 17): stale metrics, open risks, coverage gaps.

Where automated validation is unavailable, manual audit **shall** be performed per the Review Schedule (Section 20). The absence of tooling **shall not** excuse a health indicator from detection.

### 21.3 Thresholds and Escalation

| Indicator | Threshold | Escalation |
|-----------|-----------|------------|
| Broken References | Any count > 0 | Flag in Quarterly Review; remediate in same quarter. |
| Missing Dependencies | Any mandatory dependency on a non-baselined Specification | Block progression to `Approved`; escalate to Chief Technical Advisor. |
| Missing Traceability | Any "None recorded" beyond initial portfolio state | Flag in Traceability Audit; remediate before `Implementation Ready`. |
| Blocked | Any open Critical risk or gap | Escalate to Production Owner via Emergency Review (Section 20.5). |
| Needs Update | Metrics older than one quarter | Flag in Quarterly Review; refresh within the quarter. |
| Portfolio Health Score < 60 | Composite score below threshold | Escalate to Production Owner; trigger remediation plan. |

Escalation **shall** follow the Authority Model: Repository Administrator → Chief Technical Advisor → Production Owner. The Production Owner **shall** be informed of any Critical escalation within one business day of detection.

---

## 22. Change Impact Matrix

This section defines governance for how a Specification change propagates through the repository. It **shall not** redefine the Change Control classification (Specification Program Section 26); it describes the **propagation path** and the **review and approval requirements** triggered along that path. Impact assessment is mandatory before any Change Control request is approved.

### 22.1 Propagation Path

```
Specification (changed)
    │
    ▼
Dependent Specifications (mandatory + optional)
    │
    ▼
Roadmaps (derived from changed or dependent Specifications)
    │
    ▼
Implementation Plans (translating changed Roadmaps)
    │
    ▼
Verification (re-verification of affected requirement identifiers)
    │
    ▼
Acceptance (re-acceptance if contracts changed)
    │
    ▼
Evidence (regeneration of affected evidence)
```

A change to a Specification **shall** propagate downward through every artifact derived from it. A change to a Specification with dependents **shall** also propagate laterally to every dependent Specification, because a change to a dependency may invalidate the dependent's assumptions.

### 22.2 Impact Assessment

Before a Change Control request is approved, an impact assessment **shall** be performed and recorded with:

| Field | Value |
|-------|-------|
| **Change ID** | CHG-NNN (sequential, never reused) |
| **Changed Specification** | SPEC-NNN vX.Y |
| **Change Classification** | Major / Minor / Patch (Specification Program Section 26) |
| **Affected Specifications** | List of dependent SPEC-NNN (mandatory and optional) |
| **Affected Roadmaps** | List of derived Roadmaps |
| **Affected Implementation Plans** | List of translating Implementation Plans |
| **Affected Verification** | List of requirement identifiers requiring re-verification |
| **Affected Acceptance** | Yes / No (contracts changed?) |
| **Affected Evidence** | List of Evidence artifacts requiring regeneration |
| **Assessor** | Chief Technical Advisor |
| **Assessment Date** | ISO date |

The impact assessment **shall** identify every artifact in the propagation path (Section 22.1) that is affected. An assessment that omits a known dependent **shall** be treated as a defect.

### 22.3 Review Requirements

- A **Patch** change **shall** require review of the changed Specification only.
- A **Minor** change **shall** require review of the changed Specification and confirmation that dependent Specifications are not affected.
- A **Major** change **shall** require review of the changed Specification **and** every affected dependent Specification, Roadmap, and Implementation Plan. Affected Verification **shall** be re-run for the affected requirement identifiers.

### 22.4 Approval Requirements

- **Patch** changes **shall** be approved by the Chief Technical Advisor.
- **Minor** changes **shall** be approved by the Chief Technical Advisor with recorded confirmation of no dependent impact.
- **Major** changes **shall** be approved by the Production Owner, because they may alter baselined contracts and require re-acceptance (Specification Program Section 39).
- Any change that alters a baselined Specification **shall** follow Change Control (Specification Program Section 26) regardless of classification.

---

## 23. Navigation Scenarios

This section provides navigation guidance for the principal reader personas who enter the repository. Each scenario defines the **canonical reading order** for that persona. Scenarios are **advisory guidance**; they **shall not** override the navigation rules in Section 9 or Specification Program Section 37.

### 23.1 Enterprise Architect

```
Index
    │
    ▼
Specification
    │
    ▼
ADR
    │
    ▼
Implementation
```

The Enterprise Architect enters via the Index to survey the portfolio, selects a Specification to understand a domain's architecture, reads the ADRs to understand significant design decisions, and reviews the Implementation to confirm architectural intent is realized.

### 23.2 Engineer

```
Index
    │
    ▼
Specification
    │
    ▼
Verification
```

The Engineer enters via the Index to locate the Specification governing their task, reads the baselined Specification to understand contracts and requirements, and consults Verification to understand what conformance evidence exists and what must be produced.

### 23.3 Auditor

```
Index
    │
    ▼
Evidence
```

The Auditor enters via the Index to locate the portfolio, selects the Specifications in scope for the audit, and descends directly to Evidence to verify conformance. The Auditor **may** ascend from Evidence to Verification to Acceptance to confirm the full chain.

### 23.4 Reviewer

```
Index
    │
    ▼
Acceptance
```

The Reviewer enters via the Index to locate the Specification under review, confirms the Specification's status and dependencies, and examines Acceptance records to understand prior acceptance decisions and conditions.

### 23.5 Future AI Agent

```
Master Program
    │
    ▼
Architecture Specification Program
    │
    ▼
Index
    │
    ▼
Specification
    │
    ▼
Roadmap
    │
    ▼
Implementation
    │
    ▼
Verification
    │
    ▼
Evidence
```

The Future AI Agent **shall** begin at the Master Program (why), descend through the Architecture Specification Program (how Specifications are governed), enter the Index (which Specifications exist), and traverse the full artifact chain in order. This is the mandatory reading order for AI consumption; see Section 27 for the full AI Consumption Rules.

---

## 24. Repository KPIs

This section defines measurable repository Key Performance Indicators. KPIs are **quantitative targets**, distinct from the metrics in Section 17 (which are measurements). Each KPI defines a target that the portfolio **should** meet to be considered well-governed. KPIs **shall not** be used as approval gates unless explicitly stated; they are governance health targets.

| KPI | Definition | Target |
|-----|------------|--------|
| Portfolio Completeness | Percentage of Master Program workstreams covered by at least one registered Specification. | 100% |
| Specification Completion | Percentage of registered Specifications with a complete artifact chain (Section 18). | ≥ 90% at steady state |
| Review Completion | Percentage of Specifications in `Review` that complete the review cycle within the Review Standard duration. | ≥ 95% |
| Dependency Accuracy | Percentage of declared dependencies that match Specification metadata and pass acyclicity validation. | 100% |
| Traceability Coverage | Percentage of artifact-chain links populated (not "None recorded") beyond the initial portfolio state. | ≥ 95% |
| Broken Link Rate | Broken references per registered Specification. | 0 |
| Repository Consistency | Percentage of artifacts correctly placed and named per Section 9 and Specification Program Section 14. | 100% |
| Average Review Duration | Mean elapsed time from `Review` entry to `Approved` exit. | ≤ 10 business days |
| Average Approval Duration | Mean elapsed time from `Approved` entry to `Baselined` exit. | ≤ 5 business days |
| Repository Expansion | Net new registered Specifications per quarter. | Tracked, no fixed target |
| Governance Compliance | Percentage of governance artifacts (Index, Registry, standards) current per the Review Schedule (Section 20). | 100% |

KPIs **shall** be reported in the Quarterly Review (Section 20.1) and Annual Review (Section 20.2). Persistent failure to meet a target **shall** trigger a remediation plan approved by the Chief Technical Advisor.

---

## 25. Enterprise Glossary

This section is the official terminology glossary for the enterprise architecture governance portfolio. Terms defined here **shall** be used consistently across all governed artifacts. Where a term is defined in the Specification Program or Master Program, those definitions prevail; this glossary restates them for Index-reader convenience and **shall not** contradict them.

| Term | Definition |
|------|------------|
| **Architecture** | The structured set of architectural decisions, contracts, and invariants governing a domain, as captured in Specifications. |
| **Specification** | A governed artifact that defines the architecture of a single concern, authored under the mandatory template (Specification Program Section 16) and identified by a permanent `SPEC-NNN`. |
| **Portfolio** | The complete set of Architecture Specifications produced under the Master Program, organized and navigated via this Index. |
| **Registry** | The Architecture Specification Registry (Specification Program Section 35); the authoritative source of truth for Specification records. |
| **Index** | This document; the readable, navigable projection of the Registry and the single navigation entry point for the portfolio. |
| **Governance** | The set of standards, processes, and rules that control how Specifications are written, reviewed, approved, versioned, traced, and accepted. |
| **ADR** | Architecture Decision Record; the artifact recording rationale for a significant decision inside a Specification (Specification Program Section 22). |
| **Roadmap** | A time-ordered delivery plan derived from one or more baselined Specifications. |
| **Implementation** | The engineering translation of a baselined Specification into an Implementation Plan and executing code. |
| **Verification** | The artifact and process that proves the implemented system conforms to Specification requirement identifiers. |
| **Acceptance** | The formal record that the Production Owner accepts the verified system (Specification Program Section 7). |
| **Evidence** | The concrete, reproducible artifacts underpinning Verification and the full traceability chain. |
| **Baseline** | An approved version of a Specification that is immutable except via Change Control (Specification Program Section 32). |
| **Registered** | The Document Status of a Specification that has an allocated ID but has not yet been drafted. |
| **Approved** | The Document Status of a Specification that has completed the approval flow and received Production Owner sign-off. |
| **Archived** | The Document Status of a permanently retired Specification; retained immutably for historical traceability. |
| **Dependency** | A declared relationship between Specifications per the Specification Dependency Framework (Specification Program Section 34); mandatory (`→`) or optional (`~>`). |
| **Traceability** | The bidirectional chain of links from Master Program through Specification through Evidence (Section 10). |
| **Classification** | The category assigned to a Specification per the Classification Framework (Specification Program Section 33); e.g., Core, Supporting, Operational, Migration, Platform, Governance, Reference. |

---

## 26. Portfolio Lifecycle

This section defines the lifecycle of the entire portfolio, from need identification through archive. It **shall not** redefine the per-Specification Document Status model (Specification Program Section 32); it describes the **portfolio-level transitions** that govern how the portfolio as a whole evolves. Per-Specification lifecycle transitions remain governed by Section 32 and Section 11.

### 26.1 Lifecycle Stages

```
Need Identified
    │
    ▼
Registered
    │
    ▼
Specification Created
    │
    ▼
Review
    │
    ▼
Baseline
    │
    ▼
Implementation
    │
    ▼
Verification
    │
    ▼
Acceptance
    │
    ▼
Maintenance
    │
    ▼
Deprecation
    │
    ▼
Archive
```

### 26.2 Transitions

| Transition | From → To | Trigger | Governance |
|------------|-----------|---------|------------|
| Need Identified → Registered | A Master Program workstream or architecture goal identifies a need. | Chief Technical Advisor allocates `SPEC-NNN` (Section 12.2). | ID allocation recorded in Index and Registry. |
| Registered → Specification Created | An owner is assigned and drafting begins. | Owner assigned; status moves to `Draft` (Section 32). | Owner recorded in Index. |
| Specification Created → Review | Drafting complete; mandatory template populated. | Owner submits for review; status moves to `Review`. | Review Standard (Section 20, Specification Program Section 24). |
| Review → Baseline | Review complete; approval flow complete. | Production Owner sign-off; status moves to `Approved` then `Baselined`. | Approval Standard (Specification Program Section 39). |
| Baseline → Implementation | Baselined Specification traced to Roadmap and Implementation Plan. | Status moves to `Implementation Ready` then `Implementation Active`. | Lifecycle gating (Section 13). |
| Implementation → Verification | Implementation complete; conformance evidence produced. | Status moves to `Verified`. | Verification against requirement identifiers. |
| Verification → Acceptance | Verification proves conformance. | Production Owner records acceptance; status moves to `Accepted`. | Acceptance record filed. |
| Acceptance → Maintenance | Accepted Specification enters operational maintenance. | Ongoing; Specification remains `Accepted`. | Maintenance per Review Schedule (Section 20). |
| Maintenance → Deprecation | Specification superseded or no longer recommended for new use. | Production Owner approves deprecation; status moves to `Deprecated`. | Superseding Specification ID recorded. |
| Deprecation → Archive | Specification permanently retired. | Production Owner approves archival; status moves to `Archived`. | Archived artifact immutable; historical links preserved (Section 13). |

### 26.3 Responsibilities

- **Need Identification:** Chief Technical Advisor (with Production Owner).
- **Registration:** Chief Technical Advisor (ID allocation).
- **Specification Creation:** Specification Owner.
- **Review:** Reviewer (delegated by Production Owner).
- **Baseline:** Production Owner (approval).
- **Implementation:** Engineering Execution Agent (Maintainer).
- **Verification:** Engineering Execution Agent (Maintainer).
- **Acceptance:** Production Owner.
- **Maintenance:** Specification Owner and Custodian (Chief Technical Advisor).
- **Deprecation:** Production Owner (approval); Custodian (record).
- **Archive:** Archive Owner (Chief Technical Advisor); Production Owner (approval).

### 26.4 Governance

Every lifecycle transition **shall** be recorded in the Registry (when instantiated) and reflected in this Index in the same change (Section 11.2). Transitions **shall** comply with the lifecycle gating rules (Specification Program Section 32) and the dependency rules (Section 7.2). A transition that violates a gate **shall** be reversed and treated as a defect.

---

## 27. AI Consumption Rules

This section defines guidance for Future AI Agents that consume the enterprise governance repository. Future AI Agents **shall** follow these rules to ensure consistent, traceable, and governance-compliant navigation. These rules are **binding on AI Agents** and **advisory for human readers** (human readers follow Section 23).

### 27.1 Mandatory Reading Order

A Future AI Agent **shall** always begin with:

```
Master Program
    │
    ▼
Architecture Specification Program
    │
    ▼
Architecture Specification Index
    │
    ▼
Specification
    │
    ▼
Roadmap
    │
    ▼
Implementation
    │
    ▼
Verification
    │
    ▼
Acceptance
    │
    ▼
Evidence
```

No Future AI Agent **shall** begin consumption at a Specification, Roadmap, or Evidence artifact without first reading the Master Program, Architecture Specification Program, and this Index. Beginning at a derivative artifact without the governing context is a forbidden shortcut (Section 27.5).

### 27.2 Navigation Order

Navigation **shall** proceed top-down per Section 9 and Section 23.5. A Future AI Agent **shall**:

1. Read the Master Program to understand **why** the portfolio exists.
2. Read the Architecture Specification Program to understand **how** Specifications are governed.
3. Read this Index to discover **which** Specifications exist and their dependencies.
4. Descend through the artifact chain for each Specification in dependency order (Section 7).

### 27.3 Reference Order

When a Future AI Agent references a Specification, it **shall** use the `SPEC-NNN vX.Y` form (Section 9.2). References **shall** be made in the following order of authority:

1. The Registry (authoritative source of truth).
2. This Index (readable projection).
3. The Specification artifact itself.

Where the Registry and Index diverge, the Registry prevails (Section 1.3). Where the Index and Specification diverge, the Chief Technical Advisor **shall** be notified for remediation.

### 27.4 Traceability Order

A Future AI Agent **shall** follow traceability links in the order defined in Section 10: Master Program → Specification Program → Index → Specification → Roadmap → Implementation Plan → Verification → Acceptance → ADR → Evidence. Traceability **shall not** be traversed in reverse except during an audit (Section 23.3), and even then the AI Agent **shall** record the full forward chain to confirm completeness.

### 27.5 Forbidden Shortcuts

A Future AI Agent **shall not**:

- Begin consumption at a derivative artifact (Roadmap, Implementation Plan, Verification, Evidence) without reading the governing artifacts first.
- Reference a Specification by file name or Short Identifier alone; the `SPEC-NNN vX.Y` form is mandatory (Section 9.2).
- Assume a Specification is baselined without checking its Document Status in the Index/Registry.
- Declare a dependency without validating acyclicity (Section 6.3) and baseline status (Section 7.2).
- Modify a baselined Specification without an approved Change Control request (Section 22).
- Reuse a retired `SPEC-NNN` identifier (Section 13).
- Omit "None recorded" markers where an artifact-chain link does not yet exist (Section 10.1).

### 27.6 Consistency Requirements

A Future AI Agent **shall** maintain consistency with the governance rules at all times:

- Every Specification it references **shall** exist in this Index.
- Every dependency it declares **shall** be reflected in Section 6 and the dependent Specification's metadata.
- Every cross-reference it creates **shall** be bidirectional (Section 9.4).
- Every artifact it produces **shall** be placed in the correct repository location (Section 9.1).
- Every status transition it records **shall** comply with the lifecycle gating (Specification Program Section 32).

A Future AI Agent that detects an inconsistency **shall** flag it to the Chief Technical Advisor and **shall not** attempt to remediate it unilaterally. Remediation authority follows the Authority Model (Production Owner → Chief Technical Advisor → Engineering Execution Agent).

---

**End of Architecture Specification Index v1.1**
