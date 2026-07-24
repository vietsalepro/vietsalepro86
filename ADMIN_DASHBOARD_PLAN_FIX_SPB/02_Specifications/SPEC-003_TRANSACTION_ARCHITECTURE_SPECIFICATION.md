# SPEC-003 — Transaction Architecture Specification

**Project:** VietSalePro  
**Subsystem:** Admin Dashboard / Enterprise Architecture  
**Specification Name:** Transaction Architecture Specification  
**Short Identifier:** TransactionArchitecture  
**Specification ID:** SPEC-003  
**Classification:** Core  
**Status:** Baselined  
**Version:** 1.0  
**Effective Date:** 2026-07-24  
**Author:** Engineering Execution Agent  
**Technical Custodian:** Chief Technical Advisor (Architecture Governance)  
**Final Owner:** Production Owner  
**Approvers:** Chief Technical Advisor, Production Owner  
**Baseline Approved By:** Chief Technical Advisor (delegated by Production Owner)  
**Baseline Date:** 2026-07-24  
**Master Program Reference:** Deletion & Audit Architecture Remediation Program v1.0  
**Related Specifications:** SPEC-001 Delete Framework (dependent on SPEC-003), SPEC-002 Audit Architecture (optional)  
**Related ADRs:** None recorded.  
**Roadmap Items:** None recorded.  

---

## 16.1 Metadata

This specification is the authoritative architecture definition for the **Transaction Architecture** of VietSalePro. It is a **Core** specification that establishes the atomicity model, transaction boundary ownership, side-effect coordination, and recovery model that the Delete Framework and all other multi-step business operations shall operate within. Its identifier is `SPEC-003`; its short identifier is `TransactionArchitecture`; its version is `1.0`.

| Field | Value |
|---|---|
| Project | VietSalePro |
| Subsystem | Admin Dashboard / Enterprise Architecture |
| Specification ID | SPEC-003 |
| Name | Transaction Architecture Specification |
| Short Identifier | TransactionArchitecture |
| Classification | Core |
| Status | Baselined |
| Version | 1.0 |
| Effective Date | 2026-07-24 |
| Author | Engineering Execution Agent |
| Technical Custodian | Chief Technical Advisor (Architecture Governance) |
| Final Owner | Production Owner |
| Approvers | Chief Technical Advisor, Production Owner |
| Baseline Approved By | Chief Technical Advisor (delegated by Production Owner) |
| Baseline Date | 2026-07-24 |
| Master Program | Deletion & Audit Architecture Remediation Program v1.0 |
| Related Specifications | SPEC-001 Delete Framework (dependent on SPEC-003), SPEC-002 Audit Architecture (optional) |
| Related ADRs | None recorded |
| Roadmap Items | None recorded |

---

## 16.2 Purpose

**SPEC-003-PUR-001.** This document defines the enterprise Transaction Architecture for VietSalePro.

**SPEC-003-PUR-002.** The Transaction Architecture shall establish a single, technology-neutral model for atomic business operations across all tenant-scoped and platform-scoped domains, ensuring that multi-step mutations either complete fully or leave the system in a consistent, recoverable state.

**SPEC-003-PUR-003.** The Transaction Architecture shall provide the atomicity and side-effect coordination foundation required by SPEC-001 (Delete Framework) for its transaction contract, failure model, recovery model, and observability.

**SPEC-003-PUR-004.** The Transaction Architecture shall define the ownership of the transaction boundary, the role of the transaction coordinator, the relationship between database transactions and external side effects, and the patterns for compensating actions, outbox delivery, sagas, idempotency, and retry without prescribing implementation code, file names, operational rollout instructions, or data-definition statements.

**SPEC-003-PUR-005.** This specification shall not prescribe a specific database, runtime, workflow engine, messaging broker, or programming language. Those choices are governed by implementation plans derived from this specification and by the Architecture Specification Program constraints on technology neutrality.

---

## 16.3 Scope

**SPEC-003-SCO-001.** This specification covers the conceptual Transaction Architecture and its canonical model for all business operations in VietSalePro that require atomicity, consistency, isolation, durability, or coordination across multiple steps, resources, or services.

**SPEC-003-SCO-002.** The following transaction concerns are explicitly covered by this specification:

- Transaction ownership and the single owner of each transaction boundary;
- Transaction lifecycle, context, scope, and state model;
- Atomicity, consistency, isolation, and durability (ACID) invariants;
- Commit model, rollback model, and partial-failure handling;
- Nested transaction principles and savepoint semantics;
- Distributed transaction principles, two-phase and saga coordination patterns;
- Transaction coordinator, side-effect coordination, outbox pattern, compensation pattern, and saga pattern;
- Idempotency, retry model, failure classification, and recovery model;
- Timeout model, long-running transaction governance, and concurrency controls;
- Ordering guarantees, transaction integrity, and cross-service coordination;
- Interaction with the Audit Architecture (SPEC-002), Delete Framework (SPEC-001), trigger governance, and foreign-key governance;
- Security, compliance, observability, risks, constraints, verification requirements, and acceptance criteria.

**SPEC-003-SCO-003.** The Transaction Architecture shall define how the database transaction boundary is separated from external side effects, how side effects are made reliable through an outbox or compensating-action model, and how failures are classified into recoverable, retryable, and unrecoverable categories with explicit recovery guidance.

**SPEC-003-SCO-004.** This specification does not define internal schemas, function signatures, operational rollout artifacts, or any concrete implementation of a particular database, messaging system, or workflow engine. Those details belong in Implementation Plans derived from this specification.

**SPEC-003-SCO-005.** Future business operations introduced after initial implementation shall consume the canonical Transaction Architecture at design time; they shall not introduce independent transaction semantics or split transaction ownership across layers.

---

## 16.4 References

**SPEC-003-REF-001.** The following normative references govern this specification:

| Identifier | Title | Version | Purpose |
|---|---|---|---|
| Master Program | Deletion & Audit Architecture Remediation Program | v1.0 | Program vision, principles, workstreams, and scope; transaction ownership workstream (Section 10) |
| SPEC-001 | Delete Framework Architecture Specification | v1.1 (dependent) | Consumes SPEC-003 transaction contracts (CON-006, CON-007), failure model, recovery model, and verification requirements |
| SPEC-002 | Audit Architecture Specification | v1.0 (optional dependency) | Audit-before-commit and audit-after-commit interactions; immutable audit records for transaction lifecycle |
| SPEC-005 | Foreign Key Governance Specification | TBD (optional) | Explicit referential-integrity rules ensuring transaction boundaries respect `ON DELETE` policies |
| SPEC-004 | Trigger Governance Specification | TBD (related) | Trigger classification; low-level invariant triggers do not encode transaction workflow logic |
| SPEC-006 | Observability Specification | TBD (related) | Observability instrumentation for transaction lifecycle and outbox processing |
| SPEC-007 | Regression & Verification Specification | TBD (related) | Regression coverage for transaction rollback, recovery, and side-effect idempotency |

---

## 16.5 Architecture Context

**SPEC-003-CTX-001.** The VietSalePro platform currently performs multi-step business operations (checkout, return, exchange, inventory movement, supplier exchange, import, disposal, member invitation, tenant creation, and tenant deletion) through a mixture of direct data access, remote procedures, and ad-hoc coordination. Many operations are wrapped in a single database transaction, but external side effects (storage removal, message delivery, billing provider calls, identity cleanup) are not uniformly governed.

