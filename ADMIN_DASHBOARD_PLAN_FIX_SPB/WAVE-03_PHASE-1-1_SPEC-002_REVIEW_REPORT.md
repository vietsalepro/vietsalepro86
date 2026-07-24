# WAVE-03 — PHASE 1.1: ĐÁNH GIÁ SPEC-002 (Audit Architecture)

| Trường | Giá trị |
|---|---|
| Prompt ID | WAVE‑03‑PHASE‑1‑1‑001 |
| Ngày | 2026-07-24 |
| Agent | Engineering Execution Agent |
| Đối tượng đánh giá | `SPEC-002_AUDIT_ARCHITECTURE_SPECIFICATION.md` |
| Trạng thái | HOÀN THÀNH |
| Quyết định được ủy quyền | CTA (Chief Technical Advisor) thay mặt Production Owner |

---

## 1. TÓM TẮT SPEC-002 (Dành cho Production Owner)

### SPEC-002 là gì?
SPEC-002 định nghĩa **kiến trúc nhật ký kiểm toán (Audit Architecture)** toàn hệ thống của VietSalePro. Đây là bản thiết kế nền tảng quy định cách ghi, lưu trữ, truy vấn và bảo vệ các sự kiện quan trọng trong hệ thống.

### Tại sao cần?
Sự cố `delete-tenant` HTTP 500 cho thấy lỗi cốt lõi: nhật ký kiểm toán bị ràng buộc vào các đối tượng đang tồn tại (tenant, user, v.v.). Khi đối tượng bị xóa, trigger ghi audit không thể chèn dòng vì `tenant_id` còn là khóa ngoại (FK) tới `tenants(id)`. Kết quả là xóa thất bại và lịch sử kiểm toán có thể bị mất.

### SPEC-002 giải quyết vấn đề gì?
- **Audit Independence**: audit không phụ thuộc vào sự tồn tại của đối tượng.
- **Immutability**: audit ghi một chiều (append-only), không sửa/xóa sau khi seal.
- **Traceability**: mỗi bản ghi có `correlation_id`, `actor`, `target_type`, `target_id`, snapshots trước/sau, và chuỗi hash chống giả mạo.
- **Unified model**: thống nhất business audit (`app_audit_log`) và admin audit (`audit_log`).

### Điểm mạnh
- Mô hình miền rõ ràng: Audit Record, Audit Context, Audit Actor, Audit Subject, Audit Event.
- Định nghĩa đầy đủ component, interface, contract, state machine, failure/recovery, security, observability.
- Ngôn ngữ trung lập công nghệ — không bắt buộc engine, table name, column type.
- Traceability tới Master Program, SPEC-001, SPEC-005 đầy đủ qua ID `SPEC-002-XXX`.

### Điểm cần lưu ý
- SPEC-002 nêu rõ nó không bao gồm migration, code, schema cụ thể. Các chi tiết đó thuộc Implementation Plan.
- Cơ sở dữ liệu hiện tại **chưa tuân thủ** hoàn toàn kiến trúc mục tiêu (vẫn còn FK, vẫn ghi audit qua trigger, chưa có hash chain). Điều này là bình thường vì SPEC chỉ là thiết kế; việc chỉnh sửa sẽ do Implementation Plan thực hiện.

---

## 2. TÀI LIỆU ĐÃ ĐỌC

| Tài liệu | Trạng thái |
|---|---|
| `VAI_TRO_TRACH_NHIEM_VIETSALEPRO.md` | ✅ Đọc |
| `NGUYEN_TAC_VIET_PROMPT_AGENT_VIETSALEPRO.md` | ✅ Đọc |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/SEMANTIC_MEMORY.md` | ✅ Đọc (thay thế .codebase-memory/SEMANTIC_MEMORY.md bị ignore) |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/ROADMAP.md` | ✅ Đọc |
| `SPEC-002_AUDIT_ARCHITECTURE_SPECIFICATION.md` | ✅ Đọc toàn bộ |
| `SPEC-001_DELETE_FRAMEWORK_ARCHITECTURE_SPECIFICATION.md` | ✅ Đọc phần liên quan (CON-012/013, DAT-004/005, FAM-005, VRF-005) |
| `SPEC-005_FOREIGN_KEY_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` | ✅ Đọc phần liên quan (audit independence, FK governance) |
| `Deletion_Audit_Architecture_Remediation_Program.md` | ✅ Đọc tóm tắt |
| `Architecture_Specification_Program.md` | ✅ Đọc tóm tắt |
| `ARCHITECTURE_SPECIFICATION_INDEX.md` | ✅ Đọc tóm tắt |

