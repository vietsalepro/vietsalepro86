-- P9.1.1: Billing reminders bugfix delta.
-- Applied after P9.1 migration (20250707000000_phase_p9_1_billing_reminders.sql).
-- Fixes:
--   1. GRANT EXECUTE for the 4 P9.1 RPCs to authenticated role (frontend Data API).
--   2. Reject empty milestones array in set_billing_reminder_config.
-- ponytail: idempotent GRANTs; function bodies replaced with CREATE OR REPLACE.

-- ============================================================
-- 1. EXECUTE grants for authenticated role
-- ============================================================
GRANT EXECUTE ON FUNCTION public.get_billing_reminder_config() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_billing_reminder_config() TO service_role;

GRANT EXECUTE ON FUNCTION public.set_billing_reminder_config(BOOLEAN, INT[], TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_billing_reminder_config(BOOLEAN, INT[], TEXT, TEXT, TEXT) TO service_role;

GRANT EXECUTE ON FUNCTION public.get_pending_billing_reminders() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_pending_billing_reminders() TO service_role;

GRANT EXECUTE ON FUNCTION public.send_billing_reminders() TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_billing_reminders() TO service_role;

-- ============================================================
-- 2. Empty milestones validation
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_billing_reminder_config(
  p_enabled BOOLEAN,
  p_milestones INT[],
  p_send_time TEXT DEFAULT '09:00',
  p_function_url TEXT DEFAULT '',
  p_reminder_secret TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET timezone = 'Asia/Ho_Chi_Minh'
AS $$
DECLARE
  v_value JSONB;
  v_milestones INT[];
BEGIN
  -- Validate milestones: positive days, deduplicate, sorted, non-empty.
  v_milestones := ARRAY(SELECT DISTINCT unnest(p_milestones) ORDER BY 1);
  IF array_length(v_milestones, 1) IS NULL OR array_length(v_milestones, 1) = 0 OR EXISTS (SELECT 1 FROM unnest(v_milestones) x WHERE x <= 0) THEN
    RAISE EXCEPTION 'milestones phải là mảng số nguyên dương không rỗng';
  END IF;

  v_value := jsonb_build_object(
    'enabled', p_enabled,
    'milestones', to_jsonb(v_milestones),
    'send_time', COALESCE(p_send_time, '09:00'),
    'function_url', COALESCE(p_function_url, ''),
    'reminder_secret', COALESCE(p_reminder_secret, '')
  );

  INSERT INTO public.system_settings (key, value)
  VALUES ('billing_reminder_config', v_value)
  ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

  RETURN v_value;
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_billing_reminder_config(BOOLEAN, INT[], TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_billing_reminder_config(BOOLEAN, INT[], TEXT, TEXT, TEXT) TO service_role;
