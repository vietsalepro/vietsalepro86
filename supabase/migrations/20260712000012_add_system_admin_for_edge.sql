-- Migration: 20260712000012_add_system_admin_for_edge.sql
-- RPC dành riêng cho Edge Function (không check auth.uid())
--
-- Lý do: Khi Edge Function gọi RPC từ service-role client, auth.uid() là null.
-- is_system_admin() đã được fix (migration 00011) để cho phép service_role bypass,
-- nhưng add_system_admin() cũng bị lỗi tương tự: nó kiểm tra caller là system admin
-- dựa trên auth.uid(), nhưng service-role client không có auth.uid().
--
-- Cách 1 (Trong EF main handler - đã done ở migration 00011):
--   is_system_admin() cho phép current_user = 'service_role' bypass
--
-- Cách 2 (RPC riêng cho Edge Function - migration này):
--   Tạo RPC add_system_admin_for_edge chỉ cho phép service_role gọi,
--   nhận p_creator_id để audit log, không dùng auth.uid()
--
-- Cách 3 (Direct insert trong EF - đã dùng trong create-system-admin):
--   supabaseAdmin.from('system_admins').insert({ user_id: newUserId })
--
-- Migration này implement Cách 2 để các Edge Function khác có thể gọi RPC
-- thay vì direct insert (có validation + audit log đầy đủ)

CREATE OR REPLACE FUNCTION public.add_system_admin_for_edge(
  p_user_id UUID,
  p_creator_id UUID
)
RETURNS public.system_admins
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.system_admins;
BEGIN
  -- Chỉ cho phép service_role gọi RPC này
  IF current_user != 'service_role' THEN
    RAISE EXCEPTION 'Only service_role can call this function' USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Validate user exists
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
    RAISE EXCEPTION 'Không tìm thấy user: %', p_user_id;
  END IF;

  -- Check not already system admin
  IF EXISTS (SELECT 1 FROM public.system_admins WHERE user_id = p_user_id) THEN
    RAISE EXCEPTION 'User already a system admin';
  END IF;

  -- Insert new system admin
  INSERT INTO public.system_admins (user_id)
  VALUES (p_user_id)
  RETURNING * INTO v_row;

  -- Audit log
  INSERT INTO public.app_audit_log (user_id, table_name, record_id, action, new_data)
  VALUES (p_creator_id, 'system_admins', p_user_id, 'SYSTEM_ADMIN_ADD',
          jsonb_build_object('new_admin_id', p_user_id, 'created_by', p_creator_id));

  RETURN v_row;
END;
$$;

-- Thêm comment cho RPC
COMMENT ON FUNCTION public.add_system_admin_for_edge IS 
'RPC dành riêng cho Edge Function (service_role) để thêm system admin.
Không sử dụng auth.uid() vì service_role client không có auth.uid().
Caller phải truyền p_creator_id là UUID của system admin đang thực hiện hành động.
Chỉ service_role mới được gọi RPC này.';