---

## 3. KẾT QUẢ XÁC MINH THỰC TẾ

### 3.1 Codebase (qua Codebase Memory MCP + grep)

| Hạng mục | SPEC-002 yêu cầu | Thực tế codebase | Khớp? |
|---|---|---|---|
| Audit Writer | Component `Audit Writer` duy nhất được phép tạo/seal bản ghi audit. | `services/auditService.ts` có `writeAuditLog` gọi Edge Function `audit-log` để insert `app_audit_log` cho các sự kiện thủ công. Tuy nhiên, nhiều bảng vẫn ghi audit qua trigger `write_audit_log()` / `audit_log_trigger()`. | ⚠️ Một phần |
| Audit Store | Append-only store, không UPDATE/DELETE. | Tồn tại `app_audit_log`, `audit_log`, `app_audit_log_partitioned`. Chưa có trigger/constraint chống UPDATE/DELETE trên các bảng audit. | ⚠️ Một phần |
| Audit Query API | Read-only, phân quyền tenant-scoped / platform-scoped. | `services/auditService.ts:getAuditLogs` đọc `app_audit_log` (tenant-scoped). `services/admin/auditAdminService.ts:getAdminAuditLogs` gọi RPC `get_admin_audit_logs` đọc `audit_log` (platform-scoped, kiểm `is_system_admin`). | ✅ Có |
| Triggers audit | `trg_audit_log_*` và `audit_log_trigger()` | Có `write_audit_log()` cho `app_audit_log` và `audit_log_trigger()`/`audit_log_trigger_system_admins()`/`audit_log_trigger_tenant_subscriptions()` cho `audit_log`. Xem `supabase/migrations/20260730000000_wave02_package02_audit_triggers.sql` và `supabase/schema.sql` dòng 33307. | ✅ Có |
| Hash chain / integrity | Tính toán `integrity_hash` và liên kết chuỗi. | Chưa thấy cột `integrity_hash`, `previous_hash` trong DB và code. | ❌ Không có |

### 3.2 Database production (qua Supabase MCP, read-only)

Project: `QLBH` (`rsialbfjswnrkzcxarnj`), Postgres 17.6.1.

| Bảng | Cột chính | FK hiện tại | Ghi chú |
|---|---|---|---|
| `app_audit_log` | id, tenant_id, user_id, table_name, record_id, action, old_data, new_data, ip_address, user_agent, created_at | `app_audit_log_tenant_id_fkey` → `tenants(id)`<br>`app_audit_log_user_id_fkey` → `users(id)`<br>`on_delete='n'` (NO ACTION) | Vẫn ràng buộc tới tenant và user. |
| `audit_log` | id, tenant_id, actor_id, action, entity_type, entity_id, old_data, new_data, ip_address, created_at | `audit_log_tenant_id_fkey` → `tenants(id)`<br>`audit_log_actor_id_fkey` → `users(id)`<br>`on_delete='n'` (NO ACTION) | `audit_log_tenant_id_fkey` vẫn tồn tại — là nguyên nhân gốc của sự cố delete-tenant. |
| `app_audit_log_partitioned` | Cùng cấu trúc với `app_audit_log` | **Không có FK** | Phù hợp với yêu cầu independence, nhưng chưa thấy code sử dụng. |

`audit_log_trigger()` hiện tại đã được fix: khi `TG_TABLE_NAME = 'tenants'` và `TG_OP = 'DELETE'`, `tenant_id` được đặt `NULL` để tránh vi phạm FK. Xem `supabase/migrations/20260715000011_fix_audit_log_trigger_tenant_delete.sql` và `supabase/schema.sql` dòng 33307-33338. Đây là bản vá triệu chứng, chưa loại bỏ FK.

### 3.3 Đối chiếu với SPEC-001 và SPEC-005

| Mối quan hệ | Đối chiếu | Kết quả |
|---|---|---|
| SPEC-001 CON-012 | SPEC-002 cung cấp mô hình audit để delete pipeline ghi intent/pre-state/outcome. | ✅ Nhất quán |
| SPEC-001 CON-013 | Audit records không FK tới entity bị xóa. | ✅ Nhất quán |
| SPEC-001 DAT-004 | `Delete Audit` độc lập với lifecycle entity. | ✅ Nhất quán |
| SPEC-001 DAT-005 | Retention của audit theo SPEC-002, không phụ thuộc entity đã xóa. | ✅ Nhất quán |
| SPEC-001 FAM-005 | Audit write failure dựa vào SPEC-002 recovery model. | ✅ Nhất quán |
| SPEC-001 VRF-005 | Audit records survive entity deletion. | ✅ Nhất quán ở mô hình SPEC-002; thực tế DB cần migration. |
| SPEC-005 FAM-006 | Audit record không được couple với operational entity qua mandatory FK. | ✅ Nhất quán; DB hiện tại vi phạm. |
| SPEC-005 VRF-005 | Audit-independence validation. | ✅ Nhất quán |

