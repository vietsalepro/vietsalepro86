# SPEC-001 — Delete Framework Architecture Specification

**Project:** VietSalePro  
**Subsystem:** Admin Dashboard / Enterprise Architecture  
**Specification Name:** Delete Framework Architecture Specification  
**Short Identifier:** DeleteFramework  
**Specification ID:** SPEC-001  
**Classification:** Core  
**Status:** Draft  
**Version:** 1.1  
**Effective Date:** 2026-07-23  
**Author:** Engineering Execution Agent  
**Technical Custodian:** Chief Technical Advisor (Architecture Governance)  
**Final Owner:** Production Owner  
**Approvers:** Chief Technical Advisor, Production Owner  
**Master Program Reference:** Deletion & Audit Architecture Remediation Program v1.0  
**Related Specifications:** SPEC-002 Audit Architecture, SPEC-003 Transaction Architecture, SPEC-005 Foreign Key Governance  
**Related ADRs:** None recorded.  
**Roadmap Items:** None recorded.  

---

## 16.1 Metadata

This specification is the authoritative architecture definition for the **Delete Framework** of VietSalePro. It is a **Core** specification that establishes the canonical, reusable deletion pipeline for every in-scope domain. Its identifier is `SPEC-001`; its short identifier is `DeleteFramework`; its version is `1.1`.

| Field | Value |
|---|---|
| Project | VietSalePro |
| Subsystem | Admin Dashboard / Enterprise Architecture |
| Specification ID | SPEC-001 |
| Name | Delete Framework Architecture Specification |
| Short Identifier | DeleteFramework |
| Classification | Core |
| Status | Draft |
| Version | 1.1 |
| Effective Date | 2026-07-23 |
| Author | Engineering Execution Agent |
| Technical Custodian | Chief Technical Advisor (Architecture Governance) |
| Final Owner | Production Owner |
| Approvers | Chief Technical Advisor, Production Owner |
| Master Program | Deletion & Audit Architecture Remediation Program v1.0 |
| Related Specifications | SPEC-002, SPEC-003, SPEC-005 (mandatory) |
| Related ADRs | None recorded |
| Roadmap Items | None recorded |

---

## 16.2 Purpose

**SPEC-001-PUR-001.** This document defines the enterprise Delete Framework for VietSalePro.

**SPEC-001-PUR-002.** The Delete Framework shall make deletion a first-class platform capability: every delete operation across every in-scope domain shall be explicit, atomic, auditable, recoverable, and reusable.

**SPEC-001-PUR-003.** The framework shall replace ad-hoc, per-module delete implementations with a single canonical pipeline that is consumed by frontend, service, Edge Function, and database layers.

**SPEC-001-PUR-004.** This specification shall resolve the architectural failure class that produced the `delete-tenant` HTTP 500 incident by governing deletion lifecycle, transaction ownership, audit interaction, foreign-key policy interaction, and observability.

**SPEC-001-PUR-005.** This specification shall not prescribe implementation code, file names, deployment commands, or migration SQL. Those details belong in Implementation Plans derived from this specification.

---

## 16.3 Scope

**SPEC-001-SCO-001.** This specification covers the conceptual delete framework and its canonical pipeline for all deletable domains of VietSalePro.

**SPEC-001-SCO-002.** The following in-scope domains are explicitly covered by this specification:

- Tenant
- User
- Product
- Customer
- Warehouse
- Employee
- Membership
- Subscription

**SPEC-001-SCO-003.** The framework shall define:

- Deletion lifecycle states and state transitions;
- Deletion classifications: soft, hard, purge, bulk, archive, logical, physical, retention, compliance, and emergency;
- Canonical delete pipeline stages: request, validation, preparation, transaction execution, side-effect orchestration, and completion;
- Layer responsibilities for frontend, service, edge/routing, database, storage, audit, authentication, and authorization;
- Interaction models with the Audit Architecture (SPEC-002), Transaction Architecture (SPEC-003), and Foreign Key Governance (SPEC-005);
- Failure modes, recovery model, and observability requirements;
- Security, compliance, and acceptance criteria.

**SPEC-001-SCO-004.** This specification does not define the internal schemas, RPC signatures, or deployment artifacts of any specific implementation. Those are governed by related specifications and implementation plans.

**SPEC-001-SCO-005.** Future domains introduced after initial implementation shall onboard to this framework at design time; they shall not introduce independent delete semantics.

---

## 16.4 References

**SPEC-001-REF-001.** The following normative references govern this specification:

| Identifier | Title | Version | Purpose |
|---|---|---|---|
| Master Program | Deletion & Audit Architecture Remediation Program | v1.0 | Program vision, principles, workstreams, and scope |
| SPEC-002 | Audit Architecture Specification | TBD (mandatory dependency) | Immutable, append-only audit records that survive entity deletion |
| SPEC-003 | Transaction Architecture Specification | TBD (mandatory dependency) | Atomic deletion boundary, rollback, and side-effect compensation |
| SPEC-005 | Foreign Key Governance Specification | TBD (mandatory dependency) | Explicit `ON DELETE` contract and referential-integrity policy |
| SPEC-004 | Trigger Governance Specification | TBD (dependent) | Trigger classification and removal of business workflow logic from triggers |
| SPEC-006 | Observability Specification | TBD (dependent) | Delete-lifecycle observability instrumentation |
| SPEC-007 | Regression & Verification Specification | TBD (dependent) | Regression coverage for delete paths |

---

## 16.5 Architecture Context

**SPEC-001-CTX-001.** The VietSalePro platform currently performs deletion as a feature-level concern rather than a platform capability.

**SPEC-001-CTX-002.** The `delete-tenant` HTTP 500 incident demonstrated the failure pattern: an `AFTER DELETE` trigger attempted to insert an audit row referencing a tenant that was already deleted within the same transaction, causing a foreign-key violation and an unhandled error.

