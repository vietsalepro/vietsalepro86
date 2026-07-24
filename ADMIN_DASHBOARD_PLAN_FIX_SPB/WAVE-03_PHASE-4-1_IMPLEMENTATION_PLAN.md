# WAVE-03 — PHASE 4.1: IMPLEMENTATION PLAN — SPEC-001 (Delete Framework)

| Trường | Giá trị |
|---|---|
| Prompt ID | WAVE‑03‑PHASE‑4‑1‑001 |
| Đối tượng | Engineering Execution Agent (hoặc implementer tiếp theo) |
| Ngày | 2026-07-24 |
| Agent | Engineering Execution Agent |
| SPEC đích | SPEC-001_DELETE_FRAMEWORK_ARCHITECTURE_SPECIFICATION.md (v1.1, Baselined) |
| SPEC liên quan | SPEC-002, SPEC-003, SPEC-004, SPEC-005, SPEC-006, SPEC-007 (tất cả Baselined) |
| Trạng thái | PLAN COMPLETE — chờ Phase 4.2 duyệt trước khi thực thi |

---

## 1. EXECUTIVE SUMMARY (Tóm tắt cho Production Owner)

SPEC-001 đã Baselined — đây là bản thiết kế kiến trúc mục tiêu (target) cho **Delete Framework** toàn hệ thống VietSalePro. Implementation Plan này chuyển đổi từ hiện trạng (as‑is) sang mục tiêu bằng cách:

- Tách transaction ownership khỏi Edge Function, tập trung vào một `SECURITY DEFINER` RPC `delete_tenant_canonical`.
- Thêm `delete_state`, `outbox`, `tenant_deletion_backups` để theo dõi vòng đời xóa và xử lý side‑effect (storage/auth) một cách idempotent, **sau** khi DB commit.
- Tách audit khỏi FK-coupled tới `tenants`, đảm bảo audit records sống sót sau entity deletion.
- Dời business logic trong trigger (`trg_audit_log_*`, `trg_tenants_before_delete`…) ra application code / RPC.
- Giữ lại guardrail trigger theo SPEC-004, loại bỏ business‑workflow trigger.

**Không có thay đổi mã nguồn, migration, schema, hoặc deploy trong Phase 4.1.** Đây chỉ là kế hoạch.

---

## 2. GAP ANALYSIS (Tổng hợp từ các Review Reports)

| ID | Gap | Mô tả hiện trạng | SPEC liên quan | Mức ưu tiên |
|---|---|---|---|---|
| G1 | Không có transaction owner duy nhất | `hardDeleteTenant` trong `supabase/functions/delete-tenant/index.ts` gọi nhiều endpoint Supabase riêng lẻ (storage, orphan delete, tenants.delete, auth.admin.deleteUser, audit.insert) → không atomic. | SPEC-001, SPEC-003 | **Critical** |
| G2 | Storage cleanup chạy trước DB commit | Bucket `remove` xảy ra trước khi `tenants.delete()` hoàn tất; nếu DB rollback sẽ mất storage mà không thể khôi phục. | SPEC-001, SPEC-003 | **Critical** |
| G3 | Audit FK-coupled tới tenants | `app_audit_log.tenant_id` và `audit_log.tenant_id` còn FK tới `public.tenants(id)`; xóa tenant sẽ vi phạm FK hoặc xóa audit. | SPEC-001, SPEC-002, SPEC-005 | **Critical** |
| G4 | Business logic trong trigger | `trg_audit_log_tenants` (AFTER DELETE) ghi audit row; các trigger `trg_audit_log_products/orders/...` ghi audit trực tiếp. Vi phạm SPEC-004. | SPEC-001, SPEC-004 | **Major** |
| G5 | Không có State Manager / `delete_state` | Không bảng trạng thái nào theo dõi request → validation → preparation → transaction → side‑effects → complete. | SPEC-001 | **Major** |
| G6 | Không có outbox cho side-effect orchestration | Storage/auth cleanup gọi trực tiếp, không qua outbox/cron, không idempotent retry. | SPEC-001, SPEC-003 | **Major** |
| G7 | Không có idempotency key / request_id uniqueness | Edge Function dùng `correlation_id` nhưng DB không lưu để phòng trùng lặp request khi retry. | SPEC-001 | **Major** |
| G8 | `delete_tenant_safe` là SECURITY INVOKER | Hàm này chỉ soft-delete, chưa phải canonical hard-delete RPC; cần `delete_tenant_canonical` SECURITY DEFINER. | SPEC-001, SPEC-003 | **Minor** |
| G9 | `_legacy*` fallbacks | Các path cũ (non-atomic) cần retire sau khi pipeline mới ổn định. | SPEC-001 | **Minor** |

