# Wave-01 Remediation Scope Definition

**Project:** VietSalePro  
**Program:** Deletion & Audit Architecture Remediation  
**Document Name:** Wave-01 Remediation Scope Definition  
**Version:** 1.0  
**Status:** Draft — Scope Frozen  
**Date:** 2026-07-23  
**Authority Model:** Production Owner → Chief Technical Advisor → Engineering Execution Agent  

---

## 1. Purpose

This document freezes the Wave-01 Remediation implementation scope. It identifies the authorized Specifications, the sections that may be edited, the mandatory and optional modifications, and the findings that must be preserved exactly.

No scope changes are permitted after this document is baselined.

---

## 2. Governance Boundary

- **Governance lock:** Active.
- **Highest authority:** `SPEC_BASELINE_CERTIFICATION.md` v1.0.
- **Governance documents that shall not be modified:**
  - `ADMIN_DASHBOARD_PLAN_FIX_SPB/Deletion_Audit_Architecture_Remediation_Program.md`
  - `ADMIN_DASHBOARD_PLAN_FIX_SPB/01_Governance/Architecture_Specification_Program.md`
  - `ADMIN_DASHBOARD_PLAN_FIX_SPB/01_Governance/ARCHITECTURE_SPECIFICATION_INDEX.md`
  - `ADMIN_DASHBOARD_PLAN_FIX_SPB/01_Governance/SPEC_BASELINE_CERTIFICATION.md`

---

## 3. Authorized Specifications

Only the following Architecture Specifications are authorized for Wave-01 Remediation:

| # | Specification ID | File Path | Wave-01 Disposition |
|---|------------------|-----------|---------------------|
| 1 | SPEC-002 | `02_Specifications/SPEC-002_AUDIT_ARCHITECTURE_SPECIFICATION.md` | Category D — preserve exactly |
| 2 | SPEC-003 | `02_Specifications/SPEC-003_TRANSACTION_ARCHITECTURE_SPECIFICATION.md` | Category A — mandatory correction |
| 3 | SPEC-004 | `02_Specifications/SPEC-004_TRIGGER_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` | Category B/C — optional improvements |
| 4 | SPEC-005 | `02_Specifications/SPEC-005_FOREIGN_KEY_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` | Category A — mandatory correction |
| 5 | SPEC-006 | `02_Specifications/SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md` | Category A — mandatory correction |
| 6 | SPEC-007 | `02_Specifications/SPEC-007_REGRESSION_VERIFICATION_ARCHITECTURE_SPECIFICATION.md` | Category D — preserve exactly |

**SPEC-001** (`02_Specifications/SPEC-001_DELETE_FRAMEWORK_ARCHITECTURE_SPECIFICATION.md`) is the Golden Example and is **not** authorized for modification.

---

## 4. Category A — Mandatory Remediation

These four findings must be corrected. No Wave-01 Remediation is complete until all Category A items are resolved.

### A-01: SPEC-006 Classification Correction

| Field | Value |
|-------|-------|
| **Specification** | SPEC-006 — Observability Architecture Specification |
| **File** | `02_Specifications/SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md` |
| **Locations** | Header line 8; Metadata table line 34; `16.1 Metadata` narrative |
| **Current State** | `Classification: Core` |
| **Required State** | `Classification: Operational` |
| **Authority** | `SPEC_BASELINE_CERTIFICATION.md` Section 20.5; `ARCHITECTURE_SPECIFICATION_INDEX.md` Sections 5.2/6.1/7.1 |
| **Scope Rule** | Header, metadata table, and any narrative in `16.1 Metadata` that calls SPEC-006 Core must be updated. No other section may be changed. |

### A-02: SPEC-005 Evidence Section Restructure

| Field | Value |
|-------|-------|
| **Specification** | SPEC-005 — Foreign Key Governance Architecture Specification |
| **File** | `02_Specifications/SPEC-005_FOREIGN_KEY_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` |
| **Locations** | `Evidence` section, lines 744-806 (`E.1`–`E.6`) |
| **Current State** | Six evidence subsections (`E.1`–`E.6`) |
| **Required State** | Ten evidence subsections (`E.1`–`E.10`) |
| **Authority** | `SPEC_BASELINE_CERTIFICATION.md` Section 15.6; Prohibited Variations table Section 17 |
| **Scope Rule** | Restructure the Evidence section while preserving all existing factual content. The required subsections are: Foundation Documents Consulted, Governance Documents Consulted, Cross-Validation Results, Extracted Governance Summary, Portfolio Validation, Dependency Validation, Template Compliance, Traceability Summary, Risk Assessment, Confirmation. |

### A-03: SPEC-003 Evidence Section Restructure

| Field | Value |
|-------|-------|
| **Specification** | SPEC-003 — Transaction Architecture Specification |
| **File** | `02_Specifications/SPEC-003_TRANSACTION_ARCHITECTURE_SPECIFICATION.md` |
| **Locations** | `Evidence` section, lines 789-887 (`E.1`–`E.12`) |
| **Current State** | Twelve evidence subsections with domain-specific labels |
| **Required State** | Ten evidence subsections (`E.1`–`E.10`) with certified labels |
| **Authority** | `SPEC_BASELINE_CERTIFICATION.md` Section 15.6; Prohibited Variations table Section 17 |
| **Scope Rule** | Re-map the existing verification content into the certified `E.1`–`E.10` structure. Domain-specific checks may be retained as sub-bullets under the appropriate base section. No content may be removed unless it duplicates a base section. |

