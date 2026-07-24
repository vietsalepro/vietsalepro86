# SPEC-006 — Observability Architecture Specification

**Project:** VietSalePro  
**Subsystem:** Enterprise Observability  
**Specification Name:** Observability Architecture Specification  
**Short Identifier:** Observability  
**Specification ID:** SPEC-006  
**Classification:** Operational  
**Status:** Baselined  
**Version:** 1.1  
**Effective Date:** 2026-07-24  
**Author:** Engineering Execution Agent  
**Technical Custodian:** Chief Technical Advisor (Architecture Governance)  
**Final Owner:** Production Owner  
**Approvers:** Chief Technical Advisor, Production Owner  
**Baseline Approved By:** Chief Technical Advisor (delegated by Production Owner)  
**Baseline Date:** 2026-07-24  
**Master Program Reference:** Deletion & Audit Architecture Remediation Program v1.0  
**Related Specifications:** SPEC-001 Delete Framework (mandatory); SPEC-002 Audit Architecture, SPEC-003 Transaction Architecture, SPEC-004 Trigger Governance, SPEC-005 Foreign Key Governance, SPEC-007 Regression & Verification (informative)  
**Related ADRs:** None recorded.  
**Roadmap Items:** None recorded.  

---

## 16.1 Metadata

This specification is the authoritative architecture definition for the **Observability Architecture** of VietSalePro. It is an **Operational** specification that defines how every critical operation, architectural boundary, and failure becomes explainable and diagnosable without owning business workflow or state. Its identifier is `SPEC-006`; its short identifier is `Observability`; its version is `1.1`.

| Field | Value |
|---|---|
| Project | VietSalePro |
| Subsystem | Enterprise Observability |
| Specification ID | SPEC-006 |
| Name | Observability Architecture Specification |
| Short Identifier | Observability |
| Classification | Operational |
| Status | Baselined |
| Version | 1.1 |
| Effective Date | 2026-07-24 |
| Author | Engineering Execution Agent |
| Technical Custodian | Chief Technical Advisor (Architecture Governance) |
| Final Owner | Production Owner |
| Approvers | Chief Technical Advisor, Production Owner |
| Baseline Approved By | Chief Technical Advisor (delegated by Production Owner) |
| Baseline Date | 2026-07-24 |
| Master Program | Deletion & Audit Architecture Remediation Program v1.0 |
| Related Specifications | SPEC-001 (mandatory); SPEC-002, SPEC-003, SPEC-004, SPEC-005, SPEC-007 (informative) |
| Related ADRs | None recorded |
| Roadmap Items | None recorded |

---

## 16.2 Purpose

**SPEC-006-PUR-001.** This document defines the enterprise Observability Architecture for VietSalePro.

**SPEC-006-PUR-002.** Observability exists to explain system behavior. Every critical operation must be observable, every architectural boundary must emit traceable events, and every failure must be diagnosable without modifying business state.

**SPEC-006-PUR-003.** This specification shall establish a passive, technology-neutral observability layer that provides correlation identifiers, structured events, logs, metrics, traces, alerts, dashboards, and retention governance for the delete, audit, transaction, trigger, and foreign-key lifecycle concerns defined in related specifications.

**SPEC-006-PUR-004.** The architecture shall ensure that every request has a correlation identifier, every transaction is traceable, every delete workflow is observable, every trigger execution is observable, and every foreign-key integrity failure is observable.

**SPEC-006-PUR-005.** Observability shall not implement business workflow, own transactions, own the audit lifecycle, own delete orchestration, or change business state. It is a passive, read-only-on-state instrumentation layer.

**SPEC-006-PUR-006.** This specification shall not prescribe source code, file names, deployment commands, or concrete product choices. Those details belong in Implementation Plans derived from this specification.

---

## 16.3 Scope

**SPEC-006-SCO-001.** This specification covers the conceptual observability architecture for all in-scope domains and cross-cutting platform operations of VietSalePro.

**SPEC-006-SCO-002.** The following in-scope domains are explicitly covered:

- Tenant
- User
- Product
- Customer
- Warehouse
- Employee
- Membership
- Subscription

**SPEC-006-SCO-003.** The architecture shall define:

- Observability principles, governance, objectives, ownership, and lifecycle;
- Event taxonomy, classification, and metadata;
- Correlation identifier model, trace model, span model, and context propagation;
- Logging, metrics, and tracing architecture;
- Audit observability, transaction observability, trigger observability, foreign-key observability, and delete-workflow observability;
- Error taxonomy, failure classification, health signals, operational signals, and business signals;
- Telemetry model, alerting principles, monitoring principles, dashboard principles;
- Incident investigation, root-cause traceability, diagnostic workflow, and retention principles;
- Security, compliance, privacy, and risk considerations;
- Architecture decisions, traceability, verification requirements, and acceptance criteria.

**SPEC-006-SCO-004.** This specification does not define the internal schemas, storage formats, or deployment artifacts of any specific observability implementation. Those are governed by related specifications and future Implementation Plans.

**SPEC-006-SCO-005.** Future domains introduced after initial implementation shall consume this observability architecture at design time; they shall not introduce independent observability semantics.

---

## 16.4 References

**SPEC-006-REF-001.** The following normative references govern this specification:

| Identifier | Title | Version | Purpose |
|---|---|---|---|
| Master Program | Deletion & Audit Architecture Remediation Program | v1.0 | Program vision, principles, workstreams, and scope |
| SPEC-001 | Delete Framework Architecture Specification | TBD (mandatory dependency) | Delete-lifecycle observability instrumentation |
| SPEC-002 | Audit Architecture Specification | TBD (informative dependency) | Audit record and integrity observability |
| SPEC-003 | Transaction Architecture Specification | TBD (informative dependency) | Transaction boundary and compensation observability |
| SPEC-004 | Trigger Governance Architecture Specification | TBD (informative dependency) | Trigger execution and classification observability |
| SPEC-005 | Foreign Key Governance Architecture Specification | TBD (informative dependency) | Relationship and integrity failure observability |
| SPEC-007 | Regression & Verification Architecture Specification | TBD (informative dependency) | Verification of observability requirements |
| Architecture Specification Program | Architecture Specification Program | v1.1 | Mandatory template, metadata, and governance rules |
| SPEC_BASELINE_CERTIFICATION | Architecture Specification Baseline Certification | v1.1 | Inheritance rules and allowed variations |
| ARCHITECTURE_SPECIFICATION_INDEX | Architecture Specification Index | v1.1 | Portfolio registration and dependency graph |

