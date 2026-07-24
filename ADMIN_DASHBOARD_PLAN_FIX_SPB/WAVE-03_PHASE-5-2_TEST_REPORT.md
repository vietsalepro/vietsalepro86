# BÁO CÁO KIỂM THỬ — WAVE-03 PHASE 5.2

| Trường | Giá trị |
|--------|---------|
| Prompt ID | WAVE-03-PHASE-5-2-001 |
| Ngày | 2026-07-24 |
| Agent | Engineering Execution Agent |
| Môi trường | Supabase local (127.0.0.1:54322) |
| Trạng thái tổng thể | **BLOCKED** — migration thành công, kiểm thử static/regression PASS, pgTAP gặp lỗi harness & trigger state chưa đúng |

---

## 1. CHUẨN BỊ MÔI TRƯỜNG

- `supabase --version`: `2.109.1`
- `supabase status` (local): database đang chạy, edge runtime/pooler/imgproxy đang stopped.
- Không chạy bất kỳ thao tác nào trên production.

## 2. MIGRATION LOCAL

Lệnh:

```powershell
supabase migration up --local --include-all
```

Kết quả:

```
Applying migration 20260713000002_wave02_package03_sequence_anchor.sql...
Applying migration 20260721100000_wave03_package01_service_layer_permissions.sql...
Applying migration 20260721120000_wave03_package02_edge_audit.sql...
Applying migration 20260725000000_create_delete_state_tables.sql...
Applying migration 20260725000001_create_rpc_delete_tenant_canonical.sql...
Applying migration 20260725000002_audit_independence.sql...
Applying migration 20260725000003_trigger_migration.sql...
Applying migration 20260729000000_wave02_package01_log_view_rpc.sql...
Applying migration 20260730000000_wave02_package02_audit_triggers.sql...
Applying migration 20260731000000_wave02_package03_security_context.sql...
Applying migration 20260801000000_wave04_canonical_read_rpcs.sql...
Local database is up to date.
```

**Trạng thái:** ✅ PASS — tất cả migration đã apply trên local.

## 3. TYPE CHECK

Lệnh:

```powershell
npx tsc --noEmit
```

Kết quả: `Exited with code 0 and no output`

**Trạng thái:** ✅ PASS

## 4. VITEST (REGRESSION STATIC)

Do file `.env` đang trỏ đến production (`https://rsialbfjswnrkzcxarnj.supabase.co`), toàn bộ test suite gọi live DB không được chạy để tránh tác động production. Thay vào đó, chạy các test static/regression mới của Phase 5.1:

```powershell
npx vitest run tests/edge-functions/outbox-processor.regression.test.ts tests/regression/delete-tenant-idempotency.test.ts tests/regression/delete-tenant-500.test.ts
```

Kết quả:

```
Test Files  3 passed (3)
     Tests  14 passed (14)
  Start at  16:43:21
  Duration  1.27s
```

**Trạng thái:** ✅ PASS (các test static/regression đúng theo yêu cầu)

## 5. pgTAP SQL TESTS

Lệnh:

```powershell
supabase test db --local supabase/tests/rpc/delete_state_tables.test.sql supabase/tests/rpc/delete_tenant_canonical.test.sql supabase/tests/rpc/audit_independence.test.sql supabase/tests/rpc/trigger_migration.test.sql
```

Kết quả:

```
/PROJECT/vietsalepro/supabase/tests/rpc/delete_state_tables.test.sql ...... ok
/PROJECT/vietsalepro/supabase/tests/rpc/delete_tenant_canonical.test.sql .. Failed 10/10 subtests
/PROJECT/vietsalepro/supabase/tests/rpc/audit_independence.test.sql ....... Failed 3/5 subtests
/PROJECT/vietsalepro/supabase/tests/rpc/trigger_migration.test.sql ........ Failed 2/4 subtests

Files=4, Tests=15,  Result: FAIL
```

**Phân tích lỗi:**

