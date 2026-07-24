# DELETE_TENANT_FORENSIC_INVESTIGATION_REPORT.md

---

## 1. Problem Summary

**Symptom**

- In the Admin Dashboard → Tenants page, when a system admin clicks **“Xóa vĩnh viễn”** (hard delete) on a tenant and confirms, the frontend calls the `delete-tenant` Edge Function.
- The call returns **HTTP 500 Internal Server Error**:
  - Browser console:  
    `POST /functions/v1/delete-tenant 500 (Internal Server Error)`
  - Supabase client surfaces: **“Edge Function returned a non-2xx status code”**.

**Impact**

- System admins **cannot permanently delete tenants** from the Admin Dashboard.
- Each failed hard delete attempt still performs some irreversible side effects (see §11) while leaving the tenant row intact.

**High‑level root cause (preview)**

- The `delete-tenant` Edge Function successfully reaches the **hard delete** path and issues:

  ```sql
  DELETE FROM public.tenants WHERE id = <tenant_id>;
  ```

- This fires the **admin audit triggers** defined on `public.tenants` and related tables, which insert entries into the **`public.audit_log`** table.  
- The `audit_log.tenant_id` column has a **foreign key constraint** referencing `public.tenants(id)`:

  ```sql
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE SET NULL
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="32584-32590" />

- During the tenant hard delete, the audit trigger inserts into `audit_log` using the deleted tenant id as `tenant_id`, but at that moment **no matching row exists in `public.tenants`**, causing:

  > `insert or update on table "audit_log" violates foreign key constraint "audit_log_tenant_id_fkey"`

  (Postgres **ERROR** from Supabase MCP `get_logs(service='postgres')` at `2026-07-23T01:35:46.490000`).

- This database error propagates back through Supabase, is caught by the Edge Function’s catch block, and returned as an **HTTP 500**.

---

## 2. Execution Flow (End‑to‑End)

**High‑level sequence**

1. **Admin UI** (`/admin/tenants`) renders tenants list and action buttons.  
   <ref_snippet file="C:/PROJECT/vietsalepro/pages/admin/Tenants.tsx" lines="145-177" />

2. User clicks **“Xóa vĩnh viễn”** on a tenant → `handleDelete(tenant)` opens a **confirmation dialog** and, on confirm, calls `hardDeleteTenant(tenant.id)`.  
   <ref_snippet file="C:/PROJECT/vietsalepro/pages/admin/Tenants.tsx" lines="313-333" />

3. **Service layer (admin)**: `services/admin/tenantAdminService.ts` re‑exports `hardDeleteTenant` from `tenantService`.  
   <ref_snippet file="C:/PROJECT/vietsalepro/services/admin/tenantAdminService.ts" lines="216-239" />

4. **Service layer (core)**: `tenantService.hardDeleteTenant(tenantId)` invokes the Supabase **Edge Function**:

   ```ts
   const { data, error } = await supabase.functions.invoke(
     'delete-tenant',
     { body: { tenant_id: tenantId, force: true } }
   );
   ```  

   <ref_snippet file="C:/PROJECT/vietsalepro/services/tenantService.ts" lines="727-744" />

5. **Supabase JS client** (`lib/supabase.ts`):

   - Created with `createClient(supabaseUrl, supabaseAnonKey, { global: { fetch: tenantFetch } })`.  
   - `tenantFetch` injects `x-tenant-id` if a tenant is selected; there is no special handling for admin requests.  
   <ref_snippet file="C:/PROJECT/vietsalepro/lib/supabase.ts" lines="6-33" />

6. **Supabase Edge Function runtime**:

   - `POST https://<project>.supabase.co/functions/v1/delete-tenant` with:
     - `Authorization: Bearer <user_access_token>`
     - `apikey: <anon-key>`
     - `Content-Type: application/json`
     - Body: `{ "tenant_id": "<uuid>", "force": true }`

   - `verify_jwt: true` for `delete-tenant` (Supabase MCP `list_edge_functions`):  

     ```json
     {
       "slug": "delete-tenant",
       "verify_jwt": true,
       "entrypoint_path": "C:\\Users\\SUACAUBA\\Downloads\\Project\\vietsale-pro-v7\\supabase\\functions\\delete-tenant\\index.ts",
       "status": "ACTIVE",
       "version": 6
     }
     ```  

7. **Edge Function handler (`supabase/functions/delete-tenant/index.ts`)**:

   - Validates rate limit using `rate_limit_logs`.
   - Extracts JWT from `Authorization` header, uses `supabaseAdmin.auth.getUser(token)` to resolve `user`.
   - Validates that the caller is a **system admin or tenant owner** via `_shared/permissions.ts`.
   - Loads tenant row.
   - Checks `force` flag → `true` → calls `hardDeleteTenant(supabaseAdmin, tenantId, user.id, ip)`.  
   <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="216-300" />
   <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/_shared/permissions.ts" lines="28-39" />

8. **Hard delete implementation**:

   - Removes storage objects under `tenant-assets/<tenant_id>/`.
   - Deletes orphan rows in `app_audit_log` and `terms_acceptance`.
   - Performs `DELETE FROM public.tenants WHERE id = <tenant_id>` (with BEFORE/AFTER triggers).
   - Attempts to delete orphaned auth users via `supabaseAdmin.auth.admin.deleteUser`.
   - Writes a **business audit row** into `app_audit_log` with `action: 'DELETE'`.  
     <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="70-214" />

