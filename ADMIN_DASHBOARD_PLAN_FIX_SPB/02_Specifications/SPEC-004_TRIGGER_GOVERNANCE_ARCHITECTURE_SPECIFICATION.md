# SPEC-004 — Trigger Governance Architecture Specification

**Project:** VietSalePro  
**Subsystem:** Admin Dashboard / Enterprise Architecture  
**Specification Name:** Trigger Governance Architecture Specification  
**Short Identifier:** TriggerGovernance  
**Specification ID:** SPEC-004  
**Classification:** Core  
**Status:** Draft  
**Version:** 1.0  
**Effective Date:** 2026-07-23  
**Author:** Engineering Execution Agent  
**Technical Custodian:** Chief Technical Advisor (Architecture Governance)  
**Final Owner:** Production Owner  
**Approvers:** Chief Technical Advisor, Production Owner  
**Master Program Reference:** Deletion & Audit Architecture Remediation Program v1.0  
**Related Specifications:** SPEC-001 Delete Framework (mandatory), SPEC-002 Audit Architecture (optional), SPEC-003 Transaction Architecture (optional), SPEC-005 Foreign Key Governance (optional)  
**Related ADRs:** None recorded.  
**Roadmap Items:** None recorded.  

---

## 16.1 Metadata

This specification is the authoritative architecture definition for **Trigger Governance** in VietSalePro. It is a **Core** specification that establishes the catalog, classification, ownership, lifecycle, execution boundary, and behavioral contract for every persistence-layer trigger in the platform. Its identifier is `SPEC-004`; its short identifier is `TriggerGovernance`; its version is `1.0`.

| Field | Value |
|---|---|
| Project | VietSalePro |
| Subsystem | Admin Dashboard / Enterprise Architecture |
| Specification ID | SPEC-004 |
| Name | Trigger Governance Architecture Specification |
| Short Identifier | TriggerGovernance |
| Classification | Core |
| Status | Draft |
| Version | 1.0 |
| Effective Date | 2026-07-23 |
| Author | Engineering Execution Agent |
| Technical Custodian | Chief Technical Advisor (Architecture Governance) |
| Final Owner | Production Owner |
| Approvers | Chief Technical Advisor, Production Owner |
| Master Program | Deletion & Audit Architecture Remediation Program v1.0 |
| Related Specifications | SPEC-001 Delete Framework (mandatory), SPEC-002 Audit Architecture (optional), SPEC-003 Transaction Architecture (optional), SPEC-005 Foreign Key Governance (optional) |
| Related ADRs | None recorded |
| Roadmap Items | None recorded |

---

## 16.2 Purpose

**SPEC-004-PUR-001.** This document defines the enterprise Trigger Governance Architecture for VietSalePro.

**SPEC-004-PUR-002.** The Trigger Governance Architecture shall make every persistence-layer trigger explicit, classified, owned, observable, and accountable. No trigger shall operate as an undocumented, untestable side effect.

**SPEC-004-PUR-003.** The architecture shall establish the canonical boundary for legitimate trigger behavior and shall prohibit the placement of business workflow logic, business process orchestration, external system invocation, transaction ownership, cross-service coordination, or hidden business rules inside triggers.

**SPEC-004-PUR-004.** The architecture shall provide the trigger-classification, trigger-lifecycle, trigger-execution, and trigger-remediation contracts required by SPEC-001 (Delete Framework) for safe deletion workflows, by SPEC-002 (Audit Architecture) for audit-independence, and by SPEC-003 (Transaction Architecture) for atomic transaction boundaries.

**SPEC-004-PUR-005.** This specification shall not prescribe implementation code, file names, deployment scripts, data-definition statements, or operational rollout instructions. Those details belong in Implementation Plans derived from this specification.

---

## 16.3 Scope

**SPEC-004-SCO-001.** This specification covers the conceptual Trigger Governance Architecture and its canonical model for all persistence-layer triggers in VietSalePro, regardless of the physical data store, programming language, or runtime environment.

**SPEC-004-SCO-002.** The following trigger concerns are explicitly covered by this specification:

- Trigger governance principles and ownership;
- Trigger classification: integrity/guardrail, audit-immutability, referential-cascade, denormalized-cache, maintenance, business-workflow, and legacy;
- Trigger registration, cataloguing, and metadata;
- Trigger naming convention, scope, and execution boundary;
- Trigger invocation model, ordering, priority, chaining, isolation, and dependencies;
- Trigger authorization and responsibility assignment;
- Allowed and forbidden trigger behavior;
- Trigger determinism, idempotency, failure model, recovery model, and timeout considerations;
- Trigger observability, logging, monitoring, and audit interaction;
- Trigger transaction interaction and delete-framework interaction;
- Trigger foreign-key interaction and side-effect rules;
- Trigger state model, risk model, compliance, security, and future evolution.

**SPEC-004-SCO-003.** The Trigger Governance Architecture shall define how business-workflow triggers are identified, quarantined, and migrated to explicit, testable application-code paths while preserving low-level data-integrity triggers that are the sole legitimate residence of trigger logic.

**SPEC-004-SCO-004.** This specification does not define internal trigger code bodies, database-specific syntax, migration files, RPC signatures, or deployment artifacts. Those are governed by Implementation Plans and related specifications.

**SPEC-004-SCO-005.** Future persistence-layer triggers introduced after initial implementation shall be catalogued and classified according to this architecture at design time; they shall not be added without registration and review.

---

## 16.4 References

**SPEC-004-REF-001.** The following normative references govern this specification:

| Identifier | Title | Version | Purpose |
|---|---|---|---|
| Master Program | Deletion & Audit Architecture Remediation Program | v1.0 | Program vision, principles, workstreams, and scope |
| SPEC-001 | Delete Framework Architecture Specification | v1.1 (dependent) | Consumes SPEC-004 trigger contracts for business-workflow removal and guardrail triggers |
| SPEC-002 | Audit Architecture Specification | v1.0 (optional) | Audit immutability triggers and audit-write migration |
| SPEC-003 | Transaction Architecture Specification | v1.0 (optional) | Transaction boundary ownership and side-effect coordination |
| SPEC-005 | Foreign Key Governance Specification | TBD (optional) | Explicit referential-integrity contract and `ON DELETE` policies |
| SPEC-006 | Observability Specification | TBD (related) | Observability instrumentation for trigger lifecycle |
| SPEC-007 | Regression & Verification Specification | TBD (related) | Regression coverage for trigger rationalization |

---

## 16.5 Architecture Context

**SPEC-004-CTX-001.** The VietSalePro platform currently relies on persistence-layer triggers for multiple concerns, including audit logging, business-code generation, tenant limits, user tracking, and data-maintenance timestamps. Many of these triggers are not catalogued or classified, and some encode business workflow logic that is invisible to application layers and difficult to test.

**SPEC-004-CTX-002.** The `delete-tenant` HTTP 500 incident demonstrated a failure class in which an `AFTER DELETE` trigger attempted to write an audit row inside the same transaction that removed the referenced operational entity. This produced a referential-integrity failure, aborted the transaction, and surfaced as an unhandled error to the caller. The trigger owned business workflow logic that belonged in an explicit, testable code path.

**SPEC-004-CTX-003.** The underlying architectural deficiencies exposed by that incident are:

1. No authoritative inventory of triggers exists; their number, location, and responsibilities are not visible.
2. Triggers are not classified by architectural purpose, so guardrail triggers are indistinguishable from business-workflow triggers.
3. Business workflow logic is embedded in triggers, making it implicit, hard to test, and hard to reason about.
4. Audit record creation is delegated to triggers, coupling audit lifecycle to low-level data-change side effects.
5. Trigger ordering, chaining, and failure behavior are not documented or governed.
6. No process exists to approve, retire, or migrate triggers before they are introduced or modified.

**SPEC-004-CTX-004.** The target architecture treats trigger governance as a platform capability. Every trigger is catalogued, classified, owned, and bound by a strict behavior contract. Business-workflow logic is migrated to explicit application services; only low-level data-integrity, audit-immutability, and referential-cascade logic remains in the persistence layer, and even these are registered, reviewed, and observable.

**SPEC-004-CTX-005.** The architecture shall be technology-neutral: it may be realized through any persistence-layer trigger mechanism, provided the contracts and invariants defined in this specification are preserved.

---

## 16.6 Responsibilities

**SPEC-004-RES-001.** The responsibilities of each architectural layer in Trigger Governance are:

| Layer | Responsibility |
|---|---|
| Application Service | Own business workflows, business rules, audit record construction, and transaction orchestration calls. |
| Transaction Coordinator | Own the transaction boundary and commit/rollback decision, per SPEC-003. |
| Audit Writer | Own audit record creation, sealing, and integrity, per SPEC-002. |
| Trigger Registry | Maintain the canonical catalog of triggers, classifications, owners, and lifecycle states. |
| Trigger Classifier | Assign the correct classification to every trigger and detect classification drift. |
| Trigger Validator | Verify that a trigger conforms to the allowed behavior contract for its classification before activation. |
| Trigger Lifecycle Manager | Drive trigger registration, review, approval, activation, quarantine, retirement, and migration. |
| Trigger Execution Guard | Enforce the execution boundary by rejecting forbidden side effects at runtime or review time. |
| Persistence Layer | Provide the mechanism for low-level invariant enforcement and trigger invocation. |
| Security / Authorization | Control who may register, modify, or retire triggers and who may access the trigger catalog. |
| Operations | Monitor trigger executions, respond to alerts, and perform recovery actions. |

**SPEC-004-RES-002.** Application Services shall own all business workflow logic. The persistence layer shall not perform business decisions, calculations, or orchestration.

**SPEC-004-RES-003.** The Trigger Lifecycle Manager shall be the single authority for the trigger state machine; no engineer shall introduce, modify, or remove a trigger outside the governed lifecycle.

---

## 16.7 Architecture Principles Mapping

**SPEC-004-PRM-001.** The Trigger Governance Architecture shall implement every relevant principle of the Master Program as follows:

| Master Program Principle | Trigger Governance Realization |
|---|---|
| Deletion is a domain capability, not a SQL shortcut | No trigger shall implement delete workflow logic; delete lifecycle is owned by SPEC-001. |
| Audit history must survive the entity | Audit-immutability triggers may reject UPDATE/DELETE on sealed audit records but shall not write audit records. |
| Triggers guard; services decide | Triggers enforce low-level invariants only; services decide business outcomes. |
| One transaction owner | The Transaction Coordinator owns the transaction; triggers participate but do not own it. |
| Explicit by default | Every `ON DELETE` behavior and every trigger is registered, classified, and reviewed. |
| Delete is observable | Every trigger execution is correlated to a request and emits observable events. |
| No delete without validation | Trigger rationalization is verified before delete governance is accepted. |
| Platform reuse over local invention | New triggers consume the canonical Trigger Governance Architecture rather than inventing local behavior. |

---

## 16.8 Domain Model

**SPEC-004-DOM-001.** The Trigger Governance domain consists of the following conceptual objects, each with a single responsibility:

| Entity | Responsibility |
|---|---|
| Trigger | A low-level mechanism bound to a data-change event in the persistence layer. |
| Trigger Classification | The architectural purpose of a trigger (guardrail, audit-immutability, cascade, cache, maintenance, business-workflow, legacy). |
| Trigger Catalog | The authoritative registry of every trigger, its classification, owner, scope, and lifecycle state. |
| Trigger Metadata | The descriptive attributes required to locate, reason about, and govern a trigger. |
| Trigger Run | A single execution of a trigger in response to a data-change event. |
| Trigger Outcome | The result of a Trigger Run: success, failure, invariant violation, or rejection. |
| Trigger Migration | The planned, reviewed transition of a business-workflow trigger to an explicit application-code path. |

**SPEC-004-DOM-002.** A `Trigger` shall be uniquely identified by a `trigger_id` that encodes its domain, target resource, and classification. The `Trigger Catalog` shall be the single source of truth for trigger existence and state.

**SPEC-004-DOM-003.** A `Trigger Classification` is not a runtime type; it is an architectural label assigned by the Trigger Classifier and recorded in the `Trigger Catalog`.

**SPEC-004-DOM-004.** A `Trigger Run` shall always be associated with a `Trigger` and, where applicable, with the `correlation_id` of the operation that caused the data change.

---

## 16.9 Components

**SPEC-004-COM-001.** The Trigger Governance Architecture comprises the following logical components:

| Component | Responsibility | Placement |
|---|---|---|
| Trigger Catalog Store | Persist the canonical list of triggers, metadata, classifications, and lifecycle states. | Governance / Operations layer |
| Trigger Classifier | Inspect trigger purpose and assign the correct classification. | Architecture / Engineering governance |
| Trigger Validator | Verify that a trigger's code and behavior conform to the allowed contract for its classification. | Governance / Engineering governance |
| Trigger Lifecycle Manager | Manage registration, review, approval, activation, quarantine, retirement, and migration. | Governance / Operations layer |
| Trigger Execution Guard | Enforce the execution boundary at runtime or at review time by rejecting forbidden side effects. | Runtime / Governance layer |
| Trigger Migration Handler | Plan and track the migration of business-workflow triggers to explicit application code. | Engineering governance |
| Trigger Observability Emitter | Emit structured logs, metrics, and traces for every trigger lifecycle and runtime event. | Observability layer |
| Trigger Approval Authority | Approve or reject new triggers, reclassifications, and migrations. | Chief Technical Advisor / Production Owner |

**SPEC-004-COM-002.** The `Trigger Catalog Store` shall be the sole authoritative record of trigger existence and state. No trigger shall be considered active unless it is recorded in the catalog with an `ACTIVE` or `RETAINED` state.

**SPEC-004-COM-003.** The `Trigger Execution Guard` shall reject any trigger that attempts to perform an action outside the allowed behavior contract for its classification, either through static validation or through runtime safeguards.

---

## 16.10 Interfaces

**SPEC-004-INT-001.** The Trigger Governance Architecture exposes the following abstract interfaces:

| Interface | Input | Output | Purpose |
|---|---|---|---|
| Register Trigger | Trigger metadata, classification request, owner, scope | `trigger_id`, review ticket | Enroll a trigger in the catalog. |
| Classify Trigger | `trigger_id`, code inspection, intended purpose | Classification label, risk score | Assign the architectural class. |
| Validate Trigger | `trigger_id`, classification, behavior evidence | Pass/fail with findings | Confirm contract conformance. |
| Activate Trigger | `trigger_id`, approved classification | Active state or quarantine | Move trigger into production. |
| Retire/Migrate Trigger | `trigger_id`, migration plan, target application code | Retired or migrated state | Remove forbidden triggers safely. |
| Query Trigger Catalog | Filters (domain, classification, state, owner) | Trigger list and metadata | Support governance, audit, and operations. |
| Emit Trigger Observability | `trigger_id`, `correlation_id`, event type, outcome | Acknowledgment | Provide traceability. |

**SPEC-004-INT-002.** All trigger governance interfaces shall be read-only or append-only with respect to the `Trigger Catalog`, except for the `Lifecycle Manager`, which is the sole component authorized to mutate lifecycle state.

---

## 16.11 Contracts

**SPEC-004-CON-001.** The Trigger Governance contracts are technology-neutral and implementation-neutral. Every implementation shall honor the following contracts.

### 16.11.1 Trigger Classification Contract

**SPEC-004-CON-002.** Every trigger shall be assigned exactly one classification from the canonical set defined in this specification.

**SPEC-004-CON-003.** The canonical trigger classifications are:

| Classification | Allowed Purpose | Examples |
|---|---|---|
| Integrity / Guardrail | Enforce low-level invariants that cannot be expressed through declarative constraints. | Prevent impossible state transitions, enforce value bounds. |
| Audit Immutability | Reject UPDATE or DELETE attempts on sealed audit records. | Block mutation of sealed audit rows. |
| Referential Cascade | Maintain referential integrity through controlled propagation when declarative `ON DELETE` is insufficient. | Cascade cleanup of dependent rows under explicit policy. |
| Denormalized Cache | Keep a derived, non-authoritative cache consistent with an authoritative source. | Update a summary counter or search index. |
| Maintenance | Update automatically-maintained non-business fields such as timestamps. | Set `updated_at` or `last_modified`. |
| Business Workflow | Encode business rules, business process, or external side effects. | Forbidden; must be migrated. |
| Legacy / Unknown | Triggers whose purpose is not yet classified. | Must be reviewed and reclassified. |

### 16.11.2 Trigger Ownership Contract

**SPEC-004-CON-004.** Every trigger shall have a named owner who is accountable for its classification, behavior, lifecycle, and retirement.

**SPEC-004-CON-005.** A trigger may not be activated, modified, or retired without the recorded owner's approval or explicit delegation.