**SPEC-001-CTX-003.** The underlying architectural deficiencies exposed by that incident are:

1. Audit records are coupled to live operational entities.
2. Triggers encode business workflow logic (audit insertion) that belongs in explicit, testable code paths.
3. No single component owns the atomic delete transaction; storage, auth, and database deletions are split across layers.
4. No canonical delete framework exists; each module invents its own path.
5. No observable delete lifecycle exists; failures cannot be attributed to a step.
6. Foreign-key `ON DELETE` policies were chosen locally without a global risk model.

**SPEC-001-CTX-004.** The target architecture treats deletion as a reusable platform primitive. Every domain consumes the same pipeline, the same state machine, and the same observability contracts, while retaining domain-specific validation, dependency mapping, and side-effect handlers.

**SPEC-001-CTX-005.** The framework shall be technology-neutral: it may be realized through stored procedures, RPCs, edge functions, workflow engines, event buses, queues, saga orchestrators, or a combination thereof, provided the contracts and invariants defined in this specification are preserved.

---

## 16.6 Responsibilities

**SPEC-001-RES-001.** The responsibilities of each architectural layer in the Delete Framework are:

| Layer | Responsibility |
|---|---|
| Frontend | Render the delete action, request confirmation, capture user intent, prevent duplicate submission, display status and structured errors. |
| Service | Validate input, verify caller permissions, attach correlation identifiers, route to the canonical delete handler, return structured errors. |
| Edge / Routing | Authenticate and authorize the request, rate-limit, transform the request to the canonical format, invoke the database-owned delete pipeline, log request metadata. |
| Database | Own the delete transaction, enforce invariants, perform the actual row deletions, write audit intent, return step-level status, and roll back on failure. |
| Storage | Provide idempotent object removal and a list of removed objects for recovery. Storage cleanup shall not occur before the database transaction commits. |
| Audit | Record pre- and post-state snapshots immutably and independently of the operational entity lifecycle, as defined in SPEC-002. |
| Authentication | Verify the identity of the caller. |
| Authorization | Resolve roles and permissions before the delete transaction begins. |

**SPEC-001-RES-002.** Business workflow logic shall not be split between Edge Functions and triggers.

**SPEC-001-RES-003.** The database layer shall enforce integrity and invariants; it shall not perform authorization decisions.

**SPEC-001-RES-004.** The frontend layer shall request deletion and display consequences; it shall not decide whether a hard delete is permitted.

---

## 16.7 Architecture Principles Mapping

**SPEC-001-PRM-001.** The Delete Framework shall implement every principle of the Master Program as follows:

| Principle | Mapping to Delete Framework |
|---|---|
| Deletion is explicit | Every delete passes through the canonical delete API; no row is removed as a side effect of an unrelated operation. |
| Deletion is deterministic | The pipeline is centralized and free of hidden conditional branches; the same request with the same state yields the same actions. |
| Deletion is idempotent | The framework recognizes finality; replaying a completed or non-existent delete request returns a stable result without duplicate side effects. |
| Deletion is observable | Every request carries a correlation identifier and produces a step trace across all layers. |
| Deletion is recoverable | Failed or partially failed deletes roll back, retry, or provide explicit recovery guidance without data loss. |
| Audit is immutable | Delete audit records are append-only and independent of entity lifecycle, per SPEC-002. |
| Database owns integrity | The database layer owns the atomic transaction and referential-integrity enforcement, per SPEC-003 and SPEC-005. |
| Application owns workflow | Side-effect ordering and business decisions are owned by explicit application code, not triggers. |
| Platform before feature | Feature teams shall reuse the canonical delete framework; custom implementations are prohibited without exception. |
| Reuse before reinvention | Existing platform handlers shall be consumed before new ones are created. |
| Side effects are compensatable | External cleanup is idempotent or reversibly compensatable; the database transaction shall not wait on external systems. |
| Failure is a first-class state | Failed, rolled-back, retryable, and closed states are modeled explicitly in the delete state machine. |

---

## 16.8 Domain Model

**SPEC-001-DOM-001.** The Delete Framework domain consists of the following conceptual objects, each with a single responsibility:

| Concept | Responsibility |
|---|---|
| Delete Request | Captures intent: actor, target type, target identifier, deletion classification, correlation ID, timestamp, authorization context, and reason. |
| Delete Session | Binds a set of related delete requests and side effects for a single logical operation; provides isolation for bulk or cascade deletes. |
| Delete Transaction | Represents the atomic database boundary that commits or rolls back row-level changes; owned by the database layer. |
| Delete Pipeline | The ordered sequence of validation, preparation, execution, side-effect orchestration, and completion stages. |
| Delete State | The current lifecycle state of a delete operation. |
| Delete Result | The outcome returned to the caller: final state, affected resources, error code, recovery guidance, and next-step instructions. |
| Delete Recovery | The set of compensating actions, snapshots, and runbooks required to restore consistency after a failure. |
| Delete Audit | The immutable record of what was requested, what was done, and the pre- and post-states, per SPEC-002. |
| Delete Context | Ambient information: tenant, region, feature flags, legal hold status, retention policy, and correlation identifiers. |
| Delete Metadata | Additional structured information: classification, reason, approval references, and policy identifiers. |

**SPEC-001-DOM-002.** A `Delete Request` shall not perform deletions directly. It shall be consumed by the `Delete Pipeline`.

**SPEC-001-DOM-003.** A `Delete Transaction` shall be the only component that commits or rolls back row-level changes.

**SPEC-001-DOM-004.** A `Delete Session` may contain one or more `Delete Request` objects, but each `Delete Request` shall belong to exactly one `Delete Session`.

---

## 16.9 Components

**SPEC-001-COM-001.** The Delete Framework comprises the following logical components:

| Component | Role | Placement |
|---|---|---|
| Delete API | Presents the canonical delete interface to callers. | Service / Edge layer |
| Delete Orchestrator | Sequences pipeline stages and coordinates side-effect handlers. | Service / Edge layer |
| Delete Validator | Verifies caller authorization, target existence, classification eligibility, and dependency constraints. | Service and Database layers |
| Delete Transaction Owner | Owns the atomic database transaction; performs row deletions and enforces invariants. | Database layer |
| Side-Effect Handler Registry | Maintains the set of idempotent handlers for storage, auth, notification, billing, and external cleanup. | Service / Edge layer |
| Side-Effect Handler | Performs one type of external cleanup and provides compensation information. | Service / Edge or infrastructure layer |
| State Manager | Persists and transitions the delete state machine. | Database / persistence layer |
| Audit Writer | Records immutable delete audit events, per SPEC-002. | Database / persistence layer |
| Recovery Manager | Detects failures, triggers rollback or compensation, and emits recovery guidance. | Service / Operations layer |
| Observability Emitter | Emits structured logs, metrics, and traces tied to the correlation ID. | All layers |

**SPEC-001-COM-002.** The `Delete Transaction Owner` shall be the sole component that commits or rolls back the row-level delete transaction.

**SPEC-001-COM-003.** The `Side-Effect Handler Registry` shall allow handlers to be registered per domain and per classification without changing the core pipeline.

**SPEC-001-COM-004.** The `State Manager` shall persist every state transition with the previous state, new state, actor, timestamp, and reason.

---

## 16.10 Interfaces

**SPEC-001-INT-001.** The Delete Framework exposes the following abstract interfaces:

### 16.10.1 Delete Request Interface

| Attribute | Type | Description |
|---|---|---|
| `request_id` | UUID | Unique identifier for the delete request. |
| `correlation_id` | UUID | Propagated across all layers and audit records. |
| `actor_id` | Identity | The user or service that initiated the delete. |
| `actor_context` | Context | Tenant, role, authorization context, and IP/User-Agent metadata. |
| `target_type` | Domain name | The domain type of the target, for example Tenant, User, Product. |
| `target_id` | Identifier | The unique identifier of the target entity. |
| `classification` | Classification | One of the delete classifications defined in this specification. |
| `reason` | String | Human-readable reason for the delete. |
| `metadata` | Key-value map | Approval references, policy identifiers, legal hold flags, retention rules. |

### 16.10.2 Delete Result Interface

| Attribute | Type | Description |
|---|---|---|
| `request_id` | UUID | The originating request identifier. |
| `correlation_id` | UUID | The correlation identifier. |
| `final_state` | State | The terminal or intermediate state of the delete. |
| `affected_resources` | List | Domain identifiers and resource references affected by the delete. |
| `error_code` | Code | Structured error code, empty if successful. |
| `error_message` | String | Human-readable error description. |
| `recovery_guidance` | String | Instructions for recovery or retry, when applicable. |
| `next_steps` | List | Recommended actions for the caller. |

**SPEC-001-INT-002.** The Delete API shall accept a `Delete Request` and return a `Delete Result`.

**SPEC-001-INT-003.** The Side-Effect Handler Interface shall accept a `Delete Context` and a `Delete Request`; it shall return a status indicating success, idempotent already-done, or failure requiring compensation.

**SPEC-001-INT-004.** The Audit Writer Interface shall accept a `Delete Audit` record and persist it immutably, as defined in SPEC-002.

---

## 16.11 Contracts

**SPEC-001-CON-001.** The Delete Framework contracts are technology-neutral and implementation-neutral. Every implementation shall honor the following contracts:

### 16.11.1 Request Contract

**SPEC-001-CON-002.** Every delete request shall contain a unique `request_id`, a `correlation_id`, an identified actor, a target type, a target identifier, and a classification.

**SPEC-001-CON-003.** A delete request with an unrecognized classification shall be rejected before validation.

### 16.11.2 Authorization Contract

**SPEC-001-CON-004.** Authorization shall be resolved before the database transaction begins.

**SPEC-001-CON-005.** A caller without the required role or permission for the target classification shall receive a structured authorization error.

### 16.11.3 Transaction Contract

**SPEC-001-CON-006.** The database layer shall own exactly one atomic transaction per delete request or delete session.

**SPEC-001-CON-007.** The transaction shall commit only when all invariants, constraints, and row deletions defined by the domain contract succeed.

**SPEC-001-CON-008.** If any invariant fails, the transaction shall roll back completely and the target entity and its dependent data shall remain unchanged.

### 16.11.4 Side-Effect Contract

**SPEC-001-CON-009.** Side-effect handlers shall be idempotent.

**SPEC-001-CON-010.** Side-effect handlers shall not block the database transaction commit.

**SPEC-001-CON-011.** Side-effect failures shall be recorded in the delete state machine and shall trigger compensation or retry per the recovery model.

### 16.11.5 Audit Contract

**SPEC-001-CON-012.** The delete pipeline shall write at least one audit record for every delete request: the intent, the pre-state, and the outcome.

**SPEC-001-CON-013.** Audit records shall not hold foreign keys that prevent them from surviving the deletion of the target entity.

### 16.11.6 Idempotency Contract

**SPEC-001-CON-014.** Replaying a delete request for an already-deleted or non-existent target shall return a stable `Delete Result` without creating duplicate side effects or inconsistent state.

---

## 16.12 State Machine

**SPEC-001-STM-001.** Every delete operation shall move through the governed lifecycle defined in this section.

### 16.12.1 Happy Path

```
ACTIVE
  ↓ request validated
DELETE_REQUESTED
  ↓ caller authorized, classification resolved
VALIDATING
  ↓ invariants pass, dependencies surveyed
PREPARING
  ↓ pre-delete snapshot and audit intent recorded
TRANSACTION_STARTED
  ↓ database transaction opened
EXECUTING
  ↓ row deletions performed
SIDE_EFFECTS_PENDING
  ↓ external cleanups enqueued or completed
COMMITTING
  ↓ transaction committed
COMPLETED
```