---

## 4. KHOẢNG TRỐNG / MÂU THUẪN PHÁT HIỆN

| ID | Phát hiện | Mức độ | Đề xuất khắc phục |
|---|---|---|---|
| GAP-001 | `audit_log` và `app_audit_log` vẫn có FK tới `tenants` và `users`. Vi phạm `SPEC-002-DAT-002`, `CON-005`, `SEC-003` về independence. | Critical | Trong Implementation Plan: xóa FK, chuyển `tenant_id`/`user_id`/`actor_id` thành non-FK text/uuid lưu giá trị định danh, thêm lifecycle marker. |
| GAP-002 | Việc ghi audit vẫn phụ thuộc nhiều vào database triggers (`write_audit_log`, `audit_log_trigger`). Vi phạm `SPEC-002-WFL-003` và `CST-004`. | Major | Implementation Plan chuyển logic ghi audit vào explicit `Audit Writer` (Edge Function / service / RPC) và chỉ giữ trigger làm guard thuần túy nếu cần. |
| GAP-003 | Chưa có trigger/constraint nào trên `audit_log`/`app_audit_log` ngăn UPDATE/DELETE. Vi phạm `CON-002/003`, `SEC-003`. | Major | Thêm `BEFORE UPDATE OR DELETE` trigger hoặc `REVOKE` quyền; chỉ `Audit Retention Manager` được phép purge theo policy. |
| GAP-004 | Chưa có cột `integrity_hash` / `previous_hash` và verifier. Vi phạm `DOM-001`, `CON-016`, `VRF-006`. | Minor | Implementation Plan bổ sung cột và scheduled verifier/alert. |
| GAP-005 | `app_audit_log_partitioned` tồn tại, không có FK, nhưng chưa thấy code path nào sử dụng. | Minor | Quyết định trong Implementation Plan: sử dụng partitioned table hoặc loại bỏ. |
| GAP-006 | `auditService.ts` `getAuditLogs` truy vấn `app_audit_log` bằng `supabase.from`, chưa gọi RPC `get_audit_logs` với phân quyền mạnh. | Minor | Đánh giá lại trong Implementation Plan; xem xét chuyển sang RPC security definer. |

**Phân loại tổng quan:**
- 1 Critical, 2 Major, 3 Minor.
- Tất cả gaps đều nằm ở **thực thi** hiện tại, không phải lỗi logic của SPEC-002.

---

## 5. ĐÁNH GIÁ TỔNG THỂ

| Tiêu chí | Đánh giá | Ghi chú |
|---|---|---|
| Phù hợp Master Program | ✅ | Các nguyên tắc audit independence, immutability, append-only được phản ánh đầy đủ. |
| Phù hợp Architecture Specification Program | ✅ | Đầy đủ 26 section bắt buộc, identifier, metadata, traceability. |
| Phù hợp thực tế codebase | ✅ | Có `auditService.ts`, `auditAdminService.ts`, `audit-log` Edge Function, `get_admin_audit_logs` RPC, các trigger audit. Mô hình conceptual khớp với hướng triển khai. |
| Phù hợp thực tế database | ❌ | DB production vẫn còn FK và trigger-based audit; chưa đạt independence/immutability. Đây là điểm cần remediation. |
| Nhất quán với SPEC-001 | ✅ | Các contract CON-012/013, DAT-004/005, FAM-005, VRF-005 tham chiếu đúng SPEC-002. |
| Nhất quán với SPEC-005 | ✅ | FK governance hỗ trợ audit independence, không mâu thuẫn. |
| Rủi ro nếu Baseline | Trung bình | Spec tốt, nhưng Implementation Plan sẽ phải xử lý nhiều thay đổi schema và trigger. |

---

## 6. KHUYẾN NGHỊ

- ✅ **APPROVE — SPEC-002 có thể được Baseline ngay.**

### Lý do
1. SPEC-002 là bản thiết kế kiến trúc hợp lệ, đầy đủ, trung lập công nghệ.
2. Không có mâu thuẫn nội tại hoặc với Master Program / Architecture Specification Program.
3. Các gap phát hiện là ở **hiện thực hiện tại**, không phải ở bản thiết kế. Việc baseline SPEC-002 sẽ tạo cơ sở để các Implementation Plan khắc phục gap theo đúng hướng.
4. SPEC-001 đang chờ SPEC-002 baseline để tiếp tục; việc trì hoãn sẽ chặn tiến độ Wave-03.

