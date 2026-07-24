-- Wave-03 Phase 5.1 Step 6 regression test
-- Verifies audit rows survive tenant deletion via the deleted_tenant_id soft reference
-- and that the FK coupling is removed.

BEGIN;
SET LOCAL search_path = public, extensions;

SELECT plan(5);

-- ============================================================
-- Schema assertions
-- ============================================================

SELECT has_column('public', 'app_audit_log', 'deleted_tenant_id', 'app_audit_log has deleted_tenant_id');

SELECT ok(
  NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'app_audit_log_tenant_id_fkey'
      AND table_schema = 'public'
      AND table_name = 'app_audit_log'
  ),
  'app_audit_log tenant_id FK is dropped'
);

-- ============================================================
-- Functional assertion: audit row survives tenant deletion
-- ============================================================

SELECT tests.create_supabase_user(
  'audit-indep-admin@example.com',
  '61111111-1111-1111-1111-111111111111'::uuid
);

INSERT INTO public.system_admins (user_id)
VALUES ('61111111-1111-1111-1111-111111111111'::uuid);

INSERT INTO public.tenants (id, name, subdomain, status, plan, owner_id)
VALUES (
  '62222222-2222-2222-2222-222222222222'::uuid,
  'Audit Independence Test Tenant',
  'audit-indep-test-5-1',
  'active',
  'free',
  '61111111-1111-1111-1111-111111111111'::uuid
);

INSERT INTO public.tenant_subscriptions (tenant_id, plan, max_users, max_products, max_orders_per_month)
VALUES (
  '62222222-2222-2222-2222-222222222222'::uuid,
  'free',
  10,
  50,
  300
);

INSERT INTO public.tenant_memberships (tenant_id, user_id, role)
VALUES
  ('62222222-2222-2222-2222-222222222222'::uuid, '61111111-1111-1111-1111-111111111111'::uuid, 'admin');

SELECT ok(
  (public.delete_tenant_canonical(
    '62222222-2222-2222-2222-222222222222'::uuid,
    '63333333-3333-3333-3333-333333333333'::uuid,
    '61111111-1111-1111-1111-111111111111'::uuid,
    '64444444-4444-4444-4444-444444444444'::uuid
  ) ->> 'success') = 'true',
  'delete_tenant_canonical succeeds after audit independence migration'
);

SELECT is(
  (SELECT count(*) FROM public.tenants WHERE id = '62222222-2222-2222-2222-222222222222'::uuid),
  0::bigint,
  'tenant is removed'
);

SELECT is(
  (SELECT count(*) FROM public.app_audit_log
   WHERE deleted_tenant_id = '62222222-2222-2222-2222-222222222222'::uuid
     AND action = 'DELETE'),
  1::bigint,
  'audit intent row survives with deleted_tenant_id soft reference'
);

SELECT * FROM finish();
ROLLBACK;
