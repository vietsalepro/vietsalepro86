# WAVE-03 — KẾ HOẠCH TRIỂN KHAI STAGING & PRODUCTION

| Trường | Giá trị |
|--------|---------|
| Prompt ID | WAVE‑03‑PHASE‑7‑0‑001 |
| Ngày | 2026-07-24 |
| Người lập | Engineering Execution Agent |
| Người phê duyệt | Production Owner / Chief Technical Advisor (ủy quyền) |
| Môi trường Staging | `shbmzvfcenbybvyzclem` (QLBH Staging Multi-Tenant) |
| Môi trường Production | `rsialbfjswnrkzcxarnj` (VietSalePro) |
| Trạng thái | **KẾ HOẠCH** — chưa thực thi |

---

## 1. TÓM TẮT

Wave-03 (SPEC Baseline & Implementation — SPEC-001 Delete Framework) đã được Production Owner **ACCEPT** tại Phase 6.3. Tài liệu này là kế hoạch triển khai từng bước lên Staging và Production, bao gồm:

- Danh sách toàn bộ thành phần cần deploy.
- Thứ tự và phụ thuộc giữa các thành phần.
- Các bước pre-deployment, staging, production, verification.
- Rollback plan cho từng tầng.
- Checklist an toàn và yêu cầu phê duyệt.

> **Lưu ý:** Đây là kế hoạch. Không thực hiện commit/push/deploy trong prompt này. Các bước 7.5–7.7 (Production) yêu cầu phê duyệt riêng của Production Owner.

---

## 2. DANH SÁCH THÀNH PHẦN WAVE-03 CẦN TRIỂN KHAI

### 2.1 Migrations (`supabase/migrations/`)

| # | File | Mục đích | Thứ tự |
|---|------|----------|--------|
| 1 | `20260725000000_create_delete_state_tables.sql` | Tạo `public.delete_state`, `public.outbox`, `public.tenant_deletion_backups` | 1 |
| 2 | `20260725000001_create_rpc_delete_tenant_canonical.sql` | Tạo SECURITY DEFINER RPC `public.delete_tenant_canonical` | 2 |
| 3 | `20260725000002_audit_independence.sql` | Thêm `app_audit_log.deleted_tenant_id`, xóa FK `app_audit_log_tenant_id_fkey`, nâng cấp RPC | 3 |
| 4 | `20260725000003_trigger_migration.sql` | Disable 12 business-workflow audit trigger; giữ guardrail trigger | 4 |
| 5 | `20260731000001_disable_remaining_business_triggers.sql` | Disable thêm 3 trigger (`invitations`, `licenses`, `system_admins`) | 5 |

### 2.2 Edge Functions (`supabase/functions/`)

| Function | Thay đổi | Phụ thuộc |
|----------|----------|-----------|
| `outbox-processor` | Mới: xử lý hàng đợi `public.outbox` (storage/auth cleanup) | `public.outbox`, `public.delete_state` |
| `delete-tenant` | Cập nhật: thêm `USE_CANONICAL_DELETE` gate, gọi `delete_tenant_canonical` khi flag bật | RPC `delete_tenant_canonical`, tables `delete_state`, `outbox`, `tenant_deletion_backups` |

### 2.3 Services (`services/`)

| File | Thay đổi | Ghi chú |
|------|----------|---------|
| `services/tenantService.ts` | `hardDeleteTenant` gọi `delete_tenant_canonical` khi `VITE_USE_CANONICAL_DELETE === 'true'` | Nằm trong source SPA; deploy thông qua Vercel (không thuộc phạm vi deploy DB/Edge Function này) |
| `services/supabaseService.ts` | `_legacy*` được đánh dấu `@deprecated` | Cùng source SPA |

### 2.4 Tests

| Loại | File |
|------|------|
| pgTAP | `supabase/tests/rpc/delete_state_tables.test.sql` |
| pgTAP | `supabase/tests/rpc/delete_tenant_canonical.test.sql` |
| pgTAP | `supabase/tests/rpc/audit_independence.test.sql` |
| pgTAP | `supabase/tests/rpc/trigger_migration.test.sql` |
| Vitest | `tests/edge-functions/outbox-processor.regression.test.ts` |
| Vitest | `tests/regression/delete-tenant-idempotency.test.ts` |
| Vitest | `tests/edge-functions/delete-tenant.regression.test.ts` |
| Vitest | `tests/regression/delete-tenant-500.test.ts` |

