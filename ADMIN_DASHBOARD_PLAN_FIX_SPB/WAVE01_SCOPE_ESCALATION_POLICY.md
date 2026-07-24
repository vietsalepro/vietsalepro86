# Wave-01 Scope Escalation Policy

**Project:** VietSalePro  
**Program:** Deletion & Audit Architecture Remediation — Wave-01  
**Document:** Wave-01 Scope Escalation Policy  
**Version:** 1.0  
**Status:** Active  
**Date:** 2026-07-23  
**Authority Model:** Production Owner → Chief Technical Advisor → Engineering Execution Agent

---

## 1. Scope Authority

The single source of truth for Wave-01 scope is `WAVE01_REMEDIATION_SCOPE_DEFINITION.md` v1.0.

| Authority | Role |
|-----------|------|
| **Production Owner** | Sole authority to approve scope expansion, emergency exceptions, and final acceptance per `VAI_TRO_TRACH_NHIEM_VIETSALEPRO.md` Section 1. |
| **Chief Technical Advisor** | Technical interpretation of scope; may recommend escalation. Cannot approve scope expansion. |
| **Engineering Execution Agent** | Executes only the authorized scope. Must escalate any proposed deviation. |

---

## 2. Scope Categories (Wave-01)

| Category | Definition | Authority to Execute |
|----------|------------|----------------------|
| **Category A** | Mandatory corrections in `SPEC-003`, `SPEC-005`, and `SPEC-006`. | Engineering Execution Agent, per `WAVE01_REMEDIATION_SCOPE_DEFINITION.md` Section 4. |
| **Category B** | Optional repository-consistency improvement (B-01). | Engineering Execution Agent, only after all Category A items are complete and if bandwidth allows. |
| **Category C** | Optional golden-alignment improvements (C-01, C-02). | Engineering Execution Agent, only after all Category A items are complete and if they do not conflict with Category A. |
| **Category D** | Allowed Evolution findings that must be preserved exactly. | None. These are read-only for Wave-01. |

---

## 3. Incident Change Matrix

A change is classified by asking: **Does the edit alter a section or file listed as in-scope for the current task?**

| Condition | Classification | Action |
|-----------|----------------|--------|
| Edit is inside an authorized section of an authorized Specification and is necessary to complete the Category A task. | **In scope** | Proceed. Capture evidence. |
| Edit is inside the same authorized file but outside the listed section, and is purely mechanical (anchor repair, TOC, whitespace) caused by the authorized edit. | **Incidental** | Allowed. Record in the work log. |
| Edit is a typo or factual correction in an authorized file but outside the listed section. | **Scope expansion** | Do not proceed. File a deferred finding. |
| Edit is a Category B/C optional improvement inside `SPEC-004` or `SPEC-006` and all Category A work is complete. | **Optional** | Allowed only if explicitly chosen and no conflict with Category A. |
| Edit touches a Category D finding. | **Forbidden** | Stop. Escalate to Production Owner. |
| Edit touches `SPEC-001` or any governance document. | **Forbidden** | Stop. Escalate to Production Owner. |
| Edit creates a new file, section, requirement, or dependency. | **Scope expansion** | Stop. Escalate to Production Owner. |

---

## 4. Production Owner Approval Requirements

Production Owner approval is mandatory before any of the following:

1. Adding, removing, or retyping a `Related Specifications` dependency.
2. Creating, renaming, or deleting any file in `02_Specifications` or `01_Governance`.
3. Editing `SPEC-001` or any governance document.
4. Changing a Category D Allowed Evolution finding.
5. Addressing a finding that is not in the Wave-01 Category A list.
6. Deviating from the certified `E.1`–`E.10` Evidence structure.
7. Introducing a dependency label not defined in `Architecture_Specification_Program.md` Section 34.1.
8. Any action that could alter business meaning, requirement identifiers, or architecture.

---

## 5. Escalation Process

| Step | Action | Owner |
|------|--------|-------|
| 1 | Pause the current edit. Save no new changes until the question is resolved. | Engineering Execution Agent |
| 2 | Document the proposed deviation, the reason it appears necessary, and the exact file/section/line. | Engineering Execution Agent |
| 3 | Route to the Chief Technical Advisor for technical review unless the issue is governance or scope expansion, in which case route directly to the Production Owner. | Engineering Execution Agent |
| 4 | If the Chief Technical Advisor confirms the deviation is out of scope, escalate to the Production Owner. | Chief Technical Advisor |
| 5 | Production Owner decides: approve with updated scope, defer to a later wave, or reject. | Production Owner |
| 6 | If approved, the updated scope is appended to `WAVE01_REMEDIATION_SCOPE_DEFINITION.md` by the Production Owner or Chief Technical Advisor; the Engineering Execution Agent does not self-authorize. | Production Owner / Chief Technical Advisor |
| 7 | Resume work only after written scope update exists. | Engineering Execution Agent |

---

## 6. Rollback Conditions

The Engineering Execution Agent must roll back (revert to the last known good state) the current edit set when:

1. A stop condition is triggered and continuing would expand scope.
2. An edit is discovered to have touched a Category D finding.
3. An edit is discovered to have modified a governance document.
4. Verification shows that an authorized edit has introduced traceability drift, business-meaning change, or dependency-graph change.
5. The Production Owner or Chief Technical Advisor rejects the current edit direction.
6. A Category A edit cannot be completed without violating the certified `E.1`–`E.10` Evidence model.

**Rollback method:** Restore the affected `02_Specifications/SPEC-00*.md` files from the last git commit before the remediation session. Do not use `git reset --hard` on the entire working tree unless explicitly authorized.

---

## 7. Communication Template

When escalating, use the following structure:

```
Scope Escalation — Wave-01
Finding ID: (if applicable)
File/section/line:
Proposed change:
Why it appears necessary:
Why it is out of scope:
Risk of not doing it:
Recommended decision: (approve / defer to Wave-XX / reject)
```

---

## 8. Evidence

| # | Evidence | Storage |
|---|----------|---------|
| 1 | All scope-escalation requests and decisions | `WAVE01_SCOPE_ESCALATION_POLICY.md` log or a linked `WAVE01_SCOPE_ESCALATION_LOG.md` if produced |
| 2 | Updated scope definition, if any | `WAVE01_REMEDIATION_SCOPE_DEFINITION.md` version bump by PO/CTA |
| 3 | Rollback record | Completion report and git diff |