9. **Database triggers & constraints**:

   - The `DELETE` on `public.tenants` fires:
     - `tenants_before_delete_guardrail` (sets `app.hard_delete_tenant` flag).  
       <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="29371-29389" />
     - `trg_audit_log_tenants` and related triggers (for `audit_log`).  
       <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="32627-32652" />

   - `audit_log_trigger` inserts into `public.audit_log` using `COALESCE(NEW.tenant_id, OLD.tenant_id)` and `auth.uid()` as `actor_id`.  
     <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="32627-32644" />

   - Because the parent tenant row is being deleted, the insert into `public.audit_log` violates
     `audit_log.tenant_id REFERENCES public.tenants(id)`.

10. **Error propagation**:

    - Postgres logs `ERROR: insert or update on table "audit_log" violates foreign key constraint "audit_log_tenant_id_fkey"` at `2026-07-23T01:35:46.490000` (Supabase MCP `get_logs`, service `postgres`).
    - Supabase client for the Edge Function receives an error from the `DELETE` call on `tenants`.
    - The `try/catch` at the end of `index.ts` catches the error and returns:

      ```ts
      return jsonResponse({ error: message }, 500);
      ```  

      <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="301-304" />

11. **Supabase Edge logs**:

    - Supabase MCP `get_logs(service='edge-function')` for project `rsialbfjswnrkzcxarnj` shows multiple entries like:

      - `POST | 500 | https://rsialbfjswnrkzcxarnj.supabase.co/functions/v1/delete-tenant`  
        `timestamp: 2026-07-23T01:35:46.642000, function_id: fc6e8648-93dd-472e-890a-83c435145b77, version: 6`

12. **Frontend receives 500**:

    - `supabase.functions.invoke('delete-tenant', ...)` returns `error` and no successful `data`.
    - `tenantService.hardDeleteTenant` throws, `Tenants.tsx` catches and shows the generic error toast (`err.message || 'Xóa thất bại.'`).  
      <ref_snippet file="C:/PROJECT/vietsalepro/pages/admin/Tenants.tsx" lines="323-327" />

---

## 3. Frontend Analysis

### 3.1 Delete button & confirmation dialog

- The Admin Tenants page imports admin tenant services including `softDeleteTenant` and `hardDeleteTenant`:  
  <ref_snippet file="C:/PROJECT/vietsalepro/pages/admin/Tenants.tsx" lines="32-41" />

- The **hard delete** action is wired via `handleDelete`:

  ```tsx
  const handleDelete = (tenant: Tenant) => {
    openConfirmDialog({
      title: 'Xóa cửa hàng vĩnh viễn',
      message: `Xóa vĩnh viễn cửa hàng "${tenant.name}"? Toàn bộ dữ liệu sẽ bị xóa.`,
      confirmLabel: 'Xóa vĩnh viễn',
      cancelLabel: 'Hủy',
      variant: 'danger',
      onConfirm: async () => {
        setBusyId(tenant.id);
        try {
          await hardDeleteTenant(tenant.id);
          refresh();
          addToast({ type: 'success', message: `Đã xóa ${tenant.name}.` });
        } catch (err: any) {
          addToast({ type: 'error', message: err?.message || 'Xóa thất bại.' });
        } finally {
          setBusyId(null);
        }
      },
    });
  };
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/pages/admin/Tenants.tsx" lines="313-331" />

**Conclusion:** The UI correctly routes the “hard delete” button through `hardDeleteTenant(tenant.id)` after an explicit confirmation.

### 3.2 Service invocation & payload

- `tenantAdminService.ts` is an **admin wrapper** that re‑exports core tenantService functions, including `softDeleteTenant` (used for “archive”) and `hardDeleteTenant` (used for permanent delete):  

  ```ts
  export {
    createTenantWithCredentials,
    getAllTenants,
    getTenantById,
    getTenantBySubdomain,
    getTenantCredentials,
    getTenantFeatureFlags,
    updateTenantFeatureFlags,
    getTopTenants,
    getTenantGrowth,
    searchTenants,
    softDeleteTenant,
    hardDeleteTenant,
    updateTenant,
  } from '../tenantService';
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/services/admin/tenantAdminService.ts" lines="216-239" />

- Core implementation of hard delete in `tenantService.ts`:

  ```ts
  export async function hardDeleteTenant(tenantId: string): Promise<void> {
    const { data, error } = await supabase.functions.invoke<{ success?: boolean; error?: string }>(
      'delete-tenant',
      {
        body: { tenant_id: tenantId, force: true },
      }
    );

    if (error) throw error;
    if (!data || typeof data !== 'object' || !data.success) {
      throw new Error(data?.error || 'Xóa cửa hàng thất bại');
    }
  }
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/services/tenantService.ts" lines="732-744" />

- There is a dedicated Vitest ensuring the **payload contract** is correct and that the delete removes all tenant data at the **service level**:

  ```ts
  await hardDeleteTenant(tenant.id);

  expect(invokeSpy).toHaveBeenCalledWith(
    'delete-tenant',
    expect.objectContaining({
      body: expect.objectContaining({ tenant_id: tenant.id, force: true }),
    }),
  );
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/tests/tenant.test.ts" lines="178-193" />

