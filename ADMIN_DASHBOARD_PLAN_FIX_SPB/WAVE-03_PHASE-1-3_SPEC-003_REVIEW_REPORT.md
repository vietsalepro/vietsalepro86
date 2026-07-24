# WAVE-03 — PHASE 1.3: ĐÁNH GIÁ SPEC-003 (Transaction Architecture)

| Trường | Giá trị |
|---|---|
| Prompt ID | WAVE‑03‑PHASE‑1‑3‑001 |
| Ngày | 2026-07-24 |
| Agent | Engineering Execution Agent |
| Đối tượng đánh giá | `02_Specifications/SPEC-003_TRANSACTION_ARCHITECTURE_SPECIFICATION.md` (v1.0, Draft, Effective 2026-07-23) |
| Trạng thái | HOÀN THÀNH |
| Quyết định được ủy quyền | CTA (Chief Technical Advisor) thay mặt Production Owner |
| MCP sử dụng | codebase-memory (read-only), Supabase production `rsialbfjswnrkzcxarnj` (read-only) |
| Skills sử dụng | codebase-design, doc-coauthoring, code-review, writing-plans |

---

## 1. TÓM TẮT SPEC-003 (Dành cho Production Owner)

### SPEC-003 là gì?
SPEC-003 định nghĩa **Kiến trúc Giao dịch (Transaction Architecture)** toàn hệ thống của VietSalePro. Đây là bản thiết kế nền tảng quy định cách tổ chức một thao tác nghiệp vụ nhiều bước sao cho: hoặc thành công toàn bộ, hoặc không để lại trạng thái nửa vờn (atomic); ai là chủ sở hữu duy nhất của giao dịch (transaction owner); và cách xử lý các "tác dụng phụ" bên ngoài database (xóa file storage, gọi billing, dọn auth) sao cho an toàn, có thể khôi phục.

### Tại sao cần?
Sự cố `delete-tenant` HTTP 500 cho thấy lỗi cốt lõi: không có một "người chủ" duy nhất cho giao dịch xóa tenant. Việc xóa bị chia nhỏ qua nhiều lớp (Edge Function, service, trigger, FK cascade). Trigger cố ghi audit trong cùng giao dịch đang xóa → vi phạm khóa ngoại → toàn bộ giao dịch bị hủy → lỗi 500. Không có cơ chế tách "thay đổi dữ liệu" khỏi "tác dụng phụ bên ngoài", nên khi một bước hỏng thì không biết rollback hay bù đắp (compensate) ở đâu.

### SPEC-003 giải quyết vấn đề gì?
- **Transaction Coordinator duy nhất** — một component duy nhất quyết định commit/rollback cho mỗi giao dịch.
- **Outbox Pattern** — tác dụng phụ bên ngoài được ghi thành "thông điệp" trong cùng giao dịch, chỉ gửi đi sau khi giao dịch đã commit → không còn "tác dụng phụ mồ côi".
- **Compensation & Saga** — khi tác dụng phụ hỏng sau commit, có cơ chế bù đắp idempotent; thao tác dài được chia thành saga.
- **Idempotency & Retry** — mỗi yêu cầu mang `idempotency_key`; replay không nhân đôi; retry có backoff có giới hạn.
- **State Machine** — vòng đời giao dịch được mô hình hóa: RECEIVED → VALIDATED → OPEN → EXECUTING → COMMITTING → COMMITTED → SIDE_EFFECTS_DISPATCHING → COMPLETED (và nhánh FAILING/ROLLING_BACK/COMPENSATING/ESCALATED).
- **Tách audit khỏi trigger** — audit có thể ghi trong hoặc ngoài giao dịch theo SPEC-002, trigger chỉ giữ invariant cấp thấp.