**SPEC-003-CTX-002.** The `delete-tenant` HTTP 500 incident demonstrated the failure pattern: an attempt to write an audit row inside an `AFTER DELETE` database trigger created a referential-integrity failure within the same database transaction, which aborted the transaction and surfaced as an unhandled error. The underlying cause was not a one-line defect; it was the absence of a clear transaction boundary, a single transaction owner, and a side-effect coordination model that separates database state changes from post-commit cleanup.

**SPEC-003-CTX-003.** The underlying architectural deficiencies exposed by that incident and related workflows are:

1. Transaction ownership is split across the frontend, service, routing, and database layers, so no single component decides when to commit, roll back, or compensate.
2. External side effects are triggered directly from within database transactions or from procedural code without an outbox or compensating-action pattern, making partial failures hard to recover.
3. Audit writes are performed by database triggers rather than by an explicit, testable transaction participant, coupling audit lifecycle to database-level side effects.
4. There is no uniform timeout, retry, or idempotency model for operations that cross resource boundaries.
5. Long-running and distributed operations lack a state model, so failures cannot be classified, retried, or compensated consistently.
6. Foreign-key and trigger interactions with transactions are not reviewed as architecture, leading to hidden workflow logic inside low-level mechanisms.

**SPEC-003-CTX-004.** The target architecture treats transaction ownership and side-effect coordination as platform capabilities. Every multi-step operation shall flow through a transaction coordinator that owns the boundary, enforces ACID invariants inside the boundary, and coordinates external side effects through an outbox or compensating-action model outside the critical commit path.

**SPEC-003-CTX-005.** The Transaction Architecture shall be technology-neutral: it may be realized through stored procedures, remote procedures, workflow engines, message brokers, outbox tables, saga orchestrators, or a combination thereof, provided the contracts and invariants defined in this specification are preserved.

---

## 16.6 Responsibilities

**SPEC-003-RES-001.** The responsibilities of each architectural layer in the Transaction Architecture are:

| Layer | Responsibility |
|---|---|
| Frontend | Initiate operations, capture user intent, prevent duplicate submission, render transaction status, display structured errors and recovery guidance. |
| Service | Validate input, resolve caller permissions, construct the transaction request, attach correlation identifiers, submit to the transaction coordinator, return structured results. |
| Edge / Routing | Authenticate and authorize the request, rate-limit, transform the request into the canonical transaction format, invoke the transaction coordinator, log request metadata. |
| Transaction Coordinator | Own the transaction boundary; open, execute, commit, or roll back the database transaction; orchestrate side effects through the outbox or compensating-action model; emit state transitions. |
| Database / Resource Manager | Enforce ACID invariants, isolation, referential integrity, and durability for operations within the transaction boundary; expose savepoint and rollback primitives. |
| Outbox Processor | Read pending outbox messages and dispatch side effects to handlers idempotently, retrying with backoff and escalating on unrecoverable failure. |
| Compensation Manager | Track completed side effects and trigger compensating actions when post-commit failures cannot be retried to success. |
| Side-Effect Handler | Perform one type of external operation (storage cleanup, message send, provider call, identity removal) in an idempotent or reversibly compensatable manner. |
| Audit Writer | Record transaction lifecycle events and pre/post-state snapshots immutably and independently of operational entity lifecycle, per SPEC-002. |
| State Manager | Persist and transition the transaction state machine; guarantee that every transition is recorded with previous state, new state, actor, timestamp, and reason. |

**SPEC-003-RES-002.** Business workflow logic shall not be split between the transaction coordinator and database triggers. Triggers may enforce low-level invariants only; they shall not make cross-step decisions or emit side effects.

**SPEC-003-RES-003.** The transaction coordinator shall be the single component that decides whether a transaction commits or rolls back. No other layer shall commit or roll back a transaction owned by the coordinator.

---

## 16.7 Architecture Principles Mapping

**SPEC-003-PRM-001.** The Transaction Architecture shall implement every relevant principle of the Master Program as follows:

| Principle | Mapping to Transaction Architecture |
|---|---|
| Deletion is explicit | Every transaction boundary is explicitly declared by the transaction coordinator; no data mutation occurs as an unrecorded side effect of another operation. |
| Deletion is deterministic | The same transaction request, given the same state, produces the same ordered set of participants, the same commit/rollback decision, and the same outbox messages. |
| Deletion is idempotent | Replaying a completed or failed transaction with the same transaction identifier returns the recorded result without duplicating database mutations or side effects. |
| Deletion is observable | Every transaction carries a correlation identifier and emits a step trace across the transaction coordinator, resource manager, outbox processor, and side-effect handlers. |
| Deletion is recoverable | Failed or partially failed transactions roll back inside the boundary, or are retried/compensated outside the boundary, with explicit recovery guidance. |
| Audit is immutable | Transaction lifecycle events are recorded as immutable, append-only audit records per SPEC-002; audit writes do not mutate operational state. |
| Database owns integrity | ACID invariants, isolation, and referential integrity are enforced by the database or resource manager inside the transaction boundary. |
| Application owns workflow | The transaction coordinator owns ordering, participant invocation, outbox enqueueing, compensation decisions, and retry policy. |
| Platform before feature | Feature teams consume the canonical transaction coordinator and side-effect patterns; they do not invent local transaction mechanisms. |
| Reuse before reinvention | Existing transaction coordination, outbox, and compensation capabilities are consumed before new ones are created. |
| Side effects are compensatable | External cleanup is idempotent or reversibly compensatable; the critical database transaction does not wait on external systems. |
| Failure is a first-class state | Open, Executing, Committing, Committed, Rolling Back, Rolled Back, Compensating, Retryable, and Closed are modeled explicitly in the transaction state machine. |

---

## 16.8 Domain Model

**SPEC-003-DOM-001.** The Transaction Architecture domain consists of the following conceptual objects, each with a single responsibility:

| Concept | Responsibility |
|---|---|
| Transaction Request | Captures intent: operation type, transaction identifier, correlation identifier, actor, scope, participants, classification, timeout, isolation level, and authorization context. |
| Transaction Boundary | The logical scope within which ACID invariants apply. The boundary is owned by the Transaction Coordinator and is bounded by a single commit/rollback decision. |
| Transaction Session | A runtime container that binds one or more related operations to a transaction identifier and a correlation identifier. |
| Transaction Coordinator | The component that opens the transaction, sequences participants, decides commit or rollback, and enforces the side-effect coordination model. |
| Participant | A logical step that executes work inside the transaction boundary (domain logic, audit-before-commit, constraint validation). |
| Outbox | A durable, append-only queue of side-effect messages generated inside the transaction and dispatched after commit. |
| Outbox Processor | The component that polls or is notified of outbox messages and dispatches them to side-effect handlers. |
| Side-Effect Handler | Performs one external operation and returns success, idempotent already-done, or failure requiring retry/compensation. |
| Compensation Action | A reversibly compensatable operation that undoes or neutralizes a completed side effect when retry is not possible. |
| Saga Step | A logical unit in a long-running or cross-service operation that has its own local transaction and is coordinated by saga orchestration rules. |
| Recovery Record | Tracks failure classification, retry attempts, next retry timestamp, escalation status, and operator guidance. |
| Transaction State | A named lifecycle stage of a transaction. |

**SPEC-003-DOM-002.** A `Transaction Request` shall not perform resource mutations directly. It shall be consumed by the `Transaction Coordinator`.