### 2.5 Scripts & tài liệu

| File | Mục đích |
|------|----------|
| `scripts/verify-wave03.ts` | Verification 33 check Wave-03 (chạy trên local DB) |
| `scripts/verify-wave02.ts` | Regression baseline Wave-02 |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/SEMANTIC_MEMORY.md` | Cập nhật kiến thức Wave-03 |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/runbooks/DELETE_TENANT_RUNBOOK.md` | Runbook xóa tenant |
| `docs/admin-dashboard/MIGRATION_RUNBOOK.md` | Cập nhật |
| `docs/admin-dashboard/ROLLBACK_RUNBOOK.md` | Cập nhật |
| `docs/admin-dashboard/DISASTER_RECOVERY_RUNBOOK.md` | Cập nhật |
| `docs/admin-dashboard/INCIDENT_RESPONSE_RUNBOOK.md` | Cập nhật |

---

## 3. SƠ ĐỒ PHỤ THUỘC & THỨ TỰ

```
[1] Commit/push source Wave-03 lên repository
    │
    ▼
[2] Deploy migrations lên Staging (theo thứ tự timestamp)
    │   20260725000000 ──► 20260725000001 ──► 20260725000002 ──► 20260725000003 ──► 20260731000001
    │
    ▼
[3] Deploy Edge Functions lên Staging
    │   outbox-processor ──► delete-tenant
    │   (phải sau khi migrations thành công vì functions tham chiếu tables/RPC mới)
    │
    ▼
[4] Verification trên Staging
    │
    ▼ (cổng phê duyệt Production Owner)
[5] Deploy migrations lên Production
    │
    ▼
[6] Deploy Edge Functions lên Production
    │
    ▼
[7] Verification trên Production
    │
    ▼
[8] Báo cáo kết quả
```

**Nguyên tắc thứ tự:**

- Migrations phải chạy đúng timestamp; migration sau thay thế/cập nhật object do migration trước tạo ra (vd: `20260725000002_audit_independence.sql` thay thế `delete_tenant_canonical`).
- Edge Functions deploy sau migrations vì chúng đọc/ghi `public.outbox`, `public.delete_state` và `delete_tenant_canonical`.
- Service/SPA cập nhật đi kèm commit source, nhưng build Vercel là bước riêng nếu PO yêu cầu.

---

## 4. TIÊN KIỂM (PRE-DEPLOYMENT CHECKS)

| # | Kiểm tra | Cách thực hiện | Tiêu chí PASS |
|---|----------|----------------|---------------|
| P1 | Wave-03 đã được ACCEPT | Đọc `WAVE-03_PHASE-6-2_ACCEPTANCE_REQUEST.md` | Có chữ ký `ACCEPT` |
| P2 | Local verification PASS | `npx tsx scripts/verify-wave03.ts` | 33/33 PASS |
| P3 | Vitest regression PASS | `npx vitest run tests/edge-functions tests/regression` | Toàn bộ PASS |
| P4 | pgTAP PASS | `supabase test db` (hoặc `npx supabase test db`) | Toàn bộ PASS |
| P5 | Git branch | `git branch --show-current` | `master` |
| P6 | Không có thay đổi chưa lưu ngoài Wave-03 | `git status --short` | Chỉ có file Wave-03 và docs liên quan |
| P7 | Supabase CLI sẵn sàng | `supabase --version` | >= phiên bản đang dùng trong dự án |
| P8 | Đã đăng nhập Supabase | `supabase projects list` | Thấy `shbmzvfcenbybvyzclem` và `rsialbfjswnrkzcxarnj` |
| P9 | Feature flag tắt | Kiểm tra `.env`/Vercel env | `USE_CANONICAL_DELETE` và `VITE_USE_CANONICAL_DELETE` không được bật |
| P10 | Backup staging & prod | Tạo backup qua Dashboard hoặc `pg_dump` | Có bằng chứng backup (PO/CTA xác nhận) |