### Điểm mạnh
- Mô hình miền rõ ràng: Transaction Request, Transaction Boundary, Transaction Coordinator, Participant, Outbox, Outbox Processor, Side-Effect Handler, Compensation Action, Saga Step, Recovery Record, Transaction State.
- Đầy đủ 26 section bắt buộc (16.1–16.26) theo Architecture Specification Program: Purpose, Scope, References, Context, Responsibilities, Principles Mapping, Domain Model, Components, Interfaces, Contracts (CON-001→033), State Machine, Workflow, Sequence, Data Model, Failure Model (FAM-001→013), Recovery Model (RCM-001→005), Security (SEC-001→007), Observability, Risks (RSK-001→008), Constraints (CST-001→007), Non-goals, Verification (VRF-001→010), Acceptance (ACC-001), Future Evolution, Appendix.
- Ngôn ngữ trung lập công nghệ — không bắt buộc engine, table name, column type, runtime (PUR-005, SCO-004, CST-001). Phù hợp "RPC-as-coordinator" hiện tại và mở đường cho workflow engine sau này.
- Traceability đầy đủ tới Master Program (Sections 1,2,3,7,8,9,10,15,17,22,23,24,28) và SPEC-001 (CON-006/007, VRF-003/004), SPEC-002, SPEC-005.
- Chẩn đoán kiến trúc (CTX-001→005) khớp chính xác với thực tế codebase/database (xác minh qua MCP — xem Mục 3).

### Điểm cần lưu ý
- SPEC-003 nêu rõ nó KHÔNG bao gồm migration, code, schema cụ thể (SCO-004, NGO-001→007). Các chi tiết đó thuộc Implementation Plan.
- Hệ thống hiện tại **chưa tuân thủ** kiến trúc mục tiêu: chưa có outbox tổng quát, chưa có saga/compensation, tenant deletion vẫn trigger-driven, chưa có idempotency_key ở mức giao dịch. Đây là dự kiến vì SPEC-003 chỉ là thiết kế; việc remediation sẽ do Implementation Plan thực hiện.
- `ARCHITECTURE_SPECIFICATION_INDEX.md` vẫn ghi SPEC-003 là "Planned / Not yet initiated / Version —" trong khi file SPEC đã là Draft v1.0 — cần đồng bộ Index khi Baseline (xem GAP-006).

---

## 2. TÀI LIỆU ĐÃ ĐỌC

| Tài liệu | Trạng thái |
|---|---|
| `VAI_TRO_TRACH_NHIEM_VIETSALEPRO.md` | ✅ Đọc |
| `NGUYEN_TAC_VIET_PROMPT_AGENT_VIETSALEPRO.md` | ✅ Đọc |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_BASELINE.md` | ✅ Đọc |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/SEMANTIC_MEMORY.md` | ✅ Đọc (phần transaction/RPC/atomicity, §3.2, §5) |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/VALIDATION_REPORT.md` | ✅ Đọc (xác nhận "RPCs for atomicity (SECURITY DEFINER) ✓") |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/ROADMAP.md` | ✅ Đọc |
| `02_Specifications/SPEC-003_TRANSACTION_ARCHITECTURE_SPECIFICATION.md` | ✅ Đọc toàn bộ (910 dòng) |
| `02_Specifications/SPEC-001_DELETE_FRAMEWORK_ARCHITECTURE_SPECIFICATION.md` | ✅ Đọc phần liên quan (CON-006/007/008, VRF-003/004, CST-002, RSK-003) |
| `02_Specifications/SPEC-005_FOREIGN_KEY_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` | ✅ Đọc phần liên quan (PUR-003, REF, CST-002, cross-spec consistency) |
| `Deletion_Audit_Architecture_Remediation_Program.md` (Master Program) | ✅ Đọc Section 10 (transaction workstream), Guiding Principles 3, 4, 7 |
| `01_Governance/Architecture_Specification_Program.md` | ✅ Đọc tóm tắt (template 26 section, technology neutrality §18) |
| `01_Governance/ARCHITECTURE_SPECIFICATION_INDEX.md` | ✅ Đọc entry SPEC-003 (§5.3), dependency matrix §6.2, acyclicity §6.3 |
| `WAVE-03_PHASE-1-1_SPEC-002_REVIEW_REPORT.md` | ✅ Đọc (tham chiếu pattern đánh giá đã thiết lập) |

---

## 3. KẾT QUẢ XÁC MINH THỰC TẾ

### 3.1 Codebase (qua Codebase Memory MCP — `search_graph`)

