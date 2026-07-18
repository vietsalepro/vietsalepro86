# Phase 5 — Long-term hardening

**Mục tiêu:** Thiết lập kiến trúc và quy trình để admin dashboard vận hành ổn định > 20 năm, tránh lặp lại các lỗi đã gặp.

**Ưu tiên:** Thấp / ongoing — thực hiện sau khi dashboard đã hoạt động trở lại.

---

## 1. RPC Contract Compliance Audit

### 1.1 Mục tiêu

Đảm bảo `docs/admin-dashboard/RPC_CONTRACTS.md`, `services/*.ts`, và `pg_proc` trong DB luôn đồng bộ.

### 1.2 Cách làm

Viết một script kiểm tra đơn giản bằng Node.js hoặc SQL:

```typescript
// scripts/audit-rpc-contracts.ts
import { rpcContracts } from '../docs/admin-dashboard/RPC_CONTRACTS.md'; // hoặc parse file
// So sánh với supabase.rpc('') có thể gọi được
```

Hoặc dùng SQL trực tiếp:

```sql
SELECT proname
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
  AND proname IN (
    'is_system_admin',
    'has_tenant_role',
    'get_tenants_admin',
    'get_current_user_tenants',
    'get_top_tenants',
    -- ... danh sách từ contract
  );
```

### 1.3 Tích hợp vào CI

Thêm bước vào CI pipeline:

```yaml
- name: Audit RPC contracts
  run: npx tsx scripts/audit-rpc-contracts.ts
```

Nếu phát hiện RPC trong code nhưng không có trong DB, CI fail.

---

## 2. Explicit Grants Audit

### 2.1 Quy tắc

Mỗi migration tạo function phải kèm theo:

```sql
REVOKE ALL ON FUNCTION public.xxx(...) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.xxx(...) TO authenticated;
GRANT EXECUTE ON FUNCTION public.xxx(...) TO service_role;
```

### 2.2 Script kiểm tra grants

```sql
SELECT
  n.nspname AS schema,
  p.proname AS function_name,
  array_to_string(p.proargtypes::regtype[], ', ') AS args,
  COALESCE(
    string_agg(DISTINCT r.rolname, ', '),
    'NO GRANTS'
  ) AS grantees
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
LEFT JOIN pg_namespace public_ns ON public_ns.nspname = 'public'
LEFT JOIN pg_auth_members m ON m.roleid = r.oid
LEFT JOIN LATERAL aclexplode(COALESCE(p.proacl, acldefault('f', p.proowner))) AS a ON TRUE
LEFT JOIN pg_roles r ON r.oid = a.grantee
WHERE n.nspname = 'public'
  AND p.proname LIKE 'get_%'
GROUP BY n.nspname, p.proname, p.proargtypes
ORDER BY p.proname;
```

### 2.3 Hành động

- Quét toàn bộ function `public.get_*`, `public.search_*`, `public.create_*`.
- Bổ sung `REVOKE`/`GRANT` cho các function còn thiếu.
- Không dùng `auto_expose_new_tables = true` trong `config.toml`.

---

## 3. Service Layer Defensive Mapping

### 3.1 Nguyên tắc

Frontend/service không bao giờ tin tưởng backend trả về đúng định dạng.

### 3.2 Ví dụ cải tiến

```typescript
export async function getTopTenants(options: { limit?: number; offset?: number } = {}) {
  const { data, error } = await supabase.rpc('get_top_tenants', {
    p_limit: options.limit ?? 10,
    p_offset: options.offset ?? 0,
  });
  if (error) {
    console.error('getTopTenants RPC error:', error);
    throw new Error('Không thể tải top tenants');
  }
  // Defensive: đảm bảo data có dạng object { data, count }
  const rawData = Array.isArray(data) ? { data, count: data.length } : data;
  return {
    data: (rawData?.data ?? []).map(mapTopTenantFromDB),
    count: rawData?.count ?? 0,
  };
}
```

### 3.3 Files cần rà soát

- `services/tenantService.ts`
- `services/admin/*.ts`
- `services/systemAdminService.ts`
- `services/auditService.ts`

---

## 4. Feature Flags cho tính năng chưa ổn định

### 4.1 Mục tiêu

Có thể tắt nhanh các tính năng nâng cao (GDPR, audit realtime, advanced analytics) mà không cần deploy code.

### 4.2 Cách làm

Sử dụng JSONB `tenants.settings->features` làm canonical source. Không có bảng `tenant_feature_flags`; các flag được định nghĩa trong `supabase/migrations/20250706000012_phase_p8_2_feature_flags.sql` và backfill mặc định trong `supabase/migrations/20250711000002_phase_5_long_term_admin_feature_flags.sql`.

Đọc/ghi qua các RPC:

```sql
SELECT public.get_tenant_feature_flags('tenant-uuid');
SELECT public.update_tenant_feature_flags('tenant-uuid', '{"adminGdprEnabled": true}'::jsonb);
```

Trong UI:

```typescript
const { gdprEnabled } = useAdminFeatureFlags();
if (!gdprEnabled) return null;
```

