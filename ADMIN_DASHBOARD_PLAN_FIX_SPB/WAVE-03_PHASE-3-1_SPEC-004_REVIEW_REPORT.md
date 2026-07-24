# WAVE-03 — PHASE 3.1: ĐÁNH GIÁ SPEC-004 (TRIGGER GOVERNANCE)

| Trường | Giá trị |
|---|---|
| Prompt ID | WAVE‑03‑PHASE‑3‑1‑001 |
| Ngày | 2026-07-24 |
| Agent | Engineering Execution Agent |
| Đối tượng đánh giá | `02_Specifications/SPEC-004_TRIGGER_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` (v1.0, Draft) |
| Trạng thái | HOÀN THÀNH |
| Quyết định được ủy quyền | CTA (Chief Technical Advisor) thay mặt Production Owner |
| MCP sử dụng | codebase-memory (read-only), Supabase production (read-only — connection timeout, fallback migrations + schema.sql consolidated) |
| Skills sử dụng | codebase-design, doc-coauthoring, code-review, writing-plans |

---

## 1. TÓM TẮT SPEC-004 (Dành cho Production Owner)

### SPEC-004 là gì?
SPEC-004 định nghĩa **Trigger Governance Architecture** — bản thiết kế kiến trúc cho **quản lý và phân loại mọi database trigger** trong toàn hệ thống VietSalePro. Đây là **Core specification** thiết lập: catalog (bộ danh mục), classification (phân loại), ownership (chủ sở hữu), lifecycle (vòng đời), execution boundary (ranh giới thực thi), và behavioral contract (hợp đồng hành vi) cho **mọi trigger ở tầng persistence**.

### Tại sao cần?
Sự cố `delete-tenant` HTTP 500 bộc lộ một lớp lỗi kiến trúc: trigger `trg_audit_log_tenants` (AFTER DELETE) cố ghi audit row tham chiếu tenant đang bị xóa trong cùng transaction → vi phạm FK → lỗi 500 không xử lý được. Nguyên nhân gốc không phải một dòng code sai, mà là **business workflow logic (audit insertion) nằm trong trigger** — nơi không được phép làm việc đó. Hiện trạng không có:
- Một bộ danh mục trigger chính thức (không ai biết có bao nhiêu trigger, làm gì).
- Phân loại rõ ràng (guardrail vs business-workflow không phân biệt được).
- Quy trình phê duyệt / nghỉ hưu / migrate trigger.
- Ranh giới hành vi rõ ràng (trigger được phép làm gì, cấm làm gì).

### SPEC-004 giải quyết vấn đề gì?
- **7 phân loại trigger canonical** (CON-003): Integrity/Guardrail, Audit Immutability, Referential Cascade, Denormalized Cache, Maintenance, Business Workflow (cấm), Legacy/Unknown.
- **Trigger Catalog** là nguồn sự thật duy nhất (COM-002): không trigger nào active nếu chưa được đăng ký.
- **Lifecycle state machine** (STM-001): PLANNED → REGISTERED → REVIEWED → ACTIVE → RETIRED → ARCHIVED (+ QUARANTINED, MIGRATING).
- **Execution Boundary** (CON-010/011): trigger chỉ làm invariant/maintenance/cache/cascade thấp cấp; **cấm** ghi audit, gọi external system, quyết định authorization, sở hữu transaction, orchestrate business workflow.
- **Migration path** cho business-workflow trigger (WFL-003, STM MIGRATING): migrate ra application code, verify, rồi retire.
- **Tương tác chặt chẽ** với 4 SPEC đã Baselined:
  - SPEC-001 (Delete): trigger không implement delete workflow (CON-032/033).
  - SPEC-002 (Audit): trigger không ghi audit record (CON-028/029).
  - SPEC-003 (Transaction): trigger không sở hữu transaction (CON-030/031).
  - SPEC-005 (FK): trigger tôn trọng ON DELETE policy (CON-034).
- **Observability** (OBS-001→003): mỗi trigger execution emit event có correlation_id; alert khi phát hiện trigger không tài liệu hoặc vi phạm contract.
- **10 verification requirement** (VRF-001→010) + 9 acceptance criteria (ACC-001).