| Hạng mục | SPEC-003 yêu cầu | Thực tế codebase | Khớp? |
|---|---|---|---|
| Transaction Coordinator (single owner) | Một `Transaction Coordinator` duy nhất sở hữu boundary (CON-002, DOM-003, RES-003) | Các RPC `SECURITY DEFINER` đóng vai trò coordinator de-facto: `process_checkout`, `process_checkout_tenant`, `create_exchange_transaction`, `delete_order`, `delete_import_v2`, `delete_inventory_count_rpc`, `gdpr_delete_user_data`. Service callers: `createOrder`, `createImportReceipt`, `createExchangeTransaction` trong `services/supabaseService.ts`. | ⚠️ Một phần — coordinator tồn tại dạng RPC nhưng không thống nhất toàn hệ thống, không có participant registry/state manager tách bạch. |
| Outbox Writer / Outbox | Durable queue ghi trong boundary, dispatch sau commit (CON-011/012/013, DOM-004, DAT-004) | KHÔNG có bảng outbox tổng quát. Có `webhook_deliveries` (xem §3.2) — outbox theo miền webhook. Không có Outbox Writer/Processor tổng quát. | ❌ Không có (trừ webhook) |
| Side-Effect Handler | Handler idempotent cho storage/auth/billing/notification (RES-001, CON-014) | `billing-webhooks` Edge Function (Stripe/Momo/VNPay/BankTransfer); webhook delivery với retry (`retry_webhook_delivery`, `mark_webhook_delivery`, `webhook_retry_schedule`). Storage cleanup / auth cleanup chưa thấy wrapper idempotent tách bạch. | ⚠️ Một phần — billing webhook có; storage/auth chưa rõ |
| Compensation Manager | Compensating action idempotent, reverse order (CON-014/015/016, RCM-003) | Không phát hiện compensation manager hay compensation log. | ❌ Không có |
| Saga / long-running | Saga steps với local transaction + backward recovery (CON-017/018/019) | Không phát hiện saga orchestrator hay saga step table. | ❌ Không có |
| Idempotency | `idempotency_key` trên transaction request (CON-020/021/022, SEC-005) | `idempotency_key` tồn tại trên `webhook_deliveries` (xem §3.2). Không có idempotency_key ở mức transaction request tổng quát. | ⚠️ Một phần (webhook only) |
| Retry Manager | Bounded retry + backoff + deadline (CON-023/024/025, RCM-005) | `webhook_deliveries` có `attempt_count`, `max_attempts`, `next_retry_at`, `attempt_log` → retry có backoff cho webhook. Không có retry manager tổng quát. | ⚠️ Một phần (webhook only) |
| `_legacy*` fallback | SPEC-003 yêu cầu single owner/atomicity (CON-002) | `supabaseService.ts` có `_legacy*` fallbacks cho checkout/deleteOrder/createReturnOrder — **non-atomic**, dùng nếu migration chưa apply (SEMANTIC_MEMORY §3.1, §6.1). Vi phạm ngầm single-owner. | ❌ Vi phạm (cần retire) |
| State Manager | Mỗi transition ghi prev/new state/actor/timestamp/reason (COM-004, STM-003, DAT) | Không phát hiện transaction state table hay state transition log. | ❌ Không có |

### 3.2 Database production (qua Supabase MCP, read-only)

Project: `QLBH` (`rsialbfjswnrkzcxarnj`), Postgres 17.6.1.

**Bảng transaction-related (truy vấn `information_schema.tables`):**

| Bảng | Tồn tại? | Ghi chú |
|---|---|---|
| `outbox` | ❌ Không | — |
| `transaction_state` / `delete_state` | ❌ Không | Khớp ROADMAP §4 (deferred) |
| `saga*` / `compensation*` / `retry_schedule` / `recovery_record` | ❌ Không | — |
| `webhook_deliveries` | ✅ Có | Outbox-like theo miền webhook |
| `tenant_webhooks` | ✅ Có | Cấu hình webhook của tenant |

**Cấu trúc `webhook_deliveries`** (xác minh `information_schema.columns`): `id, webhook_id, tenant_id, event_type, payload(jsonb), idempotency_key, status, http_status, response_body, error_message, attempt_count, max_attempts, attempted_at, delivered_at, next_retry_at, attempt_log(jsonb), created_at, updated_at`.
→ Đây là **outbox + idempotency + retry + backoff** thực sự, nhưng **giới hạn trong miền webhook**, không phải outbox tổng quát cho mọi side-effect (storage/auth/billing provider).