---

## 5. STAGING DEPLOYMENT (Bước 7.1 – 7.4)

### 5.1 Bước 7.1 — Commit & Push

```bash
git add -A
git status --short
# Kiểm tra chỉ có các file Wave-03 và docs liên quan
git commit -m "deploy(wave-03): SPEC-001 delete framework for staging/prod

- 5 migrations: delete_state tables, canonical RPC, audit independence, trigger governance
- Edge Functions: outbox-processor, delete-tenant (USE_CANONICAL_DELETE gate)
- tenantService canonical RPC call + feature flag
- pgTAP/Vitest tests + verify scripts + runbooks/SEMANTIC_MEMORY updates"
git push origin master
```

### 5.2 Bước 7.2 — Deploy Migrations lên Staging

```bash
# Link CLI với staging (nếu chưa link)
supabase link --project-ref shbmzvfcenbybvyzclem

# Xem các migration đang chờ
supabase migration list

# Apply migrations
supabase migration up --linked
```

**Kiểm tra sau migration:**

```bash
supabase migration list
```

Đảm bảo 5 migration Wave-03 ở trạng thái `APPLIED`.

### 5.3 Bước 7.3 — Deploy Edge Functions lên Staging

```bash
# Deploy từng function (có thể thay bằng --project-ref nếu không link)
supabase functions deploy outbox-processor --project-ref shbmzvfcenbybvyzclem
supabase functions deploy delete-tenant --project-ref shbmzvfcenbybvyzclem

# Kiểm tra danh sách function
supabase functions list --project-ref shbmzvfcenbybvyzclem
```

**Lưu ý `verify_jwt`:**

- Kiểm tra `supabase/config.toml` hoặc trạng thái deploy để đảm bảo `delete-tenant` và `outbox-processor` có `verify_jwt` phù hợp với môi trường hiện tại.
- Nếu `outbox-processor` được gọi bởi cron/không qua JWT user, cần `--no-verify-jwt` (hoặc tương đương) theo thiết lập tổ chức.
- Không tự ý thay đổi config nếu PO/CTA chưa phê duyệt.

### 5.4 Bước 7.4 — Verification trên Staging

`scripts/verify-wave03.ts` được viết cho local DB (Docker). Trên Staging/Production, thực hiện các kiểm tra tương đương bằng `psql` với connection string hoặc Supabase Dashboard SQL Editor.

**A. Kiểm tra schema:**

```sql
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('delete_state','outbox','tenant_deletion_backups')
ORDER BY tablename;

SELECT column_name FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'app_audit_log'
  AND column_name = 'deleted_tenant_id';

SELECT conname FROM pg_constraint
WHERE conname IN ('app_audit_log_tenant_id_fkey','audit_log_tenant_id_fkey');
-- Kỳ vọng: 0 dòng
```

**B. Kiểm tra RPC:**

```sql
SELECT proname, prosecdef::int FROM pg_proc
WHERE proname = 'delete_tenant_canonical';
-- Kỳ vọng: 1 dòng, prosecdef = 1 (SECURITY DEFINER)
```

**C. Kiểm tra trigger:**

```sql
SELECT t.tgname, t.tgenabled
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public'
  AND t.tgname IN (
    'trg_audit_log_invitations','trg_audit_log_licenses','trg_audit_log_system_admins',
    'tenants_before_delete_guardrail','tenant_memberships_guardrails'
  );
-- Kỳ vọng: 3 business trigger t.tgenabled = 'D' (disabled)
--          2 guardrail trigger t.tgenabled = 'O' (enabled)
```

**D. Kiểm tra Edge Functions:**

```bash
supabase functions list --project-ref shbmzvfcenbybvyzclem
```

Kỳ vọng thấy `outbox-processor` và `delete-tenant`.

**E. Smoke test đường xóa (không bắt buộc nếu staging không cho phép):**

