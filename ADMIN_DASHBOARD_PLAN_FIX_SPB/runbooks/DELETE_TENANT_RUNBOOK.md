# Runbook — Xóa Tenant (Canonical Delete Pipeline)

> **Vị trí:** `ADMIN_DASHBOARD_PLAN_FIX_SPB/runbooks/DELETE_TENANT_RUNBOOK.md`  
> **Liên quan:** SPEC-001, SPEC-003, SPEC-004, SPEC-006, SPEC-007  
> **Cập nhật:** 2026-07-24 (Wave-03 Phase 5.3)

---

## 1. Tổng quan canonical pipeline

Kể từ Wave-03, quy trình xóa tenant có hai path:

| Path | Kích hoạt | Đặc điểm |
|---|---|---|
| **Legacy** | `USE_CANONICAL_DELETE` = `false` hoặc chưa đặt | Edge Function `delete-tenant` thực hiện nhiều bước HTTP riêng lẻ, không đảm bảo atomic. |
| **Canonical** | `USE_CANONICAL_DELETE` = `true` | SECURITY DEFINER RPC `delete_tenant_canonical` sở hữu toàn bộ transaction: backup → audit intent → xóa tenant → enqueue `outbox`. Side effect (storage/auth) do Edge Function `outbox-processor` xử lý sau commit. |

Canonical pipeline bao gồm:
1. `delete_state` — state machine theo dõi vòng đời request xóa.
2. `tenant_deletion_backups` — snapshot JSON của tenant trước khi xóa.
3. `outbox` — hàng đợi idempotent cho `storage.cleanup` và `auth.cleanup`.
4. `outbox-processor` — Edge Function poll `outbox` và thực hiện cleanup.

---

## 2. Vận hành cơ bản

### 2.1 Khởi tạo xóa tenant

Từ UI/admin gọi `tenantService.hardDeleteTenant(tenantId, correlationId?)`.

- `correlationId` tùy chọn, dùng để trace xuyên suốt logs, audit, `delete_state`.
- Service tự động chọn canonical hoặc legacy dựa trên feature flag.

### 2.2 Kiểm tra trạng thái `delete_state`

```sql
SELECT
  request_id,
  tenant_id,
  action,
  status,
  payload,
  started_at,
  updated_at,
  completed_at
FROM public.delete_state
WHERE tenant_id = '<tenant-id>'
ORDER BY started_at DESC;
```

Các trạng thái chính:
- `DELETE_REQUESTED` — request đã ghi nhận.
- `SIDE_EFFECTS_PENDING` — transaction DB đã commit, tenant row đã xóa, chờ `outbox` xử lý.
- `COMPLETED` — toàn bộ side effect đã hoàn tất (nếu được cập nhật bởi processor hoặc audit cuối).
- `FAILED` — lỗi không retry được (ví dụ tenant không tồn tại).
- `ROLLBACK` / `RECOVERABLE` — trạng thái dành cho can thiệp thủ công.

---

## 3. Giám sát và xử lý `outbox`

### 3.1 Xem outbox cho một request

```sql
SELECT
  message_id,
  request_id,
  topic,
  payload,
  status,
  attempts,
  error,
  created_at,
  processed_at
FROM public.outbox
WHERE request_id = '<request-id>'
ORDER BY created_at;
```

### 3.2 Message bị kẹt

**pending > 5 phút:**
- Kiểm tra `outbox-processor` có đang chạy không:
  ```bash
  supabase functions serve outbox-processor
  ```
- Gọi thủ công (local):
  ```powershell
  curl.exe -X POST http://127.0.0.1:54321/functions/v1/outbox-processor `
    -H "Authorization: Bearer <service_role_key>"
  ```

**failed hoặc attempts >= MAX_ATTEMPTS (5):**
- Xem lỗi trong cột `error`.
- Nếu lỗi tạm thời, reset để retry:
  ```sql
  UPDATE public.outbox
  SET status = 'pending', attempts = 0, error = NULL, processed_at = NULL
  WHERE message_id = '<message-id>';
  ```
- Nếu lỗi vĩnh viễn (ví dụ auth user không tồn tại), xử lý thủ công và đánh dấu:
  ```sql
  UPDATE public.outbox
  SET status = 'processed', processed_at = now(), error = 'manually resolved'
  WHERE message_id = '<message-id>';
  ```

---

## 4. Rollback / khôi phục khi sự cố

### 4.1 Lấy snapshot trước khi xóa

```sql
SELECT
  request_id,
  tenant_id,
  snapshot
