# Wave-01 — Alignment Action Register

**Project:** VietSalePro  
**Program:** Deletion & Audit Architecture Remediation  
**Scope:** SPEC-002 through SPEC-007  
**Governance Authority:** Architecture Specification Program v1.1, SPEC_BASELINE_CERTIFICATION.md v1.0  
**Date:** 2026-07-23  

This register records all findings from the Wave-01 Governance-Based Golden Alignment Review. It contains **Category A (Governance Violation)** and **Category B (Golden Alignment Opportunity)** findings. **Allowed Evolution (Category C)** is recorded separately at the end with `Action Required = NO`.

---

## Category A — Governance Violations (Action Required = YES)

| ID | Specification | Section / Location | Category | Finding | Required Action | Action Required | Rationale |
|----|---------------|---------------------|----------|---------|-----------------|-----------------|-----------|
| A-01 | SPEC-006 Observability | Header line 8; Metadata table line 34 | A | Classification is declared as `Core`; `SPEC_BASELINE_CERTIFICATION.md` Section 20.5 and `ARCHITECTURE_SPECIFICATION_INDEX.md` Section 5.2 mandate `Operational` | Update header and metadata table to `Classification: Operational` | YES | Certification is the highest authority and explicitly assigns Operational classification |
| A-02 | SPEC-005 Foreign Key Governance | `Evidence` section, lines 744-806 (E.1–E.6) | A | Evidence section contains only 6 subsections instead of the certified 10-part structure | Restructure Evidence into `E.1`–`E.10` matching `SPEC_BASELINE_CERTIFICATION.md` Section 15.6: Foundation Documents, Governance Documents, Cross-Validation Results, Extracted Governance Summary, Portfolio Validation, Dependency Validation, Template Compliance, Traceability Summary, Risk Assessment, Confirmation | YES | Prohibited variation of Evidence organization per Certification Section 17 |
| A-03 | SPEC-003 Transaction | `Evidence` section, lines 789-887 (E.1–E.12) | A | Evidence section has 12 subsections and does not use the certified 10-part labels/structure | Re-map the existing verification content into the certified `E.1`–`E.10` structure; domain-specific checks may be retained as sub-bullets within the base sections | YES | Same as A-02 |
| A-04 | SPEC-006 Observability | `Evidence` section, lines 743-818 (E.1–E.13) | A | Evidence section has 13 subsections and does not use the certified 10-part labels/structure | Re-map the existing verification content into the certified `E.1`–`E.10` structure; per-dependency observations belong under `E.6 Dependency Validation` | YES | Same as A-02 |

---

## Category B — Golden Alignment Opportunities (Action Required = NO / Optional)

| ID | Specification | Section / Location | Category | Finding | Recommended Action | Action Required | Rationale |
|----|---------------|---------------------|----------|---------|-------------------|-----------------|-----------|
| B-01 | SPEC-004 Trigger Governance | `Evidence` E.3, lines 715-726 | B | Cross-Validation Results table is less detailed than SPEC-001's `E.3`; it omits Index registration, ID/Name/Classification consistency, dependencies, authoring order, workstream, scope, and governance-version checks | Expand the E.3 table to include the Index/registry cross-validation checks used in SPEC-001 `E.3` | NO | Optional enrichment; not a governance violation |
| B-02 | SPEC-004 Trigger Governance | `Evidence` E.2, line 712 | B | Index reference description omits "registration" and "classification" compared with SPEC-001 `E.2` | Align description with SPEC-001 to explicitly mention registration and classification | NO | Minor wording difference; reference is valid |
| B-03 | SPEC-006 Observability | Header line 17; Metadata table line 43 | B | `Related Specifications` uses "(informative dependency)" which is not a defined dependency type in the Architecture Specification Program Section 34.1 (Mandatory, Optional, Prohibited) | Replace "informative" with "optional" to match the Program's controlled vocabulary and the Index | NO | Label style; intent is clear |

---

## Allowed Evolution (Category C — Action Required = NO)

The following items are **not defects** and require **no corrective action**. They are intentional, governance-compliant enrichments that preserve the architecture.

| ID | Specification | Location | Category | Description |
|----|---------------|----------|----------|-------------|
| C-01 | SPEC-002 | Appendix D | C | Extended Traceability Summary with 18 section mappings to Master Program Section 10.2 |
| C-02 | SPEC-002 | Appendix A-B | C | Audit Event Classification Matrix and Audit Independence Reference Model |
| C-03 | SPEC-003 | Section 16.11 | C | Domain-specific contracts (ACID, Outbox, Compensation, Saga, Timeout, Retry) |
| C-04 | SPEC-003 | Sections 16.8–16.10 | C | Transaction-specific Domain Model, Components, and Interfaces |
| C-05 | SPEC-004 | Sections 16.11, Appendix A-C | C | 19 trigger-specific contracts and Trigger Classification/Mapping templates |
| C-06 | SPEC-005 | Appendix A-F | C | Relationship Classification, Delete/Update Policy Matrices, Cross-Boundary Checklist |
| C-07 | SPEC-006 | Line 658 | C | `Architecture Decisions (Supplementary)` section placed before Appendix |
| C-08 | SPEC-006 | Appendix C | C | Domain-specific glossary (Correlation ID, Trace, Span, Signal, Alert Rule, Retention Policy) |
| C-09 | SPEC-007 | Appendix B-C | C | Verification Taxonomy and Regression Coverage Model appendices |
| C-10 | SPEC-007 | Appendix D | C | Extended glossary for verification domain |

---

## Register Summary

| Category | Count | Action Required |
|----------|-------|-----------------|
| A — Governance Violation | 4 | YES |
| B — Golden Alignment Opportunity | 3 | NO (optional) |
| C — Allowed Evolution | 10 | NO |
