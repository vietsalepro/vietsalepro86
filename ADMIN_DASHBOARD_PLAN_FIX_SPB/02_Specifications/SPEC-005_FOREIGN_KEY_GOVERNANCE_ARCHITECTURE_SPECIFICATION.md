# SPEC-005 — Foreign Key Governance Architecture Specification

**Project:** VietSalePro  
**Subsystem:** Admin Dashboard / Enterprise Architecture  
**Specification Name:** Foreign Key Governance Architecture Specification  
**Short Identifier:** ForeignKeyGovernance  
**Specification ID:** SPEC-005  
**Classification:** Core  
**Status:** Draft  
**Version:** 1.0  
**Effective Date:** 2026-07-23  
**Author:** Engineering Execution Agent  
**Technical Custodian:** Chief Technical Advisor (Architecture Governance)  
**Final Owner:** Production Owner  
**Approvers:** Chief Technical Advisor, Production Owner  
**Master Program Reference:** Deletion & Audit Architecture Remediation Program v1.0  
**Related Specifications:** SPEC-001 Delete Framework (dependent), SPEC-002 Audit Architecture (dependent), SPEC-003 Transaction Architecture (dependent), SPEC-004 Trigger Governance (related)  
**Related ADRs:** None recorded.  
**Roadmap Items:** None recorded.  

---

## 16.1 Metadata

This specification is the authoritative architecture definition for **Foreign Key Governance** in VietSalePro. It is a **Core** specification that establishes the enterprise referential-integrity policy, relationship ownership model, relationship catalog, and foreign-key lifecycle for every persistent relationship in the platform. Its identifier is `SPEC-005`; its short identifier is `ForeignKeyGovernance`; its version is `1.0`.

| Field | Value |
|---|---|
| Project | VietSalePro |
| Subsystem | Admin Dashboard / Enterprise Architecture |
| Specification ID | SPEC-005 |
| Name | Foreign Key Governance Architecture Specification |
| Short Identifier | ForeignKeyGovernance |
| Classification | Core |
| Status | Draft |
| Version | 1.0 |
| Effective Date | 2026-07-23 |
| Author | Engineering Execution Agent |
| Technical Custodian | Chief Technical Advisor (Architecture Governance) |
| Final Owner | Production Owner |
| Approvers | Chief Technical Advisor, Production Owner |
| Master Program | Deletion & Audit Architecture Remediation Program v1.0 |
| Related Specifications | SPEC-001 Delete Framework (dependent), SPEC-002 Audit Architecture (dependent), SPEC-003 Transaction Architecture (dependent), SPEC-004 Trigger Governance (related) |
| Related ADRs | None recorded |
| Roadmap Items | None recorded |

---

## 16.2 Purpose

**SPEC-005-PUR-001.** This document defines the enterprise Foreign Key Governance Architecture for VietSalePro.

**SPEC-005-PUR-002.** The Foreign Key Governance Architecture shall make every persistent relationship explicit, classified, owned, validated, and traceable. Every referential-integrity policy shall be declared in a single authoritative catalog before it is realized in any persistence layer.

**SPEC-005-PUR-003.** The architecture shall provide the referential-integrity foundation required by SPEC-001 (Delete Framework) for delete-policy decisions, by SPEC-002 (Audit Architecture) for audit-record independence from operational foreign keys, by SPEC-003 (Transaction Architecture) for transaction-boundary enforcement, and by SPEC-004 (Trigger Governance) for distinguishing legitimate referential-cascade triggers from forbidden business-workflow triggers.

**SPEC-005-PUR-004.** The architecture shall define the ownership, lifecycle, classification, cardinality, optionality, delete policy, update policy, and cross-boundary rules for every relationship, ensuring that the persistence layer enforces only those integrity constraints that have been reviewed and approved as architecture.

**SPEC-005-PUR-005.** This specification shall not prescribe implementation code, file names, deployment commands, data-definition statements, or persistence-layer syntax. Those details belong in Implementation Plans derived from this specification.

---

## 16.3 Scope

**SPEC-005-SCO-001.** This specification covers the conceptual Foreign Key Governance Architecture and its canonical model for all persistent relationships in VietSalePro.

**SPEC-005-SCO-002.** The following foreign-key governance concerns are explicitly covered by this specification:

- Foreign key governance principles and referential-integrity principles;
- Foreign key ownership and the separation of ownership from application workflow;
- Foreign key lifecycle from proposal through retirement;
- Foreign key registration, cataloging, and relationship metadata;
- Parent–child and aggregate ownership models;
- Referential-integrity contracts and relationship classification;
- Cardinality governance, mandatory relationships, and optional relationships;
- Delete policy classification: CASCADE, RESTRICT, SET NULL, and NO ACTION;
- Update policy classification and identifier-stability rules;
- Referential boundary rules, including cross-aggregate, cross-module, and cross-tenant relationships;
- Circular dependency prevention and detection;
- Relationship validation, consistency, and determinism requirements;
- Referential-integrity verification, failure model, and recovery model;
- Security, compliance, observability, monitoring, and risk governance;
- Architecture decisions, traceability, verification requirements, and acceptance criteria.

**SPEC-005-SCO-003.** The Foreign Key Governance Architecture shall define how referential-integrity policies are separated from business workflow, business decisions, transaction orchestration, delete orchestration, trigger behavior, and audit lifecycle, and how each responsibility is assigned to the architecture that owns it.

**SPEC-005-SCO-004.** This specification does not define internal schemas, table names, column types, persistence-layer syntax, transition artifacts, or runtime deployment artifacts. Those details belong in Implementation Plans derived from this specification.

**SPEC-005-SCO-005.** Future persistent relationships introduced after initial implementation shall be registered and classified according to this architecture at design time; they shall not be introduced without governance review.

---

## 16.4 References

**SPEC-005-REF-001.** The following normative references govern this specification:

| Identifier | Title | Version | Purpose |
|---|---|---|---|
| Master Program | Deletion & Audit Architecture Remediation Program | v1.0 | Program vision, principles, workstreams, and scope; explicit-foreign-key-contract workstream (Section 10.5) |
| SPEC-001 | Delete Framework Architecture Specification | v1.1 (dependent) | Consumes SPEC-005 delete-policy contracts, cascade rules, and referential-boundary decisions |
| SPEC-002 | Audit Architecture Specification | v1.0 (dependent) | Audit-record independence from operational foreign keys; audit-survival contract |
| SPEC-003 | Transaction Architecture Specification | v1.0 (dependent) | Transaction boundary ownership and rollback behavior for referential-integrity failures |
| SPEC-004 | Trigger Governance Architecture Specification | v1.0 (related) | Legitimate referential-cascade triggers versus forbidden business-workflow triggers |
| SPEC-006 | Observability Specification | TBD (related) | Observability instrumentation for relationship validation and policy drift |
| SPEC-007 | Regression & Verification Specification | TBD (related) | Regression coverage for foreign-key policy enforcement |