### Bằng chứng xác minh (read-only)

| Nguồn | Công cụ | Kết quả |
|---|---|---|
| `supabase/functions/delete-tenant/index.ts` | Codebase Memory MCP + `read` | `hardDeleteTenant` (dòng 70–214) thực hiện storage cleanup trước `tenants.delete`, nhiều HTTP call riêng biệt. |
| `services/tenantService.ts` | Codebase Memory MCP + `read` | `hardDeleteTenant` (dòng 732–748) gọi Edge Function `delete-tenant`; `deleteTenant` (dòng 727–730) xóa trực tiếp. |
| `supabase/schema.sql` | `grep` trên repo | Tồn tại `trg_audit_log_tenants` (AFTER DELETE), `trg_audit_log_products`, `trg_audit_log_orders`,...; `delete_tenant_safe` là `SECURITY INVOKER` trong schema baseline, `SECURITY DEFINER` được alter ở dòng 36405 (migration cuối). |
| Supabase Production | `list_projects` / `list_tables` | `list_projects` trả về project `QLBH` ACTIVE_HEALTHY; `list_tables` timeout theo tình trạng đã biết của pooler — fallback sang `supabase/schema.sql` đã cross-validated. |

---

## 3. THÀNH PHẦN CẦN TẠO / SỬA

### 3.1 Migration SQL (5 file)

| # | File | Mục đích | SPEC liên quan | Ghi chú quan trọng |
|---|---|---|---|---|
| 1 | `supabase/migrations/20260725000000_create_delete_state_tables.sql` | Tạo `delete_state`, `delete_session`, `delete_recovery` | SPEC-001 DAT-003 | Chỉ tạo bảng, chưa kích hoạt logic; an toàn chạy trước. |
| 2 | `supabase/migrations/20260725000001_create_outbox_table.sql` | Tạo `outbox` với `message_id`, `topic`, `payload`, `status`, `attempts`, `created_at`, `processed_at` | SPEC-003 CON-011/012/013 | Dùng cho storage/auth cleanup sau commit. |
| 3 | `supabase/migrations/20260725000002_audit_independence.sql` | Xóa FK `app_audit_log_tenant_id_fkey` / `audit_log_tenant_id_fkey`; thêm `deleted_tenant_id` UUID nullable soft reference | SPEC-002, SPEC-005 | Rủi ro cao; cần chạy sau khi audit independence logic đã đảm bảo. |
| 4 | `supabase/migrations/20260725000003_trigger_migration.sql` | Disable/drop các business-workflow trigger (`trg_audit_log_tenants`, `trg_audit_log_products`, `trg_audit_log_orders`, ...); giữ lại guardrail trigger (`trg_tenants_before_delete`, `trg_tenant_memberships_guardrails`) | SPEC-004 | Cần code audit writer replacement trước. |
| 5 | `supabase/migrations/20260725000004_create_tenant_deletion_backups.sql` | Tạo `tenant_deletion_backups` lưu JSON snapshot tenant + memberships trước hard-delete | SPEC-001 RCM-001 | Phục vụ recovery. |

### 3.2 RPC mới / cập nhật (5+ hàm)

| # | Hàm | Loại | Mục đích | SPEC |
|---|---|---|---|---|
| 1 | `delete_tenant_canonical(p_tenant_id UUID, p_request_id UUID, p_actor_id UUID, p_correlation_id UUID)` | SECURITY DEFINER mới | Đơn vị transaction owner duy nhất: backup → audit intent → delete tenant row (CASCADE) → ghi outbox messages → commit. | SPEC-001, SPEC-003 |
| 2 | `create_delete_state(...)` | SECURITY DEFINER mới | Insert `delete_state` record ở `DELETE_REQUESTED`. | SPEC-001 |
| 3 | `update_delete_state(p_request_id UUID, p_status TEXT, p_payload JSONB)` | SECURITY DEFINER mới | Cập nhật state machine. | SPEC-001 |
| 4 | `enqueue_outbox_message(p_topic TEXT, p_payload JSONB, p_request_id UUID)` | SECURITY DEFINER mới | Ghi message vào `outbox` trong cùng transaction. | SPEC-003 |
| 5 | `process_outbox_messages(p_batch_size INTEGER)` | SECURITY DEFINER mới / cron | Lấy message `pending`, gọi storage/auth cleanup idempotently, đánh dấu `processed`/`failed`. | SPEC-003 |

