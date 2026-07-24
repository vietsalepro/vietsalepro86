# Wave-01 Remediation Execution Plan

**Project:** VietSalePro  
**Program:** Deletion & Audit Architecture Remediation  
**Document Name:** Wave-01 Remediation Execution Plan  
**Version:** 1.0  
**Status:** Draft — Execution Plan  
**Date:** 2026-07-23  
**Authority Model:** Production Owner → Chief Technical Advisor → Engineering Execution Agent  

---

## 1. Objective

Execute the Wave-01 Remediation by correcting the four Category A governance violations and optionally addressing the Category B and Category C findings defined in `WAVE01_REMEDIATION_SCOPE_DEFINITION.md`, while preserving all Category D Allowed Evolution findings.

This plan contains no implementation, no commit, no push, and no deployment. It governs documentation-only edits to the authorized Specification files.

---

## 2. Sequencing Principles

1. **Governance before style.** All Category A corrections are completed before any optional work.
2. **Structural before detail.** Evidence section restructure is completed before evidence content enrichment.
3. **Metadata first.** SPEC-006 classification (A-01) is corrected before its Evidence section (A-04).
4. **No scope expansion.** Only the files and sections defined in `WAVE01_REMEDIATION_SCOPE_DEFINITION.md` may be touched.
5. **Traceability preserved.** Requirement identifiers, cross-references, and dependency declarations must remain intact.
6. **No architecture changes.** Domain models, contracts, state machines, workflows, failure/recovery models, and acceptance criteria must not be altered.

---

## 3. Phase 1 — Category A Corrections

### Task A-01: Correct SPEC-006 Classification

| Field | Value |
|-------|-------|
| **Finding ID** | A-01 |
| **Target** | `02_Specifications/SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md` |
| **Change** | `Classification: Core` → `Classification: Operational` |
| **Locations to Edit** | Header `Classification:` field; metadata table `Classification` row; `16.1 Metadata` narrative if it calls SPEC-006 Core |
| **Steps** | 1. Update header field. 2. Update metadata table. 3. Update `16.1 Metadata` narrative sentence. |
| **Verification** | `grep -i "Classification"` in the file returns only "Operational". |
| **Owner** | Engineering Execution Agent |
| **Dependencies** | None |

### Task A-02: Restructure SPEC-005 Evidence Section

| Field | Value |
|-------|-------|
| **Finding ID** | A-02 |
| **Target** | `02_Specifications/SPEC-005_FOREIGN_KEY_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` |
| **Change** | Evidence section `E.1`–`E.6` → certified `E.1`–`E.10` |
| **Locations to Edit** | `Evidence` section, lines 744-806 |
| **Steps** | 1. Replace existing Evidence subsections with the certified 10-part structure. 2. Retain existing factual content. 3. Add `E.4 Extracted Governance Summary`, `E.5 Portfolio Validation`, `E.6 Dependency Validation`, `E.7 Template Compliance`, `E.8 Traceability Summary`, `E.9 Risk Assessment`, `E.10 Confirmation`. 4. Map existing cross-validation rows to `E.3`. 5. Map related-specification checks to `E.6`. |
| **Verification** | `grep "^### E\."` returns exactly `E.1` through `E.10` with the required titles. |
| **Owner** | Engineering Execution Agent |
| **Dependencies** | None |

### Task A-03: Restructure SPEC-003 Evidence Section

| Field | Value |
|-------|-------|
| **Finding ID** | A-03 |
| **Target** | `02_Specifications/SPEC-003_TRANSACTION_ARCHITECTURE_SPECIFICATION.md` |
| **Change** | Evidence section `E.1`–`E.12` → certified `E.1`–`E.10` |
| **Locations to Edit** | `Evidence` section, lines 789-887 |
| **Steps** | 1. Re-label and re-group current evidence content into `E.1`–`E.10`. 2. Combine "Governance Hierarchy Understanding" and "Inheritance Rules Applied" into `E.4 Extracted Governance Summary`. 3. Confirm SPEC-003 registration in Index under `E.5 Portfolio Validation`. 4. Move dependency verification under `E.6 Dependency Validation`. 5. Move current "Risk Assessment" content to `E.9`. 6. Retain confirmation in `E.10`. 7. Keep domain-specific checks as sub-bullets. |
| **Verification** | `grep "^### E\."` returns exactly `E.1` through `E.10` with the required titles. |
| **Owner** | Engineering Execution Agent |
| **Dependencies** | None |

### Task A-04: Restructure SPEC-006 Evidence Section

