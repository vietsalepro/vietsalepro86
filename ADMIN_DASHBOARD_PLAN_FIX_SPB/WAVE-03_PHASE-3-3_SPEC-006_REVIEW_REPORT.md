# WAVE-03 — PHASE 3.3: ĐÁNH GIÁ SPEC-006 (OBSERVABILITY)

| Trường | Giá trị |
|---|---|
| Prompt ID | WAVE‑03‑PHASE‑3‑3‑001 |
| Ngày | 2026-07-24 |
| Agent | Engineering Execution Agent |
| Đối tượng đánh giá | `02_Specifications/SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md` (v1.1, Draft) |
| Trạng thái | HOÀN THÀNH |
| Quyết định được ủy quyền | CTA (Chief Technical Advisor) thay mặt Production Owner |
| MCP sử dụng | codebase-memory (read-only), Supabase production (read-only — connection timeout, fallback `supabase/schema.sql` consolidated) |
| Skills sử dụng | codebase-design, doc-coauthoring, code-review, writing-plans |

---

## 1. TÓM TẮT SPEC-006 (Dành cho Production Owner)

### SPEC-006 là gì?
SPEC-006 định nghĩa **Observability Architecture** — bản thiết kế kiến trúc cho **quan sát, giám sát và ghi nhật ký** toàn hệ thống VietSalePro. Đây là **Operational specification** (không phải Core) thiết lập: correlation ID (mã liên kết), sự kiện có cấu trúc (events), logs, metrics, traces, alerts, dashboards, và chính sách lưu trữ (retention) cho toàn bộ vòng đời của delete/audit/transaction/trigger/foreign-key.

Nói cách khác: SPEC-006 là **mắt và tai của hệ thống**. Khi có sự cố (như `delete-tenant` HTTP 500 trước đây), SPEC-006 đảm bảo operator/support/compliance **có thể dựng lại toàn bộ diễn biến** — bước nào thất bại, trạng thái đã thay đổi gì, component nào phát ra lỗi — mà không cần truy cập trực tiếp production.

### Tại sao cần?
Sự cố `delete-tenant` bộc lộ 6 thiếu hụt kiến trúc (CTX-002):
1. Request không mang correlation ID nhất quán.
2. Lỗi không có cấu trúc — thiếu mã lỗi, hướng khôi phục, chủ sở hữu.
3. Vòng đời xóa không nhìn thấy được dưới dạng chuỗi bước có tên.
4. Audit/transaction/trigger/FK phát tín hiệu bằng cơ chế rời rạc, không chung taxonomy.
5. Alerting/dashboard không gắn với failure model.
6. Retention/privacy cho dữ liệu observability không được quản lý tường minh.

### SPEC-006 giải quyết vấn đề gì?
- **Correlation ID hợp nhất** (CON-002→004): mọi logical operation có 1 `correlation_id` từ entry point, lan truyền qua mọi layer kể cả async/scheduled; nếu thiếu thì sinh mới + đánh dấu `correlation_inferred`.
- **14 domain concept** (DOM-001→004): Correlation ID, Trace, Span, Event, Log Entry, Metric, Alert Rule, Dashboard, Signal, Retention Policy, Telemetry, Health/Operational/Business Signal.
- **11 component logic** (COM-001→003): Observability Emitter, Correlation Manager, Trace Collector, Log Router, Metric Aggregator, Event Catalog, Alert Manager, Dashboard Provider, Query/Analytics Engine, Retention Manager, Privacy Anonymizer.
- **5 interface trừu tượng** (INT-001→003): Signal Ingestion, Trace Span, Metric Sample, Alert Rule, Dashboard Query.
- **25 contract** (CON-001→025): correlation, event, trace/span, metric, log, alert, retention, privacy, passivity, và **5 cross-specification contract** (CON-021→025) consuming signals từ SPEC-001/002/003/004/005.
- **2 state machine** (STM-001→005): Signal lifecycle (Emitted→Captured→Enriched→Routed→Indexed→Retained→Expired) + Alert lifecycle (Armed→Evaluating→Firing→Acknowledged→Resolved).
- **10 failure mode + 10 recovery action** (FAM-001→010, RCM-001) — failure là first-class state.
- **7 risk** (RSK-001→007) với mitigation + owner.
- **Passivity cứng** (PUR-005, RES-002, CON-020, CST-002/003): observability KHÔNG sở hữu transaction, KHÔNG thay đổi business state, KHÔNG quyết định authorization — chỉ là lớp instrumentation thụ động.
- **Self-observable** (OBS-001→003): pipeline phát health signal về chính nó (ingestion, indexing, alerting).
- **Privacy by emission** (SEC-001→006, CON-019): phân loại nhạy cảm tại điểm phát, redact/tokenize trước lưu trữ dài hạn.
- **10 verification requirement** (VRF-001→010) + 9 acceptance criteria (ACC-001).
- **Traceability đầy đủ** tới Master Program (Sections 1,2,3,4,5,6,7,8,9,10.1–10.8,13,14,20,22,23,24,25,28,29).