**SPEC-003-DOM-003.** The `Transaction Coordinator` shall be the only component that commits or rolls back the `Transaction Boundary`.

**SPEC-003-DOM-004.** An `Outbox` message shall be generated inside the transaction boundary and shall be committed atomically with the operational state changes, so that a committed transaction is guaranteed to produce durable side-effect intents.

---

## 16.9 Components

**SPEC-003-COM-001.** The Transaction Architecture comprises the following logical components:

| Component | Role | Placement |
|---|---|---|
| Transaction Coordinator | Owns the transaction boundary, sequences participants, commits/rolls back, and enforces the outbox model. | Application / Service layer |
| Boundary Guard | Verifies transaction preconditions, authorization, participant eligibility, and isolation constraints before the coordinator opens the boundary. | Service / Application layer |
| Participant Registry | Maintains the set of transaction participants per operation type without modifying the coordinator core. | Application layer |
| Outbox Writer | Appends side-effect messages to the durable outbox within the transaction boundary. | Database / Persistence layer |
| Outbox Processor | Dispatches outbox messages to side-effect handlers with retry, backoff, and escalation. | Service / Operations layer |
| Compensation Manager | Records completed side effects and triggers compensating actions when necessary. | Service / Operations layer |
| Retry Manager | Schedules retries, tracks attempts, and enforces retry limits and backoff policies. | Service / Operations layer |
| Timeout Monitor | Enforces transaction timeouts, cancels long-running operations, and transitions stalled transactions to a recoverable state. | Operations / SRE layer |
| Concurrency Manager | Controls lock scope, isolation level selection, and conflict detection to preserve ordering guarantees. | Database / Application layer |
| State Manager | Persists every transaction state transition with previous state, new state, actor, timestamp, and reason. | Database / Persistence layer |
| Integrity Verifier | Validates that committed transactions have matching outbox entries and that outbox messages are eventually processed. | Operations / SRE layer |
| Observability Emitter | Emits structured logs, metrics, and traces tied to the transaction correlation identifier. | All layers |

**SPEC-003-COM-002.** The `Transaction Coordinator` shall be the sole component that commits or rolls back a `Transaction Boundary`.

**SPEC-003-COM-003.** The `Participant Registry` shall allow new participants to be registered per domain and per operation type without changing the core coordinator.

**SPEC-003-COM-004.** The `State Manager` shall persist every state transition with the previous state, new state, actor, timestamp, and reason, making the transaction lifecycle reconstructible.

---

## 16.10 Interfaces

**SPEC-003-INT-001.** The Transaction Architecture exposes the following abstract interfaces:

### 16.10.1 Transaction Request Interface

| Attribute | Type | Description |
|---|---|---|
| `transaction_id` | Identifier | Unique identifier for the transaction. |
| `correlation_id` | Identifier | Propagated across all layers and audit records. |
| `actor_id` | Identity | The user or service that initiated the operation. |
| `actor_context` | Context | Tenant, role, authorization context, source metadata. |
| `operation_type` | Domain name | The business operation being performed (for example, Delete, Checkout, Exchange). |
| `participants` | List | Ordered list of transaction participants. |
| `isolation_level` | Classification | Desired isolation (for example, read committed, serializable, snapshot). |
| `timeout` | Duration | Maximum time the transaction may remain open. |
| `idempotency_key` | Identifier | Key used to detect and deduplicate replayed requests. |
| `metadata` | Key-value map | Operation-specific context: classification, reason, approval references. |

### 16.10.2 Transaction Result Interface

| Attribute | Type | Description |
|---|---|---|
| `transaction_id` | Identifier | The originating transaction identifier. |
| `correlation_id` | Identifier | The correlation identifier. |
| `final_state` | State | Terminal or intermediate state of the transaction. |
| `committed_at` | Timestamp | Time of commit, if committed. |
| `affected_resources` | List | Domain identifiers affected by the transaction. |
| `outbox_messages` | List | Identifiers of side-effect messages queued for dispatch. |
| `error_code` | Code | Structured error code, empty if successful. |
| `error_message` | String | Human-readable error description. |
| `recovery_guidance` | String | Instructions for recovery or retry, when applicable. |
| `next_steps` | List | Recommended actions for the caller. |

### 16.10.3 Outbox Message Interface

| Attribute | Type | Description |
|---|---|---|
| `message_id` | Identifier | Unique identifier for the outbox message. |
| `correlation_id` | Identifier | The originating correlation identifier. |
| `transaction_id` | Identifier | The originating transaction identifier. |
| `handler_type` | Name | The side-effect handler responsible for processing. |
| `payload` | Opaque | Handler-specific payload; the coordinator does not inspect the payload content. |
| `status` | State | Pending, Processing, Completed, Failed, Compensating, Compensated. |

### 16.10.4 Compensation Action Interface

| Attribute | Type | Description |
|---|---|---|
| `compensation_id` | Identifier | Unique identifier for the compensation. |
| `original_message_id` | Identifier | The outbox message being compensated. |
| `handler_type` | Name | The side-effect handler that performs compensation. |
| `payload` | Opaque | Compensation payload derived from the completed side effect. |
| `status` | State | Pending, Completed, Failed, Escalated. |

**SPEC-003-INT-002.** The Transaction Coordinator shall accept a `Transaction Request` and return a `Transaction Result`.

**SPEC-003-INT-003.** The Outbox Processor Interface shall accept an `Outbox Message` and return a status indicating success, idempotent already-done, failure requiring retry, or failure requiring compensation.

**SPEC-003-INT-004.** The Audit Writer Interface shall accept transaction lifecycle events and persist them immutably, as defined in SPEC-002.

---

## 16.11 Contracts

**SPEC-003-CON-001.** The Transaction Architecture contracts are technology-neutral and implementation-neutral. Every implementation shall honor the following contracts:

### 16.11.1 Transaction Boundary Contract

**SPEC-003-CON-002.** Every transaction shall have exactly one `Transaction Coordinator` that owns the commit/rollback decision for the transaction boundary.

**SPEC-003-CON-003.** A transaction boundary shall include all operational mutations that must succeed or fail together. Operations that can fail independently shall be placed outside the boundary and coordinated through the outbox or saga model.

### 16.11.2 ACID Contract

**SPEC-003-CON-004.** Atomicity: all changes inside a transaction boundary shall commit together or roll back together. No partial commit of an in-boundary operation is permitted.

**SPEC-003-CON-005.** Consistency: the transaction shall leave every participating resource in a valid state with respect to the domain invariants declared for the operation. Invariants that cannot be enforced by the resource manager shall be validated before commit.

**SPEC-003-CON-006.** Isolation: concurrent transactions shall not observe each other's uncommitted state. The degree of isolation shall be selected to match the concurrency requirements and the acceptable anomaly tolerance of the operation.

**SPEC-003-CON-007.** Durability: once a transaction is committed, its effects shall survive coordinator or resource-manager failure, subject to the durability guarantees of the persistence layer.

### 16.11.3 Commit and Rollback Contract

**SPEC-003-CON-008.** The `Transaction Coordinator` shall commit only after all in-boundary participants have succeeded and all outbox messages for the transaction have been durably recorded.

**SPEC-003-CON-009.** The `Transaction Coordinator` shall roll back if any in-boundary participant fails, any invariant is violated, the timeout is reached, or an explicit rollback is requested before commit.

**SPEC-003-CON-010.** After a rollback, no side effect that is outside the transaction boundary shall be considered committed. Outbox messages generated by the transaction shall not be dispatched.