| Field | Value |
|-------|-------|
| **Finding ID** | A-04 |
| **Target** | `02_Specifications/SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md` |
| **Change** | Evidence section `E.1`–`E.13` → certified `E.1`–`E.10` |
| **Locations to Edit** | `Evidence` section, lines 743-818 |
| **Steps** | 1. Re-label and re-group current evidence content into `E.1`–`E.10`. 2. Combine current `E.3` (Baseline Certification Compliance) and `E.4` (Golden Specification Comparison) into `E.4 Extracted Governance Summary`. 3. Confirm SPEC-006 registration and `Operational` classification in `E.5 Portfolio Validation`. 4. Fold per-dependency verification subsections into `E.6 Dependency Validation` as a table. 5. Confirm 26 mandatory sections and supplementary section placement in `E.7 Template Compliance`. 6. Summarize Appendix D traceability in `E.8 Traceability Summary`. 7. Move risk observations to `E.9 Risk Assessment`. 8. State no implementation/commit/push/deploy in `E.10 Confirmation`. |
| **Verification** | `grep "^### E\."` returns exactly `E.1` through `E.10` with the required titles. |
| **Owner** | Engineering Execution Agent |
| **Dependencies** | A-01 must be completed first |

---

## 4. Phase 2 — Optional Category B/C Improvements

Phase 2 begins only after all Phase 1 Category A corrections are verified. Phase 2 is optional and does not affect Wave-01 acceptance.

### Task B-01: Standardize SPEC-006 Dependency Labels

| Field | Value |
|-------|-------|
| **Finding ID** | B-01 (Repository Consistency) |
| **Target** | `02_Specifications/SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md` |
| **Change** | Replace `(informative dependency)` with `(optional)` |
| **Locations to Edit** | Header `Related Specifications` line 17; metadata table line 43 |
| **Steps** | 1. Replace `(informative dependency)` with `(optional)` in both locations. 2. Ensure wording matches `Architecture_Specification_Program.md` Section 34.1. |
| **Verification** | `grep -i "informative dependency"` returns no results; `grep -i "(optional)"` matches the intended references. |
| **Owner** | Engineering Execution Agent |
| **Dependencies** | A-01, A-04 |

### Task C-01: Enrich SPEC-004 Evidence E.3

| Field | Value |
|-------|-------|
| **Finding ID** | C-01 (Golden Alignment) |
| **Target** | `02_Specifications/SPEC-004_TRIGGER_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` |
| **Change** | Expand `E.3 Cross-Validation Results` table |
| **Locations to Edit** | Evidence `E.3`, lines 715-726 |
| **Steps** | 1. Add rows for Index registration, Specification ID match, Specification Name match, Classification match, Dependencies match, Authoring order match, Workstream match, Scope match, Required template match, Governance version consistency. 2. Use the same check/result format as SPEC-001 `E.3`. |
| **Verification** | `E.3` table contains at least the additional rows listed above. |
| **Owner** | Engineering Execution Agent |
| **Dependencies** | None |

### Task C-02: Refine SPEC-004 Evidence E.2 Description

| Field | Value |
|-------|-------|
| **Finding ID** | C-02 (Golden Alignment) |
| **Target** | `02_Specifications/SPEC-004_TRIGGER_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` |
| **Change** | Align `E.2` Index reference description with SPEC-001 |
| **Locations to Edit** | Evidence `E.2`, line 712 |
| **Steps** | 1. Update the `ARCHITECTURE_SPECIFICATION_INDEX.md` reference description to explicitly mention "registration, classification, dependencies, and authoring order". |
| **Verification** | `E.2` description contains the four required terms. |
| **Owner** | Engineering Execution Agent |
| **Dependencies** | None |

---

## 5. Phase 3 — Wave-01 Verification Gate

Before closing Wave-01, the Engineering Execution Agent shall verify the following:

| # | Gate | Verification Method |
|---|------|---------------------|
| 1 | Category A zero | All four Category A findings are corrected |
| 2 | SPEC-006 classification | `grep -i "Classification"` in SPEC-006 returns only "Operational" |
| 3 | Evidence structure for SPEC-003, SPEC-005, SPEC-006 | `grep "^### E\."` returns exactly `E.1` through `E.10` with required titles |
| 4 | Classification consistency | SPEC-006 header and Index both read `Operational` |
| 5 | No architecture drift | No requirement identifiers, domain models, contracts, or state machines were changed |
| 6 | No forbidden operations | No implementation, commit, push, or deployment has occurred |
| 7 | Traceability preserved | All cross-references still use `SPEC-NNN vX.Y` format |
| 8 | Category D preserved | All ten Allowed Evolution findings remain unchanged |
| 9 | Optional items | Category B/C items completed only after Category A; no conflict introduced |

---

## 6. Execution Constraints and Guardrails

- No changes to `SPEC-001`, governance documents, repository structure, or source code.
- No commits, pushes, or deployments.
- All changes are limited to the `02_Specifications/SPEC-00*.md` files listed in the scope definition.
- If a Phase 2 optional improvement conflicts with a Phase 1 correction, the Phase 1 correction takes precedence.
- Any new finding discovered during execution is recorded and deferred to a subsequent wave; it is not remediated inside Wave-01 unless it is a direct consequence of a Category A correction.

---

## 7. Execution Order Summary

```
A-01 → A-02
A-01 → A-03
A-01 → A-04
A-04 → B-01 (optional)
A-03 → Verification Gate
A-04 → Verification Gate
A-02 → Verification Gate
C-01, C-02 (optional, parallel) → Verification Gate
```

---

**No implementation performed. No Specification modified. No Governance modified. No commit. No push. No deployment.**