---

## 16.5 Architecture Context

**SPEC-005-CTX-001.** The VietSalePro platform currently maintains many persistent relationships across operational, audit, billing, security, and administrative domains. The `ON DELETE` and `ON UPDATE` behaviors of these relationships were selected locally during implementation without a unified risk model, ownership model, or review process.

**SPEC-005-CTX-002.** The `delete-tenant` HTTP 500 incident demonstrated a failure class in which an `AFTER DELETE` trigger attempted to insert an audit row that referenced an operational entity being removed in the same transaction. The underlying cause was not a trigger defect alone; it was an inverted dependency between an immutable audit record and a transient operational entity, combined with the absence of an explicit foreign-key ownership and policy catalog.

**SPEC-005-CTX-003.** The underlying architectural deficiencies exposed by that incident are:

1. No authoritative catalog of relationships exists; their number, direction, ownership, and delete/update policies are not visible to architects, reviewers, or operators.
2. Foreign-key policies are not classified by architectural purpose, so cascade paths that protect integrity are indistinguishable from cascade paths that encode business workflow.
3. Audit records are coupled to operational entities through foreign keys, preventing audit history from surviving entity deletion.
4. Cross-aggregate and cross-module relationships are not reviewed, allowing hidden cascade paths and circular dependency risks.
5. No process exists to propose, classify, validate, approve, or retire a relationship before it is introduced or modified.
6. Transaction boundaries and delete orchestration are inferred from implicit foreign-key behaviors rather than governed by explicit architecture.

**SPEC-005-CTX-004.** The target architecture treats foreign-key governance as a platform capability. Every relationship is registered in a Foreign Key Catalog, classified by ownership and policy, reviewed for cross-boundary risk, and validated for determinism. Referential-integrity policy is the sole responsibility of Foreign Key Governance; delete orchestration, transaction boundaries, trigger behavior, and audit lifecycle are assigned to the architectures that own them.

**SPEC-005-CTX-005.** The architecture shall be technology-neutral: it may be realized through any persistence layer that supports declarative or procedural referential-integrity enforcement, provided the contracts and invariants defined in this specification are preserved.

---

## 16.6 Responsibilities

**SPEC-005-RES-001.** The responsibilities of each architecture in the foreign-key governance model are:

| Architecture | Responsibility |
|---|---|
| Foreign Key Governance | Owns referential-integrity policy: relationship cataloging, classification, ownership, delete policy, update policy, validation, and cross-boundary review. |
| Delete Framework | Owns delete orchestration and the decision of whether, when, and how a delete is performed, per SPEC-001. |
| Transaction Architecture | Owns transaction boundaries, commit/rollback semantics, and side-effect coordination, per SPEC-003. |
| Trigger Governance | Owns which persistence-layer triggers are legitimate and how they are classified, per SPEC-004. |
| Audit Architecture | Owns audit-record lifecycle, immutability, and independence from operational entity lifecycles, per SPEC-002. |
| Domain Model / Data Architecture | Owns the logical entity model and proposes relationships to the Foreign Key Catalog. |
| Implementation Team | Realizes approved foreign-key policies using the persistence-layer mechanisms selected by the Implementation Plan. |

**SPEC-005-RES-002.** Foreign Key Governance shall not implement business workflow, business decisions, delete orchestration, transaction coordination, trigger behavior, or audit logic.

**SPEC-005-RES-003.** The persistence layer shall enforce only those referential-integrity policies that have been registered and approved in the Foreign Key Catalog.

---

## 16.7 Architecture Principles Mapping

**SPEC-005-PRM-001.** The Foreign Key Governance Architecture shall implement every principle of the Master Program as follows:

| Principle | Mapping to Foreign Key Governance |
|---|---|
| Deletion is explicit | Every delete policy and cascade path is declared in the Foreign Key Catalog before implementation; no behavior is implicit. |
| Deletion is deterministic | The same parent-state change yields the same child-state result for a given policy classification. |
| Deletion is idempotent | Cascade paths and set-null rules are deterministic and replay-safe at the referential-integrity layer. |
| Deletion is observable | Every catalog change and integrity failure is emitted as structured observability data. |
| Deletion is recoverable | Referential-integrity failures are classified and mapped to rollback or remediation actions. |
| Audit is immutable | Audit records are not coupled to operational entities through mandatory foreign keys; audit survival is a first-class policy requirement. |
| Database owns integrity | The persistence layer enforces declared referential-integrity policies within the transaction boundary. |
| Application owns workflow | Business workflow, side-effect ordering, and business decisions remain outside the referential-integrity policy. |
| Platform before feature | New relationships are registered and classified in the catalog before any feature consumes them. |
| Reuse before reinvention | Existing approved policies are reused; new policies require review and classification. |
| Side effects are compensatable | Cascade behaviors at the persistence layer are not substitutes for application-level compensation logic. |
| Failure is a first-class state | Integrity violations produce structured failures, recovery guidance, and trace records. |

### 16.7.1 Foreign Key Governance Mandates

**SPEC-005-PRM-002.** The following mandates govern every relationship:

- Foreign keys protect referential integrity.
- Foreign keys MUST NOT implement business workflow.
- Foreign keys MUST NOT encode business decisions.
- Foreign keys MUST NOT replace Transaction Architecture.
- Foreign keys MUST NOT replace Delete Framework.
- Foreign keys MUST NOT replace Trigger Governance.
- Foreign keys MUST NOT create hidden business behavior.
- Delete Framework owns delete orchestration.
- Transaction Coordinator owns transaction boundaries.
- Trigger Governance owns trigger behavior.
- Audit Architecture owns audit lifecycle.
- Foreign Key Governance owns only referential integrity policy.

### 16.7.2 Architecture Decisions

**SPEC-005-PRM-003.** The following architecture decisions are encoded by this specification:

| Decision | Rationale |
|---|---|
| All relationships are cataloged centrally | A single catalog prevents hidden cascade paths and makes change impact traceable. |
| Delete and update policies are classified, not ad-hoc | Classification forces an explicit risk decision for every relationship. |
| Audit records are independent of operational foreign keys | Audit history must outlive the entities it describes. |
| Cross-aggregate and cross-module relationships require review | Unreviewed cross-boundary relationships are the primary source of cascade surprises and circular dependencies. |
| Referential-integrity policy is separated from transaction and delete orchestration | Integrity enforcement belongs to the persistence layer; orchestration belongs to application architecture. |

---

## 16.8 Domain Model

**SPEC-005-DOM-001.** The Foreign Key Governance domain consists of the following conceptual objects, each with a single responsibility:

