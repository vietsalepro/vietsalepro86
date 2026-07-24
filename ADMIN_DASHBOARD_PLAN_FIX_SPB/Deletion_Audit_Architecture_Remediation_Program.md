# Deletion & Audit Architecture Remediation Program

**Project:** VietSalePro  
**Subsystem:** Admin Dashboard  
**Program Name:** Deletion & Audit Architecture Remediation Program  
**Version:** 1.0  
**Status:** Architecture Program — Not Yet Implementation  

---

## 1. Executive Summary

The VietSalePro Admin Dashboard currently cannot reliably delete a tenant. The immediate symptom is an HTTP 500 from the `delete-tenant` Edge Function, but the underlying cause is architectural: deletion is treated as an ad-hoc database operation rather than a first-class platform capability, audit history is coupled to entities that may be deleted, transaction ownership is split across layers, and trigger logic encodes business workflows that are invisible to the rest of the stack.

This document defines the **Deletion & Audit Architecture Remediation Program**. It is the single source of truth for all future remediation work. The program redesigns deletion, audit, transaction management, trigger governance, foreign key policy, and observability so that failures of this class cannot reappear in any domain.

The intended outcome is a platform where every delete operation is explicit, atomic, auditable, recoverable, and reusable across Tenant, User, Product, Customer, Warehouse, Employee, Membership, Subscription, and all future modules.

---

## 2. Business Motivation

- **Operational risk:** System administrators cannot remove a tenant cleanly. Failed deletes can leave orphaned storage objects, orphaned auth users, and inconsistent audit records.
- **Compliance risk:** Audit records must outlive the entities they describe. Coupling audit rows to live entities creates gaps in traceability.
- **Velocity risk:** Every new module reinvents delete semantics. Without a canonical framework, each domain will repeat the same trigger, transaction, and foreign-key mistakes.
- **Reliability risk:** Partial deletions are visible to users and regulators. A hard delete that removes some artifacts and not others is worse than a delete that never starts.
- **Supportability risk:** When deletion fails, the system does not identify the failing step, the affected resources, or the recovery path.

---

## 3. Architecture Vision

Delete becomes a **first-class platform capability**. It is not a SQL statement scattered through Edge Functions, services, and triggers. It is a governed, reusable framework with the following properties:

1. **Canonical delete pipeline** — one pattern for every deletable domain.
2. **Audit independence** — audit history is immutable, append-only, and not dependent on the continued existence of the entity it records.
3. **Single transactional ownership** — the database owns the atomic delete boundary; external side effects are idempotent and run outside the critical transaction or via an outbox.
4. **No business logic hidden in triggers** — triggers enforce low-level invariants only.
5. **Explicit foreign key contract** — every relationship declares, documents, and validates its `ON DELETE` behavior.
6. **Observable delete lifecycle** — every delete carries a correlation identifier, step-level tracking, structured errors, and recovery guidance.

---

## 4. Current Problems

### 4.1 The `delete-tenant` failure pattern

The current path follows this sequence:

```
Admin UI
  → Edge Function: delete-tenant
  → DELETE FROM public.tenants WHERE id = <tenant_id>
  → AFTER DELETE trigger
  → INSERT INTO public.audit_log (..., tenant_id, ...)
  → FK violation: audit_log.tenant_id REFERENCES public.tenants(id)
  → Postgres error
  → Edge Function catch block returns HTTP 500
```

The trigger attempts to write an audit row using the identifier of a row that no longer exists within the same transaction. The `ON DELETE SET NULL` behavior on the existing audit foreign key does not help because the new audit row cannot reference a deleted row, and the deleted row has not yet committed.

### 4.2 Architectural weaknesses exposed by the incident

- **Audit is coupled to live entities.** `audit_log.tenant_id` references `public.tenants(id)`, so audit history cannot be written for an entity that is being removed. This is the wrong direction of dependency: audit should outlive the entity.
- **Triggers contain business workflow logic.** Audit insertion is delegated to an `AFTER DELETE` trigger. This makes the delete workflow implicit, hard to test, and hard to reason about.
- **No single transaction owner.** Storage objects, auth users, orphan rows, and the tenant row are deleted in multiple places. Some operations are inside the database transaction; some are not. A failure at any point leaves partial state.
- **No canonical delete framework.** Every domain is free to implement its own delete path. Similar failures are therefore expected to recur in User, Product, Customer, Warehouse, Employee, Membership, Subscription, and future modules.
- **No observable delete lifecycle.** When the HTTP 500 is returned, the frontend, support team, and operators cannot determine which step failed or what has already been removed.
- **Foreign key policies are not reviewed as architecture.** `ON DELETE` behaviors were chosen locally per table without a global risk model, leading to cascade surprises, undeletable graphs, and lost context.

---

## 5. Root Cause Summary

The `delete-tenant` HTTP 500 is not a one-line bug. It is the result of five interacting architectural deficiencies:

1. **Wrong audit dependency direction.** Audit records reference a tenant that is being deleted. Because audit must be preserved, the foreign key relationship must allow audit to survive the tenant, not the reverse.
2. **Trigger-side business logic.** Writing audit records inside an `AFTER DELETE` trigger turns a data-preservation concern into a fragile, implicit side effect of a low-level SQL statement.
3. **No transaction boundary around the entire delete.** The Edge Function issues separate deletions for storage, auth, and database objects. The database `DELETE` is not wrapped in a single stored procedure or RPC that can roll back if any invariant fails.
4. **Unclear layer responsibilities.** The frontend, service, Edge Function, and database each own pieces of deletion but none owns the end-to-end contract.
5. **Missing deletion governance.** There is no architectural rule stating how delete workflows must be built, reviewed, tested, or observed.

Patching the trigger alone would only remove this specific error. It would not prevent the next failure in another table, another domain, or another environment.

---

## 6. Why This Requires an Architectural Redesign

A local fix is insufficient for the following reasons:

- **Symptom vs. system.** The FK violation is a symptom. The system-level problem is that deletion, audit, and transaction architecture are undefined.
- **Reproducibility.** The same pattern of trigger + audit FK + split transaction exists, or will exist, in every module that hard-deletes records.
- **Audit durability.** A design that requires an entity to remain in order to record its removal is architecturally inverted.
- **Operational integrity.** Hard deletes must be atomic or recoverable. The current code is neither.
- **Future cost.** Without a canonical framework, every new domain repeats analysis, design, testing, and debugging that should be solved once.

---

## 7. Guiding Principles

1. **Deletion is a domain capability, not a SQL shortcut.** Every deletion passes through a canonical pipeline.
2. **Audit history must survive the entity.** Audit records are immutable and independent of the operational lifecycle of the subjects they describe.
3. **Triggers guard; services decide.** Triggers may enforce invariants (e.g., prevent accidental deletes). Business workflows, audit, and cascading decisions belong in explicit, testable code paths.
4. **One transaction owner.** The database layer owns the atomic transaction for the delete. Cross-service side effects are idempotent and run under a separate, compensatable model.
5. **Explicit by default.** Every `ON DELETE`, `CASCADE`, `SET NULL`, and `RESTRICT` is documented and risk-assessed.
6. **Delete is observable.** Every delete request carries a correlation ID, a step trace, and structured error metadata.
7. **No delete without validation.** No new delete feature ships without integration, database, transaction, and failure-recovery tests.
8. **Platform reuse over local invention.** Future modules reuse the canonical delete framework; they do not invent a new one.

---

## 8. Architecture Goals

| Goal | Description |
|------|-------------|
| **Canonical Delete Framework** | A single, reusable deletion pipeline for all domains. |
| **Audit Independence** | Audit records are decoupled from the continued existence of operational entities. |
| **Atomic Deletion** | A delete either completes fully or leaves the system in a recoverable, pre-delete state. |
| **Trigger Rationalization** | Triggers are classified, minimized, and stripped of business workflow logic. |
| **FK Clarity** | Every foreign key has an explicit, reviewed `ON DELETE` contract. |
| **Governed Workflow** | Layers have clear, separated responsibilities and no feature bypasses the framework. |
| **Observable & Recoverable** | Deletes are traceable, failures are attributable, and recovery guidance is explicit. |
| **Regression-Protected** | Every delete path is covered by integration, database, trigger, transaction, edge-function, and failure-recovery tests. |

---

## 9. Program Scope

This program covers the Admin Dashboard delete and audit architecture and all platform modules that perform deletions. The following domains are explicitly in scope:

- Tenant
- User
- Product
- Customer
- Warehouse
- Employee
- Membership
- Subscription

The program produces architecture specifications, governance rules, and verification criteria. It does **not** produce implementation code, migrations, or trigger changes. Those are future workstreams governed by this document.

---

## 10. Program Workstreams

### 10.1 Delete Framework Redesign

Design a canonical deletion framework reusable across the entire platform.

**Elements:**