### 16.11.4 Outbox Contract

**SPEC-003-CON-011.** Side effects that cross resource or service boundaries shall be represented as outbox messages appended inside the transaction boundary and dispatched only after commit.

**SPEC-003-CON-012.** The outbox write shall be committed atomically with the operational state changes, so that a committed transaction implies a committed set of side-effect intents.

**SPEC-003-CON-013.** The `Outbox Processor` shall dispatch outbox messages at least once, detecting and suppressing duplicates through idempotency keys.

### 16.11.5 Compensation Contract

**SPEC-003-CON-014.** Every side-effect handler that is not naturally idempotent shall declare a compensating action or a reversible equivalent.

**SPEC-003-CON-015.** A compensating action shall be recorded as its own transaction and shall itself be idempotent, so that replay does not produce additional side effects.

**SPEC-003-CON-016.** Compensation shall be triggered only when the original side effect has completed and cannot be retried to success.

### 16.11.6 Saga Contract

**SPEC-003-CON-017.** Long-running or cross-service operations may be decomposed into saga steps, where each step has its own local transaction boundary and the overall operation is coordinated by saga rules.

**SPEC-003-CON-018.** A saga shall define a backward-recovery plan: for each step, a compensating action is defined and invoked in reverse order if any later step fails.

**SPEC-003-CON-019.** Saga steps shall be ordered explicitly. The coordinator shall not proceed to the next step until the current step has committed and its result has been recorded.

### 16.11.7 Idempotency Contract

**SPEC-003-CON-020.** Every transaction request shall carry an `idempotency_key` that the coordinator uses to detect replayed requests.

**SPEC-003-CON-021.** Replaying a committed or rolled-back transaction with the same `idempotency_key` and `transaction_id` shall return the recorded result without re-executing participants or duplicating outbox messages.

**SPEC-003-CON-022.** Side-effect handlers and compensating actions shall be idempotent with respect to their `message_id` or `compensation_id`.

### 16.11.8 Retry Contract

**SPEC-003-CON-023.** The `Retry Manager` shall apply a bounded retry policy with maximum attempts, exponential or fixed backoff, and a deadline.

**SPEC-003-CON-024.** Retries shall not extend the original transaction boundary. A failed side effect shall be retried by the `Outbox Processor` or `Compensation Manager` outside the original transaction.

**SPEC-003-CON-025.** Transient failures shall be classified as retryable; non-transient and invariant failures shall be classified as non-retryable and shall trigger compensation or escalation.

### 16.11.9 Timeout Contract

**SPEC-003-CON-026.** Every transaction shall declare a timeout. If the timeout is reached before commit, the transaction shall be rolled back and the state machine shall transition to `ROLLBACK` or `TIMEOUT_RECOVERY`.

**SPEC-003-CON-027.** Long-running operations that exceed a short-lived transaction timeout shall be modeled as sagas with per-step timeouts rather than as single long-lived database transactions.

### 16.11.10 Ordering and Integrity Contract

**SPEC-003-CON-028.** Participants inside a transaction boundary shall execute in the order declared by the `Transaction Request`.

**SPEC-003-CON-029.** Outbox messages for a single transaction shall be dispatched in the order they were generated unless a handler explicitly supports out-of-order processing.

**SPEC-003-CON-030.** Transaction integrity shall be verified by comparing committed transaction records with outbox entries, compensating actions, and audit records, ensuring that no committed transaction is missing a required side effect or audit event.

### 16.11.11 Audit and Trigger Interaction Contract

**SPEC-003-CON-031.** Audit lifecycle events may be generated inside the transaction boundary (audit-before-commit) or outside it (audit-after-commit via the outbox), as determined by the operation-specific contract and defined in SPEC-001 and SPEC-002.

**SPEC-003-CON-032.** Triggers may enforce low-level invariants but shall not encode business workflow logic or emit side effects that cross the transaction boundary.

**SPEC-003-CON-033.** Foreign-key and referential-integrity constraints shall be treated as invariants within the transaction boundary; they shall not drive workflow ordering or side-effect orchestration.

---

## 16.12 State Machine

**SPEC-003-STM-001.** Every transaction shall move through the governed lifecycle defined in this section.

### 16.12.1 Happy Path

```
RECEIVED
  ↓ request validated
VALIDATED
  ↓ boundary opened
OPEN
  ↓ participants execute
EXECUTING
  ↓ all participants succeed
COMMITTING
  ↓ operational state and outbox committed
COMMITTED
  ↓ outbox messages dispatched
SIDE_EFFECTS_DISPATCHING
  ↓ all side effects completed
COMPLETED
```

### 16.12.2 Failure and Recovery Path

```
EXECUTING / COMMITTING
  ↓ participant or invariant fails
FAILING
  ↓ rollback prepared
ROLLING_BACK
  ↓ transaction rolled back
ROLLED_BACK
  ↓ retry conditions satisfied
RETRYABLE
  ↓ retry succeeds
OPEN or COMPLETED
```

```
COMMITTED
  ↓ side-effect handler fails and retry exhausted
COMPENSATING
  ↓ compensating actions applied
COMPENSATED
  ↓ or compensation fails
ESCALATED
  ↓ operator intervention
CLOSED
```

### 16.12.3 Transition Rules

| From | To | Guard | Owner | Action |
|---|---|---|---|---|
| RECEIVED | VALIDATED | Request structure and authorization pass | Boundary Guard | Validate request and idempotency key. |
| VALIDATED | OPEN | Preconditions satisfied, timeout set | Transaction Coordinator | Open transaction boundary and initialize state. |
| OPEN | EXECUTING | Participants registered | Transaction Coordinator | Execute participants in declared order. |
| EXECUTING | COMMITTING | All participants succeed, invariants pass | Transaction Coordinator | Validate final state and prepare commit. |
| COMMITTING | COMMITTED | Operational state and outbox persisted | Database / Resource Manager | Commit transaction. |
| COMMITTED | SIDE_EFFECTS_DISPATCHING | Outbox messages available | Outbox Processor | Begin dispatching outbox messages. |
| SIDE_EFFECTS_DISPATCHING | COMPLETED | All outbox messages processed | Outbox Processor / Compensation Manager | Record completion, emit final audit. |
| EXECUTING / COMMITTING | FAILING | Participant failure or invariant violation | Transaction Coordinator | Halt execution, preserve state, emit error. |
| FAILING | ROLLING_BACK | Rollback is safe | Transaction Coordinator | Roll back in-boundary changes. |
| ROLLING_BACK | ROLLED_BACK | Resource manager confirms rollback | Database / Resource Manager | Release resources, return structured error. |
| ROLLED_BACK | RETRYABLE | Retry conditions met | Retry Manager | Schedule retry with backoff. |
| RETRYABLE | OPEN | Retry preconditions restored | Transaction Coordinator | Restart transaction at the appropriate step. |
| COMMITTED | COMPENSATING | Side effect failed, retry exhausted | Compensation Manager | Trigger compensating actions in reverse order. |
| COMPENSATING | COMPENSATED | All compensations succeed | Compensation Manager | Record final state and audit. |
| COMPENSATING | ESCALATED | Compensation fails | Recovery Manager | Create incident record, alert operators. |
| ESCALATED | CLOSED | Operator resolves or accepts | Operations | Close transaction with resolution record. |

**SPEC-003-STM-002.** Terminal states are `COMPLETED`, `ROLLED_BACK`, `COMPENSATED`, `ESCALATED`, and `CLOSED`.