### 16.11.3 Trigger Registration Contract

**SPEC-004-CON-006.** No trigger shall be introduced without prior registration in the `Trigger Catalog`.

**SPEC-004-CON-007.** Registration shall capture: `trigger_id`, name, classification, owner, scope (table/resource and event), ordering dependencies, timeout expectation, risk classification, and review status.

### 16.11.4 Trigger Naming and Scope Contract

**SPEC-004-CON-008.** Every trigger name shall be predictable and shall encode the target resource, event, and classification intent.

**SPEC-004-CON-009.** A trigger's scope shall be limited to a single data-change event on a single resource unless an explicit multi-resource cascade contract is approved and documented.

### 16.11.5 Trigger Execution Boundary Contract

**SPEC-004-CON-010.** Triggers exist only to protect low-level data integrity. Triggers shall not implement business workflows, orchestrate business processes, invoke external systems, own business transactions, perform cross-service coordination, or contain hidden business rules.

**SPEC-004-CON-011.** A trigger shall operate entirely within the persistence layer and shall not initiate operations outside the transaction boundary in which it was invoked.

### 16.11.6 Trigger Invocation Model Contract

**SPEC-004-CON-012.** A trigger shall be invoked automatically by the persistence layer as a consequence of a data-change event on its target resource.

**SPEC-004-CON-013.** The invocation model shall be deterministic: the same input state, with the same catalogued triggers, shall produce the same trigger execution order and outcome.

### 16.11.7 Trigger Ordering and Priority Contract

**SPEC-004-CON-014.** The order in which triggers fire on the same resource and event shall be explicit, documented in the `Trigger Catalog`, and reviewed when any trigger is added, removed, or reclassified.

**SPEC-004-CON-015.** Priority shall be used only to resolve low-level invariant ordering (for example, immutability before cascade); it shall not encode business sequencing.

### 16.11.8 Trigger Chaining and Isolation Contract

**SPEC-004-CON-016.** Trigger chaining shall be explicit and documented. A trigger that modifies a different resource and thereby causes additional triggers to fire is considered a cascade and shall be classified as Referential Cascade.

**SPEC-004-CON-017.** Triggers shall be isolated from each other's internal state. No trigger shall rely on the order-specific side effects of another trigger beyond the documented chaining contract.

### 16.11.9 Trigger Dependencies and Authorization Contract

**SPEC-004-CON-018.** Every trigger shall declare its dependencies, if any, on other triggers, constraints, or resources in the `Trigger Catalog`.

**SPEC-004-CON-019.** The activation of a trigger shall require authorization from the trigger owner and, for high-risk classifications, from the Trigger Approval Authority.

### 16.11.10 Trigger Behavior Contract

**SPEC-004-CON-020.** Allowed trigger behavior is limited to: enforcing a low-level invariant, rejecting an invalid operation, updating a maintenance field, updating a denormalized cache, or propagating a referential change within the documented cascade policy.

**SPEC-004-CON-021.** Forbidden trigger behavior includes: writing audit records, sending messages, calling external systems, making authorization decisions, computing business values, assigning identifiers, enforcing tenant limits, or performing any action that belongs to an Application Service.

### 16.11.11 Trigger Determinism and Idempotency Contract

**SPEC-004-CON-022.** Trigger execution must remain deterministic. The outcome shall depend only on the state of the target resource and the documented trigger logic, not on external state, time, or execution order beyond the documented priority.

**SPEC-004-CON-023.** Trigger execution must be idempotent within a transaction: if a transaction is replayed or retried, the trigger shall produce the same effect and shall not create duplicate side effects.

### 16.11.12 Trigger Timeout Contract

**SPEC-004-CON-024.** Every trigger shall declare a maximum execution duration in the `Trigger Catalog`. A trigger that exceeds that duration shall be considered a failure and shall cause the enclosing transaction to roll back unless explicitly exempted.

### 16.11.13 Trigger Failure and Recovery Contract

**SPEC-004-CON-025.** A failed trigger shall produce a structured error containing the `trigger_id`, the data-change event, the failure classification, and the `correlation_id` of the operation.

**SPEC-004-CON-026.** When a trigger failure is classified as unrecoverable, the persistence layer shall roll back the enclosing transaction to preserve data integrity.

### 16.11.14 Trigger Observability Contract

**SPEC-004-CON-027.** Every trigger execution shall emit an observable event containing: `trigger_id`, classification, target resource, event type, `correlation_id`, start/end timestamps, duration, and outcome.

### 16.11.15 Trigger Audit Interaction Contract

**SPEC-004-CON-028.** Audit record creation is owned by the Audit Writer, per SPEC-002. Triggers shall not write audit records.

**SPEC-004-CON-029.** Audit-immutability triggers may reject UPDATE or DELETE attempts on sealed audit records, but they shall not create, modify, or interpret audit content.

### 16.11.16 Trigger Transaction Interaction Contract

**SPEC-004-CON-030.** Triggers participate in the transaction owned by the Transaction Coordinator, per SPEC-003. Triggers shall not own, commit, or roll back a transaction.

**SPEC-004-CON-031.** A trigger shall not emit side effects that cross the transaction boundary, such as outbox messages, external calls, or compensating actions.

### 16.11.17 Trigger Delete Framework Interaction Contract

**SPEC-004-CON-032.** The Delete Framework, per SPEC-001, owns the delete workflow. Triggers may enforce low-level invariants during a delete operation but shall not implement delete cascade logic that is not explicitly documented in the Delete Framework or Foreign Key Governance.

**SPEC-004-CON-033.** A trigger that fires during a delete operation shall not attempt to insert audit rows referencing an entity that is being deleted within the same transaction.

