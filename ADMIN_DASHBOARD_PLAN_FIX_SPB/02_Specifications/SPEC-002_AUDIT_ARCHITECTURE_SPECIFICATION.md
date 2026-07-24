# SPEC-002 — Audit Architecture Specification

**Project:** VietSalePro  
**Subsystem:** Admin Dashboard / Enterprise Architecture  
**Specification Name:** Audit Architecture Specification  
**Short Identifier:** AuditArchitecture  
**Specification ID:** SPEC-002  
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
**Related Specifications:** SPEC-001 Delete Framework (dependent on SPEC-002), SPEC-005 Foreign Key Governance (optional)  
**Related ADRs:** None recorded.  
**Roadmap Items:** None recorded.  

---

## 16.1 Metadata

This specification is the authoritative architecture definition for the **Audit Architecture** of VietSalePro. It is a **Core** specification that establishes the independent, immutable, append-only audit model in which audit records survive the entities they describe. Its identifier is `SPEC-002`; its short identifier is `AuditArchitecture`; its version is `1.0`.

| Field | Value |
|---|---|
| Project | VietSalePro |
| Subsystem | Admin Dashboard / Enterprise Architecture |
| Specification ID | SPEC-002 |
| Name | Audit Architecture Specification |
| Short Identifier | AuditArchitecture |
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
| Related Specifications | SPEC-001 (dependent on SPEC-002), SPEC-005 (optional) |
| Related ADRs | None recorded |
| Roadmap Items | None recorded |

---

## 16.2 Purpose

**SPEC-002-PUR-001.** This document defines the enterprise Audit Architecture for VietSalePro.

**SPEC-002-PUR-002.** The Audit Architecture shall establish audit independence: audit records shall be immutable, append-only, and shall not depend on the continued existence of the operational entities they describe.

**SPEC-002-PUR-003.** The Audit Architecture shall provide the architectural foundation required by SPEC-001 (Delete Framework) for audit contracts, recovery model, failure model, verification requirements, and observability.

**SPEC-002-PUR-004.** The Audit Architecture shall define a unified audit model that spans both business audit (tenant-scoped actions performed by users) and system/admin audit (platform-scoped actions performed by system administrators and services), ensuring that both classes of audit records survive entity deletion and remain queryable for compliance, forensic, and operational purposes.

**SPEC-002-PUR-005.** This specification shall not prescribe implementation code, file names, table names, column types, deployment commands, or migration SQL. Those details belong in Implementation Plans derived from this specification.

---

## 16.3 Scope

**SPEC-002-SCO-001.** This specification covers the conceptual Audit Architecture and its canonical audit model for all auditable domains of VietSalePro.

**SPEC-002-SCO-002.** The following audit concerns are explicitly covered by this specification:

- Audit principles: immutability, independence, append-only semantics, completeness, traceability, non-repudiation, and tamper-evidence;
- Audit domain model: audit records, audit context, audit subjects, audit actors, audit events, and audit retention;
- Audit components: audit writer, audit store, audit query API, audit retention manager, audit integrity verifier, and audit export service;
- Audit interfaces and contracts: audit write, audit query, audit retention, audit immutability, audit independence, and audit integrity;
- Audit lifecycle: state machine governing audit record progression from creation through sealing, archival, and purge;
- Audit workflow and sequence for the critical paths: business mutation audit, deletion audit, and admin action audit;
- Audit data model: logical entities, independence from operational foreign keys, non-FK identifier storage, and metadata with lifecycle markers;
- Audit immutability invariants: append-only enforcement, no update or delete of audit rows, and tamper-evidence mechanisms;
- Audit independence: decoupling of audit records from operational entity lifecycles;
- Audit retention: retention policies, legal hold, export, and archival independent of operational data retention;
- Audit integrity: completeness checks, hash chaining, and tamper detection;
- Audit security: access control, encryption, least privilege, and forensic readiness;
- Audit observability: audit write metrics, integrity check alerts, and retention alerts;
- Failure model, recovery model, risks, constraints, verification requirements, and acceptance criteria.

**SPEC-002-SCO-003.** The Audit Architecture shall define how immutable audit records survive entity deletion. Specifically, when an operational entity (for example, a Tenant, User, Product, or Customer) is deleted, the audit records that reference that entity shall remain intact, queryable, and forensically complete.

**SPEC-002-SCO-004.** This specification does not define the internal schemas, RPC signatures, trigger implementations, or deployment artifacts of any specific implementation. Those are governed by related specifications and implementation plans.

**SPEC-002-SCO-005.** Future auditable domains introduced after initial implementation shall onboard to this Audit Architecture at design time; they shall not introduce independent audit models.

---

## 16.4 References

**SPEC-002-REF-001.** The following normative references govern this specification:

| Identifier | Title | Version | Purpose |
|---|---|---|---|
| Master Program | Deletion & Audit Architecture Remediation Program | v1.0 | Program vision, principles, workstreams, and scope; audit architecture redesign workstream (Section 10.2) |
| SPEC-001 | Delete Framework Architecture Specification | v1.1 (dependent) | Consumes SPEC-002 audit contracts (CON-012, CON-013), audit data model (DAT-004, DAT-005), and audit verification (VRF-005) |
| SPEC-005 | Foreign Key Governance Specification | TBD (optional dependency) | Explicit `ON DELETE` contract ensuring audit tables are not entangled with operational foreign keys |
| SPEC-004 | Trigger Governance Specification | TBD (related) | Trigger classification; audit triggers are converted to explicit audit writes per this specification |
| SPEC-006 | Observability Specification | TBD (related) | Observability instrumentation for audit write lifecycle |
| SPEC-007 | Regression & Verification Specification | TBD (related) | Regression coverage for audit immutability and independence |

---

## 16.5 Architecture Context

**SPEC-002-CTX-001.** The VietSalePro platform currently maintains a dual audit system: business audit (tenant-scoped, written to `app_audit_log` via database triggers and manual edge function calls) and admin audit (platform-scoped, written to `audit_log` via database triggers).

**SPEC-002-CTX-002.** The `delete-tenant` HTTP 500 incident demonstrated the core architectural deficiency: `audit_log.tenant_id` referenced `public.tenants(id)` as a foreign key, so an `AFTER DELETE` trigger could not write an audit row for a tenant that was being deleted within the same transaction. The audit record was coupled to the live entity it described.

**SPEC-002-CTX-003.** The underlying architectural deficiencies exposed by that incident are:

1. Audit records are coupled to live operational entities through foreign keys, so audit history cannot survive entity deletion.
2. Audit insertion is delegated to database triggers, making the audit workflow implicit, hard to test, and hard to reason about.
3. Audit records are split across multiple tables (`app_audit_log`, `app_audit_log_partitioned`, `audit_log`) with no unified independence model.
4. No tamper-evidence or integrity verification mechanism exists; audit records can be modified or deleted without detection.
5. No retention, legal hold, or archival policy is defined independently of operational data retention.
6. Audit records lack a consistent correlation identifier linking them to the operational request that produced them.

**SPEC-002-CTX-004.** The target architecture treats audit as an independent, immutable, append-only platform capability. Audit records are decoupled from operational entity lifecycles through non-foreign-key identifier storage. Audit writes are performed by explicit, testable code paths (the Audit Writer), not by implicit triggers. Both business audit and admin audit share the same independence, immutability, and integrity invariants.

**SPEC-002-CTX-005.** The Audit Architecture shall be technology-neutral: it may be realized through stored procedures, RPCs, edge functions, append-only event stores, hash-chained ledgers, write-once storage, or a combination thereof, provided the contracts and invariants defined in this specification are preserved.

---

## 16.6 Responsibilities

**SPEC-002-RES-001.** The responsibilities of each architectural layer in the Audit Architecture are:

| Layer | Responsibility |
|---|---|
| Application / Service | Capture audit context (actor, action, target, correlation ID, source metadata), construct the audit record, and submit it to the Audit Writer. |
| Audit Writer | Validate the audit record, enforce immutability invariants, persist the record append-only, seal it, and return a confirmation. |
| Audit Store | Provide append-only persistence with no update or delete capability for audit records; enforce row-level immutability at the storage layer. |
| Audit Query API | Provide read-only access to audit records with tenant-scoped and platform-scoped authorization; enforce least privilege. |
| Audit Retention Manager | Apply retention policies, enforce legal holds, manage archival, and authorize purge only when retention and legal constraints are satisfied. |
| Audit Integrity Verifier | Periodically verify audit completeness, hash chain continuity, and tamper-evidence; emit alerts on integrity violations. |
| Audit Export Service | Produce exportable audit bundles for compliance, legal, or external review without compromising immutability. |
| Database | Enforce append-only constraints, immutability triggers (reject UPDATE/DELETE), and referential independence (no FK to operational entities). |

**SPEC-002-RES-002.** Audit insertion shall not be performed by business-workflow triggers. Audit triggers, where retained, shall be limited to immutability enforcement (rejecting UPDATE or DELETE attempts on audit rows), not to writing audit records.

**SPEC-002-RES-003.** The Audit Writer shall be the sole component authorized to create audit records. No other component shall write directly to the audit store.

**SPEC-002-RES-004.** The Audit Retention Manager shall be the sole component authorized to purge audit records, and only when retention policies and legal hold constraints are satisfied and an explicit purge authorization is recorded.

---

## 16.7 Architecture Principles Mapping

**SPEC-002-PRM-001.** The Audit Architecture shall implement every relevant principle of the Master Program as follows:

| Principle | Mapping to Audit Architecture |
|---|---|
| Deletion is explicit | Audit records are written explicitly by the Audit Writer for every auditable operation, including deletes; no audit is produced as an implicit side effect of an unrelated operation. |
| Deletion is deterministic | The same auditable operation, given the same context, produces the same audit record content and the same integrity hash. |
| Deletion is idempotent | Replaying an audit write for an already-sealed record returns a stable confirmation without creating duplicate audit rows. |
| Deletion is observable | Every audit write carries a correlation identifier and produces an observability event visible across layers. |
| Deletion is recoverable | Audit write failures are retried or queued; audit records are reconstructable from request logs and the Audit Integrity Verifier. |
| Audit is immutable | Audit records are append-only; no UPDATE or DELETE is permitted except by the Audit Retention Manager under explicit purge authorization. Audit history outlives the entities it describes. |
| Database owns integrity | The database layer enforces append-only constraints, immutability triggers, and referential independence; it is the single source of truth for whether an audit write is valid. |
| Application owns workflow | Audit context capture, audit record construction, and audit write orchestration are owned by explicit application code, not by triggers. |
| Platform before feature | All auditable domains shall consume the canonical Audit Architecture; custom audit implementations are prohibited without exception. |
| Reuse before reinvention | Existing audit components (Audit Writer, Audit Store, Audit Query API) shall be consumed before new ones are created. |
| Side effects are compensatable | Audit export and archival are idempotent; failed exports are retried without duplicating audit records. |
| Failure is a first-class state | Audit write failure, integrity violation, and retention violation are modeled explicitly in the audit failure and recovery models. |

---

## 16.8 Domain Model

**SPEC-002-DOM-001.** The Audit Architecture domain consists of the following conceptual objects, each with a single responsibility:

| Concept | Responsibility |
|---|---|
| Audit Record | The immutable, append-only record of a single auditable event: actor, action, target type, target identifier, target snapshot, timestamp, correlation ID, source metadata, authorization context, and integrity hash. |
| Audit Context | The ambient information captured at audit time: tenant, actor identity, role, source IP, User-Agent, correlation ID, and authorization context. |
| Audit Subject | The operational entity that the audit record describes, referenced by type and identifier stored as non-foreign-key columns with a lifecycle marker. |
| Audit Actor | The user or service that performed the auditable action, referenced by identifier stored as a non-foreign-key column with a lifecycle marker. |
| Audit Event | The classification of the auditable action (create, update, delete, login, configuration change, billing action, compliance action, etc.). |
| Audit Retention Policy | The rule governing how long an audit record is retained, when it may be archived, and when it may be purged, independent of operational data retention. |
| Audit Legal Hold | A flag or marker that prevents purge or archival of audit records subject to legal or regulatory hold. |
| Audit Integrity Hash | A tamper-evidence value (hash chain link or content hash) computed over the audit record content and the previous record's hash, enabling detection of modification or deletion. |
| Audit Export Bundle | An exportable, signed collection of audit records produced for compliance, legal, or external review. |

**SPEC-002-DOM-002.** An `Audit Record` shall reference its `Audit Subject` and `Audit Actor` by identifier stored as non-foreign-key columns with lifecycle markers (for example, `active`, `deleted`, `purged`), not through foreign keys to operational tables.

**SPEC-002-DOM-003.** An `Audit Record` shall be immutable once sealed. No component other than the Audit Retention Manager shall be authorized to remove a sealed audit record, and only under explicit purge authorization satisfying retention and legal hold constraints.

**SPEC-002-DOM-004.** An `Audit Retention Policy` shall be independent of the retention of the operational entity the audit record describes. The deletion or purge of an operational entity shall not trigger the deletion or purge of its audit records.

---

## 16.9 Components