---

## 16.5 Architecture Context

**SPEC-006-CTX-001.** The VietSalePro platform currently produces operational events, logs, and errors in a domain-local and ad-hoc manner. The `delete-tenant` failure demonstrated that operators, support staff, and compliance reviewers cannot reliably reconstruct which step failed, what state had already changed, or which component produced an error.

**SPEC-006-CTX-002.** The underlying architectural deficiencies exposed by that incident are:

1. Requests do not consistently carry a propagated correlation identifier.
2. Errors are not structured; failure codes, recovery guidance, and ownership are missing from responses.
3. The delete lifecycle is not visible as a sequence of named, attributable steps.
4. Audit, transaction, trigger, and foreign-key events are emitted by separate mechanisms without a shared taxonomy.
5. Alerting and dashboard concerns are not tied to the failure model or diagnostic workflow.
6. Retention and privacy rules for observability data are not explicitly governed.

**SPEC-006-CTX-003.** The target architecture treats observability as a first-class, passive platform capability. Every critical operation emits standardized signals that can be correlated, queried, and used for incident investigation without direct access to production resources.

**SPEC-006-CTX-004.** The architecture shall be technology-neutral: it may be realized through agents, collectors, event buses, indexes, time-series stores, or query services, provided the contracts and invariants defined in this specification are preserved.

---

## 16.6 Responsibilities

**SPEC-006-RES-001.** The responsibilities of each architectural layer in the Observability Architecture are:

| Layer | Responsibility |
|---|---|
| Frontend | Attach correlation identifiers to outbound actions; render status, structured errors, and recovery guidance to the operator. |
| Service | Enrich correlation identifiers, emit domain events and timing spans, forward context to downstream components, and return structured errors. |
| Edge / Routing | Propagate correlation context, emit request-entry events, emit routing and rate-limiting signals, and preserve context across asynchronous boundaries. |
| Database | Emit transaction boundary events, row-level lifecycle events, and integrity findings without changing business logic or owning workflow. |
| Storage | Emit object lifecycle and cleanup events; attach correlation identifiers to storage operations. |
| Audit | Emit audit-write and integrity-verification events, as defined in SPEC-002. |
| Trigger | Emit trigger-fired, trigger-completed, and trigger-failed events, as defined in SPEC-004. |
| Foreign Key Governance | Emit relationship validation, drift, and integrity-failure events, as defined in SPEC-005. |
| Platform Operations | Define alert rules, dashboard semantics, retention policies, and incident investigation procedures. |
| Security & Compliance | Define privacy, retention, access control, and audit requirements for observability data. |

**SPEC-006-RES-002.** No observability component shall modify business state, commit or roll back transactions, or perform authorization decisions on behalf of business components.

**SPEC-006-RES-003.** The observability layer shall treat related specifications as signal producers and consumers: it shall observe their lifecycles and provide the evidence they require, but it shall not assume their responsibilities.

---

## 16.7 Architecture Principles Mapping

**SPEC-006-PRM-001.** The Observability Architecture shall implement every principle of the Master Program as follows:

| Principle | Mapping to Observability Architecture |
|---|---|
| Deletion is explicit | Every delete request is observable as an explicit intent with a correlation identifier and a step trace, per SPEC-001. |
| Deletion is deterministic | The same delete request, given the same state, emits the same sequence of observability signals. |
| Deletion is idempotent | Replayed operations are recognized in observability data; duplicate signals are idempotently represented or deduplicated without creating false alerts. |
| Deletion is observable | Every delete request carries a correlation identifier and produces a step trace across all layers. |
| Deletion is recoverable | Failure and recovery signals include structured error codes, affected steps, and recovery guidance. |
| Audit is immutable | Audit integrity signals are emitted whenever audit records are written or verified, per SPEC-002. |
| Database owns integrity | Database-level integrity events, including transaction boundaries and constraint findings, are emitted by the persistence layer. |
| Application owns workflow | Observability records workflow events but does not own the workflow decisions. |
| Platform before feature | Domain teams reuse the canonical observability contracts rather than inventing local logging or tracing conventions. |
| Reuse before reinvention | Existing platform signals and correlation schemes are consumed before new ones are created. |
| Side effects are compensatable | Compensation and retry events are emitted for every side-effect attempt. |
| Failure is a first-class state | Failed, retryable, compensating, and closed states are explicit observability events. |

**SPEC-006-PRM-002.** The following observability-specific principles are mandatory:

1. Observability exists to explain system behavior.
2. Every critical operation must be observable.
3. Every architectural boundary must emit traceable events.
4. Every failure must be diagnosable.
5. Every request shall have a correlation identifier.
6. Every transaction shall be traceable.
7. Every delete workflow shall be observable.
8. Every trigger execution shall be observable.
9. Every foreign-key integrity failure shall be observable.
10. Observability is passive and does not own business state.

---

## 16.8 Domain Model

**SPEC-006-DOM-001.** The Observability Architecture domain consists of the following conceptual objects, each with a single responsibility:

| Concept | Responsibility |
|---|---|
| Correlation ID | A globally unique identifier that binds all signals for one logical request across every layer and component. |
| Trace | A directed graph of spans that represents the end-to-end path of a logical operation. |
| Span | A named, timed interval of work performed by one component; a trace is composed of spans. |
| Event | An immutable record that a discrete thing occurred, including its type, timestamp, actor, correlation identifier, and payload. |
| Log Entry | A human-readable and machine-parseable record emitted by a component, bound to a correlation identifier and timestamp. |
| Metric | A numeric measurement aggregated over time, classified by name, dimensions, and value. |
| Alert Rule | A declarative condition that, when satisfied by signals, produces an alert for operators. |
| Dashboard | A read-only view that groups signals, metrics, and traces to support investigation and operational awareness. |
| Signal | The generic term for any emitted observability data: event, log entry, metric, or trace span. |
| Retention Policy | The rule set that governs how long each class of observability data is kept, anonymized, or purged. |
| Telemetry | The combined output of all signals and their supporting metadata, queryable for incident investigation. |
| Health Signal | A signal that indicates whether a component or subsystem is functioning within expected bounds. |
| Operational Signal | A signal that indicates resource utilization, throughput, latency, or error rates. |
| Business Signal | A signal that indicates counts or outcomes relevant to business operations. |