**Conclusion:**  
The frontend invokes the correct service and that service sends the expected JSON body:

```json
{ "tenant_id": "<uuid>", "force": true }
```

### 3.3 Headers and authentication token

- Supabase client is created in `lib/supabase.ts`:

  ```ts
  const supabase = createClient(
    supabaseUrl || '',
    supabaseAnonKey || '',
    { global: { fetch: tenantFetch } }
  );
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/lib/supabase.ts" lines="30-33" />

- `tenantFetch` adds `x-tenant-id` if `currentTenantId` is set:

  ```ts
  const headers = new Headers(init?.headers);
  if (currentTenantId) headers.set('x-tenant-id', currentTenantId);
  return fetch(input, { ...init, headers });
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/lib/supabase.ts" lines="24-27" />

- For `functions.invoke`, Supabase JS automatically includes:

  - `Authorization: Bearer <access_token>` from the current Supabase session.
  - `apikey: <VITE_SUPABASE_ANON_KEY>`.
  - `Content-Type: application/json`.

**Conclusion:**  
Request headers and authentication token are correctly populated by the Supabase client. There is no indication of malformed headers or missing JWT from the frontend.

---

## 4. Service Layer Analysis

### 4.1 Tenant admin service

- `tenantAdminService.deleteAccount` uses the **soft delete** path (`delete_tenant_safe` RPC) and is unrelated to the failing “hard delete” button:

  ```ts
  export async function deleteAccount(id: string): Promise<Tenant> {
    return softDeleteTenantBase(id);
  }
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/services/admin/tenantAdminService.ts" lines="70-76" />

- The hard delete is **re-exported** for advanced admin actions (`hardDeleteTenant`).

### 4.2 Core tenant service

- **Soft delete**:

  ```ts
  export async function softDeleteTenant(tenantId: string): Promise<Tenant> {
    const { data, error } = await supabase.rpc('delete_tenant_safe', {
      p_tenant_id: tenantId,
    });
    if (error) throw error;
    return mapTenantFromDB(data);
  }
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/services/tenantService.ts" lines="746-752" />
  <ref_snippet file="C:/PROJECT/vietsalepro/docs/admin-dashboard/RPC_CONTRACTS.md" lines="51-52" />

- **Hard delete** (reproduced above in §3.2) uses the Edge Function rather than RPC, by design, since it must:
  - Use the **service role** key.
  - Perform **cross-cutting operations** (storage cleanup, auth user deletion, audit logging) that are not feasible in a single Postgres RPC.

### 4.3 Tests

- `tests/tenant.test.ts` exercises:

  - Tenant creation and membership.
  - `softDeleteTenant` / `restoreTenant`.
  - `hardDeleteTenant` path and ensures:
    - Correct `functions.invoke` payload.
    - Tenant and related objects disappear from the **mock** supabase environment.  
    <ref_snippet file="C:/PROJECT/vietsalepro/tests/tenant.test.ts" lines="166-203" />

**Conclusion:**  
The service layer matches the documented contracts and is covered by tests. It **assumes** the `delete-tenant` Edge Function will successfully perform the hard delete, which is where the failure actually occurs.

---

## 5. Edge Function Analysis (`delete-tenant`)

### 5.1 Handler entry & environment

- The Edge Function uses Supabase JS v2 with the **service role** key:

  ```ts
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="221-226" />

- It sets up CORS and a simple `jsonResponse` helper.  
  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="5-29" />

### 5.2 Request parsing & rate limit

- IP extraction and validation:

  ```ts
  const rawIp = getClientIp(req);
  const ip = isValidIp(rawIp) ? rawIp : '0.0.0.0';
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="228-230" />

- Per‑IP rate limit from `rate_limit_logs`:

  ```ts
  const { count, error: countError } = await supabaseAdmin
    .from('rate_limit_logs')
    .select('*', { count: 'exact', head: true })
    .eq('ip_address', ip)
    .eq('action', 'delete_tenant')
    .gte('window_start', windowStart);

  if ((count ?? 0) >= RATE_LIMIT_MAX) {
    return jsonResponse({ error: 'Rate limit exceeded: 10 requests per minute' }, 429);
  }
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="232-242" />

- INSERT into `rate_limit_logs` is **best effort**; any failure is logged but **does not abort** the request:

  ```ts
  const { error: logError } = await supabaseAdmin.from('rate_limit_logs').insert({
    ip_address: ip,
    action: 'delete_tenant',
    window_start: new Date().toISOString(),
  });
  if (logError) {
    console.error('Failed to write rate_limit_logs entry:', logError);
  }
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="244-252" />

