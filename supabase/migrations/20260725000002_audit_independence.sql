-- === MIGRATION START: 20260725000002_audit_independence.sql ===
-- Scope: SPEC-001 / SPEC-002 / SPEC-005 — Wave-03 Phase 5.1 Step 6
-- Makes audit rows independent of the operational tenant lifecycle by:
--   1. Adding a nullable deleted_tenant_id soft reference.
--   2. Dropping the FK from app_audit_log.tenant_id -> tenants(id).
--   3. Updating delete_tenant_canonical to populate deleted_tenant_id.
--
-- WARNING: This migration removes referential-integrity enforcement on
-- app_audit_log.tenant_id. Run on staging/local first; do NOT run on
-- production without explicit Production Owner/CTA approval.
--
-- ROLLBACK (also at end of this file):
--   - Re-add the FK constraints.
--   - Restore the pre-Step-6 version of delete_tenant_canonical.

-- ============================================================
-- 1. Add soft reference column(s)
-- ============================================================

ALTER TABLE public.app_audit_log
  ADD COLUMN IF NOT EXISTS deleted_tenant_id UUID;

-- Support the legacy/secondary audit_log table if it exists in some environments.
ALTER TABLE IF EXISTS public.audit_log
  ADD COLUMN IF NOT EXISTS deleted_tenant_id UUID;

-- ============================================================
-- 2. Index the soft reference for audit survival queries
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_app_audit_deleted_tenant
  ON public.app_audit_log(deleted_tenant_id)
  WHERE deleted_tenant_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_audit_log_deleted_tenant
  ON public.audit_log(deleted_tenant_id)
  WHERE deleted_tenant_id IS NOT NULL;

-- ============================================================
-- 3. Drop FK constraints that couple audit rows to live tenants
-- ============================================================

ALTER TABLE public.app_audit_log
  DROP CONSTRAINT IF EXISTS app_audit_log_tenant_id_fkey;

ALTER TABLE IF EXISTS public.audit_log
  DROP CONSTRAINT IF EXISTS audit_log_tenant_id_fkey;

-- ============================================================
-- 4. Replace delete_tenant_canonical to populate deleted_tenant_id
-- ============================================================

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
  v_user_ids JSONB;
  v_existing_status TEXT;
BEGIN
  -- Idempotency guard
  SELECT status INTO v_existing_status
  FROM public.delete_state
  WHERE request_id = p_request_id;

  IF v_existing_status IN ('SIDE_EFFECTS_PENDING','COMMITTING','COMPLETED','CLOSED') THEN
    RETURN jsonb_build_object(
      'success', true,
      'request_id', p_request_id,
      'tenant_id', p_tenant_id,
      'status', v_existing_status
    );
  END IF;

  INSERT INTO public.delete_state(request_id, tenant_id, actor_id, correlation_id, action, status)
  VALUES (p_request_id, p_tenant_id, p_actor_id, p_correlation_id, 'hard', 'DELETE_REQUESTED')
  ON CONFLICT (request_id) DO NOTHING;

  SELECT * INTO v_tenant FROM public.tenants WHERE id = p_tenant_id;
  IF NOT FOUND THEN
    UPDATE public.delete_state
    SET status = 'FAILED', updated_at = now()
    WHERE request_id = p_request_id AND status <> 'FAILED';
    RETURN jsonb_build_object('success', false, 'error', 'tenant_not_found');
  END IF;

  IF v_tenant.subdomain = 'admin' THEN
    RETURN jsonb_build_object('success', false, 'error', 'reserved_admin_subdomain');
  END IF;

  SELECT jsonb_agg(DISTINCT user_id)
  INTO v_user_ids
  FROM (
    SELECT v_tenant.owner_id AS user_id
    UNION ALL
    SELECT user_id FROM public.tenant_memberships WHERE tenant_id = p_tenant_id
  ) u
  WHERE user_id IS NOT NULL;

  INSERT INTO public.tenant_deletion_backups(request_id, tenant_id, snapshot)
  VALUES (
    p_request_id,
    p_tenant_id,
    jsonb_build_object(
      'tenant', to_jsonb(v_tenant),
      'user_ids', COALESCE(v_user_ids, '[]'::jsonb)
    )
  );

  -- Audit intent now carries the soft reference so the audit row survives deletion.
  INSERT INTO public.app_audit_log(
    tenant_id, deleted_tenant_id, user_id, table_name, record_id, action, new_data, ip_address
  ) VALUES (
    p_tenant_id,
    p_tenant_id,
    p_actor_id,
    'tenants',
    p_tenant_id::text,
    'DELETE',
    jsonb_build_object('status','hard_delete_intent','correlation_id', p_correlation_id),
    '0.0.0.0'::inet
  );

  DELETE FROM public.tenants WHERE id = p_tenant_id;

  INSERT INTO public.outbox(request_id, topic, payload)
  VALUES
    (p_request_id, 'storage.cleanup', jsonb_build_object('tenant_id', p_tenant_id)),
    (p_request_id, 'auth.cleanup', jsonb_build_object('tenant_id', p_tenant_id, 'user_ids', COALESCE(v_user_ids, '[]'::jsonb)));

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

GRANT EXECUTE ON FUNCTION public.delete_tenant_canonical(UUID, UUID, UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_tenant_canonical(UUID, UUID, UUID, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.delete_tenant_canonical(UUID, UUID, UUID, UUID) TO anon;

-- ROLLBACK:
--
-- ALTER TABLE public.app_audit_log
--   ADD CONSTRAINT app_audit_log_tenant_id_fkey
--   FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE SET NULL;
--
-- ALTER TABLE IF EXISTS public.audit_log
--   ADD CONSTRAINT audit_log_tenant_id_fkey
--   FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE SET NULL;
--
-- DROP FUNCTION IF EXISTS public.delete_tenant_canonical(UUID, UUID, UUID, UUID);
-- (Restore the Step 2 definition from 20260725000001_create_rpc_delete_tenant_canonical.sql.)

-- === MIGRATION END: 20260725000002_audit_independence.sql ===
