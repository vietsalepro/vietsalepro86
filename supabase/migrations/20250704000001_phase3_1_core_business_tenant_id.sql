-- Phase 3.1: Add tenant_id to core business tables
-- Tables: products, customers, orders, order_items, suppliers, promotions

-- ============================================================
-- 1. Add nullable tenant_id columns
-- ============================================================
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE public.suppliers ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE public.promotions ADD COLUMN IF NOT EXISTS tenant_id UUID;

-- ============================================================
-- 2. Add tenant lookup indexes
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_products_tenant_id ON public.products(tenant_id);
CREATE INDEX IF NOT EXISTS idx_customers_tenant_id ON public.customers(tenant_id);
CREATE INDEX IF NOT EXISTS idx_orders_tenant_id ON public.orders(tenant_id);
CREATE INDEX IF NOT EXISTS idx_order_items_tenant_id ON public.order_items(tenant_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_tenant_id ON public.suppliers(tenant_id);
CREATE INDEX IF NOT EXISTS idx_promotions_tenant_id ON public.promotions(tenant_id);

-- ============================================================
-- 3. Add foreign keys to public.tenants (idempotent)
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.products'::regclass AND conname = 'fk_products_tenant_id') THEN
    ALTER TABLE public.products ADD CONSTRAINT fk_products_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.customers'::regclass AND conname = 'fk_customers_tenant_id') THEN
    ALTER TABLE public.customers ADD CONSTRAINT fk_customers_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.orders'::regclass AND conname = 'fk_orders_tenant_id') THEN
    ALTER TABLE public.orders ADD CONSTRAINT fk_orders_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.order_items'::regclass AND conname = 'fk_order_items_tenant_id') THEN
    ALTER TABLE public.order_items ADD CONSTRAINT fk_order_items_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.suppliers'::regclass AND conname = 'fk_suppliers_tenant_id') THEN
    ALTER TABLE public.suppliers ADD CONSTRAINT fk_suppliers_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.promotions'::regclass AND conname = 'fk_promotions_tenant_id') THEN
    ALTER TABLE public.promotions ADD CONSTRAINT fk_promotions_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;
END $$;