**SPEC-006-DOM-002.** A `Correlation ID` shall be created at the entry point of every logical operation and propagated to every downstream component, including asynchronous and scheduled paths.

**SPEC-006-DOM-003.** A `Trace` shall contain one or more `Span` objects, and each `Span` shall reference exactly one `Correlation ID`.

**SPEC-006-DOM-004.** An `Event` shall be immutable after capture. Transformation, enrichment, and routing shall produce new derived records rather than mutating the original.

---

## 16.9 Components

**SPEC-006-COM-001.** The Observability Architecture comprises the following logical components:

| Component | Role | Placement |
|---|---|---|
| Observability Emitter | Emits structured events, logs, metrics, and span boundaries from instrumented components. | Every layer |
| Correlation Manager | Creates, validates, and propagates correlation identifiers across synchronous and asynchronous boundaries. | Entry and routing layers |
| Trace Collector | Accepts and assembles spans into traces; preserves parent-child relationships. | Infrastructure layer |
| Log Router | Routes log entries to storage, index, or archival destinations while preserving correlation context. | Infrastructure layer |
| Metric Aggregator | Receives metric samples, applies dimensions, and produces aggregated time-series views. | Infrastructure layer |
| Event Catalog | Maintains the canonical event taxonomy, classification, and schema registry. | Governance layer |
| Alert Manager | Evaluates alert rules against signals and routes alerts to the appropriate owner. | Operations layer |
| Dashboard Provider | Serves read-only dashboards that query telemetry by correlation identifier, component, or time. | Operations layer |
| Query/Analytics Engine | Supports ad-hoc investigation, correlation reconstruction, and aggregation queries. | Operations layer |
| Retention Manager | Applies retention and privacy policies to each class of observability data. | Governance/Operations layer |
| Privacy Anonymizer | Redacts or tokenizes sensitive fields before storage or export. | Security layer |

**SPEC-006-COM-002.** The `Observability Emitter` shall not change the outcome of the operation it instruments. If emission fails, the operation shall continue unless otherwise specified by a related specification.

**SPEC-006-COM-003.** The `Correlation Manager` shall be the sole source of new correlation identifiers for entry-point operations; downstream components shall propagate the identifier they receive.

---

## 16.10 Interfaces

**SPEC-006-INT-001.** The Observability Architecture exposes the following abstract interfaces:

### 16.10.1 Signal Ingestion Interface

| Attribute | Type | Description |
|---|---|---|
| `correlation_id` | Identifier | The propagated correlation identifier for the logical operation. |
| `signal_type` | Enumeration | One of `event`, `log`, `metric`, or `trace_span`. |
| `timestamp` | Timestamp | The time at which the signal was emitted. |
| `source` | Component name | The component or layer that emitted the signal. |
| `payload` | Structured map | Type-specific fields, redacted of secrets and unnecessary personal data. |
| `severity` | Enumeration | Optional severity class for event and log signals. |

### 16.10.2 Trace Span Interface

| Attribute | Type | Description |
|---|---|---|
| `span_id` | Identifier | Unique identifier for this span. |
| `parent_id` | Identifier | Optional identifier of the parent span. |
| `correlation_id` | Identifier | The trace correlation identifier. |
| `name` | String | Human-readable span name, such as the operation being performed. |
| `start_time` | Timestamp | Span start time. |
| `end_time` | Timestamp | Span end time. |
| `status` | Enumeration | `ok`, `error`, or `unknown`. |
| `attributes` | Structured map | Key-value pairs describing the span context. |

### 16.10.3 Metric Sample Interface

| Attribute | Type | Description |
|---|---|---|
| `name` | String | Metric name from the canonical metric catalog. |
| `value` | Numeric | The measured value. |
| `timestamp` | Timestamp | Sampling time. |
| `dimensions` | Structured map | Categorical dimensions, such as domain, classification, or component. |

### 16.10.4 Alert Rule Interface

| Attribute | Type | Description |
|---|---|---|
| `rule_id` | Identifier | Unique alert rule identifier. |
| `name` | String | Human-readable rule name. |
| `condition` | Expression | The predicate over signals that triggers an alert. |
| `severity` | Enumeration | Alert severity class. |
| `owner` | Role | The role accountable for response. |
| `runbook_reference` | Reference | Pointer to diagnostic or recovery guidance. |

### 16.10.5 Dashboard Query Interface

| Attribute | Type | Description |
|---|---|---|
| `query_id` | Identifier | Saved or ad-hoc query identifier. |
| `filters` | Structured map | Correlation identifier, component, event type, time range, severity, or domain filters. |
| `aggregation` | Enumeration | Optional aggregation mode, such as count, rate, or distribution. |
| `visualization` | Enumeration | Optional preferred visualization type. |

**SPEC-006-INT-002.** The Signal Ingestion Interface shall accept all observability signals emitted by instrumented components.

**SPEC-006-INT-003.** The Dashboard Query Interface shall support reconstruction of the full lifecycle of any operation from its `correlation_id` without direct access to the production runtime.

---

## 16.11 Contracts

**SPEC-006-CON-001.** The Observability Architecture contracts are technology-neutral and implementation-neutral. Every implementation shall honor the following contracts:

### 16.11.1 Correlation Identifier Contract

**SPEC-006-CON-002.** Every logical operation shall be assigned a unique `correlation_id` at its entry point and propagated unchanged to every downstream component.

**SPEC-006-CON-003.** Asynchronous operations, including scheduled jobs and outbox processors, shall carry the originating `correlation_id` in their context.

**SPEC-006-CON-004.** If a request is missing a `correlation_id` when received by a downstream component, the component shall generate a new one, mark the signal as `correlation_inferred`, and continue processing.

### 16.11.2 Event Contract

**SPEC-006-CON-005.** Every event shall contain `correlation_id`, `event_type`, `timestamp`, `source`, `actor`, and `outcome`.

**SPEC-006-CON-006.** Event types shall be drawn from the canonical Event Taxonomy maintained by the `Event Catalog`.

**SPEC-006-CON-007.** Event payloads shall not contain secrets, credentials, or unredacted personal data.

### 16.11.3 Trace and Span Contract

**SPEC-006-CON-008.** Every critical operation shall be represented by a `Trace` composed of one or more `Span` objects.

