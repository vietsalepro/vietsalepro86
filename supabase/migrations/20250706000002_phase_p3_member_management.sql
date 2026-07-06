-- P3: Admin dashboard — Member management
-- RPC liệt kê thành viên kèm email để system admin quản lý member trên dashboard.
-- ponytail: migration idempotent; chỉ system admin được gọi RPC này.
--          Dùng SECURITY DEFINER vì cần đọc auth.users để lấy email.

-- ============================================================
-- 1. RPC lấy danh sách thành viên của tenant kèm email
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_tenant_members_with_email(
  p_tenant_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Chỉ system admin mới được xem danh sách thành viên tenant' USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = p_tenant_id) THEN
    RAISE EXCEPTION 'Không tìm thấy tenant: %', p_tenant_id;
  END IF;

  RETURN (
    SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)
    FROM (
      SELECT
        tm.id,
        tm.tenant_id,
        tm.user_id,
        u.email,
        tm.role,
        tm.invited_by,
        inviter.email AS invited_by_email,
        tm.created_at,
        tm.updated_at
      FROM public.tenant_memberships tm
      LEFT JOIN auth.users u ON u.id = tm.user_id
      LEFT JOIN auth.users inviter ON inviter.id = tm.invited_by
      WHERE tm.tenant_id = p_tenant_id
      ORDER BY tm.created_at DESC
    ) t
  );
END;
$$;