> **Close-out note (2026-07-18):** `useAdminFeatureFlags()` đã được định nghĩa nhưng chưa được bất kỳ page/component nào import. Các flag vẫn được toggle từ `pages/admin/Tenants.tsx` và lưu trong `tenants.settings->features` JSONB.

### 4.3 Tính năng nên đặt sau flag

- GDPR requests / export
- Audit log realtime
- Advanced analytics / cohort / churn
- Impersonation
- Read replica queue

---

## 5. Health Check Endpoint

### 5.1 Mục tiêu

Có một endpoint để monitoring kiểm tra trạng thái các RPC và edge function chính.

### 5.2 Triển khai

Tạo edge function `admin-health-check`:

```typescript
// supabase/functions/admin-health-check/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

serve(async (req) => {
  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

  const checks = [
    { name: 'get_top_tenants', sql: 'SELECT public.get_top_tenants(1, 0)' },
    { name: 'get_current_user_tenants', sql: 'SELECT public.get_current_user_tenants()' },
    { name: 'get_tenants_admin', sql: 'SELECT public.get_tenants_admin(1, 1)' },
  ];

  const results = [];
  for (const check of checks) {
    try {
      const { error } = await supabase.rpc('is_system_admin'); // placeholder
      results.push({ name: check.name, ok: !error, error: error?.message });
    } catch (e) {
      results.push({ name: check.name, ok: false, error: e.message });
    }
  }

  return new Response(JSON.stringify({ ok: results.every(r => r.ok), checks: results }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```

### 5.3 Tích hợp monitoring

- Uptime Robot / Better Stack ping endpoint mỗi 5 phút.
- Nếu `ok: false`, gửi cảnh báo Slack/email.

---

## 6. Multi-Environment Deployment Workflow

### 6.1 Quy trình chuẩn

```
local dev → supabase migration up / test
    ↓
staging → supabase db push --linked-staging
    ↓
production → supabase db push (sau khi staging pass)
```

### 6.2 Kiểm tra trước mỗi deploy production

- [ ] `npm run lint` PASS
- [ ] `npm run build` PASS
- [ ] `npx vitest run` PASS
- [ ] `npx supabase db test` PASS (pgtap)
- [ ] Smoke test trên staging PASS
- [ ] Backup production mới nhất

### 6.3 Không deploy vào giờ cao điểm

Nên deploy vào khung giờ thấp điểm (ví dụ: 2–5 giờ sáng theo múi giờ người dùng chính).

---

## 7. Documentation & Ownership

### 7.1 Cập nhật runbook

Mỗi khi thêm RPC mới, cập nhật:

- `docs/admin-dashboard/RPC_CONTRACTS.md`
- `docs/admin-dashboard/MIGRATION_RUNBOOK.md`
- `docs/admin-dashboard/ADMIN_DASHBOARD_DEPLOYMENT_ERROR_REMEDIATION_PLAN.md` (nếu liên quan)

### 7.2 Ownership

Ghi rõ owner cho từng subdomain:

| Component | Owner | Contact |
|-----------|-------|---------|
| Admin Dashboard UI | Frontend Team | ... |
| RPC Functions | Backend/DBA | ... |
| Edge Functions | Platform Team | ... |
| Supabase Project | DevOps | ... |

---

## 8. Kiến trúc đề xuất tổng thể

```
Frontend (Vite SPA)
    │
    ├── Service Layer (typed RPC calls + defensive mapping)
    │     └── Error normalization + toast messages
    │
    └── Supabase Client
          │
          ├── RPC Functions (public schema)
          │     ├── SECURITY INVOKER (default)
          │     ├── SECURITY DEFINER only when crossing RLS
          │     └── Explicit GRANT EXECUTE
          │
          ├── Edge Functions
          │     ├── audit-log (logging)
          │     ├── cron-admin-tasks (background jobs)
          │     ├── create-system-admin (privileged ops)
          │     └── admin-health-check (monitoring)
          │
          └── RLS Policies on tables

Migrations: idempotent, timestamped, one concern per file
Contracts: RPC_CONTRACTS.md kept in sync with code
Tests: vitest (service) + pgtap (DB) run in CI
Monitoring: health check endpoint + alerts
```

---

## 9. Checklist Phase 5

- [ ] Viết script audit RPC contracts.
- [ ] Chạy grants audit trên production, bổ sung `REVOKE`/`GRANT` còn thiếu.
- [ ] Rà soát service layer, thêm defensive mapping và error normalization.
- [ ] Thêm feature flags cho GDPR, audit realtime, advanced analytics.
- [ ] Tạo edge function `admin-health-check`.
- [ ] Thiết lập monitoring/alerting cho health check endpoint.
- [ ] Cập nhật `MIGRATION_RUNBOOK.md` và `RPC_CONTRACTS.md`.
- [ ] Xác định owner cho từng component.
- [ ] Thiết lập multi-environment deployment workflow.
- [ ] Đào tạo team về quy trình contract-first và idempotent migrations.
