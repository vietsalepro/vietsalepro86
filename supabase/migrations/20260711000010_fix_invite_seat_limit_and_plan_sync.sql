-- Fix: seat-limit enforcement and usage summary must count the same members as the invite-member edge function.
-- VIP does allow extra members (cashier, inventory_manager, accountant, admin) up to the plan's max_users,
-- but the old DB trigger counted every row including inactive ones, while the edge function counts only
-- pending/active members. This mismatch caused the DB trigger to throw a 500 after the edge function
-- pre-check had already said there was room.
--
-- Also sync tenant_subscriptions when the tenant plan is changed via update_tenant, so switching a shop
-- to VIP actually gives it the VIP limits.

-- ============================================================
-- 1. Limit trigger: count only pending/active members.
-- ============================================================
CREATE OR REPLACE FUNCTION public.check_tenant_limits()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tenant public.tenants%ROWTYPE;
  v_sub public.tenant_subscriptions%ROWTYPE;
  v_current INTEGER;
  v_max INTEGER;
BEGIN
  SELECT * INTO v_tenant FROM public.tenants WHERE id = NEW.tenant_id;
  IF NOT FOUND OR v_tenant.status NOT IN ('active', 'trial') THEN
    RAISE EXCEPTION 'Tenant không hoạt động hoặc không tồn tại';
  END IF;

  SELECT * INTO v_sub FROM public.tenant_subscriptions WHERE tenant_id = NEW.tenant_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Không tìm thấy subscription cho tenant';
  END IF;

  IF TG_TABLE_NAME = 'tenant_memberships' THEN
    SELECT count(*) INTO v_current
    FROM public.tenant_memberships
    WHERE tenant_id = NEW.tenant_id
      AND status IN ('pending', 'active');
    v_max := v_sub.max_users;
    IF v_current >= v_max THEN
      RAISE EXCEPTION 'Đã đạt giới hạn số user của gói dịch vụ';
    END IF;
  ELSIF TG_TABLE_NAME = 'products' THEN
    SELECT count(*) INTO v_current FROM public.products WHERE tenant_id = NEW.tenant_id;
    v_max := v_sub.max_products;
    IF v_current >= v_max THEN
      RAISE EXCEPTION 'Đã đạt giới hạn số sản phẩm của gói dịch vụ';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- ============================================================
-- 2. Usage summary: count only pending/active members.
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_tenant_usage_summary(p_tenant_id UUID)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
AS $$
DECLARE
  v_user_count INTEGER;
  v_product_count INTEGER;
  v_sub public.tenant_subscriptions%ROWTYPE;
  v_tenant public.tenants%ROWTYPE;
  v_current_month_orders INTEGER;
  v_current_month_start DATE;
  v_today DATE;
BEGIN
  IF NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Chỉ system admin mới được xem usage tenant' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO v_tenant FROM public.tenants WHERE id = p_tenant_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Không tìm thấy tenant: %', p_tenant_id;
  END IF;

  SELECT * INTO v_sub FROM public.tenant_subscriptions WHERE tenant_id = p_tenant_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Không tìm thấy subscription cho tenant: %', p_tenant_id;
  END IF;

  SELECT COUNT(*) INTO v_user_count
  FROM public.tenant_memberships
  WHERE tenant_id = p_tenant_id AND status IN ('pending', 'active');

  SELECT COUNT(*) INTO v_product_count FROM public.products WHERE tenant_id = p_tenant_id;

  v_today := date_trunc('month', CURRENT_DATE)::DATE;
  v_current_month_start := v_sub.current_month_start;
  IF v_current_month_start IS NULL OR v_current_month_start <> v_today THEN
    v_current_month_orders := 0;
    v_current_month_start := v_today;
  ELSE
    v_current_month_orders := v_sub.current_month_orders;
  END IF;

  RETURN json_build_object(
    'tenantId', v_sub.tenant_id,
    'plan', v_sub.plan,
    'billingStatus', v_sub.billing_status,
    'expiresAt', v_sub.expires_at,
    'users', json_build_object(
      'current', v_user_count,
      'max', v_sub.max_users,
      'percent', CASE WHEN v_sub.max_users > 0 THEN ROUND((v_user_count::NUMERIC / v_sub.max_users) * 100, 2) ELSE 0 END
    ),
    'products', json_build_object(
      'current', v_product_count,
      'max', v_sub.max_products,
      'percent', CASE WHEN v_sub.max_products > 0 THEN ROUND((v_product_count::NUMERIC / v_sub.max_products) * 100, 2) ELSE 0 END
    ),
    'orders', json_build_object(
      'current', v_current_month_orders,
      'max', v_sub.max_orders_per_month,
      'percent', CASE WHEN v_sub.max_orders_per_month > 0 THEN ROUND((v_current_month_orders::NUMERIC / v_sub.max_orders_per_month) * 100, 2) ELSE 0 END,
      'monthStart', v_current_month_start
    )
  );
END;
$$;

-- ============================================================
-- 3. Sync tenant_subscriptions when the tenant plan is changed.
-- ============================================================
CREATE OR REPLACE FUNCTION public.update_tenant(
  p_tenant_id UUID,
  p_name TEXT DEFAULT NULL,
  p_plan TEXT DEFAULT NULL,
  p_status TEXT DEFAULT NULL,
  p_isolation_mode TEXT DEFAULT NULL,
  p_isolation_schema TEXT DEFAULT NULL,
  p_isolation_project_ref TEXT DEFAULT NULL,
  p_custom_domain TEXT DEFAULT NULL,
  p_white_label JSONB DEFAULT NULL,
  p_read_replica_url TEXT DEFAULT NULL,
  p_connection_pool_config JSONB DEFAULT NULL
)
RETURNS public.tenants
LANGUAGE plpgsql
AS $_$
DECLARE
  v_tenant public.tenants;
  v_old_plan TEXT;
  v_new_isolation_mode TEXT;
  v_new_plan TEXT;
  v_domain TEXT;
  v_limits JSONB;