### Điểm mạnh
- **Trung lập công nghệ** (CTX-005, CST-001): không ép engine/SQL/vendor cụ thể — đúng chuẩn Architecture Specification Program.
- **Đầy đủ 26 section bắt buộc** (16.1–16.26) theo template governance.
- **Domain Model rõ ràng** (DOM-001→004): 7 concept (Trigger, Classification, Catalog, Metadata, Run, Outcome, Migration) với trách nhiệm đơn nhất.
- **8 component logic** (COM-001→004): Catalog Store, Classifier, Validator, Lifecycle Manager, Execution Guard, Migration Handler, Observability Emitter, Approval Authority.
- **37 contract** (CON-001→037) bao phủ classification, ownership, registration, naming, execution boundary, invocation, ordering, chaining, dependencies, behavior, determinism, idempotency, timeout, failure/recovery, observability, audit/transaction/delete/FK interaction, security/compliance.
- **6 failure mode + 6 recovery action** (FAM-001→002, RCM-001→003) — failure là first-class state.
- **5 risk** (RSK-001) với mitigation và owner.
- **3 ma trận phụ lục**: Classification Matrix (A), Metadata Template (B), Trigger-to-Domain Mapping (C), Traceability (D).
- **Traceability đầy đủ** tới Master Program (Sections 1,2,3,7,8,9,10.1,10.6,10.7,10.8,22,24,25,28,20,13,14).
- **Phụ thuộc đúng thứ tự acyclic**: SPEC-004 phụ thuộc bắt buộc SPEC-001 (đã Baselined 2026-07-24).
- **Future Evolution** (FEV-001/002): extension points cho classification mới, resource mới, automated discovery, runtime enforcement, event-driven alternatives — ADR bắt buộc khi thêm/xóa/reclassify.
- **Appendix C Trigger-to-Domain Mapping** ánh xạ trực tiếp các domain hiện có (Audit, Delete, Tenant Limits, Order Code Generation, Timestamps) sang governance action — rất thực tế và đối chiếu được với codebase.

### Điểm cần lưu ý
- SPEC-004 là **bản thiết kế mục tiêu (target)**, không phải mô tả hiện trạng. Codebase/database hiện tại **chưa tuân thủ** (chưa có Trigger Catalog, chưa phân loại, business-workflow trigger còn active) — điều này đúng kỳ vọng vì việc sửa thuộc Implementation Plan (Phase 4+).
- SPEC-004 tự nêu rõ (NGO-001, SCO-004) không bao gồm: code, trigger syntax, migration, RPC signature, deployment. Đây là ranh giới lành mạnh với Implementation Plan.
- **Index (Section 5.2) vẫn ghi SPEC-004 Status = "Planned"/"Version —"**, trong khi file SPEC-004 thực tế là "Draft v1.0". Đây là **minor inconsistency** của Index (chưa đồng bộ trạng thái Draft) — không ảnh hưởng nội dung SPEC. Khuyến nghị: cập nhật Index sang "Draft v1.0" khi Baseline (cùng lúc Phase 3.2).
- SPEC-004 là **SPEC phụ thuộc bắt buộc SPEC-001** (đã Baselined) — điều kiện tiên quyết Section 34.5 đã thoả mãn.

---

## 2. TÀI LIỆU ĐÃ ĐỌC

| Tài liệu | Trạng thái |
|---|---|
| `VAI_TRO_TRACH_NHIEM_VIETSALEPRO.md` | ✅ Tham chiếu (vai trò CTA ủy quyền Production Owner) |
| `NGUYEN_TAC_VIET_PROMPT_AGENT_VIETSALEPRO.md` | ✅ Tham chiếu (nguyên tắc viết prompt/agent, MCP, skills, evidence) |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/SEMANTIC_MEMORY.md` | ✅ Đọc (architecture overview, trigger inventory, audit dual system) |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/ROADMAP.md` | ✅ Đọc toàn bộ (Phase 1 ✅, Phase 2 ✅, Phase 3.1 ⏳) |
| `SPEC-004_TRIGGER_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` | ✅ Đọc toàn bộ (755 dòng, 26 section) |
| `Deletion_Audit_Architecture_Remediation_Program.md` (Master Program) | ✅ Tham chiếu (vision, principles, workstreams) |
| `01_Governance/Architecture_Specification_Program.md` | ✅ Tham chiếu (mandatory template, dependency framework) |
| `01_Governance/ARCHITECTURE_SPECIFICATION_INDEX.md` | ✅ Đọc (SPEC-004 portfolio entry, dependency matrix, acyclicity) |
| `WAVE-03_PHASE-1-1_SPEC-002_REVIEW_REPORT.md` | ✅ Tham chiếu pattern |
| `WAVE-03_PHASE-1-3_SPEC-003_REVIEW_REPORT.md` | ✅ Tham chiếu pattern |
| `WAVE-03_PHASE-1-5_SPEC-005_REVIEW_REPORT.md` | ✅ Tham chiếu pattern |
| `WAVE-03_PHASE-2-1_SPEC-001_REVIEW_REPORT.md` | ✅ Tham chiếu pattern |
| SPEC-001 / SPEC-002 / SPEC-003 / SPEC-005 (cross-reference trigger contracts) | ✅ Grep trigger-related contracts |