- The `rate_limit_logs` action check constraint was explicitly **fixed** to allow `'delete_tenant'`:

  ```sql
  -- delete-tenant and create-system-admin insert rows with action 'delete_tenant' / 'create_system_admin',
  -- which were not in the original allowed set. This caused the hard-delete tenant flow to fail with 500.
  ...
  ALTER TABLE public.rate_limit_logs
  ADD CONSTRAINT rate_limit_logs_action_check
  CHECK (action IN (..., 'delete_tenant', 'create_system_admin'));
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="29319-29354" />

**Conclusion:** Current rate limit logic is **not** the failing point; previous 500s caused by the old CHECK constraint have already been remediated in the schema.

### 5.3 Authentication & authorization

- JWT extraction and user resolution:

  ```ts
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return jsonResponse({ error: 'Missing Authorization header' }, 401);
  }
  const token = authHeader.replace('Bearer ', '');
  const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token);
  if (userError || !user) {
    return jsonResponse({ error: 'Invalid token' }, 401);
  }
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="254-262" />

- Authorization: only **system admins** or **tenant owners** may delete tenants:

  ```ts
  const isAdmin = await checkIsSystemAdmin(supabaseAdmin, user.id);
  const isOwner = await checkIsTenantOwner(supabaseAdmin, tenantId, user.id);
  if (!isAdmin && !isOwner) {
    return jsonResponse({ error: 'Only system admins or tenant owners can delete tenants' }, 403);
  }
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="272-276" />
  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/_shared/permissions.ts" lines="28-38" />
  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/_shared/permissions.ts" lines="58-73" />

- Supabase MCP `list_edge_functions` shows `verify_jwt: true` for `delete-tenant`, meaning Supabase enforces a valid JWT at the platform level as well.

**Conclusion:**  
Authentication and authorization for delete-tenant are correctly enforced and **return 401/403, not 500**, when they fail. The observed 500s occur **after** auth has succeeded.

### 5.4 Parameter validation

- Body parsing and validation:

  ```ts
  const body = await req.json().catch(() => ({}));
  const tenantId = (body.tenant_id ?? body.tenantId)?.toString().trim();
  const force = body.force === true;

  if (!tenantId || !UUID_REGEX.test(tenantId)) {
    return jsonResponse({ error: 'tenant_id không hợp lệ' }, 400);
  }
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="264-270" />

- The **force flag** is an explicit boolean and defaults to `false` if absent; hard delete path only executes when `force === true`.

**Conclusion:**  
The payload contract from frontend (`tenant_id: uuid, force: true`) matches the Edge Function’s expectations.

### 5.5 Soft vs hard delete paths

- **Soft delete** (`force === false`):

  ```ts
  if (force) {
    // Hard-delete...
  } else {
    // Default: soft-delete (archive)
    return jsonResponse(await softDeleteTenant(supabaseAdmin, tenantId, user.id, ip), 200);
  }
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="294-300" />

  `softDeleteTenant`:

  - Updates `tenants.status = 'archived'` and `archived_at`.
  - Deactivates all `tenant_memberships`.
  - Writes an **`app_audit_log`** row with `action: 'UPDATE'`.  
    <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="31-68" />

- **Hard delete** (`force === true`):

  - Loads tenant (ensures existence and rejects admin tenant).  
    <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="70-85" />
  - Collects related user ids from `tenant_memberships` and `owner_id`.
  - Iteratively deletes storage objects from `tenant-assets` bucket.
  - Deletes orphan rows from `app_audit_log` and `terms_acceptance`.
  - **Deletes the tenant row**:

    ```ts
    const { error: deleteTenantError } = await supabaseAdmin
      .from('tenants')
      .delete()
      .eq('id', tenantId);
    if (deleteTenantError) throw deleteTenantError;
    ```  

    <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="142-149" />

  - Deletes auth users with no other tenant memberships or ownership.
  - Writes a **hard delete audit row** into `app_audit_log` with `action: 'DELETE'`.  
    <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="187-201" />

### 5.6 Error handling

- Any thrown error from Supabase operations is caught at the top level:

  ```ts
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Unknown error';
    return jsonResponse({ error: message }, 500);
  }
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="301-304" />

**Conclusion:**  
The Edge Function **propagates any database or storage errors as HTTP 500**, which is exactly what we see for the failing hard delete attempts. The soft delete path is not involved in the observed 500s.

---

## 6. Database Analysis

### 6.1 Rate limit table (`rate_limit_logs`)

- The schema explicitly documents that `delete-tenant` uses `action = 'delete_tenant'`, and a later migration updated the CHECK constraint accordingly.  
  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="29319-29354" />

- Given this migration, and the best-effort logging behavior in the Edge Function, **rate limit logging is not currently a source of 500s**.

### 6.2 Tenant tables