### 16.12.2 Failure and Recovery Path

```
FAILED
  ↓ failure classified
ROLLBACK
  ↓ transaction rolled back or compensations triggered
RECOVERABLE
  ↓ operator intervention or data correction applied
RETRYABLE
  ↓ conditions for retry satisfied
DELETE_REQUESTED or CLOSED
```

### 16.12.3 Transition Rules

| From | To | Guard | Owner | Action |
|---|---|---|---|---|
| ACTIVE | DELETE_REQUESTED | Target exists and caller is authenticated | Service / Edge | Create delete request, assign correlation ID. |
| DELETE_REQUESTED | VALIDATING | Authorization resolved | Service | Verify permissions and classification. |
| VALIDATING | PREPARING | Invariants satisfied | Database / Domain Logic | Survey dependencies and record pre-state. |
| PREPARING | TRANSACTION_STARTED | Pre-state snapshotted and audit intent written | Database | Open atomic transaction. |
| TRANSACTION_STARTED | EXECUTING | Transaction owner confirmed | Database | Perform deletions inside transaction. |
| EXECUTING | SIDE_EFFECTS_PENDING | Row deletions complete | Database | Commit database transaction. |
| SIDE_EFFECTS_PENDING | COMMITTING | External side effects idempotently triggered | Application / Outbox | Enqueue or execute storage, auth, notification cleanup. |
| COMMITTING | COMPLETED | Side effects acknowledged or compensatable | Application | Record completion and final audit. |
| Any failure state | FAILED | Guard or invariant fails | Pipeline | Halt, preserve state, emit structured error. |
| FAILED | ROLLBACK | Recovery path identified | Transaction Owner | Roll back transaction or trigger compensations. |
| ROLLBACK | RECOVERABLE | Manual correction available | Operations | Operator remediates root cause. |
| RECOVERABLE | RETRYABLE | Preconditions restored | Operator / Automation | Validate that retry is safe. |
| RETRYABLE | DELETE_REQUESTED or CLOSED | Retry exhausted or success | Pipeline | Restart at the appropriate state or close as unrecoverable. |

**SPEC-001-STM-002.** States are terminal when they are `COMPLETED`, `CLOSED`, or a final error classification.

**SPEC-001-STM-003.** Every transition shall be logged with previous state, new state, actor, timestamp, and reason.

---

## 16.13 Workflow

**SPEC-001-WFL-001.** The canonical delete workflow consists of the following high-level stages:

1. **Request** — Caller submits a `Delete Request` with target, classification, and context.
2. **Authenticate** — The system verifies the caller identity.
3. **Authorize** — The system resolves roles and permissions for the requested classification.
4. **Validate** — The system checks target existence, classification eligibility, dependency constraints, and invariants.
5. **Prepare** — The system records pre-delete snapshots and writes the delete intent audit record.
6. **Transact** — The database layer opens the atomic transaction and performs row deletions.
7. **Commit** — The database layer commits the transaction if all invariants pass.
8. **Orchestrate Side Effects** — The system invokes idempotent handlers for storage, auth, notification, billing, and external cleanup.
9. **Complete** — The system records the final audit, emits observability events, and returns a `Delete Result`.

**SPEC-001-WFL-002.** If any stage from Validate through Commit fails, the workflow shall transition to `FAILED` and the recovery model shall apply.

**SPEC-001-WFL-003.** Side-effect handlers shall execute only after the database transaction commits.

**SPEC-001-WFL-004.** The workflow shall support both single-target and bulk-target requests through the `Delete Session` abstraction.

---

## 16.14 Sequence

**SPEC-001-SEQ-001.** The critical path for a hard delete of a single tenant or similar top-level entity shall follow this sequence:

```
Frontend
  → Service: submit Delete Request with correlation ID
    → Edge / Routing: authenticate, authorize, rate-limit
      → Database / Delete Transaction Owner: validate invariants
        → Database / Delete Transaction Owner: snapshot pre-state
          → Database / Delete Transaction Owner: write delete intent audit
            → Database / Delete Transaction Owner: open atomic transaction
              → Database / Delete Transaction Owner: perform row deletions
                → Database / Delete Transaction Owner: commit transaction
                  → Side-Effect Handler Registry: invoke idempotent handlers
                    → Storage: remove objects
                    → Auth: remove or orphan identities
                    → Notifications: cancel pending messages
                    → Billing: close or transfer accounts
                  → Database / Audit Writer: write completion audit
                    → State Manager: transition to COMPLETED
                      → Observability Emitter: emit structured log and metric
                        → Edge / Routing: return Delete Result
```

**SPEC-001-SEQ-002.** If validation fails before the transaction opens, the system shall return a structured error and no state transition beyond `FAILED` shall occur.

**SPEC-001-SEQ-003.** If the database transaction fails, the system shall roll back and the pre-delete state shall be preserved.

**SPEC-001-SEQ-004.** If a side-effect handler fails after commit, the delete state shall transition to `SIDE_EFFECTS_PENDING` or `FAILED` and compensation or retry shall be initiated without rolling back the database transaction.

---

## 16.15 Data Model

**SPEC-001-DAT-001.** The Delete Framework data model is logical and conceptual. It does not prescribe physical table names, column types, or storage engines.

### 16.15.1 Core Entities

| Entity | Attributes | Ownership |
|---|---|---|
| Delete Request | request_id, correlation_id, actor, target_type, target_id, classification, reason, metadata | Application / Service |
| Delete Session | session_id, request_ids, status, created_at | Application / Service |
| Delete State | request_id, state, previous_state, actor, timestamp, reason | State Manager / Database |
| Delete Audit | request_id, correlation_id, action, actor, target_type, target_id, pre_state, post_state, timestamp | Audit Writer / Database |
| Delete Recovery | request_id, failure_code, compensation_action, recovery_guidance, operator_notes | Recovery Manager / Database |