> **Lưu ý**: `.codebase-memory/CODEBASE_MEMORY_BASELINE.md`, `VALIDATION_REPORT.md`, `SEMANTIC_MEMORY.md` nằm trong thư mục `.codebase-memory/` bị ignore-file chặn đọc trực tiếp. Bản sao `SEMANTIC_MEMORY.md` tại `ADMIN_DASHBOARD_PLAN_FIX_SPB/` đã được đọc đầy đủ. Codebase Memory MCP được dùng để xác minh trực tiếp graph (28.881 nodes).

---

## 3. KẾT QUẢ XÁC MINH THỰC TẾ

### 3.1 Qua Codebase Memory MCP (read-only)

Xác minh qua `search_graph` (BM25 + name_pattern) trên project `vietsalepro` (28.881 nodes / 42.874 edges).

| Hạng mục SPEC-004 | Yêu cầu | Thực tế codebase | Khớp? |
|---|---|---|---|
| Trigger Catalog Store | Bảng/catalog chính thức | Không có `trigger_registry` / catalog table | ❌ Chưa có (đúng kỳ vọng target) |
| Trigger Classifier | Code phân loại trigger | Không có | ❌ Chưa có |
| Trigger Lifecycle Manager | Quy trình quản lý lifecycle | Không có | ❌ Chưa có |
| Trigger Execution Guard | Cơ chế chặn forbidden side effect | Không có | ❌ Chưa có |
| `audit_log_trigger()` function | (đối tượng cần migrate) | Tồn tại — `supabase/schema.sql:33307-33338`, SECURITY DEFINER, INSERT vào `audit_log` | ✅ Xác nhận tồn tại (business-workflow) |
| `trg_audit_log_tenants` | AFTER DELETE trigger (nguồn gốc sự cố) | Tồn tại — `schema.sql:32648-32651`, AFTER INSERT/UPDATE/DELETE, EXECUTE `audit_log_trigger()` | ✅ Xác nhận tồn tại (cần migrate) |
| `tenants_before_delete_guardrail` | BEFORE DELETE guardrail | Tồn tại — `schema.sql:29384-29389`, set `app.hard_delete_tenant` flag | ✅ Xác nhận (guardrail — retain) |
| `tenant_registration_event_trigger` | AFTER INSERT event | Tồn tại — `schema.sql:27006-27011`, AFTER INSERT, EXECUTE `insert_tenant_registration_event()` | ✅ Xác nhận (business-workflow — migrate) |
| `set_tenant_record_user_tracking` | BEFORE INSERT/UPDATE tracking | Tồn tại — `schema.sql:31037-31041` (tenants) + 6 bảng khác (products/orders/customers/suppliers/categories/brands) | ✅ Xác nhận (maintenance — review) |
| `trg_tenant_memberships_guardrails` | Guardrail memberships | Tồn tại — `schema.sql:29263-29268`, BEFORE DELETE/UPDATE | ✅ Xác nhận (guardrail — retain) |
| `trg_tenant_memberships_audit` | Audit-writing trigger | Tồn tại — `schema.sql:30325-30329`, AFTER INSERT/UPDATE/DELETE, INSERT vào `app_audit_log` | ✅ Xác nhận (business-workflow — migrate) |
| `trg_orders_set_order_code` | Order code generation | Tồn tại — `schema.sql:14653-14657`, BEFORE INSERT | ✅ Xác nhận (business-workflow — migrate) |
| `trg_check_tenant_user_limit` / `trg_check_tenant_product_limit` | Tenant limit enforcement | Tồn tại — `schema.sql:15173-15182`, BEFORE INSERT | ✅ Xác nhận (business-workflow — migrate) |