FROM public.tenant_deletion_backups
WHERE tenant_id = '<tenant-id>'
ORDER BY created_at DESC
LIMIT 1;
```

`snapshot` là JSONB chứa:
- `tenant` — toàn bộ row `public.tenants` trước khi xóa.
- `user_ids` — mảng UUID của owner và members.

### 4.2 Khôi phục thủ công (tùy quyết định Production Owner)

Canonical pipeline không tự động rollback DB vì tenant row đã bị xóa CASCADE. Để phục hồi:
1. Lấy snapshot từ `tenant_deletion_backups`.
2. Chèn lại `public.tenants` từ `snapshot->tenant`.
3. Tái tạo `tenant_memberships` và các bảng con theo nhu cầu từ snapshot/backup.
4. Nếu side effect storage/auth đã chạy, cần khôi phục riêng:
   - `storage.cleanup`: re-upload assets từ backup nếu có.
   - `auth.cleanup`: tạo lại user/auth record và gán membership.

### 4.3 Dừng pipeline khẩn cấp

Nếu phát hiện lỗi nghiêm trọng khi canonical đang bật:
1. Tắt feature flag `USE_CANONICAL_DELETE` (xem §5).
2. Hủy/khóa request đang chạy trong `delete_state`:
   ```sql
   UPDATE public.delete_state
   SET status = 'FAILED', updated_at = now()
   WHERE request_id = '<request-id>' AND status NOT IN ('COMPLETED','FAILED','CLOSED');
   ```
3. Đánh dấu `outbox` message liên quan thành `failed` hoặc xóa nếu chưa xử lý.

---

## 5. Feature flag `USE_CANONICAL_DELETE`

### 5.1 Frontend / Vite

```bash
# .env.local hoặc biến môi trường build
VITE_USE_CANONICAL_DELETE=true
```

`services/tenantService.ts` kiểm tra:
```ts
const env = (import.meta as any).env ?? (typeof process !== 'undefined' ? process.env : {});
const useCanonical =
  env?.VITE_USE_CANONICAL_DELETE === 'true' || env?.USE_CANONICAL_DELETE === 'true';
```

### 5.2 Edge Function

```bash
# .env hoặc config.toml [edge_runtime]
USE_CANONICAL_DELETE=true
```

`supabase/functions/delete-tenant/index.ts` kiểm tra:
```ts
if (Deno.env.get('USE_CANONICAL_DELETE') === 'true') { ... }
```

### 5.3 Bật/tắt an toàn

- **Bật:** chỉ trên staging/non-prod trước, sau khi pgTAP + Vitest PASS.
- **Tắt:** đặt về `false` hoặc xóa biến. Legacy path sẽ được sử dụng ngay lập tức.
- **Canary:** bật cho 1 tenant test, kiểm tra `delete_state` + `outbox`, sau đó mở rộng.

---

## 6. Kiểm tra nhanh sau khi xóa

```sql
-- 1. Tenant đã xóa chưa?
SELECT id FROM public.tenants WHERE id = '<tenant-id>';

-- 2. Audit intent còn tồn tại?
SELECT * FROM public.app_audit_log
WHERE deleted_tenant_id = '<tenant-id>' AND action = 'DELETE';

-- 3. Outbox đã xử lý xong?
SELECT request_id, topic, status FROM public.outbox
WHERE request_id = '<request-id>';

-- 4. Storage còn asset của tenant?
-- Trong Edge Function log hoặc storage bucket `tenant-assets/<tenant-id>/`
```

---

## 7. Liên hệ và tham chiếu

- **SPEC-001:** `ADMIN_DASHBOARD_PLAN_FIX_SPB/02_Specifications/SPEC-001_DELETE_FRAMEWORK_ARCHITECTURE_SPECIFICATION.md`
- **Test report:** `ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE-03_PHASE-5-2B_TEST_REPORT.md`
- **Implementation plan:** `ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE-03_PHASE-4-1_IMPLEMENTATION_PLAN.md`
- **Code chính:**
  - `supabase/migrations/20260725000000_create_delete_state_tables.sql`
  - `supabase/migrations/20260725000001_create_rpc_delete_tenant_canonical.sql`
  - `supabase/migrations/20260725000002_audit_independence.sql`
  - `supabase/migrations/20260725000003_trigger_migration.sql`
  - `supabase/functions/delete-tenant/index.ts`
  - `supabase/functions/outbox-processor/index.ts`
  - `services/tenantService.ts`