Với một test tenant, gọi `delete-tenant` Edge Function với `force=true` và `USE_CANONICAL_DELETE=false` (mặc định) để đảm bảo legacy path vẫn hoạt động. Không bật `USE_CANONICAL_DELETE` trừ khi có chỉ thị.

---

## 6. CỔNG PHÊ DUYỆT PRODUCTION

Trước khi chạy bất kỳ lệnh nào trong mục 7, Production Owner/CTA phải ký phê duyệt theo mẫu dưới:

| Hạng mục | Người phê duyệt | Ký | Ngày |
|----------|-----------------|----|------|
| Staging deploy & verify thành công | CTA/PO | ☐ | |
| Backup Production đã tạo | CTA/PO | ☐ | |
| Production deploy được phép thực hiện | PO | ☐ | |
| Rollback window đã xác định (vd: 30 phút) | CTA/PO | ☐ | |

---

## 7. PRODUCTION DEPLOYMENT (Bước 7.5 – 7.7)

### 7.1 Bước 7.5 — Deploy Migrations lên Production

```bash
# Link CLI với production
supabase link --project-ref rsialbfjswnrkzcxarnj

# Xem migration chờ
supabase migration list

# Apply migrations
supabase migration up
```

**Kiểm tra:**

```bash
supabase migration list
```

5 migration Wave-03 phải ở trạng thái `APPLIED`.

### 7.2 Bước 7.6 — Deploy Edge Functions lên Production

```bash
supabase functions deploy outbox-processor --project-ref rsialbfjswnrkzcxarnj
supabase functions deploy delete-tenant --project-ref rsialbfjswnrkzcxarnj

supabase functions list --project-ref rsialbfjswnrkzcxarnj
```

### 7.3 Bước 7.7 — Verification trên Production

Chạy lại các câu SQL trong mục 5.4 với connection string Production.

Bổ sung kiểm tra:

```sql
-- Không có request xóa nào đang chạy ngoài ý muốn
SELECT COUNT(*) FROM public.delete_state;
-- Kỳ vọng: 0 (trừ khi đã test)

SELECT COUNT(*) FROM public.outbox;
-- Kỳ vọng: 0
```

### 7.4 Bước 7.8 — Báo cáo kết quả

Tạo `WAVE-03_DEPLOYMENT_REPORT.md` với:

- Danh sách migration đã applied (timestamp + tên file).
- Danh sách Edge Functions đã deploy (version slug, verify_jwt).
- Kết quả verification SQL.
- Kết quả smoke test (nếu có).
- Bất kỳ lỗi/giả định nào.
- Chữ ký PO/CTA.

---

## 8. ROLLBACK PLAN

### 8.1 Rollback Migrations

Supabase migrations không tự động chạy `down`. Nếu cần rollback, thực hiện theo thứ tự **ngược** của deployment, dùng SQL đã comment trong từng file migration.

| Thứ tự rollback | File | Lệnh SQL cần chạy (từ comment trong migration) |
|-------------------|------|-------------------------------------------------|
| 5 → 4 | `20260731000001_disable_remaining_business_triggers.sql` | Re-enable 3 trigger: `ALTER TABLE ... ENABLE TRIGGER trg_audit_log_invitations; ALTER TABLE ... ENABLE TRIGGER trg_audit_log_licenses; ALTER TABLE ... ENABLE TRIGGER trg_audit_log_system_admins;` |
| 4 → 3 | `20260725000003_trigger_migration.sql` | Re-enable toàn bộ 12 trigger trong phần comment ROLLBACK |
| 3 → 2 | `20260725000002_audit_independence.sql` | `ALTER TABLE app_audit_log ADD CONSTRAINT ... FOREIGN KEY ... ON DELETE SET NULL;` sau đó `DROP FUNCTION IF EXISTS public.delete_tenant_canonical(...)` |
| 2 → 1 | `20260725000001_create_rpc_delete_tenant_canonical.sql` | `DROP FUNCTION IF EXISTS public.delete_tenant_canonical(UUID, UUID, UUID, UUID);` |
| 1 → 0 | `20260725000000_create_delete_state_tables.sql` | `DROP TABLE IF EXISTS public.tenant_deletion_backups CASCADE; DROP TABLE IF EXISTS public.outbox CASCADE; DROP TABLE IF EXISTS public.delete_state CASCADE;` |