| Concept | Responsibility |
|---|---|
| Relationship | A persistent association between a parent entity and a child entity, declared by a foreign-key policy. |
| Foreign Key | The concrete policy that binds a child-side identifier to a parent-side identifier and declares the delete/update behavior. |
| Parent Entity | The referenced entity whose identifier is the target of the foreign key. |
| Child Entity | The referencing entity whose identifier attribute depends on the parent. |
| Aggregate | A consistency boundary that groups a root entity and its owned child entities. |
| Aggregate Root | The entity that defines the aggregate boundary and is responsible for the lifecycle of its owned children. |
| Relationship Metadata | The catalog record that classifies, documents, and traces the relationship. |
| Foreign Key Catalog | The authoritative registry of all relationships and their metadata. |
| Delete Policy | The action taken on child rows when the parent row is deleted. |
| Update Policy | The action taken on child rows when the parent identifier is updated. |
| Cardinality | The multiplicity constraint (one-to-one, one-to-many, many-to-many) of the relationship. |
| Optionality | Whether the child-side participation is mandatory or optional. |
| Cross-Boundary Relationship | A relationship that crosses aggregate, module, or tenant boundaries. |
| Circular Dependency | A cycle in the relationship graph that creates undeterminable deletion ordering. |
| Validation Result | The outcome of a relationship classification and consistency check. |

**SPEC-005-DOM-002.** A `Relationship` shall be classified before it is realized in any persistence layer.

**SPEC-005-DOM-003.** A `Foreign Key` shall enforce only the referential-integrity policy recorded in the `Foreign Key Catalog`.

**SPEC-005-DOM-004.** An `Aggregate Root` shall own the lifecycle of its owned children; a child shall belong to exactly one aggregate root unless explicitly reviewed as a cross-aggregate relationship.

---

## 16.9 Components

**SPEC-005-COM-001.** The Foreign Key Governance Architecture comprises the following logical components:

| Component | Role | Placement |
|---|---|---|
| Foreign Key Catalog | Authoritative registry of every relationship, its classification, ownership, policies, and review status. | Enterprise architecture / governance layer |
| Relationship Metadata Registry | Holds the structured metadata for each relationship: name, parent, child, cardinality, optionality, policies, rationale, and reviewers. | Enterprise architecture / governance layer |
| Policy Classifier | Assigns delete and update policy classifications based on ownership, cardinality, and risk review. | Foreign Key Governance authority |
| Boundary Review Function | Evaluates cross-aggregate, cross-module, and cross-tenant relationships for circular dependencies and cascade risk. | Enterprise architecture / governance layer |
| Referential-Integrity Validator | Verifies that every realized relationship matches the approved catalog entry and that the relationship graph is consistent and acyclic. | Architecture / verification function |
| Policy Drift Detector | Detects unauthorized or un-cataloged relationships and policy changes in the persistence layer. | Observability / governance layer |
| Change Approval Gateway | Records approval decisions for new, modified, or retired relationships. | Governance / change-control layer |
| Reporting View | Produces relationship maps, dependency matrices, and risk reports for architects and reviewers. | Governance / documentation layer |

**SPEC-005-COM-002.** The `Foreign Key Catalog` shall be the single source of truth for every persistent relationship in the platform.

**SPEC-005-COM-003.** The `Boundary Review Function` shall reject any cross-boundary relationship that introduces a circular dependency or an unreviewed cascade risk.

**SPEC-005-COM-004.** The `Policy Drift Detector` shall emit an alert when a realized relationship is not present in the catalog or when its declared policy differs from the catalog.

---

## 16.10 Interfaces

**SPEC-005-INT-001.** The Foreign Key Governance Architecture exposes the following abstract interfaces:

### 16.10.1 Relationship Declaration Interface

| Attribute | Type | Description |
|---|---|---|
| `relationship_id` | Identifier | Unique catalog identifier for the relationship. |
| `parent_type` | Domain name | The aggregate root or parent entity. |
| `child_type` | Domain name | The referencing entity. |
| `parent_attribute` | Attribute name | The referenced identifier attribute on the parent. |
| `child_attribute` | Attribute name | The referencing attribute on the child. |
| `ownership_model` | Ownership model | `PARENT_CHILD` or `AGGREGATE`. |
| `cardinality` | Cardinality | `ONE_TO_ONE`, `ONE_TO_MANY`, or `MANY_TO_MANY`. |
| `optionality` | Optionality | `MANDATORY` or `OPTIONAL`. |
| `delete_policy` | Delete policy | `CASCADE`, `RESTRICT`, `SET_NULL`, or `NO_ACTION`. |
| `update_policy` | Update policy | `CASCADE`, `RESTRICT`, `SET_NULL`, or `NO_ACTION`. |
| `crosses_boundary` | Boolean | True if the relationship crosses aggregate, module, or tenant boundaries. |
| `rationale` | String | Business and architectural justification for the policy. |

### 16.10.2 Policy Query Interface

| Attribute | Type | Description |
|---|---|---|
| `relationship_id` | Identifier | Target relationship identifier. |
| `parent_state` | State | The state change occurring on the parent (delete, update, or restore). |
| `child_policy` | Policy | The resulting child action as declared in the catalog. |
| `owner` | Responsibility | The architecture that owns the action (Foreign Key Governance, Delete Framework, Transaction Coordinator, etc.). |

### 16.10.3 Validation Report Interface

| Attribute | Type | Description |
|---|---|---|
| `validation_id` | Identifier | Unique identifier for the validation run. |
| `relationship_id` | Identifier | Relationship validated. |
| `status` | Status | `PASS`, `FAIL`, or `REVIEW_REQUIRED`. |
| `findings` | List | Human-readable and structured findings. |
| `recommended_action` | String | Corrective or approval action. |

**SPEC-005-INT-002.** The `Relationship Declaration Interface` shall be consumed by the `Foreign Key Catalog` to create or update a relationship entry.

**SPEC-005-INT-003.** The `Policy Query Interface` shall be consumed by the Delete Framework, Transaction Architecture, and Trigger Governance to determine the approved referential-integrity behavior for a given parent-state change.

**SPEC-005-INT-004.** The `Validation Report Interface` shall be consumed by the `Referential-Integrity Validator`, `Boundary Review Function`, and governance dashboards to report consistency and risk findings.

---

## 16.11 Contracts

**SPEC-005-CON-001.** The Foreign Key Governance contracts are technology-neutral and implementation-neutral. Every implementation shall honor the following contracts:

### 16.11.1 Referential Integrity Contract

**SPEC-005-CON-002.** Every relationship shall be declared in the `Foreign Key Catalog` before it is realized.

**SPEC-005-CON-003.** A child entity shall not reference a parent identifier that does not exist, unless the relationship is classified as `OPTIONAL` and the child attribute is null.

**SPEC-005-CON-004.** A parent entity shall not be deleted or updated in a way that violates the declared `delete_policy` or `update_policy` of any dependent child entity.

### 16.11.2 Delete Policy Contract

