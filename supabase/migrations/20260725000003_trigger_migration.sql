-- === MIGRATION START: 20260725000003_trigger_migration.sql ===
-- Scope: SPEC-001 / SPEC-004 — Wave-03 Phase 5.1 Step 7
-- Disables business-workflow audit triggers so delete audit is written explicitly
-- by the canonical RPC/application code, not by AFTER DELETE triggers.
--
-- Guardrail triggers remain enabled:
--   - tenants_before_delete_guardrail (BEFORE DELETE on tenants)
--   - tenant_memberships_guardrails (BEFORE DELETE/UPDATE on tenant_memberships)
--   - set_tenant_record_user_tracking (BEFORE INSERT/UPDATE on tenants/products/orders/...)
--   - trg_app_audit_log_login_enforcement (BEFORE INSERT/UPDATE on app_audit_log)
--
-- WARNING: Disables audit automation for many tables. Run on staging/local first.
-- Do NOT run on production without explicit Production Owner/CTA approval.
--
-- ROLLBACK (at end of file): re-enable all disabled triggers.

DO $$
DECLARE
  v_pair text;
  v_parts text[];
  v_table text;
  v_trigger text;
  v_pairs text[] := array[
    'public.orders,trg_audit_log_orders',
    'public.products,trg_audit_log_products',
    'public.import_receipts,trg_audit_log_import_receipts',
    'public.disposals,trg_audit_log_disposals',
    'public.app_settings,trg_audit_log_app_settings',
    'public.tenants,trg_audit_log_tenants',
    'public.tenant_memberships,trg_audit_log_tenant_memberships',
    'public.tenant_memberships,tenant_memberships_audit',
    'public.tenant_subscriptions,trg_audit_log_tenant_subscriptions',
    'public.system_admins,trg_audit_log_system_admins',
    'public.invitations,trg_audit_log_invitations',
    'public.licenses,trg_audit_log_licenses'
  ];
BEGIN
  FOREACH v_pair IN ARRAY v_pairs
  LOOP
    v_parts := string_to_array(v_pair, ',');
    v_table := v_parts[1];
    v_trigger := v_parts[2];

    IF EXISTS (
      SELECT 1
      FROM pg_trigger t
      JOIN pg_class c ON t.tgrelid = c.oid
      JOIN pg_namespace n ON c.relnamespace = n.oid
      WHERE t.tgname = v_trigger
        AND n.nspname || '.' || c.relname = v_table
    ) THEN
      EXECUTE format('ALTER TABLE %s DISABLE TRIGGER %I', v_table, v_trigger);
    END IF;
  END LOOP;
END $$;

-- ROLLBACK:
-- DO $$
-- DECLARE
--   v_pair text;
--   v_parts text[];
--   v_table text;
--   v_trigger text;
--   v_pairs text[] := array[
--     'public.orders,trg_audit_log_orders',
--     'public.products,trg_audit_log_products',
--     'public.import_receipts,trg_audit_log_import_receipts',
--     'public.disposals,trg_audit_log_disposals',
--     'public.app_settings,trg_audit_log_app_settings',
--     'public.tenants,trg_audit_log_tenants',
--     'public.tenant_memberships,trg_audit_log_tenant_memberships',
--     'public.tenant_memberships,tenant_memberships_audit',
--     'public.tenant_subscriptions,trg_audit_log_tenant_subscriptions',
--     'public.system_admins,trg_audit_log_system_admins',
--     'public.invitations,trg_audit_log_invitations',
--     'public.licenses,trg_audit_log_licenses'
--   ];
-- BEGIN
--   FOREACH v_pair IN ARRAY v_pairs
--   LOOP
--     v_parts := string_to_array(v_pair, ',');
--     v_table := v_parts[1];
--     v_trigger := v_parts[2];
--     EXECUTE format('ALTER TABLE %s ENABLE TRIGGER %I', v_table, v_trigger);
--   END LOOP;
-- END $$;

-- === MIGRATION END: 20260725000003_trigger_migration.sql ===
