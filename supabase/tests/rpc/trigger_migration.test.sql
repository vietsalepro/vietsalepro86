-- Wave-03 Phase 5.1 Step 7 regression test
-- Verifies business-workflow audit triggers are disabled while guardrail triggers remain enabled.

BEGIN;
SET LOCAL search_path = public, extensions;

SELECT plan(4);

-- Business workflow audit triggers should be disabled
SELECT is(
  (SELECT count(*) FROM pg_trigger t
   JOIN pg_class c ON t.tgrelid = c.oid
   JOIN pg_namespace n ON c.relnamespace = n.oid
   WHERE n.nspname = 'public'
     AND t.tgname IN (
       'trg_audit_log_orders','trg_audit_log_products','trg_audit_log_import_receipts',
       'trg_audit_log_disposals','trg_audit_log_app_settings','trg_audit_log_tenants',
       'trg_audit_log_tenant_memberships','tenant_memberships_audit',
       'trg_audit_log_tenant_subscriptions','trg_audit_log_system_admins',
       'trg_audit_log_invitations','trg_audit_log_licenses'
     )
     AND t.tgenabled = 'D'),
  12::bigint,
  'all business-workflow audit triggers are disabled'
);

-- Guardrail trigger names must each be enabled on at least one table
SELECT ok(
  (SELECT count(DISTINCT t.tgname) FROM pg_trigger t
   JOIN pg_class c ON t.tgrelid = c.oid
   JOIN pg_namespace n ON c.relnamespace = n.oid
   WHERE n.nspname = 'public'
     AND t.tgname IN (
       'tenants_before_delete_guardrail',
       'tenant_memberships_guardrails',
       'set_tenant_record_user_tracking',
       'trg_app_audit_log_login_enforcement'
     )
     AND t.tgenabled = 'O') = 4,
  'all four guardrail trigger names are enabled'
);

-- tenants_before_delete_guardrail specifically enabled
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public' AND c.relname = 'tenants'
      AND t.tgname = 'tenants_before_delete_guardrail' AND t.tgenabled = 'O'
  ),
  'tenants_before_delete_guardrail is enabled'
);

-- tenant_memberships_guardrails specifically enabled
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public' AND c.relname = 'tenant_memberships'
      AND t.tgname = 'tenant_memberships_guardrails' AND t.tgenabled = 'O'
  ),
  'tenant_memberships_guardrails is enabled'
);

SELECT * FROM finish();
ROLLBACK;
