# Wave-01 Remediation Acceptance Criteria

**Project:** VietSalePro  
**Program:** Deletion & Audit Architecture Remediation  
**Document Name:** Wave-01 Remediation Acceptance Criteria  
**Version:** 1.0  
**Status:** Draft — Acceptance Criteria  
**Date:** 2026-07-23  
**Authority Model:** Production Owner → Chief Technical Advisor → Engineering Execution Agent  

---

## 1. Purpose

This document defines the acceptance criteria for the Wave-01 Remediation Program. Remediation is accepted only when every criterion below is satisfied and the required evidence is recorded.

---

## 2. Program-Level Acceptance Criteria

| # | Criterion | Required State | Evidence |
|---|-----------|----------------|----------|
| 1 | Mandatory role documents read | `VAI_TRO_TRACH_NHIEM_VIETSALEPRO.md` and `NGUYEN_TAC_VIET_PROMPT_AGENT_VIETSALEPRO.md` read and applied | Reference in the final completion report |
| 2 | Mandatory engineering memory read | `.codebase-memory/CODEBASE_MEMORY_BASELINE.md`, `SEMANTIC_MEMORY.md`, and `VALIDATION_REPORT.md` read and not contradicted | Reference in the final completion report |
| 3 | Governance documents read | `Deletion_Audit_Architecture_Remediation_Program.md`, `Architecture_Specification_Program.md`, `ARCHITECTURE_SPECIFICATION_INDEX.md`, and `SPEC_BASELINE_CERTIFICATION.md` read | Reference in the final completion report |
| 4 | Governance lock confirmed | Governance remains unchanged; no governance document modified | File diff or status showing no changes to governance files |
| 5 | Implementation scope frozen | `WAVE01_REMEDIATION_SCOPE_DEFINITION.md` is the single scope authority | Scope document present and approved |
| 6 | Authorized modifications identified | Four Category A actions documented and traceable to `SPEC_BASELINE_CERTIFICATION.md` | Action register and verification report |
| 7 | Forbidden modifications identified | All out-of-scope items listed in `WAVE01_REMEDIATION_SCOPE_DEFINITION.md` | Scope document Section 8 |
| 8 | Category A remediation confirmed | All four Category A findings corrected | Verification report and file diffs |
| 9 | Category D preservation confirmed | All ten Allowed Evolution findings unchanged | Verification report and file diffs |
| 10 | Verification gates defined | `WAVE01_REMEDIATION_EXECUTION_PLAN.md` Phase 3 gates are followed | Verification report |
| 11 | Acceptance criteria defined | This document is produced and reviewed | This document |
| 12 | No implementation performed during authorization | Only the four deliverable documents were created | File list and git status |
| 13 | No Specification modified during authorization | No `02_Specifications/SPEC-00*.md` file edited under authorization | Git status |
| 14 | No Governance modified during authorization | No governance file edited under authorization | Git status |
| 15 | No commit | No commit made | Git status |
| 16 | No push | No push made | Git status |
| 17 | No deployment | No deployment made | Explicit statement in completion report |

---

## 3. Category A Task Acceptance Criteria

### A-01: SPEC-006 Classification is `Operational`

| # | Check | Pass Condition |
|---|-------|----------------|
| 1 | Header field | `Classification: Operational` appears in the header |
| 2 | Metadata table | `| Classification | Operational |` appears in the metadata table |
| 3 | 16.1 Metadata narrative | No sentence in `16.1 Metadata` calls SPEC-006 `Core` |
| 4 | No stale occurrences | `grep -i "Classification"` in the file returns only `Operational` |

### A-02: SPEC-005 Evidence is `E.1`–`E.10`

| # | Check | Pass Condition |
|---|-------|----------------|
| 1 | Subsection count | Exactly ten `### E.N` subsections exist in the Evidence section |
| 2 | Required titles | `E.1` through `E.10` use the certified titles: Foundation Documents Consulted, Governance Documents Consulted, Cross-Validation Results, Extracted Governance Summary, Portfolio Validation, Dependency Validation, Template Compliance, Traceability Summary, Risk Assessment, Confirmation |
| 3 | Content preserved | Existing factual evidence content is retained or mapped into the new structure |
| 4 | No implementation statement | `E.10` explicitly states no implementation, commit, push, or deployment performed |

### A-03: SPEC-003 Evidence is `E.1`–`E.10`

