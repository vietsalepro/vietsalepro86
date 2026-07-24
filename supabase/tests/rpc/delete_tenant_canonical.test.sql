-- Wave-03 Phase 5.1 Step 2 unit test
-- Tests delete_tenant_canonical: happy path, state/outbox/backup creation, and idempotency.

BEGIN;
SET LOCAL search_path = public, extensions;

SELECT plan(10);

-- ============================================================
-- Setup: admin actor and test tenant
-- ============================================================

SELECT tests.create_supabase_user(
  'rpc-delete-admin@example.com',
  '51111111-1111-1111-1111-111111111111'::uuid
);
SELECT tests.create_supabase_user(
  'rpc-delete-member@example.com',
  '52222222-2222-2222-2222-222222222222'::uuid
);

INSERT INTO public.system_admins (user_id)
VALUES ('51111111-1111-1111-1111-111111111111'::uuid);

INSERT INTO public.tenants (id, name, subdomain, status, plan, owner_id)
VALUES (
  '53333333-3333-3333-3333-333333333333'::uuid,
  'Canonical Delete Test Tenant',
  'canonical-delete-test-5-1',
  'active',
  'free',
  '51111111-1111-1111-1111-111111111111'::uuid
);

INSERT INTO public.tenant_subscriptions (tenant_id, plan, max_users, max_products, max_orders_per_month)
VALUES (
  '53333333-3333-3333-3333-333333333333'::uuid,
  'free',
  10,
  50,
  300
);

INSERT INTO public.tenants (id, name, subdomain, status, plan, owner_id)
VALUES (
  '59999999-9999-9999-9999-999999999999'::uuid,
  'Reserved Admin Tenant',
  'admin',
  'active',
  'free',
  '51111111-1111-1111-1111-111111111111'::uuid
);

INSERT INTO public.tenant_memberships (tenant_id, user_id, role)
VALUES
  ('53333333-3333-3333-3333-333333333333'::uuid, '51111111-1111-1111-1111-111111111111'::uuid, 'admin'),
  ('53333333-3333-3333-3333-333333333333'::uuid, '52222222-2222-2222-2222-222222222222'::uuid, 'member');

-- ============================================================
-- 1. Happy path: canonical hard delete returns success
-- ============================================================

SELECT ok(
  (public.delete_tenant_canonical(
    '53333333-3333-3333-3333-333333333333'::uuid,
    '54444444-4444-4444-4444-444444444444'::uuid,
    '51111111-1111-1111-1111-111111111111'::uuid,
    '55555555-5555-5555-5555-555555555555'::uuid
  ) ->> 'success') = 'true',
  'delete_tenant_canonical succeeds for a deletable tenant'
);

-- ============================================================
-- 2. Tenant row is removed
-- ============================================================

SELECT is(
  (SELECT count(*) FROM public.tenants WHERE id = '53333333-3333-3333-3333-333333333333'::uuid),
  0::bigint,
  'tenant row is deleted after canonical RPC'
);

-- ============================================================
-- 3. delete_state reaches SIDE_EFFECTS_PENDING
-- ============================================================

SELECT is(
  (SELECT status FROM public.delete_state WHERE request_id = '54444444-4444-4444-4444-444444444444'::uuid),
  'SIDE_EFFECTS_PENDING',
  'delete_state is SIDE_EFFECTS_PENDING'
);

-- ============================================================
-- 4. Snapshot backup is written
-- ============================================================

SELECT ok(
  (SELECT snapshot ? 'tenant' FROM public.tenant_deletion_backups WHERE request_id = '54444444-4444-4444-4444-444444444444'::uuid),
  'tenant_deletion_backups snapshot contains tenant'
);

-- ============================================================
-- 5. Audit intent is recorded
-- ============================================================

SELECT is(
  (SELECT count(*) FROM public.app_audit_log
   WHERE table_name = 'tenants'
     AND record_id = '53333333-3333-3333-3333-333333333333'::uuid::text
     AND action = 'DELETE'),
  1::bigint,
  'hard delete audit intent is recorded'
);

-- ============================================================
-- 6. Outbox enqueues two side-effect messages
-- ============================================================

SELECT is(
  (SELECT count(*) FROM public.outbox WHERE request_id = '54444444-4444-4444-4444-444444444444'::uuid),
  2::bigint,
  'two outbox messages are enqueued'
);

SELECT is(
  (SELECT count(*) FROM public.outbox
   WHERE request_id = '54444444-4444-4444-4444-444444444444'::uuid
     AND topic = 'storage.cleanup'),
  1::bigint,
  'storage.cleanup outbox message exists'
);

SELECT is(
  (SELECT count(*) FROM public.outbox
   WHERE request_id = '54444444-4444-4444-4444-444444444444'::uuid
     AND topic = 'auth.cleanup'),
  1::bigint,
  'auth.cleanup outbox message exists'
);

-- ============================================================
-- 7. Idempotency: reusing the same request_id returns the stored status
-- ============================================================

SELECT ok(
  (public.delete_tenant_canonical(
    '53333333-3333-3333-3333-333333333333'::uuid,
    '54444444-4444-4444-4444-444444444444'::uuid,
    '51111111-1111-1111-1111-111111111111'::uuid,
    '55555555-5555-5555-5555-555555555555'::uuid
  ) ->> 'status') = 'SIDE_EFFECTS_PENDING',
  'reusing request_id returns existing SIDE_EFFECTS_PENDING status'
);

-- ============================================================
-- 8. Admin subdomain guard
-- ============================================================

SELECT ok(
  (public.delete_tenant_canonical(
    (SELECT id FROM public.tenants WHERE subdomain = 'admin' LIMIT 1),
    '56666666-6666-6666-6666-666666666666'::uuid,
    '51111111-1111-1111-1111-111111111111'::uuid
  ) ->> 'error') = 'reserved_admin_subdomain',
  'admin subdomain cannot be deleted'
);

SELECT * FROM finish();
ROLLBACK;