**SPEC-002-COM-001.** The Audit Architecture comprises the following logical components:

| Component | Role | Placement |
|---|---|---|
| Audit Writer | Validates audit records, enforces immutability invariants, persists records append-only, computes integrity hashes, and seals records. | Application / Database layer |
| Audit Store | Provides append-only persistence with no update or delete capability; enforces row-level immutability at the storage layer. | Database / persistence layer |
| Audit Query API | Provides read-only, authorized access to audit records with tenant-scoped and platform-scoped filtering. | Service / Edge layer |
| Audit Retention Manager | Applies retention policies, enforces legal holds, manages archival to cold storage, and authorizes purge. | Service / Operations layer |
| Audit Integrity Verifier | Periodically verifies audit completeness, hash chain continuity, and tamper-evidence; emits alerts on violations. | Operations / SRE layer |
| Audit Export Service | Produces signed, exportable audit bundles for compliance and external review without compromising immutability. | Service / Compliance layer |
| Audit Context Capture | Captures actor, source, correlation, and authorization context at the point of the auditable operation and constructs the audit record. | Application / Service layer |
| Audit Observability Emitter | Emits structured logs, metrics, and traces for audit write lifecycle, integrity checks, and retention actions. | All layers |

**SPEC-002-COM-002.** The `Audit Writer` shall be the sole component authorized to create and seal audit records.

**SPEC-002-COM-003.** The `Audit Store` shall reject any UPDATE or DELETE operation on sealed audit records except purge operations issued by the `Audit Retention Manager` with explicit authorization.

**SPEC-002-COM-004.** The `Audit Integrity Verifier` shall run on a defined schedule and shall emit an alert if any hash chain discontinuity, missing record, or content mismatch is detected.

---

## 16.10 Interfaces

**SPEC-002-INT-001.** The Audit Architecture exposes the following abstract interfaces:

### 16.10.1 Audit Write Interface

| Attribute | Type | Description |
|---|---|---|
| `audit_id` | UUID | Unique identifier for the audit record. |
| `correlation_id` | UUID | Propagated from the originating operational request. |
| `actor_id` | Identifier | The user or service that performed the action (non-FK). |
| `actor_lifecycle` | Lifecycle marker | `active`, `deleted`, `purged` — captured at audit time. |
| `actor_context` | Context | Tenant, role, authorization context, source IP, User-Agent. |
| `target_type` | Domain name | The domain type of the audited subject (Tenant, User, Product, etc.). |
| `target_id` | Identifier | The unique identifier of the audited subject (non-FK). |
| `target_lifecycle` | Lifecycle marker | `active`, `deleted`, `purged` — captured at audit time. |
| `action` | Audit Event | The classification of the auditable action. |
| `pre_state` | Snapshot | The state of the subject before the action (for mutations). |
| `post_state` | Snapshot | The state of the subject after the action (for mutations). |
| `timestamp` | Timestamp | The time the auditable action occurred. |
| `integrity_hash` | Hash | Tamper-evidence value computed over content and previous hash. |
| `metadata` | Key-value map | Retention class, legal hold flag, policy identifiers, approval references. |

### 16.10.2 Audit Query Interface

| Attribute | Type | Description |
|---|---|---|
| `filter` | Query filter | Tenant scope, actor, target type, target id, action, time range, correlation ID. |
| `authorization` | Context | Caller identity and role; determines tenant-scoped vs platform-scoped access. |
| `pagination` | Cursor | Cursor-based pagination for large audit result sets. |
| `result` | List of Audit Record | Read-only audit records matching the filter. |

### 16.10.3 Audit Retention Interface

| Attribute | Type | Description |
|---|---|---|
| `policy_id` | Identifier | The retention policy to apply. |
| `scope` | Filter | Tenant, domain, time range, or legal hold status. |
| `action` | Retention Action | `archive`, `purge`, `legal_hold`, `release_hold`. |
| `authorization` | Context | Caller identity and explicit purge or hold authorization. |

**SPEC-002-INT-002.** The Audit Write Interface shall accept an `Audit Record` from an authorized caller and return a sealed confirmation containing the `audit_id` and `integrity_hash`.

**SPEC-002-INT-003.** The Audit Query Interface shall be read-only and shall enforce tenant-scoped authorization for business audit and platform-scoped authorization for admin audit.

**SPEC-002-INT-004.** The Audit Retention Interface shall require explicit authorization for any `purge` or `legal_hold` action and shall record the authorizing actor and reason as an audit record itself.

---

## 16.11 Contracts

**SPEC-002-CON-001.** The Audit Architecture contracts are technology-neutral and implementation-neutral. Every implementation shall honor the following contracts:

### 16.11.1 Immutability Contract

**SPEC-002-CON-002.** Audit records shall be append-only. Once an audit record is sealed, no UPDATE operation shall be permitted on any field of that record.

**SPEC-002-CON-003.** No DELETE operation shall be permitted on a sealed audit record except by the Audit Retention Manager under explicit purge authorization satisfying retention and legal hold constraints.

**SPEC-002-CON-004.** The Audit Store shall enforce immutability at the storage layer through constraints, triggers that reject UPDATE/DELETE, or append-only storage semantics.

### 16.11.2 Independence Contract

**SPEC-002-CON-005.** Audit records shall not hold foreign keys that reference operational entity tables. Referenced entity identifiers shall be stored as non-foreign-key columns with lifecycle markers.

**SPEC-002-CON-006.** The deletion or purge of an operational entity shall not cause the deletion, nullification, or modification of any audit record that references that entity.

**SPEC-002-CON-007.** Audit records shall remain queryable by target identifier and target type after the referenced operational entity has been deleted, soft-deleted, or purged.

### 16.11.3 Write Contract

**SPEC-002-CON-008.** Every auditable operation shall produce exactly one audit record through the Audit Writer. The audit record shall contain the actor, action, target type, target identifier, target lifecycle marker, pre-state and post-state snapshots (for mutations), timestamp, correlation ID, and authorization context.

**SPEC-002-CON-009.** The Audit Writer shall compute an integrity hash over the audit record content and the previous sealed record's hash, forming a tamper-evident hash chain.

**SPEC-002-CON-010.** An audit write that fails shall be retried or queued. A failed audit write shall not cause the originating operational transaction to fail unless the operational contract requires audit-before-commit semantics (defined in SPEC-001 CON-012).

### 16.11.4 Query Contract

**SPEC-002-CON-011.** The Audit Query API shall return audit records matching the caller's authorization scope. Business audit queries shall be scoped to the caller's tenant; admin audit queries shall be scoped to system administrator authorization.

