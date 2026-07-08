-- P15.1: Admin dashboard — API platform keys
-- tenant_api_keys schema + create/revoke + auth middleware + versioning (YAGNI).
-- ponytail: migration idempotent; chỉ system admin được quản lý key; key plaintext chỉ trả về đúng 1 lần khi tạo.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- 1. Schema
-- ============================================================

CREATE TABLE IF NOT EXISTS public.tenant_api_keys (
  id UUID PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  api_key_hash TEXT NOT NULL,
  api_key_preview TEXT,
  version INTEGER NOT NULL DEFAULT 1,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','revoked')),
  created_by UUID REFERENCES auth.users(id),
  revoked_at TIMESTAMPTZ,
  revoked_by UUID REFERENCES auth.users(id),
  last_used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tenant_api_keys_tenant_id ON public.tenant_api_keys(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_api_keys_status ON public.tenant_api_keys(status);

ALTER TABLE public.tenant_api_keys ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'tenant_api_keys' AND policyname = 'tenant_api_keys_system_admin_all'
  ) THEN
    CREATE POLICY "tenant_api_keys_system_admin_all"
      ON public.tenant_api_keys FOR ALL TO authenticated
      USING (public.is_system_admin())
      WITH CHECK (public.is_system_admin());
  END IF;
END $$;

-- ============================================================
-- 2. Auth middleware: validate API key and return tenant_id
-- ponytail: SECURITY DEFINER để tránh rò rỉ hash; chỉ trả về tenant_id hoặc NULL.
-- ============================================================

CREATE OR REPLACE FUNCTION public.auth_tenant_api_key(p_api_key TEXT)
RETURNS UUID
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_hash TEXT;
  v_key_id UUID;
  v_tenant_id UUID;
BEGIN
  IF p_api_key IS NULL OR length(p_api_key) < 32 THEN
    RETURN NULL;
  END IF;

  v_hash := encode(extensions.digest(p_api_key, 'sha256'), 'hex');

  SELECT id, tenant_id INTO v_key_id, v_tenant_id
  FROM public.tenant_api_keys
  WHERE api_key_hash = v_hash AND status = 'active'
  LIMIT 1;

  IF v_key_id IS NOT NULL THEN
    UPDATE public.tenant_api_keys
    SET last_used_at = now()
    WHERE id = v_key_id;
  END IF;

  RETURN v_tenant_id;
END;
$$;

REVOKE ALL ON FUNCTION public.auth_tenant_api_key(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.auth_tenant_api_key(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.auth_tenant_api_key(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.auth_tenant_api_key(TEXT) TO anon;

-- ============================================================
-- 3. RPC create API key
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_tenant_api_key(
  p_tenant_id UUID,
  p_name TEXT,
  p_version INTEGER DEFAULT 1
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public, extensions
AS $$
DECLARE
  v_key TEXT;
  v_hash TEXT;
  v_preview TEXT;
  v_row public.tenant_api_keys;
BEGIN
  IF NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Chỉ system admin mới được tạo API key' USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF p_tenant_id IS NULL THEN
    RAISE EXCEPTION 'Thiếu tenant_id';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.tenants WHERE id = p_tenant_id) THEN
    RAISE EXCEPTION 'Không tìm thấy tenant: %', p_tenant_id;
  END IF;

  IF p_name IS NULL OR length(trim(p_name)) = 0 THEN
    RAISE EXCEPTION 'Tên API key không được để trống';
  END IF;

  v_key := encode(extensions.gen_random_bytes(32), 'hex');
  v_hash := encode(extensions.digest(v_key, 'sha256'), 'hex');
  v_preview := right(v_key, 4);

  INSERT INTO public.tenant_api_keys (
    tenant_id, name, api_key_hash, api_key_preview, version, created_by
  ) VALUES (
    p_tenant_id, trim(p_name), v_hash, v_preview, COALESCE(p_version, 1), auth.uid()
  )
  RETURNING * INTO v_row;

  RETURN json_build_object(
    'id', v_row.id,
    'tenantId', v_row.tenant_id,
    'name', v_row.name,
    'apiKey', v_key,
    'apiKeyPreview', v_row.api_key_preview,
    'version', v_row.version,
    'status', v_row.status,
    'createdAt', v_row.created_at,
    'lastUsedAt', v_row.last_used_at
  );
END;
$$;

-- ============================================================
-- 4. RPC revoke API key
-- ============================================================

CREATE OR REPLACE FUNCTION public.revoke_tenant_api_key(
  p_key_id UUID
)
RETURNS public.tenant_api_keys
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_row public.tenant_api_keys;
BEGIN
  IF NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Chỉ system admin mới được thu hồi API key' USING ERRCODE = 'insufficient_privilege';
  END IF;

  UPDATE public.tenant_api_keys
  SET status = 'revoked',
      revoked_at = now(),
      revoked_by = auth.uid(),
      updated_at = now()
  WHERE id = p_key_id
  RETURNING * INTO v_row;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Không tìm thấy API key: %', p_key_id;
  END IF;

  RETURN v_row;
END;
$$;

-- ============================================================
-- 5. RPC list API keys for a tenant
-- ============================================================

CREATE OR REPLACE FUNCTION public.list_tenant_api_keys(
  p_tenant_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
AS $$
BEGIN
  IF NOT public.is_system_admin() THEN
    RAISE EXCEPTION 'Chỉ system admin mới được xem API key' USING ERRCODE = 'insufficient_privilege';
  END IF;

  RETURN (
    SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)
    FROM (
      SELECT
        id,
        tenant_id AS tenantId,
        name,
        api_key_preview AS apiKeyPreview,
        version,
        status,
        created_by AS createdBy,
        revoked_at AS revokedAt,
        revoked_by AS revokedBy,
        last_used_at AS lastUsedAt,
        created_at AS createdAt,
        updated_at AS updatedAt
      FROM public.tenant_api_keys
      WHERE tenant_id = p_tenant_id
      ORDER BY created_at DESC
    ) t
  );
END;
$$;