**SPEC-005-CON-005.** The delete policy of a relationship shall be one of `CASCADE`, `RESTRICT`, `SET_NULL`, or `NO_ACTION`.

**SPEC-005-CON-006.** A `CASCADE` delete policy is permitted only when the child entity is owned by the parent aggregate and its lifecycle is wholly determined by the aggregate root.

**SPEC-005-CON-007.** A `RESTRICT` delete policy is required when the child entity is not owned by the parent and the parent cannot be deleted while children exist.

**SPEC-005-CON-008.** A `SET_NULL` delete policy is permitted only for `OPTIONAL` relationships where the child can remain meaningful without a parent reference.

**SPEC-005-CON-009.** A `NO_ACTION` delete policy is permitted only when the relationship is managed by an explicit application-level or framework-level delete orchestration that guarantees equivalent integrity.

### 16.11.3 Update Policy Contract

**SPEC-005-CON-010.** The update policy of a relationship shall be one of `CASCADE`, `RESTRICT`, `SET_NULL`, or `NO_ACTION`.

**SPEC-005-CON-011.** `CASCADE` update is permitted only when the parent identifier is a synthetic, system-managed surrogate that is not exposed as a business identifier.

**SPEC-005-CON-012.** `RESTRICT` update is required when the parent identifier is a business identifier or when child references must not be silently remapped.

**SPEC-005-CON-013.** Identifier attributes that participate in cross-module or cross-tenant references shall be immutable once created; `RESTRICT` or `NO_ACTION` update policies shall apply to such relationships.

### 16.11.4 Cross-Boundary Contract

**SPEC-005-CON-014.** A cross-aggregate relationship shall not use a `CASCADE` delete policy unless the child aggregate is explicitly subsumed into the parent aggregate through a documented ownership transfer.

**SPEC-005-CON-015.** A cross-module relationship shall use `RESTRICT` or `NO_ACTION` delete policy by default and shall require an explicit risk review for any other policy.

**SPEC-005-CON-016.** A cross-tenant relationship shall not exist; tenant-scoped data shall not reference tenant-scoped data of another tenant.

**SPEC-005-CON-017.** Every cross-boundary relationship shall include a documented referential boundary and a documented remediation path if the parent is deleted.

### 16.11.5 Validation Contract

**SPEC-005-CON-018.** The `Referential-Integrity Validator` shall verify that the realized relationship graph matches the `Foreign Key Catalog`.

**SPEC-005-CON-019.** The `Boundary Review Function` shall reject any relationship that creates a circular dependency or an undeclared cascade path.

**SPEC-005-CON-020.** A relationship that fails validation shall not be promoted beyond the `PROPOSED` catalog state until the failure is remediated and re-approved.

---

## 16.12 State Machine

**SPEC-005-STM-001.** Every relationship shall move through the governed lifecycle defined in this section.

### 16.12.1 Happy Path

```
PROPOSED
  ↓ declaration complete and rationale provided
UNDER_REVIEW
  ↓ classification, ownership, and policy approved
APPROVED
  ↓ realized in persistence layer
ACTIVE
  ↓ superseded by a new approved relationship
DEPRECATED
  ↓ all implementations removed and history archived
RETIRED
```

### 16.12.2 Failure and Rejection Path

```
PROPOSED
  ↓ review identifies risk or inconsistency
REJECTED
  ↓ remediation submitted
PROPOSED
```

### 16.12.3 Transition Rules

| From | To | Guard | Owner | Action |
|---|---|---|---|---|
| PROPOSED | UNDER_REVIEW | Declaration is complete and parent/child attributes are known. | Domain Model / Data Architecture | Submit for review. |
| UNDER_REVIEW | APPROVED | Classification, policies, boundaries, and ownership are accepted. | Boundary Review Function | Approve and record. |
| UNDER_REVIEW | REJECTED | Risk, circular dependency, or policy conflict is identified. | Boundary Review Function | Reject with findings. |
| REJECTED | PROPOSED | Remediation addresses findings. | Domain Model / Data Architecture | Resubmit. |
| APPROVED | ACTIVE | Implementation matches catalog entry and validation passes. | Implementation Team | Promote to active. |
| ACTIVE | DEPRECATED | A superseding relationship is approved or the relationship is no longer required. | Foreign Key Governance | Mark deprecated. |
| DEPRECATED | RETIRED | No realized implementation remains and all references are removed. | Implementation Team | Retire. |

**SPEC-005-STM-002.** States are terminal when they are `RETIRED` or `REJECTED` and not resubmitted.

**SPEC-005-STM-003.** Every transition shall be logged with previous state, new state, actor, timestamp, and reason.

---

## 16.13 Workflow

**SPEC-005-WFL-001.** The canonical relationship registration workflow consists of the following high-level stages:

1. **Declare** — The domain architect submits a `Relationship Declaration` with parent, child, ownership, cardinality, optionality, and proposed policies.
2. **Classify** — The Policy Classifier assigns the delete and update policy classifications based on ownership and risk.
3. **Review Boundaries** — The Boundary Review Function evaluates cross-aggregate, cross-module, and circular-dependency risks.
4. **Approve** — The governance authority approves or rejects the relationship.
5. **Realize** — The implementation team applies the approved policy using the persistence-layer mechanism selected by the Implementation Plan.
6. **Validate** — The Referential-Integrity Validator confirms that the realized relationship matches the catalog and that the graph remains consistent.
7. **Monitor** — The Policy Drift Detector watches for unauthorized changes.
8. **Retire** — When a relationship is no longer required, it is deprecated and retired.

**SPEC-005-WFL-002.** If any stage from Classify through Validate fails, the workflow shall transition to `REJECTED` and the recovery model shall apply.

**SPEC-005-WFL-003.** A relationship shall not be realized before it reaches the `APPROVED` catalog state.

**SPEC-005-WFL-004.** The workflow shall support both new relationships and modifications to existing relationships through the same lifecycle.

---

## 16.14 Sequence

**SPEC-005-SEQ-001.** The critical path for establishing a new relationship shall follow this sequence:

```
Domain Model / Data Architecture
  → Foreign Key Catalog: submit Relationship Declaration
    → Policy Classifier: assign delete and update policy classifications
      → Boundary Review Function: evaluate cross-aggregate and cross-module risks
        → Change Approval Gateway: approve or reject the relationship
          → Implementation Team: realize the approved policy in the persistence layer
            → Referential-Integrity Validator: validate realized relationship against catalog
              → Policy Drift Detector: register active policy for ongoing monitoring
                → Foreign Key Catalog: transition relationship state to ACTIVE
```

**SPEC-005-SEQ-002.** If classification or boundary review fails, the sequence shall return the relationship to `REJECTED` with structured findings before any realization occurs.

**SPEC-005-SEQ-003.** The Referential-Integrity Validator shall execute after realization but before the relationship is promoted to `ACTIVE`.

