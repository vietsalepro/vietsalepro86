# WAVE-03 — DEPLOYMENT CHECKLIST

> Dùng để theo dõi từng bước triển khai Wave-03 lên Staging và Production.
> Cập nhật trạng thái khi hoàn thành. Không đánh dấu hoàn thành nếu chưa có bằng chứng.

---

## TIỀN KIỂM (PRE-DEPLOYMENT)

| # | Kiểm tra | Trạng thái | Bằng chứng / Ghi chú |
|---|----------|------------|----------------------|
| P1 | Wave-03 đã được PO/CTA ký `ACCEPT` | ☐ / ☐ | `WAVE-03_PHASE-6-2_ACCEPTANCE_REQUEST.md` |
| P2 | `npx tsx scripts/verify-wave03.ts` 33/33 PASS | ☐ | Log output |
| P3 | Vitest regression PASS (`tests/edge-functions`, `tests/regression`) | ☐ | `npx vitest run` output |
| P4 | pgTAP PASS (`supabase test db`) | ☐ | Test output |
| P5 | Đang ở branch `master` | ☐ | `git branch` |
| P6 | `git status` chỉ còn file Wave-03 & docs | ☐ | `git status --short` |
| P7 | Supabase CLI hoạt động (`supabase --version`) | ☐ | Phiên bản CLI |
| P8 | Đã đăng nhập (`supabase projects list`) | ☐ | Có 2 project refs |
| P9 | Feature flag `USE_CANONICAL_DELETE` / `VITE_USE_CANONICAL_DELETE` tắt | ☐ | `.env`/Vercel env screenshot |
| P10 | Backup staging tạo xong | ☐ | Backup ID / timestamp |
| P11 | Backup production tạo xong | ☐ | Backup ID / timestamp |

---

## 7.1 — COMMIT & PUSH

| # | Bước | Trạng thái | Bằng chứng |
|---|------|------------|------------|
| 1 | `git add -A` | ☑ | `git status --short` |
| 2 | `git commit -m "deploy(wave-03): ..."` | ☑ | `9878496c` |
| 3 | `git push origin master` | ☑ | `origin/master` đã nhận `9878496c` |

---

## 7.2 — STAGING: DEPLOY MIGRATIONS

Môi trường: `shbmzvfcenbybvyzclem`

| # | Bước | Trạng thái | Bằng chứng |
|---|------|------------|------------|
| 1 | `supabase link --project-ref shbmzvfcenbybvyzclem` | ☐ | Link thành công |
| 2 | `supabase migration list` ghi nhận 5 migration chờ | ☐ | Screenshot/output |
| 3 | `supabase migration up --linked` | ☐ | Log apply |
| 4 | `supabase migration list` → 5 migration `APPLIED` | ☐ | Screenshot/output |

---

## 7.3 — STAGING: DEPLOY EDGE FUNCTIONS

| # | Bước | Trạng thái | Bằng chứng |
|---|------|------------|------------|
| 1 | `supabase functions deploy outbox-processor --project-ref shbmzvfcenbybvyzclem` | ☐ | Log deploy |
| 2 | `supabase functions deploy delete-tenant --project-ref shbmzvfcenbybvyzclem` | ☐ | Log deploy |
| 3 | `supabase functions list --project-ref shbmzvfcenbybvyzclem` thấy cả 2 | ☐ | List output |
| 4 | Xác nhận `verify_jwt` setting phù hợp | ☐ | Config check |

---

## 7.4 — STAGING: VERIFICATION

| # | Kiểm tra | Trạng thái | Bằng chứng |
|---|----------|------------|------------|
| 1 | `public.delete_state` tồn tại | ☐ | `pg_tables` output |
| 2 | `public.outbox` tồn tại | ☐ | `pg_tables` output |
| 3 | `public.tenant_deletion_backups` tồn tại | ☐ | `pg_tables` output |
| 4 | `public.delete_tenant_canonical` tồn tại và `SECURITY DEFINER` | ☐ | `pg_proc` output |
| 5 | `app_audit_log.deleted_tenant_id` tồn tại | ☐ | `information_schema.columns` output |
| 6 | FK `app_audit_log_tenant_id_fkey` không còn | ☐ | `pg_constraint` output (0 dòng) |
| 7 | 3 business trigger `D` (disabled) | ☐ | `pg_trigger` output |
| 8 | 2 guardrail trigger `O` (enabled) | ☐ | `pg_trigger` output |
| 9 | `outbox-processor` Edge Function hoạt động | ☐ | Invoke test / log |
| 10 | `delete-tenant` legacy path vẫn trả 200 khi flag tắt | ☐ | Smoke test log |

---

## CỔNG PHÊ DUYỆT PRODUCTION

| # | Điều kiện | Ký tên | Ngày |
|---|-----------|--------|------|
| 1 | Staging deploy & verify thành công | ☐ | |
| 2 | Backup Production đã tạo | ☐ | |
| 3 | Cho phép deploy Production | ☐ | |
| 4 | Rollback window đã xác định | ☐ | |