**SPEC-002-CON-012.** Audit queries shall support filtering by correlation ID, actor, target type, target identifier, action, and time range.

### 16.11.5 Retention Contract

**SPEC-002-CON-013.** Audit retention policies shall be defined independently of operational data retention. The retention of an audit record shall not be shortened by the deletion of the operational entity it describes.

**SPEC-002-CON-014.** A legal hold shall prevent purge or archival of affected audit records until the hold is explicitly released by an authorized actor, with the release recorded as an audit record.

**SPEC-002-CON-015.** Purge of audit records shall require explicit authorization, shall record the authorizing actor, reason, and retention policy basis, and shall produce a purge audit record before the purged records are removed.

### 16.11.6 Integrity Contract

**SPEC-002-CON-016.** The Audit Integrity Verifier shall periodically verify that the hash chain is continuous, that no sealed record is missing or modified, and that the audit store contains no records with broken integrity hashes.

**SPEC-002-CON-017.** An integrity violation shall emit a critical alert and shall create an incident record. Integrity violations shall not be silently repaired; repair requires explicit operator action and an audit record documenting the repair.

### 16.11.7 Idempotency Contract

**SPEC-002-CON-018.** Replaying an audit write for an already-sealed record (identified by `audit_id` or `correlation_id` plus action plus target) shall return the existing sealed confirmation without creating a duplicate audit record.

---

## 16.12 State Machine

**SPEC-002-STM-001.** Every audit record shall move through the governed lifecycle defined in this section.

### 16.12.1 Happy Path

```
CREATED
  ↓ audit record validated and persisted append-only
SEALED
  ↓ integrity hash computed and chain link established
RETAINED
  ↓ retention policy active; queryable
ARCHIVED
  ↓ moved to cold storage; still queryable via export
PURGED
  ↓ retention expired, no legal hold, explicit purge authorization
```

### 16.12.2 Legal Hold Path

```
SEALED / RETAINED / ARCHIVED
  ↓ legal hold applied
LEGAL_HOLD
  ↓ hold released by authorized actor
RETAINED or ARCHIVED
```

### 16.12.3 Transition Rules

| From | To | Guard | Owner | Action |
|---|---|---|---|---|
| CREATED | SEALED | Audit record validated, persisted append-only, integrity hash computed | Audit Writer | Seal record; establish hash chain link. |
| SEALED | RETAINED | Retention policy assigned | Audit Retention Manager | Assign retention class; record remains queryable. |
| RETAINED | ARCHIVED | Retention age threshold reached; no legal hold | Audit Retention Manager | Move to cold storage; record remains queryable via export. |
| ARCHIVED | PURGED | Retention expired; no legal hold; explicit purge authorization | Audit Retention Manager | Record purge audit; remove record. |
| SEALED / RETAINED / ARCHIVED | LEGAL_HOLD | Legal hold applied by authorized actor | Audit Retention Manager | Mark hold; block purge and archival. |
| LEGAL_HOLD | RETAINED or ARCHIVED | Hold released by authorized actor | Audit Retention Manager | Release hold; record release audit; resume retention lifecycle. |

**SPEC-002-STM-002.** `PURGED` is a terminal state. Once an audit record is purged, it cannot be restored except from an external backup; the purge audit record documenting the purge shall itself be retained and shall not be purged.

**SPEC-002-STM-003.** Every state transition shall be logged with previous state, new state, actor, timestamp, and reason. State transitions of audit records are themselves auditable events.

---

## 16.13 Workflow

**SPEC-002-WFL-001.** The canonical audit workflow consists of the following high-level stages:

1. **Capture Context** — At the point of an auditable operation, the Audit Context Capture component gathers actor, source, correlation ID, authorization context, and target metadata.
2. **Construct Record** — The application constructs an `Audit Record` with pre-state and post-state snapshots (for mutations) or action details (for non-mutation events).
3. **Submit to Audit Writer** — The application submits the audit record to the Audit Writer.
4. **Validate** — The Audit Writer validates the record structure, required fields, and authorization of the submitting caller.
5. **Compute Integrity** — The Audit Writer computes the integrity hash over the record content and the previous sealed record's hash.
6. **Persist Append-Only** — The Audit Writer persists the record to the Audit Store using append-only semantics.
7. **Seal** — The Audit Writer seals the record, establishing the hash chain link.
8. **Confirm** — The Audit Writer returns a sealed confirmation to the caller.
9. **Assign Retention** — The Audit Retention Manager assigns the retention policy class to the sealed record.

**SPEC-002-WFL-002.** If any stage from Validate through Seal fails, the audit write shall be retried or queued, and the Audit Writer shall emit a failure observability event.

**SPEC-002-WFL-003.** Audit writes shall not be performed by business-workflow triggers. Audit context capture and record construction shall be owned by explicit application code.

**SPEC-002-WFL-004.** The audit workflow shall support both synchronous (audit-before-commit) and asynchronous (audit-after-commit via outbox) modes, as defined by the operational contract in SPEC-001.

---

## 16.14 Sequence

**SPEC-002-SEQ-001.** The critical path for audit of a deletion operation shall follow this sequence:

```
Application / Delete Pipeline
  → Audit Context Capture: gather actor, correlation ID, target, source metadata
    → Audit Writer: validate audit record
      → Audit Writer: compute integrity hash (content + previous hash)
        → Audit Store: persist append-only
          → Audit Writer: seal record, establish chain link
            → Audit Writer: return sealed confirmation
              → Audit Observability Emitter: emit audit write log and metric
                → Audit Retention Manager: assign retention class
```

**SPEC-002-SEQ-002.** For a business mutation (for example, order creation, product update), the audit sequence shall occur within or immediately after the operational transaction, capturing pre-state and post-state snapshots.

**SPEC-002-SEQ-003.** For an admin action (for example, tenant creation, configuration change, system admin login), the audit sequence shall capture the admin actor, authorization context, and action details, and shall persist to the platform-scoped audit store.

**SPEC-002-SEQ-004.** If the Audit Store rejects the append-only write (for example, storage failure or constraint violation), the Audit Writer shall retry with backoff, and if retries are exhausted, shall queue the audit record for later replay and emit a critical alert. The originating operational transaction shall proceed or fail according to the audit-before-commit or audit-after-commit contract defined in SPEC-001.

---

## 16.15 Data Model

**SPEC-002-DAT-001.** The Audit Architecture data model is logical and conceptual. It does not prescribe physical table names, column types, or storage engines.

### 16.15.1 Core Entities