**SPEC-006-CON-009.** A `Span` shall capture a named, timed unit of work performed by one component and reference its parent span or the trace root.

**SPEC-006-CON-010.** Spans crossing a trust or persistence boundary shall be emitted at both sides of the boundary with the same `correlation_id`.

### 16.11.4 Metric Contract

**SPEC-006-CON-011.** Metric names shall be stable and hierarchical. A metric name shall identify what is measured, and its `dimensions` shall identify the context.

**SPEC-006-CON-012.** Metric samples shall include a timestamp and numeric value. Counter metrics shall be monotonically increasing within a reporting window unless reset explicitly by a documented maintenance action.

### 16.11.5 Log Contract

**SPEC-006-CON-013.** Every log entry shall be structured, containing `correlation_id`, `timestamp`, `severity`, `source`, `message_template`, and named parameters.

**SPEC-006-CON-014.** Log messages shall be phrased as statements of fact about the system, not as diagnostic advice for operators. Recovery guidance belongs in error contracts, not log text.

### 16.11.6 Alert Contract

**SPEC-006-CON-015.** An alert shall fire only when a documented `Alert Rule` condition is satisfied by signals.

**SPEC-006-CON-016.** Every alert shall include `correlation_id` or a query filter, `severity`, `affected_component`, `failure_class`, and `runbook_reference`.

### 16.11.7 Retention Contract

**SPEC-006-CON-017.** Every signal class shall be assigned a `Retention Policy` that defines retention duration, anonymization schedule, and authorized access roles.

**SPEC-006-CON-018.** Retention actions shall themselves emit an observability event.

### 16.11.8 Privacy Contract

**SPEC-006-CON-019.** Observability data shall be classified by sensitivity at the point of emission. Sensitive values shall be redacted, tokenized, or excluded before storage or export.

### 16.11.9 Passivity Contract

**SPEC-006-CON-020.** Observability components shall be passive. They shall not own transactions, modify business state, or alter the outcome of the operations they observe.

### 16.11.10 Cross-Specification Contract

**SPEC-006-CON-021.** SPEC-001 Delete Framework shall emit delete-lifecycle signals as defined in SPEC-001 Section 16.19. This specification defines the canonical ingestion, correlation, and presentation contracts for those signals.

**SPEC-006-CON-022.** SPEC-002 Audit Architecture shall emit audit-write and integrity signals as defined in SPEC-002 Section 16.19. This specification defines how those signals are correlated with the broader request lifecycle.

**SPEC-006-CON-023.** SPEC-003 Transaction Architecture shall emit transaction boundary and compensation signals as defined in SPEC-003 Section 16.19. This specification defines how those signals are represented as traces and metrics.

**SPEC-006-CON-024.** SPEC-004 Trigger Governance shall emit trigger execution signals as defined in SPEC-004 Section 16.19. This specification defines the canonical event schema and alert conditions for those signals.

**SPEC-006-CON-025.** SPEC-005 Foreign Key Governance shall emit relationship and integrity-failure signals as defined in SPEC-005 Section 16.19. This specification defines how those signals are aggregated and alerted.

---

## 16.12 State Machine

**SPEC-006-STM-001.** The Observability Architecture defines the lifecycle of a captured signal as follows:

### 16.12.1 Signal Lifecycle States

```
Emitted -> Captured -> Enriched -> Routed -> Indexed -> Retained -> Expired
```

| State | Meaning |
|---|---|
| Emitted | A component produced a raw signal. |
| Captured | The signal was accepted by the ingestion path. |
| Enriched | Correlation, classification, and privacy context were applied. |
| Routed | The signal was directed to the appropriate storage, index, or stream. |
| Indexed | The signal is available for query and aggregation. |
| Retained | The signal is stored under an active retention policy. |
| Expired | The signal has reached the end of its retention period and has been purged or anonymized. |

### 16.12.2 Alert Lifecycle States

```
Armed -> Evaluating -> Firing -> Acknowledged -> Resolved
```

| State | Meaning |
|---|---|
| Armed | The alert rule is active and monitoring signals. |
| Evaluating | The rule condition is being checked against a window of signals. |
| Firing | The condition is satisfied and a notification has been generated. |
| Acknowledged | An operator has taken ownership of the alert. |
| Resolved | The condition is no longer satisfied or the incident is closed. |

### 16.12.3 Transition Rules

**SPEC-006-STM-002.** A signal shall move from `Emitted` to `Captured` only if it conforms to the `Signal Ingestion Interface`.

**SPEC-006-STM-003.** A signal shall move from `Captured` to `Enriched` after correlation and privacy classification are applied.

**SPEC-006-STM-004.** A signal in `Routed` shall not be lost before `Indexed` without a corresponding `signal_dropped` event.

**SPEC-006-STM-005.** An alert shall transition from `Firing` to `Acknowledged` only through explicit operator action.

---

## 16.13 Workflow

**SPEC-006-WFL-001.** The canonical observability workflow is:

1. A logical operation begins and the `Correlation Manager` assigns or receives a `correlation_id`.
2. Each boundary crossed by the operation emits signals through the `Observability Emitter`.
3. The `Trace Collector` assembles spans into a trace keyed by `correlation_id`.
4. The `Log Router` and `Metric Aggregator` store logs and metrics under the same `correlation_id`.
5. The `Alert Manager` evaluates rules against incoming signals and produces alerts.
6. Operators use the `Dashboard Provider` and `Query/Analytics Engine` to investigate by `correlation_id`, component, or time.
7. The `Retention Manager` applies retention and privacy policies, emitting lifecycle events for each action.

**SPEC-006-WFL-002.** Every step of the workflow is itself observable. The observability pipeline shall emit health signals for ingestion lag, drop rates, indexing delays, and alert evaluation errors.

---

## 16.14 Sequence

**SPEC-006-SEQ-001.** The following sequence illustrates observability for a representative critical operation. The actual operation may be a delete request, transaction, trigger, or foreign-key validation; the observability pattern is the same.