- Define deletion lifecycle states: `active`, `soft-deleted`, `pending-purge`, `purged`, `archived`.
- Define deletion modes: `soft`, `hard`, `purge`, `bulk`.
- Define a canonical delete API contract for frontend, service, Edge Function, and database.
- Specify a single database deletion owner (e.g., a dedicated RPC or stored function) for each domain.
- Specify idempotent, compensatable side-effect handlers for storage and auth cleanup.
- Provide a per-domain deletion checklist and risk register.

**Reusability target:**

All listed domains — Tenant, User, Product, Customer, Warehouse, Employee, Membership, Subscription — must use the canonical framework. Future modules are prohibited from introducing independent delete implementations.

### 10.2 Audit Architecture Redesign

Redesign audit to preserve history without binding it to live entities.

**Key analyses:**

- **Business Audit** — Records actions performed by users inside a tenant: who changed what, when, from where. Must be queryable by tenant administrators and support staff.
- **System/Admin Audit** — Records platform-level actions performed by system administrators and services: tenant deletion, user provisioning, configuration changes. Must remain available after the tenant or user is removed.
- **Historical data preservation** — Audit must be append-only and immutable. Updates and deletes of audit rows are prohibited.
- **Audit independence** — Audit tables must not hold foreign keys that would prevent them from surviving the deletion of the entities they reference. Referenced identifiers may be stored as non-FK columns or inside JSONB metadata with lifecycle markers.
- **Long-term traceability** — Each audit row must include: actor, action, target type, target identifier, target snapshot, timestamp, correlation ID, source IP/User-Agent, and authorization context.
- **Referential integrity strategy** — Operational data may reference audit rows for history; audit rows must not reference operational data in a way that blocks deletion.
- **Lifecycle of audit records** — Define retention, legal hold, export, and archival policies independent of operational data retention.

### 10.3 Transaction Architecture

Define the canonical transaction strategy for deletions.

**Principles:**

- **Atomicity:** The database-layer delete function commits or rolls back as a single transaction.
- **Consistency:** The database transaction enforces all invariants before commit. No partial row deletions are persisted.
- **Rollback:** A deletion that cannot satisfy its invariants rolls back completely.
- **Failure recovery:** Side effects outside the database (storage, auth, external systems) use idempotent cleanup or an outbox pattern. Failures in side effects do not compromise the database transaction.
- **No partial deletion:** If a delete fails before commit, the entity and all dependent data remain unchanged.
- **Single transactional ownership:** Exactly one component owns the transaction. Edge Functions may initiate; the database layer commits.

**Required outcome:**

A documented transaction boundary model and a decision matrix for when to use synchronous commit, outbox, or compensating actions.

### 10.4 Trigger Review Program

Review every database trigger involved in delete workflows.

**Activities:**

- Inventory all triggers on deletable tables.
- Classify each trigger as: `guardrail`, `audit`, `cascade`, `denormalized-cache`, `business-workflow`, or `legacy`.
- Recommend retention or removal for each class.
- Move `business-workflow` triggers into explicit, testable code paths.
- Keep `guardrail` triggers only for low-level invariants that must be enforced at the database level.
- Convert `audit` triggers into explicit audit writes performed by the canonical delete framework.
- Document every remaining trigger with its purpose, risk, and test coverage.

### 10.5 Foreign Key Review

Review all foreign key constraints and `ON DELETE` behaviors.

**Scope:**

- Every `REFERENCES` clause in the operational schema.
- All `ON DELETE` / `ON UPDATE` settings: `CASCADE`, `SET NULL`, `RESTRICT`, `NO ACTION`.

**Objectives:**

- Identify `CASCADE` chains that can silently delete data beyond the intended scope.
- Identify `SET NULL` columns that lose business context after deletion.
- Identify `RESTRICT` / `NO ACTION` constraints that create undeletable subgraphs.
- Identify cyclic dependencies that can deadlock or prevent deletion.
- Produce a risk register and a per-table recommended `ON DELETE` policy.
- Ensure audit and historical tables are not entangled with operational foreign keys.

### 10.6 Deletion Workflow Governance

Define the canonical deletion workflow and the responsibilities of each layer.

| Layer | Responsibility |
|-------|----------------|
| **Frontend** | Render deletion action, request confirmation, capture user intent, display status and errors, prevent duplicate submission. |
| **Service** | Validate input, check caller permissions, attach correlation IDs, route to the canonical delete handler, return structured errors. |
| **Edge Function** | Authenticate and authorize the request, rate-limit, transform request to canonical format, invoke the database-owned delete pipeline, log request metadata. |
| **RPC / Database** | Own the delete transaction, enforce invariants, perform the actual deletion, write audit records, return step-level status, and roll back on failure. |
| **Storage** | Provide idempotent object removal and a list of removed objects for recovery. Do not delete storage before the database transaction commits. |
| **Audit** | Record pre- and post-state snapshots immutably, independently of the entity lifecycle. |
| **Authentication** | Verify JWT and resolve user identity. |
| **Authorization** | Resolve roles and permissions before the delete transaction begins. |

**Separation rules:**

- Business workflow logic must not be split between Edge Functions and triggers.
- The database must not perform authorization; it may enforce invariants.
- The frontend must not decide whether a hard delete is allowed; it may only request it.

### 10.7 Regression Strategy

Design a regression strategy that covers every stage of deletion.

**Required test types:**

- **Integration Tests** — End-to-end delete flows through frontend, service, Edge Function, and database.
- **Database Tests** — Transaction rollback, FK violations, orphan cleanup, and invariant enforcement.
- **Trigger Tests** — Verify remaining triggers and verify removed triggers no longer fire.
- **Transaction Tests** — Partial failure simulation and rollback correctness.
- **Edge Function Tests** — Authentication, authorization, rate limiting, and structured error response.
- **Real Database Tests** — Tests run against a real Supabase/Postgres instance with isolated test tenants.
- **Failure Recovery Tests** — Simulate side-effect failures and verify compensating actions or retries.

**Governance:**

- No delete feature is considered complete without regression coverage.
- Tests must use isolated test tenants and reset state between runs.

### 10.8 Observability Program

Define production observability for delete operations.

**Elements:**

- **Logging** — Structured logs for every delete request at frontend, service, Edge Function, and database layers.
- **Correlation IDs** — A single `delete_request_id` propagated across all layers and persisted in audit records.
- **Structured Errors** — Error responses include a step identifier, error code, affected resource, and recovery guidance.
- **Delete Pipeline Tracking** — A persistent delete pipeline status record with states such as `requested`, `validated`, `deleting`, `side-effects-pending`, `completed`, `failed`.
- **Failure Step Identification** — Every failure is associated with the exact pipeline step and layer.
- **Recovery Guidance** — Error responses and logs contain an explicit next step for operators and support staff.

### 10.9 Architecture Governance

Define long-term governance rules for all delete and audit work.

**Rules:**

1. No delete workflow may exist outside the canonical delete framework.
2. No business workflow may be hidden inside database triggers.
3. No partial deletion may be committed to production without compensating or retry logic.
4. No new delete feature may ship without regression coverage.
5. No production deployment may occur without validated deletion behavior.
6. No audit table may hold a foreign key that would prevent it from surviving deletion of the audited entity.
7. No `ON DELETE` behavior may be changed without a documented risk assessment.
8. Every delete path must have a single, documented transaction owner.
9. Every delete request must carry a correlation ID.
10. Every architectural decision must be recorded in this program or a child ADR.

---

## 11. Milestones

| Phase | Milestone | Exit Criteria |
|-------|-----------|---------------|
| **M1 — Discovery** | Complete trigger inventory and FK inventory. | Inventory documents approved by architecture owner. |
| **M2 — Design** | Approve canonical delete framework, audit redesign, and transaction model. | Design documents and ADRs accepted. |
| **M3 — Governance** | Publish governance rules and implementation/verification order. | Governance ratified; no implementation starts before ratification. |
| **M4 — Pilot** | Apply framework to one pilot domain (recommended: **Tenant**). | Pilot passes integration, transaction, and failure-recovery tests. |
| **M5 — Rollout** | Apply framework to all in-scope domains. | Each domain validated before next domain begins. |
| **M6 — Observability** | Deploy delete pipeline tracking and structured errors. | Dashboards and alerts operational in production. |
| **M7 — Closeout** | Architecture remediation program closed with exit criteria met. | Architecture exit criteria signed off. |

---

## 12. Deliverables

| Deliverable | Owner | Purpose |
|-------------|-------|---------|
| Trigger inventory and classification | Database Architecture | Input to trigger rationalization. |
| Foreign key risk register | Data Architecture | Input to FK policy updates. |
| Canonical delete framework specification | Platform Architecture | Defines reusable delete pipeline. |
| Audit architecture specification | Security & Compliance | Defines independent audit model. |
| Transaction ownership model | Platform Architecture | Defines atomicity and recovery. |
| Deletion workflow governance guide | Engineering Leadership | Defines layer responsibilities. |
| Regression strategy and test plan | QA & Platform | Defines mandatory test coverage. |
| Observability specification | SRE / Platform | Defines logging, correlation, and recovery. |
| Architecture decision records | Architecture Board | Records key choices. |
| Pilot and rollout plan | Engineering Management | Sequenced implementation plan. |