**RPC `SECURITY DEFINER` liên quan transaction** (truy vấn `pg_proc` WHERE `prosecdef=true`):

| RPC | SECURITY DEFINER? | Vai trò |
|---|---|---|
| `process_checkout` | ✅ | Coordinator checkout (atomic: order + items + stock + points + ledger) |
| `process_checkout_tenant` | ✅ | Coordinator checkout tenant-scoped |
| `create_exchange_transaction` | ✅ | Coordinator return/exchange (atomic: return + new order + stock + debt + ledger) |
| `delete_order` | ✅ | Coordinator xóa order |
| `delete_import_v2` | ✅ | Coordinator xóa import receipt |
| `delete_inventory_count_rpc` | ✅ | Coordinator xóa inventory count |
| `gdpr_delete_user_data` | ✅ | Coordinator GDPR delete |
| `delete_admin_role` | ✅ | Coordinator xóa admin role |
| `trg_tenants_before_delete` | ✅ (trigger fn) | Guardrail BEFORE DELETE trên `tenants` |
| `delete_tenant_safe` | ❌ **SECURITY INVOKER** | Chỉ soft-archive (status='archived'), kiểm `is_system_admin()` bên trong |

**Trigger trên bảng `tenants`** (truy vấn `pg_trigger`):

| Trigger | Sự kiện | Hàm | Ý nghĩa kiến trúc |
|---|---|---|---|
| `tenants_before_delete_guardrail` | BEFORE DELETE | `trg_tenants_before_delete()` (SECURITY DEFINER) | Đặt flag `app.hard_delete_tenant='true'` rồi trả OLD — hard-delete vẫn dựa vào trigger + FK cascade |
| `trg_audit_log_tenants` | AFTER INSERT/DELETE/UPDATE | `audit_log_trigger()` | Ghi audit **trong trigger** — đúng pattern SPEC-003 CTX-002 phê phán (audit-in-trigger) |
| `tenant_registration_event_trigger` | AFTER INSERT | `insert_tenant_registration_event()` | Side-effect event trong trigger |
| `set_tenant_record_user_tracking` | BEFORE INSERT/UPDATE | `set_tenant_record_user_tracking()` | Tracking invariant — hợp lệ (low-level) |

**Định nghĩa `delete_tenant_safe`** (xác minh `pg_get_functiondef`):
```sql
-- SECURITY INVOKER; chỉ UPDATE status='archived', không xóa cứng, không outbox, không side-effect coordination
UPDATE public.tenants SET status='archived', archived_at=now(), updated_at=now()
WHERE id=p_tenant_id RETURNING * INTO v_tenant;
```
→ Đây là **soft-archive**, không phải transaction coordinator cho hard-delete. Hard-delete vẫn đi qua `DELETE tenants` → BEFORE DELETE trigger → FK cascade → AFTER DELETE audit trigger.

**Kết luận §3.2:** Thực tế database **không có** hạ tầng transaction architecture tổng quát (outbox/saga/compensation/state). Có pattern RPC-as-coordinator cho các nghiệp vụ POS (checkout/exchange/import/order) và outbox-like cục bộ cho webhook. Tenant hard-delete vẫn trigger-driven + audit-in-trigger — đúng chẩn đoán SPEC-003 CTX-002.

### 3.3 Đối chiếu với SPEC-001, SPEC-002, SPEC-005

