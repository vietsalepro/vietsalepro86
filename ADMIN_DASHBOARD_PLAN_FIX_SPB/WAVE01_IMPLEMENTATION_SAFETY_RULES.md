# Wave-01 Implementation Safety Rules

**Project:** VietSalePro  
**Program:** Deletion & Audit Architecture Remediation — Wave-01  
**Document:** Wave-01 Implementation Safety Rules  
**Version:** 1.0  
**Status:** Active  
**Date:** 2026-07-23  
**Authority Model:** Production Owner → Chief Technical Advisor → Engineering Execution Agent

---

## 1. Mandatory Reading Confirmation

The Engineering Execution Agent confirms the following mandatory documents were read completely and their constraints applied before these safety rules were drafted.

| # | Document | Path |
|---|----------|------|
| 1 | Vai Trò — Trách Nhiệm — Quyền Hạn | `ADMIN_DASHBOARD_PLAN_FIX_SPB/VAI_TRO_TRACH_NHIEM_VIETSALEPRO.md` |
| 2 | Nguyên Tắc Viết Prompt Cho Agent | `ADMIN_DASHBOARD_PLAN_FIX_SPB/NGUYEN_TAC_VIET_PROMPT_AGENT_VIETSALEPRO.md` |
| 3 | Codebase Memory Baseline | `.codebase-memory/CODEBASE_MEMORY_BASELINE.md` |
| 4 | Semantic Memory | `.codebase-memory/SEMANTIC_MEMORY.md` |
| 5 | Validation Report | `.codebase-memory/VALIDATION_REPORT.md` |
| 6 | Deletion & Audit Architecture Remediation Program | `ADMIN_DASHBOARD_PLAN_FIX_SPB/Deletion_Audit_Architecture_Remediation_Program.md` |
| 7 | Architecture Specification Program | `ADMIN_DASHBOARD_PLAN_FIX_SPB/01_Governance/Architecture_Specification_Program.md` |
| 8 | Architecture Specification Index | `ADMIN_DASHBOARD_PLAN_FIX_SPB/01_Governance/ARCHITECTURE_SPECIFICATION_INDEX.md` |
| 9 | Architecture Specification Baseline Certification | `ADMIN_DASHBOARD_PLAN_FIX_SPB/01_Governance/SPEC_BASELINE_CERTIFICATION.md` |
| 10 | Wave-01 Remediation Program Authorization | `ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE01_REMEDIATION_PROGRAM_AUTHORIZATION.md` |
| 11 | Wave-01 Remediation Scope Definition | `ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE01_REMEDIATION_SCOPE_DEFINITION.md` |
| 12 | Wave-01 Remediation Execution Plan | `ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE01_REMEDIATION_EXECUTION_PLAN.md` |
| 13 | Wave-01 Remediation Acceptance Criteria | `ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE01_REMEDIATION_ACCEPTANCE_CRITERIA.md` |
| 14 | Architecture Governance Evolution Review | `ADMIN_DASHBOARD_PLAN_FIX_SPB/ARCHITECTURE_GOVERNANCE_EVOLUTION_REVIEW.md` |
| 15 | Governance Decision Record | `ADMIN_DASHBOARD_PLAN_FIX_SPB/GOVERNANCE_DECISION_RECORD.md` |

---

## 2. Scope Boundary

Wave-01 is limited to the files and sections identified in `WAVE01_REMEDIATION_SCOPE_DEFINITION.md`.

| Aspect | Authority / Rule |
|--------|------------------|
| **Highest authority for Wave-01** | `SPEC_BASELINE_CERTIFICATION.md` v1.0 |
| **Governance lock** | Active; no governance document may be modified |
| **Authorized files** | `02_Specifications/SPEC-002.md` through `SPEC-007.md` |
| **Forbidden file** | `02_Specifications/SPEC-001_DELETE_FRAMEWORK_ARCHITECTURE_SPECIFICATION.md` |
| **Forbidden actions** | No source code, schema, migration, RPC, Edge Function, test, or deployment change |
| **Change categories** | Category A — mandatory; Category B/C — optional after Category A is complete; Category D — preserve exactly |

---

## 3. Mandatory Safety Questions

### Question 1 — Incidental typo outside the authorized remediation scope