**SPEC-003-STM-003.** Every transition shall be logged with previous state, new state, actor, timestamp, and reason.

---

## 16.13 Workflow

**SPEC-003-WFL-001.** The canonical transaction workflow consists of the following high-level stages:

1. **Receive** — The caller submits a `Transaction Request` with transaction identifier, correlation identifier, operation type, participants, timeout, and idempotency key.
2. **Validate** — The `Boundary Guard` checks authorization, participant eligibility, idempotency, and preconditions.
3. **Open** — The `Transaction Coordinator` opens the transaction boundary and initializes the state machine.
4. **Reserve** — Any required resources, locks, or optimistic reservations are acquired inside the boundary.
5. **Execute** — The coordinator invokes each participant in order, capturing participant results and any generated outbox messages.
6. **Pre-Commit Check** — The coordinator validates that all participants succeeded, all invariants hold, and the timeout has not been reached.
7. **Commit** — The coordinator commits the operational state and the outbox messages atomically.
8. **Dispatch Side Effects** — The `Outbox Processor` dispatches outbox messages to side-effect handlers after commit.
9. **Retry or Compensate** — Failed side effects are retried with backoff; unrecoverable side effects trigger compensating actions.
10. **Complete** — The coordinator records the final state, emits an audit event, and returns a `Transaction Result`.

**SPEC-003-WFL-002.** If any stage from `Execute` through `Commit` fails, the workflow shall transition to `FAILING` and the `Recovery Model` shall apply.

**SPEC-003-WFL-003.** Side-effect dispatch shall occur only after the operational transaction has committed.

**SPEC-003-WFL-004.** The workflow shall support both short-lived ACID transactions and long-running sagas through the same `Transaction Coordinator` interface, with the coordinator selecting the appropriate model based on operation classification.

---

## 16.14 Sequence

**SPEC-003-SEQ-001.** The critical path for a business operation that requires a transaction boundary shall follow this sequence:

```
Caller (Frontend / Service / Routing)
  → Boundary Guard: validate request, idempotency, authorization
    → Transaction Coordinator: open transaction boundary
      → Concurrency Manager: acquire locks / set isolation
        → Participant 1..N: execute domain logic inside boundary
          → Outbox Writer: append side-effect messages
            → Audit Writer (optional audit-before-commit): record lifecycle event
        → Transaction Coordinator: pre-commit validation
          → Database / Resource Manager: commit operational state and outbox
            → State Manager: transition to COMMITTED
              → Outbox Processor: dispatch pending messages
                → Side-Effect Handler 1..N: perform idempotent external operations
                  → Compensation Manager (if failure): record completed effects and trigger compensations
            → Audit Writer (audit-after-commit / completion): record final event
              → Observability Emitter: emit structured log, metric, trace
                → Transaction Coordinator: return Transaction Result
```

**SPEC-003-SEQ-002.** If validation fails before the boundary is opened, the system shall return a structured error and no state transition beyond `RECEIVED` shall occur.

**SPEC-003-SEQ-003.** If a participant fails during `EXECUTING`, the coordinator shall roll back in-boundary changes and the state shall transition to `ROLLED_BACK`.

**SPEC-003-SEQ-004.** If a side-effect handler fails after commit, the transaction state shall transition to `SIDE_EFFECTS_DISPATCHING` with a failure marker; retries or compensations shall be applied without rolling back the committed database state.

---

## 16.15 Data Model

**SPEC-003-DAT-001.** The Transaction Architecture data model is logical and conceptual. It does not prescribe physical table names, column types, or storage engines.

### 16.15.1 Core Entities

| Entity | Attributes | Ownership |
|---|---|---|
| Transaction | transaction_id, correlation_id, actor, operation_type, state, previous_state, timeout, isolation_level, started_at, committed_at, rolled_back_at, metadata | Transaction Coordinator / State Manager |
| Participant | participant_id, transaction_id, sequence, status, result, error_code | Transaction Coordinator |
| Outbox Message | message_id, transaction_id, correlation_id, handler_type, payload, status, created_at, processed_at | Outbox Writer / Outbox Processor |
| Compensation Log | compensation_id, original_message_id, handler_type, payload, status, created_at | Compensation Manager |
| Retry Schedule | retry_id, message_id, attempt, next_retry_at, deadline, status | Retry Manager |
| Saga Step | saga_id, step_sequence, transaction_id, local_status, compensation_reference | Saga Orchestrator |
| Lock / Lease | resource_id, transaction_id, acquired_at, released_at, mode | Concurrency Manager |
| Transaction Audit | audit_id, transaction_id, correlation_id, action, actor, timestamp | Audit Writer |
| Recovery Record | recovery_id, transaction_id, failure_class, guidance, escalated_at, operator_notes | Recovery Manager |

### 16.15.2 Data Ownership

**SPEC-003-DAT-002.** The `Transaction Coordinator` and `State Manager` own the `Transaction`, `Participant`, `Outbox Message`, `Compensation Log`, `Retry Schedule`, and `Saga Step` persistence.

**SPEC-003-DAT-003.** The `Audit Writer` owns `Transaction Audit` records and persists them immutably and independently of operational entity lifecycles, per SPEC-002.

**SPEC-003-DAT-004.** The `Outbox Message` entity shall be committed in the same logical boundary as the operational state changes, so that a committed transaction implies committed side-effect intents.

**SPEC-003-DAT-005.** `Compensation Log` and `Retry Schedule` records shall be retained until the transaction reaches a terminal state or is explicitly closed by an operator.

---

## 16.16 Failure Model

**SPEC-003-FAM-001.** The following failure modes are in scope for the Transaction Architecture:

| ID | Failure Mode | Likelihood | Impact | Detection |
|---|---|---|---|---|
| SPEC-003-FAM-001 | Authorization or validation failure before transaction open | Medium | Low | Boundary Guard returns structured error. |
| SPEC-003-FAM-002 | Participant failure inside the transaction boundary | Medium | High | Coordinator detects participant error during EXECUTING. |
| SPEC-003-FAM-003 | Invariant or referential-integrity violation during transaction | Medium | High | Resource manager or Boundary Guard rejects commit. |
| SPEC-003-FAM-004 | Coordinator timeout before commit | Low | High | Timeout Monitor triggers rollback. |
| SPEC-003-FAM-005 | Outbox message loss or dispatch failure after commit | Low | High | Outbox Processor detects unprocessed messages. |
| SPEC-003-FAM-006 | Side-effect handler fails after retry exhaustion | Low | High | Outbox Processor marks message Failed; Compensation Manager takes over. |
| SPEC-003-FAM-007 | Compensation action itself fails | Low | Critical | Compensation Manager returns failure; Recovery Manager escalates. |
| SPEC-003-FAM-008 | Duplicate transaction submission | Medium | Medium | Idempotency check returns recorded result. |
| SPEC-003-FAM-009 | Concurrency conflict (deadlock, serialization anomaly) | Medium | High | Concurrency Manager detects conflict; transaction retried or rolled back. |
| SPEC-003-FAM-010 | State transition lost or corrupted | Low | Critical | State Manager consistency check fails on next read. |
| SPEC-003-FAM-011 | Saga step failure requiring backward recovery | Low | High | Saga Orchestrator detects step failure and invokes preceding compensations. |

**SPEC-003-FAM-012.** Every failure mode shall have a corresponding recovery action defined in the Recovery Model.

