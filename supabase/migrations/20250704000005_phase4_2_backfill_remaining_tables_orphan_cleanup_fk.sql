-- Phase 4.2: Backfill remaining tables + orphan cleanup + FK
-- Mục tiêu: Dữ liệu cũ thuộc về tenant đầu tiên; xử lý 26 bảng còn lại, dọn orphan, thêm FK lot_id.
-- ponytail: Kế hoạch ghi 27 bảng, nhưng thực tế DB có 26 bảng cần backfill sau Phase 4.1.
-- ponytail: import_items chưa có cột lot_id nên phải thêm cột + populate từ lot_code trước khi add FK.

-- ============================================================
-- 1. Backfill remaining tables (26 bảng)
-- ============================================================
DO $$
DECLARE v_tenant_id UUID;
BEGIN
  SELECT id INTO v_tenant_id FROM public.tenants WHERE subdomain = 'main';
  IF v_tenant_id IS NOT NULL THEN
    UPDATE public.app_settings SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.brands SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.categories SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.customer_payment_ledger SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.disposal_items SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.disposals SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.einvoice_config SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.einvoice_orders SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.import_items SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.import_receipts SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.inventory_count_items SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.inventory_counts SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.inventory_movements SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.point_history SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.processed_operations SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.product_lots SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.rank_configs SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.rank_history SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.return_order_items SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.return_orders SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.rewards SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.stock_movements SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.supplier_exchange_received_items SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.supplier_exchange_return_items SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.supplier_exchanges SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
    UPDATE public.supplier_payment_ledger SET tenant_id = v_tenant_id WHERE tenant_id IS NULL;
  END IF;
END $$;

-- ============================================================
-- 2. Set NOT NULL cho tenant_id trên 26 bảng
-- ============================================================
ALTER TABLE public.app_settings ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.brands ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.categories ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.customer_payment_ledger ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.disposal_items ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.disposals ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.einvoice_config ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.einvoice_orders ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.import_items ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.import_receipts ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.inventory_count_items ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.inventory_counts ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.inventory_movements ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.point_history ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.processed_operations ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.product_lots ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.rank_configs ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.rank_history ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.return_order_items ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.return_orders ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.rewards ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.stock_movements ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.supplier_exchange_received_items ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.supplier_exchange_return_items ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.supplier_exchanges ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE public.supplier_payment_ledger ALTER COLUMN tenant_id SET NOT NULL;

-- ============================================================
-- 3. Backup orphan records (cha-con)
-- ponytail: Dùng tên cột cha thật trong DB (receipt_id, count_id, exchange_id), không phải tên trong kế hoạch.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.orphan_records_backup (
  table_name TEXT,
  backed_up_at TIMESTAMPTZ DEFAULT now(),
  data JSONB
);

INSERT INTO public.orphan_records_backup (table_name, data)
SELECT 'order_items', to_jsonb(t.*) FROM public.order_items t WHERE t.order_id IS NULL;

INSERT INTO public.orphan_records_backup (table_name, data)
SELECT 'import_items', to_jsonb(t.*) FROM public.import_items t WHERE t.receipt_id IS NULL;

INSERT INTO public.orphan_records_backup (table_name, data)
SELECT 'product_lots', to_jsonb(t.*) FROM public.product_lots t WHERE t.product_id IS NULL;

INSERT INTO public.orphan_records_backup (table_name, data)
SELECT 'return_order_items', to_jsonb(t.*) FROM public.return_order_items t WHERE t.return_order_id IS NULL;

INSERT INTO public.orphan_records_backup (table_name, data)
SELECT 'inventory_count_items', to_jsonb(t.*) FROM public.inventory_count_items t WHERE t.count_id IS NULL;

INSERT INTO public.orphan_records_backup (table_name, data)
SELECT 'disposal_items', to_jsonb(t.*) FROM public.disposal_items t WHERE t.disposal_id IS NULL;

INSERT INTO public.orphan_records_backup (table_name, data)
SELECT 'supplier_exchange_return_items', to_jsonb(t.*) FROM public.supplier_exchange_return_items t WHERE t.exchange_id IS NULL;

INSERT INTO public.orphan_records_backup (table_name, data)
SELECT 'supplier_exchange_received_items', to_jsonb(t.*) FROM public.supplier_exchange_received_items t WHERE t.exchange_id IS NULL;

-- ============================================================
-- 4. Delete orphan records
-- ============================================================
DELETE FROM public.order_items WHERE order_id IS NULL;
DELETE FROM public.import_items WHERE receipt_id IS NULL;
DELETE FROM public.product_lots WHERE product_id IS NULL;
DELETE FROM public.return_order_items WHERE return_order_id IS NULL;
DELETE FROM public.inventory_count_items WHERE count_id IS NULL;
DELETE FROM public.disposal_items WHERE disposal_id IS NULL;
DELETE FROM public.supplier_exchange_return_items WHERE exchange_id IS NULL;
DELETE FROM public.supplier_exchange_received_items WHERE exchange_id IS NULL;

-- ============================================================
-- 5. Chuẩn bị lot_id cho import_items (cột chưa tồn tại)
-- ============================================================
ALTER TABLE public.import_items ADD COLUMN IF NOT EXISTS lot_id TEXT;

-- ponytail: populate từ lot_code nếu khớp product_id + code. product_lots.id là TEXT nên lot_id cũng là TEXT.
UPDATE public.import_items i
SET lot_id = pl.id
FROM public.product_lots pl
WHERE i.lot_id IS NULL
  AND i.lot_code IS NOT NULL
  AND i.lot_code <> ''
  AND pl.product_id = i.product_id
  AND pl.code = i.lot_code;

-- ============================================================
-- 6. Backup + cleanup lot_id reference không hợp lệ trước khi thêm FK
-- ============================================================
INSERT INTO public.orphan_records_backup (table_name, data)
SELECT 'order_items_invalid_lot', to_jsonb(t.*)
FROM public.order_items t
WHERE t.lot_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM public.product_lots WHERE id = t.lot_id);

UPDATE public.order_items
SET lot_id = NULL
WHERE lot_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM public.product_lots WHERE id = lot_id);

-- ============================================================
-- 7. Add missing FKs (NO ACTION: không cho xóa lô nếu còn tham chiếu)
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.order_items'::regclass AND conname = 'order_items_lot_id_fkey') THEN
    ALTER TABLE public.order_items ADD CONSTRAINT order_items_lot_id_fkey
      FOREIGN KEY (lot_id) REFERENCES public.product_lots(id) ON DELETE NO ACTION;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.return_order_items'::regclass AND conname = 'return_order_items_lot_id_fkey') THEN
    ALTER TABLE public.return_order_items ADD CONSTRAINT return_order_items_lot_id_fkey
      FOREIGN KEY (lot_id) REFERENCES public.product_lots(id) ON DELETE NO ACTION;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.import_items'::regclass AND conname = 'import_items_lot_id_fkey') THEN
    ALTER TABLE public.import_items ADD CONSTRAINT import_items_lot_id_fkey
      FOREIGN KEY (lot_id) REFERENCES public.product_lots(id) ON DELETE NO ACTION;
  END IF;
END $$;
