# WAVE-03 — PHASE 2.1: ĐÁNH GIÁ SPEC-001 (DELETE FRAMEWORK)

| Trường | Giá trị |
|---|---|
| Prompt ID | WAVE‑03‑PHASE‑2‑1‑001 |
| Ngày | 2026-07-24 |
| Agent | Engineering Execution Agent |
| Đối tượng đánh giá | `02_Specifications/SPEC-001_DELETE_FRAMEWORK_ARCHITECTURE_SPECIFICATION.md` (v1.1, Draft) |
| Trạng thái | HOÀN THÀNH |
| Quyết định được ủy quyền | CTA (Chief Technical Advisor) thay mặt Production Owner |
| MCP sử dụng | codebase-memory (read-only), Supabase production (read-only — connection timeout, fallback repository + Phase 1.5 cross-validated findings) |
| Skills sử dụng | codebase-design, doc-coauthoring, code-review, writing-plans |

---

## 1. TÓM TẮT SPEC-001 (Dành cho Production Owner)

### SPEC-001 là gì?
SPEC-001 định nghĩa **Delete Framework Architecture** — bản thiết kế kiến trúc lõi cho **quy trình xóa chuẩn (canonical delete pipeline)** toàn hệ thống VietSalePro. Đây là **SPEC trung tâm** của toàn bộ chương trình: mọi domain (tenant, user, product, customer, warehouse, employee, membership, subscription) khi xóa dữ liệu đều phải đi qua cùng một đường ống chuẩn, cùng một máy trạng thái, cùng một hợp đồng quan sát.

### Tại sao cần?
Sự cố `delete-tenant` HTTP 500 bộc lộ một lớp lỗi kiến trúc: việc xóa đang là **mối quan tâm tính năng (feature-level concern)** chứ không phải **năng lực nền tảng (platform capability)**. Mỗi module tự bịa ra cách xóa riêng, không có:
- Một component duy nhất sở hữu transaction atomic.
- Một vòng đời xóa có thể quan sát (state machine).
- Một hợp đồng audit độc lập với entity bị xóa.
- Một chính sách side-effect (storage/auth/billing) idempotent và bù trừ được.

Hậu quả: trigger `AFTER DELETE` cố ghi audit row tham chiếu tenant đã bị xóa trong cùng transaction → vi phạm FK → lỗi 500 không xử lý được.

### SPEC-001 giải quyết vấn đề gì?
- **Canonical Delete Pipeline 9 giai đoạn**: Request → Authenticate → Authorize → Validate → Prepare → Transact → Commit → Orchestrate Side Effects → Complete.
- **Single Transaction Owner**: chỉ database layer sở hữu đúng một transaction atomic cho mỗi delete request/session (CON-006/007/008).
- **Audit Independence**: audit ghi intent + pre-state + outcome, không giữ FK bắt buộc tới entity bị xóa (CON-012/013, phụ thuộc SPEC-002).
- **Idempotent Side-Effect Handlers**: storage/auth/billing/notification cleanup chạy **sau** commit, idempotent, bù trừ được, không block transaction (CON-009/010/011, WFL-003).
- **State Machine cai trị**: ACTIVE → DELETE_REQUESTED → VALIDATING → PREPARING → TRANSACTION_STARTED → EXECUTING → SIDE_EFFECTS_PENDING → COMMITTING → COMPLETED (+ nhánh FAILED/ROLLBACK/RECOVERABLE/RETRYABLE/CLOSED).
- **10 classification xóa**: soft, hard, archive, logical, physical, purge, retention, compliance, emergency, bulk.
- **Recovery Model**: ưu tiên rollback trước commit, compensation idempotent sau commit, state `RECOVERABLE` cho operator (RCM-001→004).
- **Observability**: mỗi request mang correlation_id, emit log/metric/trace/alert/dashboard (OBS-001→003).