---

## 13. Success Criteria

1. `delete-tenant` and all in-scope delete operations succeed end-to-end without HTTP 500 due to audit FK violations.
2. Every in-scope domain uses the canonical delete framework.
3. No business workflow logic remains in `AFTER DELETE` triggers.
4. Audit records survive deletion of the entities they reference.
5. A delete that cannot complete rolls back with no partial state.
6. Every delete request is traceable by correlation ID through all layers.
7. 100% of in-scope delete paths have regression coverage.
8. Every `ON DELETE` behavior is documented and risk-assessed.
9. Production deletion behavior is validated before every deployment.

---

## 14. Architecture Exit Criteria

The remediation program is complete when:

- The canonical delete framework is in production for all in-scope domains.
- Audit tables are independent of operational entity lifecycles.
- Triggers are classified, documented, and limited to guardrails and low-level invariants.
- All FK policies are reviewed and aligned with the risk register.
- Transaction ownership is clearly assigned per domain and testable.
- Observability dashboards and alerts cover delete pipeline tracking.
- Governance rules are enforced in code review and CI/CD gates.
- Architecture board has signed off the closeout report.

---

## 15. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **Scope creep** — Implementation teams add unrelated changes. | Medium | High | Enforce strict change boundaries and ADRs. |
| **Legacy trigger dependencies** — Removing a trigger breaks unknown workflows. | High | High | Inventory and test every trigger before removal. |
| **FK policy changes cause data loss** — `CASCADE` or `SET NULL` misconfiguration. | Medium | Critical | Apply changes in staging with full data diff review. |
| **Audit migration complexity** — Large `audit_log` table requires careful migration. | Medium | High | Plan a separate, staged migration workstream. |
| **Cross-service transaction drift** — Storage or auth cleanup fails silently. | Medium | High | Use outbox or compensating actions with idempotency. |
| **Adoption resistance** — Teams build custom delete paths. | Medium | Medium | Governance gates in code review and CI. |
| **Performance degradation** — Audit snapshots and transaction locking increase load. | Low | Medium | Load-test pilot domain before rollout. |

---

## 16. Non-Goals

This program explicitly does **not** include the following:

- Writing or modifying any source code, Edge Functions, SQL, triggers, RLS policies, RPC definitions, or migrations.
- Implementing the `delete-tenant` hotfix.
- Rebuilding the Admin Dashboard UI.
- Changing authentication providers.
- Defining business rules such as which roles may delete which entities.
- Legal or tax record retention policy decisions (inputs to audit retention, not outputs of this program).

---

## 17. Future Expansion

After the core remediation is complete, the following extensions may be considered under separate programs:

- **Bulk delete** framework for large datasets with progress tracking and resumption.
- **Soft-delete / archive** capability with full-text search over deleted-but-retained data.
- **Audit log export** and long-term cold storage.
- **Data residency** considerations for audit retention across regions.
- **Customer data deletion** workflows driven by privacy requests.
- **Automated anomaly detection** on delete volume and patterns.

---

## 18. Governance Rules

1. **Canonical framework rule:** Every delete implementation must be approved as a use of the canonical delete framework. Custom delete implementations require architecture board sign-off.
2. **Trigger rule:** No new trigger may contain business workflow logic. New triggers require a documented invariant and approval.
3. **Audit rule:** No new audit table may reference an operational table in a way that blocks deletion of the operational entity.
4. **Transaction rule:** Every delete path must identify a single transaction owner in its architecture document.
5. **Testing rule:** No delete feature may be merged without integration, database, transaction, edge-function, and failure-recovery tests.
6. **Deployment rule:** No production deployment may proceed without validated deletion behavior in the target environment.
7. **Observability rule:** Every delete request must generate a correlation ID and log structured errors.
8. **ADR rule:** Every architectural decision produced by this program is recorded as an architecture decision record (ADR).
9. **Review rule:** All FK, trigger, and audit changes are reviewed by the architecture board before implementation.
10. **Adoption rule:** Future modules are onboarded to the canonical framework at design time, not after implementation.

---

## 19. Recommended Implementation Order

1. **Trigger inventory and classification** — Understand current state before changing it.
2. **Foreign key inventory and risk register** — Identify constraints that drive or block deletion.
3. **Audit architecture design** — Establish the independent audit model first, because it constrains delete design.
4. **Transaction model** — Define atomic boundaries and side-effect handling.
5. **Canonical delete framework** — Design the reusable pipeline.
6. **Pilot domain: Tenant** — Validate the framework where the original failure occurred.
7. **Remaining in-scope domains** — Roll out in priority order: User, Product, Customer, Warehouse, Employee, Membership, Subscription.
8. **Observability** — Implement logging, correlation IDs, and pipeline tracking.
9. **Governance gates** — Add CI checks, code review checklists, and architecture board review.
10. **Program closeout** — Sign off exit criteria and hand over to maintenance.

---

## 20. Recommended Verification Order

1. **Unit/database tests** for the canonical delete pipeline on the pilot domain.
2. **Trigger tests** confirming removed or retained trigger behavior.
3. **Transaction tests** simulating partial failure and rollback.
4. **Edge function tests** for authentication, authorization, and structured error responses.
5. **Integration tests** of the full frontend-to-database delete flow.
6. **Real database tests** in a staging environment with isolated tenants.
7. **Failure recovery tests** for storage and auth side effects.
8. **Observability validation** confirming correlation IDs and step traces appear in logs.
9. **Production validation** in a controlled release before general availability.
10. **Governance audit** verifying no custom delete implementations were introduced.

---

## 21. Long-Term Maintenance Strategy

- **Quarterly trigger review:** Audit all triggers for drift back into business workflow logic.
- **Quarterly FK review:** Reassess `ON DELETE` policies as the schema evolves.
- **Annual delete framework review:** Evaluate new domains and update the canonical framework.
- **Continuous regression:** Keep delete integration and transaction tests in CI.
- **Incident linkage:** Every deletion-related incident is mapped back to this program and the framework is updated if a gap is found.
- **Documentation ownership:** The architecture board owns this program document. Updates are approved through ADRs and versioned releases.

---

## 22. Enterprise Architecture Vision

This program transforms the VietSalePro platform from a collection of feature-oriented deletion operations into a unified, platform-oriented deletion capability.

Under the legacy model, each module invented its own delete path: the frontend decided wording, the Edge Function issued direct SQL, the trigger wrote audit rows, and the database enforced constraints that no one had globally reviewed. Deletion was a side effect of business features rather than a governed platform service.

The target model treats deletion as a reusable, first-class platform primitive. The canonical delete framework, audit independence model, transaction ownership rules, and observability contracts become shared infrastructure that all domains consume.

This transformation enables:

- **Long-term scalability** — New domains are onboarded to the canonical framework at design time, eliminating repeated rediscovery of trigger, foreign-key, and transaction problems.
- **Long-term maintainability** — A single deletion pipeline, a single state machine, and a single set of principles govern every delete operation, reducing the surface area for regression.
- **Architectural evolution** — The framework exposes stable seams (correlation IDs, state events, side-effect handlers, audit hooks) that allow future capabilities to be attached without redesigning deletion.
- **Operational excellence** — Every delete is explicit, deterministic, observable, and recoverable, so operators and support staff can trace, attribute, and remediate any failure.
- **Future-proof design** — The conceptual model is intentionally independent of storage technology, runtime, or service topology, supporting future migration to workflow engines, event buses, queues, outbox patterns, saga patterns, plugin architectures, distributed services, multi-region deployments, and long-term audit archives.

The outcome is not merely a fixed `delete-tenant` path; it is a deletion platform that outlives any individual feature team or release.

---

## 23. Architecture Principles

The following principles are constitutional. Every future deletion implementation, audit design, transaction model, and observability contract must conform to them. Exceptions require an Architecture Decision Record and explicit Architecture Board approval.