| Entity | Attributes | Ownership |
|---|---|---|
| Audit Record | audit_id, correlation_id, actor_id, actor_lifecycle, actor_context, target_type, target_id, target_lifecycle, action, pre_state, post_state, timestamp, integrity_hash, previous_hash, retention_class, legal_hold_flag, metadata | Audit Writer / Audit Store |
| Audit Retention Policy | policy_id, retention_duration, archival_threshold, purge_authorization_required, scope | Audit Retention Manager |
| Audit Legal Hold | hold_id, scope, applied_by, applied_at, reason, released_by, released_at | Audit Retention Manager |
| Audit Integrity Check | check_id, check_time, records_verified, chain_status, violations, alert_emitted | Audit Integrity Verifier |
| Audit Export Bundle | bundle_id, scope, time_range, record_count, signature, exported_by, exported_at | Audit Export Service |
| Audit Purge Record | purge_id, scope, records_purged, authorized_by, reason, retention_policy_basis, timestamp | Audit Retention Manager |

### 16.15.2 Referential Independence

**SPEC-002-DAT-002.** The `Audit Record` entity shall store `actor_id` and `target_id` as non-foreign-key columns with lifecycle markers. No foreign key shall reference an operational entity table.

**SPEC-002-DAT-003.** The `Audit Record` entity may be partitioned by tenant or by time for scalability, provided partitioning does not introduce foreign keys to operational entities.

### 16.15.3 Retention

**SPEC-002-DAT-004.** Audit retention shall be governed by the `Audit Retention Policy` entity, independent of operational data retention. The deletion of an operational entity shall not alter the retention of its audit records.

**SPEC-002-DAT-005.** Legal holds shall be recorded in the `Audit Legal Hold` entity and shall block purge or archival of affected audit records until released.

**SPEC-002-DAT-006.** Purge actions shall be recorded in the `Audit Purge Record` entity, which shall itself be retained as an audit record and shall not be subject to purge.

---

## 16.16 Failure Model

**SPEC-002-FAM-001.** The following failure modes are in scope for the Audit Architecture:

| ID | Failure Mode | Likelihood | Impact | Detection |
|---|---|---|---|---|
| SPEC-002-FAM-001 | Audit write fails (storage error, constraint violation) | Medium | High | Audit Writer returns error; retry or queue initiated. |
| SPEC-002-FAM-002 | Audit record corrupted in storage (bit rot, partial write) | Low | Critical | Audit Integrity Verifier detects content mismatch or broken hash. |
| SPEC-002-FAM-003 | Hash chain discontinuity (missing or inserted record) | Low | Critical | Audit Integrity Verifier detects chain break. |
| SPEC-002-FAM-004 | Unauthorized UPDATE or DELETE on sealed audit record | Low | Critical | Audit Store immutability constraint rejects operation; alert emitted. |
| SPEC-002-FAM-005 | Retention violation (purge attempted under legal hold or before retention expiry) | Low | Critical | Audit Retention Manager rejects purge; alert emitted. |
| SPEC-002-FAM-006 | Audit query returns records outside caller's authorization scope | Low | High | Audit Query API authorization check fails; access denied and logged. |
| SPEC-002-FAM-007 | Audit export fails or produces incomplete bundle | Low | Medium | Audit Export Service detects record count mismatch; retry initiated. |
| SPEC-002-FAM-008 | Audit write replay creates duplicate record | Low | Medium | Idempotency check detects existing sealed record; returns stable confirmation. |
| SPEC-002-FAM-009 | Audit context capture misses required metadata | Medium | Medium | Audit Writer validation rejects record; retry with complete context. |
| SPEC-002-FAM-010 | Integrity verification itself fails (verifier unavailable) | Low | High | Verifier health check fails; alert emitted; manual verification required. |

**SPEC-002-FAM-011.** Every failure mode shall have a corresponding recovery action defined in the Recovery Model.

**SPEC-002-FAM-012.** Audit failures shall not return generic errors without a structured error code, correlation ID, and recovery guidance.

---

## 16.17 Recovery Model

**SPEC-002-RCM-001.** The Audit Architecture recovery model shall handle each failure mode:

| Failure Mode | Recovery Action | Owner |
|---|---|---|
| Audit write failure | Retry with backoff; if exhausted, queue for replay; emit alert. | Audit Writer |
| Audit record corruption | Detect via integrity check; do not silently repair; create incident; operator reviews and reconstructs from request logs or backup. | Audit Integrity Verifier / Operations |
| Hash chain discontinuity | Detect via integrity check; emit critical alert; operator investigates missing or inserted record; document repair in audit record. | Audit Integrity Verifier / Operations |
| Unauthorized UPDATE/DELETE | Reject at storage layer; emit critical alert; investigate source of unauthorized operation. | Audit Store / Security |
| Retention violation | Reject purge; emit alert; record attempted violation as audit record. | Audit Retention Manager |
| Authorization scope violation | Deny access; log denied query as audit record; alert on repeated violations. | Audit Query API / Security |
| Export failure | Retry export; verify record count on completion; re-sign bundle. | Audit Export Service |
| Duplicate write replay | Return existing sealed confirmation; no duplicate created. | Audit Writer |
| Missing context | Reject record; require resubmission with complete context; log rejection. | Audit Writer |
| Verifier failure | Emit alert; fall back to manual verification; restore verifier. | Audit Integrity Verifier / SRE |

**SPEC-002-RCM-002.** The recovery model shall prefer replay and reconstruction over silent repair. Any repair to audit records shall be documented in an audit record itself.

**SPEC-002-RCM-003.** Audit reconstruction shall be supported from request logs, operational transaction logs, and the previous sealed hash, enabling recovery of lost audit records without compromising the hash chain.

**SPEC-002-RCM-004.** Manual operator recovery shall be supported through explicit reconstruction tooling with documented procedures, not through ad-hoc database edits.

---

## 16.18 Security

**SPEC-002-SEC-001.** Every audit write shall be submitted by an authorized caller. The Audit Writer shall validate the submitting caller's identity and authorization.

**SPEC-002-SEC-002.** Role-based access control shall enforce that only authorized actors may query business audit (tenant-scoped) and admin audit (platform-scoped). System administrators may query admin audit; tenant administrators may query their tenant's business audit.

**SPEC-002-SEC-003.** The Audit Store shall enforce row-level immutability through constraints or triggers that reject UPDATE and DELETE on sealed records, independent of application-layer controls.

**SPEC-002-SEC-004.** Audit records shall contain the actor identity, authorization context, source IP, and User-Agent to support forensic review and non-repudiation.

**SPEC-002-SEC-005.** The Audit Architecture shall resist tampering through hash chain integrity verification. Any modification or deletion of a sealed record shall be detectable by the Audit Integrity Verifier.

