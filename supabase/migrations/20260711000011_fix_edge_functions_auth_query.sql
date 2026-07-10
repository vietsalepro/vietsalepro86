-- Fix Edge Functions that query auth.users directly via PostgREST schema('auth'),
-- which is not exposed by default and causes "Invalid schema: auth" errors.
-- ponytail: provide a SECURITY DEFINER RPC so Edge Functions can look up users by email
-- without needing the auth schema exposed in the REST API.

CREATE OR REPLACE FUNCTION public.get_user_by_email(p_email TEXT)
RETURNS TABLE(
  id UUID,
  email TEXT,
  last_sign_in_at TIMESTAMPTZ,
  confirmed_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT au.id, au.email::TEXT, au.last_sign_in_at, au.confirmed_at
  FROM auth.users au
  WHERE au.email = p_email
  LIMIT 1;
$$;
