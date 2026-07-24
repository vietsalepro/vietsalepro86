# Rollback Runbook — Admin Dashboard

## Scope

Rollback code, migration, hoặc config khi deploy gây lỗi production.

## Trigger

- Health-check FAIL sau deploy.
- Error rate tăng > 5% so với baseline.
- User report hàng loạt.
- RLS/function grant audit FAIL.
- `D-034-01_Deployment_Validation_Gate_Definition.md` gate fail/abort during promotion.

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

> Lưu ý: Supabase migrations không hỗ trợ rollback tự động. Phải viết migration ngược dưới dạng file mới trong `supabase/migrations/` (ascending lexicographic sort) hoặc restore PITR. The canonical migration source is `supabase/migrations/*.sql`.

Option A: Reverse migration
1. Tạo migration mới trong `supabase/migrations/` undo thay đổi (ví dụ drop column, revoke grant).
2. Apply: `supabase migration up`.
3. Verify against `D-034-01_Deployment_Validation_Gate_Definition.md` and `D-P3-01_Reconciled_RPC_Contract.md`.

Option B: PITR restore
1. Dùng Supabase dashboard restore về thời điểm trước migration.
2. Xem `DISASTER_RECOVERY_RUNBOOK.md`.

### 4. Verify rollback

- `npm run lint && npm run build && npx vitest run && npm run audit:rpc` (audit validates against `D-P3-01_Reconciled_RPC_Contract.md`).
- Health-check `ok: true`.
- Smoke tests PASS.
- Reference artifact checksums match `D-035-01_Deployment_Readiness_Evidence.md` §6.1 (`supabase/schema.sql`, `supabase/generated/database.types.ts`).

### 5. Post-rollback

1. Tắt maintenance mode.
2. Viết incident report.
3. Lập kế hoạch fix root cause trước khi redeploy.

## Verification Checklist

- [ ] Production deployment ổn định.
- [ ] Error rate trở lại baseline.
- [ ] No new failed migrations.
- [ ] Stakeholders notified.
- [ ] `D-034-01` deployment validation gate PASS
- [ ] `D-035-01` reference artifact checksums verified (`supabase/schema.sql`, `supabase/generated/database.types.ts`)

## Template: Reverse Migration

```sql
-- Example: undo a column addition safely
ALTER TABLE public.tenants DROP COLUMN IF EXISTS <column_name>;
```

Always wrap destructive changes in `IF EXISTS`.

## Tenant Deletion Administration (Wave-02)

> **State of the world (verified 2026-07-24)**: The historical `delete-tenant` HTTP 500 is **fixed in production and staging**. `audit_log_trigger()` sets `tenant_id := NULL` on `tenants` DELETE (migration `20260715000011_fix_audit_log_trigger_tenant_delete.sql`), so the `audit_log_tenant_id_fkey` FK is no longer violated. The FK and `trg_audit_log_tenants` are intentionally retained. See `ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE-02_RECONCILIATION_REPORT.md`.

### Assess a failed hard delete

```sql
-- Does the tenant row still exist?
SELECT id, name, status, created_at FROM public.tenants WHERE id = '<tenant_id>';

-- Orphaned tenant-scoped rows?
SELECT 'app_audit_log' AS source, COUNT(*) FROM public.app_audit_log WHERE tenant_id = '<tenant_id>'
UNION ALL SELECT 'terms_acceptance', COUNT(*) FROM public.terms_acceptance WHERE tenant_id = '<tenant_id>'
UNION ALL SELECT 'tenant_memberships', COUNT(*) FROM public.tenant_memberships WHERE tenant_id = '<tenant_id>'
UNION ALL SELECT 'tenant_subscriptions', COUNT(*) FROM public.tenant_subscriptions WHERE tenant_id = '<tenant_id>';

-- Recent audit trail for the deletion (tenant_id is NULL by design on DELETE; match on entity_id):
SELECT action, entity_type, entity_id, actor_id, created_at
FROM public.audit_log WHERE entity_type = 'tenants' AND entity_id = '<tenant_id>' ORDER BY created_at DESC;
```

### Recovery paths

- **Tenant row still exists, side effects incomplete**: the DB transaction did not commit the delete — re-run the hard delete via the `delete-tenant` edge function (`{ "tenant_id": "<id>", "force": true }`) after confirming the failure cause. The edge function is idempotent for storage/auth cleanup (skips already-removed objects).
- **Tenant row deleted, storage/auth cleanup failed**: the edge function logs `storageFailures` / `authFailures` in its 200 response. Re-drive cleanup by listing `tenant-assets/<tenant_id>/` and removing residual objects, and delete orphaned `auth.users` that have no remaining membership/ownership.
- **Restore a deleted tenant**: high-risk; there is **no** automated pre-delete snapshot table in production today (`tenant_deletion_backups` is a deferred Wave-02 item — see reconciliation report §6). Restore only from a Supabase PITR / project backup, coordinated with the Production Owner.

### Common failure mode reference

`audit_log_tenant_id_fkey` violation on tenant DELETE — **should no longer occur**. If it reappears, verify the deployed `audit_log_trigger()` still contains the `TG_OP = 'DELETE' → v_tenant_id := NULL` branch and re-apply `20260715000011` if a later migration regressed it.

### Post-recovery verification

- [ ] `public.tenants` state matches intent (deleted or restored).
- [ ] `tenant-assets/<tenant_id>/` empty or expected objects preserved.
- [ ] Orphaned `auth.users` removed/restored.
- [ ] `admin-health-check` returns `200 OK`.
- [ ] `npm run audit:rpc` passes.