1. **Entry** — The caller submits a request. The `Correlation Manager` assigns `correlation_id` `C1`.
2. **Routing** — The edge layer emits a `request_received` event carrying `C1`, source, and timestamp.
3. **Validation** — The service layer emits a `validation_started` span and a matching `validation_completed` or `validation_failed` span, both carrying `C1`.
4. **Transaction boundary** — The database layer emits a `transaction_begin` event and, later, `transaction_commit` or `transaction_rollback`, each carrying `C1`.
5. **Side effect** — A side-effect handler emits `side_effect_attempt`, `side_effect_result`, and, if needed, `compensation_initiated` events carrying `C1`.
6. **Audit** — The audit writer emits `audit_record_written` carrying `C1` and the `audit_id` defined in SPEC-002.
7. **Trigger** — Any trigger executed emits `trigger_fired`, `trigger_completed` or `trigger_failed` carrying `C1`.
8. **Result** — The response to the caller includes `correlation_id` `C1` and a structured `error_code` if applicable.
9. **Alert** — The `Alert Manager` evaluates `C1` events and fires an alert if a rule condition is met.
10. **Investigation** — An operator queries by `C1` and reconstructs the entire sequence across all layers.

**SPEC-006-SEQ-002.** Asynchronous and scheduled operations shall preserve `correlation_id` across handoffs. A new `correlation_id` shall not be created for continuations of the same logical operation unless the original context is unavailable.

---

## 16.15 Data Model

**SPEC-006-DAT-001.** The logical data model for observability contains the following core entities:

| Entity | Key Attributes | Ownership | Retention Class |
|---|---|---|---|
| Correlation | `correlation_id`, `entry_source`, `entry_time`, `ttl` | Platform Operations | Operational |
| Trace | `trace_id`, `root_span_id`, `duration`, `status` | Platform Operations | Operational |
| Span | `span_id`, `parent_id`, `trace_id`, `name`, `start`, `end`, `status` | Platform Operations | Operational |
| Event | `event_id`, `correlation_id`, `event_type`, `timestamp`, `source`, `actor`, `outcome` | Platform Operations | Operational/Business |
| Log Entry | `log_id`, `correlation_id`, `timestamp`, `severity`, `source`, `message`, `params` | Component owner | Operational/Compliance |
| Metric | `metric_id`, `name`, `timestamp`, `value`, `dimensions` | Platform Operations | Business/Operational |
| Alert | `alert_id`, `rule_id`, `correlation_id`, `severity`, `timestamp`, `state` | Operations layer | Operational |
| Dashboard | `dashboard_id`, `query_definitions`, `authorized_roles` | Operations/Security | Long-term |
| Retention Policy | `policy_id`, `signal_class`, `duration`, `anonymization_action` | Security & Compliance | Governance |

**SPEC-006-DAT-002.** Each entity shall be owned by exactly one role. Ownership determines who may define schema, access rules, and retention policy.

**SPEC-006-DAT-003.** Retention classes are `Operational`, `Business`, `Compliance`, and `Governance`. The `Retention Manager` applies the policy that matches the signal class and jurisdiction requirements.

---

## 16.16 Failure Model

**SPEC-006-FAM-001.** The following failure modes are recognized by the Observability Architecture:

| ID | Failure Mode | Likelihood | Impact | Detection | Propagation |
|---|---|---|---|---|---|
| SPEC-006-FAM-001 | Missing correlation identifier in request or signal | Medium | High | Capture-time validation | Inability to reconstruct the operation |
| SPEC-006-FAM-002 | Signal loss before capture or indexing | Low | High | Ingestion lag and drop-rate metrics | Gaps in traces and dashboards |
| SPEC-006-FAM-003 | Trace discontinuity across an asynchronous boundary | Medium | High | Parent-child validation | Broken root-cause traceability |
| SPEC-006-FAM-004 | Metric cardinality explosion from unbounded dimensions | Low | High | Cardinality monitoring | Degraded aggregation and query performance |
| SPEC-006-FAM-005 | Alert storm from a cascading failure | Medium | High | Alert rate metrics | Operator overload and missed root cause |
| SPEC-006-FAM-006 | Sensitive data in signal payload | Low | Critical | Privacy classification scan | Compliance violation and data leak |
| SPEC-006-FAM-007 | Retention policy violation | Low | Critical | Retention audit | Unauthorized data exposure or premature loss |
| SPEC-006-FAM-008 | Clock skew causing incorrect trace ordering | Medium | Medium | Cross-component timestamp validation | Misleading diagnostic timelines |
| SPEC-006-FAM-009 | Sampling bias hiding low-frequency failures | Low | High | Sampling coverage audit | False confidence in failure rates |
| SPEC-006-FAM-010 | Observability pipeline outage masking operational failures | Low | Critical | Pipeline health signals | Blind spots during incidents |

---

## 16.17 Recovery Model

**SPEC-006-RCM-001.** The following recovery actions address the failure modes defined in Section 16.16:

| Failure Mode | Recovery Action | Owner |
|---|---|---|
| Missing correlation identifier | Infer a new identifier, emit `correlation_inferred` event, and propagate the inferred value. | Correlation Manager |
| Signal loss | Re-emit from source when possible; otherwise record `signal_dropped` event and alert on sustained loss. | Platform Engineering |
| Trace discontinuity | Provide correlation fallback by request identifiers, timestamps, and actor; emit `trace_gap` event. | Trace Collector |
| Cardinality explosion | Enforce dimension allow-lists and sampling; reject or aggregate unknown high-cardinality dimensions. | Metric Aggregator |
| Alert storm | Apply alert grouping, suppression, and severity escalation; provide alert-rate dashboards. | Alert Manager |
| Sensitive data in payload | Redact or quarantine the signal, emit `privacy_violation` event, and notify Security & Compliance. | Privacy Anonymizer |
| Retention violation | Halt unauthorized access, quarantine affected data, and escalate to Security & Compliance. | Retention Manager |
| Clock skew | Normalize timestamps using a monotonic clock or authoritative time source; emit `clock_skew` event. | Trace Collector |
| Sampling bias | Document sampling policy, provide unsampled critical-path capture, and audit coverage. | Platform Engineering |
| Pipeline outage | Buffer signals at source, fail-open for business operations, and emit `pipeline_degraded` alert. | Platform Operations |

---

## 16.18 Security

**SPEC-006-SEC-001.** Observability data shall be protected under least-privilege access controls. Only authorized roles may query, export, or retain telemetry.

**SPEC-006-SEC-002.** Secret values, credentials, tokens, and raw authentication material shall never be emitted in observability signals.

