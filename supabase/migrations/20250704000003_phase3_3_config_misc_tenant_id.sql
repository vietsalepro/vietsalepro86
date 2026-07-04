-- Phase 3.3: Add tenant_id to config & misc tables
-- Tables: app_settings, brands, categories, einvoice_config, einvoice_orders,
--          point_history, processed_operations, rank_configs, rank_history,
--          rewards, customer_payment_ledger, supplier_payment_ledger

-- ============================================================
-- 1. Add nullable tenant_id columns
-- ============================================================
ALTER TABLE public.app_settings ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE public.brands ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE public.einvoice_config ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE public.einvoice_orders ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE public.point_history ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE public.processed_operations ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE public.rank_configs ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE public.rank_history ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE public.rewards ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE public.customer_payment_ledger ADD COLUMN IF NOT EXISTS tenant_id UUID;
ALTER TABLE public.supplier_payment_ledger ADD COLUMN IF NOT EXISTS tenant_id UUID;

-- ============================================================
-- 2. Add tenant lookup indexes
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_app_settings_tenant_id ON public.app_settings(tenant_id);
CREATE INDEX IF NOT EXISTS idx_brands_tenant_id ON public.brands(tenant_id);
CREATE INDEX IF NOT EXISTS idx_categories_tenant_id ON public.categories(tenant_id);
CREATE INDEX IF NOT EXISTS idx_einvoice_config_tenant_id ON public.einvoice_config(tenant_id);
CREATE INDEX IF NOT EXISTS idx_einvoice_orders_tenant_id ON public.einvoice_orders(tenant_id);
CREATE INDEX IF NOT EXISTS idx_point_history_tenant_id ON public.point_history(tenant_id);
CREATE INDEX IF NOT EXISTS idx_processed_operations_tenant_id ON public.processed_operations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_rank_configs_tenant_id ON public.rank_configs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_rank_history_tenant_id ON public.rank_history(tenant_id);
CREATE INDEX IF NOT EXISTS idx_rewards_tenant_id ON public.rewards(tenant_id);
CREATE INDEX IF NOT EXISTS idx_customer_payment_ledger_tenant_id ON public.customer_payment_ledger(tenant_id);
CREATE INDEX IF NOT EXISTS idx_supplier_payment_ledger_tenant_id ON public.supplier_payment_ledger(tenant_id);

-- ============================================================
-- 3. Add foreign keys to public.tenants (idempotent)
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.app_settings'::regclass AND conname = 'fk_app_settings_tenant_id') THEN
    ALTER TABLE public.app_settings ADD CONSTRAINT fk_app_settings_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.brands'::regclass AND conname = 'fk_brands_tenant_id') THEN
    ALTER TABLE public.brands ADD CONSTRAINT fk_brands_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.categories'::regclass AND conname = 'fk_categories_tenant_id') THEN
    ALTER TABLE public.categories ADD CONSTRAINT fk_categories_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.einvoice_config'::regclass AND conname = 'fk_einvoice_config_tenant_id') THEN
    ALTER TABLE public.einvoice_config ADD CONSTRAINT fk_einvoice_config_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.einvoice_orders'::regclass AND conname = 'fk_einvoice_orders_tenant_id') THEN
    ALTER TABLE public.einvoice_orders ADD CONSTRAINT fk_einvoice_orders_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.point_history'::regclass AND conname = 'fk_point_history_tenant_id') THEN
    ALTER TABLE public.point_history ADD CONSTRAINT fk_point_history_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.processed_operations'::regclass AND conname = 'fk_processed_operations_tenant_id') THEN
    ALTER TABLE public.processed_operations ADD CONSTRAINT fk_processed_operations_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.rank_configs'::regclass AND conname = 'fk_rank_configs_tenant_id') THEN
    ALTER TABLE public.rank_configs ADD CONSTRAINT fk_rank_configs_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.rank_history'::regclass AND conname = 'fk_rank_history_tenant_id') THEN
    ALTER TABLE public.rank_history ADD CONSTRAINT fk_rank_history_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.rewards'::regclass AND conname = 'fk_rewards_tenant_id') THEN
    ALTER TABLE public.rewards ADD CONSTRAINT fk_rewards_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.customer_payment_ledger'::regclass AND conname = 'fk_customer_payment_ledger_tenant_id') THEN
    ALTER TABLE public.customer_payment_ledger ADD CONSTRAINT fk_customer_payment_ledger_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.supplier_payment_ledger'::regclass AND conname = 'fk_supplier_payment_ledger_tenant_id') THEN
    ALTER TABLE public.supplier_payment_ledger ADD CONSTRAINT fk_supplier_payment_ledger_tenant_id FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON DELETE CASCADE;
  END IF;
END $$;