### A-04: SPEC-006 Evidence Section Restructure

| Field | Value |
|-------|-------|
| **Specification** | SPEC-006 — Observability Architecture Specification |
| **File** | `02_Specifications/SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md` |
| **Locations** | `Evidence` section, lines 743-818 (`E.1`–`E.13`) |
| **Current State** | Thirteen evidence subsections with domain-specific labels |
| **Required State** | Ten evidence subsections (`E.1`–`E.10`) with certified labels |
| **Authority** | `SPEC_BASELINE_CERTIFICATION.md` Section 15.6; Prohibited Variations table Section 17 |
| **Scope Rule** | Re-map the existing verification content into the certified `E.1`–`E.10` structure. Per-dependency observations belong under `E.6 Dependency Validation`. Retain all factual content as sub-bullets where appropriate. |

---

## 5. Category B — Optional Repository Consistency Improvements

These findings are optional and may be addressed only after all Category A items are complete. Addressing Category B items is not required for Wave-01 acceptance.

| ID | Specification | File | Location | Finding | Recommended Action |
|----|---------------|------|----------|---------|--------------------|
| B-01 | SPEC-006 | `02_Specifications/SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md` | Header line 17; Metadata table line 43 | Related Specifications use `(informative dependency)`, which is not defined in `Architecture_Specification_Program.md` Section 34.1 | Replace `(informative dependency)` with `(optional)` to match the Program's controlled vocabulary and the Index |

---

## 6. Category C — Optional Golden Alignment Improvements

These findings are optional style and alignment opportunities. They may be addressed only after all Category A items are complete and only if they do not conflict with a Category A correction.

| ID | Specification | File | Location | Finding | Recommended Action |
|----|---------------|------|----------|---------|--------------------|
| C-01 | SPEC-004 | `02_Specifications/SPEC-004_TRIGGER_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` | Evidence `E.3`, lines 715-726 | Cross-Validation Results table is less detailed than SPEC-001's `E.3` | Expand the `E.3` table to include Index registration, Specification ID/Name/Classification consistency, dependencies, authoring order, workstream match, scope match, and governance-version checks |
| C-02 | SPEC-004 | `02_Specifications/SPEC-004_TRIGGER_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` | Evidence `E.2`, line 712 | Index reference description omits "registration" and "classification" | Align the description with SPEC-001 `E.2` to explicitly mention registration, classification, dependencies, and authoring order |

---

## 7. Category D — Preserve Exactly

The following findings are Allowed Evolution under the current governance. They shall not be removed, restructured, reworded, or reclassified.

| ID | Specification | Location | Description |
|----|---------------|----------|-------------|
| D-01 | SPEC-002 | Appendix D | Extended Traceability Summary with 18 section mappings to Master Program Section 10.2 |
| D-02 | SPEC-002 | Appendix A-B | Audit Event Classification Matrix and Audit Independence Reference Model |
| D-03 | SPEC-003 | Section 16.11 | Domain-specific contracts (ACID, Outbox, Compensation, Saga, Timeout, Retry) |
| D-04 | SPEC-003 | Sections 16.8–16.10 | Transaction-specific Domain Model, Components, and Interfaces |
| D-05 | SPEC-004 | Sections 16.11, Appendix A-C | 19 trigger-specific contracts and Trigger Classification/Mapping templates |
| D-06 | SPEC-005 | Appendix A-F | Relationship Classification, Delete/Update Policy Matrices, Cross-Boundary Checklist |
| D-07 | SPEC-006 | Line 658 | `Architecture Decisions (Supplementary)` section placed before Appendix |
| D-08 | SPEC-006 | Appendix C | Domain-specific glossary (Correlation ID, Trace, Span, Signal, Alert Rule, Retention Policy) |
| D-09 | SPEC-007 | Appendix B-C | Verification Taxonomy and Regression Coverage Model appendices |
| D-10 | SPEC-007 | Appendix D | Extended glossary for verification domain |

---

## 8. Section-Level Edit Permissions

| Specification | Allowed Sections | Forbidden Sections |
|---------------|------------------|--------------------|
| SPEC-002 | None | All — preserve exactly |
| SPEC-003 | `Evidence` section only | Domain model, contracts, state machine, workflow, failure/recovery, requirement identifiers, mandatory sections `16.1`–`16.26` order, Appendix D |
| SPEC-004 | `Evidence E.2`, `Evidence E.3` only (optional) | All other sections |
| SPEC-005 | `Evidence` section only | Domain model, contracts, matrices, requirement identifiers, mandatory sections `16.1`–`16.26` order |
| SPEC-006 | Header `Classification` fields; `16.1 Metadata` narrative; `Evidence` section; optional header `Related Specifications` dependency labels | Domain model, components, interfaces, contracts, state machine, workflow, failure/recovery, requirement identifiers, mandatory sections `16.1`–`16.26` order, Appendix C |
| SPEC-007 | None | All — preserve exactly |

---

## 9. Scope Lock Statement

The Wave-01 Remediation scope is frozen as of this document. Any change to the authorized Specifications, findings, categories, or edit permissions requires a new program authorization.

Only the following modifications are permitted:

- Four Category A corrections.
- One optional Category B improvement.
- Two optional Category C improvements.
- Preservation of ten Category D Allowed Evolution findings.

No architecture, requirement, identifier, traceability, dependency graph, contract, or business-meaning change is permitted.

---

**No implementation performed. No Specification modified. No Governance modified. No commit. No push. No deployment.**