- Core tenant tables (simplified):

  ```sql
  CREATE TABLE IF NOT EXISTS public.tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    subdomain TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (...),
    plan TEXT NOT NULL DEFAULT 'free' CHECK (...),
    owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    ...
  );

  CREATE TABLE IF NOT EXISTS public.tenant_memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    ...
  );

  CREATE TABLE IF NOT EXISTS public.tenant_subscriptions (
    tenant_id UUID PRIMARY KEY REFERENCES public.tenants(id) ON DELETE CASCADE,
    ...
  );
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="13793-13827" />

### 6.3 Business audit log (`app_audit_log`)

- `app_audit_log` and `app_audit_log_partitioned` track **business operations** (orders, products, etc.) and already had extensive trigger coverage.  
  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="248-275" />
  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="16957-16974" />

- `delete-tenant` writes directly to `app_audit_log` for both soft and hard deletes, using only standard CRUD actions `UPDATE` and `DELETE` to satisfy its CHECK constraint. This behavior is guarded by a regression test:  
  <ref_snippet file="C:/PROJECT/vietsalepro/tests/edge-functions/delete-tenant.regression.test.ts" lines="10-39" />

**Conclusion:**  
`app_audit_log` is functioning as intended and is **not the source of the current 500**.

### 6.4 Admin audit log (`audit_log`)

- A **separate `audit_log` table** was introduced specifically for admin dashboard actions:

  ```sql
  CREATE TABLE IF NOT EXISTS public.audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES public.tenants(id) ON DELETE SET NULL,
    actor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    action TEXT NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
    entity_type TEXT NOT NULL,
    entity_id UUID NOT NULL,
    old_data JSONB,
    new_data JSONB,
    ip_address INET,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
  );
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="32584-32595" />

- Row‑level security and a **system‑admin‑only read policy** are configured:

  ```sql
  ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

  CREATE POLICY "audit_log_system_admin_select" ON public.audit_log FOR SELECT TO authenticated
    USING (public.is_system_admin());
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="32602-32612" />

### 6.5 Admin audit triggers

- Shared trigger function for `tenants` and `tenant_memberships`:

  ```sql
  CREATE OR REPLACE FUNCTION public.audit_log_trigger()
  RETURNS TRIGGER
  ...
  AS $$
  BEGIN
    INSERT INTO public.audit_log (tenant_id, actor_id, action, entity_type, entity_id, old_data, new_data)
    VALUES (
      COALESCE(NEW.tenant_id, OLD.tenant_id),
      auth.uid(),
      TG_OP,
      TG_TABLE_NAME,
      COALESCE(NEW.id, OLD.id),
      CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN row_to_json(OLD)::jsonb ELSE NULL END,
      CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN row_to_json(NEW)::jsonb ELSE NULL END
    );
    RETURN COALESCE(NEW, OLD);
  END;
  $$;
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="32627-32643" />

- Triggers attached to the core admin tables:

  ```sql
  CREATE TRIGGER trg_audit_log_tenants
    AFTER INSERT OR UPDATE OR DELETE ON public.tenants
    FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();

  CREATE TRIGGER trg_audit_log_tenant_memberships
    AFTER INSERT OR UPDATE OR DELETE ON public.tenant_memberships
    FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger();

  CREATE TRIGGER trg_audit_log_tenant_subscriptions
    AFTER INSERT OR UPDATE OR DELETE ON public.tenant_subscriptions
    FOR EACH ROW EXECUTE FUNCTION public.audit_log_trigger_tenant_subscriptions();
  ```  

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="32648-32682" />

**Key observation:**  
Because `trg_audit_log_tenants` is an **AFTER DELETE** trigger and `audit_log.tenant_id` has a **non‑deferrable foreign key** to `tenants.id`, inserting an audit row for the delete operation **requires the parent tenant row to still exist at insert time**.

### 6.6 PostgreSQL error (Supabase MCP logs)

Using Supabase MCP `get_logs` with `service='postgres'` and a window around the failing Edge invocation:

```json
{
  "error_severity": "ERROR",
  "event_message": "insert or update on table \"audit_log\" violates foreign key constraint \"audit_log_tenant_id_fkey\"",
  "identifier": "rsialbfjswnrkzcxarnj",
  "timestamp": "2026-07-23T01:35:46.490000"
}
```

This timestamp aligns with the `POST | 500 | .../delete-tenant` entries for the `delete-tenant` Edge Function in the `edge-function` logs.

**Conclusion (DB layer):**

- The **only** database error in the relevant time window is the **foreign key violation on `public.audit_log.tenant_id`**.
- This error is caused by the **admin audit triggers** trying to insert a row into `audit_log` while the referenced tenant row is already being deleted.

---

## 7. Authentication Analysis

- **Frontend auth**:
  - Supabase JS manages login, sessions, and `Authorization: Bearer <access_token>` headers.
  - The Admin Dashboard is only accessible to authenticated users with appropriate roles (enforced elsewhere in the app).

- **Edge function auth**:
  - `verify_jwt: true` for `delete-tenant` slug (Supabase MCP `list_edge_functions`).
  - Handler requires a valid JWT and returns **401** for missing/invalid tokens.  
    <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="254-262" />

- **Authorization**:
  - `checkIsSystemAdmin` and `checkIsTenantOwner` enforce that only system admins or the tenant owner can delete the tenant.  
    <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/_shared/permissions.ts" lines="28-39" />
  - On failure, handler returns **403** with a clear message:
    `"Only system admins or tenant owners can delete tenants"`.  
    <ref_snippet file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" lines="272-276" />

- **Supabase logs**:
  - Edge invocation logs for delete-tenant show **POST 500** responses, not 401 or 403.
  - No auth-related errors appear in the narrowed log windows.

**Conclusion:**  
The failure is **not** caused by authentication or authorization misconfiguration. Auth is working as intended; the error arises deeper in the database layer during hard delete.

---

## 8. Dependency Analysis

### 8.1 Direct dependencies of `delete-tenant` Edge Function