| Item | Decision |
|------|----------|
| **Decision** | **NO.** It may not be corrected. |
| **Justification** | `WAVE01_REMEDIATION_SCOPE_DEFINITION.md` freezes the scope to specific files and sections. Any edit outside those boundaries is a scope expansion, even if it is only a typo. `VAI_TRO_TRACH_NHIEM_VIETSALEPRO.md` and `NGUYEN_TAC_VIET_PROMPT_AGENT_VIETSALEPRO.md` forbid the Engineering Execution Agent from expanding scope. |
| **Required Action** | Record the typo as a deferred finding (`WAVE01_DEFERRED_FINDING_POLICY.md`). Continue the authorized remediation. |
| **Escalation Rule** | If the typo is in a governance document, an approved Specification, or alters the visible meaning of a normative requirement, stop immediately and request Production Owner direction. |

### Question 2 — Table of Contents inconsistency after an authorized change

| Item | Decision |
|------|----------|
| **Decision** | **YES**, it may be updated, but only as a mechanical regeneration of the TOC from existing headings. |
| **Justification** | The TOC is a derived navigation artifact. Updating it preserves readability and does not introduce new content. `WAVE01_REMEDIATION_EXECUTION_PLAN.md` requires the Evidence section structure to remain intact; updating the TOC to reflect the final heading list is incidental. |
| **Required Action** | Regenerate the TOC after all authorized structural edits are complete. Verify every TOC anchor maps to an existing heading and that no heading text was rewritten. |
| **Escalation Rule** | If updating the TOC would change a section number that is referenced by a requirement identifier, cross-reference, or external document, stop and request Production Owner approval. |

### Question 3 — Anchor links or internal cross-references require adjustment because of an authorized structural change

| Item | Decision |
|------|----------|
| **Decision** | **YES**, they may be updated, but only to preserve the original target meaning. |
| **Justification** | `WAVE01_REMEDIATION_ACCEPTANCE_CRITERIA.md` requires "no traceability drift." Authorized structural edits (e.g., `E.1`–`E.10` renumbering in the Evidence section) inherently change heading identifiers, so anchors that point to them must be repaired. |
| **Required Action** | Update only anchors that reference headings whose identifiers changed as a direct result of the authorized edit. Do not create new cross-references or change the text being referenced. |
| **Escalation Rule** | If a broken anchor points to a section outside the authorized edit area or the correct replacement is ambiguous, stop and escalate to the Chief Technical Advisor or Production Owner. |

### Question 4 — Unauthorized governance inconsistency discovered

| Item | Decision |
|------|----------|
| **Decision** | **STOP. Do not modify governance.** |
| **Justification** | `WAVE01_REMEDIATION_PROGRAM_AUTHORIZATION.md` Section 3 and `GOVERNANCE_DECISION_RECORD.md` confirm the governance corpus is locked. `Architecture_Specification_Program.md` Section 26 requires Change Control for any governance change. The Engineering Execution Agent has no authority to alter governance. |
| **Required Action** | Halt the current edit. Record the inconsistency as a deferred finding with governance-impact severity. Notify the Chief Technical Advisor and request Production Owner decision. |
| **Escalation Rule** | Immediate Production Owner escalation. No remediation work may resume on the affected finding until governance direction is clarified. |

### Question 5 — Newly discovered issue unrelated to Category A

| Item | Decision |
|------|----------|
| **Decision** | **NO.** It may not be corrected during Wave-01. |
| **Justification** | `WAVE01_REMEDIATION_SCOPE_DEFINITION.md` Section 4 lists exactly four Category A findings. Sections 5 and 6 permit Category B/C improvements only after all Category A work is complete and only within the same authorized files. A new, unrelated issue is out of scope. |
| **Required Action** | Log the issue as a deferred finding (`WAVE01_DEFERRED_FINDING_POLICY.md`) with a recommended future wave. Continue the authorized Category A work. |
| **Escalation Rule** | If the issue is P0/P1 severity (production-down or critical per `NGUYEN_TAC_VIET_PROMPT_AGENT_VIETSALEPRO.md` Section 7) and affects an authorized file, stop and request Production Owner approval for an emergency scope exception. |

### Question 6 — When must remediation STOP immediately and request Production Owner approval