| Principle | Meaning | Implication |
|-----------|---------|-------------|
| **Deletion is explicit** | No data is removed as a side effect of an unrelated operation. Delete intent must be declared, validated, and logged. | Every delete is invoked through the canonical delete API, not through generic SQL or triggers. |
| **Deletion is deterministic** | The same delete request, given the same state, must produce the same set of actions and the same final state. | Delete logic is centralized, idempotent, and free of hidden conditional branches. |
| **Deletion is idempotent** | Replaying a delete request for an already-deleted or non-existent target must not create errors, duplicate side effects, or data inconsistencies. | The framework must recognize finality and return a stable result. |
| **Deletion is observable** | Every delete request carries a correlation identifier and produces a step trace that is visible across all layers. | Support, operations, and compliance can reconstruct the full lifecycle. |
| **Deletion is recoverable** | A failed or partially failed delete must be able to roll back, retry, or be manually remediated without data loss. | Pre-delete snapshots, compensating actions, and recovery guidance are first-class. |
| **Audit is immutable** | Audit records are append-only. No update or delete of an audit row is permitted. | Audit history outlives the entities it describes and retains forensic value. |
| **Database owns integrity** | Referential integrity, constraint validation, and atomic transaction boundaries are enforced by the database layer. | The database is the single source of truth for whether a delete is valid. |
| **Application owns workflow** | Business workflow decisions, ordering, side-effect orchestration, and user-facing semantics are owned by explicit application code. | Triggers, stored procedures, and foreign keys enforce invariants, not workflows. |
| **Platform before feature** | Feature teams reuse the canonical deletion platform rather than inventing local delete paths. | Custom delete implementations are prohibited without Architecture Board exception. |
| **Reuse before reinvention** | Existing platform capabilities, handlers, and patterns are consumed before new ones are created. | Duplication of delete logic is treated as an architecture defect. |
| **Side effects are compensatable** | External cleanup (storage, auth, notifications, billing) is idempotent or reversibly compensatable. | The database transaction is never blocked on an external system. |
| **Failure is a first-class state** | Failed, rolled-back, retryable, and closed states are modeled explicitly in the delete lifecycle. | Operators can see and act on failures without reverse-engineering logs. |

---

## 24. Canonical Deletion Domain Model

The deletion domain is modeled as a set of conceptual objects. Each object has a single responsibility and a defined boundary.

| Concept | Responsibility |
|---------|--------------|
| **Delete Request** | Captures the intent to delete: actor, target type, target identifier, deletion classification, correlation ID, timestamp, and authorization context. |
| **Delete Session** | Binds a set of related delete requests and side effects for a single logical operation. Provides isolation and grouping for bulk, tenant, or cascade deletes. |
| **Delete Transaction** | Represents the atomic database boundary that commits or rolls back row-level changes. Owned by the database layer. |
| **Delete Pipeline** | The ordered sequence of validation, preparation, execution, side-effect orchestration, and completion stages for a delete. |
| **Delete State** | The current lifecycle state of a delete operation (for example, requested, validating, executing, completed, failed). |
| **Delete Result** | The outcome returned to the caller: final state, affected resources, error code, recovery guidance, and next-step instructions. |
| **Delete Recovery** | The set of compensating actions, rollback scripts, snapshots, and runbooks required to restore consistency after a failure. |
| **Delete Audit** | The immutable record of what was requested, what was done, what the pre- and post-states were, and who authorized it. |
| **Delete Context** | The ambient information needed to execute a delete: tenant, region, feature flags, legal hold status, retention policy, and correlation identifiers. |
| **Delete Metadata** | Additional structured information attached to a delete: classification, reason, approval references, and policy identifiers. |

The model intentionally separates request (what is asked), pipeline (how it is done), transaction (where it commits), state (where it is in the lifecycle), and audit (what is proven). No object is allowed to assume the responsibility of another.

---

## 25. Canonical Delete State Machine

Every delete operation moves through a governed lifecycle. The state machine is the contract between the caller, the pipeline, the transaction owner, and the observability layer.

### 25.1 Happy path

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

### 25.2 Failure and recovery path

```
FAILED
  ↓ failure classified
ROLLBACK
  ↓ transaction rolled back or compensations triggered
RECOVERABLE
  ↓ operator intervention or data correction applied
RETRYABLE
  ↓ conditions for retry satisfied
CLOSED
```

### 25.3 Transition rules and ownership

| From | To | Guard | Owner | Action |
|------|----|-------|-------|--------|
| ACTIVE | DELETE_REQUESTED | Target exists and caller is authenticated | Service / Edge Function | Create delete request, assign correlation ID. |
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

States are terminal when they are `COMPLETED`, `CLOSED`, or a final error classification. Every transition is logged with the previous state, new state, actor, timestamp, and reason.

---

## 26. Delete Classification

Deletion is not a single operation. The framework supports multiple classifications, each with distinct lifecycle, recovery, and audit requirements.

| Classification | Purpose | Lifecycle | Recovery | Audit Requirement | Typical Use Cases |
|----------------|---------|-----------|----------|-------------------|-------------------|
| **Soft Delete** | Mark an entity as deleted without removing rows. | Active → Soft-Deleted → Restored or Purged. | Reversible by restoration. | Record who deleted and when; retain full pre-state. | User-initiated deletion that may be undone. |
| **Hard Delete** | Permanently remove an entity and its owned data. | Active → Requested → Validated → Executed → Completed. | Not recoverable once committed; pre-delete snapshot may be archived. | Record full pre-state snapshot and authorization. | Legal deletion, tenant removal, data sanitation. |
| **Archive** | Move an entity and its history to an archive domain while removing it from active queries. | Active → Archived → Restored or Expunged. | Restorable from archive until retention expires. | Retain provenance and archive location. | Historical data migration, cold storage. |
| **Logical Delete** | Change a status flag so the entity is no longer visible to the application. | Active → Logically Deleted → Restored. | Reversible by status change. | Record status transition and actor. | Application-level deactivation, account closure. |
| **Physical Delete** | Remove the underlying storage representation (row, file, object). | Active → Executed → Purged. | Not recoverable without backup. | Record hash or reference of removed object. | Storage cleanup, blob removal. |
| **Purge** | Remove previously soft-deleted or archived data after retention. | Soft-Deleted / Archived → Purged. | Not recoverable. | Record retention policy basis and purge authorization. | Retention enforcement, right-to-be-forgotten. |
| **Retention Delete** | Delete data automatically when a retention period expires. | Active / Archived → Retention-Reviewed → Deleted. | Not recoverable; legal hold may block. | Record retention schedule and hold status. | Compliance-driven automatic cleanup. |
| **Compliance Delete** | Delete data to satisfy a legal, regulatory, or privacy request. | Requested → Legal Review → Authorized → Executed. | Not recoverable; may require certificate. | Record request identifier, approver, and certificate of deletion. | GDPR/CCPA request, litigation hold release. |
| **Emergency Delete** | Rapidly remove data to contain an incident. | Detected → Emergency Authorized → Executed. | May require post-incident review and possible restore from backup. | Record incident ID, emergency approver, and justification. | Breach containment, malware removal. |
| **Bulk Delete** | Remove a large set of entities under a single transaction or session. | Requested → Validated → Batched → Executed → Verified. | Roll back entire batch or per-batch compensation. | Record batch identifier, scope, and completion status. | Mass data cleanup, migration cleanup. |

The classification is declared in the `Delete Request` and enforced by the `Delete Pipeline`. The same target may move through multiple classifications over time (for example, Soft Delete → Purge).

---

## 27. Dependency Matrix

The following matrix visualizes the impact of deleting a domain. A dependency means that the row's deletion affects, is blocked by, or must coordinate with the listed domain. The matrix is used during impact analysis, rollback planning, and foreign-key review.

| Domain | Depends On | Deletion Impact |
|--------|------------|-----------------|
| **Tenant** | Membership, Storage, Subscription, Audit, Auth, Notification, Billing | Removing a tenant must cascade through membership entitlements, storage objects, active subscriptions, immutable audit history, auth identities, pending notifications, and billing records. |
| **User** | Tenant, Membership, Subscription, Audit, Auth, Notification | Deleting a user requires resolving tenant membership, active subscriptions, audit history, auth identity, and notification preferences. |
| **Product** | Tenant, Warehouse, Subscription, Audit, Billing | Product deletion affects tenant catalog, warehouse stock references, subscription line items, audit history, and billing records. |
| **Customer** | Tenant, Subscription, Audit, Billing, Notification | Customer deletion requires handling active subscriptions, immutable audit, billing accounts, and notification subscriptions. |
| **Warehouse** | Tenant, Product, Employee, Audit | Warehouse removal must reconcile product stock, employee assignments, and audit history. |
| **Employee** | Tenant, Warehouse, Subscription, Audit, Auth | Employee deletion affects warehouse assignments, subscription ownership, audit history, and auth identity. |
| **Membership** | Tenant, User, Subscription, Audit | Membership deletion is constrained by tenant, user, and subscription relationships. |
| **Subscription** | Tenant, User, Customer, Product, Billing, Audit | Subscription deletion must settle billing, update product entitlements, and record audit history. |

The matrix is not exhaustive. As new domains are introduced, they must register their deletion dependencies with the canonical framework before implementation. No domain may delete without a reviewed dependency row.

---

## 28. Risk Classification

The program expands the risk model into categories that cover the full lifecycle of a deletion platform. Each category has an owner accountable for maintaining the corresponding risk register.