### 16.11.18 Trigger Foreign Key Interaction Contract

**SPEC-004-CON-034.** Triggers shall respect the `ON DELETE` and referential-integrity policies defined in SPEC-005. Referential-cascade triggers shall be used only where declarative constraints cannot express the required policy.

### 16.11.19 Trigger Security and Compliance Contract

**SPEC-004-CON-035.** A trigger shall not contain secrets, credentials, or hard-coded authorization logic. Privilege elevation by a trigger is prohibited.

**SPEC-004-CON-036.** Every modification of the `Trigger Catalog` or trigger code shall be recorded as an auditable event, including the actor, the change, and the approval reference.

**SPEC-004-CON-037.** Compliance reviews shall verify that no business-workflow triggers remain active and that all active triggers are recorded in the `Trigger Catalog`.

---

## 16.12 State Machine

**SPEC-004-STM-001.** Every trigger shall move through the governed lifecycle defined in this section.

### 16.12.1 Happy Path

```
PLANNED
  ↓ registration submitted
REGISTERED
  ↓ metadata and owner assigned
REVIEWED
  ↓ classification confirmed, validator passed
ACTIVE
  ↓ normal operation; monitored
RETIRED
  ↓ no longer invoked
ARCHIVED
```

### 16.12.2 Exception Path

```
REVIEWED
  ↓ validator failed or high risk
QUARANTINED
  ↓ remediated and revalidated
REVIEWED

ACTIVE
  ↓ business-workflow logic discovered
MIGRATING
  ↓ replacement application code deployed and verified
RETIRED
```

### 16.12.3 Transition Rules

| From | To | Guard | Owner | Action |
|---|---|---|---|---|
| PLANNED | REGISTERED | Registration submitted | Trigger Lifecycle Manager | Create `trigger_id` and catalog entry. |
| REGISTERED | REVIEWED | Metadata complete | Trigger Classifier | Assign classification and risk. |
| REVIEWED | ACTIVE | Validation passed and approval granted | Trigger Approval Authority | Activate trigger. |
| REVIEWED | QUARANTINED | Validation failed or risk too high | Trigger Validator | Block activation; schedule remediation. |
| QUARANTINED | REVIEWED | Remediation evidence provided | Trigger Validator | Re-run validation. |
| ACTIVE | MIGRATING | Reclassified as Business Workflow | Trigger Migration Handler | Plan migration to application code. |
| MIGRATING | RETIRED | Replacement code deployed and verified | Trigger Lifecycle Manager | Disable trigger and archive. |
| ACTIVE | RETIRED | Owner or authority requests retirement | Trigger Lifecycle Manager | Disable trigger and record reason. |
| RETIRED | ARCHIVED | Retention period elapsed | Trigger Lifecycle Manager | Remove catalog entry from active governance. |

**SPEC-004-STM-002.** States are terminal when they are `RETIRED` or `ARCHIVED`.

**SPEC-004-STM-003.** Every state transition shall be logged with previous state, new state, actor, timestamp, and reason.

---

## 16.13 Workflow

**SPEC-004-WFL-001.** The canonical trigger governance workflow consists of the following high-level stages:

1. **Discover** — Identify all existing persistence-layer triggers and create initial catalog entries.
2. **Register** — Record trigger metadata, owner, scope, and intended classification.
3. **Classify** — Assign the canonical classification and a risk level.
4. **Validate** — Verify that the trigger's behavior conforms to the allowed contract for its classification.
5. **Approve** — Obtain the owner's and, where required, the authority's approval.
6. **Activate** — Move the trigger to the `ACTIVE` state.
7. **Monitor** — Continuously observe trigger executions for failures, drift, and hidden business logic.
8. **Remediate** — Quarantine or migrate triggers that violate the contract.
9. **Retire** — Disable and archive triggers that are no longer needed or that have been replaced by application code.

**SPEC-004-WFL-002.** If validation fails, the trigger shall transition to `QUARANTINED` and shall not be activated until the findings are resolved and re-validated.

**SPEC-004-WFL-003.** Business-workflow triggers shall be migrated to explicit application services through the `MIGRATING` state and shall be retired only after the replacement code is deployed and verified.

---

## 16.14 Sequence

**SPEC-004-SEQ-001.** The critical path for trigger execution in response to a data change shall follow this sequence:

```
Application Service submits data-change request
  → Transaction Coordinator opens transaction boundary
    → Persistence layer applies requested row mutation
      → Trigger Execution Guard loads active triggers for resource/event from Trigger Catalog
        → Triggers fire in documented priority order
          → Each trigger performs allowed invariant, maintenance, or cascade work
            → Trigger Execution Guard detects any forbidden side effect
              → On forbidden side effect: trigger fails, transaction rolls back
                → Trigger Observability Emitter records trigger_id, correlation_id, outcome
                  → Transaction Coordinator commits or rolls back the transaction
                    → Post-commit, side-effect handlers (outside triggers) process outbox messages
```

**SPEC-004-SEQ-002.** If a trigger detects an invariant violation, it shall raise an error that causes the persistence layer to roll back the data change and the transaction coordinator to roll back the transaction.

**SPEC-004-SEQ-003.** If a trigger attempts to perform an action outside the allowed behavior contract, the `Trigger Execution Guard` shall fail the trigger and the transaction shall roll back.

**SPEC-004-SEQ-004.** The registration and classification sequence for a new trigger shall be: engineer submits registration → Trigger Classifier assigns classification → Trigger Validator checks contract → owner and authority approve → Trigger Lifecycle Manager activates the trigger.

---

## 16.15 Data Model

**SPEC-004-DAT-001.** The Trigger Governance data model is logical and conceptual. It does not prescribe physical table names, column types, or storage engines.