### 3.2 Qua Supabase MCP (read-only) — Production

> **Kết quả**: Supabase `execute_sql` against project `rsialbfjswnrkzcxarnj` trả về **"Connection terminated due to connection timeout"** cho cả 2 lần thử (query đầy đủ `pg_trigger` và query tối giản `SELECT tgname ... LIMIT 50`). Đây là tình trạng đã được Prompt dự báo (Section 9: "khắc phục timeout bằng cách lấy thông tin từ migrations nếu cần").
>
> **Fallback**: Sử dụng `supabase/schema.sql` (consolidated schema phản ánh production state, được build từ 147 migrations) để lập trigger inventory. Đây là cùng phương pháp fallback đã dùng ở Phase 1.1/1.3/1.5/2.1 và được cross-validated.

**Trigger inventory từ `schema.sql` (31 `CREATE TRIGGER` statements)** — phân loại theo SPEC-004 CON-003:

| # | Trigger | Bảng | Timing/Event | Function | Phân loại SPEC-004 | Hành động |
|---|---|---|---|---|---|---|
| 1 | `trg_orders_set_order_code` | orders | BEFORE INSERT | `orders_set_order_code()` | **Business Workflow** (identifier generation) | Migrate |
| 2 | `trg_check_tenant_user_limit` | tenant_memberships | BEFORE INSERT | `check_tenant_limits()` | **Business Workflow** (tenant limit) | Migrate |
| 3 | `trg_check_tenant_product_limit` | products | BEFORE INSERT | `check_tenant_limits()` | **Business Workflow** (tenant limit) | Migrate |
| 4 | `trg_check_tenant_order_limit` | orders | BEFORE INSERT | `increment_monthly_order_count()` | **Business Workflow** (tenant limit) | Migrate |
| 5 | `trg_audit_log_orders` | orders | BEFORE I/U/D | `write_audit_log()` | **Business Workflow** (audit write) | Migrate |
| 6 | `trg_audit_log_products` | products | BEFORE I/U/D | `write_audit_log()` | **Business Workflow** (audit write) | Migrate |
| 7 | `trg_audit_log_import_receipts` | import_receipts | BEFORE I/U/D | `write_audit_log()` | **Business Workflow** (audit write) | Migrate |
| 8 | `trg_audit_log_disposals` | disposals | BEFORE I/U/D | `write_audit_log()` | **Business Workflow** (audit write) | Migrate |
| 9 | `trg_audit_log_app_settings` | app_settings | BEFORE I/U/D | `write_audit_log()` | **Business Workflow** (audit write) | Migrate |
| 10 | `system_settings_updated_by_trigger` | system_settings | BEFORE I/U | `system_settings_set_updated_by()` | **Maintenance** (updated_by) | Review/retain |
| 11 | `tenant_registration_event_trigger` | tenants | AFTER INSERT | `insert_tenant_registration_event()` | **Business Workflow** (registration event) | Migrate |
| 12 | `tenant_memberships_guardrails` | tenant_memberships | BEFORE D/U | `trg_tenant_memberships_guardrails()` | **Integrity/Guardrail** | Retain |
| 13 | `tenants_before_delete_guardrail` | tenants | BEFORE DELETE | `trg_tenants_before_delete()` | **Integrity/Guardrail** (set hard-delete flag) | Retain |
| 14 | `tenant_memberships_audit` | tenant_memberships | AFTER I/U/D | `trg_tenant_memberships_audit()` | **Business Workflow** (audit write to app_audit_log) | Migrate |
| 15 | `set_tenant_record_user_tracking` (tenants) | tenants | BEFORE I/U | `set_tenant_record_user_tracking()` | **Maintenance** (user tracking) | Review/retain |
| 16 | `handle_new_user` | auth.users | AFTER INSERT | `handle_new_user()` | **Business Workflow** (user provisioning) | Migrate/review |
| 17–22 | `set_tenant_record_user_tracking` (products/orders/customers/suppliers/categories/brands) | 6 bảng | BEFORE I/U | `set_tenant_record_user_tracking()` | **Maintenance** (user tracking) | Review/retain |
| 23 | `plan_features_updated_at` | plan_features | BEFORE UPDATE | `update_plan_features_updated_at()` | **Maintenance** (timestamp) | Review/retain |
| 24 | `trg_audit_log_tenants` | tenants | AFTER I/U/D | `audit_log_trigger()` | **Business Workflow** (audit write — nguồn gốc sự cố) | **Migrate (P0)** |
| 25 | `trg_audit_log_tenant_memberships` | tenant_memberships | AFTER I/U/D | `audit_log_trigger()` | **Business Workflow** (audit write) | Migrate |
| 26 | `trg_audit_log_tenant_subscriptions` | tenant_subscriptions | AFTER I/U/D | `audit_log_trigger_tenant_subscriptions()` | **Business Workflow** (audit write) | Migrate |
| 27 | `admin_roles_set_updated_at` | admin_roles | BEFORE UPDATE | `trg_admin_roles_set_updated_at()` | **Maintenance** (timestamp) | Review/retain |
| 28 | `trg_audit_log_system_admins` | system_admins | AFTER I/U/D | `audit_log_trigger_system_admins()` | **Business Workflow** (audit write) | Migrate |
| 29 | `trg_audit_log_invitations` | invitations | AFTER I/U/D | `audit_log_trigger()` | **Business Workflow** (audit write) | Migrate |
| 30 | `trg_audit_log_licenses` | licenses | AFTER I/U/D | `audit_log_trigger()` | **Business Workflow** (audit write) | Migrate |
| 31 | `trg_app_audit_log_login_enforcement` | app_audit_log | BEFORE I/U | `app_audit_log_login_enforcement()` | **Integrity/Guardrail** (login enforcement) | Review/retain |

