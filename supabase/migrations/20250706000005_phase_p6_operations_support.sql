-- P6: Admin dashboard — Operations & support cơ bản
-- Data retention status, default plan limits, maintenance mode, system settings.
-- ponytail: migration idempotent; chỉ system admin được gọi các RPC này.

-- ============================================================
-- 1. System settings table (key-value JSONB)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.system_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by UUID
);

ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'system_settings' AND policyname = 'system_settings_system_admin_select'
  ) THEN
    CREATE POLICY "system_settings_system_admin_select"
      ON public.system_settings FOR SELECT TO authenticated
      USING (public.is_system_admin());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'system_settings' AND policyname = 'system_settings_system_admin_write'
  ) THEN
    CREATE POLICY "system_settings_system_admin_write"
      ON public.system_settings FOR ALL TO authenticated
      USING (public.is_system_admin())
      WITH CHECK (public.is_system_admin());
  END IF;
END $$;

ALTER TABLE public.system_settings
  ALTER COLUMN updated_by DROP DEFAULT;

CREATE OR REPLACE FUNCTION public.system_settings_set_updated_by()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  NEW.updated_by := auth.uid();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS system_settings_updated_by_trigger ON public.system_settings;
CREATE TRIGGER system_settings_updated_by_trigger
  BEFORE INSERT OR UPDATE ON public.system_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.system_settings_set_updated_by();

-- ============================================================
-- 2. Seed default settings
-- ============================================================

INSERT INTO public.system_settings (key, value) VALUES
  ('default_limits_free', jsonb_build_object(
    'max_users', 1,
    'max_products', 50,
    'max_orders_per_month', 300
  )),
  ('default_limits_vip', jsonb_build_object(
    'max_users', 999,
    'max_products', 999999,
    'max_orders_per_month', 999999
  )),
  ('maintenance_mode', jsonb_build_object(
    'enabled', false,
    'message', ''
  )),
  ('data_retention_cron', jsonb_build_object(
    'schedule', '0 3 * * *',
    'description', 'Hàng ngày lúc 03:00'
  ))
ON CONFLICT (key) DO NOTHING;

-- ============================================================
-- 3. Helper to read default plan limits safely
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_default_plan_limit_values(p_plan TEXT)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
AS $$
DECLARE
  v_limits JSONB;
BEGIN
  IF p_plan NOT IN ('free', 'vip') THEN
    RAISE EXCEPTION 'Gói dịch vụ không hợp lệ: %', p_plan;
  END IF;

  SELECT value INTO v_limits
  FROM public.system_settings
  WHERE key = 'default_limits_' || p_plan;

  RETURN COALESCE(v_limits, '{}'::jsonb);
END;
$$;

-- ============================================================
-- 4. RPC: lấy trạng thái data retention
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_data_retention_status()
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
AS $$
DECLARE
  v_archived_orders BIGINT;
  v_archived_items BIGINT;
  v_rate_limit_count BIGINT;
  v_last_run JSONB;
  v_cron_setting JSONB;
  v_cron_job JSONB;
BEGIN
  IF NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Chỉ system admin mới được xem trạng thái data retention' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT COUNT(*) INTO v_archived_orders FROM public.orders_archive;
  SELECT COUNT(*) INTO v_archived_items FROM public.order_items_archive;
  SELECT COUNT(*) INTO v_rate_limit_count FROM public.rate_limit_logs;

  SELECT value INTO v_last_run FROM public.system_settings WHERE key = 'data_retention_last_run';
  SELECT value INTO v_cron_setting FROM public.system_settings WHERE key = 'data_retention_cron';

  -- ponytail: thử đọc cron.job nếu có quyền; nếu không thì dùng setting.
  BEGIN
    SELECT jsonb_build_object('jobid', jobid, 'jobname', jobname, 'schedule', schedule, 'active', active)
    INTO v_cron_job
    FROM cron.job
    WHERE jobname = 'data-retention-daily';
  EXCEPTION WHEN OTHERS THEN
    v_cron_job := NULL;
  END;

  RETURN json_build_object(
    'archivedOrdersCount', COALESCE(v_archived_orders, 0),
    'archivedOrderItemsCount', COALESCE(v_archived_items, 0),
    'rateLimitLogsCount', COALESCE(v_rate_limit_count, 0),
    'lastRun', v_last_run,
    'cronSchedule', COALESCE(v_cron_setting->>'schedule', '0 3 * * *'),
    'cronJob', v_cron_job
  );
