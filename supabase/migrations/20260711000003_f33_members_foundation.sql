-- F33 P1: DB Foundation for tenant_memberships
-- Scope: add status / is_active / invited_at / accepted_at, backfill existing rows, add indexes.
-- ponytail: single-file schema-only migration; idempotent DDL with IF NOT EXISTS.

-- ============================================================
-- 1. Add columns
-- ============================================================

ALTER TABLE public.tenant_memberships
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','active','inactive'));

ALTER TABLE public.tenant_memberships
ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE public.tenant_memberships
ADD COLUMN IF NOT EXISTS invited_at TIMESTAMPTZ DEFAULT now();

ALTER TABLE public.tenant_memberships
ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMPTZ;

-- ============================================================
-- 2. Backfill existing rows
-- ============================================================

UPDATE public.tenant_memberships tm
SET
  status = CASE WHEN u.last_sign_in_at IS NOT NULL THEN 'active' ELSE 'pending' END,
  invited_at = tm.created_at,
  accepted_at = CASE WHEN u.last_sign_in_at IS NOT NULL THEN u.last_sign_in_at ELSE NULL END
FROM auth.users u
WHERE tm.user_id = u.id;

-- ============================================================
-- 3. Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_tenant_memberships_tenant_status
  ON public.tenant_memberships(tenant_id, status);

CREATE INDEX IF NOT EXISTS idx_tenant_memberships_tenant_role
  ON public.tenant_memberships(tenant_id, role);

CREATE INDEX IF NOT EXISTS idx_tenant_memberships_tenant_is_active
  ON public.tenant_memberships(tenant_id, is_active);