### 16.15.2 Data Ownership

**SPEC-001-DAT-002.** The application layer owns the `Delete Request` and `Delete Session`.

**SPEC-001-DAT-003.** The database layer owns the `Delete State`, `Delete Audit`, and `Delete Recovery` persistence.

**SPEC-001-DAT-004.** The `Delete Audit` entity shall be independent of operational entity lifecycles, per SPEC-002.

### 16.15.3 Retention

**SPEC-001-DAT-005.** Delete audit records shall be retained according to the retention policy defined in SPEC-002, not tied to the retention of the deleted operational entity.

**SPEC-001-DAT-006.** Recovery records shall be retained until the delete operation reaches a terminal state or is explicitly closed by an operator.

---

## 16.16 Failure Model

**SPEC-001-FAM-001.** The following failure modes are in scope for the Delete Framework:

| ID | Failure Mode | Likelihood | Impact | Detection |
|---|---|---|---|---|
| SPEC-001-FAM-001 | Authorization failure before transaction | Medium | Low | Service/Edge layer returns structured error. |
| SPEC-001-FAM-002 | Invariant or foreign-key violation during transaction | Medium | High | Database transaction aborts and returns error. |
| SPEC-001-FAM-003 | Side-effect handler fails after commit | Low | High | Handler returns failure; state machine transitions to `SIDE_EFFECTS_PENDING` or `FAILED`. |
| SPEC-001-FAM-004 | State transition lost or corrupted | Low | Critical | State Manager consistency check fails on next read. |
| SPEC-001-FAM-005 | Audit write fails | Low | High | Audit Writer returns error; transaction rolls back or is marked for retry per SPEC-002. |
| SPEC-001-FAM-006 | Duplicate request submitted | Medium | Medium | Idempotency check returns stable result. |
| SPEC-001-FAM-007 | Bulk delete partially completes | Low | High | Per-batch state tracking detects incomplete session. |
| SPEC-001-FAM-008 | Recovery action itself fails | Low | Critical | Recovery Manager emits alert and escalates. |

**SPEC-001-FAM-009.** Every failure mode shall have a corresponding recovery action defined in the Recovery Model.

**SPEC-001-FAM-010.** Failures shall not return generic HTTP 500 responses without a structured error code, correlation ID, and recovery guidance.

---

## 16.17 Recovery Model

**SPEC-001-RCM-001.** The Delete Framework recovery model shall handle each failure mode:

| Failure Mode | Recovery Action | Owner |
|---|---|---|
| Authorization failure | Return structured error; no state change. | Service / Edge |
| Invariant or FK violation | Roll back transaction; return error with guidance; set state `FAILED` then `ROLLBACK`. | Database / Transaction Owner |
| Side-effect handler failure | Record failure; retry with backoff; compensate if handler supports it; escalate if unrecoverable. | Side-Effect Handler Registry |
| State transition lost | Reconcile from audit and request logs; emit alert. | State Manager |
| Audit write failure | Roll back transaction or queue audit retry per SPEC-002 contract. | Audit Writer |
| Duplicate request | Return idempotent stable result. | Delete Orchestrator |
| Bulk delete partial failure | Roll back completed batches or mark session `RECOVERABLE`; per-batch compensation. | Bulk Handler |
| Recovery action failure | Escalate to operations; preserve state; create incident record. | Recovery Manager |

**SPEC-001-RCM-002.** The recovery model shall prefer rollback to compensation when the database transaction has not committed.

**SPEC-001-RCM-003.** When compensation is required, compensating actions shall be idempotent and shall record both the attempted action and the compensation.

**SPEC-001-RCM-004.** Manual operator recovery shall be supported through a `RECOVERABLE` state with explicit guidance, not through ad-hoc database edits.

---

## 16.18 Security

**SPEC-001-SEC-001.** Every delete request shall be authenticated and authorized before validation.

**SPEC-001-SEC-002.** Role-based access control shall enforce the principle that only authorized actors may initiate a given delete classification. For example, hard deletes of tenants shall require system administrator or tenant owner authorization.

**SPEC-001-SEC-003.** The database layer shall enforce row-level and tenant-level isolation through the canonical authorization context; it shall not trust the application layer for isolation decisions.

**SPEC-001-SEC-004.** Delete audit records shall contain the actor, authorization context, source IP, and User-Agent to support forensic review.

**SPEC-001-SEC-005.** The framework shall resist replay attacks by validating `request_id` uniqueness and idempotency keys.

**SPEC-001-SEC-006.** Bulk delete shall require an explicit approval reference or elevated authorization, as defined in the classification rules.

**SPEC-001-SEC-007.** Emergency delete shall require post-hoc review and shall be auditable with an incident identifier and emergency approver.

---

## 16.19 Observability

**SPEC-001-OBS-001.** Every delete request shall emit structured observability data:

| Type | Requirement |
|---|---|
| Logs | Structured log per workflow stage, containing `request_id`, `correlation_id`, `target_type`, `target_id`, `actor`, `state`, and any error code. |
| Metrics | Counter for deletes initiated, completed, failed, retried, and compensated, partitioned by domain and classification. |
| Traces | Distributed trace following the delete correlation ID across frontend, service, edge, database, storage, auth, and billing. |
| Alerts | Alert on sustained delete failure rate, partial delete detection, or recovery-action failure. |
| Dashboards | Dashboard showing delete lifecycle throughput, failure rate, recovery time, and audit completeness. |

**SPEC-001-OBS-002.** The observability layer shall enable operators to reconstruct the full lifecycle of any delete request from `request_id` or `correlation_id` without querying the production database directly.