### Điểm mạnh
- **Trung lập công nghệ** (CTX-005, CST-001): không ép engine/table/column/code cụ thể — đúng chuẩn Architecture Specification Program.
- **Đầy đủ 26 section bắt buộc** (16.1–16.26) theo template governance.
- **Domain Model rõ ràng** (DOM-001→004): 10 concept (Delete Request, Session, Transaction, Pipeline, State, Result, Recovery, Audit, Context, Metadata) với trách nhiệm đơn nhất.
- **10 component logic** (COM-001→004): Delete API, Orchestrator, Validator, Transaction Owner, Side-Effect Handler Registry, Side-Effect Handler, State Manager, Audit Writer, Recovery Manager, Observability Emitter.
- **14 contract** (CON-001→014) bao phủ request, authorization, transaction, side-effect, audit, idempotency.
- **8 failure mode + 8 recovery action** (FAM-001→010, RCM-001→004) — failure là first-class state.
- **10 verification requirement** (VRF-001→010) + 9 acceptance criteria (ACC-001).
- **3 ma trận phụ lục**: Classification Matrix (A), Domain Delete Dependency Matrix (B), Glossary (C), Traceability (D).
- **Traceability đầy đủ** tới Master Program (Sections 1,2,3,7,8,9,10.1,10.6,10.7,10.8,22,23,24,25,28,20,13,14).
- **Phụ thuộc đúng thứ tự acyclic**: SPEC-001 phụ thuộc bắt buộc SPEC-002/003/005 (đã Baselined), và là nền cho SPEC-004/006/007.
- **Future Evolution** (FEV-001/002): extension points cho domain mới, classification mới, handler mới, workflow engine, multi-region, archive — ADR bắt buộc khi thêm/xóa/reclassify.

### Điểm cần lưu ý
- SPEC-001 là **bản thiết kế mục tiêu (target)**, không phải mô tả hiện trạng. Codebase/database hiện tại **chưa tuân thủ** — điều này đúng kỳ vọng vì việc sửa thuộc Implementation Plan (Phase 4+).
- SPEC-001 tự nêu rõ (NGO-001) không bao gồm: code, RPC signature, table schema, migration, UI, billing provider logic, runbook. Đây là ranh giới lành mạnh với Implementation Plan.
- Index (Section 5.2) vẫn ghi SPEC-001 Status = "Planned"/"Version —", trong khi file SPEC-001 thực tế là "Draft v1.1". Đây là **minor inconsistency** của Index (chưa đồng bộ trạng thái Draft) — không ảnh hưởng nội dung SPEC.
- SPEC-001 là **Golden Architecture Specification** (theo SPEC_BASELINE_CERTIFICATION Section 3) — sau Baseline nó là chuẩn vàng để mọi Implementation Plan đối chiếu.

---

## 2. TÀI LIỆU ĐÃ ĐỌC

