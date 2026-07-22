-- Wave-04: Canonical read RPCs for residual service-layer .from() reads.
-- Replaces direct tenant_subscriptions and tenant_memberships queries in
-- services/tenantService.ts and services/admin/tenantAdminService.ts.

-- ============================================================
-- 1. get_tenant_subscription: read a single subscription row by tenant_id
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_tenant_subscription(p_tenant_id UUID)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSON;
BEGIN
  IF NOT public.is_tenant_member(p_tenant_id) AND NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Không có quyền xem subscription của tenant này' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT to_jsonb(s.*) INTO v_result
  FROM public.tenant_subscriptions s
  WHERE s.tenant_id = p_tenant_id;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_tenant_subscription(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_tenant_subscription(UUID) TO service_role;

-- ============================================================
-- 2. get_user_accounts: list tenants with role/status for an arbitrary user_id
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_user_accounts(p_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSON;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() AND NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Không có quyền xem tài khoản người dùng khác' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json) INTO v_result
  FROM (
    SELECT
      m.role,
      m.status,
      to_jsonb(ten.*) AS tenants
    FROM public.tenant_memberships m
    JOIN public.tenants ten ON ten.id = m.tenant_id
    WHERE m.user_id = p_user_id
    ORDER BY m.created_at DESC
  ) t;

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_accounts(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_accounts(UUID) TO service_role;
