-- Phase 1: Dọn dẹp bảo mật hiện tại
-- Mục tiêu: Xóa public access policies, tạo temporary full-access policy cho authenticated users.
-- ponytail: policy tạm thời, sẽ thay bằng tenant-scoped policies ở Phase 5.

DO $$
DECLARE
  pol RECORD;
  business_tables TEXT[] := ARRAY[
    'app_settings',
    'brands',
    'categories',
    'customer_payment_ledger',
    'customers',
    'disposal_items',
    'disposals',
    'einvoice_config',
    'einvoice_orders',
    'import_items',
    'import_receipts',
    'inventory_count_items',
    'inventory_counts',
    'inventory_movements',
    'order_items',
    'orders',
    'point_history',
    'processed_operations',
    'product_lots',
    'products',
    'promotions',
    'rank_configs',
    'rank_history',
    'return_order_items',
    'return_orders',
    'rewards',
    'stock_movements',
    'supplier_exchange_received_items',
    'supplier_exchange_return_items',
    'supplier_exchanges',
    'supplier_payment_ledger',
    'suppliers'
  ];
BEGIN
  -- 1. Drop every policy assigned to the public role on business tables.
  FOR pol IN
    SELECT policyname, tablename
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = ANY(business_tables)
      AND 'public' = ANY(roles)
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, pol.tablename);
  END LOOP;
END $$;

DO $$
DECLARE
  tbl TEXT;
  business_tables TEXT[] := ARRAY[
    'app_settings',
    'brands',
    'categories',
    'customer_payment_ledger',
    'customers',
    'disposal_items',
    'disposals',
    'einvoice_config',
    'einvoice_orders',
    'import_items',
    'import_receipts',
    'inventory_count_items',
    'inventory_counts',
    'inventory_movements',
    'order_items',
    'orders',
    'point_history',
    'processed_operations',
    'product_lots',
    'products',
    'promotions',
    'rank_configs',
    'rank_history',
    'return_order_items',
    'return_orders',
    'rewards',
    'stock_movements',
    'supplier_exchange_received_items',
    'supplier_exchange_return_items',
    'supplier_exchanges',
    'supplier_payment_ledger',
    'suppliers'
  ];
BEGIN
  -- 2. Create a temporary full-access policy for authenticated users on every business table.
  --    This keeps the app working while we gradually introduce tenant-scoped RLS in later phases.
  FOREACH tbl IN ARRAY business_tables
  LOOP
    IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = tbl) THEN
      EXECUTE format('DROP POLICY IF EXISTS authenticated_full_access_temp ON public.%I', tbl);
      EXECUTE format(
        'CREATE POLICY authenticated_full_access_temp ON public.%I FOR ALL TO authenticated USING (true) WITH CHECK (true)',
        tbl
      );
    END IF;
  END LOOP;
END $$;