### 16.15.1 Core Entities

| Entity | Attributes | Ownership |
|---|---|---|
| Trigger Catalog Entry | trigger_id, name, classification, owner, scope, event, dependencies, priority, timeout, risk_level, lifecycle_state, review_ticket | Trigger Lifecycle Manager |
| Trigger Run Record | run_id, trigger_id, correlation_id, event, start_time, end_time, duration, outcome, error_code | Trigger Observability Emitter |
| Trigger Classification Rule | classification_code, allowed_behaviors, forbidden_behaviors, examples | Trigger Classifier |
| Trigger Migration Plan | migration_id, trigger_id, target_service, verification_criteria, status, owner | Trigger Migration Handler |
| Trigger Approval Record | approval_id, trigger_id, approver, approval_type, timestamp, reference | Trigger Approval Authority |

### 16.15.2 Data Ownership

**SPEC-004-DAT-002.** The `Trigger Catalog` and `Trigger Classification Rules` are owned by the Trigger Governance process.

**SPEC-004-DAT-003.** The `Trigger Run Record` is owned by the Trigger Observability Emitter and is immutable after creation.

**SPEC-004-DAT-004.** The `Trigger Migration Plan` is owned by the Trigger Migration Handler and is updated only through the migration workflow.

---

## 16.16 Failure Model

**SPEC-004-FAM-001.** The following failure modes are in scope for Trigger Governance:

| ID | Failure Mode | Likelihood | Impact | Detection |
|---|---|---|---|---|
| F-001 | Business logic hidden in an active trigger | High | High | Trigger Validator or runtime observability detects forbidden behavior. |
| F-002 | Trigger misfires or fires in wrong order | Medium | High | Outcome mismatch and correlation trace reveal ordering defect. |
| F-003 | Trigger attempts to write audit records | Medium | High | Static validation rejects or runtime audit-integrity checks detect. |
| F-004 | Trigger performs external side effect | Low | High | Trigger Execution Guard blocks or observability detects outbound call. |
| F-005 | Trigger timeout stalls transaction | Low | High | Timeout monitor fires alert; transaction coordinator rolls back. |
| F-006 | Trigger catalog is incomplete or stale | Medium | Medium | Catalog-to-runtime drift checks detect undocumented triggers. |

**SPEC-004-FAM-002.** The impact of a hidden business-workflow trigger is high because it can cause silent data corruption, transaction aborts, and audit failures that are difficult to reproduce in tests.

---

## 16.17 Recovery Model

**SPEC-004-RCM-001.** The following recovery actions shall be available for each failure mode:

| Failure Mode | Recovery Action | Owner |
|---|---|---|
| Business logic hidden in an active trigger | Quarantine trigger, migrate logic to application service, re-validate. | Trigger Migration Handler |
| Trigger misfires or fires in wrong order | Roll back transaction, correct priority/dependency, replay operation. | Trigger Lifecycle Manager |
| Trigger attempts to write audit records | Disable trigger, redirect audit writes to Audit Writer, validate. | Audit Architect / Trigger Lifecycle Manager |
| Trigger performs external side effect | Block trigger, remove external call, re-validate, compensate if needed. | Security / Trigger Lifecycle Manager |
| Trigger timeout stalls transaction | Roll back transaction, increase declared timeout or optimize trigger, re-attempt. | Operations / Trigger Lifecycle Manager |
| Trigger catalog is incomplete or stale | Re-run discovery, quarantine undocumented triggers, update catalog. | Trigger Lifecycle Manager |

**SPEC-004-RCM-002.** When a trigger is quarantined, the persistence layer shall treat it as if it were retired: it shall not fire until it is revalidated and returned to `ACTIVE`.

**SPEC-004-RCM-003.** Recovery actions for trigger failures shall not bypass the transaction ownership of the Transaction Coordinator or the audit ownership of the Audit Writer.

---

## 16.18 Security

**SPEC-004-SEC-001.** The `Trigger Catalog` shall be readable only by authorized architects, security reviewers, and operators. Modifications shall require approval from the trigger owner and the Trigger Approval Authority.

**SPEC-004-SEC-002.** No trigger shall store, log, or expose secrets, credentials, or personal data beyond the minimum required for its low-level invariant.

**SPEC-004-SEC-003.** A trigger shall not perform authorization decisions. Authorization remains the responsibility of the Application Service and the persistence-layer row-level security policy.

---

## 16.19 Observability

**SPEC-004-OBS-001.** The following observability events are required for every trigger:

| Event | Required Attributes | Purpose |
|---|---|---|
| Trigger Fired | trigger_id, correlation_id, resource, event, start_time | Trace every trigger invocation. |
| Trigger Completed | trigger_id, correlation_id, end_time, duration, outcome | Measure correctness and latency. |
| Trigger Failed | trigger_id, correlation_id, error_code, failure_class, reason | Drive alerts and recovery. |
| Trigger Classified | trigger_id, classification, risk_level, classifier, timestamp | Record governance decision. |
| Trigger State Changed | trigger_id, from_state, to_state, actor, reason | Audit lifecycle transitions. |

**SPEC-004-OBS-002.** Operators shall have dashboards showing the number of active triggers by classification, the rate of trigger failures, and the rate of trigger timeouts.

**SPEC-004-OBS-003.** Alerts shall fire when an active trigger produces an outcome outside its documented contract or when an undocumented trigger is detected in the runtime environment.

---

## 16.20 Risks

**SPEC-004-RSK-001.** The following risks are introduced or mitigated by the Trigger Governance Architecture:

| ID | Risk | Likelihood | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| R1 | Legacy business-workflow triggers resist migration | High | High | Provide migration template, staged quarantine, and automated static analysis. | Trigger Migration Handler |
| R2 | Trigger catalog drifts from runtime reality | Medium | Medium | Periodic automated discovery and catalog reconciliation. | Trigger Lifecycle Manager |
| R3 | Trigger ordering changes silently break invariants | Medium | High | Catalog-driven priority review and integration tests. | Trigger Validator |
| R4 | Performance impact from overuse of triggers | Medium | Medium | Enforce timeout contract and classify maintenance triggers for review. | Trigger Validator |
| R5 | Hidden cross-service calls in triggers | Low | High | Runtime guard and static analysis for external references. | Security / Trigger Execution Guard |

---

## 16.21 Constraints

**SPEC-004-CST-001.** The Trigger Governance Architecture is constrained by the following fixed limits:

| ID | Constraint | Source |
|---|---|---|
| C-001 | The architecture shall remain technology-neutral and shall not assume any specific database, trigger language, or runtime. | Architecture Specification Program Section 18. |
| C-002 | Triggers may enforce low-level invariants only; business workflow logic shall not be implemented in triggers. | Master Program Guiding Principle 3. |
| C-003 | Triggers shall not own, commit, or roll back transactions. | SPEC-003 Transaction Ownership Contract. |
| C-004 | Triggers shall not write audit records. | SPEC-002 Audit Writer Responsibility. |
| C-005 | Triggers shall not perform cross-service coordination or invoke external systems. | Master Program Guiding Principle 4 and SPEC-003 Side-Effect Contract. |
| C-006 | Every trigger shall be catalogued and classified before activation. | Master Program Guiding Principle 6. |

---

## 16.22 Non-goals

**SPEC-004-NGO-001.** This specification does not prescribe:

1. Implementation code, file names, package structures, or deployment commands.
2. Concrete trigger syntax, trigger templates, data-definition statements, or migration scripts.
3. Operational rollout instructions, rollback playbooks, or environment-specific configuration.
4. The internal algorithms of the Trigger Validator, Trigger Execution Guard, or static analyzer.
5. A redefinition of the Audit Architecture, Transaction Architecture, Delete Framework, or Foreign Key Governance beyond their interaction with triggers.

---

## 16.23 Verification Requirements

**SPEC-004-VRF-001.** The Trigger Governance Architecture shall be verified by the following evidence:

1. **Catalog Completeness** — Every persistence-layer trigger is recorded in the `Trigger Catalog` with complete metadata.
2. **Classification Accuracy** — Every active trigger is classified according to the canonical classification matrix.
3. **Forbidden Behavior Detection** — No active trigger writes audit records, invokes external systems, performs authorization decisions, or implements business workflow logic.
4. **Determinism** — Replaying the same data-change scenario produces the same trigger execution order and outcome.
5. **Idempotency** — Retrying a transaction does not produce duplicate trigger side effects.
6. **Timeout Compliance** — Every active trigger completes within its declared timeout.
7. **Ordering Compliance** — Trigger execution order matches the documented priority in the `Trigger Catalog`.
8. **Lifecycle Compliance** — Every trigger has transitioned through the governed lifecycle and is in an approved state.
9. **Observability** — Trigger execution events are emitted and queryable by `trigger_id` and `correlation_id`.
10. **Integration** — Delete, audit, and transaction workflows function correctly in the presence of retained low-level triggers.

---

## 16.24 Acceptance Criteria

**SPEC-004-ACC-001.** The Trigger Governance Architecture and its implementation are accepted when:

1. All mandatory sections are present and reviewed.
2. All requirements carry unique identifiers and are traceable to verification requirements and acceptance criteria.
3. The implementation passes all verification requirements in Section 16.23.
4. A complete `Trigger Catalog` exists for all persistence-layer triggers.
5. All business-workflow triggers are quarantined and either migrated or scheduled for migration with an approved plan.
6. No active trigger violates the allowed behavior contract.
7. Trigger observability dashboards and alerts are operational.
8. The `delete-tenant` path and other critical delete paths succeed without trigger-induced referential-integrity failures.
9. The Production Owner approves the specification and the implementation.

---

## 16.25 Future Evolution

**SPEC-004-FEV-001.** The Trigger Governance Architecture is designed to evolve without redesign. The following extension points are preserved:

| Extension | Description |
|---|---|
| New classifications | New low-level trigger classes may be added through the classification registry and governance review. |
| New resources | New business domains shall register their triggers through the same lifecycle. |
| Automated discovery | Catalog reconciliation may be automated over time without changing the lifecycle. |
| Runtime enforcement | The Trigger Execution Guard may be enhanced with stricter static and runtime checks. |
| Event-driven alternatives | Low-level integrity work may eventually move to declarative constraints or event-sourced handlers while preserving the same contracts. |

**SPEC-004-FEV-002.** Any change that adds, removes, or reclassifies a trigger classification shall require an Architecture Decision Record per the Master Program Section 29.

---

## 16.26 Appendix

### A. Trigger Classification Matrix

| Classification | Allowed | Forbidden | Migration Target |
|---|---|---|---|
| Integrity / Guardrail | Enforce low-level invariants, reject invalid state | Business decisions, external calls | None; retain |
| Audit Immutability | Reject UPDATE/DELETE on sealed audit records | Write audit content, read audit for logic | None; retain |
| Referential Cascade | Propagate deletions within documented policy | Cross-resource business logic | Delete Framework / FK Governance |
| Denormalized Cache | Update derived non-authoritative values | Authoritative business state changes | Application cache or read model |
| Maintenance | Update timestamp or similar non-business fields | Any business meaning | Application service or generated columns |
| Business Workflow | Nothing | Everything except low-level invariant enforcement | Application Service |
| Legacy / Unknown | Nothing until classified | Remains in quarantine until classified | Reclassified or retired |