**Supabase Edge function code** (`supabase/functions/delete-tenant/index.ts`):  
<ref_file file="C:/PROJECT/vietsalepro/supabase/functions/delete-tenant/index.ts" />

- **Libraries / runtime**:
  - `@supabase/supabase-js@2.97.0` (Deno ESM)  
  - Deno standard `serve` (`std@0.177.0/http/server.ts`)
- **Shared modules**:
  - `../_shared/permissions.ts` (`checkIsSystemAdmin`, `checkIsTenantOwner`)  
    <ref_file file="C:/PROJECT/vietsalepro/supabase/functions/_shared/permissions.ts" />
- **Environment variables**:
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY`
- **Database tables**:
  - `rate_limit_logs`
  - `tenants`
  - `tenant_memberships`
  - `system_admins`
  - `terms_acceptance`
  - `app_audit_log`
  - **`audit_log`** (indirectly, via triggers)
- **Storage**:
  - Bucket: `tenant-assets` (prefix `<tenant_id>/...`).

### 8.2 Database triggers and functions involved

- `public.trg_tenants_before_delete` (sets `app.hard_delete_tenant` flag).  
  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="29371-29380" />

- `public.trg_tenant_memberships_guardrails` (guardrails for member deletion; respects `app.hard_delete_tenant`).  
  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="29391-29405" />

- `public.audit_log_trigger` and `public.audit_log_trigger_tenant_subscriptions` for admin audit logging.  
  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="32627-32643" />
  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="32658-32674" />

### 8.3 RPCs

- **Soft delete** path uses `delete_tenant_safe` RPC (documented in RPC contracts), but hard delete path does **not** involve any RPCs.  
  <ref_snippet file="C:/PROJECT/vietsalepro/docs/admin-dashboard/RPC_CONTRACTS.md" lines="51-52" />

### 8.4 Environment & projects

- Semantic memory and validation report confirm the production Supabase project is **`rsialbfjswnrkzcxarnj`** (“QLBH”), with a separate staging project.  
  <ref_snippet file="C:/PROJECT/vietsalepro/.codebase-memory/SEMANTIC_MEMORY.md" lines="32-41" />
  <ref_snippet file="C:/PROJECT/vietsalepro/.codebase-memory/VALIDATION_REPORT.md" lines="160-162" />

**Conclusion:**  
The **only failing dependency** in the delete-tenant chain is the interaction between:

- `DELETE FROM public.tenants WHERE id = <tenant_id>` (triggered by Edge Function), and
- the **`public.audit_log` table with its tenant foreign key and AFTER DELETE triggers** on `tenants` and related tables.

---

## 9. Supabase Runtime Logs

### 9.1 Edge Function invocation logs (`service='edge-function'`)

From Supabase MCP `get_logs` with `service='edge-function'`, `project_id='rsialbfjswnrkzcxarnj'`:

- Multiple entries for `delete-tenant`:

  ```json
  {
    "event_message": "POST | 500 | https://rsialbfjswnrkzcxarnj.supabase.co/functions/v1/delete-tenant",
    "function_id": "fc6e8648-93dd-472e-890a-83c435145b77",
    "status_code": "500",
    "timestamp": "2026-07-23T01:35:46.642000",
    "version": "6"
  }
  ```

- There are also corresponding `OPTIONS | 200` entries immediately before each POST, reflecting CORS preflight success.

### 9.2 Edge Function runtime logs (`service='edge-function-runtime'`)

- For the same window, `get_logs(service='edge-function-runtime')` shows **boot and shutdown events** and “Listening on http://localhost:9999” messages for the same `function_id` (delete-tenant), with no explicit runtime stack traces or console error messages for the failing deletion requests in the narrowed window.

### 9.3 Postgres logs (`service='postgres'`)

- For the time window bracketing a failing POST, the **only error** is:

  ```json
  {
    "error_severity": "ERROR",
    "event_message": "insert or update on table \"audit_log\" violates foreign key constraint \"audit_log_tenant_id_fkey\"",
    "identifier": "rsialbfjswnrkzcxarnj",
    "timestamp": "2026-07-23T01:35:46.490000"
  }
  ```

- No other errors (e.g., `rate_limit_logs` CHECK, `app_audit_log` CHECK, or permission errors) are present in the same time band.

### 9.4 API logs (`service='api'`)

- Surrounding the failing time window, API logs contain repeated:

  ```text
  GET | 200 | /rest/v1/tenants?select=*&order=created_at.desc
  ```

- These correspond to the Tenants list refreshing, **not** to the Edge Function call.

**Conclusion:**  
Supabase logs conclusively show:

- **Edge Function** delete-tenant returning **500**.
- **Postgres** recording a **foreign key violation on `audit_log.tenant_id_fkey`** as the only error in that interval.

---

## 10. Root Cause Analysis

### 10.1 Primary root cause

**Database design conflict between admin audit triggers and hard tenant deletion**

- The admin audit system is designed to record **INSERT/UPDATE/DELETE** operations on core admin tables (`tenants`, `tenant_memberships`, `tenant_subscriptions`) into `public.audit_log`.  
  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="32622-32682" />

- The `audit_log` schema enforces:

  ```sql
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE SET NULL
  ```

  meaning any non-null `tenant_id` must reference an existing row in `public.tenants`.  
  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="32584-32590" />

- For delete operations, `trg_audit_log_tenants` is an **AFTER DELETE** trigger on `public.tenants`, and its function `audit_log_trigger` inserts a row into `audit_log` with:

  ```sql
  tenant_id := COALESCE(NEW.tenant_id, OLD.tenant_id)
  entity_id := COALESCE(NEW.id, OLD.id)
  action   := TG_OP ('DELETE')
  ```

  <ref_snippet file="C:/PROJECT/vietsalepro/supabase/schema.sql" lines="32633-32642" />

- When the `delete-tenant` Edge Function executes:

  ```ts
  supabaseAdmin
    .from('tenants')
    .delete()
    .eq('id', tenantId);
  ```

  this leads to:

  1. The tenant row is deleted from `public.tenants`.
  2. `trg_audit_log_tenants` (AFTER DELETE) fires and tries to insert an `audit_log` row with `tenant_id = OLD.id`.
  3. At insert time, there is **no longer a matching row in `public.tenants`**, because the delete has already removed it.
  4. The **non-deferrable foreign key** `audit_log_tenant_id_fkey` rejects the insert:

     > `insert or update on table "audit_log" violates foreign key constraint "audit_log_tenant_id_fkey"`

- This Postgres error is propagated back through Supabase to the Edge Function, which catches it and returns an HTTP 500.

**Therefore:**  
The **primary root cause** of the 500 is the **incompatible combination** of:

- An **AFTER DELETE** audit trigger on `public.tenants` that inserts rows into `public.audit_log` referencing the deleted tenant id, and
- A **strict, non-deferrable foreign key** from `audit_log.tenant_id` to `tenants.id`.

### 10.2 Secondary root causes / contributing factors

1. **Hard delete implemented via direct table delete rather than RPC**

   - The Edge Function uses direct table operations (`supabaseAdmin.from('tenants').delete()`) under a service role key, outside any explicit database transaction boundary from application code.
   - This means:
     - Storage cleanup **and**
     - Orphan table cleanup (`app_audit_log`, `terms_acceptance`)  
       happen **before** the failing `DELETE FROM tenants` and are **not rolled back** when the database error occurs.

2. **Lack of dedicated regression tests against the real database triggers**

   - The Vitest `tenant.test.ts` uses a **mock Supabase** environment (`tests/mocks/supabase`), which does not reproduce:
     - The actual `audit_log` table.
     - The `trg_audit_log_*` triggers.
     - The `audit_log_tenant_id_fkey` foreign key behavior.  
     <ref_snippet file="C:/PROJECT/vietsalepro/tests/tenant.test.ts" lines="1-15" />
   - As a result, tests confirm the **service-level contract** (functions.invoke + mock deletes) but **cannot catch** this database-level constraint failure.

3. **Admin audit design choice**

   - The `audit_log` table aims to maintain strong referential integrity with `public.tenants` via a foreign key, and the triggers always log a non-null `tenant_id` when possible.
   - For deletion operations, this design conflicts with the desire to **log the deletion** while simultaneously removing the parent row.

### 10.3 Non-causes (ruled out)

- **Rate limiting**: The `rate_limit_logs` CHECK constraint was already updated to include `'delete_tenant'`, and logging failures are best-effort only.
- **Edge Function code drift**: Supabase MCP `get_edge_function` shows the deployed `delete-tenant` source matches the repository’s `supabase/functions/delete-tenant/index.ts` (same logic, same audit behavior).
- **Authentication / permissions**: No 401/403 in the logs; 500 occurs after passing auth and role checks.

### 10.4 Confidence level

- **Confidence: HIGH**

Evidence chain:

- Supabase Edge logs confirm **POST /delete-tenant → 500** for function id `fc6e8648-93dd-472e-890a-83c435145b77`.
- Supabase Postgres logs in the same time window show **only one database error**:  
  `insert or update on table "audit_log" violates foreign key constraint "audit_log_tenant_id_fkey"`.
- Schema and trigger definitions clearly show how a `DELETE` on `public.tenants` leads to an `INSERT` into `public.audit_log` referencing `tenant_id`.
- The Edge Function’s try/catch translates any such database error into an HTTP 500 response.

---

## 11. Risk Assessment

### 11.1 Functional risk

- **System admins cannot permanently delete tenants** via the Admin Dashboard.
- Any operational processes that rely on fully deleting a tenant (e.g.,:

  - Data retention workflows.
  - Offboarding closed stores.
  - Cleaning up demo or test tenants in production)  

  are currently blocked.

### 11.2 Data integrity risk

Because the Edge Function performs multiple operations **before** the failing `DELETE`:

- **These side effects are likely to succeed even when the tenant delete fails:**

  - Storage cleanup: Removal of objects from `tenant-assets/<tenant_id>/...`.
  - Orphan cleanup in `app_audit_log` and `terms_acceptance` (`DELETE WHERE tenant_id = <tenant_id>`).

- **But the tenant is not actually deleted**:

  - `public.tenants` row remains.
  - `tenant_memberships` and `tenant_subscriptions` remain (due to the failed cascade).
  - `auth.users` for those tenants are not removed if the function fails before that step.

This creates risk of **inconsistent state** where:

- Audit/business logs or terms acceptances for the tenant may have been removed.
- The tenant account and membership records still exist.

(Validating exact state in production would require targeted SQL queries via MCP `execute_sql`, which are out of scope to modify data, but could be used read-only for further verification.)

### 11.3 Security and compliance risk

- Admin actions such as tenant deletion are **highly sensitive** and are correctly being audited into both `app_audit_log` and `audit_log`.
- However, the failure means that **requested deletions are not being honored**, which may conflict with:

  - Internal policies for handling closed customer accounts.
  - External data retention or privacy obligations, if tenants represent real customer data.

### 11.4 Observability risk

- The Edge Function does not add any contextual `console.error` logs for unexpected database failures; all we see is:

  - A generic `{ error: "<database error message>" }` in the HTTP 500 body.
  - A database error in Postgres logs, but no specific application-level telemetry linking the failing tenant id to the error.

---

## 12. Recommended Remediation Plan (No Implementation Performed)

> **Note:** The following items are **recommendations only**. No code, database, or deployment changes were made as part of this READ‑ONLY investigation.

### 12.1 Fix the audit_log foreign key + trigger interaction

Options (to be evaluated by the team):

1. **Adjust AFTER DELETE trigger behavior for `tenants`**

   - For `TG_OP = 'DELETE'` in `audit_log_trigger` when `TG_TABLE_NAME = 'tenants'`:

     - Consider inserting `tenant_id = NULL` instead of `OLD.id`, or
     - Use a separate “logical tenant id” field that does not have a foreign key constraint.

   - This avoids inserting `audit_log` rows that immediately violate `audit_log_tenant_id_fkey` when the parent row is gone.

2. **Make `audit_log_tenant_id_fkey` deferrable**

   - Mark the foreign key as **DEFERRABLE INITIALLY DEFERRED** so that:

     - Inserts into `audit_log` during the delete transaction can temporarily reference the soon‑to‑be‑deleted tenant id.
     - At commit time, the **ON DELETE SET NULL** behavior will clear the `tenant_id` values.

   - This requires careful testing to ensure no unexpected behavior for other code paths.

3. **Move hard delete into a transactional RPC**

   - Replace the direct `DELETE FROM tenants` in the Edge Function with a **SECURITY DEFINER RPC** that:

     - Performs the delete and any necessary cleanup in a **single transaction**.
     - Has full knowledge of the audit schema and can, for example, temporarily disable the tenant foreign key for the duration of the delete, or handle audit writes in a way that avoids violations.

   - The Edge Function would become a thin orchestration layer that calls this RPC instead of directly modifying tables.

### 12.2 Add regression tests that hit the real database schema

- Extend the existing test coverage to include:

  - A **live database scenario** (in staging) where:

    - A tenant with memberships and subscriptions is created.
    - The `delete-tenant` Edge Function is invoked with `force: true`.
    - Postcondition checks confirm:
      - Tenant row is gone.
      - Memberships and subscriptions are gone.
      - Storage objects are deleted.
      - `audit_log` rows exist and have `tenant_id` either null or consistent with the chosen design.

- These tests could be driven via:

  - Supabase CLI in staging.
  - Supabase MCP (`execute_sql` + `get_logs`) plus a harness that calls the Edge Function.

### 12.3 Improve observability for hard delete failures

- Within the `delete-tenant` Edge Function (and possibly the admin UI):

  - Log a **structured error** including:

    - The tenant id being deleted.
    - Which step failed (e.g., `delete_tenant_row`, `audit_log_insert`, etc.).
    - Any relevant error codes.

  - Surface a more specific error message to admins (e.g., “Audit log constraint failed; tenant not deleted. Contact support.”) rather than a generic “Edge Function returned a non-2xx status code”.

### 12.4 Validate and, if necessary, repair partial-deletion side effects

- Once a fix is deployed, run a one-time remediation for any tenants affected by the failed hard delete attempts:

  - Identify candidate tenants via:

    - Edge `delete-tenant` logs (POST 500 entries).
    - `audit_log` entries created around those timestamps.

  - For each candidate tenant:

    - Check consistency of:
      - `tenants`,
      - `tenant_memberships`,
      - `tenant_subscriptions`,
      - `app_audit_log`,
      - `audit_log`,
      - storage objects.

    - Decide whether to:

      - Retry the hard delete after fix, or
      - Restore any prematurely deleted logs if necessary.

---

## Summary

- **Frontend and service layers are functioning correctly**, sending the expected JSON payload to the `delete-tenant` Edge Function and handling errors as best they can.
- The **Edge Function implementation aligns with the repository source** and correctly enforces rate limits and authorization.
- The **root cause of the tenant delete failure** is a **database-level foreign key violation** on `public.audit_log.tenant_id`, triggered by `AFTER DELETE` admin audit triggers on `public.tenants` attempting to insert `audit_log` rows referencing a tenant row that has already been deleted.
- This database error causes Supabase to return **HTTP 500**, which the frontend surfaces as “Edge Function returned a non-2xx status code” and leaves the tenant undeleted, with potential partial side effects.

No changes were made to code, database schema, or deployments during this investigation.