**SPEC-001-OBS-003.** All failure states shall include structured error codes and recovery guidance suitable for support staff and compliance reviewers.

---

## 16.20 Risks

**SPEC-001-RSK-001.** The following risks are introduced or mitigated by the Delete Framework:

| ID | Risk | Likelihood | Impact | Owner | Mitigation |
|---|---|---|---|---|---|
| SPEC-001-RSK-001 | A new domain bypasses the canonical framework and invents a local delete path. | Medium | High | Chief Technical Advisor | Mandatory architecture review and framework onboarding for every new domain. |
| SPEC-001-RSK-002 | A side-effect handler is not idempotent and duplicates cleanup or deletes wrong objects. | Medium | High | Platform Engineering | Handler contract review, idempotency tests, and handler registry validation. |
| SPEC-001-RSK-003 | The database transaction holds locks for too long during large tenant deletes. | Medium | High | Database Architecture | Batch sizing, advisory locks, and timeout governance per SPEC-003. |
| SPEC-001-RSK-004 | Audit records fail to outlive the deleted entity due to residual foreign keys. | Low | Critical | Security & Compliance | SPEC-002 audit independence validation and FK review per SPEC-005. |
| SPEC-001-RSK-005 | Recovery actions are not exercised and fail during an incident. | Medium | High | SRE / Platform Operations | Regular failure-recovery drills and automated recovery tests. |
| SPEC-001-RSK-006 | Bulk delete fails midway, leaving a partially deleted session. | Low | High | Platform Engineering | Per-batch state tracking and session-level rollback or compensation. |
| SPEC-001-RSK-007 | Classification rules are ambiguous and produce inconsistent behavior. | Low | Medium | Domain Architecture | Documented classification matrix and classification validation gate. |

---

## 16.21 Constraints

**SPEC-001-CST-001.** The Delete Framework shall operate within the following constraints:

| ID | Constraint | Source |
|---|---|---|
| SPEC-001-CST-001 | The framework shall be technology-neutral and shall not assume any specific database, runtime, or workflow engine. | Architecture Specification Program Section 18. |
| SPEC-001-CST-002 | The framework shall depend on SPEC-002, SPEC-003, and SPEC-005 being baselined before it may be approved. | Architecture Specification Index Section 6.2. |
| SPEC-001-CST-003 | The framework shall not place business workflow logic inside database triggers. | Master Program Guiding Principle 3. |
| SPEC-001-CST-004 | The database transaction shall not be blocked by external side effects. | Master Program Principle: Side effects are compensatable. |
| SPEC-001-CST-005 | Audit records shall be immutable and shall outlive the entity they describe. | Master Program Guiding Principle 2. |
| SPEC-001-CST-006 | Every in-scope domain listed in Section 16.3 shall consume the canonical framework. | Master Program Section 9. |
| SPEC-001-CST-007 | Failure responses shall be structured and shall include correlation IDs and recovery guidance. | Master Program Success Criteria. |

---

## 16.22 Non-goals

**SPEC-001-NGO-001.** This specification explicitly does not cover:

1. Implementation code, file names, package structures, or deployment commands.
2. Concrete RPC signatures, GraphQL mutations, REST endpoints, or database table schemas.
3. Specific technology choices such as a particular workflow engine, queue, or saga framework.
4. User-interface copy, confirmation modals, or visual design.
5. Billing, payment, or e-invoice provider-specific cancellation logic beyond the side-effect handler contract.
6. Data-retention legal hold policy details, which belong in SPEC-002 and compliance documentation.
7. Migration scripts for moving from legacy delete paths to the canonical framework, which belong in a Migration Specification or Implementation Plan.
8. Day-to-day operational runbooks, which belong in Operational Specifications.

---

## 16.23 Verification Requirements

**SPEC-001-VRF-001.** The Delete Framework implementation shall be verified against the following requirements:

| ID | Verification Requirement | Method |
|---|---|---|
| SPEC-001-VRF-001 | Every in-scope domain uses the canonical delete API. | Static code review and governance audit. |
| SPEC-001-VRF-002 | Delete state machine transitions match Section 16.12. | State-transition unit tests. |
| SPEC-001-VRF-003 | Database transaction rollback restores pre-delete state. | Transaction failure-injection tests. |
| SPEC-001-VRF-004 | Side-effect handlers are idempotent. | Replay tests against each handler. |
| SPEC-001-VRF-005 | Audit records are written for every delete request and survive entity deletion. | Database tests and audit immutability checks. |
| SPEC-001-VRF-006 | Replaying a completed delete returns a stable result without duplicate side effects. | Idempotency integration tests. |
| SPEC-001-VRF-007 | Structured errors include correlation ID and recovery guidance. | Error-response contract tests. |
| SPEC-001-VRF-008 | Bulk delete supports per-batch state tracking and session-level recovery. | Bulk delete integration tests. |
| SPEC-001-VRF-009 | Every failure mode in Section 16.16 has a recovery test. | Failure-recovery test matrix. |
| SPEC-001-VRF-010 | Delete observability emits logs, metrics, and traces with the correlation ID. | Observability integration tests. |

---

## 16.24 Acceptance Criteria

**SPEC-001-ACC-001.** The Delete Framework specification and its implementation are accepted when:

1. All mandatory sections are present and reviewed.
2. All requirements carry unique identifiers and are traceable to verification requirements and acceptance criteria.
3. The implementation passes all verification requirements in Section 16.23.
4. No in-scope domain contains an independent delete implementation outside the canonical framework.
5. The `delete-tenant` pilot domain succeeds end-to-end without HTTP 500 and with complete audit records.
6. Rollback and recovery tests demonstrate that failed deletes leave the system in a consistent, pre-delete state.
7. Side-effect handlers demonstrate idempotency under replay.
8. Observability dashboards and alerts are operational.
9. The Production Owner approves the specification and the implementation.