**Lưu ý rollback migration 3:**

- Cột `deleted_tenant_id` có thể bị xóa hoặc giữ lại tùy quyết định PO.
- Re-add FK chỉ an toàn nếu tất cả `app_audit_log.tenant_id` còn tồn tại trong `public.tenants`. Nếu đã xóa tenant, cần dọn dữ liệu hoặc chấp nhận `ON DELETE SET NULL`.

### 8.2 Rollback Edge Functions

| Function | Cách rollback |
|----------|---------------|
| `delete-tenant` | `git checkout <commit-truoc-wave03> -- supabase/functions/delete-tenant/index.ts` rồi deploy lại; hoặc revert commit deploy rồi deploy. |
| `outbox-processor` | `supabase functions delete outbox-processor --project-ref <ref>` vì đây là function mới. |

### 8.3 Rollback Services (SPA)

- `git revert <commit-deploy-wave03>` hoặc `git checkout <base-commit> -- services/tenantService.ts services/supabaseService.ts`.
- Sau đó Vercel build & deploy theo quy trình riêng (không thuộc phạm vi kế hoạch này).

---

## 9. CHECKLIST AN TOÀN

| # | Kiểm tra an toàn | Người xác nhận | Đã kiểm tra |
|---|--------------------|----------------|-------------|
| S1 | `USE_CANONICAL_DELETE` mặc định `false` trong `delete-tenant` Edge Function (`Deno.env.get('USE_CANONICAL_DELETE') === 'true'`) | Agent | ☐ |
| S2 | `VITE_USE_CANONICAL_DELETE` mặc định `false` trong `services/tenantService.ts` | Agent | ☐ |
| S3 | `delete_tenant_canonical` chỉ được gọi khi feature flag bật | Agent | ☐ |
| S4 | Không có request xóa tenant thực tế nào chạy trên Production sau deploy | Agent | ☐ |
| S5 | `app_audit_log` vẫn ghi log bình thường; `deleted_tenant_id` tồn tại | Agent | ☐ |
| S6 | Guardrail trigger `tenants_before_delete_guardrail` và `tenant_memberships_guardrails` vẫn `enabled` | Agent | ☐ |
| S7 | Backup trước deploy đã tạo và có thể restore | PO/CTA | ☐ |
| S8 | Không bật `USE_CANONICAL_DELETE` trên Production cho đến khi có test kỹ lưỡng | PO/CTA | ☐ |

---

## 10. TÀI LIỆU THAM CHIẾU

- `ROADMAP.md` — Phase 7 triển khai Staging & Production.
- `SEMANTIC_MEMORY.md` — Kiến thức tổng hợp Wave-03.
- `VALIDATION_REPORT.md` — Xác thực codebase-memory.
- `WAVE-03_PHASE-6-1_VERIFICATION_REPORT.md` — Kết quả 33/33 PASS.
- `WAVE-03_PHASE-6-2_ACCEPTANCE_REQUEST.md` — PO đã ký ACCEPT.
- `WAVE-03_CLOSEOUT_REPORT.md` — Tổng kết Wave-03.
- `ADMIN_DASHBOARD_PLAN_FIX_SPB/runbooks/DELETE_TENANT_RUNBOOK.md` — Runbook vận hành.
- `NGUYEN_TAC_VIET_PROMPT_AGENT_VIETSALEPRO.md` — Nguyên tắc prompt/governance.
- `VAI_TRO_TRACH_NHIEM_VIETSALEPRO.md` — Phân công vai trò.

---

## 11. KẾT LUẬN

Kế hoạch này xác định rõ:

1. Toàn bộ deliverables Wave-03.
2. Thứ tự triển khai migrations → Edge Functions.
3. Các bước Staging/Production có phê duyệt cổng.
4. Rollback plan từng tầng.
5. Checklist an toàn để đảm bảo `USE_CANONICAL_DELETE` không bật nhầm.

Kế hoạch sẵn sàng để thực thi từng bước một sau khi Production Owner/CTA phê duyệt.