**SPEC-006-SEC-003.** Personal data shall be classified at emission and redacted, tokenized, or anonymized before long-term retention or export.

**SPEC-006-SEC-004.** Access to telemetry by correlation identifier shall be restricted to the tenant, actor, and role that are authorized to view the underlying operation.

**SPEC-006-SEC-005.** Cross-tenant observability queries shall be prohibited unless explicitly authorized by the tenant and logged.

**SPEC-006-SEC-006.** Encryption in transit and when stored shall apply to observability data in accordance with the organizational data-protection policy.

---

## 16.19 Observability

**SPEC-006-OBS-001.** The Observability Architecture shall be self-observable. The observability pipeline shall emit the following health signals:

| Type | Requirement |
|---|---|
| Events | `ingestion_received`, `ingestion_dropped`, `index_lag`, `query_executed`, `retention_applied`. |
| Metrics | Ingestion throughput, drop rate, indexing lag, query latency, alert evaluation latency, pipeline error rate. |
| Traces | Trace the ingestion and routing path of a sample of signals through the pipeline. |
| Alerts | Alert on sustained ingestion drop, indexing lag exceeding threshold, and pipeline error rate spikes. |
| Dashboards | Dashboard showing pipeline health, signal volume, retention status, and query performance. |

**SPEC-006-OBS-002.** The observability layer shall enable operators to reconstruct the full lifecycle of any signal from `correlation_id` without querying production resources directly.

**SPEC-006-OBS-003.** All observability pipeline failures shall include structured error codes and recovery guidance suitable for support staff and compliance reviewers.

---

## 16.20 Risks

**SPEC-006-RSK-001.** The following risks are introduced or mitigated by the Observability Architecture:

| ID | Risk | Likelihood | Impact | Owner | Mitigation |
|---|---|---|---|---|---|
| SPEC-006-RSK-001 | A new domain bypasses the canonical observability contracts and invents local logging conventions. | Medium | High | Chief Technical Advisor | Mandatory architecture review and observability onboarding for every new domain. |
| SPEC-006-RSK-002 | Sensitive data leaks into observability signals. | Low | Critical | Security & Compliance | Privacy classification, redaction, and automated scanning at ingestion. |
| SPEC-006-RSK-003 | High-cardinality metrics cause query or storage degradation. | Low | High | Platform Engineering | Dimension allow-lists and cardinality limits. |
| SPEC-006-RSK-004 | Correlation identifiers are lost across asynchronous boundaries. | Medium | High | Platform Engineering | Context propagation contract and integration tests for every async handoff. |
| SPEC-006-RSK-005 | Alert rules produce storms or false positives. | Medium | Medium | Platform Operations | Alert grouping, suppression, severity escalation, and periodic review. |
| SPEC-006-RSK-006 | Retention policies are misconfigured and retain sensitive data too long. | Low | Critical | Security & Compliance | Retention policy review and automated retention audit. |
| SPEC-006-RSK-007 | The observability pipeline becomes a single point of failure. | Low | High | Platform Operations | Buffer-at-source, fail-open semantics, and pipeline health alerting. |

---

## 16.21 Constraints

**SPEC-006-CST-001.** The Observability Architecture shall operate within the following constraints:

| ID | Constraint | Source |
|---|---|---|
| SPEC-006-CST-001 | The architecture shall be technology-neutral and shall not assume any specific collector, index, time-series store, or dashboard tool. | Architecture Specification Program Section 18. |
| SPEC-006-CST-002 | Observability components shall be passive and shall not own transactions, audit lifecycle, or delete orchestration. | Master Program Guiding Principles. |
| SPEC-006-CST-003 | Observability data shall not change business state. | Master Program Guiding Principle: Application owns workflow. |
| SPEC-006-CST-004 | Every signal shall include a correlation identifier or a documented `correlation_inferred` marker. | This specification Section 16.11.1. |
| SPEC-006-CST-005 | Sensitive and personal data shall be redacted or tokenized before retention or export. | Security and privacy policies. |
| SPEC-006-CST-006 | Retention policies shall be auditable and shall not be shorter than the shortest required compliance interval. | Compliance policy. |
| SPEC-006-CST-007 | Failure responses shall be structured and shall include correlation identifiers and recovery guidance. | Master Program Success Criteria. |

---

## 16.22 Non-goals

**SPEC-006-NGO-001.** This specification explicitly does not cover:

1. Source code, file names, package structures, or deployment commands.
2. Concrete log formats, storage schemas, query languages, or dashboard implementation technologies.
3. Specific product choices such as a particular collector, time-series database, or visualization platform.
4. Operational runbooks, on-call rotations, or incident response playbooks.
5. Business analytics, revenue reporting, or customer-facing metrics beyond operational signals.
6. Data-retention legal hold decisions, which are inputs to the retention policy, not outputs of this specification.
7. Transition scripts for moving from legacy logging to canonical observability, which belong in a Transition Specification or Implementation Plan.
8. Day-to-day operational tuning of thresholds or sampling rates, which belong in Operational Specifications.

---

## 16.23 Verification Requirements

**SPEC-006-VRF-001.** The Observability Architecture implementation shall be verified against the following requirements:

| ID | Verification Requirement | Method |
|---|---|---|
| SPEC-006-VRF-001 | Every critical operation emits a `correlation_id` at the entry point and propagates it across all layers. | Static code review and integration tests. |
| SPEC-006-VRF-002 | Every in-scope domain uses the canonical event taxonomy and signal schema. | Schema validation and governance audit. |
| SPEC-006-VRF-003 | Delete, audit, transaction, trigger, and foreign-key events are observable in the canonical dashboards. | End-to-end signal presence tests. |
| SPEC-006-VRF-004 | Structured errors include `correlation_id`, `error_code`, and recovery guidance. | Error-response contract tests. |
| SPEC-006-VRF-005 | Trace reconstruction from `correlation_id` returns a complete ordered sequence of spans. | Trace validation tests. |
| SPEC-006-VRF-006 | Alert rules fire only for documented conditions and include runbook references. | Alert rule review and simulation tests. |
| SPEC-006-VRF-007 | Privacy classification and redaction are applied before long-term retention. | Privacy audit and data-scan tests. |
| SPEC-006-VRF-008 | Retention policies are enforced and auditable for each signal class. | Retention audit tests. |
| SPEC-006-VRF-009 | The observability pipeline emits health signals for ingestion, indexing, and alerting. | Pipeline health tests. |
| SPEC-006-VRF-010 | Cross-tenant telemetry queries are blocked by access controls. | Security access-control tests. |

