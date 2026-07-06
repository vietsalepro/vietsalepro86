-- P7.1: Billing schema + bank/company config
-- Tạo bảng invoices, invoice_items, payments, bank_accounts + RLS + cột số hóa đơn + counter cho INV-YYYY-####.
-- ponytail: migration idempotent; chỉ system admin được ghi cấu hình ngân hàng/công ty, tenant member chỉ xem hóa đơn/thanh toán của mình.

-- ============================================================
-- 1. Invoices
-- ============================================================

CREATE TABLE IF NOT EXISTS public.invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  invoice_no TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'pending', 'paid', 'cancelled', 'overdue')),
  issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date DATE NOT NULL,
  period_start DATE,
  period_end DATE,
  subtotal NUMERIC(15, 2) NOT NULL DEFAULT 0,
  discount NUMERIC(15, 2) NOT NULL DEFAULT 0,
  tax NUMERIC(15, 2) NOT NULL DEFAULT 0,
  total NUMERIC(15, 2) NOT NULL DEFAULT 0,
  amount_paid NUMERIC(15, 2) NOT NULL DEFAULT 0,
  balance NUMERIC(15, 2) GENERATED ALWAYS AS (total - amount_paid) STORED,
  notes TEXT,
  created_by UUID DEFAULT auth.uid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS invoices_tenant_id_idx ON public.invoices(tenant_id);
CREATE INDEX IF NOT EXISTS invoices_status_idx ON public.invoices(status);
CREATE INDEX IF NOT EXISTS invoices_issue_date_idx ON public.invoices(issue_date);

ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'invoices' AND policyname = 'invoices_select'
  ) THEN
    CREATE POLICY "invoices_select" ON public.invoices FOR SELECT TO authenticated
      USING (public.is_system_admin() OR (tenant_id = public.current_tenant_id() AND public.is_tenant_member(tenant_id)));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'invoices' AND policyname = 'invoices_write'
  ) THEN
    CREATE POLICY "invoices_write" ON public.invoices FOR ALL TO authenticated
      USING (public.is_system_admin())
      WITH CHECK (public.is_system_admin());
  END IF;
END $$;

-- ============================================================
-- 2. Invoice items
-- ============================================================

CREATE TABLE IF NOT EXISTS public.invoice_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  quantity NUMERIC(15, 2) NOT NULL DEFAULT 1,
  unit_price NUMERIC(15, 2) NOT NULL DEFAULT 0,
  amount NUMERIC(15, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS invoice_items_invoice_id_idx ON public.invoice_items(invoice_id);
CREATE INDEX IF NOT EXISTS invoice_items_tenant_id_idx ON public.invoice_items(tenant_id);

ALTER TABLE public.invoice_items ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'invoice_items' AND policyname = 'invoice_items_select'
  ) THEN
    CREATE POLICY "invoice_items_select" ON public.invoice_items FOR SELECT TO authenticated
      USING (public.is_system_admin() OR (tenant_id = public.current_tenant_id() AND public.is_tenant_member(tenant_id)));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'invoice_items' AND policyname = 'invoice_items_write'
  ) THEN
    CREATE POLICY "invoice_items_write" ON public.invoice_items FOR ALL TO authenticated
      USING (public.is_system_admin())
      WITH CHECK (public.is_system_admin());
  END IF;
END $$;

-- ============================================================
-- 3. Payments
-- ============================================================

CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  invoice_id UUID REFERENCES public.invoices(id) ON DELETE SET NULL,
  amount NUMERIC(15, 2) NOT NULL,
  payment_method TEXT NOT NULL DEFAULT 'bank_transfer' CHECK (payment_method IN ('bank_transfer', 'cash', 'card', 'other')),
  payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  reference_code TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'rejected')),
  notes TEXT,
  created_by UUID DEFAULT auth.uid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS payments_tenant_id_idx ON public.payments(tenant_id);
CREATE INDEX IF NOT EXISTS payments_invoice_id_idx ON public.payments(invoice_id);
CREATE INDEX IF NOT EXISTS payments_status_idx ON public.payments(status);

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'payments' AND policyname = 'payments_select'
  ) THEN
    CREATE POLICY "payments_select" ON public.payments FOR SELECT TO authenticated
      USING (public.is_system_admin() OR (tenant_id = public.current_tenant_id() AND public.is_tenant_member(tenant_id)));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'payments' AND policyname = 'payments_write'
  ) THEN
    CREATE POLICY "payments_write" ON public.payments FOR ALL TO authenticated
      USING (public.is_system_admin())
      WITH CHECK (public.is_system_admin());
  END IF;
END $$;

-- ============================================================
-- 4. Bank accounts (global, for platform invoices)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.bank_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_name TEXT NOT NULL,
  account_number TEXT NOT NULL,
  bank_name TEXT NOT NULL,
  transfer_content TEXT NOT NULL DEFAULT '',
  is_default BOOLEAN NOT NULL DEFAULT false,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS bank_accounts_is_default_idx ON public.bank_accounts(is_default) WHERE is_default = true;
CREATE INDEX IF NOT EXISTS bank_accounts_display_order_idx ON public.bank_accounts(display_order);

ALTER TABLE public.bank_accounts ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'bank_accounts' AND policyname = 'bank_accounts_system_admin_select'
  ) THEN
    CREATE POLICY "bank_accounts_system_admin_select" ON public.bank_accounts FOR SELECT TO authenticated
      USING (public.is_system_admin());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'bank_accounts' AND policyname = 'bank_accounts_system_admin_write'
  ) THEN
    CREATE POLICY "bank_accounts_system_admin_write" ON public.bank_accounts FOR ALL TO authenticated
      USING (public.is_system_admin())
      WITH CHECK (public.is_system_admin());
  END IF;
END $$;

-- ============================================================
-- 5. Invoice number counter (INV-YYYY-####)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.invoice_number_counters (
  year INT PRIMARY KEY,
  counter INT NOT NULL DEFAULT 0
);

CREATE OR REPLACE FUNCTION public.get_next_invoice_number(p_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_counter INT;
BEGIN
  INSERT INTO public.invoice_number_counters (year, counter) VALUES (p_year, 1)
  ON CONFLICT (year) DO UPDATE SET counter = public.invoice_number_counters.counter + 1
  RETURNING counter INTO v_counter;

  RETURN 'INV-' || p_year || '-' || LPAD(v_counter::TEXT, 4, '0');
END;
$$;