| Item | Decision |
|------|----------|
| **Decision** | Remediation stops immediately in all conditions listed below. |
| **Justification** | `WAVE01_REMEDIATION_ACCEPTANCE_CRITERIA.md` Section 6 defines cross-cutting acceptance criteria that forbid architecture drift, traceability drift, dependency-graph changes, business-meaning changes, and implementation artifacts. `VAI_TRO_TRACH_NHIEM_VIETSALEPRO.md` gives the Production Owner sole approval authority. |
| **Required Action** | Preserve the working-tree state. Do not save further edits. Document the trigger condition. Notify Production Owner with a concise finding report. |
| **Escalation Rule** | All stop conditions escalate directly to the Production Owner. The Chief Technical Advisor may be consulted for technical context. |

### Question 7 — Incidental changes vs. scope expansion

| Type | Examples | Status |
|------|----------|--------|
| **Incidental** | Markdown whitespace or table alignment inside a section being restructured; heading-number/anchor repair caused by authorized `E.1`–`E.10` renumbering; TOC regeneration; fixing the exact `Classification` field value from `Core` to `Operational` per A-01. | Allowed within the authorized file and task. |
| **Scope expansion** | Adding, removing, or rewording normative requirements; touching Category D sections; editing governance; changing dependency types beyond the optional B-01 label; adding new files or sections; correcting typos or facts outside the authorized section. | Forbidden without Production Owner approval. |

| Item | Decision |
|------|----------|
| **Decision** | The Agent may perform only the incidental changes listed above. |
| **Justification** | `WAVE01_REMEDIATION_SCOPE_DEFINITION.md` specifies exact locations and required states. The `WAVE01_REMEDIATION_EXECUTION_PLAN.md` sequencing principles require scope preservation and traceability. |
| **Required Action** | Before any edit, classify it against the two lists. If it falls under scope expansion, convert it to a deferred finding. |
| **Escalation Rule** | Any uncertainty about classification is a stop condition. |

### Question 8 — Edits always forbidden, even if harmless

| Item | Decision |
|------|----------|
| **Decision** | The following are always forbidden. |
| **Justification** | These boundaries are derived from the governance lock, scope freeze, and role authority in `VAI_TRO_TRACH_NHIEM_VIETSALEPRO.md` and `NGUYEN_TAC_VIET_PROMPT_AGENT_VIETSALEPRO.md`. |
| **Required Action** | None; do not perform the edit. Record any discovered issue as a deferred finding if appropriate. |
| **Escalation Rule** | If a forbidden edit appears unavoidable to complete an authorized task, stop and escalate to the Production Owner. |

**Always forbidden:**

1. Modifying `Deletion_Audit_Architecture_Remediation_Program.md`, `Architecture_Specification_Program.md`, `ARCHITECTURE_SPECIFICATION_INDEX.md`, or `SPEC_BASELINE_CERTIFICATION.md`.
2. Modifying `SPEC-001` or any file outside `02_Specifications/SPEC-002.md` through `SPEC-007.md`.
3. Editing any Category D finding listed in `WAVE01_REMEDIATION_SCOPE_DEFINITION.md` Section 7.
4. Creating, deleting, or renaming Architecture Specifications or governance files.
5. Changing requirement identifiers, dependency declarations, or business-meaning text.
6. Adding new dependency types not defined in `Architecture_Specification_Program.md` Section 34.1 (`Mandatory`, `Optional`, `Prohibited`).
7. Modifying source code, database schema, migrations, RPCs, Edge Functions, tests, or deployment files.
8. Running `git commit`, `git push`, or any deployment command.

---

## 4. Mandatory Implementation Rules

