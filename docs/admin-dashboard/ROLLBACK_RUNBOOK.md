# Rollback Runbook — Admin Dashboard

## Scope

Rollback code, migration, hoặc config khi deploy gây lỗi production.

## Trigger

- Health-check FAIL sau deploy.
- Error rate tăng > 5% so với baseline.
- User report hàng loạt.
- RLS/function grant audit FAIL.

## Owner

- Primary: VietSale Pro Engineering
- Approval: Project owner (nếu SEV-1)

## Steps

### 1. Stop the bleeding

1. Bật maintenance mode nếu cần (`set_maintenance_mode` RPC).
2. Thông báo nội bộ/status page.

### 2. Rollback code

#### Vercel frontend rollback

1. Vào Vercel dashboard -> project -> Deployments.
2. Chọn deployment trước đó đang chạy ổn định.
3. Click "Promote to Production".
4. Verify production URL hoạt động.

#### Git rollback

```bash
# Find last good commit
git log --oneline -10

# Revert PR/commit
git revert --no-commit <bad-commit-hash>
git commit -m "rollback: revert <bad-commit-hash>"
git push origin main
```

### 3. Rollback database migration

> Lưu ý: Supabase migrations không hỗ trợ rollback tự động. Phải viết migration ngược hoặc restore PITR.

Option A: Reverse migration
1. Tạo migration mới undo thay đổi (ví dụ drop column, revoke grant).
2. Apply: `supabase migration up`.
3. Verify.

Option B: PITR restore
1. Dùng Supabase dashboard restore về thời điểm trước migration.
2. Xem `DISASTER_RECOVERY_RUNBOOK.md`.

### 4. Verify rollback

- `npm run lint && npm run build && npx vitest run && npm run audit:rpc`.
- Health-check `ok: true`.
- Smoke tests PASS.

### 5. Post-rollback

1. Tắt maintenance mode.
2. Viết incident report.
3. Lập kế hoạch fix root cause trước khi redeploy.

## Verification Checklist

- [ ] Production deployment ổn định.
- [ ] Error rate trở lại baseline.
- [ ] No new failed migrations.
- [ ] Stakeholders notified.

## Template: Reverse Migration

```sql
-- Example: undo a column addition safely
ALTER TABLE public.tenants DROP COLUMN IF EXISTS <column_name>;
```

Always wrap destructive changes in `IF EXISTS`.
