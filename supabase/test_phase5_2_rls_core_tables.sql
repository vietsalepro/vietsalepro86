-- Phase 5.2 RLS isolation test for core tables
-- Run inside a transaction; rolls back automatically.

BEGIN;

DO $$
DECLARE
  user_a UUID := '64d25af2-a592-4dd4-b1ff-365e7116e372';
  user_b UUID := '1271d9f5-a0c8-47f3-ace5-4ffa9cc8a82f';
  tenant_a UUID := '1bae028e-5941-4a0d-9089-d1263ee5ef64';
  tenant_b UUID;
  prod_a TEXT;
  prod_b TEXT;
  cust_a TEXT;
  cust_b TEXT;
  order_a TEXT;
  order_b TEXT;
  supplier_a TEXT;
  supplier_b TEXT;
  visible_count INTEGER;
  insert_rejected BOOLEAN;
BEGIN
  -- Ensure user_a is a member of tenant_a (idempotent)
  INSERT INTO public.tenant_memberships (tenant_id, user_id, role)
  VALUES (tenant_a, user_a, 'admin')
  ON CONFLICT (tenant_id, user_id) DO NOTHING;

  -- Create a second tenant for user_b
  INSERT INTO public.tenants (name, subdomain, owner_id)
  VALUES ('Phase 5.2 Test Tenant B', 'phase5-2-test-b', user_b)
  RETURNING id INTO tenant_b;

  INSERT INTO public.tenant_memberships (tenant_id, user_id, role)
  VALUES (tenant_b, user_b, 'admin');

  -- Create test data in tenant A
  prod_a := 'PHASE52-PROD-A';
  INSERT INTO public.products (id, name, code, tenant_id, has_lots)
  VALUES (prod_a, 'Product A', 'PHASE52-A', tenant_a, false);

  cust_a := 'PHASE52-CUST-A';
  INSERT INTO public.customers (id, name, phone, tenant_id)
  VALUES (cust_a, 'Customer A', '0900000001', tenant_a);

  supplier_a := 'PHASE52-SUPPLIER-A';
  INSERT INTO public.suppliers (id, name, phone, tenant_id)
  VALUES (supplier_a, 'Supplier A', '0900000002', tenant_a);

  order_a := 'PHASE52-ORDER-A';
  INSERT INTO public.orders (id, customer_id, total_amount, tenant_id)
  VALUES (order_a, cust_a, 100000, tenant_a);

  INSERT INTO public.order_items (order_id, product_id, quantity, price, tenant_id)
  VALUES (order_a, prod_a, 1, 100000, tenant_a);

  -- Create test data in tenant B
  prod_b := 'PHASE52-PROD-B';
  INSERT INTO public.products (id, name, code, tenant_id, has_lots)
  VALUES (prod_b, 'Product B', 'PHASE52-B', tenant_b, false);

  cust_b := 'PHASE52-CUST-B';
  INSERT INTO public.customers (id, name, phone, tenant_id)
  VALUES (cust_b, 'Customer B', '0900000003', tenant_b);

  supplier_b := 'PHASE52-SUPPLIER-B';
  INSERT INTO public.suppliers (id, name, phone, tenant_id)
  VALUES (supplier_b, 'Supplier B', '0900000004', tenant_b);

  order_b := 'PHASE52-ORDER-B';
  INSERT INTO public.orders (id, customer_id, total_amount, tenant_id)
  VALUES (order_b, cust_b, 200000, tenant_b);

  INSERT INTO public.order_items (order_id, product_id, quantity, price, tenant_id)
  VALUES (order_b, prod_b, 1, 200000, tenant_b);

  -- Switch to authenticated role and set user_a context + tenant_a header
  SET ROLE authenticated;
  PERFORM set_config('request.jwt.claims', json_build_object('sub', user_a)::text, true);
  PERFORM set_config('request.headers', json_build_object('x-tenant-id', tenant_a)::text, true);

  -- User A should see only tenant_a data
  SELECT COUNT(*) INTO visible_count FROM public.products;
  RAISE NOTICE 'User A products visible: %', visible_count;
  ASSERT visible_count >= 1 AND EXISTS (SELECT 1 FROM public.products WHERE id = prod_a), 'User A should see product A';
  ASSERT NOT EXISTS (SELECT 1 FROM public.products WHERE id = prod_b), 'User A should NOT see product B';

  SELECT COUNT(*) INTO visible_count FROM public.customers;
  RAISE NOTICE 'User A customers visible: %', visible_count;
  ASSERT EXISTS (SELECT 1 FROM public.customers WHERE id = cust_a), 'User A should see customer A';
  ASSERT NOT EXISTS (SELECT 1 FROM public.customers WHERE id = cust_b), 'User A should NOT see customer B';

  SELECT COUNT(*) INTO visible_count FROM public.orders;
  RAISE NOTICE 'User A orders visible: %', visible_count;
  ASSERT EXISTS (SELECT 1 FROM public.orders WHERE id = order_a), 'User A should see order A';
  ASSERT NOT EXISTS (SELECT 1 FROM public.orders WHERE id = order_b), 'User A should NOT see order B';

  SELECT COUNT(*) INTO visible_count FROM public.order_items;
  RAISE NOTICE 'User A order_items visible: %', visible_count;
  ASSERT EXISTS (SELECT 1 FROM public.order_items WHERE order_id = order_a), 'User A should see order item A';
  ASSERT NOT EXISTS (SELECT 1 FROM public.order_items WHERE order_id = order_b), 'User A should NOT see order item B';

  SELECT COUNT(*) INTO visible_count FROM public.suppliers;
  RAISE NOTICE 'User A suppliers visible: %', visible_count;
  ASSERT EXISTS (SELECT 1 FROM public.suppliers WHERE id = supplier_a), 'User A should see supplier A';
  ASSERT NOT EXISTS (SELECT 1 FROM public.suppliers WHERE id = supplier_b), 'User A should NOT see supplier B';

  -- Switch to user_b context + tenant_b header
  PERFORM set_config('request.jwt.claims', json_build_object('sub', user_b)::text, true);
  PERFORM set_config('request.headers', json_build_object('x-tenant-id', tenant_b)::text, true);

  -- User B querying tenant B should see only tenant_b data
  SELECT COUNT(*) INTO visible_count FROM public.products;
  RAISE NOTICE 'User B products visible: %', visible_count;
  ASSERT EXISTS (SELECT 1 FROM public.products WHERE id = prod_b), 'User B should see product B';
  ASSERT NOT EXISTS (SELECT 1 FROM public.products WHERE id = prod_a), 'User B should NOT see product A';

  -- User A querying tenant B (user A is not a member) should return 0 rows
  PERFORM set_config('request.jwt.claims', json_build_object('sub', user_a)::text, true);
  PERFORM set_config('request.headers', json_build_object('x-tenant-id', tenant_b)::text, true);
  SELECT COUNT(*) INTO visible_count FROM public.products;
  RAISE NOTICE 'User A with tenant B header products visible: %', visible_count;
  ASSERT visible_count = 0, 'User A querying tenant B should return 0 rows';

  -- User A trying to insert with tenant_b should be rejected
  PERFORM set_config('request.jwt.claims', json_build_object('sub', user_a)::text, true);
  PERFORM set_config('request.headers', json_build_object('x-tenant-id', tenant_b)::text, true);
  insert_rejected := false;
  BEGIN
    INSERT INTO public.products (id, name, code, tenant_id, has_lots)
    VALUES ('PHASE52-HACKED', 'Hacked Product', 'HACKED', tenant_b, false);
  EXCEPTION WHEN insufficient_privilege THEN
    insert_rejected := true;
  END;
  RAISE NOTICE 'User A insert into tenant B rejected: %', insert_rejected;
  ASSERT insert_rejected, 'User A should be rejected when inserting into tenant B';

  RESET ROLE;

  RAISE NOTICE 'Phase 5.2 RLS core tables test PASSED';
END $$;

ROLLBACK;
