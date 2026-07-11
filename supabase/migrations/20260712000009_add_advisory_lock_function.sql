-- Migration: 20260712000009_add_advisory_lock_function.sql
-- Hàm hỗ trợ advisory lock cho invite-member (tránh race condition)

CREATE OR REPLACE FUNCTION public.acquire_advisory_lock(p_lock_id BIGINT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT pg_try_advisory_xact_lock(p_lock_id);
$$;