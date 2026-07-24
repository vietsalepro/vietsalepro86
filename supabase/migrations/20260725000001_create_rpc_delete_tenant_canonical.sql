-- === MIGRATION START: 20260725000001_create_rpc_delete_tenant_canonical.sql ===
-- Scope: SPEC-001 Delete Framework — Wave-03 Phase 5.1 Step 2
-- Creates the SECURITY DEFINER RPC that owns the canonical tenant hard-delete transaction.
-- Parallel / not active yet; called only when USE_CANONICAL_DELETE feature flag is enabled.
-- Rollback: drop the function (see ROLLBACK section at end).

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
  -- ponytail: idempotency guard. If this request_id already completed the DB portion,
  -- return the stored status so side-effect retries are safe.
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

  -- Register the request; ignore duplicates caused by retry.
  INSERT INTO public.delete_state(request_id, tenant_id, actor_id, correlation_id, action, status)
  VALUES (p_request_id, p_tenant_id, p_actor_id, p_correlation_id, 'hard', 'DELETE_REQUESTED')
  ON CONFLICT (request_id) DO NOTHING;

  -- Load and validate tenant
  SELECT * INTO v_tenant FROM public.tenants WHERE id = p_tenant_id;
  IF NOT FOUND THEN
    UPDATE public.delete_state
    SET status = 'FAILED', updated_at = now()
    WHERE request_id = p_request_id AND status <> 'FAILED';
    RETURN jsonb_build_object('success', false, 'error', 'tenant_not_found');
  END IF;

  -- Guardrail: never delete the reserved admin tenant
  IF v_tenant.subdomain = 'admin' THEN
    RETURN jsonb_build_object('success', false, 'error', 'reserved_admin_subdomain');
  END IF;

  -- Collect user ids before memberships are cascaded away
  SELECT jsonb_agg(DISTINCT user_id)
  INTO v_user_ids
  FROM (
    SELECT v_tenant.owner_id AS user_id
    UNION ALL
    SELECT user_id FROM public.tenant_memberships WHERE tenant_id = p_tenant_id
  ) u
  WHERE user_id IS NOT NULL;

  -- Snapshot for recovery
  INSERT INTO public.tenant_deletion_backups(request_id, tenant_id, snapshot)
  VALUES (
    p_request_id,
    p_tenant_id,
    jsonb_build_object(
      'tenant', to_jsonb(v_tenant),
      'user_ids', COALESCE(v_user_ids, '[]'::jsonb)
    )
  );

  -- Audit intent: write BEFORE the tenant row is removed.
  -- ponytail: existing ON DELETE SET NULL FK on app_audit_log.tenant_id will null this
  -- after the tenant row is deleted; Step 6 adds a deleted_tenant_id soft reference.
  INSERT INTO public.app_audit_log(
    tenant_id, user_id, table_name, record_id, action, new_data, ip_address
  ) VALUES (
    p_tenant_id,
    p_actor_id,
    'tenants',
    p_tenant_id::text,
    'DELETE',
    jsonb_build_object('status','hard_delete_intent','correlation_id', p_correlation_id),
    '0.0.0.0'::inet
  );

  -- Execute deletion. ON DELETE CASCADE removes operational child rows.
  DELETE FROM public.tenants WHERE id = p_tenant_id;

  -- Enqueue post-commit side effects: storage cleanup and orphaned auth user cleanup.
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

-- Allow authenticated app clients and service_role edge functions to call the RPC.
GRANT EXECUTE ON FUNCTION public.delete_tenant_canonical(UUID, UUID, UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_tenant_canonical(UUID, UUID, UUID, UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.delete_tenant_canonical(UUID, UUID, UUID, UUID) TO anon;

-- ROLLBACK:
-- DROP FUNCTION IF EXISTS public.delete_tenant_canonical(UUID, UUID, UUID, UUID);

-- === MIGRATION END: 20260725000001_create_rpc_delete_tenant_canonical.sql ===