---

## 16.25 Future Evolution

**SPEC-001-FEV-001.** The Delete Framework is designed to evolve without redesign. The following extension points are preserved:

| Extension | Description |
|---|---|
| New domains | New deletable domains shall register with the framework by providing a domain adapter, validator, and side-effect handlers. |
| New classifications | New delete classifications shall be added through the classification registry and the state machine transition table. |
| New side-effect handlers | New handlers shall be registered in the Side-Effect Handler Registry without modifying the core pipeline. |
| Workflow engines | The pipeline may be migrated to a workflow engine, saga orchestrator, or event bus without changing the state machine or contracts. |
| Multi-region | The framework shall support region-aware deletes by including region in the `Delete Context`. |
| Long-term audit archives | Audit records may be cold-archived after a retention period without altering the framework semantics. |

**SPEC-001-FEV-002.** Any change that adds, removes, or reclassifies a delete classification shall require an Architecture Decision Record per the Master Program Section 29.

---

## 16.26 Appendix

### A. Delete Classification Matrix

| Classification | Purpose | Lifecycle | Recovery | Audit Requirement |
|---|---|---|---|---|
| Soft Delete | Mark deleted without removing rows. | Active → Soft-Deleted → Restored or Purged. | Reversible by restoration. | Record who deleted and when; retain full pre-state. |
| Hard Delete | Permanently remove entity and owned data. | Active → Requested → Validated → Executed → Completed. | Not recoverable once committed; snapshot may be archived. | Record full pre-state snapshot and authorization. |
| Archive | Move entity and history to archive domain. | Active → Archived → Restored or Expunged. | Restorable from archive until retention expires. | Retain provenance and archive location. |
| Logical Delete | Change status flag so entity is no longer visible. | Active → Logically Deleted → Restored. | Reversible by status change. | Record status transition and actor. |
| Physical Delete | Remove underlying storage representation. | Active → Executed → Purged. | Not recoverable without backup. | Record hash or reference of removed object. |
| Purge | Remove previously soft-deleted or archived data. | Soft-Deleted / Archived → Purged. | Not recoverable. | Record retention policy basis and purge authorization. |
| Retention Delete | Delete data automatically when retention expires. | Active / Archived → Retention-Reviewed → Deleted. | Not recoverable; legal hold may block. | Record retention schedule and hold status. |
| Compliance Delete | Delete data to satisfy legal/regulatory/privacy request. | Requested → Legal Review → Authorized → Executed. | Not recoverable; may require certificate. | Record request identifier, approver, and certificate. |
| Emergency Delete | Rapidly remove data to contain an incident. | Detected → Emergency Authorized → Executed. | May require post-incident review and restore from backup. | Record incident ID, emergency approver, and justification. |
| Bulk Delete | Remove a large set of entities under a single session. | Requested → Validated → Batched → Executed → Verified. | Roll back entire batch or per-batch compensation. | Record batch identifier, scope, and completion status. |

### B. Domain Delete Dependency Matrix

| Domain | Depends On | Deletion Impact |
|---|---|---|
| Tenant | Membership, Storage, Subscription, Audit, Auth, Notification, Billing | Removing a tenant cascades through membership entitlements, storage objects, active subscriptions, audit history, auth identities, pending notifications, and billing records. |
| User | Tenant, Membership, Subscription, Audit, Auth, Notification | Deleting a user requires resolving tenant membership, active subscriptions, audit history, auth identity, and notification preferences. |
| Product | Tenant, Warehouse, Subscription, Audit, Billing | Product deletion affects tenant catalog, warehouse stock references, subscription line items, audit history, and billing records. |
| Customer | Tenant, Subscription, Audit, Billing, Notification | Customer deletion requires handling active subscriptions, immutable audit, billing accounts, and notification subscriptions. |
| Warehouse | Tenant, Product, Employee, Audit | Warehouse removal must reconcile product stock, employee assignments, and audit history. |
| Employee | Tenant, Warehouse, Subscription, Audit, Auth | Employee deletion affects warehouse assignments, subscription ownership, audit history, and auth identity. |
| Membership | Tenant, User, Subscription, Audit | Membership deletion is constrained by tenant, user, and subscription relationships. |
| Subscription | Tenant, User, Customer, Product, Billing, Audit | Subscription deletion must settle billing, update product entitlements, and record audit history. |

### C. Glossary

| Term | Definition |
|---|---|
| Delete Request | A structured intent to delete a target entity with a classification and context. |
| Delete Session | A logical grouping of related delete requests and side effects. |
| Delete Pipeline | The ordered stages through which a delete request flows. |
| Delete Transaction Owner | The component that owns the atomic database transaction for a delete. |
| Side-Effect Handler | An idempotent component that performs external cleanup after the database transaction commits. |
| Delete State | A named lifecycle stage of a delete operation. |
| Delete Audit | The immutable record of a delete operation and its effects. |
| Classification | The category of deletion that determines lifecycle, recovery, and audit rules. |

### D. Traceability Summary

| This Specification Section | Traces To |
|---|---|
| 16.2 Purpose | Master Program Sections 1, 2, 3, 7, 8 |
| 16.3 Scope | Master Program Section 9 |
| 16.5 Architecture Context | Master Program Sections 4, 5, 6, 22 |
| 16.6 Responsibilities | Master Program Section 10.6 |
| 16.7 Architecture Principles Mapping | Master Program Section 23 |
| 16.8 Domain Model | Master Program Section 24 |
| 16.12 State Machine | Master Program Section 25 |
| 16.13 Workflow | Master Program Section 10.6 |
| 16.14 Sequence | Master Program Sections 10.1, 10.6 |
| 16.16 Failure Model | Master Program Section 28 |
| 16.17 Recovery Model | Master Program Sections 10.7, 28 |
| 16.19 Observability | Master Program Section 10.8 |
| 16.23 Verification Requirements | Master Program Section 20 |
| 16.24 Acceptance Criteria | Master Program Section 13, 14 |