**SPEC-005-SEQ-004.** A delete-policy impact sequence shall be available to the Delete Framework on demand: given a parent-state change, the Foreign Key Catalog shall return the child policies and their owning architectures.

---

## 16.15 Data Model

**SPEC-005-DAT-001.** The Foreign Key Governance data model is logical and conceptual. It does not prescribe physical table names, column types, or storage engines.

### 16.15.1 Core Entities

| Entity | Attributes | Ownership |
|---|---|---|
| Relationship | relationship_id, parent_type, child_type, parent_attribute, child_attribute, cardinality, optionality, delete_policy, update_policy, ownership_model, crosses_boundary, rationale, review_notes | Foreign Key Catalog |
| Catalog Entry | catalog_id, relationship_id, state, version, approved_by, approved_at, deprecated_at, retired_at | Foreign Key Catalog |
| Validation Result | validation_id, catalog_id, status, findings, executed_at, executed_by | Referential-Integrity Validator |
| Dependency Edge | source_entity, target_entity, relationship_id, direction, boundary_type | Boundary Review Function |
| Policy Drift Record | drift_id, catalog_id, observed_state, catalog_state, detected_at | Policy Drift Detector |

### 16.15.2 Data Ownership

**SPEC-005-DAT-002.** The Foreign Key Catalog owns `Relationship` and `Catalog Entry` records.

**SPEC-005-DAT-003.** The Referential-Integrity Validator owns `Validation Result` records.

**SPEC-005-DAT-004.** The Boundary Review Function owns `Dependency Edge` records used for circular-dependency and cross-boundary analysis.

**SPEC-005-DAT-005.** The Policy Drift Detector owns `Policy Drift Record` records.

### 16.15.3 Retention

**SPEC-005-DAT-006.** Catalog entries for retired relationships shall be retained for the governance retention period defined by the compliance policy, independent of the operational data retention period.

**SPEC-005-DAT-007.** Validation results and drift records shall be retained for the period required by audit and compliance review.

---

## 16.16 Failure Model

**SPEC-005-FAM-001.** The following failure modes are in scope for Foreign Key Governance:

| ID | Failure Mode | Likelihood | Impact | Detection |
|---|---|---|---|---|
| SPEC-005-FAM-001 | A relationship is realized without a catalog entry. | Medium | High | Policy Drift Detector finds an un-cataloged relationship. |
| SPEC-005-FAM-002 | A realized relationship policy differs from the approved catalog entry. | Medium | High | Drift detection or validation run compares catalog to realization. |
| SPEC-005-FAM-003 | A circular dependency is introduced into the relationship graph. | Low | Critical | Boundary Review Function cycle detection fails. |
| SPEC-005-FAM-004 | A cross-aggregate or cross-module relationship uses an unreviewed `CASCADE` policy. | Medium | Critical | Classification review rejects the relationship. |
| SPEC-005-FAM-005 | A parent deletion is blocked by `RESTRICT` but the Delete Framework is not informed. | Low | High | Transaction abort or validation failure returns a structured error. |
| SPEC-005-FAM-006 | An audit record is coupled to an operational entity through a mandatory foreign key. | Low | Critical | Audit independence verification fails. |
| SPEC-005-FAM-007 | An identifier update violates an update policy. | Low | High | Update policy validation fails. |
| SPEC-005-FAM-008 | A cross-tenant reference is introduced. | Low | Critical | Boundary review and tenant-isolation validation fail. |

**SPEC-005-FAM-009.** Every failure mode shall have a corresponding recovery action defined in the Recovery Model.

**SPEC-005-FAM-010.** Integrity failures shall not return generic HTTP 500 responses without a structured error code, correlation ID, and recovery guidance.

---

## 16.17 Recovery Model

**SPEC-005-RCM-001.** The Foreign Key Governance recovery model shall handle each failure mode:

| Failure Mode | Recovery Action | Owner |
|---|---|---|
| Un-cataloged relationship | Quarantine or remove realization; add catalog entry through the workflow. | Foreign Key Governance / Implementation Team |
| Policy drift | Revert realization to catalog policy or approve a catalog change. | Foreign Key Governance |
| Circular dependency | Reject relationship; redesign dependency graph; retire offending relationship. | Boundary Review Function |
| Unreviewed cascade | Change to `RESTRICT` or `NO_ACTION`; route deletion through Delete Framework. | Foreign Key Governance |
| Delete blocked by `RESTRICT` | Return structured error; Delete Framework performs explicit child handling. | Delete Framework / Transaction Coordinator |
| Audit coupled to operational entity | Redesign audit relationship for independence; no mandatory foreign key to operational entity. | Audit Architecture |
| Update policy violation | Abort transaction; return structured error with remediation guidance. | Transaction Coordinator |
| Cross-tenant reference | Reject design; enforce tenant isolation at the persistence layer. | Security / Foreign Key Governance |

**SPEC-005-RCM-002.** The recovery model shall prefer catalog correction over persistence-layer workarounds.

**SPEC-005-RCM-003.** When a realized relationship must change, the change shall follow the relationship lifecycle and be validated before promotion to `ACTIVE`.

**SPEC-005-RCM-004.** Manual remediation of referential-integrity failures shall be supported through documented remediation paths, not through ad-hoc policy changes.

---

## 16.18 Security

**SPEC-005-SEC-001.** Every catalog change shall be authenticated and authorized before it is recorded.

**SPEC-005-SEC-002.** Role-based access control shall enforce that only the Foreign Key Governance authority and designated architects may approve, modify, or retire a relationship.

**SPEC-005-SEC-003.** Cross-tenant relationships shall be prohibited by the Foreign Key Catalog and by the tenant-isolation architecture.

**SPEC-005-SEC-004.** Audit records of catalog changes shall contain the actor, authorization context, timestamp, and rationale to support forensic review.

**SPEC-005-SEC-005.** The `Foreign Key Catalog` shall be readable but not freely modifiable by implementation tooling without an approved change record.

**SPEC-005-SEC-006.** Sensitive relationship metadata (ownership rationale, risk findings) shall be protected according to the enterprise data-classification policy.

---

## 16.19 Observability

**SPEC-005-OBS-001.** Every relationship lifecycle event and integrity check shall emit structured observability data:

| Type | Requirement |
|---|---|
| Logs | Structured log for catalog transitions, validation runs, and drift detections, containing `relationship_id`, `catalog_id`, actor, previous state, new state, and findings. |
| Metrics | Counter for relationships by state, policy drift findings, circular-dependency rejections, cross-boundary review counts, and validation pass/fail rates. |
| Traces | Trace following a relationship change from declaration through approval, realization, validation, and activation. |
| Alerts | Alert on un-cataloged relationships, policy drift, failed boundary reviews, and validation failure spikes. |
| Dashboards | Dashboard showing catalog state distribution, pending reviews, drift trends, and cross-boundary risk exposure. |