| Mối quan hệ | Đối chiếu | Kết quả |
|---|---|---|
| SPEC-001 CON-006 | "Database layer owns exactly one atomic transaction per delete request" | ✅ Nhất quán — SPEC-003 CON-002/003/004 định nghĩa Transaction Coordinator sở hữu boundary |
| SPEC-001 CON-007 | "Transaction commits only when all invariants/constraints/row deletions succeed" | ✅ Nhất quán — SPEC-003 CON-008 (commit sau tất cả participant + outbox) |
| SPEC-001 CON-008 | "Rollback hoàn toàn nếu invariant fail" | ✅ Nhất quán — SPEC-003 CON-009/010, RCM-002 (prefer rollback khi chưa commit) |
| SPEC-001 VRF-003 | "Rollback restores pre-delete state" | ✅ Nhất quán — SPEC-003 VRF-003 (failure-injection tests) |
| SPEC-001 VRF-004 | "Side-effect handlers idempotent" | ✅ Nhất quán — SPEC-003 VRF-005/006/007, CON-022 |
| SPEC-001 CST-002 | "Phụ thuộc SPEC-002, SPEC-003, SPEC-005 baselined trước" | ✅ Nhất quán — Index §6.2/§6.3, dependency graph acyclic |
| SPEC-001 RSK-003 | "Transaction giữ lock quá lâu" → batch sizing/timeout per SPEC-003 | ✅ Nhất quán — SPEC-003 RSK-002, CON-026/027, CST-007 |
| SPEC-002 (audit) | Audit-before/after-commit qua outbox, audit độc lập | ✅ Nhất quán — SPEC-003 CON-031, INT-004, DAT-003, RSK-008 |
| SPEC-005 PUR-003 | "Transaction-boundary enforcement cho RI" | ✅ Nhất quán — SPEC-005 §775 "Transaction boundary ownership remains with Transaction Coordinator; no transaction duplication" |
| SPEC-005 CST-002 | "Phụ thuộc SPEC-001, SPEC-002, SPEC-003 baselined" | ✅ Nhất quán |
| Master Program §10 | Transaction workstream: atomicity, single owner, outbox, compensatable side-effects | ✅ Nhất quán — SPEC-003 PRM-001 mapping đầy đủ 12 nguyên tắc |
| Master Program Guiding Principle 3 | "Không business workflow logic trong trigger" | ✅ Nhất quán — SPEC-003 RES-002, CON-032, CST-002 |

---

## 4. KHOẢNG TRỐNG / MÂU THUẪN PHÁT HIỆN

| ID | Phát hiện | Mức độ | Đề xuất khắc phục |
|---|---|---|---|
| GAP-001 | **Không có outbox/saga/compensation/state tổng quát.** Chỉ `webhook_deliveries` là outbox-like cục bộ. Vi phạm CON-011→013, CON-017→019, COM-004, DAT-002. | Critical | Implementation Plan: thiết kế outbox table tổng quát, outbox processor, compensation log, retry schedule, transaction state table. Bắt đầu với delete pipeline (SPEC-001) rồi mở rộng. |
| GAP-002 | **Tenant hard-delete vẫn trigger-driven.** `trg_tenants_before_delete` (BEFORE DELETE) + FK cascade + `trg_audit_log_tenants` (AFTER DELETE audit-in-trigger). `delete_tenant_safe` chỉ soft-archive (SECURITY INVOKER). Vi phạm CTX-002, CON-031/032, RES-002, CST-002. | Critical | Implementation Plan SPEC-001: thay hard-delete bằng RPC coordinator tường minh (`delete_tenant_canonical` — đã deferred trong ROADMAP §4), di chuyển audit ra khỏi trigger (theo SPEC-002), FK cascade → coordinator-orchestrated. |
| GAP-003 | **`delete_tenant_safe` là SECURITY INVOKER**, không SECURITY DEFINER. Dựa `is_system_admin()` bên trong nhưng không sở hữu privileged boundary nhất quán với các coordinator khác. | Major | Implementation Plan: đưa lên SECURITY DEFINER với `search_path` lock, hoặc thay bằng coordinator mới; đảm bảo single-owner privileged. |
| GAP-004 | **Không có `idempotency_key` ở mức transaction request.** Chỉ có trên `webhook_deliveries`. Vi phạm CON-020/021, SEC-005, VRF-007. | Major | Implementation Plan: thêm idempotency_key vào transaction request interface và bảng transaction state; dedup ở coordinator. |
| GAP-005 | **Audit vẫn ghi trong AFTER DELETE trigger** (`trg_audit_log_tenants`). Vi phạm SPEC-003 CON-031/032, RSK-008 và SPEC-002 (audit independence). | Major | Implementation Plan SPEC-002: chuyển audit sang Audit Writer tường minh (Edge Function/RPC/service), trigger chỉ giữ invariant cấp thấp. |
| GAP-006 | **Index staleness.** `ARCHITECTURE_SPECIFICATION_INDEX.md` §5.3 vẫn ghi SPEC-003 "Planned / Not yet initiated / Version — (not yet drafted)" trong khi file SPEC là Draft v1.0 (Effective 2026-07-23). | Minor | Khi Baseline: cập nhật Index §5.3 → Status "Baselined", Version 1.0, Owner CTA, Current Phase "Baselined". Đồng bộ dependency matrix. |
| GAP-007 | **`_legacy*` non-atomic fallbacks** trong `supabaseService.ts` (checkout/deleteOrder/createReturnOrder). Vi phạm ngầm single-owner/atomicity (CON-002/004). | Minor | Implementation Plan: retire `_legacy*` sau khi toàn bộ migration đã apply; giữ single canonical path. |