**SPEC-003-FAM-013.** Failures shall not return generic error responses without a structured error code, correlation identifier, and recovery guidance.

---

## 16.17 Recovery Model

**SPEC-003-RCM-001.** The Transaction Architecture recovery model shall handle each failure mode:

| Failure Mode | Recovery Action | Owner |
|---|---|---|
| Authorization or validation failure | Return structured error; no state change. | Boundary Guard |
| Participant failure | Roll back transaction; return error with guidance; set state `ROLLED_BACK`. | Transaction Coordinator |
| Invariant or referential-integrity violation | Roll back transaction; return error identifying the violated invariant. | Transaction Coordinator / Resource Manager |
| Coordinator timeout | Roll back open transaction; set state `ROLLED_BACK` then `RETRYABLE` if safe. | Timeout Monitor / Transaction Coordinator |
| Outbox message loss or dispatch failure | Re-dispatch from durable outbox; suppress duplicates with idempotency key. | Outbox Processor |
| Side-effect handler fails after retry exhaustion | Trigger compensating action for the failed side effect; set state `COMPENSATING`. | Compensation Manager |
| Compensation action fails | Escalate to operations; preserve state; create incident record. | Recovery Manager |
| Duplicate transaction submission | Return recorded result without re-executing participants. | Transaction Coordinator |
| Concurrency conflict | Roll back or retry based on conflict classification; return retry guidance. | Concurrency Manager / Retry Manager |
| State transition lost | Reconcile from audit and transaction logs; emit alert. | State Manager |
| Saga step failure | Invoke compensating actions for all preceding steps in reverse order. | Saga Orchestrator |

**SPEC-003-RCM-002.** The recovery model shall prefer rollback to compensation when the transaction has not committed.

**SPEC-003-RCM-003.** When compensation is required, compensating actions shall be idempotent and shall record both the attempted action and the compensation.

**SPEC-003-RCM-004.** Manual operator recovery shall be supported through a `ESCALATED` state with explicit guidance, not through ad-hoc resource edits.

**SPEC-003-RCM-005.** The `Retry Manager` shall classify failures as transient or non-transient and shall not retry non-transient failures without operator intervention.

---

## 16.18 Security

**SPEC-003-SEC-001.** Every transaction request shall be authenticated and authorized before the transaction boundary is opened.

**SPEC-003-SEC-002.** Role-based access control shall enforce that only authorized actors may initiate a given operation type or transaction classification.

**SPEC-003-SEC-003.** The transaction coordinator shall enforce tenant and resource isolation through the authorization context; it shall not trust the caller for isolation decisions.

**SPEC-003-SEC-004.** Transaction audit records shall contain the actor, authorization context, source metadata, and correlation identifier to support forensic review and non-repudiation.

**SPEC-003-SEC-005.** The framework shall resist replay attacks by validating `transaction_id` and `idempotency_key` uniqueness.

**SPEC-003-SEC-006.** Sensitive payload data carried in outbox messages or compensation logs shall be protected according to the platform's data-protection policies.

**SPEC-003-SEC-007.** Compensation and retry actions shall require the same or higher authorization as the original transaction.

---

## 16.19 Observability

**SPEC-003-OBS-001.** Every transaction shall emit structured observability data:

| Type | Requirement |
|---|---|
| Logs | Structured log per workflow stage, containing `transaction_id`, `correlation_id`, `operation_type`, `actor`, `state`, and any error code. |
| Metrics | Counter for transactions initiated, committed, rolled back, retried, compensated, and timed out, partitioned by operation type and classification. |
| Traces | Distributed trace following the transaction correlation identifier across caller, boundary guard, coordinator, participants, outbox processor, and side-effect handlers. |
| Alerts | Alert on sustained transaction failure rate, outbox backlog growth, compensation failure, timeout rate, and integrity verification failure. |
| Dashboards | Dashboard showing transaction throughput, commit/rollback rate, outbox latency, retry rate, compensation rate, and long-running transaction count. |

**SPEC-003-OBS-002.** The observability layer shall enable operators to reconstruct the full lifecycle of any transaction from `transaction_id` or `correlation_id` without querying operational resources directly.

**SPEC-003-OBS-003.** All failure states shall include structured error codes and recovery guidance suitable for support staff and compliance reviewers.

---

## 16.20 Risks

**SPEC-003-RSK-001.** The following risks are introduced or mitigated by the Transaction Architecture:

| ID | Risk | Likelihood | Impact | Owner | Mitigation |
|---|---|---|---|---|---|
| SPEC-003-RSK-001 | A new operation bypasses the canonical transaction coordinator and invents a local transaction boundary. | Medium | High | Chief Technical Advisor | Mandatory architecture review and transaction onboarding for every multi-step operation. |
| SPEC-003-RSK-002 | The transaction coordinator holds locks for too long, reducing throughput or causing deadlocks. | Medium | High | Database Architecture | Shorten transaction scope, use savepoints, batch sizing, and timeout governance. |
| SPEC-003-RSK-003 | Outbox messages are dispatched before the database transaction commits, causing orphan side effects. | Low | Critical | Platform Engineering | Enforce outbox write inside the transaction boundary and dispatch only after commit. |
| SPEC-003-RSK-004 | Side-effect handlers are not idempotent, duplicating external operations on retry. | Medium | High | Platform Engineering | Handler contract review, idempotency tests, and outbox deduplication. |
| SPEC-003-RSK-005 | Compensating actions are not tested and fail during an incident. | Medium | High | SRE / Platform Operations | Regular failure-recovery drills and compensation test suite. |
| SPEC-003-RSK-006 | Long-running operations are modeled as single database transactions, causing resource exhaustion. | Low | High | Platform Engineering | Use sagas with per-step local transactions for operations exceeding the short-lived timeout. |
| SPEC-003-RSK-007 | Concurrency conflicts cause frequent rollbacks and retry storms. | Medium | Medium | Database Architecture | Select appropriate isolation levels, optimistic concurrency, and conflict backoff. |
| SPEC-003-RSK-008 | Audit records are written inside a failing transaction, causing the audit to be lost or the transaction to abort. | Low | High | Security & Compliance | Support audit-before-commit only when safe; prefer audit-after-commit via outbox per SPEC-002. |

---

## 16.21 Constraints

**SPEC-003-CST-001.** The Transaction Architecture shall operate within the following constraints:

| ID | Constraint | Source |
|---|---|---|
| SPEC-003-CST-001 | The architecture shall be technology-neutral and shall not assume any specific database, runtime, messaging broker, or workflow engine. | Architecture Specification Program Section 18. |
| SPEC-003-CST-002 | The architecture shall not place business workflow logic inside database triggers; triggers may enforce low-level invariants only. | Master Program Guiding Principle 3. |
| SPEC-003-CST-003 | The database transaction shall not be blocked waiting for external side effects. | Master Program Principle: Side effects are compensatable. |
| SPEC-003-CST-004 | Audit records shall be immutable and shall outlive the entities they describe. | Master Program Guiding Principle 2. |
| SPEC-003-CST-005 | Every transaction shall identify a single transaction owner in its architecture documentation. | Master Program Section 9. |
| SPEC-003-CST-006 | Failure responses shall be structured and shall include correlation identifiers and recovery guidance. | Master Program Success Criteria. |
| SPEC-003-CST-007 | Long-running operations shall not be implemented as a single, unbounded database transaction. | Transaction Timeout Contract (CON-026, CON-027). |

---

## 16.22 Non-goals