**SPEC-005-OBS-002.** The observability layer shall enable operators to reconstruct the full lifecycle of any relationship from `relationship_id` or `catalog_id` without querying the production persistence layer directly.

**SPEC-005-OBS-003.** All failure findings shall include structured error codes and recovery guidance suitable for support staff and compliance reviewers.

---

## 16.20 Risks

**SPEC-005-RSK-001.** The following risks are introduced or mitigated by the Foreign Key Governance Architecture:

| ID | Risk | Likelihood | Impact | Owner | Mitigation |
|---|---|---|---|---|---|
| SPEC-005-RSK-001 | A new relationship is introduced without catalog registration, creating a hidden cascade path. | Medium | High | Foreign Key Governance | Mandatory review gate before any persistence-layer change; policy drift detection. |
| SPEC-005-RSK-002 | An existing relationship is modified locally without catalog update, causing policy drift. | Medium | High | Implementation Team | Automated drift detection and validation runs in build/test pipelines. |
| SPEC-005-RSK-003 | A circular dependency is introduced, making deletes non-deterministic or unresolvable. | Low | Critical | Boundary Review Function | Cycle detection during review and validation. |
| SPEC-005-RSK-004 | Audit records are coupled to operational entities, losing audit history on delete. | Medium | Critical | Audit Architecture | Mandatory audit-independence review for every relationship involving audit entities. |
| SPEC-005-RSK-005 | Cross-tenant references leak data between tenants. | Low | Critical | Security / Foreign Key Governance | Tenant-isolation validation and prohibition of cross-tenant relationships. |
| SPEC-005-RSK-006 | `CASCADE` delete policy is used to encode business workflow, hiding logic in the persistence layer. | Medium | High | Trigger Governance / Foreign Key Governance | Policy classifier rejects `CASCADE` outside aggregate ownership; SPEC-004 classification. |

---

## 16.21 Constraints

**SPEC-005-CST-001.** The Foreign Key Governance Architecture shall operate within the following constraints:

| ID | Constraint | Source |
|---|---|---|
| SPEC-005-CST-001 | The architecture shall be technology-neutral and shall not assume any specific persistence layer, data store, or programming language. | Architecture Specification Program Section 18. |
| SPEC-005-CST-002 | The architecture shall depend on SPEC-001, SPEC-002, and SPEC-003 being baselined before it may be approved, per the Architecture Specification Index. | Architecture Specification Index Section 6.2. |
| SPEC-005-CST-003 | The architecture shall not place business workflow logic inside foreign-key policies. | Master Program Guiding Principle 3. |
| SPEC-005-CST-004 | Audit records shall not be coupled to operational entities through mandatory foreign keys. | Master Program Guiding Principle 2. |
| SPEC-005-CST-005 | Cross-tenant references shall be prohibited. | Tenant-isolation architecture. |
| SPEC-005-CST-006 | Every in-scope relationship shall be cataloged and classified before realization. | Master Program Architecture Goal 5. |
| SPEC-005-CST-007 | Failure responses shall be structured and shall include correlation IDs and recovery guidance. | Master Program Success Criteria. |

---

## 16.22 Non-goals

**SPEC-005-NGO-001.** This specification explicitly does not cover:

1. Implementation code, file names, package structures, or deployment commands.
2. Concrete persistence-layer syntax, data-definition statements, or trigger bodies.
3. Specific technology choices such as a particular relational database, object store, or graph database.
4. User-interface copy, data-entry forms, or visual design for the catalog.
5. Application-level delete orchestration logic beyond the policy contract.
6. Operational runbooks for manual remediation, which belong in Operational Specifications.
7. Transition procedures for moving from legacy relationships to the governed model, which belong in a Transition Specification or Implementation Plan.
8. Business-domain workflow rules, which belong in application architecture and business logic.

---

## 16.23 Verification Requirements

**SPEC-005-VRF-001.** The Foreign Key Governance implementation shall be verified against the following requirements:

| ID | Verification Requirement | Method |
|---|---|---|
| SPEC-005-VRF-001 | Every realized relationship has an approved catalog entry. | Catalog-to-persistence comparison and drift detection. |
| SPEC-005-VRF-002 | Relationship classifications and policies match the catalog. | Automated validation run against the relationship metadata registry. |
| SPEC-005-VRF-003 | No circular dependencies exist in the approved relationship graph. | Cycle-detection analysis over the dependency-edge model. |
| SPEC-005-VRF-004 | No cross-tenant relationships exist. | Tenant-scope validation across all relationships. |
| SPEC-005-VRF-005 | Audit records are not coupled to operational entities through mandatory parent-child relationships. | Audit-independence validation. |
| SPEC-005-VRF-006 | `CASCADE` delete policies are limited to aggregate-owned children. | Policy classification review. |
| SPEC-005-VRF-007 | Update policies respect identifier-immutability rules for cross-module references. | Update-policy validation. |
| SPEC-005-VRF-008 | Every failure mode in Section 16.16 has a recovery test. | Failure-recovery test matrix. |
| SPEC-005-VRF-009 | Policy drift detection alerts when a realized policy differs from the catalog. | Drift-detection integration test. |
| SPEC-005-VRF-010 | Catalog change observability emits logs, metrics, and traces with the relationship identifier. | Observability integration tests. |

---

## 16.24 Acceptance Criteria

**SPEC-005-ACC-001.** The Foreign Key Governance specification and its implementation are accepted when:

1. All mandatory sections are present and reviewed.
2. All requirements carry unique identifiers and are traceable to verification requirements and acceptance criteria.
3. The implementation passes all verification requirements in Section 16.23.
4. Every in-scope relationship is represented in the Foreign Key Catalog.
5. No un-cataloged relationship exists in the persistence layer.
6. No cross-tenant relationship exists.
7. Audit records demonstrate independence from operational entity lifecycles.
8. Circular-dependency and cross-boundary review gates are operational.
9. Policy drift detection and validation are operational.
10. The Production Owner approves the specification and the implementation.

---

## 16.25 Future Evolution

**SPEC-005-FEV-001.** The Foreign Key Governance Architecture is designed to evolve without redesign. The following extension points are preserved:

| Extension | Description |
|---|---|
| New relationships | New relationships shall be registered through the canonical workflow and classified before realization. |
| New policy classifications | New delete or update policy classifications shall be added through the policy registry and approved by governance. |
| New boundary types | New boundary classifications (for example, region, legal jurisdiction) shall be added to the Boundary Review Function. |
| Multi-store support | The catalog may be extended to govern relationships across heterogeneous persistence layers without changing the policy model. |
| Automated discovery | The Policy Drift Detector may integrate with schema-discovery tools while retaining the catalog as the source of truth. |
| Historical archives | Catalog entries may be cold-archived after retirement without altering the governance semantics. |