---

## 7.5 — PRODUCTION: DEPLOY MIGRATIONS

Môi trường: `rsialbfjswnrkzcxarnj`

| # | Bước | Trạng thái | Bằng chứng |
|---|------|------------|------------|
| 1 | `supabase link --project-ref rsialbfjswnrkzcxarnj` | ☐ | Link thành công |
| 2 | `supabase migration list` ghi nhận 5 migration chờ | ☐ | Output |
| 3 | `supabase migration up` | ☐ | Log apply |
| 4 | `supabase migration list` → 5 migration `APPLIED` | ☐ | Output |

---

## 7.6 — PRODUCTION: DEPLOY EDGE FUNCTIONS

| # | Bước | Trạng thái | Bằng chứng |
|---|------|------------|------------|
| 1 | `supabase functions deploy outbox-processor --project-ref rsialbfjswnrkzcxarnj` | ☐ | Log deploy |
| 2 | `supabase functions deploy delete-tenant --project-ref rsialbfjswnrkzcxarnj` | ☐ | Log deploy |
| 3 | `supabase functions list --project-ref rsialbfjswnrkzcxarnj` thấy cả 2 | ☐ | List output |
| 4 | Xác nhận `verify_jwt` setting phù hợp | ☐ | Config check |

---

## 7.7 — PRODUCTION: VERIFICATION

| # | Kiểm tra | Trạng thái | Bằng chứng |
|---|----------|------------|------------|
| 1 | `public.delete_state` tồn tại | ☐ | `pg_tables` output |
| 2 | `public.outbox` tồn tại | ☐ | `pg_tables` output |
| 3 | `public.tenant_deletion_backups` tồn tại | ☐ | `pg_tables` output |
| 4 | `public.delete_tenant_canonical` tồn tại và `SECURITY DEFINER` | ☐ | `pg_proc` output |
| 5 | `app_audit_log.deleted_tenant_id` tồn tại | ☐ | `information_schema.columns` output |
| 6 | FK `app_audit_log_tenant_id_fkey` không còn | ☐ | `pg_constraint` output (0 dòng) |
| 7 | 3 business trigger `D` (disabled) | ☐ | `pg_trigger` output |
| 8 | 2 guardrail trigger `O` (enabled) | ☐ | `pg_trigger` output |
| 9 | `delete_state` count = 0 (chưa có request xóa) | ☐ | `SELECT COUNT(*)` |
| 10 | `outbox` count = 0 (chưa có message) | ☐ | `SELECT COUNT(*)` |

---

## 7.8 — BÁO CÁO KẾT QUẢ

| # | Bước | Trạng thái | Bằng chứng |
|---|------|------------|------------|
| 1 | Tạo `WAVE-03_DEPLOYMENT_REPORT.md` | ☐ | File tồn tại |
| 2 | Đính kèm migration list, function list, SQL verification | ☐ | Trong báo cáo |
| 3 | Gửi báo cáo cho PO/CTA | ☐ | Email/chat log |
| 4 | PO/CTA ký đóng Phase 7 | ☐ | Chữ ký |

---

## CHECKLIST AN TOÀN

| # | Kiểm tra | Trạng thái | Người xác nhận |
|---|----------|------------|----------------|
| S1 | `USE_CANONICAL_DELETE` mặc định `false` trong `delete-tenant` Edge Function | ☐ | Agent |
| S2 | `VITE_USE_CANONICAL_DELETE` mặc định `false` trong `services/tenantService.ts` | ☐ | Agent |
| S3 | `delete_tenant_canonical` chỉ gọi khi flag bật | ☐ | Agent |
| S4 | Không có request xóa tenant nào chạy trên Production sau deploy | ☐ | Agent |
| S5 | `app_audit_log` vẫn ghi log; `deleted_tenant_id` tồn tại | ☐ | Agent |
| S6 | Guardrail trigger `tenants_before_delete_guardrail` & `tenant_memberships_guardrails` vẫn enabled | ☐ | Agent |
| S7 | Backup trước deploy có thể restore | ☐ | PO/CTA |
| S8 | Không bật canonical delete trên Production cho đến khi test kỹ | ☐ | PO/CTA |

---

## ROLLBACK READY

| # | Kiểm tra | Trạng thái | Bằng chứng |
|---|----------|------------|------------|
| 1 | Đã xác định commit base trước Wave-03 để revert `delete-tenant` | ☐ | `git log` |
| 2 | Có SQL rollback migrations (copy từ comment trong file migration) | ☐ | File .sql riêng (nếu cần) |
| 3 | Biết cách `supabase functions delete outbox-processor` nếu cần | ☐ | Command sẵn sàng |
| 4 | Biết cách re-deploy `delete-tenant` từ commit trước Wave-03 | ☐ | Command sẵn sàng |
