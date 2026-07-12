-- Audit current grants on public functions.
-- Run with: psql $DATABASE_URL -f scripts/audit-grants.sql
-- or via Supabase SQL Editor.

SELECT
  n.nspname AS schema,
  p.proname AS function_name,
  pg_get_function_identity_arguments(p.oid) AS args,
  COALESCE(string_agg(DISTINCT r.rolname, ', ' ORDER BY r.rolname), 'NO GRANTS') AS grantees
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
LEFT JOIN LATERAL aclexplode(COALESCE(p.proacl, acldefault('f', p.proowner))) AS a ON TRUE
LEFT JOIN pg_roles r ON r.oid = a.grantee
WHERE n.nspname = 'public'
GROUP BY n.nspname, p.proname, p.oid
ORDER BY p.proname;