---

## 16.24 Acceptance Criteria

**SPEC-006-ACC-001.** The Observability Architecture specification and its implementation are accepted when:

1. All mandatory sections are present and reviewed.
2. All requirements carry unique identifiers and are traceable to verification requirements and acceptance criteria.
3. The implementation passes all verification requirements in Section 16.23.
4. Every in-scope domain emits observability signals through the canonical contracts.
5. The `delete-tenant` pilot, or equivalent representative operation, can be reconstructed end-to-end by `correlation_id`.
6. No observability component modifies business state or owns transactions.
7. Privacy and retention policies are enforced without exception.
8. Dashboards and alerts cover delete, audit, transaction, trigger, and foreign-key lifecycles.
9. The Production Owner approves the specification and the implementation.

---

## 16.25 Future Evolution

**SPEC-006-FEV-001.** The Observability Architecture is designed to evolve without redesign. The following extension points are preserved:

| Extension | Description |
|---|---|
| New domains | New domains shall register their event types in the `Event Catalog` and emit through the `Observability Emitter`. |
| New signal classes | New signal classes, such as profile or sustainability metrics, shall be added by extending the `Signal Ingestion Interface`. |
| New alert dimensions | Alert rules may reference new dimensions without changing the rule contract. |
| Multi-region | The architecture shall support region-aware correlation and retention by including region in the `Event` and `Span` attributes. |
| Long-term archives | Signals may be cold-archived after active retention without altering the correlation or query semantics. |
| Anomaly detection | Future automated analysis may consume the canonical event taxonomy and metrics without altering emission contracts. |

**SPEC-006-FEV-002.** Any change that adds, removes, or reclassifies an event type or metric shall require an Architecture Decision Record per the Master Program Section 29.

---

## Architecture Decisions (Supplementary)

The following architecture decisions shape the Observability Architecture. They are recorded here because they drive the contracts and components in the preceding sections.

1. **Passivity.** Observability shall be a passive instrumentation layer. No observability component shall own business workflow, transactions, audit lifecycle, or delete orchestration.

2. **Correlation-first context.** Every logical operation shall carry a single `correlation_id` from entry point through every synchronous and asynchronous boundary. Context propagation is the responsibility of every layer, not a centralized gate.

3. **Canonical event taxonomy.** The `Event Catalog` shall own the canonical event taxonomy. Domain teams may register new event types but shall not invent independent observability taxonomies.

4. **Privacy by emission.** Signals shall be classified by sensitivity at the point of emission. Redaction, tokenization, and anonymization shall occur before long-term retention, not as a post-hoc batch process.

5. **Schema-on-write for operational signals.** Metric and log schemas shall be defined before activation. Schema-on-write is preferred over schema-on-read for operational signals to preserve query determinism.

6. **Self-observing pipeline.** The observability pipeline shall emit health signals about its own ingestion, routing, indexing, and alerting so the pipeline can be diagnosed without direct production access.

7. **Cross-specification contracts over local instrumentation.** Delete, audit, transaction, trigger, and foreign-key domains shall emit signals that conform to this architecture, while retaining their own lifecycle ownership.

---

## 16.26 Appendix

### A. Event Classification Matrix

| Event Class | Description | Examples |
|---|---|---|
| Lifecycle | Marks a transition in an operation or entity lifecycle. | `request_received`, `validation_completed`, `transaction_committed` |
| Health | Indicates component health status. | `component_healthy`, `component_degraded` |
| Operational | Indicates throughput, latency, or resource utilization. | `metric_sample` with `operation_duration` |
| Business | Indicates a business-meaningful outcome. | `order_completed`, `subscription_cancelled` |
| Security | Indicates access, authorization, or privacy events. | `unauthorized_query_attempt`, `privacy_violation` |
| Failure | Indicates an error or exception condition. | `validation_failed`, `transaction_rollback` |
| Recovery | Indicates a remediation or compensation action. | `compensation_initiated`, `alert_acknowledged` |

### B. Error Taxonomy

| Failure Class | Meaning | Example |
|---|---|---|
| Transient | May resolve on retry. | Network timeout, temporary ingestion lag. |
| Permanent | Requires intervention or compensation. | Constraint violation, unrecoverable data loss. |
| Setup | Caused by incorrect policy or rule. | Retention mismatch, alert threshold error. |
| Security | Involves unauthorized access or data leak risk. | Cross-tenant query, unredacted payload. |
| Pipeline | Failure inside the observability pipeline itself. | Indexer outage, signal drop. |
| Unknown | Class not yet determined. | Must be escalated to operations. |

### C. Glossary

| Term | Definition |
|---|---|
| Correlation ID | A globally unique identifier that binds all signals for a single logical operation. |
| Trace | A directed graph of spans representing an end-to-end operation. |
| Span | A named, timed unit of work in a trace. |
| Signal | Any observability data: event, log entry, metric, or trace span. |
| Event Catalog | The canonical registry of event types and schemas. |
| Alert Rule | A declarative condition that produces an alert when satisfied. |
| Retention Policy | The rule set that governs signal lifetime, anonymization, and purging. |

### D. Traceability Summary

| This Specification Section | Traces To |
|---|---|
| 16.2 Purpose | Master Program Sections 1, 2, 3, 7, 8, 10.8 |
| 16.3 Scope | Master Program Section 9 |
| 16.5 Architecture Context | Master Program Sections 4, 5, 6, 22 |
| 16.6 Responsibilities | Master Program Section 10.6, 10.8 |
| 16.7 Architecture Principles Mapping | Master Program Section 23 |
| 16.8 Domain Model | Master Program Section 24 |
| 16.9 Components | Master Program Sections 10.1, 10.8 |
| 16.10 Interfaces | Master Program Sections 10.1, 10.8 |
| 16.11 Contracts | Master Program Sections 10.1, 10.2, 10.3, 10.4, 10.5, 10.8 |
| 16.12 State Machine | Master Program Section 25 |
| 16.13 Workflow | Master Program Sections 10.6, 10.8 |
| 16.14 Sequence | Master Program Sections 10.1, 10.8 |
| 16.15 Data Model | Master Program Section 24 |
| 16.16 Failure Model | Master Program Section 28 |
| 16.17 Recovery Model | Master Program Sections 10.7, 28 |
| 16.18 Security | Master Program Guiding Principles |
| 16.19 Observability | Master Program Section 10.8 |
| 16.23 Verification Requirements | Master Program Section 20 |
| 16.24 Acceptance Criteria | Master Program Sections 13, 14 |