### 3.3 Edge Function mới / cập nhật

| # | File | Thay đổi | SPEC |
|---|---|---|---|
| 1 | `supabase/functions/delete-tenant/index.ts` | Cập nhật: validate → gọi `delete_tenant_canonical` thay vì thực hiện nhiều bước; giữ correlation ID propagation; trả về structured status. | SPEC-001, SPEC-006 |
| 2 | `supabase/functions/outbox-processor/index.ts` | Tạo mới: cron-style hoặc HTTP-invoked processor đọc `outbox` pending, thực hiện `storage.remove` và `auth.admin.deleteUser`, đánh dấu kết quả. | SPEC-003 |

### 3.4 Service layer

| # | File | Thay đổi | SPEC |
|---|---|---|---|
| 1 | `services/tenantService.ts` | Cập nhật `hardDeleteTenant` để gọi `delete_tenant_canonical` RPC thay vì `supabase.functions.invoke('delete-tenant')`; giữ `correlationId` tùy chọn. | SPEC-001 |
| 2 | `services/outboxService.ts` | Tạo mới: thin wrapper gọi `enqueue_outbox_message` / `process_outbox_messages` cho phần frontend/admin nếu cần. | SPEC-003 |

### 3.5 Tests

| Loại | Vị trí đề xuất | Mục đích | SPEC |
|---|---|---|---|
| Unit | `supabase/tests/rpc/delete_tenant_canonical.test.sql` | Test state transition, idempotency, rollback khi constraint fail. | SPEC-007 |
| Integration | `tests/integration/delete-tenant-canonical.test.ts` | Test end-to-end `tenantService.hardDeleteTenant` → RPC → outbox → storage/auth cleanup. | SPEC-007 |
| Regression | `tests/regression/delete-tenant-500.regression.test.ts` | Đảm bảo không tái diễn lỗi HTTP 500 / FK audit. | SPEC-007 |

### 3.6 Documentation

| File | Thay đổi | Ghi chú |
|---|---|---|
| `.codebase-memory/SEMANTIC_MEMORY.md` | Thêm section Delete Framework architecture, state machine, RPC contracts. | Theo prompt, thực hiện ở Phase 5.3 |
| `ADMIN_DASHBOARD_PLAN_FIX_SPB/runbooks/DELETE_TENANT_RUNBOOK.md` | Cập nhật quy trình vận hành, rollback, manual recovery. | Tạo nếu chưa có |

---

## 4. THỨ TỰ TRIỂN KHAI (8 bước)

> **Nguyên tắc:** side-effect-free trước, destructive sau; feature flag cho mọi chuyển đổi pipeline.

| Bước | Nội dung | Lý do / rủi ro giảm thiểu | Exit Gate |
|---|---|---|---|
| **1** | Tạo các bảng mới (`delete_state`, `outbox`, `tenant_deletion_backups`) | An toàn, không ảnh hưởng production; chỉ thêm infrastructure. | Migration chạy trên staging; smoke test select/insert. |
| **2** | Tạo `delete_tenant_canonical` phiên bản **song song**, chưa active (không public trong `tenantService`) | Kiểm tra logic transaction, rollback, snapshot trước khi active. | Unit test pass; no data mutation ngoài test tenant. |
| **3** | Tạo `outbox-processor` Edge Function | Xử lý side-effect idempotent; chạy trên `outbox` test messages. | Processor hoàn thành 1 vòng lặp pending→processed. |
| **4** | Cập nhật `delete-tenant/index.ts` gọi `delete_tenant_canonical` dưới **feature flag** (`USE_CANONICAL_DELETE` env var) | Triển khai an toàn; có thể revert về legacy bằng env var. | Canary trên 1 tenant non-prod; audit + state đúng. |
| **5** | Cập nhật `tenantService.ts` `hardDeleteTenant` để gọi canonical path khi flag bật | Đồng bộ client path với Edge Function. | Integration test pass. |
| **6** | Loại bỏ audit FK (`20260725000002_audit_independence.sql`) | Rủi ro cao nhất; chạy sau khi audit writer replacement đã sẵn sàng. | Backup `app_audit_log`/`audit_log`; audit rows survive tenant deletion trong staging. |
| **7** | Migrate triggers (`20260725000003_trigger_migration.sql`) | Dời business-workflow trigger; giữ guardrail trigger. | Regression test delete-tenant-500 PASS; trigger registry cập nhật. |
| **8** | Thêm `request_id` idempotency key và retire `_legacy*` fallbacks | Cuối cùng, khi pipeline stable. | Tất cả delete paths qua canonical; legacy code đánh dấu deprecated/removed. |