BEGIN
  IF NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Chỉ system admin mới được cập nhật tenant' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT * INTO v_tenant FROM public.tenants WHERE id = p_tenant_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Không tìm thấy tenant: %', p_tenant_id;
  END IF;

  IF p_name IS NOT NULL AND TRIM(p_name) = '' THEN
    RAISE EXCEPTION 'Tên cửa hàng không được để trống';
  END IF;

  IF p_plan IS NOT NULL AND NOT public.is_valid_plan(p_plan) THEN
    RAISE EXCEPTION 'Gói dịch vụ không hợp lệ: %', p_plan;
  END IF;

  IF p_status IS NOT NULL AND p_status NOT IN ('active', 'suspended', 'trial', 'pending', 'archived', 'read_only') THEN
    RAISE EXCEPTION 'Trạng thái tenant không hợp lệ: %', p_status;
  END IF;

  v_new_isolation_mode := COALESCE(p_isolation_mode, v_tenant.isolation_mode);
  IF v_new_isolation_mode IS NOT NULL AND v_new_isolation_mode NOT IN ('shared', 'schema', 'project') THEN
    RAISE EXCEPTION 'Chế độ cô lập không hợp lệ: %', v_new_isolation_mode;
  END IF;

  v_new_plan := COALESCE(p_plan, v_tenant.plan);
  v_old_plan := v_tenant.plan;

  IF v_new_isolation_mode <> 'shared' AND v_new_plan = 'free' THEN
    RAISE EXCEPTION 'Tenant gói Free không được phép cô lập schema/project. Hãy chuyển sang VIP hoặc để shared.';
  END IF;

  IF v_new_isolation_mode = 'schema' AND COALESCE(p_isolation_schema, v_tenant.isolation_schema) IS NULL THEN
    RAISE EXCEPTION 'Chế độ schema cô lập yêu cầu tên schema (isolation_schema).';
  END IF;

  IF v_new_isolation_mode = 'project' AND COALESCE(p_isolation_project_ref, v_tenant.isolation_project_ref) IS NULL THEN
    RAISE EXCEPTION 'Chế độ project cô lập yêu cầu project ref (isolation_project_ref).';
  END IF;

  v_domain := NULLIF(TRIM(p_custom_domain), '');
  IF v_domain IS NOT NULL THEN
    IF v_new_plan = 'free' THEN
      RAISE EXCEPTION 'Custom domain chỉ khả dụng cho tenant VIP.' USING ERRCODE = 'check_violation';
    END IF;
    IF v_domain !~ '^[a-z0-9][-a-z0-9]*(\.[-a-z0-9]+)+$' THEN
      RAISE EXCEPTION 'Tên miền không hợp lệ: %', v_domain;
    END IF;
    IF EXISTS (
      SELECT 1 FROM public.tenants
      WHERE lower(custom_domain) = lower(v_domain)
        AND id <> p_tenant_id
    ) THEN
      RAISE EXCEPTION 'Tên miền đã được sử dụng bởi tenant khác: %', v_domain;
    END IF;
  END IF;

  IF p_read_replica_url IS NOT NULL AND TRIM(p_read_replica_url) = '' THEN
    RAISE EXCEPTION 'read_replica_url không được để trống nếu được truyền';
  END IF;

  UPDATE public.tenants
  SET name = COALESCE(NULLIF(TRIM(p_name), ''), name),
      plan = v_new_plan,
      status = COALESCE(p_status, status),
      isolation_mode = v_new_isolation_mode,
      isolation_schema = CASE
        WHEN p_isolation_mode = 'shared' THEN NULL
        ELSE COALESCE(p_isolation_schema, isolation_schema)
      END,
      isolation_project_ref = CASE
        WHEN p_isolation_mode = 'shared' THEN NULL
        ELSE COALESCE(p_isolation_project_ref, isolation_project_ref)
      END,
      custom_domain = v_domain,
      white_label = CASE
        WHEN p_white_label IS NULL THEN white_label
        ELSE p_white_label
      END,
      read_replica_url = CASE
        WHEN p_read_replica_url IS NULL THEN read_replica_url
        ELSE NULLIF(TRIM(p_read_replica_url), '')
      END,
      connection_pool_config = CASE
        WHEN p_connection_pool_config IS NULL THEN connection_pool_config
        ELSE p_connection_pool_config
      END,
      updated_at = now()
  WHERE id = p_tenant_id
  RETURNING * INTO v_tenant;

  -- ponytail: when the plan changes, keep tenant_subscriptions in sync with the new plan's default limits.
  IF p_plan IS NOT NULL AND p_plan <> v_old_plan THEN
    v_limits := public.get_default_plan_limit_values(p_plan);
    UPDATE public.tenant_subscriptions
    SET plan = p_plan,
        max_users = COALESCE((v_limits->>'max_users')::INTEGER, 0),
        max_products = COALESCE((v_limits->>'max_products')::INTEGER, 0),
        max_orders_per_month = COALESCE((v_limits->>'max_orders_per_month')::INTEGER, 0),
        updated_at = now()
    WHERE tenant_id = p_tenant_id;
  END IF;

  RETURN v_tenant;
END;
$_$;
