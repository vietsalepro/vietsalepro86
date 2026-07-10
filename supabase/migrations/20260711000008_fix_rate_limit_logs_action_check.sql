-- Fix: rate_limit_logs CHECK constraint rejected actions used by newer edge functions.
-- delete-tenant and create-system-admin insert rows with action 'delete_tenant' / 'create_system_admin',
-- which were not in the original allowed set. This caused the hard-delete tenant flow to fail with 500.
--
-- ponytail: drop the old constraint by definition lookup (works whether the name is the default
-- name or a custom one) and recreate with the complete current action list.

DO $$
DECLARE
  con_name TEXT;
BEGIN
  SELECT con.conname INTO con_name
  FROM pg_constraint con
  JOIN pg_class cls ON cls.oid = con.conrelid
  JOIN pg_namespace ns ON ns.oid = cls.relnamespace
  WHERE ns.nspname = 'public'
    AND cls.relname = 'rate_limit_logs'
    AND con.contype = 'c'
    AND pg_get_constraintdef(con.oid) ILIKE '%action%IN%';

  IF con_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.rate_limit_logs DROP CONSTRAINT IF EXISTS %I', con_name);
  END IF;
END $$;

ALTER TABLE public.rate_limit_logs
ADD CONSTRAINT rate_limit_logs_action_check
CHECK (action IN (
  'login',
  'create_tenant',
  'check_subdomain',
  'invite_member',
  'process_checkout',
  'delete_tenant',
  'create_system_admin'
));