---

## Evidence

### E.1 Foundation Documents Consulted

The following foundation documents were read and followed:

1. `.codebase-memory/CODEBASE_MEMORY_BASELINE.md` — Project baseline, repository architecture, validation status, and known limitations.
2. `.codebase-memory/SEMANTIC_MEMORY.md` — Architecture overview, business modules, tenant lifecycle, deletion patterns, and confidence gaps.
3. `.codebase-memory/VALIDATION_REPORT.md` — Coverage assessment, risks, and recommendations.

### E.2 Governance Documents Consulted

The following governance documents were read in the required order:

1. `Deletion_Audit_Architecture_Remediation_Program.md` (Master Program v1.0) — Vision, principles, goals, workstreams, scope, state machine, domain model, classification, dependency matrix, risks, and success criteria.
2. `01_Governance/Architecture_Specification_Program.md` (Specification Program v1.1) — Mandatory template, metadata, versioning, naming, folder structure, traceability, dependency, and quality gates.
3. `01_Governance/ARCHITECTURE_SPECIFICATION_INDEX.md` (Index v1.1) — SPEC-006 registration, classification, dependencies, portfolio position, and authoring order.

### E.3 Cross-Validation Results

| Check | Result |
|---|---|
| SPEC-006 registered in Index | ✓ Found in Index as Operational and Planned. |
| Specification ID matches | ✓ SPEC-006 in both Index and this document. |
| Classification is Operational | ✓ Header, metadata table, and narrative updated to Operational. |
| No circular dependencies introduced | ✓ SPEC-006 declares only informative dependencies. |
| Mandatory 26-section template followed | ✓ All sections 16.1–16.26 are present. |
| No implementation artifacts introduced | ✓ No source code, schema, deployment, or rollout instructions present. |

### E.4 Extracted Governance Summary

The inheritance rules from `SPEC_BASELINE_CERTIFICATION.md` (Section 15) were applied:

- Document header, metadata table, ownership model, status model, requirement identifier convention, evidence format, traceability format, quality gates, normative language, section numbering, and appendix organization were inherited from SPEC-001.
- The allowed variations for SPEC-006 (Baseline Certification Section 20.5) were used to shape the domain model, components, contracts, state machine, failure model, and recovery model around observability concerns.

SPEC-001 was used only as the golden authoring example. The document structure, metadata fields, section numbering, traceability summary, and evidence format were inherited. No delete-framework-specific architecture, lifecycle, contracts, or workflows were copied.

### E.5 Portfolio Validation

- SPEC-006 is registered in `ARCHITECTURE_SPECIFICATION_INDEX.md` as the Observability Architecture Specification.
- The Index records classification `Operational` and status `Planned`; the header, metadata table, and `16.1 Metadata` narrative now align with `Operational`.
- The specification ID, short identifier, name, and version match the Index entry.
- No implementation, source code, database schema, data transition, remote calls, or Edge Function changes were performed.
- The draft file is placed in `02_Specifications/` as specified by the Index.

### E.6 Dependency Validation

| Specification | Verified Reference |
|---|---|
| SPEC-002 Audit Architecture | Observability ingestion/correlation contracts without duplicating audit immutability, retention, or write responsibilities. |
| SPEC-003 Transaction Architecture | Transaction boundary and compensation signals represented as traces/metrics without owning commit, rollback, or outbox logic. |
| SPEC-004 Trigger Governance | Canonical event schema and alert conditions for trigger execution signals without classifying triggers or governing lifecycles. |
| SPEC-005 Foreign Key Governance | Relationship and integrity-failure signals aggregated and alerted without governing `ON DELETE` policies or relationship classification. |

- Delete workflow observability references SPEC-001 Section 16.19.
- Audit observability references SPEC-002 Section 16.19.
- Transaction observability references SPEC-003 Section 16.19.
- Trigger observability references SPEC-004 Section 16.19.
- Foreign-key observability references SPEC-005 Section 16.19.
- No architectural responsibilities of the related specifications are duplicated.

### E.7 Template Compliance

- The mandatory 26-section template (Sections 16.1–16.26) is present and ordered.
- No product-specific or framework-specific terms appear in the specification. No source code, deployment commands, file names, or storage schemas are prescribed.
- The architecture is described in terms of components, interfaces, contracts, and invariants.
- The specification does not prescribe a programming language, runtime, database, collector, index, time-series store, dashboard tool, or messaging technology.
- The Architecture Decisions (Supplementary) section is preserved at its existing location per the Allowed Evolution finding D-07.

### E.8 Traceability Summary

Traceability is maintained to:

- Master Program: `Deletion & Audit Architecture Remediation Program v1.0`
- Golden Specification: `SPEC-001 Delete Framework Architecture Specification v1.1`
- Related Specifications: `SPEC-002 Audit Architecture v1.0`, `SPEC-003 Transaction Architecture v1.0`, `SPEC-004 Trigger Governance v1.0`, `SPEC-005 Foreign Key Governance v1.0`
- Governance: `Architecture Specification Program v1.1`, `ARCHITECTURE_SPECIFICATION_INDEX.md v1.1`, `SPEC_BASELINE_CERTIFICATION.md v1.0`
- The full traceability matrix is recorded in Appendix D.

### E.9 Risk Assessment

- The primary residual risk is that the informative dependencies (SPEC-002, SPEC-003, SPEC-004, SPEC-005) are not yet baselined. This is acceptable while the specifications remain in Draft status.
- The `Operational` classification alignment between this document and the Index has been reconciled for Wave-01.
- No implementation, database, or operational rollout risks are introduced by this specification alone.

### E.10 Confirmation

- **No implementation performed.**
- **No repository source code modified.**
- **No database schema, data transitions, remote calls, or Edge Functions modified.**
- **No API, workflow, permissions, or business logic modified.**
- **No commit performed.**
- **No push performed.**
- **No deployment performed.**
- **No governance document modified.**
- **No existing Specification modified.**

---

*End of SPEC-006 — Observability Architecture Specification v1.1*
