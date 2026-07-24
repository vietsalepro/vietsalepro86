# Governance Change Impact Analysis

**Project:** VietSalePro  
**Program:** Architecture Governance Evolution Review  
**Date:** 2026-07-23  
**Status:** Draft — No implementation, commit, push, or deployment performed  
**Authority Model:** Production Owner → Chief Technical Advisor → Engineering Execution Agent  

---

## 1. Scope

This document evaluates the three candidate governance evolutions identified during the Architecture Governance Evolution Review. Each candidate is analyzed against the mandatory impact dimensions required by the program.

No governance document, specification, or repository artifact was modified in producing this analysis.

---

## 2. Candidate EV-01: Formalize an `Allowed Evolution` Register / Category

### Current Governance

- `SPEC_BASELINE_CERTIFICATION.md` Section 16 — *Allowed Variations* already enumerates 16 content-level aspects that future Specifications MAY vary.
- `SPEC_BASELINE_CERTIFICATION.md` Section 20 — per-SPEC allowed variations list permitted domain-model, component, contract, state-machine, failure-model, and recovery-model variations for SPEC-002 through SPEC-007.
- `Architecture_Specification_Program.md` Section 35 — *Architecture Specification Registry* and Section 36 — *Index Governance* define the portfolio registry but do not include a discrete `Allowed Evolution` classification.
- Wave-01 introduced the colloquial `Category C — Allowed Evolution` / `Category D — Allowed Evolution` labels in `WAVE01_GOVERNANCE_ALIGNMENT_REVIEW.md` and `WAVE01_FINAL_ACTION_REGISTER.md`.

### Observed Repository Pattern

Wave-01 found 10 Allowed Evolution findings across six Specifications (SPEC-002 through SPEC-007). All 10 were content-level enrichments permitted by the existing Allowed Variations and per-SPEC allowed-variation rules. They appeared repeatedly as:

1. Domain-specific domain models / components / interfaces / contracts.
2. Appendix supporting material (matrices, glossaries, taxonomies, classification models).
3. Extended traceability and supplementary pre-Appendix sections.

### Reason for Evolution

Proponents might argue that a dedicated `Allowed Evolution` register or finding category would make reviews faster and provide a canonical place to record recurring permitted deviations.

### Benefits

- Faster classification during future alignment reviews.
- A single catalog of pre-approved variation patterns.
- Reduced ambiguity between "golden-alignment opportunity" and "allowed evolution".

### Risks

- **Duplication** of the existing Allowed Variations framework.
- **Over-governance** — adds a new artifact class to maintain.
- **Versioning instability** — Wave-01 registers would need reclassification/re-baseline if the new category is retroactively applied.
- **Scope creep** — reviewers may be tempted to record every minor content difference.

### Affected Documents

| Document | Impact |
|----------|--------|
| `Architecture_Specification_Program.md` | Add Allowed Evolution register/category rules (likely Sections 30, 35, 36). |
| `ARCHITECTURE_SPECIFICATION_INDEX.md` | Add navigation and portfolio filtering by Allowed Evolution status. |
| `SPEC_BASELINE_CERTIFICATION.md` | Update Section 16 to reference the new register. |
| `WAVE01_*` files | Re-classify 10 D findings; re-baseline verification. |
| All SPEC Evidence sections | May need to reference the new register. |

### Backward Compatibility

Can be made backward-compatible if the new register is additive only. However, it would still require version increments of all governance documents and re-cross-referencing by every Specification.

### Certification Impact

`SPEC_BASELINE_CERTIFICATION.md` v1.0 would no longer be the current certified version. Re-certification of SPEC-001 as the Golden Specification would be required because the inheritance rules would reference a changed governance layer.

### Repository Impact

- New governance artifact and possible new folder/identifier.
- Re-categorization of historical Wave-01 records.
- Risk of divergent register and Index if not synchronized.

### Engineering Impact

- Authors would need to consult one more artifact when drafting.
- Reviewers would need to update checklists.
- Tooling/scripts that parse the Index/Registry would need updates.

