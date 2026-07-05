-- Sub-phase 9.5: Edge Function `process-checkout` prerequisites
-- Mục tiêu: Cung cấp RPC tenant-aware để Edge Function xử lý đơn hàng atomic.
-- ponytail: Tạo function mới process_checkout_tenant thay vì sửa function cũ,
-- để giữ backward compatibility cho frontend gọi process_checkout trong quá trình chuyển đổi.

-- ============================================================================
-- 1. Mở rộng rate_limit_logs action enum cho process_checkout
-- ============================================================================

ALTER TABLE public.rate_limit_logs
DROP CONSTRAINT IF EXISTS rate_limit_logs_action_check;

ALTER TABLE public.rate_limit_logs
ADD CONSTRAINT rate_limit_logs_action_check
CHECK (action IN ('login', 'create_tenant', 'check_subdomain', 'invite_member', 'process_checkout'));

-- ============================================================================
-- 2. Tenant-aware atomic checkout RPC
-- ============================================================================

CREATE OR REPLACE FUNCTION public.process_checkout_tenant(
  p_tenant_id UUID,
  p_order JSONB,
  p_items JSONB DEFAULT '[]'::JSONB,
  p_deltas JSONB DEFAULT '[]'::JSONB,
  p_reward_deltas JSONB DEFAULT '[]'::JSONB,
  p_customer_update JSONB DEFAULT NULL::JSONB,
  p_point_history JSONB DEFAULT '[]'::JSONB,
  p_allow_negative BOOLEAN DEFAULT FALSE,
  p_op_id TEXT DEFAULT NULL::TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tenant          public.tenants%ROWTYPE;
  v_order_id        TEXT;
  v_customer_id     TEXT;
  v_item            JSONB;
  v_delta           JSONB;
  v_reward          JSONB;
  v_ph              JSONB;
  v_product         RECORD;
  v_reward_row      RECORD;
  v_lot             RECORD;
  v_lot_id          TEXT;
  v_deduct_qty      NUMERIC;
  v_new_qty         NUMERIC;
  v_new_stock       NUMERIC;
  v_add_spent       NUMERIC;
  v_add_debt        NUMERIC;
  v_add_points      NUMERIC;
  v_item_cost       NUMERIC;
  v_inserted_op     INTEGER;
  v_order_item_id   TEXT;
  v_idx             INTEGER;
  v_qty_after       NUMERIC;
  v_posting_date    TIMESTAMPTZ;
BEGIN
  IF p_tenant_id IS NULL THEN
    RAISE EXCEPTION 'tenant_id is required';
  END IF;

  SELECT * INTO v_tenant FROM public.tenants WHERE id = p_tenant_id;
  IF NOT FOUND OR v_tenant.status NOT IN ('active', 'trial') THEN
    RAISE EXCEPTION 'Tenant không hoạt động hoặc không tồn tại';
  END IF;

  v_order_id := p_order->>'id';
  IF v_order_id IS NULL OR v_order_id = '' THEN
    RAISE EXCEPTION 'order.id is required';
  END IF;

  v_posting_date := COALESCE((p_order->>'date')::TIMESTAMPTZ, NOW());

  -- Idempotency: ghi nhận tenant_id để dọn dẹp dễ dàng sau này.
  IF p_op_id IS NOT NULL AND p_op_id != '' THEN
    INSERT INTO public.processed_operations (op_id, op_type, ref_id, tenant_id)
    VALUES (p_op_id, 'checkout', v_order_id, p_tenant_id)
    ON CONFLICT (op_id) DO NOTHING;
    GET DIAGNOSTICS v_inserted_op = ROW_COUNT;
    IF v_inserted_op = 0 THEN
      RETURN jsonb_build_object('ok', true, 'order_id', v_order_id, 'skipped', true, 'reason', 'op_id already processed');
    END IF;
  END IF;

  v_customer_id := p_order->>'customerId';
  IF v_customer_id IS NULL OR v_customer_id = '' OR v_customer_id = 'guest' THEN
    v_customer_id := NULL;
  END IF;

  -- Nếu có customer_id, xác minh customer thuộc tenant.
  IF v_customer_id IS NOT NULL THEN
    PERFORM 1 FROM public.customers WHERE id = v_customer_id AND tenant_id = p_tenant_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Khách hàng không thuộc tenant này';
    END IF;
  END IF;

  IF p_op_id IS NOT NULL AND p_op_id != '' THEN
    INSERT INTO public.orders (
      id, date, customer_id, customer_name,
      total_amount, paid_amount, debt_recorded, payment_method,
      status, points_earned, points_redeemed, rewards_redeemed,
      applied_promotions, note, tenant_id
    ) VALUES (
      v_order_id, v_posting_date, v_customer_id, p_order->>'customerName',
      COALESCE((p_order->>'totalAmount')::NUMERIC, 0),
      COALESCE((p_order->>'paidAmount')::NUMERIC, 0),
      COALESCE((p_order->>'debtRecorded')::NUMERIC, 0),
      p_order->>'paymentMethod',
      COALESCE(p_order->>'status', 'completed'),
      COALESCE((p_order->>'pointsEarned')::NUMERIC, 0),
      COALESCE((p_order->>'pointsRedeemed')::NUMERIC, 0),
      COALESCE(p_order->'rewardsRedeemed', '[]'::jsonb),
      COALESCE(p_order->'appliedPromotions', '[]'::jsonb),
      p_order->>'note',
      p_tenant_id
    );
  ELSE
    INSERT INTO public.orders (
      id, date, customer_id, customer_name,
      total_amount, paid_amount, debt_recorded, payment_method,
      status, points_earned, points_redeemed, rewards_redeemed,
      applied_promotions, note, tenant_id
    ) VALUES (
      v_order_id, v_posting_date, v_customer_id, p_order->>'customerName',
      COALESCE((p_order->>'totalAmount')::NUMERIC, 0),
      COALESCE((p_order->>'paidAmount')::NUMERIC, 0),
      COALESCE((p_order->>'debtRecorded')::NUMERIC, 0),
      p_order->>'paymentMethod',
      COALESCE(p_order->>'status', 'completed'),
      COALESCE((p_order->>'pointsEarned')::NUMERIC, 0),
      COALESCE((p_order->>'pointsRedeemed')::NUMERIC, 0),
      COALESCE(p_order->'rewardsRedeemed', '[]'::jsonb),
      COALESCE(p_order->'appliedPromotions', '[]'::jsonb),
      p_order->>'note',
      p_tenant_id
    )
    ON CONFLICT (id) DO UPDATE SET
      date               = EXCLUDED.date,
      customer_id        = EXCLUDED.customer_id,
      customer_name      = EXCLUDED.customer_name,
      total_amount       = EXCLUDED.total_amount,
      paid_amount        = EXCLUDED.paid_amount,
      debt_recorded      = EXCLUDED.debt_recorded,
      payment_method     = EXCLUDED.payment_method,
      status             = EXCLUDED.status,
      points_earned      = EXCLUDED.points_earned,
      points_redeemed    = EXCLUDED.points_redeemed,
      rewards_redeemed   = EXCLUDED.rewards_redeemed,
      applied_promotions = EXCLUDED.applied_promotions,
      note               = EXCLUDED.note,
      tenant_id          = EXCLUDED.tenant_id;
  END IF;

  CREATE TEMP TABLE IF NOT EXISTS tmp_phase7b_order_item_ids (
    idx INTEGER PRIMARY KEY,
    order_item_id TEXT
  ) ON COMMIT DROP;
  DELETE FROM tmp_phase7b_order_item_ids;

  DELETE FROM public.order_items WHERE order_id = v_order_id AND tenant_id = p_tenant_id;
  IF jsonb_typeof(p_items) = 'array' AND jsonb_array_length(p_items) > 0 THEN
    v_idx := 0;
    FOR v_item IN SELECT value FROM jsonb_array_elements(p_items) LOOP
      v_idx := v_idx + 1;
      v_item_cost := COALESCE(
        (v_item->>'cost')::NUMERIC,
        CASE
          WHEN NULLIF(v_item->>'lotId', '') IS NOT NULL THEN
            (SELECT cost FROM public.product_lots WHERE id = v_item->>'lotId' AND tenant_id = p_tenant_id)
          ELSE
            (SELECT cost FROM public.products WHERE id = v_item->>'productId' AND tenant_id = p_tenant_id)
        END,
        0
      );
      INSERT INTO public.order_items (
        order_id, product_id, product_name, quantity, unit_name, price,
        lot_id, lot_code, cost, tenant_id
      ) VALUES (
        v_order_id, v_item->>'productId', v_item->>'productName',
        COALESCE((v_item->>'quantity')::NUMERIC, 0), v_item->>'unitName',
        COALESCE((v_item->>'price')::NUMERIC, 0),
        NULLIF(v_item->>'lotId', ''), NULLIF(v_item->>'lotCode', ''),
        v_item_cost, p_tenant_id
      ) RETURNING id INTO v_order_item_id;
      INSERT INTO tmp_phase7b_order_item_ids (idx, order_item_id)
      VALUES (v_idx, v_order_item_id);
    END LOOP;
  END IF;

  IF jsonb_typeof(p_deltas) = 'array' AND jsonb_array_length(p_deltas) > 0 THEN
    FOR v_delta IN SELECT * FROM jsonb_array_elements(p_deltas) LOOP
      v_deduct_qty := COALESCE((v_delta->>'deductBaseQty')::NUMERIC, 0);
      v_lot_id     := NULLIF(v_delta->>'lotId', '');
      IF v_deduct_qty <= 0 THEN CONTINUE; END IF;
      SELECT id, name, quantity, has_lots INTO v_product
      FROM public.products WHERE id = v_delta->>'productId' AND tenant_id = p_tenant_id FOR UPDATE;
      IF NOT FOUND THEN
        RAISE EXCEPTION 'Sản phẩm % không tồn tại trong hệ thống', v_delta->>'productId';
      END IF;
      IF v_product.has_lots THEN
        IF v_lot_id IS NULL THEN
          RAISE EXCEPTION 'Sản phẩm "%" có quản lý lô, phải chọn lô khi bán', v_product.name
            USING ERRCODE = 'P0001';
        END IF;
        SELECT id, code, quantity INTO v_lot
        FROM public.product_lots WHERE id = v_lot_id AND product_id = v_product.id AND tenant_id = p_tenant_id FOR UPDATE;
        IF NOT FOUND THEN
          RAISE EXCEPTION 'Lô % không tồn tại cho sản phẩm "%"', v_lot_id, v_product.name;
        END IF;
        v_new_qty := COALESCE(v_lot.quantity, 0) - v_deduct_qty;
        IF v_new_qty < 0 AND NOT p_allow_negative THEN
          RAISE EXCEPTION 'Tồn lô "%" của "%" không đủ (còn %, cần %)',
            v_lot.code, v_product.name, v_lot.quantity, v_deduct_qty
            USING ERRCODE = 'P0001';
        END IF;
        UPDATE public.product_lots SET quantity = v_new_qty, updated_at = NOW() WHERE id = v_lot.id AND tenant_id = p_tenant_id;
      ELSE
        v_new_qty := COALESCE(v_product.quantity, 0) - v_deduct_qty;
        IF v_new_qty < 0 AND NOT p_allow_negative THEN
          RAISE EXCEPTION 'Tồn kho không đủ cho "%" (còn %, cần %)',
            v_product.name, v_product.quantity, v_deduct_qty
            USING ERRCODE = 'P0001';
        END IF;
        UPDATE public.products SET quantity = v_new_qty WHERE id = v_product.id AND tenant_id = p_tenant_id;
      END IF;
    END LOOP;
  END IF;

  IF jsonb_typeof(p_reward_deltas) = 'array' AND jsonb_array_length(p_reward_deltas) > 0 THEN
    FOR v_reward IN SELECT * FROM jsonb_array_elements(p_reward_deltas) LOOP
      IF COALESCE((v_reward->>'quantity')::NUMERIC, 0) <= 0 THEN CONTINUE; END IF;
      SELECT id, name, stock INTO v_reward_row
      FROM public.rewards WHERE id = v_reward->>'rewardId' AND tenant_id = p_tenant_id FOR UPDATE;
      IF NOT FOUND THEN CONTINUE; END IF;
      v_new_stock := COALESCE(v_reward_row.stock, 0) - (v_reward->>'quantity')::NUMERIC;
      IF v_new_stock < 0 AND NOT p_allow_negative THEN
        RAISE EXCEPTION 'Hết quà tặng "%" (còn %, cần %)',
          v_reward_row.name, v_reward_row.stock, v_reward->>'quantity';
      END IF;
      UPDATE public.rewards SET stock = GREATEST(v_new_stock, 0) WHERE id = v_reward_row.id AND tenant_id = p_tenant_id;
    END LOOP;
  END IF;

  IF jsonb_typeof(p_items) = 'array' AND jsonb_array_length(p_items) > 0 THEN
    v_idx := 0;
    FOR v_item IN SELECT value FROM jsonb_array_elements(p_items) LOOP
      v_idx := v_idx + 1;
      SELECT order_item_id INTO v_order_item_id FROM tmp_phase7b_order_item_ids WHERE idx = v_idx;
      IF v_order_item_id IS NULL THEN CONTINUE; END IF;
      v_lot_id := NULLIF(v_item->>'lotId', '');
      v_item_cost := COALESCE(
        (v_item->>'cost')::NUMERIC,
        CASE
          WHEN v_lot_id IS NOT NULL THEN (SELECT cost FROM public.product_lots WHERE id = v_lot_id AND tenant_id = p_tenant_id)
          ELSE (SELECT cost FROM public.products WHERE id = v_item->>'productId' AND tenant_id = p_tenant_id)
        END,
        0
      );
      v_qty_after := public.calc_qty_after_transaction(v_item->>'productId', v_lot_id, -COALESCE((v_item->>'quantity')::NUMERIC, 0));
      PERFORM public.insert_stock_ledger_entry(
        v_posting_date, 'Sales Invoice'::TEXT, v_order_id, v_order_item_id,
        v_item->>'productId', v_lot_id, 'Kho Chính'::TEXT,
        -COALESCE((v_item->>'quantity')::NUMERIC, 0), v_qty_after,
        v_item_cost, 0::NUMERIC, v_item_cost, NULL, FALSE
      );
    END LOOP;
  END IF;

  IF p_customer_update IS NOT NULL
     AND p_customer_update->>'customerId' IS NOT NULL
     AND p_customer_update->>'customerId' != ''
     AND p_customer_update->>'customerId' != 'guest' THEN
    v_add_spent  := COALESCE((p_customer_update->>'addSpent')::NUMERIC, 0);
    v_add_debt   := COALESCE((p_customer_update->>'addDebt')::NUMERIC, 0);
    v_add_points := COALESCE((p_customer_update->>'addPoints')::NUMERIC, 0);
    UPDATE public.customers SET
      total_spent        = GREATEST(0, COALESCE(total_spent, 0) + v_add_spent),
      debt               = GREATEST(0, COALESCE(debt, 0) + v_add_debt),
      loyalty_points     = GREATEST(0, COALESCE(loyalty_points, 0) + v_add_points),
      last_purchase_date = COALESCE(v_posting_date, NOW()),
      updated_at         = NOW()
    WHERE id = p_customer_update->>'customerId' AND tenant_id = p_tenant_id;

    IF v_add_debt > 0 THEN
      PERFORM public.insert_customer_ledger_entry(
        p_customer_id    := p_customer_update->>'customerId',
        p_reference_type := 'order',
        p_reference_id   := v_order_id,
        p_amount         := v_add_debt,
        p_reason         := 'Tạo đơn nợ ' || v_order_id,
        p_created_by     := COALESCE(NULLIF(p_op_id, ''), 'system'),
        p_created_at     := COALESCE(v_posting_date, NOW())
      );
    END IF;
  END IF;

  IF jsonb_typeof(p_point_history) = 'array' AND jsonb_array_length(p_point_history) > 0 THEN
    FOR v_ph IN SELECT * FROM jsonb_array_elements(p_point_history) LOOP
      INSERT INTO public.point_history (id, customer_id, date, type, amount, description, order_id, tenant_id)
      VALUES (
        v_ph->>'id', NULLIF(v_ph->>'customerId', ''),
        COALESCE((v_ph->>'date')::TIMESTAMPTZ, NOW()), v_ph->>'type',
        COALESCE((v_ph->>'amount')::NUMERIC, 0), v_ph->>'description',
        NULLIF(v_ph->>'orderId', ''), p_tenant_id
      )
      ON CONFLICT (id) DO UPDATE SET
        amount      = EXCLUDED.amount,
        description = EXCLUDED.description;
    END LOOP;
  END IF;

  RETURN jsonb_build_object('ok', true, 'order_id', v_order_id, 'skipped', false);
END;
$$;