**Tổng kết phân loại (theo SPEC-004 CON-003):**
- **Business Workflow (cấm — phải migrate)**: ~18 trigger (audit-writing × 13, tenant limit × 3, order code × 1, registration event × 1, user provisioning × 1).
- **Integrity/Guardrail (retain)**: ~3 trigger (memberships guardrails, tenants before-delete guardrail, app_audit_log login enforcement).
- **Maintenance (review/retain)**: ~10 trigger (updated_at/updated_by/user tracking × nhiều bảng).

> **Đối chiếu SPEC-004 Appendix C (Trigger-to-Domain Mapping)**: Mapping của SPEC-004 (Audit → migrate audit-writing; Delete → retain guardrail/cascade; Tenant Limits → migrate; Order Code → migrate; Timestamps → review) **khớp chính xác** với phân loại thực tế ở trên. Đây là bằng chứng mạnh rằng SPEC-004 được soạn thảo có đối chiếu codebase thực.

### 3.3 Đối chiếu với các SPEC đã Baseline

| SPEC đã Baseline | Contract SPEC-004 tham chiếu | Contract SPEC đối ứng | Nhất quán? |
|---|---|---|---|
| **SPEC-001 (Delete)** | CON-032 (trigger không implement delete workflow), CON-033 (trigger không insert audit row cho entity đang delete), RES-002 | SPEC-001 CST-003 "framework shall not place business workflow logic inside database triggers"; CTX-002 (AFTER DELETE trigger audit insert = gốc sự cố) | ✅ Khớp |
| **SPEC-002 (Audit)** | CON-028 (trigger không ghi audit record), CON-029 (audit-immutability trigger chỉ reject U/D) | SPEC-002 RES-002, WFL-003, CST-004 "Audit insertion shall not be performed by business-workflow triggers"; RES-002 "Audit triggers, where retained, limited to immutability enforcement" | ✅ Khớp |
| **SPEC-003 (Transaction)** | CON-030 (trigger không own/commit/rollback transaction), CON-031 (trigger không emit side effect cross transaction boundary) | SPEC-003 RES-002, CON-032, CST-002 "triggers may enforce low-level invariants only; shall not encode business workflow logic or emit side effects that cross the transaction boundary" | ✅ Khớp |
| **SPEC-005 (FK)** | CON-034 (trigger tôn trọng ON DELETE policy; referential-cascade trigger chỉ khi declarative không đủ) | SPEC-005 RES-002, RSK-006, cross-spec consistency "Trigger behavior remains with Trigger Governance; no trigger logic duplication"; INT-003 (Policy Query Interface consumed by Trigger Governance) | ✅ Khớp |