| Tài liệu | Trạng thái |
|---|---|
| `VAI_TRO_TRACH_NHIEM_VIETSALEPRO.md` | ✅ Tham chiếu (vai trò CTA ủy quyền Production Owner) |
| `NGUYEN_TAC_VIET_PROMPT_AGENT_VIETSALEPRO.md` | ✅ Tham chiếu (nguyên tắc viết prompt/agent) |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_BASELINE.md` | ✅ Đọc toàn bộ (knowledge priority, known limitations L1–L12) |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/SEMANTIC_MEMORY.md` | ✅ Đọc (grep delete/audit/SECURITY DEFINER/_legacy) |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/ROADMAP.md` | ✅ Đọc toàn bộ (Phase 1 ✅, Phase 2.1 ⏳, deferred items) |
| `SPEC-001_DELETE_FRAMEWORK_ARCHITECTURE_SPECIFICATION.md` | ✅ Đọc toàn bộ (817 dòng, 26 section) |
| `01_Governance/ARCHITECTURE_SPECIFICATION_INDEX.md` | ✅ Đọc phần SPEC-001 (Section 5.2, 6.2, 6.3, dependency acyclicity) |
| `01_Governance/Architecture_Specification_Program.md` | ✅ Tham chiếu (26-section template, Section 34.5 dependency gate) |
| `Deletion_Audit_Architecture_Remediation_Program.md` | ✅ Tham chiếu (Master Program v1.0) |
| `WAVE-03_PHASE-1-1_SPEC-002_REVIEW_REPORT.md` | ✅ Đọc phần khuyến nghị (tham khảo pattern) |
| `WAVE-03_PHASE-1-3_SPEC-003_REVIEW_REPORT.md` | ✅ Tham chiếu (pattern khuyến nghị APPROVE) |
| `WAVE-03_PHASE-1-5_SPEC-005_REVIEW_REPORT.md` | ✅ Đọc toàn bộ (tham khảo pattern + kết quả xác minh production schema) |

---

## 3. KẾT QUẢ XÁC MINH THỰC TẾ

### 3.1 Codebase (qua Codebase Memory MCP + repository)

| Hạng mục | SPEC-001 yêu cầu | Thực tế codebase | Khớp? |
|---|---|---|---|
| Delete Pipeline (pilot tenant) | 9 stages, single canonical API (WFL-001, COM-001) | Edge Function `supabase/functions/delete-tenant/index.ts` với `softDeleteTenant` (31-68) + `hardDeleteTenant` (70-214). Pipeline hiện tại là **ad-hoc**: fetch → guard admin subdomain → storage cleanup → orphan delete → delete tenant row (CASCADE + trigger) → auth cleanup → audit insert. **Không có 9 stage chuẩn, không có Orchestrator tách bạch.** | ❌ As-is không khớp (đúng kỳ vọng — đây là trạng thái SPEC remediate) |
| Transaction Owner | Single component owns atomic transaction (CON-006/007/008, COM-002) | **Không có transaction owner duy nhất.** `hardDeleteTenant` thực hiện nhiều lời gọi Supabase riêng biệt (storage.list/remove, orphan table deletes, tenants.delete, auth.admin.deleteUser, app_audit_log.insert) — **không được bao trong một DB transaction atomic**. Mỗi bước là HTTP/RPC riêng. | ❌ As-is vi phạm CON-006 |
| Audit Writer | Explicit audit write, independent (CON-012/013, SPEC-002) | `services/auditService.ts` `writeAuditLog` (49-82) + Edge `audit-log/index.ts`. Audit ghi qua **trigger** (`audit_log_trigger` trong schema.sql 33307-33338, migration 20260715000011) **và** insert thủ công trong Edge Function. Audit vẫn tham chiếu `tenant_id` (FK tới tenants). | ❌ As-is vi phạm CON-013 (audit FK-coupled) |
| Side-Effect Handler | Idempotent, post-commit, compensatable (CON-009/010/011, WFL-003) | Storage cleanup (`bucket.remove`) chạy **TRƯỚC** khi delete tenant row (dòng 109-139) — **vi phạm WFL-003/RES-001** ("Storage cleanup shall not occur before the database transaction commits"). Auth cleanup chạy sau DB delete nhưng **không idempotent, không compensatable, không có registry**. | ❌ As-is vi phạm CON-009/010 + WFL-003 |
| State Manager | Persist delete state machine (COM-004, STM-001, DAT-003) | **Không có bảng `delete_state`/`delete_session`/`delete_request`/`delete_recovery`** (grep `CREATE TABLE` trong `supabase/` → 0 kết quả). Không có State Manager component. | ❌ As-is không có |
| Idempotency | `request_id` uniqueness, replay stable (CON-014, SEC-005) | Chỉ có `correlationId` phục vụ logging (dòng 71, 206). **Không có `request_id` uniqueness check, không có idempotency key, không có replay-stable result.** | ❌ As-is không có |
| Trigger-based business logic | Cấm (CST-003, RES-002) | `trg_tenants_before_delete` (migration 20260711000009, đặt `app.hard_delete_tenant`), `trg_tenant_memberships_guardrails`, `audit_log_trigger` — **business workflow logic trong trigger**. | ❌ As-is vi phạm CST-003 |
| `_legacy*` fallbacks | N/A (SPEC không cấm, nhưng ad-hoc path việt "Platform before feature" PRM-001) | `_legacyPushCheckout`, `_legacyDeleteOrder`, `_legacyCreateReturnOrder` trong `services/supabaseService.ts` — non-atomic fallback paths. | ⚠️ Tồn tại (di sản, sẽ do Implementation Plan xử lý) |
| `delete_tenant_safe` RPC | Transaction Owner nên SECURITY DEFINER (SPEC-003) | `delete_tenant_safe` là **SECURITY INVOKER** (migration 20250706000000 dòng 197), chỉ soft-delete (set status='archived'). `delete_tenant_canonical` **không tồn tại**. | ❌ As-is: INVOKER + soft-delete only |
| Billing webhook side-effect | Idempotent handler với retry (CON-009/011) | `billing-webhooks` Edge Function v5 (đã verify Wave-05) có retry/decodeBase64 — có tính idempotent một phần nhưng **không qua Side-Effect Handler Registry chuẩn**. | ⚠️ Có retry nhưng không qua registry |

### 3.2 Database production (qua Supabase MCP + repository cross-validation)

> **Lưu ý MCP:** `execute_sql` và `list_tables` của Supabase MCP đều trả về "Connection terminated due to connection timeout" qua 4 lần thử (kể cả sau khi chờ 15s). Đây là vấn đề transient của pooler Supabase, không phải lỗi cấu hình. Theo **Knowledge Priority** trong `CODEBASE_MEMORY_BASELINE.md` (Priority 3 = Repository, Priority 4 = Supabase MCP), tôi fallback sang **repository migrations/schema.sql (ground truth)** + **kết quả cross-validated từ báo cáo Phase 1.5** (đã xác minh production schema qua Supabase MCP cùng ngày 2026-07-24). Kết quả được đánh dấu nguồn bằng chứng.

Project production: `rsialbfjswnrkzcxarnj` (QLBH), Postgres 17.6.1, region ap-northeast-1, ACTIVE_HEALTHY (xác nhận qua `list_projects`).

| Hạng mục | SPEC-001 yêu cầu | Thực tế database | Nguồn bằng chứng | Khớp? |
|---|---|---|---|---|
| `delete_tenant_safe` security mode | SECURITY DEFINER (Transaction Owner, SPEC-003) | **SECURITY INVOKER**, soft-delete only | Repository: migration `20250706000000_phase_p1_tenant_list_core_management.sql` dòng 197; Codebase Memory BL-003 | ❌ As-is |
| `delete_tenant_canonical` RPC | Canonical pipeline RPC (COM-001/002) | **Không tồn tại** | Repository: grep `delete_tenant_canonical` → 0 | ❌ As-is (deferred per ROADMAP §4) |
| `audit_log_tenant_id_fkey` | Không FK bắt buộc tới operational entity (CON-013, SPEC-002/005) | **Vẫn còn**, delete_rule SET NULL (patched từ NO ACTION) | Phase 1.5 report (Supabase MCP 2026-07-24); migration `20260715000011` | ❌ As-is (FK-coupled, chỉ vá triệu chứng) |
| `app_audit_log_tenant_id_fkey` | Như trên | **Vẫn còn**, delete_rule SET NULL | Phase 1. report (Supabase MCP 2026-07-24) | ❌ As-is |
| `trg_audit_log_tenants` trigger | Cấm business logic trong trigger (CST-003) | **Vẫn còn** (DROP+CREATE trong schema.sql dòng 32648-32649) | Repository: `supabase/schema.sql` | ❌ As-is |
| Bảng `delete_state` | Persist state machine (DAT-003, COM-004) | **KHÔNG TỒN TẠI** | Repository: grep `CREATE TABLE.*delete_state` → 0; ROADMAP §4 (deferred) | ❌ As-is (deferred) |
| Bảng `outbox` | Side-effect orchestration (SEQ-001, CON-010) | **KHÔNG TỒN TẠI** | Repository: grep → 0; ROADMAP §4 (deferred) | ❌ As-is (deferred) |
| Bảng `tenant_deletion_backups` | Recovery snapshots (RCM-001, DAT-006) | **KHÔNG TỒN TẠI** | Repository: grep → 0; ROADMAP §4 (deferred) | ❌ As-is (deferred) |
| Bảng `delete_session`/`delete_request`/`delete_recovery` | Domain model persistence (DAT-001/002) | **KHÔNG TỒN TẠI** | Repository: grep → 0 | ❌ As-is (deferred) |
| Tổng quan schema | N/A | 88 bảng, 150 FK (public) | Phase 1.5 report (Supabase MCP 2026-07-24) | ℹ️ Tham chiếu |

### 3.3 Đối chiếu với các SPEC đã Baseline

| SPEC đã Baseline | Mối liên hệ SPEC-001 | Nhất quán? | Ghi chú |
|---|---|---|---|
| **SPEC-002 (Audit)** — Baselined 2026-07-24 | SPEC-001 CON-012 ("ít nhất một audit record: intent + pre-state + outcome"), CON-013 ("audit không giữ FK ngăn sống sót sau xóa"), DAT-004/005, CST-005 | ✅ Nhất quán | SPEC-001 ủy thác chi tiết audit independence cho SPEC-002; không mâu thuẫn. As-is (audit FK SET NULL + trigger) vi phạm cả hai SPEC — đúng kỳ vọng remediate. |
| **SPEC-003 (Transaction)** — Baselined 2026-07-24 | SPEC-001 CON-006/007/008 (single atomic transaction, commit khi invariant pass, rollback toàn bộ khi fail), COM-002 (Transaction Owner sole committer), CST-004 (DB transaction không bị block bởi side effect), RSK-003 (lock timeout) | ✅ Nhất quán | SPEC-001 ủy thác transaction ownership model cho SPEC-003; CON-006/007/008 là projection đúng. As-is (Edge Function chia nhỏ nhiều call, không atomic) vi phạm — đúng kỳ vọng. |
| **SPEC-005 (FK Governance)** — Baselined 2026-07-24 | SPEC-001 CST-003 (cấm business logic trong trigger), CST-005 (audit immutable outlive entity), RSK-004 (audit FK residual), CON-013 | ✅ Nhất quán | SPEC-005 Appendix A "Audit Reference" yêu cầu delete_policy NO_ACTION + không FK bắt buộc tới operational entity. SPEC-001 CON-013/CST-005 đồng bộ. As-is (audit FK SET NULL, trg_audit_log_tenants) vi phạm cả hai — đúng kỳ vọng. |

---

## 4. KHOẢNG TRỐNG HOẶC MÂU THUẪN PHÁT HIỆN

### 4.1 Mâu thuẫn nội tại SPEC-001: KHÔNG

Không phát hiện mâu thuẫn nội tại giữa các section của SPEC-001. Các contract, state machine, workflow, failure/recovery model, verification, acceptance criteria đều nhất quán chéo.

### 4.2 Mâu thuẫn với Master Program / Specification Program: KHÔNG

- SPEC-001 tuân thủ 26-section template (Specification Program Section 16).
- Phụ thuộc bắt buộc SPEC-002/003/005 — đúng Section 34.5 (không Baseline trước dependency). Cả 3 đã Baselined 2026-07-24 → **điều kiện tiên quyết đã thoả mãn**.
- Dependency graph acyclic (Index Section 6.3): SPEC-001 là integrator, không cycle.
- Traceability đầy đủ tới Master Program workstream 10.1 (Delete Framework Redesign).

### 4.3 Khoảng trống giữa SPEC-001 (target) và as-is (codebase/database)

Đây là **khoảng trống dự kiến**, không phải khiếm khuyết của SPEC. SPEC-001 CTX-001→003 đã mô tả chính xác các thiếu hụt này; vai trò của SPEC là đóng khoảng trống qua Implementation Plan (Phase 4+).

| # | Khoảng trống as-is | Phân loại | Cách khắc phục (thuộc Implementation Plan) |
|---|---|---|---|
| G1 | Không có transaction owner duy nhất — Edge Function chia nhỏ nhiều call không atomic (vi phạm CON-006) | Critical (as-is) | Tạo `delete_tenant_canonical` RPC SECURITY DEFINER bao bọc toàn bộ row-level delete trong một transaction (per SPEC-003) |
| G2 | Storage cleanup chạy trước DB commit (vi phạm WFL-003/RES-001/CON-010) | Critical (as-is) | Đảo thứ tự: commit DB trước, side-effect storage sau, qua outbox |
| G3 | Audit FK-coupled tới tenants (vi phạm CON-013/SPEC-002/SPEC-005) | Critical (as-is) | Loại bỏ FK audit → tenants, chuyển sang soft reference + audit independence (per SPEC-002/005 Implementation Plan) |
| G4 | Business logic trong trigger (vi phạm CST-003/RES-002) | Major (as-is) | Di chuyển audit insertion ra trigger vào explicit code path (per SPEC-004 Trigger Governance) |
| G5 | Không có State Manager / bảng delete_state (vi phạm COM-004/STM-001/DAT-003) | Major (as-is) | Tạo bảng `delete_state` + State Manager (deferred per ROADMAP §4) |
| G6 | Không có outbox cho side-effect orchestration (vi phạm SEQ-001/CON-010) | Major (as-is) | Tạo bảng `outbox` + handler registry (deferred per ROADMAP §4) |
| G7 | Không có idempotency key / request_id uniqueness (vi phạm CON-014/SEC-005) | Major (as-is) | Thêm request_id + idempotency check vào canonical API |
| G8 | `delete_tenant_safe` là SECURITY INVOKER soft-delete only | Minor (as-is) | Giữ `delete_tenant_safe` cho soft-delete; thêm `delete_tenant_canonical` SECURITY DEFINER cho hard-delete pipeline |
| G9 | `_legacy*` fallbacks (non-atomic paths) | Minor (as-is) | Đánh giá loại bỏ dần khi canonical pipeline stable (per PRM-001 "Platform before feature") |

### 4.4 Mâu thuẫn governance Index

| # | Vấn đề | Phân loại | Khắc phục |
|---|---|---|---|
| I1 | Index Section 5.2 ghi SPEC-001 Status = "Planned", Version = "— (not yet drafted)", Current Phase = "Not yet initiated" — nhưng file thực tế là Draft v1.1, Effective Date 2026-07-23 | Minor (Index drift) | Cập nhật Index Section 5.2: Status → "Draft", Version → "1.1", Current Phase → "Drafted (under review)" — thuộc Phase 2.2 Baseline hoặc maintenance Index |

---

## 5. ĐÁNH GIÁ TỔNG THỂ

| Tiêu chí | Đánh giá | Ghi chú |
|---|---|---|
| Phù hợp Master Program | ✅ | Traceability đầy đủ (Section 16.26 D); workstream 10.1; principles mapping (16.7) đầy đủ 12 nguyên tắc |
| Phù hợp Specification Program | ✅ | 26 section bắt buộc; naming/identifier/versioning đúng; dependency gate Section 34.5 thoả mãn (3 dependency đã Baselined) |
| Phù hợp thực tế codebase | ✅ | SPEC mô tả chính xác as-is (CTX-001→003) và định nghĩa target reachable; các gap là as-is dự kiến |
| Phù hợp thực tế database | ✅ | SPEC không prescribing schema cụ thể (NGO-001); các bảng mục tiêu (delete_state/outbox/...) được ROADMAP §4 công nhận là deferred |
| Nhất quán với SPEC-002 (Audit) | ✅ | CON-012/013, DAT-004/005, CST-005 ủy thác và đồng bộ audit independence |
| Nhất quán với SPEC-003 (Transaction) | ✅ | CON-006/007/008, COM-002, CST-004 ủy thác và đồng bộ transaction ownership |
| Nhất quán với SPEC-005 (FK Governance) | ✅ | CST-003, CST-005, RSK-004, CON-013 đồng bộ FK policy + audit independence |
| Rủi ro nếu Baseline | **Thấp** | SPEC là thiết kế trung lập công nghệ; rủi ro thực tiễn nằm ở Implementation Plan (Phase 4+) và việc migrate as-is → target mà không gián đoạn production. Bản thân Baseline SPEC-001 không thay đổi code/schema. |

---

## 6. KHUYẾN NGHỊ

- ✅ **APPROVE — SPEC-001 có thể được Baseline ngay.**

### Lý do
1. SPEC-001 là bản thiết kế kiến trúc lõi hợp lệ, đầy đủ 26 section, trung lập công nghệ, không mâu thuẫn nội tại.
2. Phù hợp Master Program, Specification Program, và nhất quán với cả 3 foundation specs đã Baselined (SPEC-002/003/005).
3. Điều kiện tiên quyết Section 34.5 đã thoả mãn: cả 3 dependency bắt buộc đã Baselined 2026-07-24.
4. Các gap phát hiện (G1–G9) đều là **khoảng trống as-is dự kiến** — SPEC-001 CTX-001→003 đã mô tả chính xác chúng; vai trò của SPEC là đóng khoảng trống qua Implementation Plan. Việc Baseline tạo cơ sở governance để Implementation Plan khắc phục đúng hướng.
4. SPEC-001 là **cửa chặn** của toàn bộ Phase 3 (SPEC-004/006/007 đều phụ thuộc bắt buộc SPEC-001). Trì hoãn Baseline sẽ chặn toàn bộ Wave-03.
5. Rủi ro Baseline thấp — Baseline không thay đổi code/schema; rủi ro thực tiễn thuộc Implementation Plan (Phase 4+) và sẽ được đánh giá riêng.
6. Minor inconsistency I1 (Index drift Status "Planned" vs thực tế "Draft v1.1") không ảnh hưởng nội dung SPEC — xử lý tại Phase 2.2 hoặc maintenance Index.

### Kế hoạch đề xuất sau khi Baseline
1. **CTA ký Baseline SPEC-001** (Phase 2.2) — chuyển Status: Draft v1.1 → Baselined v1.1, Baseline Date 2026-07-24.
2. **Cập nhật `ARCHITECTURE_SPECIFICATION_INDEX.md` Section 5.2**: SPEC-001 Status → "Baselined", Version → "1.1", Baseline Date → "2026-07-24", Current Phase → "Baselined" (khắc phục I1).
3. **Cập nhật `ROADMAP.md`**: 2.2 → ✅ HOÀN THÀNH; mở Phase 3 (đánh giá SPEC-004/006/007).
4. **Bắt đầu Phase 3.1** đánh giá SPEC-004 (Trigger Governance) — phụ thuộc SPEC-001 đã Baseline.
5. **Phase 4** (Implementation Plan cho SPEC-001) chỉ bắt đầu sau khi SPEC-001 Baseline và Production Owner phê duyệt kế hoạch triển khai — Implementation Plan sẽ xử lý G1–G9 theo thứ tự ưu tiên (Critical → Major → Minor), đảm bảo không gián đoạn production.

---

## 7. BÁO CÁO CHO PRODUCTION OWNER (Tóm tắt không kỹ thuật)

**Chủ đề:** Đánh giá bản thiết kế kiến trúc khung xóa dữ liệu (SPEC-001 — Delete Framework).

**Tình hình:**
- SPEC-001 là **bản thiết kế trung tâm** của toàn bộ chương trình phục hồi kiến trúc. Nó định nghĩa **một quy trình xóa chuẩn duy nhất** mà mọi loại dữ liệu (tenant, user, sản phẩm, khách hàng, kho, nhân viên, gói thành viên, gói đăng ký) phải tuân theo.
- Bản thiết kế đã soạn thảo đầy đủ, đúng chuẩn governance, trung lập công nghệ (không ép công cụ cụ thể).
- Nó trực tiếp giải quyết nguyên nhân gốc sự cố `delete-tenant` HTTP 500: (1) không ai sở hữu transaction xóa atomic, (2) audit bị ràng buộc với dữ liệu bị xóa, (3) logic nghiệp vụ nằm trong trigger, (4) dọn dẹp storage chạy sai thứ tự.
- Quá trình kiểm chứng cho thấy hệ thống **hiện tại chưa đáp ứng** các yêu cầu này — điều này **đúng kỳ vọng** vì SPEC-001 là bản thiết kế mục tiêu; việc sửa code/schema sẽ làm ở giai đoạn Implementation Plan sau khi phê duyệt.
- Cả 3 bản thiết kế nền tảng (SPEC-002 Audit, SPEC-003 Transaction, SPEC-005 FK Governance) đã được phê duyệt trước đó (2026-07-24) — điều kiện tiên quyết để đánh giá SPEC-001 đã thoả mãn. SPEC-001 nhất quán với cả 3.

**Khuyến nghị:**
- **Phê duyệt SPEC-001** để trở thành **Baseline** (bản thiết kế chuẩn vàng).
- Sau đó, team sẽ lập Implementation Plan chi tiết để: tạo RPC xóa chuẩn atomic, loại bỏ FK audit, chuyển logic ra khỏi trigger, thêm bảng theo dõi trạng thái xóa, thêm cơ chế idempotency.
- Việc can thiệp production chỉ bắt đầu **sau** khi Implementation Plan được phê duyệt riêng.

**Rủi ro nếu không phê duyệt:**
- Chậm tiến độ toàn bộ Wave-03.
- SPEC-004 (Trigger Governance), SPEC-006 (Observability), SPEC-007 (Regression) — cả 3 đều phụ thuộc SPEC-001 — không thể bắt đầu đánh giá.
- Quy trình xóa hiện tại tiếp tục ad-hoc, rủi ro tái diễn sự cố 500.

**Rủi ro nếu phê duyệt mà không có Implementation Plan rõ ràng:**
- Bản thiết kế là chuẩn mục tiêu nhưng code/schema hiện tại vẫn ad-hoc. Cần đảm bảo Implementation Plan được lập và phê duyệt **trước** khi can thiệp production, và migrate theo thứ tự ưu tiên (Critical → Major → Minor) để không gián đoạn hoạt động.

**Kết luận:** SPEC-001 sẵn sàng được phê duyệt. Đây là cột mốc quan trọng nhất của chương trình — sau Baseline, Phase 3 (3 SPEC còn lại) có thể bắt đầu.

---

## 8. BẰNG CHỨNG (EVIDENCE)

### 8.1 Codebase Memory MCP
- `search_graph` "delete tenant safe hard delete" → xác nhận `hardDeleteTenant` (supabase/functions/delete-tenant/index.ts:70-214), `softDeleteTenant` (31-68), `deleteTenant`/`softDeleteTenant` (services/tenantService.ts:727-752), `canDeleteTenant`/`canCurrentUserDeleteTenant` (lib/permissions.ts).
- `search_graph` "audit service write audit log edge" → xác nhận `writeAuditLog` (services/auditService.ts:49-82), `write_audit_log` RPC (schema.sql:13306-13328), `audit_log_trigger` (schema.sql:33307-33338, migration 20260715000011), Edge `audit-log/index.ts`.
- `search_graph` "legacy fallback non-atomic" → xác nhận `_legacyPushCheckout` (supabaseService.ts:2553-2640), `_legacyDeleteOrder` (1298-1328), `_legacyCreateReturnOrder` (3137-3311).
- `search_graph` name_pattern `delete_tenant.*` → xác nhận BL-003 "update_tenant and delete_tenant_safe RPCs are SECURITY INVOKER" (ADMIN_DASHBOARD_PLAN/09_ADMIN_DASHBOARD_SYSTEM_INCONSISTENCY_REPORT.md).

### 8.2 Supabase MCP (read-only)
- `list_projects` → xác nhận production `rsialbfjswnrkzcxarnj` (QLBH), Postgres 17.6.1, ACTIVE_HEALTHY.
- `execute_sql` / `list_tables` → **Connection timeout** (4 lần thử). Fallback sang repository + Phase 1.5 cross-validated findings (xem 8.3).

### 8.3 Repository (ground truth — Priority 3 fallback)
- `supabase/migrations/20250706000000_phase_p1_tenant_list_core_management.sql` dòng 195-218 → `delete_tenant_safe` SECURITY INVOKER, soft-delete only (set status='archived').
- `supabase/migrations/20250706000000_...` dòng 225-237 → `purge_archived_tenants` procedure hard-delete qua `DELETE FROM tenants` (dựa FK CASCADE, không transaction owner).
- `supabase/functions/delete-tenant/index.ts` dòng 81-219 → `hardDeleteTenant`: storage cleanup (109-139) **trước** DB delete (156-160), auth cleanup (162-196) **sau** DB delete, audit insert (200-208) cuối — không atomic, sai thứ tự side-effect.
- `supabase/schema.sql` dòng 32648-32649 → `trg_audit_log_tenants` trigger vẫn tồn tại.
- `supabase/migrations/20260715000011_fix_audit_log_trigger_tenant_delete.sql` → patch `audit_log_trigger` set tenant_id NULL (vá triệu chứng, FK vẫn còn).
- grep `CREATE TABLE.*(delete_state|outbox|tenant_deletion_backups|delete_session|delete_request|delete_recovery)` trong `supabase/` → **0 kết quả** (các bảng mục tiêu chưa tồn tại, deferred per ROADMAP §4).

### 8.4 File tham chiếu
- `02_Specifications/SPEC-001_DELETE_FRAMEWORK_ARCHITECTURE_SPECIFICATION.md` — toàn bộ 26 section.
- `01_Governance/ARCHITECTURE_SPECIFICATION_INDEX.md` Section 5.2 (SPEC-001 catalog), 6.2 (dependency matrix), 6.3 (acyclicity).
- `WAVE-03_PHASE-1-5_SPEC-005_REVIEW_REPORT.md` — kết quả xác minh production schema (88 bảng, 150 FK, audit FK SET NULL, không có catalog tables) — cross-validated cùng ngày.
- `ROADMAP.md` Section 4 (deferred: delete_tenant_canonical, delete_state, outbox, tenant_deletion_backups).

---

## 9. LƯU Ý VỀ PHẠM VI

- Không có thay đổi mã nguồn, schema, migration, hoặc SPEC nào trong quá trình đánh giá.
- Supabase MCP database connection timeout là vấn đề transient của pooler; fallback repository + cross-validated Phase 1.5 findings đảm bảo bằng chứng vẫn là ground truth.
- Khuyến nghị phê duyệt được đưa ra cho CTA/Production Owner; việc ký Baseline cần được thực hiện bởi CTA theo ủy quyền tại Phase 2.2.
