# Wave-01 Deferred Finding Policy

**Project:** VietSalePro  
**Program:** Deletion & Audit Architecture Remediation — Wave-01  
**Document:** Wave-01 Deferred Finding Policy  
**Version:** 1.0  
**Status:** Active  
**Date:** 2026-07-23  
**Authority Model:** Production Owner → Chief Technical Advisor → Engineering Execution Agent

---

## 1. Purpose

During Wave-01 remediation, the Engineering Execution Agent may discover issues that are valid but outside the authorized scope. This policy defines how those findings are recorded, classified, and scheduled for future work without expanding Wave-01.

---

## 2. When to Defer

A finding must be deferred when:

1. It is real, but it is not one of the four Category A findings.
2. It is outside the specific file/section/line authorized for the current task.
3. It is a Category B/C improvement that cannot be completed after Category A without conflicting with Category A.
4. It requires Production Owner approval but is not critical to Wave-01 acceptance.
5. It cannot be corrected without modifying governance, `SPEC-001`, or a Category D finding.
6. It cannot be corrected without changing architecture, business meaning, requirement identifiers, or the dependency graph.

---

## 3. Mandatory Deferred Finding Fields

Every deferred finding must include all of the following fields:

| Field | Description |
|-------|-------------|
| **Identifier** | `DF-W01-NNN` (sequential within Wave-01) |
| **Description** | One-sentence description of the issue |
| **Location** | Exact file path and, where possible, line/section |
| **Reason for defer** | Why it is not being fixed in Wave-01 |
| **Recommended future wave** | Suggested wave or program that owns the fix |
| **Severity** | P0–P4 per `NGUYEN_TAC_VIET_PROMPT_AGENT_VIETSALEPRO.md` Section 7 |
| **Governance impact** | Whether the finding touches governance, certification, or architecture |
| **Discovered during** | Task ID (e.g., A-01, B-01) |
| **Date** | Discovery date |
| **Agent** | Engineering Execution Agent identifier/session |

---

## 4. Severity Classification

| Level | Definition | Wave-01 Action |
|-------|------------|----------------|
| **P0** | Production down or data-loss risk | Stop. Escalate to Production Owner immediately. Do not continue until direction is given. |
| **P1** | Critical defect that blocks the current authorized task | Stop the current task. Escalate to Production Owner. If the task cannot proceed without fixing the P1, request an emergency scope exception. |
| **P2** | Major issue that does not block the current task but should be fixed soon | Defer to Wave-02 or a follow-up wave. Record in the deferred finding register. |
| **P3** | Minor inconsistency or cosmetic issue | Defer to the next maintenance wave or the next alignment review. |
| **P4** | Cosmetic, style, or preference | Defer; may be closed without action if no future wave picks it up. |

---

## 5. Governance Impact Levels

| Level | Meaning | Example |
|-------|---------|---------|
| **High** | Finding implies a governance, certification, architecture, or `SPEC-001` change | `SPEC_BASELINE_CERTIFICATION.md` appears internally inconsistent |
| **Medium** | Finding is in an authorized Specification but outside the current task section | A typo in `SPEC-003` outside the Evidence section |
| **Low** | Finding is cosmetic or local and has no traceability impact | A markdown alignment inconsistency in an untouched section |
| **None** | Finding is a matter of style preference | Choice between two equivalent markdown formats |

---

## 6. Workflow

| Step | Action | Output |
|------|--------|--------|
| 1 | Identify a non-authorized issue during authorized work. | Mental classification: in-scope, incidental, or deferred. |
| 2 | If unsure, treat as deferred and pause. | Escalation request if P0/P1. |
| 3 | Record the finding using the mandatory fields. | `DF-W01-NNN` entry in the Wave-01 Deferred Finding Register. |
| 4 | Continue the authorized Wave-01 remediation. | No scope expansion. |
| 5 | At completion, append the full deferred finding list to the Wave-01 Completion Report. | Evidence of scope discipline. |
| 6 | Hand off the register to the Chief Technical Advisor for future wave prioritization. | Input to Wave-02 planning. |

---

## 7. Reactivation Rules

A deferred finding becomes active again when:

1. The Production Owner explicitly authorizes it in a future wave scope document.
2. It is reclassified as P0 or P1 during a verification gate.
3. A future governance review declares it in-scope.

Until one of these occurs, the finding remains deferred and must not be patched during Wave-01.

---

## 8. Example Template

```markdown
| ID | Description | Location | Reason for defer | Future wave | Severity | Governance impact |
|----|-------------|----------|------------------|-------------|----------|-------------------|
| DF-W01-001 | Typo in `SPEC-003` Section 16.5 | `02_Specifications/SPEC-003_TRANSACTION_ARCHITECTURE_SPECIFICATION.md` line 312 | Outside the authorized Evidence-section restructure; not in scope for Wave-01 | Wave-02 repository consistency sweep | P4 | Low |
```

---

## 9. Evidence

| # | Evidence | Storage |
|---|----------|---------|
| 1 | Deferred Finding Register | `WAVE01_DEFERRED_FINDING_REGISTER.md` or a section in the Wave-01 Completion Report |
| 2 | P0/P1 escalation records | Immediate notification to Production Owner and completion report |
| 3 | Handoff to future waves | Chief Technical Advisor planning documents |