---

## 5. RỦI RO VÀ GIẢM THIỂU

| Rủi ro | Mức độ | Giảm thiểu |
|---|---|---|
| Xóa nhầm tenant production trong quá trình test | **Critical** | Mọi migration/test chạy trên staging clone; canonical RPC có guard `subdomain != 'admin'`; snapshot trước delete. |
| Audit FK drop làm mất ràng buộc hoặc gây lỗi query cũ | **Critical** | Chạy migration audit independence trong transaction riêng; thêm `deleted_tenant_id` nullable trước; cập nhật queries dùng soft reference; rollback script chuẩn bị sẵn. |
| Outbox processor duplicate gây double-delete auth/storage | **Major** | `outbox.message_id` UNIQUE + `status` = `processed` guard; processor `SELECT ... FOR UPDATE SKIP LOCKED`; side-effect handlers idempotent. |
| `delete_tenant_canonical` fail giữa chừng, để lại trạng thái lấp lửng | **Major** | State machine rõ ràng (`FAILED`/`RECOVERABLE`); cron re-try `RECOVERABLE` với exponential backoff; manual runbook. |
| Trigger disable gây mất audit row cho các bảng khác | **Major** | Thay audit trigger bằng explicit audit writer calls trong application/RPC trước khi disable; regression test audit completeness. |
| Performance: `outbox` bị đầy nếu cleanup chậm | **Minor** | Lập cron mỗi 1 phút với batch size 100; metric `outbox_pending_count` + alert > 1000. |
| Feature flag bị quên bật/vô hiệu hóa | **Minor** | Env var có giá trị mặc định `false`; dashboard metric; remove flag ở bước 8. |

### Rollback Plan (mỗi bước)

- **Bước 1–3:** Drop bảng / RPC / Edge Function mới; không ảnh hưởng legacy path.
- **Bước 4–5:** Tắt `USE_CANONICAL_DELETE`; revert `tenantService.ts` commit.
- **Bước 6:** Re-add FK (migration rollback script có sẵn trong Phụ lục).
- **Bước 7:** Re-enable trigger (migration rollback script).
- **Bước 8:** Khóa rollback nếu legacy đã xóa; yêu cầu restore từ backup.

---

## 6. TIMELINE ƯỚC TÍNH

> Timeline này là ước tính tương đối, phụ thuộc vào kết quả staging validation. Không commit cụ thể.

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

## 7. EXIT CRITERIA

Implementation Plan này được coi là **hoàn thành và sẵn sàng chuyển sang Phase 5** khi:

1. `WAVE-03_PHASE-4-1_IMPLEMENTATION_PLAN.md` đã được duyệt bởi Production Owner / CTA.
2. Tất cả file migration, RPC, Edge Function, Service, Test, Documentation được liệt kê rõ ràng với đường dẫn.
3. Thứ tự triển khai 8 bước được Production Owner / CTA đồng ý.
4. Rollback plan cho mỗi bước đã được review.
5. Không có thay đổi mã nguồn, migration, schema, hoặc deploy nào xảy ra trong Phase 4.1.

---

## 8. PHỤ LỤC: SCRIPTS, COMMANDS, SQL TEMPLATES

> Các template dưới đây chỉ mang tính **minh họa** để implementer nhanh chóng bắt đầu. Code cuối cùng phải tuân thủ SPEC, coding convention repo và được viết test-first.

### 8.1 Kiểm tra migration files hiện có (trước khi đặt timestamp)

