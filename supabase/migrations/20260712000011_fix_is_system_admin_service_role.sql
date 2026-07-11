-- Migration: 20260712000011_fix_is_system_admin_service_role.sql
-- Fix: is_system_admin() returns false when called from service-role context
-- because auth.uid() is null for service_role clients.
--
-- Root cause: is_system_admin() uses SECURITY DEFINER and checks auth.uid().
-- When Edge Functions call RPCs via service-role client, auth.uid() is null,
-- causing is_system_admin() to return false even for valid operations.
--
-- Fix: Allow service_role to bypass the check (service_role is trusted by definition).

CREATE OR REPLACE FUNCTION public.is_system_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    CASE
      WHEN current_user = 'service_role' THEN true
      ELSE EXISTS (SELECT 1 FROM public.system_admins WHERE user_id = auth.uid())
    END;
$$;