**SPEC-003-NGO-001.** This specification explicitly does not cover:

1. Implementation code, file names, package structures, or operational rollout instructions.
2. Concrete remote-procedure signatures, data-definition statements, table schemas, or storage-engine configuration.
3. Specific technology choices such as a particular database, messaging broker, workflow engine, or programming language.
4. Detailed runbooks, operational playbooks, or on-call procedures (those belong in Operational Specifications and Implementation Plans).
5. The internal audit immutability, retention, or integrity-hash schemes (those are defined in SPEC-002).
6. The detailed delete pipeline, classification matrix, or domain delete rules (those are defined in SPEC-001).
7. The detailed `ON DELETE` referential-integrity policy (that is defined in SPEC-005).

---

## 16.23 Verification Requirements

**SPEC-003-VRF-001.** The following verification requirements shall be satisfied before the Transaction Architecture is accepted:

| ID | Verification Requirement | Method |
|---|---|---|
| VRF-001 | Every multi-step operation uses a single transaction coordinator for its boundary. | Static architecture review and governance audit. |
| VRF-002 | The transaction state machine transitions match Section 16.12. | State-transition unit tests. |
| VRF-003 | Database transaction rollback restores pre-transaction state. | Transaction failure-injection tests. |
| VRF-004 | Outbox messages are committed atomically with operational state changes. | Database tests and outbox integrity checks. |
| VRF-005 | Side-effect handlers are idempotent under replay. | Replay tests against each handler. |
| VRF-006 | Compensating actions are idempotent and reverse the original side effect. | Compensation integration tests. |
| VRF-007 | Replaying a completed or rolled-back transaction returns the stable result. | Idempotency integration tests. |
| VRF-008 | Timeout monitor rolls back or cancels transactions that exceed their timeout. | Timeout simulation tests. |
| VRF-009 | Retry policy respects backoff limits and does not retry non-transient failures. | Retry-policy tests. |
| VRF-010 | Structured transaction errors include correlation identifier and recovery guidance. | Error-response contract tests. |

---

## 16.24 Acceptance Criteria

**SPEC-003-ACC-001.** The Transaction Architecture specification and its implementation are accepted when:

1. All mandatory sections are present and reviewed.
2. All requirements carry unique identifiers and are traceable to verification requirements and acceptance criteria.
3. The implementation passes all verification requirements in Section 16.23.
4. No multi-step business operation contains an independent transaction coordination mechanism outside the canonical Transaction Architecture.
5. Outbox messages are committed atomically with operational state changes and dispatched only after commit.
6. Rollback and recovery tests demonstrate that failed transactions leave the system in a consistent, pre-transaction state.
7. Side-effect handlers and compensating actions demonstrate idempotency under replay.
8. Observability dashboards and alerts are operational.
9. The Production Owner approves the specification and the implementation.

---

## 16.25 Future Evolution

**SPEC-003-FEV-001.** The Transaction Architecture is designed to evolve without redesign. The following extension points are preserved:

| Extension | Description |
|---|---|
| New operation types | New business operations shall register with the Transaction Architecture by providing participants, side-effect handlers, and timeout/isolation requirements. |
| New resource managers | The coordinator may support additional persistence or message resources through the participant registry without changing the core coordinator. |
| New outbox handlers | New side-effect handlers shall be registered without modifying the outbox processor core. |
| Workflow engines | The coordinator and saga orchestrator may be migrated to a workflow engine or saga orchestrator without changing the state machine or contracts. |
| Multi-region transactions | The architecture may be extended to region-aware coordinators by including region in the `Transaction Context`. |
| External messaging brokers | The outbox processor may be backed by a durable message broker while preserving the at-least-once, idempotent dispatch contract. |
| AI-assisted anomaly detection | Transaction patterns may be analyzed for anomalous failure or retry patterns without altering the transaction record schema. |

**SPEC-003-FEV-002.** Any change that alters the ACID contract, the outbox delivery contract, the compensation contract, or the idempotency contract shall require an Architecture Decision Record per the Master Program Section 29.

---

## 16.26 Appendix

### A. ACID Reference Model

| Property | Meaning | Architectural Responsibility |
|---|---|---|
| Atomicity | All in-boundary changes commit or roll back together. | Transaction Coordinator and Resource Manager. |
| Consistency | The transaction leaves resources in a valid state. | Participants, Boundary Guard, and Resource Manager invariants. |
| Isolation | Uncommitted state is not visible to concurrent transactions. | Resource Manager isolation level and Concurrency Manager. |
| Durability | Committed effects survive failure. | Resource Manager persistence and replication. |

### B. Glossary

| Term | Definition |
|---|---|
| Transaction Boundary | The logical scope within which ACID invariants apply and a single commit/rollback decision is made. |
| Transaction Coordinator | The component that owns the transaction boundary and commits or rolls back. |
| Participant | A logical step that executes work inside the transaction boundary. |
| Outbox | A durable queue of side-effect intents committed with the transaction. |
| Outbox Processor | The component that dispatches outbox messages to side-effect handlers. |
| Side-Effect Handler | A component that performs one external operation in an idempotent manner. |
| Compensation Action | A reversibly compensatable operation that neutralizes a completed side effect. |
| Saga | A long-running operation composed of local transactions and compensations. |
| Idempotency Key | A key used to detect and suppress duplicate transaction or message processing. |
| Savepoint | A marker within a transaction to which a partial rollback can occur. |
| Correlation Identifier | An identifier propagated across all layers to reconstruct the operation lifecycle. |

### C. Traceability Summary

| This Specification Section | Traces To |
|---|---|
| 16.2 Purpose | Master Program Sections 1, 2, 3, 7, 8, 10 |
| 16.3 Scope | Master Program Section 9, 10 |
| 16.5 Architecture Context | Master Program Sections 4, 5, 6, 10, 22 |
| 16.6 Responsibilities | Master Program Section 10.6 |
| 16.7 Architecture Principles Mapping | Master Program Section 23 |
| 16.8 Domain Model | Master Program Sections 10, 24 |
| 16.9 Components | Master Program Section 10 |
| 16.10 Interfaces | Master Program Section 10 |
| 16.11 Contracts | Master Program Section 10; SPEC-001 CON-006, CON-007 |
| 16.12 State Machine | Master Program Section 10 |
| 16.13 Workflow | Master Program Section 10.6 |
| 16.14 Sequence | Master Program Sections 10.1, 10.6 |
| 16.15 Data Model | Master Program Section 10; SPEC-002 independence contract |
| 16.16 Failure Model | Master Program Section 28 |
| 16.17 Recovery Model | Master Program Sections 10.7, 28 |
| 16.18 Security | Master Program Section 10 |
| 16.19 Observability | Master Program Section 10.8 |
| 16.20 Risks | Master Program Sections 15, 28 |
| 16.21 Constraints | Master Program Sections 7, 10 |
| 16.23 Verification Requirements | Master Program Section 20; SPEC-001 VRF-003, VRF-004 |
| 16.24 Acceptance Criteria | Master Program Sections 13, 14 |
| 16.25 Future Evolution | Master Program Section 17 |

---

## Evidence

### E.1 Foundation Documents Consulted

The following foundation documents were read and followed:

1. `.codebase-memory/CODEBASE_MEMORY_BASELINE.md` — Project baseline, stack, validation status, knowledge priority.
2. `.codebase-memory/SEMANTIC_MEMORY.md` — Architecture overview, business modules, transaction patterns, remote procedures for atomicity, edge/routing mechanisms, services.
3. `.codebase-memory/VALIDATION_REPORT.md` — Confidence scores, known limitations, corrections, risk register.