**SPEC-002-SEC-006.** Purge of audit records shall require elevated authorization and shall record the authorizing actor, reason, and retention policy basis as a purge audit record before the purged records are removed.

**SPEC-002-SEC-007.** Audit export bundles shall be cryptographically signed to support external verification and non-repudiation of exported audit content.

---

## 16.19 Observability

**SPEC-002-OBS-001.** The Audit Architecture shall emit structured observability data:

| Type | Requirement |
|---|---|
| Logs | Structured log per audit write, containing `audit_id`, `correlation_id`, `actor`, `target_type`, `target_id`, `action`, `state`, and any error code. |
| Metrics | Counter for audit writes initiated, sealed, failed, retried, purged, and exported; counter for integrity checks run and violations detected; partitioned by domain and action. |
| Traces | Distributed trace following the audit correlation ID across application, audit writer, audit store, and retention manager. |
| Alerts | Alert on sustained audit write failure rate, integrity violation detection, unauthorized immutability violation, retention violation, and verifier unavailability. |
| Dashboards | Dashboard showing audit write throughput, failure rate, integrity check status, retention lifecycle state distribution, and legal hold count. |

**SPEC-002-OBS-002.** The observability layer shall enable operators to reconstruct the full lifecycle of any audit record from `audit_id` or `correlation_id` without querying the audit store directly.

**SPEC-002-OBS-003.** All integrity violations and retention violations shall include structured error codes and recovery guidance suitable for security, compliance, and operations staff.

---

## 16.20 Risks

**SPEC-002-RSK-001.** The following risks are introduced or mitigated by the Audit Architecture:

| ID | Risk | Likelihood | Impact | Owner | Mitigation |
|---|---|---|---|---|---|
| SPEC-002-RSK-001 | A new auditable domain bypasses the canonical Audit Architecture and invents a local audit path. | Medium | High | Chief Technical Advisor | Mandatory architecture review and audit onboarding for every new domain. |
| SPEC-002-RSK-002 | Audit records fail to outlive the deleted entity due to residual foreign keys introduced during schema evolution. | Low | Critical | Security & Compliance | FK review per SPEC-005; audit independence validation in CI. |
| SPEC-002-RSK-003 | Hash chain integrity is compromised by a storage-level corruption that is not detected between verification runs. | Low | Critical | SRE / Platform Operations | Increase verification frequency; use write-once storage where feasible. |
| SPEC-002-RSK-004 | Audit write latency impacts operational transaction performance under audit-before-commit semantics. | Medium | Medium | Platform Engineering | Async audit-after-commit mode for non-critical paths; performance budget per SPEC-001. |
| SPEC-002-RSK-005 | Retention policy is misconfigured and purges audit records subject to legal hold. | Low | Critical | Security & Compliance | Legal hold check before purge; purge authorization required; purge audit record. |
| SPEC-002-RSK-006 | Audit query authorization is misconfigured and exposes cross-tenant audit data. | Low | Critical | Security | Tenant-scoped authorization enforcement; denied-query logging; periodic access review. |
| SPEC-002-RSK-007 | Audit reconstruction from logs is incomplete after a storage failure. | Low | High | SRE / Platform Operations | Regular reconstruction drills; backup of audit store; integrity verification after reconstruction. |

---

## 16.21 Constraints

**SPEC-002-CST-001.** The Audit Architecture shall operate within the following constraints:

| ID | Constraint | Source |
|---|---|---|
| SPEC-002-CST-001 | The Audit Architecture shall be technology-neutral and shall not assume any specific database, runtime, or storage engine. | Architecture Specification Program Section 18. |
| SPEC-002-CST-002 | Audit records shall be immutable and shall outlive the entity they describe. | Master Program Guiding Principle 2. |
| SPEC-002-CST-003 | Audit tables shall not hold foreign keys that prevent them from surviving the deletion of the entities they reference. | Master Program Section 10.2. |
| SPEC-002-CST-004 | Audit insertion shall not be performed by business-workflow triggers. | Master Program Guiding Principle 3. |
| SPEC-002-CST-005 | Audit retention shall be independent of operational data retention. | Master Program Section 10.2. |
| SPEC-002-CST-006 | Every auditable domain shall consume the canonical Audit Architecture. | Master Program Section 9. |
| SPEC-002-CST-007 | Audit failures shall be structured and shall include correlation IDs and recovery guidance. | Master Program Success Criteria. |

---

## 16.22 Non-goals

**SPEC-002-NGO-001.** This specification explicitly does not cover:

1. Implementation code, file names, package structures, or deployment commands.
2. Concrete table names, column types, RPC signatures, or trigger implementations.
3. Specific technology choices such as a particular append-only store, hash chain algorithm, or archival system.
4. Legal or tax record retention policy decisions (these are inputs to audit retention, not outputs of this specification).
5. User-interface design for audit log viewers or compliance dashboards.
6. Migration scripts for moving from the legacy dual audit system to the canonical Audit Architecture, which belong in a Migration Specification or Implementation Plan.
7. Day-to-day operational runbooks for audit integrity verification or retention management, which belong in Operational Specifications.
8. Specific e-invoice or billing provider audit requirements beyond the audit event classification.

---

## 16.23 Verification Requirements

**SPEC-002-VRF-001.** The Audit Architecture implementation shall be verified against the following requirements:

| ID | Verification Requirement | Method |
|---|---|---|
| SPEC-002-VRF-001 | Every auditable domain uses the canonical Audit Writer. | Static code review and governance audit. |
| SPEC-002-VRF-002 | Audit state machine transitions match Section 16.12. | State-transition unit tests. |
| SPEC-002-VRF-003 | Audit records are append-only; no UPDATE or DELETE succeeds on sealed records. | Immutability enforcement tests. |
| SPEC-002-VRF-004 | Audit records survive the deletion of the operational entity they reference. | Audit independence integration tests with entity deletion. |
| SPEC-002-VRF-005 | Audit records contain no foreign keys to operational entity tables. | Schema review and FK audit per SPEC-005. |
| SPEC-002-VRF-006 | Hash chain integrity verification detects modification or deletion of sealed records. | Integrity injection tests. |
| SPEC-002-VRF-007 | Replaying an audit write returns a stable confirmation without duplicate records. | Idempotency integration tests. |
| SPEC-002-VRF-008 | Audit queries enforce tenant-scoped and platform-scoped authorization. | Authorization scope tests. |
| SPEC-002-VRF-009 | Legal hold blocks purge until explicitly released; purge requires authorization and produces a purge audit record. | Retention and legal hold tests. |
| SPEC-002-VRF-010 | Audit observability emits logs, metrics, and traces with the correlation ID. | Observability integration tests. |