---

## Evidence

### E.1 Foundation Documents Consulted

The following foundation documents were read and followed:

1. `.codebase-memory/CODEBASE_MEMORY_BASELINE.md` — Project baseline, stack, validation status, knowledge priority.
2. `.codebase-memory/SEMANTIC_MEMORY.md` — Architecture overview, business modules, tenant lifecycle, deletion patterns.
3. `.codebase-memory/VALIDATION_REPORT.md` — Confidence scores, known limitations, corrections.

### E.2 Governance Documents Consulted

The following governance documents were read in the required order:

1. `Deletion_Audit_Architecture_Remediation_Program.md` (Master Program v1.0) — Vision, principles, goals, workstreams, scope, state machine, domain model, classification, dependency matrix, risks, success criteria.
2. `01_Governance/Architecture_Specification_Program.md` (Specification Program v1.1) — Mandatory template (Sections 16.1–16.26), metadata, versioning, naming, folder structure, traceability, dependency, quality gates.
3. `01_Governance/ARCHITECTURE_SPECIFICATION_INDEX.md` (Index v1.1) — SPEC-001 registration, classification, dependencies, portfolio position, authoring order.

### E.3 Cross-Validation Results

| Check | Result |
|---|---|
| SPEC-001 exists inside the Index | ✓ Found in Index Section 5.2 and Catalog Summary Table. |
| Specification ID matches | ✓ SPEC-001 in both Index and this specification. |
| Specification Name matches | ✓ "Delete Framework Architecture Specification" in both. |
| Classification matches | ✓ Core. |
| Dependencies match | ✓ Mandatory: SPEC-002, SPEC-003, SPEC-005. |
| Authoring order matches | ✓ SPEC-001 is #4 in recommended sequence, after foundation dependencies. |
| Workstream matches Master Program | ✓ Delete Framework Redesign (Master Program Section 10.1). |
| Scope matches Master Program | ✓ Domains: Tenant, User, Product, Customer, Warehouse, Employee, Membership, Subscription. |
| Required template matches | ✓ All 26 mandatory sections of the Specification Program are present. |
| Governance version consistent | ✓ Master Program v1.0, Spec Program v1.1, Index v1.1. |

**No inconsistencies were detected. No `GOVERNANCE_INCONSISTENCY_REPORT.md` is required.**

### E.4 Extracted Governance Summary

- **Mandatory template:** 26 sections (16.1–16.26) per the Architecture Specification Program.
- **Normative language:** Requirements use `shall`, `must`, `must not`, `should`, `may`.
- **Technology neutral:** No product-specific or framework-specific implementation details.
- **Traceability:** Requirement identifiers use `SPEC-001-<SECTION>-<NNN>`.
- **Dependencies:** SPEC-001 is Core, depends on SPEC-002, SPEC-003, SPEC-005.
- **Approval flow:** Author → Chief Technical Advisor Review → Production Owner Approval → Baseline.
- **Status model:** Draft → Review → Approved → Baselined → Implementation Ready → Implementation Active → Verified → Accepted.

### E.5 Portfolio Validation

- SPEC-001 is registered in the Architecture Specification Index.
- Classification: Core.
- Priority: P1 — Critical.
- Target folder: `02_Specifications/`.
- Dependency graph is acyclic; SPEC-001 depends on foundation Specifications SPEC-002, SPEC-003, SPEC-005, and is depended on by SPEC-004, SPEC-006, SPEC-007.

### E.6 Dependency Validation

- Mandatory dependencies declared: SPEC-002, SPEC-003, SPEC-005.
- Dependency target versions are marked as `TBD` because the target Specifications are in `Planned` status in the Index. The Specification Program Section 34.5 permits noting an expected version and fallback; this specification states the dependency as `TBD` with the understanding that SPEC-001 cannot be approved until the dependencies are baselined.
- No circular dependencies are introduced.

### E.7 Template Compliance

Every mandatory section from the Architecture Specification Program is present:

1. Metadata
2. Purpose
3. Scope
4. References
5. Architecture Context
6. Responsibilities
7. Architecture Principles Mapping
8. Domain Model
9. Components
10. Interfaces
11. Contracts
12. State Machine
13. Workflow
14. Sequence
15. Data Model
16. Failure Model
17. Recovery Model
18. Security
19. Observability
20. Risks
21. Constraints
22. Non-goals
23. Verification Requirements
24. Acceptance Criteria
25. Future Evolution
26. Appendix

### E.8 Traceability Summary

- All requirements are uniquely identified with `SPEC-001-<SECTION>-<NNN>`.
- All sections trace to the Master Program or related specifications.
- Verification requirements trace to acceptance criteria.
- Failure modes trace to recovery actions.
- Risks trace to mitigations.
- Cross-references to SPEC-002, SPEC-003, SPEC-005 use identifier and version reference style.

### E.9 Risk Assessment

- The primary residual risk is that foundation dependencies (SPEC-002, SPEC-003, SPEC-005) are not yet baselined, which blocks SPEC-001 approval per the Dependency Framework.
- The secondary risk is that future domains may attempt to bypass the canonical framework; this is mitigated by mandatory architecture review and governance audits.
- No implementation, database, or deployment risks are introduced by this specification alone.

### E.10 Confirmation

- **No implementation performed.**
- **No repository source code modified.**
- **No database schema, migrations, RPC, or Edge Functions modified.**
- **No API, workflow, permissions, or business logic modified.**
- **No commit performed.**
- **No push performed.**
- **No deployment performed.**

---

*End of SPEC-001 — Delete Framework Architecture Specification v1.1*