> Cả 4 SPEC đã Baseline đều **chủ động tham chiếu SPEC-004** trong References table và đặt trigger behavior thuộc về SPEC-004. Không có mâu thuẫn, không trùng lặp trách nhiệm. SPEC-004 là **bên cung (provider)** trigger contract; 4 SPEC kia là **bên tiêu thụ (consumer)**.

---

## 4. KHOẢNG TRỐNG HOẶC MÂU THUẪN PHÁT HIỆN

| # | Phát hiện | Mức | Mô tả | Đề xuất khắc phục |
|---|---|---|---|---|
| G1 | Index chưa đồng bộ trạng thái SPEC-004 | **Minor** | `ARCHITECTURE_SPECIFICATION_INDEX.md` Section 5.2/5.3 ghi SPEC-004 Status = "Planned", Version = "—", Owner = "to assign at Registered", Current Phase = "Not yet initiated" — trong khi file SPEC-004 thực tế là "Draft v1.0", Author = Engineering Execution Agent, Technical Custodian = CTA. | Cập nhật Index sang "Draft v1.0" khi ký Baseline (Phase 3.2). Đây là cùng pattern inconsistency đã ghi nhận ở SPEC-001/002/003/005 review — không ảnh hưởng nội dung SPEC. |
| G2 | Supabase MCP timeout | **Minor (môi trường)** | `execute_sql` against production timeout 2/2 lần. | Đã fallback sang `schema.sql` consolidated (được build từ 147 migrations, phản ánh production state). Phương pháp cross-validated với các Phase trước. Khuyến nghị: thử lại Supabase MCP ở Phase 3.2 khi ký Baseline nếu cần xác nhận live. |
| G3 | `audit_log_trigger()` post-fix vẫn vi phạm CON-028 | **Không phải gap của SPEC** | Migration `20260715000011` đã fix lỗi 500 bằng cách set `v_tenant_id := NULL` khi DELETE tenants, nhưng trigger `trg_audit_log_tenants` **vẫn tồn tại và vẫn ghi audit record** (chỉ tránh FK violation). Theo SPEC-004 CON-028, trigger **không được ghi audit record** dù gì. | Đây là **vấn đề implementation** (thuộc Implementation Plan Phase 4+), không phải gap của SPEC-004. SPEC-004 đã đúng quy định hành vi mục tiêu. Khuyến nghị: Implementation Plan SPEC-004 phải đưa `trg_audit_log_tenants` vào `MIGRATING` state ngay (P0). |
| G4 | SPEC-004 không liệt kê trigger inventory hiện tại | **Minor (theo thiết kế)** | SPEC-004 là architecture spec (trung lập công nghệ, không prescribe implementation), nên không liệt kê 31 trigger hiện có. | Đúng ranh giới (NGO-001). Trigger inventory cụ thể thuộc Implementation Plan (Discover stage, WFL-001). Báo cáo này đã lập inventory thay thế (Section 3.2). |

> **Không phát hiện mâu thuẫn Critical hay Major**. Tất cả phát hiện đều Minor hoặc thuộc phạm vi Implementation Plan.

---

## 5. ĐÁNH GIÁ TỔNG THỂ