| Category | Nature | Examples | Mitigation | Owner |
|----------|--------|----------|------------|-------|
| **Architecture Risk** | The canonical framework fails to cover a domain, or a local implementation bypasses it. | Custom delete path in a new module; domain not modeled in dependency matrix. | Mandatory architecture review and framework onboarding for every new domain. | Chief Architect / Architecture Board |
| **Operational Risk** | A delete operation cannot be completed or recovered by operations staff. | HTTP 500 with no step trace; orphaned auth user after tenant delete. | Observable pipeline, structured errors, runbooks, and recovery tooling. | SRE / Platform Operations |
| **Data Risk** | Deletion produces orphaned, inconsistent, or unintended data loss. | Cascade deletes too much; SET NULL loses context. | FK review, dependency matrix, pre-delete snapshots, and dry-run validation. | Data Architecture / DBA |
| **Compliance Risk** | Deletion or audit retention violates legal or regulatory requirements. | Audit deleted with tenant; retention-delete blocked by legal hold. | Immutable audit, legal-hold flags, retention policies, and compliance review. | Security & Compliance |
| **Performance Risk** | Deletion impacts system throughput, locking, or recovery time. | Long-running tenant delete locks tables; bulk delete times out. | Batch sizing, locking strategy, load testing, and timeout governance. | Platform Engineering |
| **Migration Risk** | Moving from legacy deletion to the canonical framework loses or corrupts data. | Audit migration misses rows; trigger removal breaks legacy workflow. | Staged migrations, data diff review, and rollback scripts. | Engineering Management |
| **Observability Risk** | Failures or partial deletes are not detected or attributable. | Missing correlation ID; side effect silently fails. | Structured logging, correlation propagation, dashboards, and alerts. | SRE / Observability |
| **Recovery Risk** | A failed delete cannot be rolled back or remediated. | No pre-delete snapshot; compensation action not idempotent. | Recovery state machine, snapshots, compensations, and incident runbooks. | Platform Engineering / SRE |

Risks are reviewed quarterly and after every deletion-related incident. New risk categories may be added only through an ADR.

---

## 29. Architecture Decision Record Strategy

All decisions that shape the deletion platform are recorded as Architecture Decision Records (ADRs). The ADR process is the audit trail for the architecture itself.

### 29.1 ADR numbering

ADRs use the format `ADR-DELETE-<sequence>`. The sequence is zero-padded and monotonically increasing (for example, `ADR-DELETE-001`). The title describes the decision in business terms.

### 29.2 ADR lifecycle

| State | Meaning |
|-------|---------|
| **Proposed** | The decision is drafted and under architecture review. |
| **Review** | The decision is being evaluated by the Architecture Board and affected workstream owners. |
| **Accepted** | The decision is approved and mandatory for implementation. |
| **Deprecated** | The decision is no longer recommended but remains documented for historical context. |
| **Superseded** | A newer ADR replaces this decision. The old ADR links to the new one. |

### 29.3 ADR approval

Every ADR is approved by the Architecture Board. ADRs that affect the canonical delete framework, audit independence, foreign-key policy, transaction ownership, or data retention require board-level sign-off. Lower-level design decisions may be approved by the Chief Architect with board notification.

### 29.4 ADR ownership

The workstream that raises a decision owns the draft. The Architecture Board owns the final record and the decision register. Each ADR has a named owner responsible for keeping it current.

### 29.5 ADR versioning

ADRs are versioned with the document date and a revision marker. Accepted ADRs are not edited in place; they are superseded by a new ADR. This preserves the decision history.

### 29.6 ADR review process

ADRs are reviewed in the architecture review stage of the Program Governance Chain. Reviews examine the problem, options, decision, consequences, and compliance with the Architecture Principles. The decision is accepted, returned for revision, or rejected.

### 29.7 When ADRs become mandatory

An ADR is mandatory before any of the following:

- Changing the canonical delete framework or state machine.
- Adding, removing, or reclassifying a database trigger.
- Changing any `ON DELETE` policy.
- Introducing a new deletion classification.
- Adding a new deletable domain to the dependency matrix.
- Modifying audit retention, immutability, or independence rules.
- Altering transaction ownership for any domain.

---

## 30. Program Governance Chain

The program follows a governance lifecycle that separates authorization, design, implementation, and closeout.

| Stage | Objective | Key Outputs | Approval Gate |
|-------|-----------|-------------|---------------|
| **Program Authorization** | Confirm business case, budget, scope, and executive sponsorship. | Program charter, sponsor sign-off, risk appetite statement. | Executive Sponsor |
| **Architecture Review** | Validate that the target architecture is sound, complete, and aligned with enterprise standards. | Architecture vision, principles, domain model, state machine, risk register. | Architecture Board |
| **Detailed Design** | Produce detailed design documents for each workstream without implementation. | Workstream designs, ADRs, dependency matrix, test strategy. | Chief Architect |
| **Engineering Kickoff** | Align engineering teams with the design, entry criteria, and exit criteria. | Sprint plans, team assignments, environment plan. | Engineering Manager |
| **Implementation** | Build the canonical framework and apply it to each in-scope domain. | Code, migrations, tests, observability artifacts. | Engineering Lead |
| **Verification** | Prove that the framework satisfies the success and exit criteria. | Test reports, audit reports, compliance sign-off. | QA / Platform |
| **Acceptance Review** | Confirm that the pilot and each wave are fit for production. | Acceptance certificates, rollback readiness, runbooks. | Product Owner / Architecture Board |
| **Program Status Review** | Track progress, risks, and deviations on a recurring basis. | Status report, risk register updates, metric dashboard. | Program Manager |
| **Closeout Review** | Verify that all exit criteria, governance gates, and handover materials are complete. | Closeout report, knowledge base, maintenance plan. | Architecture Board / Sponsor |
| **Program Closure** | Formally close the program and transfer ownership to maintenance. | Closure certificate, final ADR register, communication plan. | Executive Sponsor |

Every stage has explicit entry and exit criteria. No stage may be skipped, and every gate requires documented approval.

---

## 31. Rollout Strategy

The rollout is staged to limit blast radius, prove the framework, and allow safe rollback.

| Wave | Entry Criteria | Exit Criteria | Rollback Strategy |
|------|----------------|---------------|-------------------|
| **Pilot** | Canonical framework design accepted; tenant domain chosen; test environment ready. | `delete-tenant` succeeds end-to-end; rollback test passes; audit independence verified. | Revert to legacy delete path behind feature flag; restore tenant snapshot. |
| **Wave 1** | Pilot exit criteria met; User and Membership domains reviewed. | User and Membership deletes pass all test types; no HTTP 500 in staging. | Disable new pipeline for Wave 1 domains; re-enable legacy path; run compensation checks. |
| **Wave 2** | Wave 1 stable in production for 2 weeks; Product, Customer, Warehouse domains reviewed. | All Wave 2 domains pass integration, transaction, and recovery tests. | Per-domain feature flags revert to legacy; run dependency verification. |
| **Wave 3** | Wave 2 stable for 2 weeks; Employee and Subscription domains reviewed. | All remaining in-scope domains validated; production incident rate stable. | Revert affected domain; snapshot restore if needed. |
| **Production** | All waves validated; observability dashboards operational; runbooks published. | 100% of in-scope production traffic uses canonical framework for 30 days. | Global feature flag to fallback; emergency rollback procedure. |
| **Hypercare** | Production rollout complete; support and operations staffed. | No critical delete incidents for 30 days; metrics meet targets. | Incident-driven rollback per domain; escalate to architecture board for framework changes. |
| **Closeout** | Hypercare complete; program exit criteria signed off. | Program closure certificate issued; maintenance plan active. | Not applicable; lessons learned feed next program. |

Waves may not overlap. Each wave must pass its exit criteria before the next wave begins. Rollback decisions are made by the Program Manager with Architecture Board approval.

---

## 32. Success Metrics

The program is measured by KPIs that cover reliability, recoverability, compliance, and governance.

| KPI | Description | Measurement | Target | Frequency | Owner |
|-----|-------------|-------------|--------|-----------|-------|
| **Delete Success Rate** | Percentage of delete requests that reach `COMPLETED` without retry. | `completed / (completed + failed)` from delete pipeline tracking. | > 99.9% | Daily | Platform Engineering |
| **Rollback Success Rate** | Percentage of failed deletes that are successfully rolled back or recovered. | `recovered / (failed - closed-unrecoverable)` from recovery state. | > 99.5% | Per incident | SRE |
| **Delete HTTP 500** | Number of HTTP 500 responses returned by delete endpoints. | Edge Function error logs filtered by delete endpoints and status 500. | 0 | Daily | SRE |
| **Partial Delete Count** | Number of deletes that leave orphaned or inconsistent state. | Automated orphan scans and correlation-gap detection. | 0 | Daily | Data Architecture |
| **Audit Integrity** | Percentage of delete operations with a complete, immutable audit record. | Audit row presence, immutability check, and field completeness. | 100% | Daily | Security & Compliance |
| **Regression Coverage** | Percentage of in-scope delete paths covered by the regression strategy. | Test suite coverage reports for each delete classification and domain. | 100% | Per release | QA |
| **Mean Recovery Time** | Average time from delete failure detection to full recovery or safe closure. | Incident timestamps from `FAILED` to `RECOVERABLE` or `CLOSED`. | < 30 minutes | Weekly | SRE |
| **Production Incident Rate** | Number of production incidents per month related to deletion. | Incident tracker tagged with `deletion` root cause. | 0 | Monthly | Platform Engineering |
| **Architecture Compliance** | Percentage of new/delete work that passes architecture review and uses the canonical framework. | Code review and CI gate metrics. | 100% | Monthly | Architecture Board |
| **Governance Compliance** | Percentage of required ADRs and checkpoints completed on time. | ADR register and governance chain milestone tracking. | 100% | Monthly | Program Manager |

