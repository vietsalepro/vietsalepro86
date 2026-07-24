# Wave-01 — Alignment Execution Plan

**Project:** VietSalePro  
**Program:** Deletion & Audit Architecture Remediation  
**Scope:** SPEC-002 through SPEC-007  
**Authority:** Architecture Specification Program v1.1, SPEC_BASELINE_CERTIFICATION.md v1.0  
**Date:** 2026-07-23  

This plan translates the `WAVE01_ALIGNMENT_ACTION_REGISTER.md` into a safe, sequenced remediation workflow. It contains **no implementation, no commit, no push, and no deployment**.

---

## 1. Objective

Correct the Wave-01 Category A governance violations and optionally address Category B golden-alignment opportunities in SPEC-002 through SPEC-007, while preserving all allowed architectural evolution (Category C).

---

## 2. Sequencing Principles

1. **Governance before style.** Correct all Category A items before any Category B items.
2. **Structural before detail.** First restructure the Evidence sections (A-02, A-03, A-04); then refine their content (B-01, B-02).
3. **Metadata first.** Fix SPEC-006 classification (A-01) before Evidence restructure so that the corrected metadata is reflected in the restructured document.
4. **No architecture changes.** No requirement identifiers, contracts, domain models, or architectural decisions may be altered.
5. **Traceability preserved.** Every change must keep the existing requirement identifiers and cross-references intact.

---

## 3. Phase 1 — Category A Corrections

### 3.1 Task A-01: Correct SPEC-006 Classification

- **Target:** `02_Specifications/SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md`
- **Finding:** A-01 (Classification: Core → must be Operational)
- **Steps:**
  1. Update the header field `**Classification:** Core` to `**Classification:** Operational`.
  2. Update the metadata table field `| Classification | Core |` to `| Classification | Operational |`.
  3. Update the narrative sentence in `16.1 Metadata` that calls SPEC-006 a Core specification.
- **Verification:** `grep -i "Classification"` in the file returns only "Operational".
- **Owner:** Author / Engineering Execution Agent
- **Dependencies:** None

### 3.2 Task A-02: Restructure SPEC-005 Evidence Section

- **Target:** `02_Specifications/SPEC-005_FOREIGN_KEY_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md`
- **Finding:** A-02 (Evidence is E.1–E.6, must be E.1–E.10)
- **Steps:**
  1. Replace the `Evidence` section with the certified 10-part structure.
  2. `E.1 Foundation Documents Consulted` — retain existing content.
  3. `E.2 Governance Documents Consulted` — retain existing content.
  4. `E.3 Cross-Validation Results` — retain existing cross-validation rows; add Index/registry checks if desired.
  5. `E.4 Extracted Governance Summary` — create from the existing governance observations.
  6. `E.5 Portfolio Validation` — add verification against `ARCHITECTURE_SPECIFICATION_INDEX.md`.
  7. `E.6 Dependency Validation` — move related-specification checks here.
  8. `E.7 Template Compliance` — confirm all 26 mandatory sections are present and in order.
  9. `E.8 Traceability Summary` — summarize the Appendix D traceability matrix.
  10. `E.9 Risk Assessment` — list residual risks (e.g., dependencies on Draft Specifications).
  11. `E.10 Confirmation` — state no implementation, commit, push, or deployment performed.
- **Verification:** `grep "^### E\."` returns exactly `E.1` through `E.10` with the required titles.
- **Owner:** Author / Engineering Execution Agent
- **Dependencies:** None

### 3.3 Task A-03: Restructure SPEC-003 Evidence Section

- **Target:** `02_Specifications/SPEC-003_TRANSACTION_ARCHITECTURE_SPECIFICATION.md`
- **Finding:** A-03 (Evidence is E.1–E.12 with non-certified labels)
- **Steps:**
  1. Re-label and re-group the current `E.1`–`E.12` content into the certified `E.1`–`E.10` structure.
  2. `E.3 Cross-Validation Results` — use the current cross-validation checks.
  3. `E.4 Extracted Governance Summary` — combine "Governance Hierarchy Understanding" and "Inheritance Rules Applied" into this section.
  4. `E.5 Portfolio Validation` — confirm SPEC-003 registration in the Index.
  5. `E.6 Dependency Validation` — move dependency verification here.
  6. `E.7 Template Compliance` — confirm all mandatory sections and requirement identifiers.
  7. `E.8 Traceability Summary` — summarize Appendix C.
  8. `E.9 Risk Assessment` — move current "Risk Assessment" (E.11) content here.
  9. `E.10 Confirmation` — retain current confirmation and explicitly state no commit/deploy.
  10. Domain-specific verification material (technology-neutral, implementation-independence, cross-reference) can be kept as sub-bullets under the matching base section.
