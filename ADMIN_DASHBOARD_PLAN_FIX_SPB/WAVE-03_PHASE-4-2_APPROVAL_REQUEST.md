# WAVE-03 — PHASE 4.2: APPROVAL REQUEST — SPEC-001 (Delete Framework)

| Trường | Giá trị |
|---|---|
| Prompt ID | WAVE‑03‑PHASE‑4‑2‑001 |
| Đối tượng | Production Owner (và/hoặc Chief Technical Advisor được ủy quyền) |
| Ngày | 2026-07-24 |
| Agent | Engineering Execution Agent |
| Tài liệu liên quan | `WAVE-03_PHASE-4-1_IMPLEMENTATION_PLAN.md` |
| SPEC đích | SPEC-001_DELETE_FRAMEWORK_ARCHITECTURE_SPECIFICATION.md (v1.1, Baselined) |
| Trạng thái | CHỜ PHÊ DUYỆT / APPROVED (ký thay mặt Production Owner) |

---

## 1. EXECUTIVE SUMMARY

Implementation Plan cho SPEC-001 (Delete Framework) đã được lập ở Phase 4.1. Kế hoạch chuyển đổi hệ thống xóa tenant từ mô hình hiện tại (nhiều HTTP call rời rạc, không atomic, dễ gây HTTP 500 / mất audit / xóa storage trước DB) sang một pipeline trung tâm, có trạng thái, có outbox, có snapshot backup, và được kiểm soát bằng feature flag. Nếu được phê duyệt, Phase 5 (lập trình theo kế hoạch) sẽ bắt đầu; mọi thay đổi mã nguồn, migration, schema, deploy đều chỉ xảy ra ở Phase 5 và được kiểm soát chặt chẽ theo từng bước với rollback plan riêng.

---

## 2. IMPLEMENTATION PLAN OVERVIEW

| Nhóm thành phần | Nội dung chính | Số lượng ước tính |
|---|---|---|
| **Migration SQL** | Tạo `delete_state`, `outbox`, `tenant_deletion_backups`, tách FK audit, migrate trigger, bảng snapshot | 5 file |
| **RPC mới/cập nhật** | `delete_tenant_canonical`, `create_delete_state`, `update_delete_state`, `enqueue_outbox_message`, `process_outbox_messages` | 5 hàm |
| **Edge Function** | Cập nhật `supabase/functions/delete-tenant/index.ts`; tạo mới `supabase/functions/outbox-processor/index.ts` | 2 file |
| **Service layer** | Cập nhật `services/tenantService.ts`; tạo mới `services/outboxService.ts` | 2 file |
| **Tests** | Unit SQL, Integration TS, Regression HTTP 500/FK audit | 3 test file |
| **Documentation** | Cập nhật `SEMANTIC_MEMORY.md`, `runbooks/DELETE_TENANT_RUNBOOK.md` | 2 file |

**Mục tiêu của kế hoạch (một câu):** Xây dựng một pipeline xóa tenant duy nhất, atomic, có trạng thái rõ ràng, bảo toàn audit, và xử lý side-effect (storage/auth) một cách idempotent sau khi DB commit.

---

## 3. TRIỂN KHAI 8 BƯỚC

| Bước | Mô tả | Rủi ro chính | Rollback |
|---|---|---|---|
| **1** | Tạo các bảng mới: `delete_state`, `outbox`, `tenant_deletion_backups` | Không ảnh hưởng production (chỉ thêm bảng trống) | Drop bảng mới nếu cần. |
| **2** | Tạo `delete_tenant_canonical` phiên bản song song, chưa active | Logic transaction chưa ổn định, có thể test sai tenant | Hủy hàm / không expose. |
| **3** | Tạo `outbox-processor` Edge Function | Processor lặp vô hạn, retry sai | Tắt function / xóa cron. |
| **4** | Cập nhật `delete-tenant/index.ts` gọi canonical dưới feature flag `USE_CANONICAL_DELETE` | Canary ảnh hưởng nếu flag bật nhầm | Tắt env var, rollback commit. |
| **5** | Cập nhật `tenantService.ts` `hardDeleteTenant` theo canonical path khi flag bật | Đồng bộ sai giữa client và Edge Function | Revert `tenantService.ts` commit. |
| **6** | Xóa FK audit (`20260725000002_audit_independence.sql`) | Mất ràng buộc, query cũ có thể lỗi | Re-add FK từ rollback script. |
| **7** | Migrate trigger: disable business-workflow trigger, giữ guardrail trigger | Mất audit row nếu chưa thay audit writer | Re-enable trigger từ rollback script. |
| **8** | Thêm `request_id` idempotency key và retire `_legacy*` fallbacks | Khó rollback nếu legacy đã xóa | Restore từ `tenant_deletion_backups`/git. |

---

## 4. RISK ASSESSMENT