| Tiêu chí | Đánh giá | Ghi chú |
|---|---|---|
| Phù hợp Master Program | ✅ | Traceability (Appendix D) đầy đủ tới Master Program Sections 1,2,3,7,8,9,10.1,10.6,10.7,10.8,22,24,25,28,20,13,14. Principles Mapping (PRM-001) ánh xạ 8 nguyên tắc. |
| Phù hợp Specification Program | ✅ | Đầy đủ 26 section (16.1–16.26) theo mandatory template. Requirement ID dùng `SPEC-004-<SECTION>-<NNN>` đúng format. Evidence section đặt sau Appendix. Technology-neutral (CST-001). |
| Phù hợp thực tế codebase | ✅ | Appendix C Trigger-to-Domain Mapping khớp chính xác với 31 trigger thực tế. CTX-001→005 mô tả đúng hiện trạng (audit logging, business-code generation, tenant limits, user tracking, timestamps). |
| Phù hợp thực tế database | ✅ | 31 trigger trong `schema.sql` được phân loại chính xác theo CON-003. `trg_audit_log_tenants` (nguồn gốc sự cố) được SPEC-004 CTX-002 mô tả đúng failure class. |
| Nhất quán với SPEC-001 | ✅ | CON-032/033, RES-002 ↔ SPEC-001 CST-003, CTX-002. SPEC-001 là dependent của SPEC-004 (Index 6.2). |
| Nhất quán với SPEC-002 | ✅ | CON-028/029 ↔ SPEC-002 RES-002, WFL-003, CST-004. Audit-writing trigger migrate, audit-immutability trigger retain. |
| Nhất quán với SPEC-003 | ✅ | CON-030/031 ↔ SPEC-003 RES-002, CON-032, CST-002. Trigger participate, không own transaction. |
| Nhất quán với SPEC-005 | ✅ | CON-034 ↔ SPEC-005 RES-002, RSK-006, INT-003. Trigger tôn trọng ON DELETE policy. |
| Rủi ro nếu Baseline | **Thấp** | SPEC-004 là architecture spec (không code/migration). Rủi ro duy nhất là legacy business-workflow trigger resist migration (RSK-001, High/High) — đã có mitigation (migration template, staged quarantine, automated static analysis). Rủi ro này thuộc Implementation Plan, không phải Baseline. |

---

## 6. KHUYẾN NGHỊ

### ☑ APPROVE — SPEC-004 có thể được Baseline ngay (sau khi cập nhật Index minor inconsistency)

**Lý do khuyến nghị APPROVE:**
1. SPEC-004 **đầy đủ 26 section bắt buộc**, tuân thủ mandatory template của Architecture Specification Program.
2. SPEC-004 **trung lập công nghệ** (CST-001) — không ép implementation, đúng chuẩn governance.
3. SPEC-004 **nhất quán 100%** với cả 4 SPEC đã Baseline (SPEC-001/002/003/005) — không mâu thuẫn, không trùng lặp trách nhiệm.
4. SPEC-004 **đối chiếu chính xác thực tế codebase/database** — Appendix C mapping khớp với 31 trigger thực tế; CTX-002 mô tả đúng sự cố `delete-tenant` HTTP 500.
5. SPEC-004 **điều kiện tiên quyết đã thoả mãn** — SPEC-001 (dependency bắt buộc) đã Baselined 2026-07-24.
6. **Không phát hiện gap Critical/Major** — chỉ có 1 minor inconsistency của Index (G1) và 1 vấn đề môi trường (G2, đã fallback).
7. SPEC-004 cung cấp **cửa chặn** để đảm bảo triggers không còn chứa business workflow logic — trực tiếp giải quyết gốc rễ sự cố `delete-tenant` HTTP 500.

**Kế hoạch Baseline SPEC-004 (đề xuất cho Phase 3.2):**
1. CTA xem xét báo cáo này và xác nhận APPROVE.
2. Cập nhật `ARCHITECTURE_SPECIFICATION_INDEX.md` Section 5.2/5.3: SPEC-004 Status → "Baselined", Version → "1.0", Baseline Date → "2026-07-24", Owner → "Chief Technical Advisor", Current Phase → "Baselined". (Khắc phục G1.)
3. Cập nhật SPEC-004 file header: Status → "Baselined", Effective Date → "2026-07-24".
4. Cập nhật `ROADMAP.md`: 3.2 → ✅ HOÀN THÀNH.
5. Cập nhật Lịch sử cập nhật ROADMAP.
6. Ghi Baseline Certification (nếu quy trình yêu cầu file riêng, theo pattern SPEC-001/002/003/005).
7. Sau Baseline, chỉ còn SPEC-006 (Observability) và SPEC-007 (Regression & Verification) để hoàn thành toàn bộ 7 SPEC.

---

## 7. BÁO CÁO CHO PRODUCTION OWNER (Một trang, không kỹ thuật)

**SPEC-004 là gì?**
SPEC-004 là bản thiết kế kiến trúc cho **quản lý mọi "trigger" trong cơ sở dữ liệu**. Trigger là một đoạn chương trình tự động chạy khi dữ liệu thay đổi. Hệ thống hiện có 31 trigger đang chạy ngầm, làm nhiều việc: ghi log kiểm toán, sinh mã đơn hàng, giới hạn số user, cập nhật thời gian... nhưng **không ai quản lý, không ai phân loại, không ai biết hết chúng làm gì**.