**SPEC-005-FEV-002.** Any change that adds, removes, or reclassifies a delete or update policy shall require an Architecture Decision Record per the Master Program Section 29.

---

## 16.26 Appendix

### A. Relationship Classification Matrix

| Classification | Ownership Model | Delete Policy Default | Update Policy Default | Boundary Rules |
|---|---|---|---|---|
| Aggregate Internal | Aggregate root owns child | `CASCADE` or `SET_NULL` based on optionality | `CASCADE` if surrogate identifier, otherwise `RESTRICT` | No review required if inside same aggregate. |
| Parent–Child | Parent owns child lifecycle | `CASCADE` or `SET_NULL` based on optionality | `RESTRICT` for business identifiers | Review if child belongs to another aggregate. |
| Reference | Child references but does not own parent | `RESTRICT` or `NO_ACTION` | `RESTRICT` or `NO_ACTION` | Cross-module review required. |
| Cross-Module Reference | Child references a different module | `NO_ACTION` | `RESTRICT` | Mandatory boundary review. |
| Audit Reference | Audit record references operational event | `NO_ACTION` | `NO_ACTION` | No mandatory foreign key to operational entity. |

### B. Delete Policy Matrix

| Policy | Meaning | Permitted When | Forbidden When |
|---|---|---|---|
| CASCADE | Deleting the parent also deletes owned children. | Child is owned by the same aggregate and has no independent lifecycle. | Cross-aggregate, cross-module, cross-tenant, or audit-to-operational relationships. |
| RESTRICT | Parent cannot be deleted while children exist. | Child is not owned by the parent and must remain valid. | The Delete Framework owns an explicit child-removal path for the same relationship. |
| SET_NULL | Deleting the parent clears the child reference. | Relationship is optional and the child remains meaningful without a parent. | Relationship is mandatory or the child loses meaning when the parent is gone. |
| NO_ACTION | Parent deletion is allowed; referential integrity is enforced by application-level orchestration. | An explicit Delete Framework or application contract guarantees equivalent behavior. | No orchestration exists to manage orphaned or dependent children. |

### C. Update Policy Matrix

| Policy | Meaning | Permitted When | Forbidden When |
|---|---|---|---|
| CASCADE | Updating the parent identifier propagates to children. | Parent identifier is a system-managed surrogate never exposed as a business key. | Parent identifier is a business key, public identifier, or cross-module reference. |
| RESTRICT | Parent identifier cannot be updated while referenced by children. | Identifier stability is a business or compliance requirement. | The system design expects parent identifiers to change routinely. |
| SET_NULL | Updating the parent identifier clears the child reference. | Relationship is optional and child can remain valid without a parent. | Relationship is mandatory. |
| NO_ACTION | Parent identifier updates are managed by explicit application logic. | Identifier updates are handled by the Delete Framework or business process. | No explicit process exists to maintain child references. |

### D. Cardinality and Optionality Rules

| Cardinality | Optionality | Delete Policy Guidance | Update Policy Guidance |
|---|---|---|---|
| ONE_TO_ONE | MANDATORY | `CASCADE` if owned; otherwise `RESTRICT`. | `CASCADE` if surrogate; otherwise `RESTRICT`. |
| ONE_TO_ONE | OPTIONAL | `SET_NULL` or `CASCADE` if owned. | `SET_NULL` or `RESTRICT`. |
| ONE_TO_MANY | MANDATORY | `CASCADE` or `RESTRICT` based on ownership. | `CASCADE` if surrogate; otherwise `RESTRICT`. |
| ONE_TO_MANY | OPTIONAL | `CASCADE` for owned children; `SET_NULL` for references. | `SET_NULL` or `RESTRICT`. |
| MANY_TO_MANY | N/A | Junction relationships use `CASCADE` for junction rows and `RESTRICT` for endpoint deletes. | Junction identifiers are immutable; `RESTRICT` for endpoints. |

### E. Cross-Boundary Relationship Decision Checklist

**SPEC-005-APX-001.** A cross-boundary relationship may be approved only if the following conditions are met:

1. The parent and child modules or aggregates are documented.
2. The delete policy is `RESTRICT`, `NO_ACTION`, or an explicitly reviewed `CASCADE` with ownership transfer.
3. The update policy is `RESTRICT` or `NO_ACTION`.
4. A circular-dependency analysis shows the relationship does not close a cycle.
5. A remediation path is documented for parent deletion or identifier change.
6. The relationship does not cross tenant boundaries.
7. The audit independence requirement is satisfied if audit entities are involved.

### F. Glossary

| Term | Definition |
|---|---|
| Relationship | A persistent association between a parent entity and a child entity. |
| Foreign Key | The referential-integrity policy binding a child attribute to a parent identifier. |
| Aggregate | A consistency boundary containing an aggregate root and its owned children. |
| Aggregate Root | The entity that owns the lifecycle of all entities inside its aggregate. |
| Delete Policy | The action enforced on child rows when the parent row is deleted. |
| Update Policy | The action enforced on child rows when the parent identifier is updated. |
| Cross-Boundary Relationship | A relationship that crosses aggregate, module, or tenant boundaries. |
| Policy Drift | A realized referential-integrity policy that differs from the approved catalog entry. |
| Catalog Entry | The approved, versioned record of a relationship in the Foreign Key Catalog. |

### G. Traceability Summary

| This Specification Section | Traces To |
|---|---|
| 16.2 Purpose | Master Program Sections 1, 2, 3, 7, 8 |
| 16.3 Scope | Master Program Section 9 |
| 16.5 Architecture Context | Master Program Sections 4, 5, 6, 22 |
| 16.6 Responsibilities | Master Program Section 10.5 |
| 16.7 Architecture Principles Mapping | Master Program Section 23 |
| 16.8 Domain Model | Master Program Section 24 |
| 16.12 State Machine | Master Program Section 25 |
| 16.13 Workflow | Master Program Section 10.5 |
| 16.14 Sequence | Master Program Sections 10.1, 10.5 |
| 16.16 Failure Model | Master Program Section 28 |
| 16.17 Recovery Model | Master Program Sections 10.7, 28 |
| 16.19 Observability | Master Program Section 10.8 |
| 16.23 Verification Requirements | Master Program Section 20 |
| 16.24 Acceptance Criteria | Master Program Sections 13, 14 |

---

## Evidence

### E.1 Foundation Documents Consulted

The following foundation documents were read and followed:

1. `.codebase-memory/CODEBASE_MEMORY_BASELINE.md` — Project baseline, stack, validation status, knowledge priority.
2. `.codebase-memory/SEMANTIC_MEMORY.md` — Architecture overview, business modules, tenant lifecycle, relationship and deletion patterns.
3. `.codebase-memory/VALIDATION_REPORT.md` — Confidence scores, known limitations, corrections.

### E.2 Governance Documents Consulted

