-- Sub-phase 5.2: RLS policies — core tables
-- Tables: products, customers, orders, order_items, suppliers
-- ponytail: One policy template applied to all 5 tables; delete restricted to tenant admins.

DO $$
DECLARE
  tbl TEXT;
  core_tables TEXT[] := ARRAY['products', 'customers', 'orders', 'order_items', 'suppliers'];
BEGIN
  FOREACH tbl IN ARRAY core_tables
  LOOP
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = tbl) THEN
      -- Remove the temporary full-access policy from Phase 1 and any previously-created tenant policies.
      EXECUTE format('DROP POLICY IF EXISTS authenticated_full_access_temp ON public.%I', tbl);
      EXECUTE format('DROP POLICY IF EXISTS tenant_isolation_select ON public.%I', tbl);
      EXECUTE format('DROP POLICY IF EXISTS tenant_isolation_insert ON public.%I', tbl);
      EXECUTE format('DROP POLICY IF EXISTS tenant_isolation_update ON public.%I', tbl);
      EXECUTE format('DROP POLICY IF EXISTS tenant_isolation_delete ON public.%I', tbl);

      -- Enable RLS on the table.
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);

      -- SELECT: tenant members see their own rows; system admins bypass isolation.
      EXECUTE format(
        'CREATE POLICY tenant_isolation_select ON public.%I FOR SELECT TO authenticated USING ((tenant_id = public.current_tenant_id() AND public.is_tenant_member(tenant_id)) OR public.is_system_admin())',
        tbl
      );

      -- INSERT: only into the current tenant the user belongs to.
      EXECUTE format(
        'CREATE POLICY tenant_isolation_insert ON public.%I FOR INSERT TO authenticated WITH CHECK (tenant_id = public.current_tenant_id() AND public.is_tenant_member(tenant_id))',
        tbl
      );

      -- UPDATE: only rows of the current tenant the user belongs to.
      EXECUTE format(
        'CREATE POLICY tenant_isolation_update ON public.%I FOR UPDATE TO authenticated USING (tenant_id = public.current_tenant_id() AND public.is_tenant_member(tenant_id)) WITH CHECK (tenant_id = public.current_tenant_id() AND public.is_tenant_member(tenant_id))',
        tbl
      );

      -- DELETE: only tenant admins can delete rows of the current tenant.
      EXECUTE format(
        'CREATE POLICY tenant_isolation_delete ON public.%I FOR DELETE TO authenticated USING (tenant_id = public.current_tenant_id() AND public.is_tenant_member(tenant_id) AND public.is_tenant_admin(tenant_id))',
        tbl
      );
    END IF;
  END LOOP;
END $$;