### Maintenance Impact

- Adds ongoing maintenance of the Allowed Evolution register.
- Each new Specification wave could expand the register, increasing governance volume without proportional engineering value.

### Recommendation

**REJECT for now.** The current Allowed Variations framework already supports these patterns. A dedicated register is premature and would increase governance weight before the portfolio has matured.

---

## 3. Candidate EV-02: Add `Informative` as a Dependency Type

### Current Governance

- `Architecture_Specification_Program.md` Section 34.1 defines three dependency types: **Mandatory**, **Optional**, and **Prohibited**.
- `SPEC_BASELINE_CERTIFICATION.md` Section 17 — *Prohibited Variations* protects the metadata structure, but does not explicitly prohibit additional dependency-type words.
- Wave-01 B-03 observed that SPEC-006 used `(informative dependency)`, which is not a Program-defined type, but concluded it was a repository-consistency issue because no governance sentence explicitly prohibits the word.

### Observed Repository Pattern

SPEC-006 used `(informative dependency)` in both the header `Related Specifications` and the metadata table to describe a non-blocking reference to other Specifications.

### Reason for Evolution

If authors repeatedly use `informative` to indicate a dependency that is neither mandatory nor prohibited, governance could codify the term to avoid future B findings.

### Benefits

- Eliminates a recurring repository-consistency finding.
- Provides a precise label for reference-only dependencies.
- Reduces author confusion about when to use `Optional`.

### Risks

- **Dilutes the three-type model.** `Optional` already covers non-mandatory, non-prohibited references; a fourth type is redundant.
- **Index inconsistency.** `ARCHITECTURE_SPECIFICATION_INDEX.md` and `SPEC_BASELINE_CERTIFICATION.md` use `Optional` for the same relationships.
- **Certification churn.** Changing the dependency vocabulary would require updating `Architecture_Specification_Program.md` Section 34.1, the Index dependency tables, and SPEC-006.
- **Author confusion.** Future authors may struggle to choose between `Optional` and `Informative`.

### Affected Documents

| Document | Impact |
|----------|--------|
| `Architecture_Specification_Program.md` | Update Section 34.1 dependency-type definitions. |
| `ARCHITECTURE_SPECIFICATION_INDEX.md` | Update dependency-type vocabulary and tables. |
| `SPEC_BASELINE_CERTIFICATION.md` | Update Prohibited/Allowed Variations if dependency vocabulary is declared protected. |
| `SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md` | Change `(informative dependency)` to the new/approved type. |
| All Specifications using `Optional` | No change if `Informative` is additive; but guidance must be added. |

### Backward Compatibility

Backward-compatible only if `Informative` is added as an alias for `Optional`. However, that undermines the value of having a distinct type. If it is made semantically different, existing `Optional` references must be reviewed for reclassification.

### Certification Impact

`SPEC_BASELINE_CERTIFICATION.md` would need a new version because the inheritance and dependency rules would have changed. The Golden Specification (SPEC-001) and all dependent Specifications would need re-validation of dependency declarations.

### Repository Impact

- Minor text edits to governance and SPEC-006 if adopted.
- Risk of inconsistent dependency vocabulary across the portfolio if authors use both `Optional` and `Informative`.

### Engineering Impact

- Authors must learn a fourth dependency type.
- Dependency-validation scripts must be updated.

### Maintenance Impact

- Ongoing review burden to ensure `Optional` vs `Informative` is applied consistently.
- Potential recurring B findings if the distinction is unclear.

### Recommendation

**REJECT for now.** The intent of `(informative dependency)` is already covered by `Optional` per `Architecture_Specification_Program.md` Section 34.1. The Wave-01 remediation should replace `(informative dependency)` with `(optional)`. No governance change is required.

---

## 4. Candidate EV-03: Relax or Modularize the 10-Part Evidence Section Structure

### Current Governance