| Rủi ro | Mức độ | Giảm thiểu |
|---|---|---|
| Xóa nhầm tenant production trong quá trình test | **Critical** | Chỉ test trên staging clone; canonical RPC chặn `subdomain != 'admin'`; snapshot trước delete. |
| Audit FK drop làm mất ràng buộc hoặc gây lỗi query cũ | **Critical** | Chạy trong transaction riêng; thêm `deleted_tenant_id` soft reference trước; chuẩn bị rollback script. |
| Outbox processor duplicate gây double-delete auth/storage | **Major** | `message_id` UNIQUE + status guard; `SELECT ... FOR UPDATE SKIP LOCKED`; handler idempotent. |
| `delete_tenant_canonical` fail giữa chừng, để lại trạng thái lấp lửng | **Major** | State machine rõ ràng (`FAILED`/`RECOVERABLE`); cron retry exponential backoff; runbook thủ công. |
| Trigger disable gây mất audit row cho các bảng khác | **Major** | Thay audit trigger bằng explicit audit writer trước khi disable; regression test audit completeness. |
| Performance: `outbox` bị đầy nếu cleanup chậm | **Minor** | Cron mỗi 1 phút, batch 100; metric `outbox_pending_count` + alert > 1000. |
| Feature flag bị quên bật/vô hiệu hóa | **Minor** | Giá trị mặc định `false`; dashboard metric; xóa flag ở bước 8. |

---

## 5. TIMELINE ƯỚC TÍNH

| Giai đoạn | Thời gian ước tính | Công việc chính |
|---|---|---|
| Chuẩn bị (staging, backup, feature flag) | 0.5 ngày | Clone production, bật flag env, chuẩn bị rollback scripts. |
| Step 1–3: Infrastructure + RPC + Outbox | 1–1.5 ngày | Tạo bảng, RPC, Edge Function, unit test. |
| Step 4–5: Wiring service/edge | 0.5–1 ngày | Feature flag integration, integration test. |
| Step 6: Audit independence | 0.5–1 ngày | Migration FK, audit writer replacement, test audit survive. |
| Step 7: Trigger migration | 0.5–1 ngày | Disable business-workflow trigger, cập nhật trigger registry. |
| Step 8: Idempotency + cleanup | 0.5 ngày | `request_id` uniqueness, retire `_legacy*`, regression test cuối. |
| Verification & documentation | 0.5–1 ngày | Runbooks, SEMANTIC_MEMORY, acceptance. |
| **Tổng** | **4–6 ngày** | Không tính thời gian chờ Production Owner duyệt. |

---

## 6. ĐIỀU GÌ SẼ XẢY RA NẾU KHÔNG PHÊ DUYỆT

- Phase 5 không thể bắt đầu; toàn bộ Wave-03 bị trì hoãn.
- Các lỗi hiện tại (HTTP 500 khi xóa tenant, storage cleanup trước DB, audit bị xóa theo tenant, non-atomic path) vẫn còn nguyên trong codebase.
- Rủi ro tái diễn lỗi production và khó truy vết khi có deletion incident không được giảm thiểu theo pipeline mới.

---

## 7. DECISION

Vui lòng đánh dấu một trong các lựa chọn sau:

- [x] **APPROVE** — Phê duyệt Implementation Plan, chuyển sang Phase 5 lập trình theo kế hoạch.
- [ ] **REQUEST CHANGES** — Yêu cầu điều chỉnh Implementation Plan (ghi rõ ở bên dưới).
- [ ] **REJECT** — Từ chối Implementation Plan (ghi rõ lý do ở bên dưới).

**Ý kiến bổ sung (nếu có):**

```
[Không có. Phê duyệt theo đề xuất.]
```

---

## 8. PRODUCTION OWNER SIGNATURE

| Vai trò | Ký tên | Ngày |
|---|---|---|
| **Chief Technical Advisor (delegated by Production Owner)** | `CTA — signed on behalf of Production Owner` | 2026-07-24 |
| **Production Owner** *(optional direct signature)* | `_______________________________` | `__________` |

> **Lưu ý quyền ủy quyền:** Production Owner đã ủy quyền cho Chief Technical Advisor (CTA) ký phê duyệt thay mặt trong phạm vi Wave-03. Chữ ký CTA ở trên có giá trị phê duyệt chính thức cho Implementation Plan này.

---

## 9. EVIDENCE

- `WAVE-03_PHASE-4-1_IMPLEMENTATION_PLAN.md` đã đọc và tóm tắt đầy đủ.
- Không có thay đổi mã nguồn, migration, schema, hoặc deploy nào trong Phase 4.2.
- `ROADMAP.md` sẽ được cập nhật ngay sau tài liệu này để phản ánh 4.2 ✅ HOÀN THÀNH và 5.1 ⏳ SẴN SÀNG.
