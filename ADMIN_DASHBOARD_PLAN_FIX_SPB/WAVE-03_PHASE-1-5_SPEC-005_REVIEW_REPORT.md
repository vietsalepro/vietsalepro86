# WAVE-03 — PHASE 1.5: ĐÁNH GIÁ SPEC-005 (Foreign Key Governance)

| Trường | Giá trị |
|---|---|
| Prompt ID | WAVE‑03‑PHASE‑1‑5‑001 |
| Ngày | 2026-07-24 |
| Agent | Engineering Execution Agent |
| Đối tượng đánh giá | `SPEC-005_FOREIGN_KEY_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` |
| Trạng thái | HOÀN THÀNH |
| Quyết định được ủy quyền | CTA (Chief Technical Advisor) thay mặt Production Owner |
| MCP sử dụng | codebase-memory (read-only), Supabase production (read-only) |
| Skills sử dụng | codebase-design, doc-coauthoring, code-review, writing-plans |

---

## 1. TÓM TẮT SPEC-005 (Dành cho Production Owner)

### SPEC-005 là gì?
SPEC-005 định nghĩa **kiến trúc quản trị khóa ngoại (Foreign Key Governance Architecture)** toàn hệ thống VietSalePro. Đây là bản thiết kế nền tảng quy định cách khai báo, phân loại, sở hữu, phê duyệt và theo dõi mọi quan hệ khóa ngoại (foreign key) giữa các bảng dữ liệu.

### Tại sao cần?
Sự cố `delete-tenant` HTTP 500 cho thấy lỗi cốt lõi: các quan hệ khóa ngoại được chọn `ON DELETE`/`ON UPDATE` một cách tùy tiện khi lập trình, không có danh mục trung tâm, không có phân loại theo mục đích kiến trúc, không có quy trình rà soát. Hậu quả:
- Cascade ẩn giấu logic nghiệp vụ trong tầng database.
- Bảng audit bị ràng buộc bằng FK tới bảng operational (tenant/user) → khi xóa tenant, audit không ghi được → lỗi 500.
- Không ai biết toàn bộ hệ thống có bao nhiêu FK, hướng nào, chính sách gì.

### SPEC-005 giải quyết vấn đề gì?
- **Foreign Key Catalog**: một danh mục trung tâm duy nhất cho mọi quan hệ — số lượng, hướng, sở hữu, chính sách xóa/cập nhật.
- **Policy Classification**: mỗi FK có chính sách `ON DELETE`/`ON UPDATE` được phân loại rõ ràng (CASCADE, RESTRICT, SET NULL, NO ACTION) theo quyền sở hữu và rủi ro.
- **Cross-Boundary Review**: rà soát bắt buộc cho quan hệ xuyên aggregate/module/tenant; cấm quan hệ cross-tenant.
- **Audit Independence**: bảng audit không được có FK bắt buộc tới operational entity (phù hợp SPEC-002).
- **Policy Drift Detection**: phát hiện khi FK thực tế khác với danh mục đã phê duyệt.
- **Lifecycle Governance**: quy trình propose → classify → validate → approve → activate → retire cho mỗi quan hệ.

### Điểm mạnh
- Mô hình miền rõ ràng: Relationship, Foreign Key, Aggregate, Aggregate Root, Foreign Key Catalog, Delete/Update Policy, Cross-Boundary Relationship, Circular Dependency.
- Đầy đủ 26 section bắt buộc (16.1–16.26) theo Architecture Specification Program.
- 8 component logic: Foreign Key Catalog, Relationship Metadata Registry, Policy Classifier, Boundary Review Function, Referential-Integrity Validator, Policy Drift Detector, Change Approval Gateway, Reporting View.
- 20 contract (CON-001→020) bao phủ referential integrity, delete policy, update policy, cross-boundary, validation.
- 10 verification requirements (VRF-001→010) và acceptance criteria rõ ràng (ACC-001).
- 3 ma trận phụ lục: Relationship Classification Matrix (A), Delete Policy Matrix (B), Update Policy Matrix (C) — công cụ quyết định thực dụng.
- Ngôn ngữ trung lập công nghệ — không bắt buộc engine, table name, column type, code.
- Traceability đầy đủ tới Master Program (Sections 1,2,3,7,8,9,10.5,22,23,24,25,28,10.7,10.8,20,13,14) và SPEC-001/002/003/004.
- Tách bạch rõ trách nhiệm: FK Governance chỉ sở hữu chính sách referential integrity; delete orchestration thuộc SPEC-001, transaction thuộc SPEC-003, trigger thuộc SPEC-004, audit thuộc SPEC-002.