### B. Trigger Metadata Template

| Attribute | Description | Required |
|---|---|---|
| trigger_id | Unique, stable identifier | Yes |
| name | Human-readable, follows naming convention | Yes |
| classification | Canonical classification | Yes |
| owner | Named accountable owner | Yes |
| scope | Target resource and data-change event | Yes |
| dependencies | Other triggers or resources it depends on | If any |
| priority | Execution order among same resource/event | If multiple |
| timeout | Maximum declared execution duration | Yes |
| risk_level | Low / Medium / High | Yes |
| lifecycle_state | Current state | Yes |
| review_ticket | Reference to governance review | Yes |

### C. Trigger-to-Domain Mapping Template

| Domain | Known Trigger Classes | Governance Action |
|---|---|---|
| Audit | Audit-immutability triggers may remain; audit-writing triggers must migrate. | Convert to Audit Writer calls. |
| Delete | Referential-cascade and guardrail triggers may remain; business triggers must migrate. | Align with Delete Framework and FK Governance. |
| Tenant Limits | Business-workflow tenant limit triggers must migrate. | Move to Application Service with explicit enforcement. |
| Order Code Generation | Business-workflow identifier triggers must migrate. | Move to Application Service or canonical sequence. |
| Timestamps | Maintenance triggers may remain with review. | Evaluate generated-column alternatives. |

### D. Traceability Summary

| This Specification Section | Traces To |
|---|---|
| 16.2 Purpose | Master Program Sections 1, 2, 3, 7, 8 |
| 16.3 Scope | Master Program Section 9 |
| 16.5 Architecture Context | Master Program Sections 4, 5, 6, 22 |
| 16.6 Responsibilities | Master Program Section 10.6 |
| 16.7 Architecture Principles Mapping | Master Program Section 7 |
| 16.8 Domain Model | Master Program Section 24 |
| 16.12 State Machine | Master Program Section 25 |
| 16.13 Workflow | Master Program Section 10.6 |
| 16.14 Sequence | Master Program Sections 10.1, 10.6 |
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
2. `.codebase-memory/SEMANTIC_MEMORY.md` — Architecture overview, business modules, trigger inventory and classification observations.
3. `.codebase-memory/VALIDATION_REPORT.md` — Confidence scores, known limitations, corrections.

### E.2 Governance Documents Consulted

The following governance documents were read in the required order:

1. `Deletion_Audit_Architecture_Remediation_Program.md` (Master Program v1.0) — Vision, principles, goals, workstreams, scope, state machine, domain model, classification, dependency matrix, risks, success criteria.
2. `01_Governance/Architecture_Specification_Program.md` (Specification Program v1.1) — Mandatory template (Sections 16.1–16.26), metadata, versioning, naming, folder structure, traceability, dependency, quality gates.
3. `01_Governance/ARCHITECTURE_SPECIFICATION_INDEX.md` (Index v1.1) — Portfolio position, dependencies, and authoring order.
4. `01_Governance/SPEC_BASELINE_CERTIFICATION.md` (Baseline Certification v1.0) — Golden Specification inheritance rules, allowed and prohibited variations, specification creation rules.

### E.3 Cross-Validation Results

| Check | Result |
|---|---|
| SPEC-004 file does not already exist | Confirmed |
| SPEC-001 used as golden authoring example | Confirmed |
| SPEC-002 interaction verified | Confirmed |
| SPEC-003 interaction verified | Confirmed |
| Technology neutrality preserved | Confirmed (no SQL, vendor, or implementation code) |
| Implementation independence preserved | Confirmed (no rollout, file names, or deployment artifacts) |

### E.4 Extracted Governance Summary

The Golden Specification (SPEC-001) inheritance rules were followed: the document header, metadata table, section numbering, requirement identifier convention, normative language, traceability format, appendix organization, and evidence format were inherited. Only the trigger governance domain content is original.

### E.5 Portfolio Validation

SPEC-004 is classified as Core and integrates with SPEC-001 (mandatory), SPEC-002, SPEC-003, and SPEC-005 without duplicating their architectural responsibilities.

### E.6 Dependency Validation

- SPEC-001 Delete Framework: SPEC-004 provides the trigger behavior contract and lifecycle required to remove business-workflow triggers from delete paths.
- SPEC-002 Audit Architecture: SPEC-004 confirms that audit-writing triggers migrate to the Audit Writer while audit-immutability triggers remain as low-level guards.
- SPEC-003 Transaction Architecture: SPEC-004 confirms that triggers participate in transactions owned by the Transaction Coordinator.
- SPEC-005 Foreign Key Governance: SPEC-004 confirms that triggers respect the explicit `ON DELETE` contract.

### E.7 Template Compliance

All mandatory sections (16.1 through 16.26) are present in the required order. The Evidence section is placed after the Appendix. Requirement identifiers use the `SPEC-004-<SECTION>-<NNN>` format with the canonical three-letter section codes.

### E.8 Traceability Summary

Traceability from each specification section to the Master Program is recorded in Appendix D. All cross-references use the `SPEC-NNN vX.Y` format.

### E.9 Risk Assessment

The primary residual risk is that legacy business-workflow triggers may resist migration. This is mitigated by the classification matrix, the `MIGRATING` state, and the verification requirements. No implementation, database, or deployment risks are introduced by this specification alone.

### E.10 Confirmation

This specification was authored as an Architecture Specification only. No implementation, commit, push, deployment, database change, migration, RPC, or edge function was created or modified. The deliverable is the file `SPEC-004_TRIGGER_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` only.