**Phân loại tổng quan:**
- 2 Critical, 3 Major, 2 Minor.
- **Tất cả gaps đều nằm ở thực thi hiện tại, KHÔNG phải lỗi logic của SPEC-003.** SPEC-003 chính là khuôn khổ để khắc phục các gap này.

---

## 5. ĐÁNH GIÁ TỔNG THỂ

| Tiêu chí | Đánh giá | Ghi chú |
|---|---|---|
| Phù hợp Master Program | ✅ | 12 nguyên tắc (PRM-001) mapping đầy đủ; Section 10 transaction workstream; Guiding Principles 3, 4, 7; Section 28 failure/recovery. |
| Phù hợp Architecture Specification Program | ✅ | Đầy đủ 26 section (16.1–16.26), identifier `SPEC-003-XXX-NNN`, metadata, traceability, evidence E.1–E.5, technology neutrality (CST-001 ↔ Program §18). |
| Phù hợp thực tế codebase | ✅ | RPC-as-coordinator (checkout/exchange/import/order) là realization hiện tại khớp CTX-005; chẩn đoán CTX-001→004 khớp SEMANTIC_MEMORY §3.1/§6.1 (RPC atomicity + `_legacy*` non-atomic). |
| Phù hợp thực tế database | ❌ | DB production chưa có outbox/saga/compensation/state tổng quát; tenant hard-delete vẫn trigger-driven + audit-in-trigger. Đây là điểm cần remediation — dự kiến vì SPEC chỉ là thiết kế. |
| Nhất quán với SPEC-001 | ✅ | CON-006/007/008, VRF-003/004, CST-002, RSK-003 tham chiếu đúng SPEC-003. |
| Nhất quán với SPEC-002 | ✅ | Audit interaction (CON-031, INT-004, DAT-003, RSK-008) nhất quán; không trùng lặp nội dung audit. |
| Nhất quán với SPEC-005 | ✅ | Transaction boundary ownership không trùng lặp (SPEC-005 §775); RI trong boundary (CON-033, CST). |
| Rủi ro nếu Baseline | Trung bình | Spec tốt, neutral; Implementation Plan sẽ phải xây dựng nhiều hạ tầng mới (outbox, state, compensation) và refactor tenant deletion — khối lượng lớn nhưng đúng hướng. |

---

## 6. KHUYẾN NGHỊ

- ✅ **APPROVE — SPEC-003 có thể được Baseline ngay.**

### Lý do
1. SPEC-003 là bản thiết kế kiến trúc hợp lệ, đầy đủ 26 section, trung lập công nghệ, không mâu thuẫn nội tại.
2. Chẩn đoán kiến trúc (CTX-001→005) được xác minh khớp thực tế qua Codebase Memory MCP và Supabase MCP: tenant hard-delete trigger-driven, audit-in-trigger, không có outbox tổng quát — đúng vấn đề spec giải quyết.
3. Nhất quán với Master Program, Architecture Specification Program, và SPEC-001/002/005 (tất cả cross-reference đúng hướng, dependency graph acyclic).
4. Các gap phát hiện (GAP-001→007) đều ở **hiện thực hiện tại**, không phải lỗi thiết kế. Baseline SPEC-003 tạo cơ sở pháp lý để Implementation Plan khắc phục gap theo đúng hướng.
5. SPEC-001 đang chờ SPEC-003 baseline (CST-002) — trì hoãn sẽ chặn toàn bộ Wave-03 Phase 2.