Metrics are reviewed in the Program Status Review. Any metric below target triggers a corrective action.

---

## 33. Future Platform Evolution

The canonical deletion framework is designed to support future platform capabilities without architectural redesign. The following capabilities are not implemented by this program, but the framework is compatible with them.

- **Workflow Engine** — The delete state machine maps directly onto workflow orchestration. State transitions can be driven by an external workflow engine without changing the pipeline contract.
- **Event Bus** — Delete events (requested, validated, executed, failed, recovered) can be published to a central event bus. Consumers subscribe without coupling to the delete pipeline.
- **Queue** — Long-running side effects and bulk deletes can be moved to durable queues. The `Delete Session` provides the session boundary needed for queue-based processing.
- **Outbox Pattern** — External side effects can be written to an outbox table inside the database transaction and relayed by a publisher, preserving exactly-once semantics.
- **Saga Pattern** — Cross-service deletions can be decomposed into saga steps with compensating actions. The `Delete Recovery` concept provides the compensation model.
- **Plugin Architecture** — Domain-specific side-effect handlers can be registered as plugins that conform to the canonical handler interface, enabling third-party and custom extensions.
- **Distributed Services** — The framework is service-topology agnostic. Correlation IDs and state events allow deletes to span multiple services without losing observability.
- **Multi-region** — Audit records and delete state can be replicated across regions. The immutability and append-only design simplify conflict resolution.
- **Long-term Audit Archive** — Audit rows can be migrated to cold storage without violating the independence or immutability contract. The `Delete Audit` concept carries all metadata needed for archival indexing.

Future teams must extend the framework through the ADR process, ensuring that new capabilities remain compatible with the architecture principles and the canonical domain model.

---

## 34. References

- `DELETE_TENANT_FORENSIC_INVESTIGATION_REPORT.md` — Forensic analysis of the original `delete-tenant` HTTP 500 failure.
- VietSalePro Admin Dashboard deletion workflows and related schema.
- PostgreSQL trigger, foreign key, and transaction documentation.
- Architecture decision records (ADRs) produced during implementation of this program.

---

## 35. Enterprise Program Portfolio

### 35.1 Purpose

The master program is intentionally decomposed into focused sub-programs so that architecture, engineering, and operational governance can be assigned, tracked, and delivered without losing the unifying context of the Enterprise Architecture vision. This section defines the portfolio hierarchy and explains how every sub-program remains anchored to this document.

This document remains the **single source of truth**. No sub-program may redefine its scope, principles, or exit criteria independently; sub-program charters are delta specifications that extend, never replace, the master program.

### 35.2 Portfolio decomposition

```
Master Program: Deletion & Audit Architecture Remediation Program
    |
    +-- Delete Framework Program
    |
    +-- Audit Architecture Program
    |
    +-- Transaction Architecture Program
    |
    +-- Trigger Governance Program
    |
    +-- Foreign Key Governance Program
    |
    +-- Observability Program
    |
    +-- Regression Program
    |
    +-- Rollout Program
    |
    +-- Long-term Maintenance Program
```

### 35.3 Sub-program definitions

| Sub-Program | Purpose | Responsibilities | Deliverables | Dependencies | Relationship to the Master Program |
|---|---|---|---|---|---|
| **Delete Framework Program** | Define the canonical deletion pipeline that all domains will reuse. | State machine, deletion classification, handler contract, domain adapter model, recovery flow. | Canonical delete framework specification, handler SDK, state-machine implementation, domain integration guide. | Audit Architecture, Transaction Architecture, Trigger Governance, Foreign Key Governance. | Realizes the delete capability described in the Architecture Vision and Domain Model. |
| **Audit Architecture Program** | Make audit history independent, immutable, and recoverable. | Audit record schema, append-only policy, retention rules, cryptographic immutability where required, audit-event contract. | Audit schema, retention policy, audit-event API, audit archive design. | Delete Framework Program, Transaction Architecture Program. | Guarantees the principle that audit history survives the entity. |
| **Transaction Architecture Program** | Establish a single owner for the atomic deletion boundary and cross-service compensation. | Stored-procedure / RPC transaction boundaries, saga and outbox patterns, compensation actions, idempotency keys. | Transaction ownership model, saga step library, outbox schema, compensation runbook. | Delete Framework Program, Trigger Governance Program. | Implements the One Transaction Owner principle for every hard delete. |
| **Trigger Governance Program** | Remove business workflow logic from triggers and confine triggers to low-level invariants. | Trigger inventory, trigger classification, migration plan, trigger test harness, invariant-only policy. | Trigger register, refactored trigger set, trigger acceptance criteria, invariant checklist. | Delete Framework Program, Transaction Architecture Program. | Enforces the Triggers guard; services decide principle. |
| **Foreign Key Governance Program** | Make every `ON DELETE` contract explicit, risk-assessed, and consistent. | FK dependency mapping, policy taxonomy, undeletable-graph analysis, migration scripts for policy changes. | Dependency matrix, FK policy register, automated FK validation gate. | Delete Framework Program, Transaction Architecture Program. | Implements the Explicit by default principle across the schema. |
| **Observability Program** | Ensure every delete request is traceable, measurable, and recoverable in production. | Correlation ID propagation, structured delete logs, dashboards, alerts, step-level tracing. | Delete observability dashboard, alert rules, correlation-id library, SLO definitions. | Delete Framework Program, Rollout Program. | Realizes the Delete is observable principle. |
| **Regression Program** | Keep the delete framework correct as the platform evolves. | Regression test matrix, synthetic data fixtures, cross-domain delete tests, CI gates. | Regression suite, test data factory, coverage report, release gate. | Delete Framework Program, Audit Architecture Program, Transaction Architecture Program. | Verifies that the canonical framework remains safe across every release. |
| **Rollout Program** | Move the framework from architecture to production without destabilizing the platform. | Wave planning, feature flags, rollback playbooks, pilot execution, production verification. | Rollout plan, wave sign-off certificates, feature-flag matrix, rollback runbooks. | All architecture sub-programs. | Executes the Rollout Strategy while preserving governance gates. |
| **Long-term Maintenance Program** | Sustain the architecture after the active program closes. | Ownership handover, evergreen reviews, ADR maintenance, knowledge refresh, ongoing metric review. | Maintenance charter, review calendar, evergreen ADR backlog, runbook library. | Rollout Program, Regression Program. | Transitions the master program from project delivery to enterprise capability management. |

### 35.4 Single source of truth

All sub-program charters, workstream designs, and implementation plans derive their authority from this document. Any conflict between a sub-program plan and this master program is resolved in favor of this document and escalated to the Architecture Board for an ADR if the conflict is material.

---

## 36. Enterprise Architecture Repository

### 36.1 Purpose

The Enterprise Architecture Repository is the durable, searchable, and versioned store of all architecture knowledge produced by the program and its successors. It preserves design rationale, decision history, and verification evidence so that the platform can be maintained, scaled, and governed over many years.

### 36.2 Repository structure

| Category | Contents | Steward |
|---|---|---|
| **Master Program** | This document, program charter, scope statements, and approved amendments. | Chief Enterprise Architect |
| **ADR** | Architecture Decision Records: proposed, accepted, deprecated, and superseded. | Architecture Board |
| **Domain Models** | Canonical domain models, entity-relationship diagrams, context maps, ubiquitous-language glossary. | Domain Architecture Lead |
| **State Machines** | Delete state machine, recovery state machine, audit lifecycle, and future workflow state models. | Delete Framework Lead |
| **Sequence Diagrams** | End-to-end delete flows, compensation flows, audit write paths, rollback flows. | Solution Architect |
| **Decision Logs** | Meeting minutes, review notes, escalation records, and principle clarification memos. | Program Manager |
| **Risk Registers** | Architecture risks, mitigations, residual risk ratings, and owners. | Enterprise Risk Architect |
| **Dependency Matrix** | Domain-to-domain, table-to-table, and service-to-service delete dependency maps. | Data Architecture Lead |
| **Architecture Standards** | Coding standards, schema policies, trigger guidelines, FK policy taxonomy, observability standards. | Architecture Standards Lead |
| **Verification Reports** | Test results, audit reports, security scans, performance baselines, and compliance attestations. | QA / SRE |
| **Program Reviews** | Architecture review records, quarterly assessments, and annual program review outcomes. | Program Manager |
| **Lessons Learned** | Post-implementation reviews, incident retrospectives, and future-proofing recommendations. | Engineering Manager |