### Điểm mạnh
- **Trung lập công nghệ** (CTX-004, CST-001, NGO-001/002): không ép collector/index/time-series/dashboard tool cụ thể — đúng chuẩn Architecture Specification Program.
- **Đầy đủ 26 section bắt buộc** (16.1–16.26) theo template governance.
- **Passivity được nhấn mạnh xuyên suốt** — 5 chỗ riêng (PUR-005, RES-002, CON-020, CST-002/003) + Architecture Decision #1. Đây là ranh giới lành mạnh với SPEC-001/002/003: observability chỉ quan sát, không can thiệp.
- **Cross-specification contracts (CON-021→025) xuất sắc**: SPEC-006 định nghĩa mình là **bên cung (provider)** ingestion/correlation/presentation contract, còn 5 SPEC kia là **bên phát (producer)** signal. Không trùng lặp trách nhiệm.
- **Correlation-first context** (Architecture Decision #2, CON-002→004): 1 ID duy nhất xuyên suốt, lan truyền cả async — đúng tinh thần Wave-02 đã triển khai.
- **Self-observing pipeline** (OBS-001, Architecture Decision #6): pipeline giám sát chính nó — tránh "blind spot khi incident".
- **Failure/Recovery model chi tiết**: 10 failure mode kèm recovery action + owner (RCM-001) — bao phủ cả edge case khó (clock skew, sampling bias, cardinality explosion, pipeline outage).
- **Future Evolution** (FEV-001/002): extension points cho domain mới, signal class mới, multi-region, long-term archive, anomaly detection — ADR bắt buộc khi thêm/xóa/reclassify event/metric.
- **3 ma trận phụ lục**: Event Classification Matrix (A), Error Taxonomy (B), Glossary (C), Traceability Summary (D).
- **Phụ thuộc đúng thứ tự acyclic**: SPEC-006 phụ thuộc bắt buộc SPEC-001 (đã Baselined 2026-07-24); optional SPEC-002. Điều kiện tiên quyết Section 34.5 đã thoả mãn.

### Điểm cần lưu ý
- SPEC-006 là **bản thiết kế mục tiêu (target)**, không phải mô tả hiện trạng. Codebase/database hiện tại **chưa tuân thủ phần lớn** (chưa có Trace Collector, Metric Aggregator, Alert Manager, Event Catalog, Dashboard Provider chính thức) — điều này **đúng kỳ vọng** vì việc xây dựng thuộc Implementation Plan (Phase 4+). Điểm đã có thật (correlation ID, audit tables, retention policy, metric reading utility) cho thấy SPEC-006 được soạn thảo có đối chiếu thực tế.
- SPEC-006 tự nêu rõ (NGO-001) không bao gồm: code, log format, storage schema, query language, dashboard tool, runbook, on-call, business analytics, transition script. Đây là ranh giới lành mạnh với Implementation Plan.
- **Index (Section 5.2/5.3) vẫn ghi SPEC-006 Status = "Planned", Version = "—" (not yet drafted)**, trong khi file SPEC-006 thực tế là "Draft v1.1". Đây là **minor inconsistency** của Index (chưa đồng bộ trạng thái Draft) — cùng dạng với G1 đã khắc phục cho SPEC-004 ở Phase 3.2. Khuyến nghị: cập nhật Index sang "Draft v1.1" khi Baseline (cùng lúc Phase 3.4).
- SPEC-006 là **SPEC phụ thuộc bắt buộc SPEC-001** (đã Baselined) — điều kiện tiên quyết Section 34.5 đã thoả mãn.

---

## 2. TÀI LIỆU ĐÃ ĐỌC

| Tài liệu | Trạng thái |
|---|---|
| `VAI_TRO_TRACH_NHIEM_VIETSALEPRO.md` | ✅ Tham chiếu (vai trò CTA ủy quyền Production Owner) |
| `NGUYEN_TAC_VIET_PROMPT_AGENT_VIETSALEPRO.md` | ✅ Tham chiếu (nguyên tắc viết prompt/agent, MCP, skills, evidence) |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/SEMANTIC_MEMORY.md` | ✅ Đọc (architecture overview, audit dual system, edge functions) |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/ROADMAP.md` | ✅ Đọc toàn bộ (Phase 1 ✅, Phase 2 ✅, Phase 3.1/3.2 ✅, Phase 3.3 ⏳) |
| `SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md` | ✅ Đọc toàn bộ (841 dòng, 26 section, v1.1 Draft) |
| `Deletion_Audit_Architecture_Remediation_Program.md` (Master Program) | ✅ Tham chiếu (vision, principles, workstreams, exit criteria) |
| `01_Governance/Architecture_Specification_Program.md` | ✅ Tham chiếu (mandatory template, dependency framework, Section 34.5) |
| `01_Governance/ARCHITECTURE_SPECIFICATION_INDEX.md` | ✅ Đọc (SPEC-006 portfolio entry, dependency matrix, acyclicity) |
| `WAVE-03_PHASE-1-1_SPEC-002_REVIEW_REPORT.md` | ✅ Tham chiếu pattern |
| `WAVE-03_PHASE-2-1_SPEC-001_REVIEW_REPORT.md` | ✅ Tham chiếu pattern |
| `WAVE-03_PHASE-3-1_SPEC-004_REVIEW_REPORT.md` | ✅ Tham chiếu pattern (đối chiếu chặt chẽ nhất — cùng dạng Index inconsistency) |
| SPEC-001 / SPEC-002 / SPEC-003 / SPEC-004 / SPEC-005 (cross-reference observability sections 16.19 + correlation_id) | ✅ Grep + đọc section 16.19 của cả 5 SPEC |

> **Lưu ý**: `.codebase-memory/CODEBASE_MEMORY_BASELINE.md`, `VALIDATION_REPORT.md`, `SEMANTIC_MEMORY.md` nằm trong thư mục `.codebase-memory/` bị ignore-file chặn đọc trực tiếp. Bản sao `SEMANTIC_MEMORY.md` tại `ADMIN_DASHBOARD_PLAN_FIX_SPB/` đã được đọc đầy đủ. Codebase Memory MCP được dùng để xác minh trực tiếp graph (28.881 nodes / 42.874 edges).

---

## 3. KẾT QUẢ XÁC MINH THỰC TẾ

### 3.1 Qua Codebase Memory MCP (read-only)

Xác minh qua `search_graph` (BM25 + name_pattern) trên project `vietsalepro` (28.881 nodes / 42.874 edges) + `grep` trực tiếp codebase.

| Hạng mục SPEC-006 | Yêu cầu | Thực tế codebase | Khớp? |
|---|---|---|---|
| **Correlation Manager** (COM-001) | Tạo/lan truyền correlation ID qua sync + async | **CÓ** — `supabase/functions/delete-tenant/index.ts:14-19` `resolveCorrelationId()` (reuse header/body hoặc mint UUID); CORS cho phép `x-correlation-id` (line 7); ghi vào `app_audit_log.new_data` (line 71); `services/tenantService.ts:732-740` forward `correlation_id` trong body + header; `tests/regression/delete-tenant-500.test.ts` test correlation; `scripts/verify-wave02.ts:39-44` verify correlation propagation | ✅ Khớp (CON-002/003/004) — Wave-02 đã triển khai |
| **Observability Emitter** (COM-001) | Emit structured events/logs/metrics/spans | **PARTIAL** — `console.log`/`console.error` trong edge functions (ad-hoc, không structured); audit writes qua `write_audit_log()`/`audit_log_trigger()`; `insertAdminEvent()` trong cron-admin-tasks. Chưa có Emitter chính thức theo Signal Ingestion Interface | ⚠️ Partial (target) |
| **Log Router** (COM-001) | Route log entries tới storage/index/archive giữ correlation context | **PARTIAL** — audit tables (`app_audit_log`, `audit_log`) + `error_logs`, `cron_job_logs`, `billing_job_logs`, `billing_reminder_logs` đóng vai trò log storage ad-hoc. Không có router chính thức | ⚠️ Partial (target) |
| **Metric Aggregator** (COM-001) | Nhận metric samples, áp dimensions, tạo time-series views | **PARTIAL** — `supabase/functions/_shared/systemHealth.ts` parse Prometheus metrics (cpu/memory/disk), `MetricSeries` interface, `findMetric`/`findMetricSum`, `buildResourceMetrics()`. Đây là **metric reading utility** (đọc từ Supabase metrics API), chưa phải Metric Aggregator đầy đủ | ⚠️ Partial (target) |
| **Trace Collector** (COM-001) | Assemble spans thành traces, giữ parent-child | **KHÔNG CÓ** | ❌ Chưa có (đúng kỳ vọng target) |
| **Event Catalog** (COM-001) | Canonical event taxonomy + schema registry | **KHÔNG CÓ** | ❌ Chưa có (target) |
| **Alert Manager** (COM-001) | Đánh giá alert rules, route alert tới owner | **PARTIAL** — `services/loginHistoryService.ts` có `FailedBurstAlert`/`NewDeviceAlert`/`RapidLoginAlert`/`AdminLoginAlert` interfaces (security alerting pattern ad-hoc). Không có Alert Manager chính thức | ⚠️ Partial (target) |
| **Dashboard Provider** (COM-001) | Dashboard read-only query telemetry by correlation_id/component/time | **PARTIAL** — admin dashboard pages (Overview, AuditLog, ErrorLogs, SystemHealth) + `get_dashboard_summary`/`get_error_log_summary` RPCs. Chưa query được theo correlation_id | ⚠️ Partial (target) |
| **Retention Manager** (COM-001) | Áp retention/privacy policy cho mỗi signal class | **CÓ (business data)** — `run_data_retention()` procedure, `get/set_data_retention_config()`, `data-retention-daily` cron job (xem 3.2). Chưa áp cho observability signals riêng | ⚠️ Partial (target — business data đã có) |
| **Privacy Anonymizer** (COM-001) | Redact/tokenize sensitive fields trước storage/export | **KHÔNG CÓ** chính thức (RLS là ranh giới security, không phải anonymizer observability) | ❌ Chưa có (target) |
| **Passivity** (CON-020, RES-002) | Observability không own transaction/modify business state | **CÓ** — correlation_id chỉ ghi vào `app_audit_log.new_data` JSONB, không thay đổi business state; `verify-wave02.ts` là read-only reconciliation checker | ✅ Khớp |
| **Self-observability** (OBS-001) | Pipeline emit health signals về chính nó | **PARTIAL** — `systemHealth.ts` + admin SystemHealth page đo cpu/memory/disk/error rates. Chưa emit `ingestion_received`/`ingestion_dropped`/`index_lag` | ⚠️ Partial (target) |

### 3.2 Qua Supabase MCP (read-only) — Production

> **Kết quả**: Supabase `execute_sql` against project `rsialbfjswnrkzcxarnj` (QLBH, ap-northeast-1, ACTIVE_HEALTHY, Postgres 17) trả về **"Connection terminated due to connection timeout"**. Đây là tình trạng đã được Prompt dự báo (Section 9) và đã gặp ở Phase 1.1/1.3/1.5/2.1/3.1.
>
> **Fallback**: Sử dụng `supabase/schema.sql` (consolidated schema phản ánh production state, build từ 147 migrations) — cùng phương pháp fallback đã dùng và cross-validated ở các phase trước.

**Logging/audit tables xác nhận tồn tại (từ `schema.sql`):**

| Table | Dòng schema.sql | Vai trò observability |
|---|---|---|
| `public.app_audit_log` | 15318, 16746, 16923 (re-defined qua migrations) | Audit log chính (tenant-scoped) — correlation_id lưu trong `new_data` JSONB |
| `public.app_audit_log_partitioned` | 17187 | Audit log partitioned (data retention) |
| `public.audit_log` | 32584 | Audit log legacy (system-level) |
| `public.error_logs` | 23535 | Error logging |
| `public.cron_job_logs` | 33429 | Cron job execution logging |
| `public.billing_job_logs` | 21198 | Billing job logging |
| `public.billing_reminder_logs` | 33458 | Billing reminder logging |

**KHÔNG có các tables observability mục tiêu (xác nhận qua grep `CREATE TABLE.*public.(trace|span|metric|telemetry|event_log)`):**
- ❌ `trace` / `span` — chưa có (Trace Collector chưa triển khai)
- ❌ `metric` / `telemetry` — chưa có (Metric Aggregator chưa triển khai)
- ❌ `event_log` — chưa có (Event Catalog chưa triển khai)
- ❌ `billing_email_logs` — không tồn tại trong schema (prompt liệt kê nhưng thực tế không có — không ảnh hưởng đánh giá SPEC-006)

**Retention policies xác nhận tồn tại (từ `schema.sql`):**

| Thành phần | Vai trò | Dòng schema.sql |
|---|---|---|
| `run_data_retention()` procedure | Chạy retention hàng ngày qua pg_cron | 11611, 18467 |
| `get_data_retention_config()` | Đọc cấu hình retention | 7257, 27528 |
| `set_data_retention_config()` | Cập nhật cấu hình retention | 12220, 27559 |
| `get_data_retention_status()` | Trạng thái retention (last run, cron) | 7281, 18278 |
| `data-retention-daily` cron job | Schedule `0 3 * * *` (03:00 hàng ngày) | 17304, 12272 |
| `data_retention_config` (system_settings) | Cấu hình: orders 730d, processed_ops 90d, rate_limit_logs 1d, fraud_queue 90d, registration_events 365d | 27079-27084 |

> **Đánh giá**: Retention policy **đã có cho business data** (orders, processed operations, rate_limit_logs, fraud_queue, registration_events) — đây là nền tảng thực tế mà SPEC-006 CON-017/018 (Retention Contract) có thể mở rộng để bao phủ observability signals. Chưa có retention riêng cho trace/span/metric (vì chưa có tables tương ứng — đúng kỳ vọng target).

### 3.3 Đối chiếu với các SPEC đã Baseline

| SPEC đã Baseline | Contract SPEC-006 tham chiếu | Contract/SPEC đối ứng | Nhất quán? |
|---|---|---|---|
| **SPEC-001 (Delete)** | CON-021 (delete-lifecycle signals theo SPEC-001 §16.19) | SPEC-001 OBS-001 (structured observability: events/logs/traces/metrics per delete request), OBS-002 (reconstruct lifecycle từ `request_id`/`correlation_id`), DOM `correlation_id` UUID propagated across all layers, CON-002 (delete request chứa `correlation_id`) | ✅ Khớp |
| **SPEC-002 (Audit)** | CON-022 (audit-write/integrity signals theo SPEC-002 §16.19) | SPEC-002 OBS-001 (structured observability per audit write), OBS-002 (reconstruct audit lifecycle từ `audit_id`/`correlation_id`), DOM `correlation_id` UUID propagated from originating request, CON-018 (idempotent replay theo `correlation_id`) | ✅ Khớp |
| **SPEC-003 (Transaction)** | CON-023 (transaction boundary/compensation signals theo SPEC-003 §16.19) | SPEC-003 OBS-001 (structured observability per transaction), OBS-002 (reconstruct transaction lifecycle từ `transaction_id`/`correlation_id`), DOM `correlation_id` propagated across layers + outbox message | ✅ Khớp |
| **SPEC-004 (Trigger)** | CON-024 (trigger execution signals theo SPEC-004 §16.19) | SPEC-004 OBS-001 (Trigger Fired/Completed/Failed events với `trigger_id`+`correlation_id`), CON-027 (mỗi trigger execution emit event chứa `correlation_id`), CON-025 (failed trigger structured error chứa `correlation_id`), DOM-004 (Trigger Run gắn `correlation_id`) | ✅ Khớp |
| **SPEC-005 (FK)** | CON-025 (relationship/integrity-failure signals theo SPEC-005 §16.19) | SPEC-005 OBS-001 (mọi relationship lifecycle event + integrity check emit structured observability), References table tham chiếu SPEC-006 "Observability instrumentation for relationship validation and policy drift" | ✅ Khớp |

> Cả 5 SPEC đã Baseline đều **chủ động tham chiếu SPEC-006** trong References table (đúng vai trò "related/dependent") và đều có **Section 16.19 Observability** định nghĩa signals mà SPEC-006 CON-021→025 consuming. Không có mâu thuẫn, không trùng lặp trách nhiệm. SPEC-006 là **bên cung (provider)** ingestion/correlation/presentation contract; 5 SPEC kia là **bên phát (producer)** signal. `correlation_id` là ID hợp nhất được cả 5 SPEC + SPEC-006 thống nhất sử dụng — **nhất quán hoàn toàn**.

---

## 4. KHOẢNG TRỐNG HOẶC MÂU THUẪN PHÁT HIỆN

| # | Phát hiện | Mức | Mô tả | Đề xuất khắc phục |
|---|---|---|---|---|
| G1 | Index chưa đồng bộ trạng thái SPEC-006 | **Minor** | `ARCHITECTURE_SPECIFICATION_INDEX.md` Section 5.2 ghi SPEC-006 Status = "Planned", Version = "—" (not yet drafted), Current Phase = "Not yet initiated"; Section 5.3 Catalog Summary ghi "Planned". Trong khi file SPEC-006 thực tế là "Draft v1.1" (Effective Date 2026-07-23). Cùng dạng inconsistency đã khắc phục cho SPEC-004 ở Phase 3.2. | Cập nhật Index Section 5.2 (Status → "Draft", Version → "1.1", Current Phase → "Drafted") + Section 5.3 (Status → "Draft") khi Baseline (Phase 3.4). Không ảnh hưởng nội dung SPEC-006. |
| G2 | Khoảng cách target vs hiện trạng (Trace Collector, Metric Aggregator, Event Catalog, Alert Manager, Privacy Anonymizer chính thức) | **Không phải khiếm khuyết** | Codebase chưa có 5/11 component chính thức. Đây là **đúng kỳ vọng** vì SPEC-006 là target architecture; việc xây dựng thuộc Implementation Plan (Phase 4+). Các nền tảng đã có (correlation ID, audit tables, retention policy, metric reading utility, security alerting pattern) cho thấy SPEC-006 được soạn thảo có đối chiếu thực tế. | Không cần sửa SPEC. Chuyển vào Implementation Plan của SPEC-006 (Phase 4) — xây dựng các component còn thiếu theo thứ tự ưu tiên (Trace Collector + Event Catalog trước, rồi Metric Aggregator + Alert Manager). |
| G3 | `billing_email_logs` không tồn tại trong schema | **Minor (prompt expectation)** | Prompt Section 4.2.2 liệt kê `billing_email_logs` như table dự kiến, nhưng grep `schema.sql` không tìm thấy. Có thể table có tên khác hoặc đã được gộp vào `billing_job_logs`. | Không ảnh hưởng SPEC-006. Ghi nhận để đối chiếu chính xác hơn ở Implementation Plan. |

> **Không phát hiện mâu thuẫn Critical hay Major.** Khoảng cách target-hiện trạng (G2) là bản chất của specification (định nghĩa đích, không phải mô tả hiện trạng). Inconsistency duy nhất cần xử lý là G1 (Index sync) — cùng cách khắc phục đã áp dụng thành công cho SPEC-004.

---

## 5. ĐÁNH GIÁ TỔNG THỂ

| Tiêu chí | Đánh giá | Ghi chú |
|----------|----------|---------|
| Phù hợp Master Program | ✅ | Traceability đầy đủ (Section D) tới Master Program Sections 1,2,3,4,5,6,7,8,9,10.1–10.8,13,14,20,22,23,24,25,28,29. Principles Mapping (PRM-001) ánh xạ 12 nguyên tắc Master Program → observability. |
| Phù hợp Specification Program | ✅ | Đầy đủ 26 section bắt buộc (16.1–16.26); metadata đúng; identifier `SPEC-006` nhất quán; classification Operational đúng; dependency framework tuân thủ Section 34 (mandatory SPEC-001, optional SPEC-002); acyclic. |
| Phù hợp thực tế codebase | ✅ | Correlation ID (CON-002/003/004) đã có thật trong delete-tenant edge + tenantService + verify-wave02 + regression test. Audit/error/billing/cron log tables có thật. Retention policy có thật. Metric reading utility (systemHealth.ts) có thật. Passivity được tôn trọng (correlation_id chỉ ghi vào JSONB, không đổi business state). |
| Phù hợp thực tế database | ✅ | 7 logging/audit tables xác nhận; retention procedure + cron + config xác nhận; không có trace/span/metric tables (đúng target); correlation_id lưu trong `app_audit_log.new_data` JSONB (ponytail: no schema change). |
| Nhất quán với SPEC-001 | ✅ | CON-021 consuming SPEC-001 §16.19 delete-lifecycle signals; cùng `correlation_id` UUID propagated; SPEC-001 References tham chiếu SPEC-006 "dependent". |
| Nhất quán với SPEC-002 | ✅ | CON-022 consuming SPEC-002 §16.19 audit-write/integrity signals; cùng `correlation_id`; SPEC-002 References tham chiếu SPEC-006 "related". |
| Nhất quán với SPEC-003 | ✅ | CON-023 consuming SPEC-003 §16.19 transaction boundary/compensation signals; cùng `correlation_id` (kể cả outbox); SPEC-003 References tham chiếu SPEC-006 "related". |
| Nhất quán với SPEC-004 | ✅ | CON-024 consuming SPEC-004 §16.19 trigger execution signals; cùng `trigger_id`+`correlation_id`; SPEC-004 References tham chiếu SPEC-006 "related". |
| Nhất quán với SPEC-005 | ✅ | CON-025 consuming SPEC-005 §16.19 relationship/integrity-failure signals; SPEC-005 References tham chiếu SPEC-006 "related". |
| Rủi ro nếu Baseline | **Thấp** | SPEC-006 là target architecture, không thay đổi code/schema. Khoảng cách target-hiện trạng thuộc Implementation Plan. Rủi ro duy nhất là Index inconsistency (G1) — đã có tiền lệ khắc phục (SPEC-004 Phase 3.2). |

---

## 6. KHUYẾN NGHỊ

### ☑ APPROVE WITH MINOR CHANGES

SPEC-006 **có thể được Baseline** sau khi áp dụng 1 thay đổi nhỏ (G1 — đồng bộ Index).

**Lý do khuyến nghị:**
1. SPEC-006 là specification chất lượng cao, đầy đủ 26 section bắt buộc, trung lập công nghệ, passivity được nhấn mạnh xuyên suốt.
2. Cross-specification contracts (CON-021→025) consuming signals từ cả 5 SPEC đã Baselined — nhất quán hoàn toàn, không trùng lặp trách nhiệm.
3. Đối chiếu thực tế cho thấy SPEC-006 được soạn thảo có đối chiếu codebase: correlation ID (Wave-02), audit tables, retention policy, metric reading utility đều có thật và khớp với contracts.
4. Khoảng cách target-hiện trạng (Trace Collector, Metric Aggregator, Event Catalog, Alert Manager, Privacy Anonymizer) là bản chất của specification — thuộc Implementation Plan (Phase 4+), không phải khiếm khuyết của SPEC.
5. Inconsistency duy nhất (G1 — Index ghi "Planned" thay vì "Draft v1.1") là vấn đề của Index, không phải của SPEC-006, và đã có tiền lệ khắc phục thành công cho SPEC-004 ở Phase 3.2.

### Kế hoạch Baseline SPEC-006 (Phase 3.4)

1. **CTA (ủy quyền Production Owner)** xem xét báo cáo này.
2. Nếu đồng ý, CTA ký Baseline SPEC-006:
   - Đổi Status SPEC-006: `Draft` → `Baselined`, Version giữ `1.1`, Baseline Date `2026-07-24`.
   - Cập nhật `ARCHITECTURE_SPECIFICATION_INDEX.md` Section 5.2 (SPEC-006: Status → "Baselined", Version → "1.1", Baseline Date → "2026-07-24", Current Phase → "Baselined") + Section 5.3 (Status → "Baselined") + Section 6.2/dependency matrix (đã đúng, không đổi).
   - Cập nhật `ROADMAP.md` Phase 3.4 → ✅ HOÀN THÀNH.
3. Sau Phase 3.4, chỉ còn **SPEC-007 (Regression & Verification)** để hoàn thành toàn bộ 7 SPEC.

---

## 7. BÁO CÁO CHO PRODUCTION OWNER (Một trang, không kỹ thuật)

**SPEC-006 là gì?**
SPEC-006 là bản thiết kế cho **hệ thống "mắt và tai"** của VietSalePro — giúp biết chính xác chuyện gì đang xảy ra trong hệ thống, khi có sự cố thì dựng lại toàn bộ diễn biến, và giám sát sức khỏe hệ thống liên tục.

**Tại sao cần?**
Khi sự cố `delete-tenant` HTTP 500 xảy ra, không ai dựng lại được bước nào thất bại, trạng thái đã đổi gì, component nào lỗi — vì không có mã liên kết (correlation ID) chung, lỗi không có cấu trúc, không có dashboard/alert gắn với mô hình lỗi. SPEC-006 giải quyết triệt để 6 thiếu hụt này.

**Nó giải quyết gì?**
- Mọi request có 1 mã liên kết (correlation ID) duy nhất, lan truyền từ đầu đến cuối — kể cả tác vụ nền.
- Mọi thao tác quan trọng (xóa, audit, transaction, trigger, kiểm tra khóa ngoại) phát tín hiệu có cấu trúc, gộp về một taxonomy chung.
- Lỗi có mã, có hướng khôi phục, có chủ sở hữu.
- Có dashboard, alert, retention, privacy cho dữ liệu quan sát.
- **Quan trọng**: hệ thống quan sát chỉ "nhìn", không "làm" — không thay đổi dữ liệu business, không sở hữu transaction.

**Đối chiếu thực tế ra sao?**
- ✅ **Đã có thật**: correlation ID (Wave-02 đã thêm vào delete-tenant), bảng audit/error/billing/cron log, chính sách retention hàng ngày, tiện ích đọc metric.
- ⚠️ **Chưa có (đúng kỳ vọng)**: Trace Collector, Metric Aggregator, Event Catalog, Alert Manager chính thức — đây là bộ phận sẽ xây ở giai đoạn Implementation Plan (Phase 4+), không phải lỗi của bản thiết kế.
- ✅ **Nhất quán hoàn toàn** với 5 bản thiết kế đã phê duyệt (SPEC-001/002/003/004/005) — cả 5 đều có section observability riêng mà SPEC-006 gộp về một kiến trúc chung.

**Có rủi ro không?**
Rủi ro **thấp**. Bản thiết kế là kiến trúc mục tiêu, không thay đổi code/schema ngay. Điểm duy nhất cần sửa là Index ghi sai trạng thái ("Planned" thay vì "Draft v1.1") — cùng lỗi đã sửa thành công cho SPEC-004 trước đây.

**Đề xuất quyết định:**
**NÊN PHÊ DUYỆT (Baseline)** SPEC-006, kèm 1 sửa nhỏ trên Index (đồng bộ trạng thái). Sau khi phê duyệt, chỉ còn SPEC-007 (Regression & Verification) để hoàn thành toàn bộ 7 bản thiết kế kiến trúc.

---

## 8. LƯU Ý QUAN TRỌNG

- SPEC-006 là **SPEC Operational** — định nghĩa cách quan sát và giám sát hệ thống, là "mắt và tai" cho mọi SPEC khác.
- SPEC-006 tương tác với **tất cả 5 SPEC đã Baselined** qua CON-021→025 (cross-specification contracts) — mỗi SPEC có section Observability riêng, SPEC-006 thống nhất chúng.
- **Wave-02 đã thêm correlation ID vào codebase** (`delete-tenant` edge + `tenantService` + `verify-wave02` + regression test) — xác nhận tính thực tế của SPEC-006 CON-002/003/004.
- Sau khi SPEC-006 được Baseline, chỉ còn **SPEC-007 (Regression & Verification)** để hoàn thành toàn bộ 7 SPEC.
- Supabase `execute_sql` timeout là tình trạng đã biết (gặp ở mọi phase trước) — fallback `schema.sql` đã cross-validated và cho kết quả nhất quán.

---

## 9. BẰNG CHỨNG

| Tài liệu | Bằng chứng |
|---|---|
| `WAVE-03_PHASE-3-3_SPEC-006_REVIEW_REPORT.md` | Báo cáo đánh giá đầy đủ SPEC-006 (file này) |
| `ROADMAP.md` | Cập nhật trạng thái 3.3 → ✅ HOÀN THÀNH, 3.4 → ⏳ ĐANG CHỜ PHÊ DUYỆT |
| Codebase Memory MCP | `search_graph` trên 28.881 nodes — xác nhận correlation_id, audit/logging functions, metric utility |
| Supabase MCP | `list_projects` (project `rsialbfjswnrkzcxarnj` ACTIVE_HEALTHY); `execute_sql` timeout → fallback `schema.sql` |
| `supabase/schema.sql` | 7 logging/audit tables + retention procedure/cron/config xác nhận |
| `supabase/functions/delete-tenant/index.ts` | `resolveCorrelationId()` (line 14-19), CORS `x-correlation-id` (line 7), ghi `correlation_id` vào `app_audit_log.new_data` (line 71) |
| `services/tenantService.ts` | Forward `correlation_id` body + `x-correlation-id` header (line 732-740) |
| `scripts/verify-wave02.ts` | Verify correlation propagation (line 39-44) |
| `supabase/functions/_shared/systemHealth.ts` | Metric reading utility (Prometheus parse, MetricSeries, cpu/memory/disk) |
| SPEC-001..005 §16.19 | Cả 5 SPEC có Observability section + reference SPEC-006 + dùng `correlation_id` |