### Kế hoạch đề xuất sau khi Baseline
1. CTA ký Baseline SPEC-003 (theo ủy quyền Production Owner).
2. Cập nhật `ARCHITECTURE_SPECIFICATION_INDEX.md` §5.3: Status → "Baselined", Version → 1.0, Owner → CTA, Current Phase → "Baselined" (khắc phục GAP-006).
3. Cập nhật `ROADMAP.md`: 1.3 → ✅ HOÀN THÀNH, 1.4 → ⏳ ĐANG CHỜ PHÊ DUYỆT (sẵn sàng ký).
4. Chuyển sang Phase 1.5 — đánh giá SPEC-005 (Foreign Key Governance) — foundation spec cuối cùng.
5. Sau khi 3 foundation spec (002/003/005) baselined → Phase 2 đánh giá SPEC-001.
6. Implementation Plan cho SPEC-003 nên ưu tiên: (a) outbox table tổng quát + outbox processor; (b) `delete_tenant_canonical` RPC coordinator thay trigger-driven hard-delete; (c) di chuyển audit ra khỏi trigger; (d) retire `_legacy*`; (e) idempotency_key ở transaction request.

---

## 7. BÁO CÁO CHO PRODUCTION OWNER (Tóm tắt không kỹ thuật)

**Chủ đề:** Đánh giá bản thiết kế kiến trúc giao dịch (SPEC-003 — Transaction Architecture).

**Tình hình:**
- SPEC-003 đã soạn thảo đầy đủ, đúng chuẩn governance (26 mục bắt buộc, ngôn ngữ trung lập công nghệ).
- Bản thiết kế nêu rõ: mỗi thao tác nhiều bước phải có một "người chủ" duy nhất (transaction coordinator); các tác dụng phụ bên ngoài database (xóa file, gọi billing, dọn auth) phải được ghi thành "thông điệp chờ" (outbox) trong cùng giao dịch và chỉ gửi sau khi giao dịch đã chốt; khi hỏng có cơ chế bù đắp (compensation) và thử lại idempotent; thao tác dài chia thành saga.
- Kiểm chứng thực tế (đọc code + đọc database production) cho thấy hệ thống **hiện tại** chưa đáp ứng: chưa có outbox tổng quát (chỉ có outbox cho webhook), tenant xóa cứng vẫn dựa vào trigger và ghi audit trong trigger (đúng nguyên nhân sự cố delete-tenant HTTP 500), chưa có idempotency/compensation/saga. Đây là điều dự kiến vì SPEC-003 chỉ là bản thiết kế; việc sửa code/schema sẽ làm sau qua Implementation Plan.

**Khuyến nghị:**
- Phê duyệt SPEC-003 thành **Baseline** (bản thiết kế chuẩn). CTA sẽ ký thay mặt Production Owner theo ủy quyền.
- Sau đó, team lập Implementation Plan để: xây outbox tổng quát, thay xóa tenant cứng bằng coordinator tường minh, di chuyển audit ra khỏi trigger, retire code legacy non-atomic.

**Rủi ro nếu không phê duyệt:**
- Chậm tiến độ Wave-03. SPEC-001 (Delete Framework) không có nền tảng giao dịch để dựa vào → không thể baseline → toàn bộ Phase 2/3 bị chặn.

**Rủi ro nếu phê duyệt mà không có Implementation Plan rõ ràng:**
- Trigger-driven tenant deletion + audit-in-trigger có thể tiếp tục gây lỗi khi xóa tenant/user. Cần đảm bảo Implementation Plan được lập và phê duyệt trước khi can thiệp production.

---

## 8. BẰNG CHỨNG (EVIDENCE)

### 8.1 Codebase Memory MCP (`search_graph`, project `vietsalepro`)
- Query `"create_order process_checkout delete_tenant_safe create_import_receipt create_exchange transaction RPC"` → xác nhận `create_exchange_transaction`, `process_checkout`, `process_checkout_tenant`, `createOrder`, `createImportReceipt` tồn tại (total 78).
- Query `"delete_tenant_safe delete_tenant_canonical tenant deletion RPC atomic"` → `remove_tenant_member`, `toggle_tenant_member_active`, `get_top_tenants`; không tìm thấy `delete_tenant_canonical` (khớp ROADMAP deferred).
- Query `"outbox side effect storage cleanup auth cleanup billing webhook dispatch after commit"` → `billing-webhooks` (Stripe/Momo/VNPay/BankTransfer handlers), `webhook_retry_schedule`, `retry_webhook_delivery`, `mark_webhook_delivery`, `trigger_webhook_event`, `get_pending_webhook_deliveries`, `run_admin_cron_audit_cleanup`, `get_tenant_storage_usage` (total 260).