### 36.3 Repository rules

1. **Versioning.** Every document is versioned with a major.minor.revision scheme. Major changes require Architecture Board approval; minor changes require Chief Architect approval; revisions are editorial and may be approved by the document steward.
2. **Ownership.** Each category has a named steward. The steward is accountable for accuracy, currency, and access control, not for producing every artifact.
3. **Review cycle.** Architecture standards, risk registers, and the dependency matrix are reviewed quarterly. The master program and ADR register are reviewed annually. Verification reports are reviewed per release.
4. **Document lifecycle.** Documents progress through `Draft`, `Review`, `Approved`, `Superseded`, and `Archived` states. Approved documents are not edited in place; they are superseded by a new version so that history is preserved.
5. **Access.** The repository is readable by all engineering staff. Write access is limited to stewards, workstream leads, and the Architecture Board.
6. **Retention.** Architecture knowledge is retained for the operational lifetime of the platform plus any legally required period. Cold archival may be applied after seven years.

### 36.4 Knowledge preservation

Repository content is the institutional memory of the platform. It is reviewed during onboarding, referenced during incident response, and updated through the change-management process. No architectural decision is considered authoritative until it has been recorded in the repository.

---

## 37. Enterprise Traceability Framework

### 37.1 Purpose

Traceability ensures that every finding, risk, decision, design, line of code, test, and operational outcome can be followed from origin to closeout and back again. It provides the evidence chain required for audit, governance, and continuous improvement.

### 37.2 End-to-end traceability model

```
Finding
    ↓
Risk
    ↓
Root Cause
    ↓
Architecture Principle
    ↓
Workstream
    ↓
ADR
    ↓
Design
    ↓
Implementation
    ↓
Verification
    ↓
Acceptance
    ↓
Closeout
    ↓
Maintenance
```

### 37.3 Traceability definitions

| Link | Forward trace | Backward trace |
|---|---|---|
| **Finding → Risk** | A production or review finding is classified as a risk and added to the risk register. | Every risk can be traced to the observation or incident that created it. |
| **Risk → Root Cause** | A root-cause analysis identifies the architectural deficiency behind the risk. | The root cause links back to one or more risks. |
| **Root Cause → Architecture Principle** | Each root cause maps to the principle it violates or reinforces. | Principles are validated against known root causes to prove they are actionable. |
| **Architecture Principle → Workstream** | Principles are assigned to workstreams for implementation. | Workstreams justify their scope by the principles they address. |
| **Workstream → ADR** | Workstreams produce or consume ADRs for material decisions. | Every ADR names the originating workstream and the problem it resolves. |
| **ADR → Design** | Accepted ADRs become design documents and patterns. | Designs cite the ADRs they realize. |
| **Design → Implementation** | Designs are implemented in code, schema, and configuration. | Code artifacts reference the design and ADR. |
| **Implementation → Verification** | Implemented work is verified by tests, audits, and reviews. | Tests trace back to implementation requirements and design. |
| **Verification → Acceptance** | Verification evidence is reviewed for acceptance. | Acceptance gates require specific verification artifacts. |
| **Acceptance → Closeout** | Accepted deliverables feed program or wave closeout. | Closeout reports cite acceptance records. |
| **Closeout → Maintenance** | Closeout transfers responsibility to maintenance. | Maintenance actions refer back to the original closeout criteria. |

### 37.4 Bidirectional traceability

Every artifact must be traceable both forward and backward. Forward traceability asks, "What was produced from this decision?" Backward traceability asks, "Why does this artifact exist?" Both directions are required for audit and for safe evolution.

### 37.5 Impact analysis

When a change is proposed, the traceability model is used to identify all downstream artifacts, domains, and tests that may be affected. A change to an `ON DELETE` policy, for example, must be traced through the dependency matrix, design documents, implementation handlers, regression tests, and observability rules before approval.

### 37.6 Change traceability

All changes to architecture are captured through the change-management process. The change request links to the original finding, risk, ADR, or design that motivates it, and the implementation links back to the approved change. This prevents scope creep and preserves accountability.

### 37.7 Audit traceability

Regulatory and internal auditors can follow a delete operation from request, through state transitions, audit-event generation, and verification, to final closeout. The correlation ID is the primary key for this audit trail; the traceability framework is the map.

---

## 38. Architecture Maturity Model

### 38.1 Purpose

The maturity model describes how the Deletion & Audit architecture evolves from ad-hoc practice to an enterprise-grade platform capability. It provides a roadmap, assessment criteria, and a shared vocabulary for improvement.

### 38.2 Maturity levels

| Level | Name | Characteristics | Capabilities | Governance | Risks | Exit Criteria | Success Indicators |
|---|---|---|---|---|---|---|---|
| **1** | **Ad Hoc** | Deletion is implemented per domain with no shared pattern. Failures are fixed reactively. | Local SQL or API deletes; no canonical model. | Informal; no architecture review for deletes. | Repeated incidents, data loss, compliance gaps. | Acknowledge that deletion is a platform concern. | Incident-driven recognition. |
| **2** | **Repeatable** | A documented delete pattern exists for one domain. It may be copied informally. | Single-domain pipeline; some tests. | Workstream-level reviews; no board ownership. | Pattern drift between copies; incomplete coverage. | Pattern documented and demonstrated in one domain. | One domain deletes with rollback and audit. |
| **3** | **Standardized** | A canonical delete framework is defined and applied to all in-scope domains. | Canonical pipeline, state machine, audit independence, trigger rules, FK governance. | Architecture Board owns framework; mandatory ADRs for changes. | Gaps in observability, regression, or maintenance handover. | Framework adopted across all in-scope domains. | > 99.9% delete success, zero partial deletes, full audit coverage. |
| **4** | **Governed** | The framework is sustained by governance: change control, metrics, and continuous review. | Change management, traceability, repository, quarterly assessments, regression gates. | Enterprise governance process; cross-program alignment. | Slow response to new domains; tool fatigue. | All governance gates enforced across programs. | Architecture compliance and governance compliance at 100%. |
| **5** | **Platform** | Deletion is a self-service platform capability with reusable handlers, plugins, and event streams. | Plugin architecture, event bus, workflow engine integration, multi-region replication. | Platform team ownership; service-catalog governance. | Over-engineering; maintenance of plugin surface. | Platform usage by new domains without custom code. | New domains onboard in days; handler reuse > 80%. |
| **6** | **Enterprise** | Deletion, audit, and recovery are fully integrated into enterprise risk, compliance, and AI-readiness capabilities. | Predictive risk analysis, automated policy enforcement, AI-assisted impact analysis, long-term archival. | Enterprise Architecture Board; regulatory alignment. | Complexity of multi-system governance. | Architecture recognized as enterprise capability. | Multi-year metrics demonstrate sustained excellence and future scalability. |

### 38.3 Evolution of the Deletion Framework

The Deletion Framework begins at Level 1 in the legacy system and targets Level 3 at program closeout. Levels 4–6 are achieved through the governance, maintenance, and continuous-improvement mechanisms defined in this document. Progress is measured by the exit criteria and success indicators at each level.

---

## 39. Enterprise Change Management

### 39.1 Purpose

Change is inevitable in any enterprise platform. This section defines how architectural changes to the deletion, audit, transaction, trigger, foreign-key, and observability domains are requested, assessed, approved, implemented, and verified without undermining the master architecture.

### 39.2 Change lifecycle

| Step | Activity | Owner | Output |
|---|---|---|---|
| **1. Architecture Change Request (ACR)** | Document the proposed change, the problem it solves, the affected principles, and the originating finding or risk. | Requester / Workstream Lead | ACR record |
| **2. Impact Assessment** | Trace the change through the dependency matrix, domain model, state machine, ADRs, and regression tests. | Solution Architect | Impact assessment report |
| **3. Architecture Review** | Review the ACR and impact assessment against principles and governance rules. | Architecture Board | Review decision |
| **4. ADR Update** | Create or supersede an ADR if the change is material. | Chief Architect | Approved or updated ADR |
| **5. Repository Update** | Update the architecture repository with the new decision, design, and risk register. | Document Steward | Updated repository artifacts |
| **6. Implementation Planning** | Define tasks, owners, sequencing, and rollback plan. | Engineering Manager | Implementation plan |
| **7. Regression Planning** | Identify affected tests, data fixtures, and environments. | QA Lead | Regression plan |
| **8. Verification** | Execute tests, audits, and observability checks. | QA / SRE | Verification report |
| **9. Acceptance** | Confirm that exit criteria are met. | Product Owner / Architecture Board | Acceptance certificate |
| **10. Deployment Approval** | Authorize production deployment with feature flags and rollback criteria. | Program Manager / SRE | Deployment approval |
| **11. Knowledge Update** | Update runbooks, training material, and lessons learned. | Engineering Manager | Updated knowledge base |

### 39.3 Approval authority