1. `delete_tenant_canonical.test.sql` & `audit_independence.test.sql`: lỗi `schema "tests" does not exist` vì `tests.create_supabase_user` chưa được tạo trong database. Helper `supabase/tests/admin/000_helpers.sql` không được `supabase test db` tự động load.
2. `trigger_migration.test.sql`:
   - Test 1: mong đợi 12 trigger business-workflow bị disabled (`tgenabled='D'`), thực tế chỉ có 9 trigger disabled; 3 trigger `trg_audit_log_invitations`, `trg_audit_log_licenses`, `trg_audit_log_system_admins` vẫn `O` (enabled).
   - Test 2: mong đợi 4 guardrail trigger enabled, thực tế trả về 10 vì `set_tenant_record_user_tracking` tồn tại trên 7 bảng khác nhau.

**Trạng thái:** 🔴 FAIL — cần xử lý harness `tests` schema và trigger state trước khi coi là pass.

## 6. XÁC MINH MANUAL

### 6.1 Bảng mới

```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema='public' AND table_name IN ('delete_state','outbox','tenant_deletion_backups')
ORDER BY table_name;
```

Kết quả:

```
│ table_name              │
├─────────────────────────┤
│ delete_state            │
│ outbox                  │
│ tenant_deletion_backups │
```

**Trạng thái:** ✅ PASS

### 6.2 RPC `delete_tenant_canonical`

```sql
SELECT proname, prosecdef FROM pg_proc WHERE proname = 'delete_tenant_canonical';
```

Kết quả:

```
│ proname                 │ prosecdef │
├─────────────────────────┼───────────┤
│ delete_tenant_canonical │ true      │
```

**Trạng thái:** ✅ PASS

### 6.3 Audit independence

Kiểm tra FK:

```sql
SELECT constraint_name FROM information_schema.table_constraints
WHERE table_schema='public' AND table_name='app_audit_log' AND constraint_type='FOREIGN KEY' AND constraint_name LIKE '%tenant%';
```

Kết quả: 0 rows

Kiểm tra cột `deleted_tenant_id`:

```sql
SELECT column_name FROM information_schema.columns
WHERE table_schema='public' AND table_name='app_audit_log' AND column_name='deleted_tenant_id';
```

Kết quả:

```
│ column_name       │
├───────────────────┤
│ deleted_tenant_id │
```

**Trạng thái:** ✅ PASS

### 6.4 Trigger migration

```sql
SELECT n.nspname||'.'||c.relname AS table_trigger, t.tgname, t.tgenabled
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid=c.oid
JOIN pg_namespace n ON c.relnamespace=n.oid
WHERE n.nspname='public'
  AND (t.tgname LIKE 'trg_audit_log_%' OR t.tgname IN ('tenants_before_delete_guardrail','tenant_memberships_guardrails','set_tenant_record_user_tracking','trg_app_audit_log_login_enforcement','tenant_memberships_audit'))
ORDER BY t.tgname;
```

Kết quả (tóm tắt):

- Guardrail `tenants_before_delete_guardrail`: `O` ✅
- Guardrail `tenant_memberships_guardrails`: `O` ✅
- Business-workflow audit trigger: 9/12 đã `D` (disabled), 3 trigger (`trg_audit_log_invitations`, `trg_audit_log_licenses`, `trg_audit_log_system_admins`) vẫn `O`.

**Trạng thái:** ⚠️ PARTIAL — cần disable 3 trigger còn lại.

### 6.5 Outbox / idempotency

Tạo test tenant + gọi `delete_tenant_canonical` 2 lần với cùng `request_id`:

```
first_result:  {"request_id":"a3333333-...","status":"SIDE_EFFECTS_PENDING","success":true,"tenant_id":"a2222222-..."}
second_result: {"request_id":"a3333333-...","status":"SIDE_EFFECTS_PENDING","success":true,"tenant_id":"a2222222-..."}
```

Sau đó kiểm tra `outbox`:

```
│ request_id                           │ topic           │ status  │
├──────────────────────────────────────┼─────────────────┼─────────┤
│ a3333333-3333-3333-3333-333333333333 │ storage.cleanup │ pending │
│ a3333333-3333-3333-3333-333333333333 │ auth.cleanup    │ pending │
```

**Trạng thái:** ✅ PASS — idempotency hoạt động đúng, outbox enqueue 2 message.

### 6.6 Feature flag `USE_CANONICAL_DELETE`

- `services/tenantService.ts` (dòng 740-741): `useCanonical` chỉ true khi `VITE_USE_CANONICAL_DELETE === 'true'` hoặc `USE_CANONICAL_DELETE === 'true'`. Mặc định false.
- `supabase/functions/delete-tenant/index.ts` (dòng 318): `Deno.env.get('USE_CANONICAL_DELETE') === 'true'`. Mặc định false.
- `hardDeleteTenant` có 2 path: canonical RPC (`supabase.rpc('delete_tenant_canonical', ...)`) khi flag true, legacy `supabase.functions.invoke('delete-tenant', ...)` khi flag false.

**Trạng thái:** ✅ PASS

### 6.7 Outbox-processor Edge Function

- `supabase/functions/outbox-processor/index.ts` tồn tại và xử lý `storage.cleanup`/`auth.cleanup` (đã xác minh qua Vitest static).
- Edge runtime local đang stopped, không gọi được trực tiếp; trạng thái `outbox` vẫn `pending`.

**Trạng thái:** ⚠️ PARTIAL — structure OK, runtime chưa chạy nên chưa verify `status = 'processed'`.

## 7. VẤN ĐỀ PHÁT SINH

| # | Vấn đề | Mức độ | Đề xuất |
|---|--------|--------|---------|
| 1 | pgTAP tests thiếu `tests` schema (`tests.create_supabase_user`) | BLOCKER | Tạo `tests` schema helper trước khi chạy pgTAP, hoặc sửa test file để tự tạo user thủ công. |
| 2 | 3 business-workflow audit trigger (`invitations`, `licenses`, `system_admins`) vẫn enabled | BLOCKER | Kiểm tra lại thứ tự migration; các trigger này có thể được tạo lại bởi migration `20260730000000_wave02_package02_audit_triggers.sql` sau khi `20260725000003_trigger_migration.sql` đã disable. Cần chạy lệnh disable hoặc điều chỉnh migration. |
| 3 | `trigger_migration.test.sql` đếm `set_tenant_record_user_tracking` trên nhiều bảng dẫn đến sai số | MINOR | Sửa test để chỉ đếm distinct trigger name hoặc lọc theo bảng `tenants`. |
| 4 | Edge runtime local stopped | INFO | `supabase functions serve` cần được start để verify outbox-processor runtime. |
| 5 | `.env` trỏ production | RISK | Không chạy test live DB với `.env` hiện tại; cần `.env.local` hoặc override env khi chạy integration test. |

## 8. KẾT LUẬN

- **Migration local:** ✅ PASS
- **Type check:** ✅ PASS
- **Vitest (static/regression):** ✅ PASS
- **pgTAP SQL tests:** 🔴 FAIL
- **Manual verification:** ✅ đúng với bảng, RPC, audit independence, feature flag, idempotency; ⚠️ trigger migration chưa hoàn chỉnh và outbox-processor runtime chưa verify.

**Tổng kết:** **BLOCKED**  
Phase 5.2 chưa đạt điều kiện PASS vì pgTAP thất bại và trigger state chưa đúng. Cần khắc phục 2 blocker (tests schema + 3 trigger còn enabled) và chạy lại pgTAP trước khi chuyển sang Phase 5.3 / deploy.

---

## 9. EVIDENCE FILES

- `supabase migration up --local --include-all` output: §2
- `npx tsc --noEmit` output: §3
- `npx vitest run ...` output: §4
- `supabase test db --local ...` output: §5
- Manual SQL outputs: §6

Không có commit, push, deploy, hoặc thay đổi production trong báo cáo này.