| # | Check | Pass Condition |
|---|-------|----------------|
| 1 | Subsection count | Exactly ten `### E.N` subsections exist in the Evidence section |
| 2 | Certified labels | `E.1`–`E.10` use the certified labels required by `SPEC_BASELINE_CERTIFICATION.md` Section 15.6 |
| 3 | Domain checks retained | Existing domain-specific verification content is retained as sub-bullets under the appropriate base section |
| 4 | Risk and confirmation | `E.9 Risk Assessment` and `E.10 Confirmation` are present |

### A-04: SPEC-006 Evidence is `E.1`–`E.10`

| # | Check | Pass Condition |
|---|-------|----------------|
| 1 | Subsection count | Exactly ten `### E.N` subsections exist in the Evidence section |
| 2 | Certified labels | `E.1`–`E.10` use the certified labels required by `SPEC_BASELINE_CERTIFICATION.md` Section 15.6 |
| 3 | Per-dependency folded | Per-dependency verification observations are consolidated under `E.6 Dependency Validation` |
| 4 | Classification consistency | `E.5 Portfolio Validation` confirms SPEC-006 is registered and classified as `Operational` |
| 5 | Risk and confirmation | `E.9 Risk Assessment` and `E.10 Confirmation` are present |

---

## 4. Optional Category B/C Acceptance Criteria

These criteria apply only if the optional improvements are attempted.

| ID | Task | Acceptance Condition |
|----|------|----------------------|
| B-01 | SPEC-006 dependency labels | `(informative dependency)` is replaced with `(optional)` in both header and metadata table; no other dependency type vocabulary is introduced |
| C-01 | SPEC-004 Evidence E.3 | `E.3` table contains rows for Index registration, Specification ID match, Name match, Classification match, Dependencies match, Authoring order match, Workstream match, Scope match, Required template match, Governance version consistency |
| C-02 | SPEC-004 Evidence E.2 | `E.2` description explicitly mentions "registration, classification, dependencies, and authoring order" |

---

## 5. Category D Preservation Acceptance Criteria

| # | Check | Pass Condition |
|---|-------|----------------|
| 1 | D-01 through D-10 unchanged | No edit is made to the sections/locations identified in `WAVE01_REMEDIATION_SCOPE_DEFINITION.md` Section 7 |
| 2 | No reclassification | No Category D finding is reworded, removed, or reclassified as a defect |
| 3 | Allowed Evolution intact | All ten findings remain in their original form and location |

---

## 6. Cross-Cutting Acceptance Criteria

| # | Criterion | Pass Condition |
|---|-----------|----------------|
| 1 | No architecture change | No requirement identifier, domain model, contract, state machine, workflow, failure/recovery model, or acceptance criterion was altered |
| 2 | No traceability drift | All cross-references still use the `SPEC-NNN vX.Y` format with correct identifiers and versions |
| 3 | No dependency graph change | No `Related Specifications` dependency was added, removed, or retyped except the SPEC-006 B-01 optional label correction |
| 4 | No business meaning change | No normative requirement statement was reworded in a way that changes its meaning |
| 5 | No implementation artifacts | No source code, schema, migration, RPC, Edge Function, test, or deployment file was modified |
| 6 | No governance modification | No governance document was edited or version-bumped |
| 7 | No commit | Git working tree contains only the remediation file changes; no commit exists |
| 8 | No push | No push was performed |
| 9 | No deployment | No deployment was performed |

---

## 7. Verification Evidence Required

The following evidence must be collected and referenced in the Wave-01 Remediation Completion Report:

| # | Evidence | Description |
|---|----------|-------------|
| 1 | Before / After | For each modified Specification, a summary of the changed sections |
| 2 | Files Changed | List of all `02_Specifications/SPEC-00*.md` files touched by the remediation |
| 3 | Diff | `git diff` or equivalent showing the exact changes to the authorized files |
| 4 | Verification Commands | Output of `grep` checks for classification and Evidence structure |
| 5 | Category D Check | Statement confirming no Category D finding was changed |
| 6 | Governance Lock Confirmation | Statement confirming no governance document was modified |
| 7 | No-Implementation Statement | Statement confirming no code, schema, migration, RPC, Edge Function, or deployment change was made |
| 8 | No-Commit/Push Statement | Statement confirming no commit or push was performed |

---

## 8. Final Acceptance Statement

Wave-01 Remediation is **accepted** when:

- All four Category A findings are corrected and verified.
- Optional Category B/C items are either completed correctly or explicitly deferred.
- All Category D findings are preserved.
- No architecture, governance, implementation, commit, push, or deployment artifact was introduced.
- The evidence package listed in Section 7 is complete.

Only then may the Wave-01 Final Verification be re-run.

---

**No implementation performed. No Specification modified. No Governance modified. No commit. No push. No deployment.**
