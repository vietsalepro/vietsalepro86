# Disaster Recovery Runbook — Admin Dashboard

## Scope

Phục hồi hệ thống sau sự cố nghiêm trọng: mất dữ liệu, corruption, Supabase project failure, hoặc extended outage.

## RTO / RPO

- RTO: 4 giờ
- RPO: 1 giờ

## Owner

- Primary: VietSale Pro Engineering
- Backup: Project owner

## Prerequisites

- Supabase project refs: staging `shbmzvfcenbybvyzclem`, production `rsialbfjswnrkzcxarnj`.
- Access: Supabase dashboard, Supabase CLI, Vercel dashboard, DNS provider.
- Backup locations: Supabase PITR + manual backups nếu có.

## Steps

### 1. Assess impact

- Kiểm tra Supabase status page.
- Ping health-check edge function.
- Kiểm tra Vercel deployment status.

### 2. Activate recovery

#### Scenario A: Database corruption / accidental data loss

1. Tạm dừng mọi write operation (enable maintenance mode nếu có RPC `set_maintenance_mode`).
2. Xác định thời điểm cần restore (PITR) qua Supabase dashboard.
3. Restore production DB về thời điểm trước sự cố.
4. Verify dữ liệu qua health-check và smoke tests.

```bash
# Example: restore via Supabase CLI (verify exact command with current CLI version)
supabase projects restore --project-ref rsialbfjswnrkzcxarnj --target-time "2026-07-12T10:00:00Z"
```

#### Scenario B: Supabase project complete failure

1. Tạo project mới hoặc dùng staging project.
2. Apply migrations từ `supabase/migrations/` theo thứ tự.
3. Restore data từ backup gần nhất.
4. Cập nhật `SUPABASE_URL` / `SUPABASE_ANON_KEY` / `SUPABASE_SERVICE_ROLE_KEY` trong Vercel env.
5. Redeploy frontend.

#### Scenario C: Frontend / Vercel failure

1. Rollback deployment trong Vercel dashboard.
2. Verify build với `npm run build`.
3. Redeploy production.

### 3. Verify

- Health-check `ok: true`.
- `npm run audit:rpc` PASS.
- Smoke tests: tenant isolation, login, billing list.

### 4. Communicate

- Cập nhật status page/email cho affected users.
- Ghi log vào `Plan/Log/DR-<timestamp>.md`.

## Verification Checklist

- [ ] DB accessible.
- [ ] All migrations applied.
- [ ] RPC contracts match `docs/admin-dashboard/RPC_CONTRACTS.md`.
- [ ] Health-check endpoint PASS.
- [ ] Critical admin flows smoke tested.

## Annual DR Drill

- Thực hiện drill restore lên staging environment mỗi 6 tháng.
- Ghi kết quả vào `Plan/Log/DR-DRILL-<timestamp>.md`.