| # | Rule | Source |
|---|------|--------|
| R-01 | **Governance before implementation.** No edit may contradict the locked governance corpus. | `ARCHITECTURE_GOVERNANCE_EVOLUTION_REVIEW.md` Q1–Q5; `GOVERNANCE_DECISION_RECORD.md` Section 9 |
| R-02 | **Scope before optimization.** All Category A corrections are completed before any optional Category B/C work. | `WAVE01_REMEDIATION_EXECUTION_PLAN.md` Section 2 |
| R-03 | **Preserve architecture.** No domain model, contract, state machine, workflow, failure/recovery model, or acceptance criterion may be altered. | `WAVE01_REMEDIATION_EXECUTION_PLAN.md` Section 2.6; `WAVE01_REMEDIATION_ACCEPTANCE_CRITERIA.md` Section 6.1 |
| R-04 | **Preserve traceability.** `SPEC-NNN vX.Y` cross-references and requirement identifiers must remain intact, except for mechanical anchor repair. | `WAVE01_REMEDIATION_ACCEPTANCE_CRITERIA.md` Section 6.2 |
| R-05 | **Preserve requirement identifiers.** Do not add, remove, or renumber requirement IDs. | `WAVE01_REMEDIATION_ACCEPTANCE_CRITERIA.md` Section 6.2 |
| R-06 | **Preserve business meaning.** Rewording is allowed only for mechanical alignment; it must not change normative intent. | `WAVE01_REMEDIATION_ACCEPTANCE_CRITERIA.md` Section 6.4 |
| R-07 | **Preserve Category D.** The ten Allowed Evolution findings are left exactly as-is. | `WAVE01_REMEDIATION_SCOPE_DEFINITION.md` Section 7 |
| R-08 | **Never expand scope without authorization.** New findings are deferred, not patched during Wave-01. | `WAVE01_REMEDIATION_SCOPE_DEFINITION.md` Sections 4–6 |

---

## 5. Stop Conditions

Remediation must stop immediately and the Production Owner must be notified when any of the following is encountered:

1. Governance conflict — any contradiction with `SPEC_BASELINE_CERTIFICATION.md` v1.1.
2. Architecture change requirement — any domain model, contract, state machine, workflow, or failure/recovery model that must change to complete the edit.
3. Requirement identifier change — a required edit cannot be made without adding, removing, or renumbering requirement IDs.
4. Dependency graph change — a `Related Specifications` entry must be added, removed, or retyped beyond the B-01 optional label correction.
5. Business meaning change — the only way to make the edit is to reword a normative requirement.
6. Uncertainty about scope — the Agent cannot determine whether an edit is authorized.
7. Evidence conflict — the file content does not match the evidence recorded in the Wave-01 documents.
8. Missing governance authority — the edit appears necessary but no document authorizes it.
9. Attempt to modify a forbidden file or a Category D finding.
10. Discovery of a P0/P1 issue that is not in the authorized Wave-01 scope.

---

## 6. Escalation Rules

| Condition | First Escalation | Final Authority |
|-----------|------------------|-----------------|
| Technical ambiguity in authorized edit | Chief Technical Advisor | Production Owner |
| Scope interpretation uncertainty | Chief Technical Advisor | Production Owner |
| Governance inconsistency | Chief Technical Advisor | Production Owner |
| P0/P1 issue discovered | Production Owner (immediate) | Production Owner |
| Need to modify governance | Production Owner (immediate) | Production Owner |
| Need to touch Category D | Production Owner (immediate) | Production Owner |
| Any stop condition | Production Owner (immediate) | Production Owner |

---

## 7. Prohibited Actions

The Engineering Execution Agent must not:

- Modify any Architecture Specification outside `SPEC-002`–`SPEC-007`.
- Modify `SPEC-001` or any governance document.
- Perform implementation, compilation, build, test, or deployment.
- Commit or push to the repository.
- Create new requirement identifiers, dependencies, or acceptance criteria.
- Use dependency labels other than `Mandatory`, `Optional`, or `Prohibited`.
- Delete, reclassify, or reword any Category D Allowed Evolution finding.
- Add boilerplate, frameworks, or new documentation unless explicitly required.

---

## 8. Final Decision

**OPTION A — Implementation Safety Rules are APPROVED.**

**Wave-01 Remediation may begin.**

**Rationale:**

- All mandatory role, engineering memory, governance, and Wave-01 input documents have been read.
- The governance lock is confirmed and the highest authority (`SPEC_BASELINE_CERTIFICATION.md` v1.0) is identified.
- The Wave-01 implementation boundaries are frozen and unambiguous.
- Incidental edit policy, scope escalation policy, deferred finding policy, stop conditions, and execution guardrails are documented.
- No Specification, governance document, source code, schema, migration, RPC, Edge Function, test, commit, push, or deployment has been performed.
- These safety rules are evidence-based, consistent with the locked governance corpus, and do not expand the authorized remediation scope.

**Approval note:** The Engineering Execution Agent declares these rules ready for execution. Final Production Owner sign-off remains with the Production Owner per `VAI_TRO_TRACH_NHIEM_VIETSALEPRO.md` Section 1.
