CREATE OR REPLACE FUNCTION public.get_admin_audit_logs(
  p_limit INT DEFAULT 100,
  p_tenant_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  tenant_id UUID,
  actor_id UUID,
  action TEXT,
  entity_type TEXT,
  entity_id UUID,
  old_data JSONB,
  new_data JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Chỉ system admin mới được xem audit log' USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN QUERY
  SELECT l.id, l.tenant_id, l.actor_id, l.action, l.entity_type, l.entity_id, l.old_data, l.new_data, l.ip_address, l.created_at
  FROM public.audit_log l
  WHERE (p_tenant_id IS NULL OR l.tenant_id = p_tenant_id)
  ORDER BY l.created_at DESC
  LIMIT p_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.get_admin_audit_logs(INT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_admin_audit_logs(INT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_audit_logs(INT, UUID) TO service_role;

CREATE OR REPLACE FUNCTION public.get_cron_job_logs(
  p_limit INT DEFAULT 100
)
RETURNS TABLE (
  id UUID,
  job_name TEXT,
  status TEXT,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  details JSONB,
  error_message TEXT,
  retry_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Chỉ system admin mới được xem cron job log' USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN QUERY
  SELECT l.id, l.job_name, l.status, l.started_at, l.completed_at, l.details, l.error_message, l.retry_count
  FROM public.cron_job_logs l
  ORDER BY l.started_at DESC
  LIMIT p_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.get_cron_job_logs(INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_cron_job_logs(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_cron_job_logs(INT) TO service_role;

CREATE OR REPLACE FUNCTION public.get_billing_reminder_logs(
  p_limit INT DEFAULT 100,
  p_tenant_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  tenant_id UUID,
  reminder_type TEXT,
  status TEXT,
  sent_at TIMESTAMPTZ,
  error_message TEXT,
  created_at TIMESTAMPTZ,
  created_date DATE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Chỉ system admin mới được xem billing reminder log' USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN QUERY
  SELECT l.id, l.tenant_id, l.reminder_type, l.status, l.sent_at, l.error_message, l.created_at, l.created_date
  FROM public.billing_reminder_logs l
  WHERE (p_tenant_id IS NULL OR l.tenant_id = p_tenant_id)
  ORDER BY l.created_at DESC
  LIMIT p_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.get_billing_reminder_logs(INT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_billing_reminder_logs(INT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_billing_reminder_logs(INT, UUID) TO service_role;

CREATE OR REPLACE FUNCTION public.get_billing_email_logs(
  p_limit INT DEFAULT 100,
  p_tenant_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  tenant_id UUID,
  invoice_id UUID,
  type TEXT,
  recipient TEXT,
  status TEXT,
  provider_message_id TEXT,
  error_message TEXT,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Chỉ system admin mới được xem billing email log' USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN QUERY
  SELECT l.id, l.tenant_id, l.invoice_id, l.type, l.recipient, l.status, l.provider_message_id, l.error_message, l.created_at
  FROM public.billing_email_logs l
  WHERE (p_tenant_id IS NULL OR l.tenant_id = p_tenant_id)
  ORDER BY l.created_at DESC
  LIMIT p_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.get_billing_email_logs(INT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_billing_email_logs(INT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_billing_email_logs(INT, UUID) TO service_role;