---

## 16.24 Acceptance Criteria

**SPEC-002-ACC-001.** The Audit Architecture specification and its implementation are accepted when:

1. All mandatory sections are present and reviewed.
2. All requirements carry unique identifiers and are traceable to verification requirements and acceptance criteria.
3. The implementation passes all verification requirements in Section 16.23.
4. No auditable domain contains an independent audit implementation outside the canonical Audit Architecture.
5. Audit records survive the deletion of the entities they reference, verified by integration tests with entity deletion.
6. Immutability enforcement tests confirm that no UPDATE or DELETE succeeds on sealed audit records.
7. Hash chain integrity verification detects injected modifications or deletions.
8. Legal hold and retention policies are enforced; purge requires authorization and produces a purge audit record.
9. Audit queries enforce tenant-scoped and platform-scoped authorization.
10. The Production Owner approves the specification and the implementation.

---

## 16.25 Future Evolution

**SPEC-002-FEV-001.** The Audit Architecture is designed to evolve without redesign. The following extension points are preserved:

| Extension | Description |
|---|---|
| New auditable domains | New domains shall register with the Audit Architecture by providing an audit event classification and audit context capture integration. |
| New audit event classifications | New audit event types shall be added through the audit event registry without changing the audit writer or audit store. |
| Cold archival | Audit records may be cold-archived to long-term storage after a retention threshold without altering the audit model semantics. |
| Multi-region audit | The Audit Architecture may be extended to region-aware audit storage by including region in the audit context. |
| External audit ledger | The hash chain may be anchored to an external tamper-evident ledger (for example, a notarization service) for enhanced non-repudiation. |
| Streaming audit | Audit writes may be streamed to an event bus or audit stream for real-time compliance monitoring without changing the audit store contract. |
| AI-assisted anomaly detection | Audit event patterns may be analyzed for anomalous delete or mutation patterns without altering the audit record schema. |

**SPEC-002-FEV-002.** Any change that alters the immutability contract, the independence contract, or the integrity hash scheme shall require an Architecture Decision Record per the Master Program Section 29.

---

## 16.26 Appendix

### A. Audit Event Classification Matrix

| Event Class | Scope | Trigger | Pre-State | Post-State | Retention Class |
|---|---|---|---|---|---|
| Business Create | Tenant | Entity creation (order, product, customer, etc.) | None | Created entity snapshot | Standard |
| Business Update | Tenant | Entity modification | Pre-modification snapshot | Post-modification snapshot | Standard |
| Business Delete | Tenant | Entity deletion (soft, hard, purge) | Pre-delete snapshot | Deletion confirmation | Extended |
| Business Return/Exchange | Tenant | Return or exchange transaction | Pre-return snapshot | Post-return snapshot | Standard |
| Business Inventory | Tenant | Inventory count, stock movement, disposal | Pre-action snapshot | Post-action snapshot | Standard |
| Business Import/Purchase | Tenant | Import receipt creation, supplier exchange | Pre-action snapshot | Post-action snapshot | Standard |
| Admin Tenant Management | Platform | Tenant create, update, delete, subdomain change | Pre-action snapshot | Post-action snapshot | Extended |
| Admin User Management | Platform | User create, delete, role change, 2FA override | Pre-action snapshot | Post-action snapshot | Extended |
| Admin Billing | Platform | Invoice create, payment confirm, webhook | Pre-action snapshot | Post-action snapshot | Extended |
| Admin Configuration | Platform | System settings, feature flags, global config | Pre-change snapshot | Post-change snapshot | Extended |
| Admin Security | Platform | Login, 2FA, impersonation, password reset | Action metadata | Action result | Extended |
| Admin Compliance | Platform | GDPR request, legal hold, purge authorization | Action metadata | Action result | Extended |
| Audit Lifecycle | Platform | Audit seal, archive, purge, legal hold, integrity check | Action metadata | Action result | Permanent |

### B. Audit Independence Reference Model

| Operational Entity | Audit Reference Storage | Lifecycle Marker | Survival on Entity Delete |
|---|---|---|---|
| Tenant | `target_id` (non-FK), `target_type='Tenant'` | `deleted` / `purged` | Audit records remain; queryable by `target_id`. |
| User | `actor_id` or `target_id` (non-FK), `target_type='User'` | `deleted` / `purged` | Audit records remain; actor identity preserved in snapshot. |
| Product | `target_id` (non-FK), `target_type='Product'` | `deleted` / `purged` | Audit records remain; product snapshot preserved. |
| Customer | `target_id` (non-FK), `target_type='Customer'` | `deleted` / `purged` | Audit records remain; customer snapshot preserved. |
| Membership | `target_id` (non-FK), `target_type='Membership'` | `deleted` / `purged` | Audit records remain; membership snapshot preserved. |
| Subscription | `target_id` (non-FK), `target_type='Subscription'` | `deleted` / `purged` | Audit records remain; subscription snapshot preserved. |

### C. Glossary

| Term | Definition |
|---|---|
| Audit Record | The immutable, append-only record of a single auditable event. |
| Audit Context | The ambient information captured at audit time (actor, source, correlation, authorization). |
| Audit Subject | The operational entity described by an audit record, referenced by non-FK identifier. |
| Audit Actor | The user or service that performed the auditable action, referenced by non-FK identifier. |
| Audit Event | The classification of the auditable action. |
| Audit Writer | The sole component authorized to create and seal audit records. |
| Audit Store | The append-only persistence layer enforcing row-level immutability. |
| Audit Integrity Hash | A tamper-evidence value forming a hash chain over audit records. |
| Audit Retention Policy | The rule governing audit record retention, archival, and purge. |
| Audit Legal Hold | A marker preventing purge or archival of affected audit records. |
| Lifecycle Marker | A non-FK column indicating the operational entity's lifecycle state at audit time. |
| Sealed | The state of an audit record after the integrity hash is computed and the chain link is established. |

### D. Traceability Summary