```bash
# Windows PowerShell
Get-ChildItem supabase\migrations | Sort-Object Name | Select-Object -Last 10 Name

# hoặc bash
ls -la supabase/migrations | tail -n 10
```

### 8.2 Template tạo bảng `delete_state`

```sql
-- supabase/migrations/20260725000000_create_delete_state_tables.sql
CREATE TABLE IF NOT EXISTS public.delete_state (
  request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  actor_id UUID,
  correlation_id UUID,
  action TEXT NOT NULL CHECK (action IN ('soft','hard','purge','archive')),
  status TEXT NOT NULL DEFAULT 'DELETE_REQUESTED'
    CHECK (status IN (
      'DELETE_REQUESTED','VALIDATING','PREPARING','TRANSACTION_STARTED',
      'EXECUTING','SIDE_EFFECTS_PENDING','COMMITTING','COMPLETED',
      'FAILED','ROLLBACK','RECOVERABLE','CLOSED'
    )),
  payload JSONB DEFAULT '{}',
  started_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_delete_state_tenant_id ON public.delete_state(tenant_id);
CREATE INDEX IF NOT EXISTS idx_delete_state_status ON public.delete_state(status);
```

### 8.3 Template `outbox` table

```sql
-- supabase/migrations/20260725000001_create_outbox_table.sql
CREATE TABLE IF NOT EXISTS public.outbox (
  message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES public.delete_state(request_id),
  topic TEXT NOT NULL,
  payload JSONB NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','processing','processed','failed')),
  attempts INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  processed_at TIMESTAMPTZ,
  error TEXT
);

CREATE INDEX IF NOT EXISTS idx_outbox_status_created ON public.outbox(status, created_at)
  WHERE status IN ('pending','failed');
```

### 8.4 Template audit independence migration

```sql
-- supabase/migrations/20260725000002_audit_independence.sql
BEGIN;

-- 1. Thêm soft reference trước
ALTER TABLE public.app_audit_log
  ADD COLUMN IF NOT EXISTS deleted_tenant_id UUID;

ALTER TABLE public.audit_log
  ADD COLUMN IF NOT EXISTS deleted_tenant_id UUID;

-- 2. Tạo index
CREATE INDEX IF NOT EXISTS idx_app_audit_deleted_tenant
  ON public.app_audit_log(deleted_tenant_id)
  WHERE deleted_tenant_id IS NOT NULL;

-- 3. Xóa FK (chạy sau khi code replacement đã sẵn sàng)
ALTER TABLE public.app_audit_log
  DROP CONSTRAINT IF EXISTS app_audit_log_tenant_id_fkey;

ALTER TABLE public.audit_log
  DROP CONSTRAINT IF EXISTS audit_log_tenant_id_fkey;

COMMIT;
```

### 8.5 Template RPC `delete_tenant_canonical`

```sql
CREATE OR REPLACE FUNCTION public.delete_tenant_canonical(
  p_tenant_id UUID,
  p_request_id UUID DEFAULT gen_random_uuid(),
  p_actor_id UUID DEFAULT NULL,
  p_correlation_id UUID DEFAULT NULL
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tenant public.tenants%ROWTYPE;
  v_result JSONB;
BEGIN
  -- 1. Create state
  INSERT INTO public.delete_state(request_id, tenant_id, actor_id, correlation_id, action, status)
  VALUES (p_request_id, p_tenant_id, p_actor_id, p_correlation_id, 'hard', 'DELETE_REQUESTED')
  ON CONFLICT (request_id) DO NOTHING;

  -- 2. Validate + load
  SELECT * INTO v_tenant FROM public.tenants WHERE id = p_tenant_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'tenant_not_found');
  END IF;

  IF v_tenant.subdomain = 'admin' THEN
    RETURN jsonb_build_object('success', false, 'error', 'reserved_admin_subdomain');
  END IF;

  -- 3. Backup
  INSERT INTO public.tenant_deletion_backups(request_id, tenant_id, snapshot)
  VALUES (p_request_id, p_tenant_id, to_jsonb(v_tenant));

  -- 4. Audit intent (independent, soft ref)
  INSERT INTO public.app_audit_log(
    tenant_id, deleted_tenant_id, user_id, table_name, record_id, action, new_data, ip_address
  ) VALUES (
    p_tenant_id, p_tenant_id, p_actor_id, 'tenants', p_tenant_id, 'DELETE',
    jsonb_build_object('status','hard_delete_intent','correlation_id', p_correlation_id),
    '0.0.0.0'
  );

  -- 5. Delete tenant (CASCADE handles operational rows)
  DELETE FROM public.tenants WHERE id = p_tenant_id;

  -- 6. Enqueue outbox for storage + auth cleanup
  INSERT INTO public.outbox(request_id, topic, payload)
  VALUES
    (p_request_id, 'storage.cleanup', jsonb_build_object('tenant_id', p_tenant_id)),
    (p_request_id, 'auth.cleanup',    jsonb_build_object('tenant_id', p_tenant_id));

  -- 7. Update state
  UPDATE public.delete_state
  SET status = 'SIDE_EFFECTS_PENDING', updated_at = now()
  WHERE request_id = p_request_id;

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'tenant_id', p_tenant_id,
    'status', 'SIDE_EFFECTS_PENDING'
  );
END;
$$;
```