### 8.2 Supabase MCP (read-only, project `rsialbfjswnrkzcxarnj`)
- `execute_sql` — `information_schema.tables` cho `outbox/transaction/delete_state/saga/compensation/retry/recovery` → **0 rows** (không tồn tại).
- `execute_sql` — `information_schema.tables` cho `webhook%` → `tenant_webhooks`, `webhook_deliveries`.
- `execute_sql` — `information_schema.columns` cho `webhook_deliveries` → 18 cột gồm `idempotency_key`, `attempt_count`, `max_attempts`, `next_retry_at`, `attempt_log`.
- `execute_sql` — `pg_proc` WHERE `prosecdef=true` AND `proname LIKE %delete%/create_order/process_checkout/create_import/create_exchange%` → 9 RPC SECURITY DEFINER (liệt kê §3.2).
- `execute_sql` — `pg_proc` WHERE `proname LIKE %delete_tenant%` → `delete_tenant_safe` (prosecdef=**false**), `delete_tenant_webhook` (prosecdef=false).
- `execute_sql` — `pg_get_functiondef` cho `delete_tenant_safe`, `trg_tenants_before_delete` → body xác nhận soft-archive + trigger flag (§3.2).
- `execute_sql` — `pg_trigger` trên `tenants` → 4 trigger (liệt kê §3.2), gồm `tenants_before_delete_guardrail` (BEFORE DELETE) và `trg_audit_log_tenants` (AFTER DELETE audit-in-trigger).

### 8.3 File tham chiếu (qua codebase memory + grep)
- `services/supabaseService.ts` — `createOrder` (1099), `createImportReceipt` (1852), `createExchangeTransaction` (3027); `_legacy*` fallbacks (SEMANTIC_MEMORY §6.1).
- `supabase/functions/billing-webhooks/index.ts` — `handleStripeWebhook`, `handleMomoWebhook`, `handleVNPayWebhook`, `handleBankTransferWebhook`.
- `supabase/schema.sql` — `process_checkout` (10374/16132), `process_checkout_tenant` (15821), `create_exchange_transaction` (3844), `webhook_retry_schedule` (13290), `retry_webhook_delivery` (25277), `audit_log_trigger` (33307).
- `supabase/migrations/20250705000004_phase9_5_process_checkout.sql`, `20250705000005_phase9_5_process_checkout_ledger_fixes.sql` — checkout coordinator.
- `supabase/migrations/20260715000011_fix_audit_log_trigger_tenant_delete.sql` — bản vá triệu chứng audit FK (tenant_id=NULL khi xóa tenant).

### 8.4 Cross-SPEC consistency (grep)
- `SPEC-001` — 18 match cho `CON-006|CON-007|CON-008|VRF-003|VRF-004|SPEC-003`; tất cả tham chiếu đúng hướng.
- `SPEC-005` — 15 match; §775 "Transaction boundary ownership remains with Transaction Coordinator; no transaction duplication"; CST-002 phụ thuộc SPEC-003 baselined.
- `Master Program` — 25 match; §10 transaction workstream, Guiding Principles 3/4/7, §28 failure/recovery.
- `ARCHITECTURE_SPECIFICATION_INDEX.md` — 18 match; §5.3 SPEC-003 entry (Planned — staleness GAP-006), §6.2 dependency matrix (SPEC-003 no mandatory deps), §6.3 acyclicity.

---

## 9. LƯU Ý VỀ PHẠM VI

- Không có thay đổi mã nguồn, schema, migration, hoặc SPEC nào trong quá trình đánh giá.
- Khuyến nghị phê duyệt được đưa ra cho CTA/Production Owner; việc ký Baseline cần được thực hiện bởi CTA theo ủy quyền (VAI_TRO_TRACH_NHIEM_VIETSALEPRO §2, §4).
- Tất cả truy vấn Supabase đều read-only (`execute_sql` SELECT); không `apply_migration`, không DDL, không DML ghi.
- Báo cáo tuân thủ pattern đã thiết lập bởi `WAVE-03_PHASE-1-1_SPEC-002_REVIEW_REPORT.md`.