- **Verification:** `grep "^### E\."` returns exactly `E.1` through `E.10` with the required titles.
- **Owner:** Author / Engineering Execution Agent
- **Dependencies:** None

### 3.4 Task A-04: Restructure SPEC-006 Evidence Section

- **Target:** `02_Specifications/SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md`
- **Finding:** A-04 (Evidence is E.1–E.13 with non-certified labels)
- **Steps:**
  1. Re-label and re-group the current `E.1`–`E.13` content into the certified `E.1`–`E.10` structure.
  2. `E.3 Cross-Validation Results` — use current baseline/golden-spec comparison checks.
  3. `E.4 Extracted Governance Summary` — combine current `E.3` (Baseline Certification Compliance) and `E.4` (Golden Specification Comparison) content.
  4. `E.5 Portfolio Validation` — confirm SPEC-006 registration and Operational classification in the Index.
  5. `E.6 Dependency Validation` — fold the per-dependency verification subsections (E.5–E.8) into one table.
  6. `E.7 Template Compliance` — confirm 26 mandatory sections and the supplementary section are correctly placed.
  7. `E.8 Traceability Summary` — summarize Appendix D.
  8. `E.9 Risk Assessment` — retain current risk observations.
  9. `E.10 Confirmation` — state no implementation, commit, push, or deployment performed.
- **Verification:** `grep "^### E\."` returns exactly `E.1` through `E.10` with the required titles.
- **Owner:** Author / Engineering Execution Agent
- **Dependencies:** A-01 must be completed first

---

## 4. Phase 2 — Category B Optional Improvements

### 4.1 Task B-01: Enrich SPEC-004 Evidence E.3

- **Target:** `02_Specifications/SPEC-004_TRIGGER_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md`
- **Finding:** B-01 (Cross-Validation table is generic)
- **Steps:**
  1. Add rows to `E.3` for: Index registration, Specification ID match, Specification Name match, Classification match, Dependencies match, Authoring order match, Workstream match, Scope match, Required template match, Governance version consistency.
  2. Use the same check/result table format as SPEC-001 `E.3`.
- **Owner:** Author / Engineering Execution Agent
- **Dependencies:** None

### 4.2 Task B-02: Refine SPEC-004 Evidence E.2 Description

- **Target:** `02_Specifications/SPEC-004_TRIGGER_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md`
- **Finding:** B-02 (Index description omits registration/classification)
- **Steps:**
  1. Update the `ARCHITECTURE_SPECIFICATION_INDEX.md` reference description to include "registration, classification, dependencies, and authoring order".
- **Owner:** Author / Engineering Execution Agent
- **Dependencies:** None

### 4.3 Task B-03: Standardize SPEC-006 Dependency Labels

- **Target:** `02_Specifications/SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md`
- **Finding:** B-03 ("informative dependency" is not a Program-defined type)
- **Steps:**
  1. In the header `Related Specifications` and `16.1 Metadata` table, replace "(informative dependency)" with "(optional)".
- **Owner:** Author / Engineering Execution Agent
- **Dependencies:** A-01

---

## 5. Phase 3 — Wave-01 Verification Gate

Before closing Wave-01, the Author shall verify:

1. **Category A zero:** All four Category A items are corrected.
2. **Evidence structure:** For every Specification, `grep "^### E\."` returns exactly `E.1` through `E.10` with the certified titles.
3. **Classification consistency:** SPEC-006 header and Index both read `Operational`.
4. **No architecture drift:** No requirement identifiers, domain models, contracts, or state machines were changed.
5. **No forbidden operations:** No implementation, commit, push, or deployment has occurred.
6. **Traceability preserved:** All cross-references still use `SPEC-NNN vX.Y` format with target identifiers and versions.

---

## 6. Acceptance Criteria

- [ ] SPEC-006 Classification is `Operational` in both header and metadata table.
- [ ] SPEC-003, SPEC-005, and SPEC-006 Evidence sections use the certified `E.1`–`E.10` structure.
- [ ] SPEC-004 Evidence E.3 optionally includes Index cross-validation checks.
- [ ] SPEC-004 Evidence E.2 and SPEC-006 dependency labels optionally use Program-controlled vocabulary.
- [ ] All allowed evolution (Category C) remains intact and unchanged.
- [ ] `WAVE01_GOVERNANCE_ALIGNMENT_REVIEW.md` and `WAVE01_ALIGNMENT_ACTION_REGISTER.md` are updated to reflect closure of items.
- [ ] No code, schema, migration, Edge Function, or deployment artifact was modified.

---

## 7. Constraints and Guardrails

- No changes to `SPEC-001`, governance documents, repository structure, or source code.
- No commits, pushes, or deployments.
- All changes are limited to the `02_Specifications/SPEC-00*.md` files listed in the action register.
- If a Phase 2 optional improvement conflicts with a Phase 1 correction, the Phase 1 correction takes precedence.