- **Architecture Board** approves changes that affect the canonical delete framework, audit independence, transaction ownership, FK policy, trigger governance, or any architecture principle.
- **Chief Architect** may approve lower-level design clarifications, documentation updates, and non-breaking extensions, with board notification.
- **Engineering Manager** approves implementation sequencing and resourcing within an approved design.
- **SRE / Platform** approves production deployment and rollback readiness.

### 39.4 Breaking changes

A breaking change is any change that alters the delete state machine, changes the audit immutability contract, removes a public handler interface, or changes an `ON DELETE` policy in a way that can orphan or delete data unexpectedly. Breaking changes require:

1. A mandatory ADR.
2. Architecture Board approval.
3. A backward-compatibility or migration plan.
4. A deprecation period, unless safety requires immediate action.
5. A rollback procedure validated before deployment.

### 39.5 Backward compatibility and deprecation

New framework versions must support the previous major handler contract and audit-event schema for a declared deprecation window. Deprecated contracts are marked, logged, and removed only after all known consumers have migrated. Migration guides are mandatory for any contract change.

### 39.6 Version compatibility

The canonical delete framework, audit schema, and handler contract are versioned independently. Patch versions are backward-compatible. Minor versions may add optional features. Major versions may introduce breaking changes and require an ADR and migration plan.

### 39.7 Long-term evolution

Architecture evolves through small, governed changes rather than large rewrites. Every change is an opportunity to strengthen the repository, the traceability model, and the maturity of the platform. The master program is the launch point; the change-management process is the engine of long-term sustainability.

---

## 40. Cross-Program Governance

### 40.1 Purpose

The Deletion & Audit Architecture Remediation Program does not operate in isolation. It interfaces with security, performance, database governance, platform engineering, DevOps, compliance, observability, testing, data governance, and incident management. This section defines how shared concerns are governed across programs.

### 40.2 Cross-program responsibilities

| Program | Shared responsibilities | Shared governance | Escalation path |
|---|---|---|---|
| **Security Program** | Delete authorization, audit integrity, cryptographic protection, data sanitization, and least-privilege access. | Security architecture review for any delete or audit change. | CISO / Security Architect |
| **Performance Program** | Delete latency, bulk-delete throughput, storage cleanup, and resource isolation. | Performance budget and load-test gating for delete flows. | Performance Architect |
| **Database Governance** | FK policies, trigger rules, indexing, schema migrations, and transaction isolation. | DB review for all schema, FK, and trigger changes. | Data Architect |
| **Platform Engineering** | Handler SDK, plugin model, service topology, multi-region support, and feature flags. | Platform architecture review for framework changes. | Platform Engineering Lead |
| **DevOps** | Deployment pipelines, rollback automation, environment parity, and observability wiring. | Deployment approval and pipeline gates. | DevOps Lead |
| **Compliance** | Regulatory retention, audit immutability, right-to-erasure, and privacy impact. | Compliance sign-off for audit and retention changes. | Compliance Officer |
| **Observability** | Correlation IDs, delete dashboards, alerts, and SLOs. | Observability standards review for all delete paths. | SRE Lead |
| **Testing** | Regression suite, synthetic delete data, failure-injection tests, and coverage gates. | Test plan approval for framework changes. | QA Lead |
| **Data Governance** | Data lineage, classification, retention, and cold-archive policy. | Data governance review for delete and audit retention. | Data Governance Lead |
| **Incident Management** | Delete-related incident triage, post-mortems, and architecture feedback. | Incident review linked to program lessons learned. | Incident Commander / SRE |

### 40.3 Shared review process

Any change that touches a shared responsibility is reviewed by the owning program before Architecture Board approval. Shared reviews are recorded in the change request and linked to the relevant ADR. No domain may bypass a shared review gate when the change falls under another program's scope.

### 40.4 Conflict resolution

When two programs disagree on a design, the Architecture Board convenes a joint review. The Chief Enterprise Architect chairs the review, and the decision is recorded as an ADR. In the event of a tie, the principle that best protects data integrity, auditability, and operational stability prevails.

### 40.5 Architecture ownership

The Architecture Board retains ultimate ownership of the cross-program architecture. Individual programs own their domain-specific implementations but must conform to the master architecture. No shared component may be changed without notifying the Architecture Repository steward.

---

## 41. Continuous Improvement Framework

### 41.1 Purpose

Enterprise architecture is never finished. This section defines the feedback loops that keep the Deletion & Audit architecture healthy, current, and resilient after the initial program is complete.

### 41.2 Improvement cadence

| Review | Frequency | Focus | Output |
|---|---|---|---|
| **Architecture Reviews** | Per change or quarterly | Validate that changes align with principles, ADRs, and the master program. | Review minutes, action items |
| **Quarterly Assessments** | Quarterly | Review KPIs, risks, dependency matrix, and maturity progression. | Quarterly architecture report |
| **Annual Program Review** | Annually | Reassess the entire architecture portfolio, principles, and long-term evolution. | Annual architecture strategy update |
| **Technical Debt Review** | Bi-annually | Identify and prioritize architectural debt in delete, audit, and transaction code. | Technical debt backlog |
| **Architecture Health Review** | Quarterly | Evaluate observability, test coverage, incident rate, and framework reuse. | Health scorecard |
| **Lessons Learned** | Per wave / per major incident | Capture what worked, what failed, and what should change. | Lessons-learned register |
| **Incident Feedback Loop** | Per delete-related incident | Convert incidents into architecture improvements or ADR updates. | Incident-to-architecture ticket |
| **Framework Evolution** | As needed | Propose and approve extensions such as workflow engine, event bus, or plugin model. | Framework evolution backlog |
| **Knowledge Sharing** | Quarterly | Disseminate architecture decisions, patterns, and lessons to engineering. | Architecture knowledge session |

### 41.3 From incident to improvement

Every production incident involving deletion, audit, transaction failure, or data inconsistency is treated as an architecture signal. The incident review answers:

1. Did the canonical framework fail, or did a deviation from the framework cause the incident?
2. Does the traceability model correctly link the incident to the relevant design and ADR?
3. Is there a missing principle, guard, or test?
4. Should an ADR, design, or standard be updated?
5. Are the runbooks, dashboards, or alerts adequate?

If the answer to any question reveals a gap, an architecture improvement item is created and prioritized through the change-management process.

### 41.4 Framework evolution

Improvements are not one-off fixes. They are batched into the framework evolution backlog and approved through the ADR process. This ensures that the platform matures deliberately and that every improvement strengthens the architecture.

---

## 42. Enterprise Success Model

### 42.1 Purpose

KPIs measure the program's operational health, but they do not fully capture the long-term enterprise value of the architecture. This section defines the qualitative dimensions of success and how they are evaluated over multiple years.

### 42.2 Qualitative success dimensions

| Dimension | Definition | Evaluation approach |
|---|---|---|
| **Engineering Productivity** | Teams spend less time debugging, re-implementing, or reasoning about deletion. | Time-to-implement a new domain delete; reduction in delete-related support tickets. |
| **Architecture Consistency** | The same patterns, language, and governance apply across all domains. | Architecture review pass rate; number of custom delete implementations. |
| **Operational Excellence** | Deletion is predictable, observable, and recoverable in production. | Incident rate, mean recovery time, rollback success, and SLO attainment. |
| **Platform Reuse** | New domains consume the canonical framework rather than building bespoke solutions. | Handler reuse rate; time to onboard a new deletable domain. |
| **Knowledge Reuse** | Architecture knowledge is discoverable, current, and used during design and incident response. | Repository usage metrics; onboarding time; incident response accuracy. |
| **AI Readiness** | Data, audit, and traceability are structured and governed so that AI-assisted analysis, impact prediction, and automation can be adopted safely. | Data lineage completeness; structured audit coverage; automation readiness score. |
| **Developer Onboarding** | New engineers understand the delete framework and its constraints quickly. | Onboarding time to first approved delete change; knowledge-base satisfaction. |
| **Governance Adoption** | Teams follow the governance chain, ADR process, and change-management process as a matter of routine. | ACR and ADR submission rate; compliance metrics. |
| **Long-term Maintainability** | The architecture can be extended, debugged, and operated without heroic effort. | Mean time to diagnose architectural debt; maintenance cost trend. |
| **Future Scalability** | The framework can support new domains, regions, services, and regulatory regimes without redesign. | Time to support a new region or compliance requirement; extension backlog size. |

### 42.3 Multi-year evaluation

Enterprise success is evaluated across rolling three-year horizons. Year one focuses on adoption and stabilization. Year two focuses on reuse, governance maturity, and operational excellence. Year three and beyond focus on platformization, AI readiness, and future scalability. The Chief Enterprise Architect reports these dimensions to executive leadership annually.

### 42.4 From success model to roadmap

The qualitative success model informs the long-term roadmap. Gaps identified in any dimension become architecture improvement items, prioritized through the change-management process, and recorded in the Enterprise Architecture Repository.

---

*End of document.*