### E.2 Governance Documents Consulted

The following governance documents were read in the required order:

1. `Deletion_Audit_Architecture_Remediation_Program.md` (Master Program v1.0) — Vision, principles, workstreams, scope, state machine, domain model, classification, dependency matrix, risks, success criteria.
2. `01_Governance/Architecture_Specification_Program.md` (Specification Program v1.1) — Mandatory template (Sections 16.1–16.26), metadata, versioning, naming, repository layout, traceability, dependency, quality gates, identifier registry, status model, classification, dependency framework, registry, index governance, navigation, consistency, approval clarification, expansion.
3. `01_Governance/ARCHITECTURE_SPECIFICATION_INDEX.md` (Index v1.1) — SPEC-003 registration, classification, dependencies, portfolio position, authoring order.
4. `01_Governance/SPEC_BASELINE_CERTIFICATION.md` (Golden Governance v1.0) — Inheritance rules, allowed and prohibited variations, specification creation rules, evidence structure.

### E.3 Cross-Validation Results

| Check | Result |
|---|---|
| SPEC-003 registered in Index | ✓ Found in Index Section 5.3 and dependency matrix. |
| Specification ID matches | ✓ SPEC-003 in both Index and this document. |
| Classification is Core | ✓ Matches Index. |
| No circular dependencies introduced | ✓ SPEC-003 has no mandatory dependencies per Index Section 6.2. |
| Dependency on SPEC-003 declared by SPEC-001 | ✓ SPEC-001 references SPEC-003 as mandatory dependency. |

### E.4 Extracted Governance Summary

Governance hierarchy understood:

- The Master Program sets the vision, principles, and architecture exit criteria.
- The Architecture Specification Program defines the mandatory template, metadata, normative language, traceability, and quality gates.
- The Index registers SPEC-003 as a Core, P1, foundation specification with no mandatory dependencies.
- The Golden Governance certifies SPEC-001 as the structural and governance reference; SPEC-003 inherits the document structure but introduces original transaction architecture.

Inherited elements applied:

- Document header and metadata table (SPEC_BASELINE_CERTIFICATION Section 15.1, 15.2).
- 26 mandatory sections in order (SPEC_BASELINE_CERTIFICATION Section 15.5, 16.1 Prohibited Variations).
- Requirement identifier convention and three-letter section codes (SPEC_BASELINE_CERTIFICATION Section 15.5).
- Traceability Summary and Evidence section (SPEC_BASELINE_CERTIFICATION Sections 15.6, 15.7).
- Ownership model, status model, normative language, and quality gates (SPEC_BASELINE_CERTIFICATION Section 15.8).

Golden Specification comparison:

- SPEC-001 — Delete Framework Architecture Specification v1.1 was used as the Golden authoring example. The document header format, metadata table, 26-section organization, requirement identifier convention, normative writing style, evidence section structure (E.1–E.10), and Traceability Summary format were inherited.
- The architectural content (transaction boundary, outbox, compensation, saga, state machine) is original to SPEC-003 and does not duplicate the Delete Framework or Audit Architecture.
- Domain Model, Components, Interfaces, Contracts, State Machine, Failure Model, Recovery Model, and Data Model are original to this specification.

### E.5 Portfolio Validation

- SPEC-003 is registered in `ARCHITECTURE_SPECIFICATION_INDEX.md` as a Core, P1, foundation specification with no mandatory dependencies.
- The specification ID, short identifier, name, and version match the Index entry.
- The filename follows the `SPEC-NNN_<DOMAIN>_ARCHITECTURE_SPECIFICATION.md` convention established by SPEC-001 and SPEC-002.
- The new file is placed in `ADMIN_DASHBOARD_PLAN_FIX_SPB/02_Specifications/`, consistent with the repository layout defined in the Architecture Specification Program (Section 14) and the Index (Section 9.1).
- No existing governance documents, source code, database artifacts, or other specifications were modified.

### E.6 Dependency Validation

| Target | Reference Format | Result |
|---|---|---|
| Master Program | `Deletion & Audit Architecture Remediation Program v1.0` | ✓ Used in header and References. |
| SPEC-001 | `SPEC-001 Delete Framework (dependent on SPEC-003), v1.1` / `SPEC-001 v1.1` | ✓ Referenced in metadata, References, and Evidence. |
| SPEC-002 | `SPEC-002 Audit Architecture, v1.0` | ✓ Referenced in metadata, References, and contracts. |
| SPEC-005 | `SPEC-005 Foreign Key Governance, TBD` | ✓ Referenced as optional dependency. |

- SPEC-003 has no mandatory dependencies; optional dependencies are SPEC-002 and SPEC-005.
- SPEC-001 references SPEC-003 as a mandatory dependency.

### E.7 Template Compliance

Technology-Neutral Verification:

| Check | Result |
|---|---|
| No specific database, runtime, or workflow engine prescribed | ✓ No product or vendor names used in normative sections. |
| No implementation code, file names, or package structures | ✓ Only logical components and interfaces described. |
| No data-definition statements or concrete signatures | ✓ Logical data model and abstract interfaces only. |
| Side effects described generically (storage, message, provider, identity) | ✓ No concrete API or transport specified. |

Implementation-Independence Verification:

| Check | Result |
|---|---|
| No operational rollout instructions | ✓ None present. |
| No schema change instructions | ✓ None present. |
| No remote-call, REST, GraphQL, or stored-procedure signatures | ✓ Abstract `Transaction Request`/`Result` only. |
| No repository layout or file naming beyond the specification filename | ✓ None present. |

### E.8 Traceability Summary

Traceability is maintained to:

- Master Program: `Deletion & Audit Architecture Remediation Program v1.0`
- Golden Specification: `SPEC-001 Delete Framework Architecture Specification v1.1`
- Related Specifications: `SPEC-002 Audit Architecture v1.0`, `SPEC-005 Foreign Key Governance, TBD`
- Governance: `Architecture Specification Program v1.1`, `ARCHITECTURE_SPECIFICATION_INDEX.md v1.1`, `SPEC_BASELINE_CERTIFICATION.md v1.0`
- The full traceability matrix is recorded in Appendix D.

### E.9 Risk Assessment

- The primary residual risk is that SPEC-003's dependencies (none mandatory, optional SPEC-002, SPEC-005) are not yet baselined. This is acceptable for a foundation root per the Index dependency matrix (Section 6.2).
- The secondary risk is that operations may attempt to implement nested or long-running behavior as a single database transaction. This is mitigated by the Timeout Contract (CON-026, CON-027) and the Saga Contract (CON-017, CON-018, CON-019).
- No implementation, database, or operational rollout risks are introduced by this specification alone.

### E.10 Confirmation

- **No implementation performed.**
- **No repository source code modified.**
- **No database schema, schema changes, remote-call contracts, or edge/routing layer modified.**
- **No API, workflow, permissions, or business logic modified.**
- **No commit performed.**
- **No push performed.**
- **No operational rollout performed.**
- **No governance document modified.**
- **No existing Specification modified.**
- **Exactly one file created:** `ADMIN_DASHBOARD_PLAN_FIX_SPB/02_Specifications/SPEC-003_TRANSACTION_ARCHITECTURE_SPECIFICATION.md`.

---

*End of SPEC-003 — Transaction Architecture Specification v1.0*