### Kế hoạch đề xuất sau khi Baseline
1. CTA ký Baseline SPEC-002.
2. Cập nhật `ARCHITECTURE_SPECIFICATION_INDEX.md` (nếu cần) và `ROADMAP.md` 1.2 → "ĐANG CHỜ PHÊ DUYỆT" đã hoàn thành.
3. Chuyển sang Phase 1.3 đánh giá SPEC-003 hoặc bắt đầu lập Implementation Plan cho SPEC-002 tùy Roadmap.

---

## 7. BÁO CÁO CHO PRODUCTION OWNER (Tóm tắt không kỹ thuật)

**Chủ đề:** Đánh giá bản thiết kế kiến trúc nhật ký kiểm toán (SPEC-002).

**Tình hình:**
- SPEC-002 đã được soạn thảo đầy đủ, đúng chuẩn governance.
- Bản thiết kế nêu rõ: nhật ký kiểm toán phải độc lập với dữ liệu nghiệp vụ, không bị xóa/sửa sau khi ghi, và có thể truy vết ngược mọi hành động.
- Quá trình kiểm chứng cho thấy hệ thống **hiện tại** chưa đáp ứng hết các yêu cầu này (ví dụ: còn khóa ngoại từ bảng audit sang bảng tenant/user, còn ghi audit qua trigger). Đây là điều dự kiến vì SPEC-002 chỉ là bản thiết kế; việc sửa code/schema sẽ làm sau.

**Khuyến nghị:**
- Phê duyệt SPEC-002 để trở thành **Baseline** (bản thiết kế chuẩn).
- Sau đó, team sẽ lập kế hoạch triển khai chi tiết để loại bỏ khóa ngoại audit, chuyển ghi audit ra khỏi trigger, và thêm cơ chế chống sửa/xóa.

**Rủi ro nếu không phê duyệt:**
- Chậm tiến độ Wave-03.
- SPEC-001 (Delete Framework) không có nền tảng audit để dựa vào.

**Rủi ro nếu phê duyệt mà không có Implementation Plan rõ ràng:**
- Các khóa ngoại và trigger hiện tại có thể tiếp tục gây lỗi khi xóa tenant/user.
- Cần đảm bảo Implementation Plan được lập và phê duyệt trước khi can thiệp production.

---

## 8. BẰNG CHỨNG (EVIDENCE)

### 8.1 Codebase Memory MCP
- `search_graph` tìm `writeAuditLog`, `getAuditLogs`, `getAdminAuditLogs`: xác nhận các component audit tồn tại.
- `search_graph` tìm `audit_log_trigger`, `trg_audit_log_*`: xác nhận các trigger audit hiện có.

### 8.2 Supabase MCP (read-only)
- `list_projects` xác định project production `rsialbfjswnrkzcxarnj`.
- `execute_sql` truy vấn `information_schema.columns` cho `audit_log`, `app_audit_log`, `app_audit_log_partitioned`.
- `execute_sql` truy vấn `pg_constraint` xác nhận FK `audit_log_tenant_id_fkey`, `audit_log_actor_id_fkey`, `app_audit_log_tenant_id_fkey`, `app_audit_log_user_id_fkey`.
- `execute_sql` truy vấn `information_schema.triggers` xác nhận không có trigger bảo vệ UPDATE/DELETE trên bảng audit.

### 8.3 File tham chiếu
- `services/auditService.ts` — `writeAuditLog` (dòng 49) và `getAuditLogs` (dòng 93).
- `services/admin/auditAdminService.ts` — `getAdminAuditLogs` (dòng 123).
- `supabase/functions/audit-log/index.ts` — Edge Function ghi `app_audit_log`.
- `supabase/schema.sql` dòng 33307-33338 — định nghĩa `audit_log_trigger()`.
- `supabase/migrations/20260715000011_fix_audit_log_trigger_tenant_delete.sql` — bản vá tenant_id NULL khi xóa tenant.
- `supabase/migrations/20260730000000_wave02_package02_audit_triggers.sql` — `get_admin_audit_logs` RPC và `audit_log_trigger_system_admins`.

---

## 9. LƯU Ý VỀ PHẠM VI

- Không có thay đổi mã nguồn, schema, migration, hoặc SPEC nào trong quá trình đánh giá.
- Khuyến nghị phê duyệt được đưa ra cho CTA/Production Owner; việc ký Baseline cần được thực hiện bởi CTA theo ủy quyền.
