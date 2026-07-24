# Implementation Execution Guardrails

**Project:** VietSalePro  
**Program:** Deletion & Audit Architecture Remediation — Wave-01  
**Document:** Implementation Execution Guardrails  
**Version:** 1.0  
**Status:** Active  
**Date:** 2026-07-23  
**Authority Model:** Production Owner → Chief Technical Advisor → Engineering Execution Agent

---

## 1. Pre-Flight Checklist

Before touching any file, the Engineering Execution Agent must verify:

- [ ] `WAVE01_REMEDIATION_SCOPE_DEFINITION.md` v1.0 is open and the authorized file/section is identified.
- [ ] The file is in `02_Specifications/SPEC-002.md` through `SPEC-007.md`.
- [ ] The file is not `SPEC-001` and not a governance document.
- [ ] The specific Category A task (A-01, A-02, A-03, A-04) is known.
- [ ] No uncommitted changes from a previous session are present that could be confused with Wave-01 edits.
- [ ] `WAVE01_IMPLEMENTATION_SAFETY_RULES.md`, `WAVE01_SCOPE_ESCALATION_POLICY.md`, and `WAVE01_DEFERRED_FINDING_POLICY.md` are accessible.
- [ ] A log or register is ready to capture deferred findings.

---

## 2. Edit Constraints

| # | Constraint |
|---|------------|
| C-01 | Edit only the file and sections listed in `WAVE01_REMEDIATION_SCOPE_DEFINITION.md`. |
| C-02 | Complete all Category A corrections before any Category B/C optional work. |
| C-03 | Preserve all Category D findings exactly as they are. |
| C-04 | Do not add, remove, or renumber requirement identifiers. |
| C-05 | Do not alter `SPEC-NNN vX.Y` cross-references except to repair mechanical anchors caused by authorized renumbering. |
| C-06 | Do not introduce dependency labels other than `Mandatory`, `Optional`, or `Prohibited`. |
| C-07 | Do not change the business meaning of any normative statement. |
| C-08 | Do not create new files, sections, or acceptance criteria. |
| C-09 | Do not edit source code, migrations, RPCs, Edge Functions, tests, or deployment files. |
| C-10 | Do not run `git commit`, `git push`, or any deployment command. |

---

## 3. Real-Time Verification Commands

After each authorized edit, run the relevant checks from `WAVE01_REMEDIATION_EXECUTION_PLAN.md` Phase 3 and `WAVE01_REMEDIATION_ACCEPTANCE_CRITERIA.md`.

| Task | Verification Command | Pass Condition |
|------|----------------------|----------------|
| A-01 | `grep -i "Classification" 02_Specifications/SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md` | Only `Operational` remains |
| A-02 | `grep "^### E\." 02_Specifications/SPEC-005_FOREIGN_KEY_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` | Exactly `E.1` through `E.10` with certified titles |
| A-03 | `grep "^### E\." 02_Specifications/SPEC-003_TRANSACTION_ARCHITECTURE_SPECIFICATION.md` | Exactly `E.1` through `E.10` with certified titles |
| A-04 | `grep "^### E\." 02_Specifications/SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md` | Exactly `E.1` through `E.10` with certified titles |
| B-01 | `grep -i "informative dependency" 02_Specifications/SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md` | No matches; `(optional)` is present in the intended locations |
| C-01 | Visual inspection of `E.3` table in `SPEC-004` | Table contains the required rows |
| C-02 | Visual inspection of `E.2` description in `SPEC-004` | Description mentions registration, classification, dependencies, and authoring order |

---

## 4. Evidence Capture

Every authorized edit must be accompanied by:

1. **Before / After summary** — what changed and why.
2. **Files changed list** — exact paths of `02_Specifications/SPEC-00*.md` touched.
3. **Diff** — `git diff` output for the authorized files only.
4. **Verification command output** — the grep or inspection results from Section 3.
5. **Category D check** — statement that no Category D finding was modified.
6. **Governance lock confirmation** — statement that no governance file was modified.
7. **No-implementation statement** — no code, schema, migration, RPC, Edge Function, or deployment change was made.
8. **No-commit/push statement** — no commit or push was performed.

---

## 5. Allowed Mechanical Edits

The following are allowed if they are direct consequences of authorized edits in the same file:

- Regenerating the Table of Contents.
- Repairing anchor links that point to renumbered headings.
- Adjusting whitespace or table alignment within the edited section.
- Updating the `Classification` field from `Core` to `Operational` in `SPEC-006` per A-01.
- Replacing `(informative dependency)` with `(optional)` in `SPEC-006` per B-01.

---

## 6. Disallowed Edits

The following are disallowed, even if they appear harmless:

- Typo or grammar corrections outside the authorized section.
- Rewording for style unless the exact wording is part of an authorized alignment.
- Adding new headings, subsections, or appendices.
- Changing file metadata other than the fields explicitly listed in a Category A task.
- Modifying the version number of the Specification unless explicitly authorized.

---

## 7. Stop and Rollback Triggers

| Trigger | Immediate Action |
|---------|------------------|
| Accidental edit to a governance file | Stop. Restore the file from git. Escalate to Production Owner. |
| Accidental edit to `SPEC-001` or `SPEC-002` or `SPEC-007` outside scope | Stop. Restore the file from git. Escalate to Production Owner. |
| Category D finding modified | Stop. Restore the section from git. Escalate to Production Owner. |
| `grep` verification fails | Stop. Do not proceed to the next task. Fix the current task or escalate. |
| Uncertainty whether an edit is in scope | Stop. Treat as a deferred finding and escalate. |
| Scope expansion proposed by Chief Technical Advisor but not approved by Production Owner | Do not apply. Continue with the existing authorized scope. |

---

## 8. Completion Gate

Wave-01 remediation is not considered complete until:

- [ ] All four Category A findings are corrected.
- [ ] All verification commands in Section 3 pass.
- [ ] No Category D finding has been modified.
- [ ] No governance document has been modified.
- [ ] No source code, schema, migration, RPC, Edge Function, test, or deployment file has been modified.
- [ ] No commit or push has been made.
- [ ] All deferred findings are recorded with the mandatory fields.
- [ ] Evidence from Section 4 is collected and ready for the Wave-01 Completion Report.