| This Specification Section | Traces To |
|---|---|
| 16.2 Purpose | Master Program Sections 1, 2, 3, 7, 8, 10.2 |
| 16.3 Scope | Master Program Section 9, 10.2 |
| 16.5 Architecture Context | Master Program Sections 4, 5, 6, 10.2 |
| 16.6 Responsibilities | Master Program Section 10.2, 10.6 |
| 16.7 Architecture Principles Mapping | Master Program Section 23 |
| 16.8 Domain Model | Master Program Section 10.2, 24 |
| 16.9 Components | Master Program Section 10.2 |
| 16.10 Interfaces | Master Program Section 10.2 |
| 16.11 Contracts | Master Program Section 10.2; SPEC-001 CON-012, CON-013 |
| 16.12 State Machine | Master Program Section 10.2 |
| 16.13 Workflow | Master Program Section 10.2, 10.6 |
| 16.14 Sequence | Master Program Sections 10.1, 10.2, 10.6 |
| 16.15 Data Model | Master Program Section 10.2; SPEC-001 DAT-004, DAT-005 |
| 16.16 Failure Model | Master Program Section 28; SPEC-001 FAM-005 |
| 16.17 Recovery Model | Master Program Sections 10.2, 28 |
| 16.18 Security | Master Program Section 10.2 |
| 16.19 Observability | Master Program Section 10.2, 10.8; SPEC-001 OBS |
| 16.20 Risks | Master Program Section 15, 28 |
| 16.21 Constraints | Master Program Sections 7, 10.2 |
| 16.23 Verification Requirements | Master Program Section 20; SPEC-001 VRF-005 |
| 16.24 Acceptance Criteria | Master Program Section 13, 14 |
| 16.25 Future Evolution | Master Program Section 17 |

---

## Evidence

### E.1 Foundation Documents Consulted

The following foundation documents were read and followed:

1. `.codebase-memory/CODEBASE_MEMORY_BASELINE.md` — Project baseline, stack, validation status, knowledge priority, known limitations.
2. `.codebase-memory/SEMANTIC_MEMORY.md` — Architecture overview, business modules, audit logging dual system (Section 4.6), audit tables (Section 5.1), audit triggers (Section 5.4), audit edge function (Section 6.2), audit services (Section 7).
3. `.codebase-memory/VALIDATION_REPORT.md` — Confidence scores, known limitations, corrections, risk register.

### E.2 Governance Documents Consulted

The following governance documents were read in the required order:

1. `Deletion_Audit_Architecture_Remediation_Program.md` (Master Program v1.0) — Vision, principles, goals, workstreams (Section 10.2 Audit Architecture Redesign), scope, state machine, domain model, classification, dependency matrix, risks, success criteria.
2. `01_Governance/Architecture_Specification_Program.md` (Specification Program v1.1) — Mandatory template (Sections 16.1–16.26), metadata, versioning, naming, folder structure, traceability, dependency, quality gates, identifier registry, status model, classification, dependency framework, registry, index governance, navigation, consistency, approval clarification, expansion.
3. `01_Governance/ARCHITECTURE_SPECIFICATION_INDEX.md` (Index v1.1) — SPEC-002 registration, classification, dependencies, portfolio position, authoring order, lifecycle dashboard, traceability matrix.

### E.3 Cross-Validation Results

| Check | Result |
|---|---|
| SPEC-002 exists inside the Index | ✓ Found in Index Section 5.2 and Catalog Summary Table (Section 5.3). |
| Specification ID matches | ✓ SPEC-002 in both Index and this specification. |
| Specification Name matches | ✓ "Audit Architecture Specification" in both. |
| Classification matches | ✓ Core. |
| Dependencies match | ✓ No mandatory dependencies (foundation root). Optional: SPEC-005. |
| Authoring order matches | ✓ SPEC-002 is #2 in recommended sequence (foundation root); audit design precedes delete design per Master Program Section 19. |
| Workstream matches Master Program | ✓ Audit Architecture Redesign (Master Program Section 10.2). |
| Scope matches Master Program | ✓ Audit independence, business audit, system/admin audit, historical data preservation, audit independence, long-term traceability, referential integrity strategy, lifecycle of audit records (Master Program Section 10.2). |
| Required template matches | ✓ All 26 mandatory sections of the Specification Program are present. |
| Governance version consistent | ✓ Master Program v1.0, Spec Program v1.1, Index v1.1, Baseline Certification v1.0. |

**No inconsistencies were detected. No `GOVERNANCE_INCONSISTENCY_REPORT.md` is required.**

### E.4 Extracted Governance Summary

- **Mandatory template:** 26 sections (16.1–16.26) per the Architecture Specification Program.
- **Normative language:** Requirements use `shall`, `must`, `must not`, `should`, `may`.
- **Technology neutral:** No product-specific or framework-specific implementation details.
- **Traceability:** Requirement identifiers use `SPEC-002-<SECTION>-<NNN>`.
- **Dependencies:** SPEC-002 is Core, a foundation root with no mandatory dependencies; optional dependency on SPEC-005.
- **Approval flow:** Author → Chief Technical Advisor Review → Production Owner Approval → Baseline.
- **Status model:** Draft → Review → Approved → Baselined → Implementation Ready → Implementation Active → Verified → Accepted.

### E.5 Portfolio Validation

- SPEC-002 is registered in the Architecture Specification Index (Section 5.2).
- Classification: Core.
- Priority: P1 — Critical.
- Target folder: `02_Specifications/`.
- Dependency graph is acyclic; SPEC-002 is a foundation root with no mandatory dependencies, and is depended on by SPEC-001 (mandatory), SPEC-006 (optional), and SPEC-007 (optional).

### E.6 Dependency Validation

- Mandatory dependencies declared: none (foundation root per Index Section 5.2).
- Optional dependency declared: SPEC-005 (Foreign Key Governance) for audit-independence reasoning.
- No circular dependencies are introduced.
- SPEC-002 provides the architectural foundation for SPEC-001 audit contracts (CON-012, CON-013), audit data model (DAT-004, DAT-005), audit failure mode (FAM-005), audit verification (VRF-005), and audit observability. These dependencies are declared in SPEC-001, not in SPEC-002, consistent with the foundation-root model.

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

- All requirements are uniquely identified with `SPEC-002-<SECTION>-<NNN>`.
- All sections trace to the Master Program (Section 10.2 Audit Architecture Redesign) or related specifications.
- Verification requirements trace to acceptance criteria.
- Failure modes trace to recovery actions.
- Risks trace to mitigations.
- Cross-references to SPEC-001, SPEC-005 use identifier and version reference style.
- SPEC-001 dependencies on SPEC-002 (CON-012, CON-013, DAT-004, DAT-005, FAM-005, VRF-005) are satisfied by the contracts and invariants defined in this specification.

### E.9 Risk Assessment

- The primary residual risk is that the optional dependency on SPEC-005 (Foreign Key Governance) is not yet baselined, which may delay full audit-independence validation. This is mitigated by the audit independence contract (CON-005 through CON-007) and the FK audit verification requirement (VRF-005).
- The secondary risk is that legacy audit triggers may resist removal; this is mitigated by the trigger governance in SPEC-004 and the explicit audit-write ownership rule (RES-002, RES-003).
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

*End of SPEC-002 — Audit Architecture Specification v1.0*