**Vấn đề SPEC-004 giải quyết**
Sự cố `delete-tenant` lỗi 500 xảy ra vì một trigger tự động ghi log kiểm toán khi xóa tenant — nhưng tenant vừa bị xóa nên log không ghi được → lỗi. Nguyên nhân gốc: **trigger làm việc không thuộc phạm vi của nó** (ghi log kiểm toán là việc của application code, không phải trigger). SPEC-004 quy định rõ: trigger **chỉ được làm invariant thấp cấp** (bảo vệ tính toàn vẹn dữ liệu); **cấm** ghi log kiểm toán, gọi hệ thống ngoài, quyết định phân quyền, sở hữu transaction, hay orchestrate workflow.

**SPEC-004 đưa ra**
- **Bộ danh mục chính thức** cho mọi trigger (ai cũng biết có trigger nào, làm gì, ai sở hữu).
- **7 phân loại** rõ ràng (guardrail, audit-immutability, cascade, cache, maintenance, business-workflow [cấm], legacy).
- **Vòng đời quản lý**: từ đăng ký → phân loại → kiểm tra → phê duyệt → kích hoạt → giám sát → nghỉ hưu.
- **Đường migrate** cho 18 trigger business-workflow hiện có (chuyển logic ra application code, kiểm chứng, rồi tắt trigger).
- **Giám sát**: mỗi lần trigger chạy đều có log + cảnh báo nếu phát hiện trigger "lậu" hoặc vi phạm hợp đồng.

**Đánh giá**
- SPEC-004 **đầy đủ, rõ ràng, trung lập công nghệ**, tuân thủ đúng chuẩn governance.
- SPEC-004 **không mâu thuẫn** với 4 bản thiết kế đã phê duyệt trước đó (SPEC-001/002/003/005) — ngược lại, nó **bổ sung và hoàn thiện** cho 4 bản đó.
- SPEC-004 **khớp với thực tế** cơ sở dữ liệu (31 trigger được phân loại chính xác).
- **Rủi ro thấp**: SPEC-004 chỉ là bản thiết kế, không thay đổi code/database. Việc sửa thực tế thuộc Implementation Plan (Giai đoạn 4+).

**Đề xuất quyết định**
**NÊN PHÊ DUYỆT (BASELINE) SPEC-004.** Đây là cửa chặn quan trọng để đảm bảo trigger không còn chứa logic nghiệp vụ — trực tiếp giải quyết gốc rễ sự cố lỗi 500. Sau khi phê duyệt, chỉ còn 2 bản thiết kế (SPEC-006 Quan sát, SPEC-007 Kiểm thử hồi quy) để hoàn thành toàn bộ 7 bản thiết kế kiến trúc.

---

## 8. LƯU Ý QUAN TRỌNG

- SPEC-004 là **SPEC phụ thuộc bắt buộc SPEC-001** (đã Baseline 2026-07-24). Điều kiện tiên quyết Section 34.5 đã thoả mãn.
- Sau khi SPEC-004 được Baseline, **chỉ còn SPEC-006 (Observability) và SPEC-007 (Regression & Verification)** để hoàn thành toàn bộ 7 SPEC.
- `trg_audit_log_tenants` (AFTER DELETE) là **trigger business-workflow cốt lõi cần migrate (P0)** — trực tiếp liên quan sự cố `delete-tenant` HTTP 500. Migration `20260715000011` chỉ fix triệu chứng (set tenant_id NULL), trigger **vẫn ghi audit record** → vẫn vi phạm SPEC-004 CON-028. Việc migrate thuộc Implementation Plan Phase 4+.
- Supabase MCP production timeout — đã fallback sang `schema.sql` consolidated (cross-validated với các Phase trước).
- **Không có commit, push, deploy, hoặc thay đổi mã nguồn/migration/schema/SPEC** trong prompt này. Chỉ tạo báo cáo đánh giá và cập nhật ROADMAP.

---

## 9. TÀI LIỆU ĐÃ TẠO/CẬP NHẬT

- `WAVE-03_PHASE-3-1_SPEC-004_REVIEW_REPORT.md` ✅ (file này)
- `ROADMAP.md` ✅ (cập nhật 3.1 → HOÀN THÀNH, 3.2 → sẵn sàng ký Baseline)