### 8.6 Template `tenantService.ts` sửa `hardDeleteTenant`

```ts
// services/tenantService.ts
export async function hardDeleteTenant(
  tenantId: string,
  correlationId?: string
): Promise<void> {
  const cid = correlationId ?? (globalThis.crypto?.randomUUID?.() ?? `${Date.now()}-${tenantId}`);
  const requestId = globalThis.crypto?.randomUUID?.() ?? `${Date.now()}-${tenantId}`;

  const { data, error } = await supabase.rpc('delete_tenant_canonical', {
    p_tenant_id: tenantId,
    p_request_id: requestId,
    p_actor_id: null, // TODO: lấy actor từ session
    p_correlation_id: cid,
  });

  if (error) throw error;
  if (!data?.success) {
    throw new Error(data?.error || 'Xóa cửa hàng thất bại');
  }
}
```

### 8.7 Regression test checklist (template)

```ts
// tests/regression/delete-tenant-500.regression.test.ts
describe('delete-tenant canonical regression', () => {
  it('should not throw FK audit error after tenant deletion', async () => {
    const tenant = await createTestTenant();
    await expect(hardDeleteTenant(tenant.id)).resolves.not.toThrow();
    // audit row tồn tại mặc tenant đã xóa
    const { data } = await supabase
      .from('app_audit_log')
      .select('*')
      .eq('deleted_tenant_id', tenant.id)
      .single();
    expect(data).toBeTruthy();
  });
});
```

### 8.8 Command chạy migration cục bộ (không production)

```bash
supabase migration up --local    # hoặc --linked cho staging
supabase functions serve --env-file .env.local
```

---

## 9. REFERENCES

| Tài liệu | Đường dẫn |
|---|---|
| SPEC-001 | `ADMIN_DASHBOARD_PLAN_FIX_SPB/02_Specifications/SPEC-001_DELETE_FRAMEWORK_ARCHITECTURE_SPECIFICATION.md` |
| SPEC-002 | `ADMIN_DASHBOARD_PLAN_FIX_SPB/02_Specifications/SPEC-002_AUDIT_ARCHITECTURE_SPECIFICATION.md` |
| SPEC-003 | `ADMIN_DASHBOARD_PLAN_FIX_SPB/02_Specifications/SPEC-003_TRANSACTION_ARCHITECTURE_SPECIFICATION.md` |
| SPEC-004 | `ADMIN_DASHBOARD_PLAN_FIX_SPB/02_Specifications/SPEC-004_TRIGGER_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` |
| SPEC-005 | `ADMIN_DASHBOARD_PLAN_FIX_SPB/02_Specifications/SPEC-005_FOREIGN_KEY_GOVERNANCE_ARCHITECTURE_SPECIFICATION.md` |
| SPEC-006 | `ADMIN_DASHBOARD_PLAN_FIX_SPB/02_Specifications/SPEC-006_OBSERVABILITY_ARCHITECTURE_SPECIFICATION.md` |
| SPEC-007 | `ADMIN_DASHBOARD_PLAN_FIX_SPB/02_Specifications/SPEC-007_REGRESSION_VERIFICATION_ARCHITECTURE_SPECIFICATION.md` |
| SPEC-001 Review Report | `ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE-03_PHASE-2-1_SPEC-001_REVIEW_REPORT.md` |
| ROADMAP | `ADMIN_DASHBOARD_PLAN_FIX_SPB/ROADMAP.md` |