END;
$$;

-- ============================================================
-- 5. RPC: lấy cấu hình giới hạn mặc định Free/VIP
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_default_plan_limits()
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
AS $$
DECLARE
  v_free JSONB;
  v_vip JSONB;
BEGIN
  IF NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Chỉ system admin mới được xem cấu hình giới hạn' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT value INTO v_free FROM public.system_settings WHERE key = 'default_limits_free';
  SELECT value INTO v_vip FROM public.system_settings WHERE key = 'default_limits_vip';

  RETURN json_build_object(
    'free', COALESCE(v_free, jsonb_build_object('max_users', 1, 'max_products', 50, 'max_orders_per_month', 300)),
    'vip', COALESCE(v_vip, jsonb_build_object('max_users', 999, 'max_products', 999999, 'max_orders_per_month', 999999))
  );
END;
$$;

-- ============================================================
-- 6. RPC: cập nhật giới hạn mặc định của một gói
-- ============================================================

CREATE OR REPLACE FUNCTION public.set_default_plan_limits(
  p_plan TEXT,
  p_max_users INTEGER,
  p_max_products INTEGER,
  p_max_orders_per_month INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_key TEXT;
  v_value JSONB;
BEGIN
  IF NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Chỉ system admin mới được cập nhật giới hạn mặc định' USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF p_plan NOT IN ('free', 'vip') THEN
    RAISE EXCEPTION 'Gói dịch vụ không hợp lệ: %', p_plan;
  END IF;

  IF p_max_users <= 0 OR p_max_products <= 0 OR p_max_orders_per_month <= 0 THEN
    RAISE EXCEPTION 'Giới hạn phải lớn hơn 0';
  END IF;

  v_key := 'default_limits_' || p_plan;
  v_value := jsonb_build_object(
    'max_users', p_max_users,
    'max_products', p_max_products,
    'max_orders_per_month', p_max_orders_per_month
  );

  INSERT INTO public.system_settings (key, value)
  VALUES (v_key, v_value)
  ON CONFLICT (key) DO UPDATE
    SET value = EXCLUDED.value,
        updated_at = now()
  RETURNING value INTO v_value;

  RETURN v_value;
END;
$$;

-- ============================================================
-- 7. RPC: bật/tắt maintenance mode
-- ============================================================

CREATE OR REPLACE FUNCTION public.set_maintenance_mode(
  p_enabled BOOLEAN,
  p_message TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_value JSONB;
BEGIN
  IF NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Chỉ system admin mới được cập nhật maintenance mode' USING ERRCODE = 'insufficient_privilege';
  END IF;

  v_value := jsonb_build_object(
    'enabled', COALESCE(p_enabled, false),
    'message', COALESCE(p_message, '')
  );

  INSERT INTO public.system_settings (key, value)
  VALUES ('maintenance_mode', v_value)
  ON CONFLICT (key) DO UPDATE
    SET value = EXCLUDED.value,
        updated_at = now()
  RETURNING value INTO v_value;

  RETURN v_value;
END;
$$;

-- ============================================================
-- 8. RPC: lấy maintenance mode
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_maintenance_mode()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
AS $$
DECLARE
  v_value JSONB;
BEGIN
  IF NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Chỉ system admin mới được xem maintenance mode' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT value INTO v_value FROM public.system_settings WHERE key = 'maintenance_mode';
  RETURN COALESCE(v_value, jsonb_build_object('enabled', false, 'message', ''));
END;
$$;

-- ============================================================
-- 9. Cập nhật tạo tenant để dùng default limits từ system_settings
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_tenant_with_admin(
  p_name TEXT,
  p_subdomain TEXT,
  p_plan TEXT DEFAULT 'free',
  p_owner_user_id UUID DEFAULT NULL
)
RETURNS public.tenants
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_owner_id UUID;
  v_tenant public.tenants;
  v_plan TEXT;
  v_limits JSONB;
BEGIN
  IF NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Chỉ system admin mới được tạo tenant' USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RAISE EXCEPTION 'Tên cửa hàng không được để trống';
  END IF;

  IF p_subdomain IS NULL OR TRIM(p_subdomain) = '' THEN
    RAISE EXCEPTION 'Subdomain không được để trống';
  END IF;

  v_plan := COALESCE(p_plan, 'free');
  IF v_plan NOT IN ('free', 'vip') THEN
    RAISE EXCEPTION 'Gói dịch vụ không hợp lệ: %', v_plan;
  END IF;

  v_owner_id := COALESCE(p_owner_user_id, auth.uid());
  IF v_owner_id IS NULL THEN
    RAISE EXCEPTION 'Không xác định được chủ sở hữu tenant';
  END IF;

  INSERT INTO public.tenants (name, subdomain, plan, owner_id, status)
  VALUES (TRIM(p_name), TRIM(p_subdomain), v_plan, v_owner_id, 'active')
  RETURNING * INTO v_tenant;

  -- ponytail: đọc giới hạn mặc định từ system_settings; fallback về hardcoded nếu chưa có.
  v_limits := public.get_default_plan_limit_values(v_plan);

  INSERT INTO public.tenant_subscriptions (tenant_id, plan, max_users, max_products, max_orders_per_month)
  VALUES (
    v_tenant.id,
    v_plan,
    COALESCE((v_limits->>'max_users')::INTEGER, CASE WHEN v_plan = 'free' THEN 1 ELSE 999 END),
    COALESCE((v_limits->>'max_products')::INTEGER, CASE WHEN v_plan = 'free' THEN 50 ELSE 999999 END),
    COALESCE((v_limits->>'max_orders_per_month')::INTEGER, CASE WHEN v_plan = 'free' THEN 300 ELSE 999999 END)
  );

  INSERT INTO public.tenant_memberships (tenant_id, user_id, role)
  VALUES (v_tenant.id, v_owner_id, 'admin');

  RETURN v_tenant;
END;
$$;

-- ============================================================
-- 10. Ghi log sau mỗi lần chạy data retention
-- ============================================================

CREATE OR REPLACE PROCEDURE public.run_data_retention()
LANGUAGE plpgsql
AS $$
DECLARE
  v_cutoff_orders TIMESTAMPTZ;
  v_cutoff_processed TIMESTAMPTZ;
  v_cutoff_rate_limit TIMESTAMPTZ;
  v_partition_name TEXT;
  v_partition_year INT;
  v_partition_month INT;
  v_current_threshold INT;
  v_match TEXT[];
BEGIN
  v_cutoff_orders := now() - INTERVAL '2 years';
  v_cutoff_processed := now() - INTERVAL '90 days';
  v_cutoff_rate_limit := now() - INTERVAL '24 hours';
  v_current_threshold := (EXTRACT(YEAR FROM now())::int - 2) * 12 + EXTRACT(MONTH FROM now())::int;

  INSERT INTO public.orders_archive
  SELECT * FROM public.orders
  WHERE created_at < v_cutoff_orders
  ON CONFLICT DO NOTHING;

  INSERT INTO public.order_items_archive
  SELECT oi.* FROM public.order_items oi
  JOIN public.orders o ON oi.order_id = o.id
  WHERE o.created_at < v_cutoff_orders
  ON CONFLICT DO NOTHING;

  DELETE FROM public.order_items oi
  WHERE oi.order_id IN (
    SELECT id FROM public.orders WHERE created_at < v_cutoff_orders
  );

  DELETE FROM public.orders
  WHERE created_at < v_cutoff_orders;

  DELETE FROM public.processed_operations
  WHERE processed_at < v_cutoff_processed;

  DELETE FROM public.rate_limit_logs
  WHERE created_at < v_cutoff_rate_limit;

  IF EXISTS (
    SELECT 1 FROM pg_class
    WHERE relname = 'app_audit_log_partitioned' AND relkind = 'p'
  ) THEN
    FOR v_partition_name IN
      SELECT inhrelid::regclass::text
      FROM pg_inherits
      WHERE inhparent = 'public.app_audit_log_partitioned'::regclass
    LOOP
      v_match := regexp_match(v_partition_name, '(\d{4})_(\d{2})$');
      IF v_match IS NOT NULL THEN
        v_partition_year := v_match[1]::int;
        v_partition_month := v_match[2]::int;
        IF (v_partition_year * 12 + v_partition_month) < v_current_threshold THEN
          EXECUTE format('DROP TABLE IF EXISTS %I', v_partition_name);
        END IF;
      END IF;
    END LOOP;
  END IF;

  -- ponytail: ghi lại thời điểm chạy để dashboard hiển thị.
  INSERT INTO public.system_settings (key, value)
  VALUES ('data_retention_last_run', jsonb_build_object('run_at', now()))
  ON CONFLICT (key) DO UPDATE
    SET value = EXCLUDED.value,
        updated_at = now();
END;
$$;