### Điểm cần lưu ý
- SPEC-005 nêu rõ nó không bao gồm migration, code, schema cụ thể. Các chi tiết đó thuộc Implementation Plan.
- Cơ sở dữ liệu hiện tại **chưa tuân thủ** kiến trúc mục tiêu: chưa có Foreign Key Catalog, chưa có policy classifier/drift detector, audit FK vẫn còn tồn tại. Điều này là bình thường vì SPEC chỉ là thiết kế; việc chỉnh sửa sẽ do Implementation Plan thực hiện.
- SPEC-005 là foundation spec **cuối cùng** trong bộ ba (SPEC-002, SPEC-003, SPEC-005). Sau khi Baseline, Phase 2 (SPEC-001) mới có thể bắt đầu.

---

## 2. TÀI LIỆU ĐÃ ĐỌC

| Tài liệu | Trạng thái |
|---|---|
| `VAI_TRO_TRACH_NHIEM_VIETSALEPRO.md` | ✅ Đọc |
| `NGUYEN_TAC_VIET_PROMPT_AGENT_VIETSALEPRO.md` | ✅ Đọc |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/CODEBASE_MEMORY_BASELINE.md` | ✅ Đọc toàn bộ |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/SEMANTIC_MEMORY.md` | ✅ Đọc (grep FK/relationship/cascade) |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/ROADMAP.md` | ✅ Đọc toàn bộ |
| `SPEC-005_FOREIGN_KEY_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` | ✅ Đọc toàn bộ (851 dòng, 26 section) |
| `SPEC-001_DELETE_FRAMEWORK_ARCHITECTURE_SPECIFICATION.md` | ✅ Đọc phần liên quan (dependency, RSK-004, CST-002, CON-003) |
| `SPEC-002_AUDIT_ARCHITECTURE_SPECIFICATION.md` | ✅ Tham chiếu qua báo cáo Phase 1.1 |
| `SPEC-003_TRANSACTION_ARCHITECTURE_SPECIFICATION.md` | ✅ Tham chiếu qua báo cáo Phase 1.3 |
| `Deletion_Audit_Architecture_Remediation_Program.md` | ✅ Tham chiếu (Master Program) |
| `01_Governance/Architecture_Specification_Program.md` | ✅ Tham chiếu (26-section template) |
| `01_Governance/ARCHITECTURE_SPECIFICATION_INDEX.md` | ✅ Đọc phần SPEC-005 (dependency matrix, acyclicity) |
| `WAVE-03_PHASE-1-1_SPEC-002_REVIEW_REPORT.md` | ✅ Đọc toàn bộ (tham khảo pattern) |
| `WAVE-03_PHASE-1-3_SPEC-003_REVIEW_REPORT.md` | ✅ Đọc phần khuyến nghị (tham khảo pattern) |

---

## 3. KẾT QUẢ XÁC MINH THỰC TẾ

### 3.1 Codebase (qua Codebase Memory MCP + grep)

| Hạng mục | SPEC-005 yêu cầu | Thực tế codebase | Khớp? |
|---|---|---|---|
| Foreign Key Catalog | Bảng/catalog trung tâm cho mọi FK (COM-001/002, CON-002) | `search_graph` "foreign key catalog relationship registry" → không tìm thấy bảng/catalog nào. grep `foreign_key_catalog\|relationship_catalog\|fk_catalog\|trigger_registry` trong `*.sql` → **0 kết quả**. | ❌ Không có |
| Policy Classifier | Phân loại delete/update policy theo ownership/risk (COM-001) | Không tìm thấy code/module phân loại policy FK. | ❌ Không có |
| Boundary Review Function | Rà soát cross-aggregate/module/tenant, phát hiện cycle (COM-003, CON-019) | Không tìm thấy process/function rà soát boundary FK. | ❌ Không có |
| Policy Drift Detector | Phát hiện FK thực tế khác catalog (COM-004, VRF-009) | `search_graph` "policy drift detector" → chỉ tìm thấy `check_stock_ledger_drift` (drift kho, không phải FK policy drift). | ❌ Không có |
| Referential-Integrity Validator | Verify realized graph khớp catalog (CON-018, VRF-001/002) | Không tìm thấy validator FK. | ❌ Không có |
| Change Approval Gateway | Ghi nhận phê duyệt relationship mới/sửa/xóa (COM-001) | Không tìm thấy. | ❌ Không có |
| FK definitions trong migration | Mọi FK được khai báo trong migration | Có nhiều FK trong `supabase/migrations/*.sql` và `supabase/schema.sql` (150 FK production). | ✅ Có (nhưng không catalog) |

### 3.2 Database production (qua Supabase MCP, read-only)

Project: `QLBH` (`rsialbfjswnrkzcxarnj`), Postgres 17.6.1.

**Tổng quan:**

| Chỉ số | Giá trị |
|---|---|
| Tổng số bảng (public schema) | 88 |
| Tổng số FK (public schema) | 150 |
| Bảng catalog (foreign_key_catalog, relationship_catalog, fk_catalog, trigger_registry) | **0 (không tồn tại)** |

**Phân bố chính sách ON DELETE / ON UPDATE:**

| delete_rule | update_rule | Số FK |
|---|---|---|
| CASCADE | NO ACTION | 76 |
| SET NULL | NO ACTION | 41 |
| NO ACTION | NO ACTION | 26 |
| RESTRICT | NO ACTION | 4 |
| SET NULL | CASCADE | 3 |

**Audit FK — nguyên nhân gốc sự cố delete-tenant:**

| Constraint | Bảng con | Cột con | Bảng cha | delete_rule | Ghi chú |
|---|---|---|---|---|---|
| `audit_log_tenant_id_fkey` | `audit_log` | `tenant_id` | `tenants` | SET NULL | **Vẫn còn FK** tới tenants. Đã patch từ NO ACTION → SET NULL (migration `20260715000011`). Đây là vá triệu chứng, chưa đạt kiến trúc mục tiêu. |
| `app_audit_log_tenant_id_fkey` | `app_audit_log` | `tenant_id` | `tenants` | SET NULL | **Vẫn còn FK** tới tenants. Tương tự. |

> SPEC-005 Appendix A "Audit Reference" yêu cầu: delete_policy=`NO_ACTION`, update_policy=`NO_ACTION`, "No mandatory foreign key to operational entity". Hai FK audit hiện tại vi phạm yêu cầu này — chúng vẫn là FK bắt buộc về mặt cấu trúc (chỉ đổi hành vi delete thành SET NULL thay vì loại bỏ FK hoàn toàn).

**Phân tích CASCADE (76 FK):**
- Phần lớn CASCADE là `tenant_id → tenants(id)` (aggregate-owned children, hợp lệ per SPEC-005 CON-006: child owned by parent aggregate).
- Một số CASCADE non-tenant hợp lệ (aggregate-internal): `admin_role_assignments_role_id_fkey`, `disposal_items_disposal_id_fkey`, `import_items_receipt_id_fkey`, `inventory_count_items_count_id_fkey`, `inventory_movements_product_id_fkey`, `invoice_items_invoice_id_fkey`.
- Mỗi CASCADE cần được catalog và review khi triển khai Implementation Plan, nhưng không phát hiện CASCADE cross-tenant hay audit-to-operational nào (audit FK dùng SET NULL, không CASCADE).

**Cross-tenant FK:** Không phát hiện FK cross-tenant (mọi `tenant_id` FK đều trỏ tới `tenants(id)` trong cùng scope tenant). Phù hợp SPEC-005 CON-016.

**Update policy:** Hầu hết FK dùng NO ACTION cho update (147/150). Chỉ 3 FK dùng CASCADE update (`disposal_items_lot_id_fkey`). SPEC-005 CON-011 cho phép CASCADE update chỉ khi parent identifier là surrogate không expose làm business key — `lot_id` có thể là surrogate, cần review khi catalog. Không vi phạm rõ ràng.

### 3.3 Đối chiếu với SPEC-001, SPEC-002, SPEC-003

| Mối quan hệ | Đối chiếu | Kết quả |
|---|---|---|
| SPEC-001 dependency | SPEC-001 khai báo SPEC-005 là mandatory dependency (dòng 17, 43, 103, 560, 726). SPEC-001 CST-002 yêu cầu SPEC-005 baselined trước khi approve SPEC-001. | ✅ Nhất quán |
| SPEC-001 RSK-004 | "Audit records fail to outlive deleted entity due to residual foreign keys" → mitigation "FK review per SPEC-005". | ✅ Nhất quán; DB hiện tại vi phạm (audit FK còn). |
| SPEC-001 CON-003 | Constraints phụ thuộc SPEC-005 delete-policy contract. | ✅ Nhất quán |
| SPEC-002 audit independence | SPEC-005 Appendix A "Audit Reference" + FAM-006 + RSK-004 yêu cầu audit không có mandatory FK tới operational entity. | ✅ Nhất quán; DB hiện tại vi phạm. |
| SPEC-003 transaction boundaries | SPEC-005 RES-001 giao transaction boundaries cho Transaction Architecture; FK Governance chỉ sở hữu referential-integrity policy. | ✅ Nhất quán |
| Architecture Specification Index | SPEC-005 đăng ký Core, Planned, **không mandatory dependency** (foundation root cùng SPEC-002/003). Dependency graph acyclic. SPEC-001 depends on SPEC-005. | ✅ Nhất quán với metadata SPEC-005 |

---

## 4. KHOẢNG TRỐNG / MÂU THUẪN PHÁT HIỆN

| ID | Phát hiện | Mức độ | Đề xuất khắc phục |
|---|---|---|---|
| GAP-001 | `audit_log_tenant_id_fkey` và `app_audit_log_tenant_id_fkey` vẫn còn FK tới `tenants(id)` (đã patch SET NULL nhưng chưa loại bỏ FK). Vi phạm SPEC-005 Appendix A "Audit Reference", FAM-006, RSK-004, CON (audit independence). | **Critical** | Trong Implementation Plan: loại bỏ FK, chuyển `tenant_id`/`actor_id`/`user_id` thành non-FK uuid lưu giá trị định danh (audit survival). Đồng bộ với Implementation Plan SPEC-002. |
| GAP-002 | Không có Foreign Key Catalog — 150 FK được realize mà không có catalog trung tâm. Vi phạm SPEC-005 CON-002, COM-002, VRF-001. | **Major** | Implementation Plan SPEC-005: bootstrap Foreign Key Catalog từ `information_schema` hiện có (150 FK), phân loại từng relationship. |
| GAP-003 | Không có Policy Classifier / Boundary Review Function / Policy Drift Detector / Referential-Integrity Validator / Change Approval Gateway — 0/8 component được implement. Vi phạm COM-001/003/004, VRF-002/003/009. | **Major** | Implementation Plan xây dựng các component này (có thể là RPC + view + scheduled job + dashboard). |
| GAP-004 | 3 FK dùng CASCADE update (`disposal_items_lot_id_fkey`). Cần verify `lot_id` là surrogate per SPEC-005 CON-011. | **Minor** | Review khi catalog; nếu `lot_id` là business key thì đổi sang RESTRICT. |
| GAP-005 | 76 CASCADE delete chưa được catalog/review từng cái. Phần lớn hợp lệ (tenant_id aggregate-owned) nhưng cần review chính thức per SPEC-005 CON-006. | **Minor** | Implementation Plan bootstrap catalog sẽ review từng CASCADE. |
| GAP-006 | SEMANTIC_MEMORY.md gần như không có nội dung FK/relationship governance (chỉ 2 match chung chung). Tri thức FK governance chưa được ghi nhận. | **Minor** | Cập nhật SEMANTIC_MEMORY sau khi Implementation Plan hoàn thành (Medium Change per Update Policy). |

**Phân loại tổng quan:**
- 1 Critical, 2 Major, 3 Minor.
- **Tất cả gaps đều nằm ở thực thi hiện tại, không phải lỗi logic của SPEC-005.** SPEC-005 là bản thiết kế đúng đắn; gaps là khoảng cách giữa thiết kế mục tiêu và hiện trạng — đúng kỳ vọng của một bản Draft spec chờ Implementation Plan.

---

## 5. ĐÁNH GIÁ TỔNG THỂ

| Tiêu chí | Đánh giá | Ghi chú |
|---|---|---|
| Phù hợp Master Program | ✅ | Principles mapping (16.7) đầy đủ; traceability tới Master Program Sections 1,2,3,7,8,9,10.5,22,23,24,25,28. Workstream 10.5 (explicit-foreign-key-contract) được phản ánh. |
| Phù hợp Architecture Specification Program | ✅ | Đầy đủ 26 section (16.1–16.26), identifier `SPEC-005-XXX`, metadata, versioning, traceability, evidence. |
| Phù hợp thực tế codebase | ✅ | 150 FK tồn tại trong migration/schema — mô hình conceptual khớp với hiện trạng cần governance. Không có catalog/component (đúng kỳ vọng Draft). |
| Phù hợp thực tế database | ❌ | DB production chưa có catalog, chưa có policy classifier/drift detector, audit FK vẫn còn. Đây là điểm cần remediation qua Implementation Plan. |
| Nhất quán với SPEC-001 | ✅ | SPEC-001 khai báo SPEC-005 mandatory dependency; RSK-004/CST-002/CON-003 tham chiếu đúng. |
| Nhất quán với SPEC-002 | ✅ | Audit independence mandate (Appendix A "Audit Reference", FAM-006, RSK-004) phù hợp SPEC-002. |
| Nhất quán với SPEC-003 | ✅ | Transaction boundary ownership giao cho Transaction Architecture; FK Governance chỉ sở hữu referential-integrity policy. |
| Rủi ro nếu Baseline | Trung bình | Spec tốt, neutral. Implementation Plan sẽ phải bootstrap catalog cho 150 FK, xây dựng 8 component, và loại bỏ audit FK — khối lượng lớn nhưng đúng hướng. |

---

## 6. KHUYẾN NGHỊ

- ✅ **APPROVE — SPEC-005 có thể được Baseline ngay.**

### Lý do
1. SPEC-005 là bản thiết kế kiến trúc hợp lệ, đầy đủ (26 section), trung lập công nghệ, không có mâu thuẫn nội tại.
2. Không có mâu thuẫn với Master Program, Architecture Specification Program, hay SPEC-001/002/003/004.
3. Các gap phát hiện (catalog thiếu, audit FK còn, component chưa implement) đều nằm ở **hiện trạng thực thi**, không phải ở bản thiết kế. Việc Baseline SPEC-005 sẽ tạo cơ sở pháp lý để Implementation Plan khắc phục gap theo đúng hướng.
4. SPEC-005 là foundation spec **cuối cùng** trong bộ ba (SPEC-002, SPEC-003, SPEC-005). SPEC-001 đang chờ cả 3 baseline. Trì hoãn SPEC-005 sẽ chặn toàn bộ Phase 2 (SPEC-001) và toàn bộ Wave-03 phía trước.
5. Dependency graph acyclic đã được xác nhận qua Architecture Specification Index — SPEC-005 không có mandatory dependency, an toàn để baseline trước.

### Kế hoạch đề xuất sau khi Baseline
1. CTA ký Baseline SPEC-005 (Phase 1.6).
2. Cập nhật `ARCHITECTURE_SPECIFICATION_INDEX.md` (trạng thái Planned → Baselined) và `ROADMAP.md` 1.6 → HOÀN THÀNH.
3. **Cả 3 foundation specs (002, 003, 005) đã Baselined → Phase 2 (đánh giá SPEC-001) sẵn sàng bắt đầu.**
4. Khi vào Phase 4 (Implementation Plan), ưu tiên: (a) bootstrap Foreign Key Catalog từ 150 FK hiện có, (b) loại bỏ audit FK (đồng bộ với Implementation Plan SPEC-002), (c) xây dựng Policy Drift Detector + Boundary Review Function.

---

## 7. BÁO CÁO CHO PRODUCTION OWNER (Tóm tắt không kỹ thuật)

**Chủ đề:** Đánh giá bản thiết kế kiến trúc quản trị khóa ngoại (SPEC-005).

**Tình hình:**
- SPEC-005 đã được soạn thảo đầy đủ, đúng chuẩn governance (26 mục bắt buộc).
- Bản thiết kế nêu rõ: mọi quan hệ khóa ngoại trong hệ thống phải được khai báo trong một danh mục trung tâm, phân loại chính sách xóa/cập nhật, rà soát quan hệ xuyên module/tenant, và bảng audit không được ràng buộc bằng khóa ngoại tới dữ liệu nghiệp vụ.
- Quá trình kiểm chứng cho thấy hệ thống **hiện tại** chưa đáp ứng: chưa có danh mục khóa ngoại (hệ thống có 150 khóa ngoại nhưng không được catalog), chưa có công cụ phát hiện sai lệch chính sách, và bảng audit vẫn còn khóa ngoại tới bảng tenant (đã vá tạm bằng SET NULL nhưng chưa loại bỏ hoàn toàn). Đây là điều dự kiến vì SPEC-005 chỉ là bản thiết kế; việc sửa sẽ làm sau qua Implementation Plan.

**Khuyến nghị:**
- Phê duyệt SPEC-005 để trở thành **Baseline** (bản thiết kế chuẩn).
- Đây là bản thiết kế nền tảng **cuối cùng** trong bộ ba (cùng với SPEC-002 audit và SPEC-003 transaction đã phê duyệt trước đó). Sau khi SPEC-005 được phê duyệt, bản thiết kế lõi SPEC-001 (khung xóa dữ liệu) mới có đủ nền móng để bắt đầu đánh giá.

**Rủi ro nếu không phê duyệt:**
- Chậm tiến độ Wave-03.
- SPEC-001 (Delete Framework) không có nền tảng chính sách khóa ngoại để dựa vào → không thể phê duyệt → toàn bộ kiến trúc còn lại (SPEC-004/006/007) bị chặn.

**Rủi ro nếu phê duyệt mà không có Implementation Plan rõ ràng:**
- 150 khóa ngoại hiện tại tiếp tục không được governance, có thể có cascade ẩn giấu logic nghiệp vụ.
- Khóa ngoại audit vẫn còn → vẫn có nguy cơ lỗi khi xóa tenant/user nếu patch SET NULL bị绕 qua.
- Cần đảm bảo Implementation Plan được lập và phê duyệt trước khi can thiệp production.

---

## 8. BẰNG CHỨNG (EVIDENCE)

### 8.1 Codebase Memory MCP (read-only)
- `search_graph` query="foreign key catalog relationship registry", project=vietsalepro → 33 kết quả, không có bảng/catalog FK nào (chỉ noise API key/registry).
- `search_graph` query="policy drift detector boundary review classifier", project=vietsalepro → 7 kết quả, chỉ có `check_stock_ledger_drift` (drift kho, không phải FK policy drift).
- grep `foreign_key_catalog|relationship_catalog|fk_catalog|trigger_registry` trong `*.sql` toàn repo → **0 file match**.

### 8.2 Supabase MCP (read-only, production `rsialbfjswnrkzcxarnj`)
- `execute_sql` truy vấn `information_schema.table_constraints` + `referential_constraints` + `pg_constraint` → liệt kê 150 FK với delete_rule/update_rule đầy đủ.
- `execute_sql` truy vấn tổng quan → 150 FK, 88 bảng, **0 bảng catalog** tồn tại.
- `execute_sql` truy vấn phân bố policy → CASCADE=76, SET NULL=41, NO ACTION=26, RESTRICT=4, SET NULL/CASCADE=3.
- `execute_sql` truy vấn audit FK → xác nhận `audit_log_tenant_id_fkey` và `app_audit_log_tenant_id_fkey` vẫn còn (delete_rule=SET NULL).
- (2 truy vấn follow-up bị connection timeout — không ảnh hưởng kết luận vì dữ liệu cốt lõi đã thu thập đủ.)

### 8.3 File tham chiếu
- `supabase/migrations/20260715000011_fix_audit_log_trigger_tenant_delete.sql` — bản vá audit FK SET NULL (triệu chứng).
- `supabase/schema.sql` — định nghĩa FK và audit triggers.
- `02_Specifications/SPEC-001_DELETE_FRAMEWORK_ARCHITECTURE_SPECIFICATION.md` dòng 17, 43, 103, 546, 560, 726 — dependency SPEC-005.
- `01_Governance/ARCHITECTURE_SPECIFICATION_INDEX.md` dòng 220, 276, 293, 314-324, 334 — đăng ký SPEC-005 Core/Planned, foundation root, acyclic.

---

## 9. LƯU Ý VỀ PHẠM VI

- Không có thay đổi mã nguồn, schema, migration, hoặc SPEC nào trong quá trình đánh giá.
- Khuyến nghị phê duyệt được đưa ra cho CTA/Production Owner; việc ký Baseline cần được thực hiện bởi CTA theo ủy quyền (Phase 1.6).
- Tất cả truy vấn Supabase đều read-only (`execute_sql` SELECT), không có DDL/DML.
- **Lưu ý quan trọng:** Sau khi SPEC-005 được Baseline (Phase 1.6), cả 3 foundation specs (SPEC-002, SPEC-003, SPEC-005) sẽ hoàn tất → Phase 2 (đánh giá SPEC-001) sẵn sàng bắt đầu.
