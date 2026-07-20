-- Wave-02 Package-02: audit triggers for privileged tables and LOGIN/LOGOUT enforcement.
-- Addresses DB-004, DB-009, SEC-005 (folded); RPC alignment for DB-006/DB-007/RPC-003.

-- 1. Refresh get_admin_audit_logs with full filter/offset/count support for the audit UI.
DROP FUNCTION IF EXISTS public.get_admin_audit_logs(INT, UUID) CASCADE;

CREATE OR REPLACE FUNCTION public.get_admin_audit_logs(
  p_limit INT DEFAULT 100,
  p_offset INT DEFAULT 0,
  p_tenant_id UUID DEFAULT NULL,
  p_actor_id UUID DEFAULT NULL,
  p_action TEXT DEFAULT NULL,
  p_entity_type TEXT DEFAULT NULL,
  p_entity_id UUID DEFAULT NULL,
  p_date_from TIMESTAMPTZ DEFAULT NULL,
  p_date_to TIMESTAMPTZ DEFAULT NULL
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
  created_at TIMESTAMPTZ,
  total_count BIGINT
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
  SELECT l.id, l.tenant_id, l.actor_id, l.action, l.entity_type, l.entity_id, l.old_data, l.new_data, l.ip_address, l.created_at,
         COUNT(*) OVER() AS total_count
  FROM public.audit_log l
  WHERE (p_tenant_id IS NULL OR l.tenant_id = p_tenant_id)
    AND (p_actor_id IS NULL OR l.actor_id = p_actor_id)
    AND (p_action IS NULL OR l.action = p_action)
    AND (p_entity_type IS NULL OR l.entity_type ILIKE '%' || p_entity_type || '%')
    AND (p_entity_id IS NULL OR l.entity_id = p_entity_id)
    AND (p_date_from IS NULL OR l.created_at >= p_date_from)
    AND (p_date_to IS NULL OR l.created_at <= p_date_to)
  ORDER BY l.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

REVOKE ALL ON FUNCTION public.get_admin_audit_logs(INT, INT, UUID, UUID, TEXT, TEXT, UUID, TIMESTAMPTZ, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_admin_audit_logs(INT, INT, UUID, UUID, TEXT, TEXT, UUID, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_audit_logs(INT, INT, UUID, UUID, TEXT, TEXT, UUID, TIMESTAMPTZ, TIMESTAMPTZ) TO service_role;

-- 2. Audit triggers for privileged admin tables (DB-004 / SEC-005).
CREATE OR REPLACE FUNCTION public.audit_log_trigger_system_admins()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.audit_log (tenant_id, actor_id, action, entity_type, entity_id, old_data, new_data)
  VALUES (
    NULL,
    auth.uid(),
    TG_OP,
    'system_admins',
    COALESCE(NEW.user_id, OLD.user_id),
    CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN row_to_json(OLD)::jsonb ELSE NULL END,
    CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN row_to_json(NEW)::jsonb ELSE NULL END
  );
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_log_system_admins ON public.system_admins;
CREATE TRIGGER trg_audit_log_system_admins
  AFTER INSERT OR UPDATE OR DELETE ON public.system_admins
  FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger_system_admins();

DROP TRIGGER IF EXISTS trg_audit_log_invitations ON public.invitations;
CREATE TRIGGER trg_audit_log_invitations
  AFTER INSERT OR UPDATE OR DELETE ON public.invitations
  FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();

DROP TRIGGER IF EXISTS trg_audit_log_licenses ON public.licenses;
CREATE TRIGGER trg_audit_log_licenses
  AFTER INSERT OR UPDATE OR DELETE ON public.licenses
  FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();

-- 3. Enforce LOGIN/LOGOUT rows in app_audit_log (DB-009).
CREATE OR REPLACE FUNCTION public.app_audit_log_login_enforcement()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.action IN ('LOGIN', 'LOGOUT') THEN
    IF NEW.table_name IS NULL THEN
      NEW.table_name := 'auth';
    END IF;
    IF NEW.user_id IS NULL THEN
      RAISE EXCEPTION 'app_audit_log LOGIN/LOGOUT requires user_id' USING ERRCODE = 'not_null_violation';
    END IF;
    IF NEW.record_id IS NULL THEN
      NEW.record_id := NEW.user_id::TEXT;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_app_audit_log_login_enforcement ON public.app_audit_log;
CREATE TRIGGER trg_app_audit_log_login_enforcement
  BEFORE INSERT OR UPDATE ON public.app_audit_log
  FOR EACH ROW EXECUTE FUNCTION public.app_audit_log_login_enforcement();