The following governance documents were read in the required order:

1. `Deletion_Audit_Architecture_Remediation_Program.md` (Master Program v1.0) — Vision, principles, goals, workstreams, scope, state machine, domain model, classification, dependency matrix, risks, success criteria.
2. `01_Governance/Architecture_Specification_Program.md` (Specification Program v1.1) — Mandatory template (Sections 16.1–16.26), metadata, versioning, naming, directory organization, traceability, dependency, quality gates.
3. `01_Governance/ARCHITECTURE_SPECIFICATION_INDEX.md` (Index v1.1) — SPEC-005 planned registration, classification, dependencies, portfolio position, authoring order.
4. `01_Governance/SPEC_BASELINE_CERTIFICATION.md` — Golden Specification inheritance rules, allowed and forbidden variations, repository consistency rules.

### E.3 Cross-Validation Results

| Check | Result |
|---|---|
| SPEC-005 follows the mandatory 26-section template | ✓ All sections 16.1–16.26 are present. |
| Metadata matches the Specification Program | ✓ Identifier, classification, status, version, ownership, and references are complete. |
| Related specifications are referenced | ✓ SPEC-001, SPEC-002, SPEC-003, SPEC-004 referenced with correct dependency direction. |
| Mandatory architectural principles are stated | ✓ Section 16.7.1 contains the full set of mandated principles. |
| Technology neutrality preserved | ✓ No persistence-layer syntax, implementation language, or deployment artifact appears. |
| Implementation independence preserved | ✓ No persistence-layer syntax, schema, or example code appear. |
| Cross-spec consistency with SPEC-001 | ✓ Delete policy contracts are consumed by Delete Framework; no delete orchestration duplication. |
| Cross-spec consistency with SPEC-002 | ✓ Audit independence mandated; audit-to-operational foreign keys prohibited. |
| Cross-spec consistency with SPEC-003 | ✓ Transaction boundary ownership remains with Transaction Coordinator; no transaction duplication. |
| Cross-spec consistency with SPEC-004 | ✓ Trigger behavior remains with Trigger Governance; no trigger logic duplication. |
| Out-of-scope items excluded | ✓ No modification of SPEC-001, SPEC-002, SPEC-003, SPEC-004, governance documents, source code, database, transition, remote calls, or edge functions. |

### E.4 Extracted Governance Summary

The following governance elements were extracted and applied:

- The Master Program establishes the vision, principles, goals, workstreams, scope, state machine, domain model, classification framework, dependency matrix, risks, and success criteria.
- The Architecture Specification Program (v1.1) defines the mandatory 26-section template, metadata model, versioning rules, normative language, traceability, dependency framework, and quality gates.
- The Architecture Specification Index (v1.1) registers SPEC-005 as a planned Core specification with dependencies on SPEC-001 and SPEC-003 (informative) and a defined portfolio position.
- The SPEC_BASELINE_CERTIFICATION (v1.0) certifies SPEC-001 as the Golden Specification and defines the inheritance, allowed variations, and repository consistency rules used by this specification.
- The Golden Specification (SPEC-001) provides the canonical document structure, metadata, identifier convention, writing style, appendix structure, evidence model, and quality level.

### E.5 Portfolio Validation

- SPEC-005 is registered in `ARCHITECTURE_SPECIFICATION_INDEX.md` as the Foreign Key Governance Architecture Specification.
- The Index entry records Core classification, planned status, and dependencies on SPEC-001 and SPEC-003 (informative).
- The specification ID, short identifier, name, and version match the Index entry.
- No circular dependencies are introduced.

### E.6 Dependency Validation

The following specifications were read as authoring and dependency examples:

1. `02_Specifications/SPEC-001_DELETE_FRAMEWORK_ARCHITECTURE_SPECIFICATION.md` (Golden Architecture Specification v1.1) — Canonical document structure, metadata, identifier convention, writing style, architecture depth, traceability, appendix structure, evidence model, and quality level.
2. `02_Specifications/SPEC-002_AUDIT_ARCHITECTURE_SPECIFICATION.md` (v1.0) — Audit independence and interaction model.
3. `02_Specifications/SPEC-003_TRANSACTION_ARCHITECTURE_SPECIFICATION.md` (v1.0) — Transaction boundary ownership and interaction model.
4. `02_Specifications/SPEC-004_TRIGGER_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` (v1.0) — Trigger classification and interaction model.

Cross-Validation confirms:

- Delete policy contracts are consumed by the Delete Framework; no delete orchestration duplication.
- Audit independence is mandated; audit-to-operational foreign keys are prohibited.
- Transaction boundary ownership remains with the Transaction Coordinator; no transaction duplication.
- Trigger behavior remains with Trigger Governance; no trigger logic duplication.

### E.7 Template Compliance

- The mandatory 26-section template (Sections 16.1–16.26) is present and ordered.
- No persistence-product names, programming-language constructs, framework names, directory paths, interface styles, transition references, remote-call signatures, or rollout guidance appear.
- All examples are conceptual (policy names, matrices, interfaces) and use architecture-level attribute names rather than physical column names or syntax.

### E.8 Traceability Summary

Traceability is maintained to:

- Master Program: `Deletion & Audit Architecture Remediation Program v1.0`
- Golden Specification: `SPEC-001 Delete Framework Architecture Specification v1.1`
- Related Specifications: `SPEC-002 Audit Architecture v1.0`, `SPEC-003 Transaction Architecture v1.0`, `SPEC-004 Trigger Governance v1.0`
- Governance: `Architecture Specification Program v1.1`, `ARCHITECTURE_SPECIFICATION_INDEX.md v1.1`, `SPEC_BASELINE_CERTIFICATION.md v1.0`

### E.9 Risk Assessment

The following observations are recorded for future Repository Consistency Review:

1. The VietSalePro relationship model spans tenant-scoped operational data, audit data, billing data, and platform administration data; the Foreign Key Catalog must be scoped to all of these.
2. The Semantic Memory documents 88 production tables and multiple cross-table relationships; the catalog will need to be bootstrapped from the existing schema as part of a future Transition Specification.
3. The `delete-tenant` incident highlighted an audit-to-tenant relationship that must be reclassified under this architecture.
4. The Validation Report notes that some edge functions and remote calls may interact with relationships; the catalog should eventually be cross-referenced with Trigger Governance and the remote-call contract registry.
5. No implementation actions were taken; this specification remains purely architectural.

### E.10 Confirmation

- **No implementation performed.**
- **No repository source code modified.**
- **No database schema, migration, remote call, or Edge Function modified.**
- **No API, workflow, permissions, or business logic modified.**
- **No commit performed.**
- **No push performed.**
- **No deployment performed.**
- **No governance document modified.**
- **No existing Specification modified.**

---

*End of SPEC-005 — Foreign Key Governance Architecture Specification v1.0*
