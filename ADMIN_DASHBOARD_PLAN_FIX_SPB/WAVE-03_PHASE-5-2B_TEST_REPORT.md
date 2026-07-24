# BÁO CÁO KIỂM THỬ — WAVE-03 PHASE 5.2b

| Trường | Giá trị |
|--------|---------|
| Prompt ID | WAVE-03-PHASE-5-2B-001 |
| Ngày | 2026-07-24 |
| Agent | Engineering Execution Agent |
| Môi trường | Supabase local (127.0.0.1:54322) |
| Trạng thái tổng thể | **PASS** — các blocker Phase 5.2 đã khắc phục |

---

## 1. CÁC KHẮC PHỤC ĐÃ THỰC HIỆN

### 1.1 Fix pgTAP harness

- **Nguyên nhân:** `supabase test db` không tự động load `supabase/tests/admin/000_helpers.sql`, nên schema `tests` chưa tồn tại.
- **Giải pháp:** Load helper trực tiếp vào Postgres local bằng `psql` trong container:
  ```powershell
  Get-Content supabase/tests/admin/000_helpers.sql | docker exec -i supabase_db_rsialbfjswnrkzcxarnj psql -U postgres -d postgres
  ```
- **Kết quả:** Schema `tests` và các hàm `tests.create_supabase_user`, `tests.authenticate_as`, `tests.logout` được tạo thành công.

### 1.2 Fix trigger migration

- **Nguyên nhân:** Migration `20260730000000_wave02_package02_audit_triggers.sql` tạo lại 3 trigger business-workflow sau khi `20260725000003_trigger_migration.sql` đã disable.
- **Giải pháp:** Tạo migration mới `supabase/migrations/20260731000001_disable_remaining_business_triggers.sql`:
  ```sql
  ALTER TABLE public.invitations DISABLE TRIGGER trg_audit_log_invitations;
  ALTER TABLE public.licenses DISABLE TRIGGER trg_audit_log_licenses;
  ALTER TABLE public.system_admins DISABLE TRIGGER trg_audit_log_system_admins;
  ```
- **Kết quả:** 3 trigger trên đều ở trạng thái `D` (disabled). Các guardrail trigger vẫn `O` (enabled).

### 1.3 Fix test data/setup để pgTAP pass

- `delete_tenant_canonical.test.sql`: thay role `'cashier'` bằng `'member'` (phù hợp với enum `tenant_role` trên local), thêm `INSERT` `tenant_subscriptions` để vượt qua `check_tenant_limits`, và thêm tenant `subdomain = 'admin'` để test guard.
- `audit_independence.test.sql`: thêm `INSERT` `tenant_subscriptions`.
- `trigger_migration.test.sql`: chuyển test count 4 guardrail trigger thành `count(DISTINCT tgname)` để xử lý `set_tenant_record_user_tracking` tồn tại trên nhiều bảng.

### 1.4 Chạy outbox-processor runtime

- Start edge runtime:
  ```powershell
  $env:SUPABASE_URL='http://127.0.0.1:54321'
  $env:SUPABASE_SERVICE_ROLE_KEY='<service_role_key>'
  supabase functions serve outbox-processor
  ```
- Gửi request test:
  ```powershell
  curl.exe -X POST http://127.0.0.1:54321/functions/v1/outbox-processor -H "Authorization: Bearer <service_role_key>"
  ```
- Kết quả:
  ```json
  {"success":true,"processed":2,"failed":0,"ids":{"processed":["...","..."],"failed":[]}}
  ```
- Kiểm tra `outbox`:
  ```
  │ request_id                           │ topic           │ status    │
  ├──────────────────────────────────────┼─────────────────┼───────────┤
  │ a3333333-3333-3333-3333-333333333333 │ storage.cleanup │ processed │
  │ a3333333-3333-3333-3333-333333333333 │ auth.cleanup    │ processed │
  ```

---

## 2. KẾT QUẢ KIỂM THỬ

### 2.1 Type check

```powershell
npx tsc --noEmit
```

Kết quả: `Exited with code 0 and no output`

**Trạng thái:** ✅ PASS

### 2.2 Vitest static/regression

```powershell
npx vitest run tests/edge-functions/outbox-processor.regression.test.ts tests/regression/delete-tenant-idempotency.test.ts tests/regression/delete-tenant-500.test.ts
```

Kết quả:

```
 Test Files  3 passed (3)
      Tests  14 passed (14)
```

**Trạng thái:** ✅ PASS

### 2.3 pgTAP

```powershell
supabase test db --local supabase/tests/rpc/delete_state_tables.test.sql supabase/tests/rpc/delete_tenant_canonical.test.sql supabase/tests/rpc/audit_independence.test.sql supabase/tests/rpc/trigger_migration.test.sql
```

Kết quả:

```
/PROJECT/vietsalepro/supabase/tests/rpc/delete_state_tables.test.sql ...... ok
/PROJECT/vietsalepro/supabase/tests/rpc/delete_tenant_canonical.test.sql .. ok
/PROJECT/vietsalepro/supabase/tests/rpc/audit_independence.test.sql ....... ok
/PROJECT/vietsalepro/supabase/tests/rpc/trigger_migration.test.sql ........ ok
All tests successful.
Files=4, Tests=28, Result: PASS
```

**Trạng thái:** ✅ PASS

### 2.4 Trigger state xác minh

```sql
SELECT t.tgname, t.tgenabled, c.relname AS table_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid=c.oid
JOIN pg_namespace n ON c.relnamespace=n.oid
WHERE n.nspname='public'
  AND (t.tgname IN ('trg_audit_log_invitations','trg_audit_log_licenses','trg_audit_log_system_admins')
       OR t.tgname IN ('tenants_before_delete_guardrail','tenant_memberships_guardrails','trg_app_audit_log_login_enforcement'))
ORDER BY t.tgname, c.relname;
```

Kết quả:

```
│ tgname                              │ tgenabled │ table_name         │
├─────────────────────────────────────┼───────────┼────────────────────┤
│ tenant_memberships_guardrails       │ O         │ tenant_memberships │
│ tenants_before_delete_guardrail     │ O         │ tenants            │
│ trg_app_audit_log_login_enforcement │ O         │ app_audit_log      │
│ trg_audit_log_invitations           │ D         │ invitations        │
│ trg_audit_log_licenses              │ D         │ licenses           │
│ trg_audit_log_system_admins         │ D         │ system_admins      │
```

**Trạng thái:** ✅ PASS — 3 business-workflow trigger disabled, guardrail enabled.

---

## 3. SẢN PHẨM BÀN GIAO

1. Migration mới: `supabase/migrations/20260731000001_disable_remaining_business_triggers.sql`
2. pgTAP harness fix: schema `tests` được load vào local DB, các test file đã điều chỉnh setup.
3. Báo cáo này: `WAVE-03_PHASE-5-2B_TEST_REPORT.md`
4. `ROADMAP.md` đã cập nhật — Phase 5.2 ✅ HOÀN THÀNH, Phase 5.3 ⏳ SẴN SÀNG.

---

## 4. GHI CHÚ

- Không chạy migration nào trên production.
- Không deploy/commit/push các thay đổi.
- `.env` vẫn trỏ production; kiểm thử sử dụng local keys từ `supabase status -o env`.