- `SPEC_BASELINE_CERTIFICATION.md` Section 15.6 — *Evidence Format* mandates that every future Specification SHALL include an Evidence section with the same 10-part structure as SPEC-001.
- `SPEC_BASELINE_CERTIFICATION.md` Section 17 — *Prohibited Variations* explicitly protects `Evidence organization` and the 10-part structure.
- `Architecture_Specification_Program.md` Sections 16.23 and 27 reinforce evidence and quality-gate requirements.

### Observed Repository Pattern

Wave-01 found three Evidence-structure deviations:

- SPEC-005 used only 6 subsections (`E.1`–`E.6`).
- SPEC-003 used 12 subsections with non-certified labels.
- SPEC-006 used 13 subsections with non-certified labels.

All three were classified as Category A — confirmed governance violations.

### Reason for Evolution

Some authors may prefer to insert domain-specific verification subsections or to shorten the Evidence section. Relaxing the structure would reduce A findings and align with the desire for domain-specific expression.

### Benefits

- More flexibility for authors.
- Potentially fewer Evidence-structure findings in future waves.
- Allows domain-specific evidence to be organized by concern.

### Risks

- **Breaks the Golden Specification certification.** SPEC-001's Evidence section is the certified reference; changing the structure invalidates `SPEC_BASELINE_CERTIFICATION.md` Section 15.6.
- **Weakens traceability.** Cross-Specification comparison of Evidence sections becomes impossible if each Specification uses its own layout.
- **Re-opens Wave-01.** The four Category A findings are grounded in the 10-part rule; changing the rule would invalidate the verification.
- **Creates review inconsistency.** Reviewers would no longer have a deterministic template to check.

### Affected Documents

| Document | Impact |
|----------|--------|
| `SPEC_BASELINE_CERTIFICATION.md` | Sections 15.6 and 17 would require complete rewrite. |
| `Architecture_Specification_Program.md` | Sections 16.23, 27, and mandatory template would change. |
| `SPEC-001_DELETE_FRAMEWORK_ARCHITECTURE_SPECIFICATION.md` | Golden Example Evidence section would no longer be the reference. |
| SPEC-002 through SPEC-007 | Evidence sections would need re-evaluation/restructuring. |
| `WAVE01_FINAL_VERIFICATION_REPORT.md` | All A-2, A-3, A-4 verdicts would be undermined. |

### Backward Compatibility

Not backward-compatible. It is a direct reversal of a *Prohibited Variation*. Existing baselined Specifications would no longer match the new template.

### Certification Impact

Severe. `SPEC_BASELINE_CERTIFICATION.md` v1.0 would be superseded; the Golden Specification would need re-certification; the Wave-01 Final Verification would be void because its Category A findings depend on the 10-part rule.

### Repository Impact

- All Specifications authored under the 10-part rule would be misaligned with the new relaxed rule.
- Traceability matrices, verification reports, and acceptance records would need reconciliation.

### Engineering Impact

- Authors would lose a deterministic checklist.
- Verification scripts that parse Evidence subsections would fail.
- Future reviews would require more manual judgment.

### Maintenance Impact

- Higher maintenance: every future Specification would need bespoke review.
- Governance drift as each wave invents its own evidence format.

### Recommendation

**REJECT.** The 10-part Evidence structure is a cornerstone of the Golden Specification and the Wave-01 verification. Deviations should be corrected through remediation, not accommodated by governance change.

---

## 5. Summary of Recommendations

| Candidate | Recommendation | Primary Risk if Adopted |
|-----------|----------------|-------------------------|
| EV-01 — Allowed Evolution register | REJECT | Over-governance and duplication of existing Allowed Variations |
| EV-02 — `Informative` dependency type | REJECT | Dilution of the Mandatory/Optional/Prohibited model; unnecessary certification churn |
| EV-03 — Relax Evidence section structure | REJECT | Invalidates `SPEC_BASELINE_CERTIFICATION.md` and Wave-01 verification |

No candidate governance evolution is justified by the Wave-01 evidence. The appropriate next step is to execute `WAVE01_ALIGNMENT_EXECUTION_PLAN.md` and `WAVE01_FINAL_ACTION_REGISTER.md` under the current governance.
