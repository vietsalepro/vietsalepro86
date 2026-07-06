import React from 'react';
import { CreditCard, ChevronRight, Loader2 } from 'lucide-react';
import { useTenant } from '../../../hooks/useTenant';
import './CheckoutButton.css';

interface CheckoutButtonProps {
  onClick: () => void;
  disabled?: boolean;
  loading?: boolean;
  total: number;
}

/**
 * CheckoutButton — CTA thanh toán
 * Style đồng bộ với ig-btn-primary (slate-800, không gradient tím)
 */
export const CheckoutButton: React.FC<CheckoutButtonProps> = ({ onClick, disabled, loading, total }) => {
  const { isReadOnly } = useTenant();
  return (
    <button
      onClick={onClick}
      disabled={disabled || loading || isReadOnly}
      title={isReadOnly ? 'Tài khoản hết hạn — vui lòng thanh toán' : undefined}
      className="checkout-btn"
    >
      {loading ? (
        <>
          <Loader2 className="checkout-btn__icon checkout-btn__icon--spin" />
          <span>Đang xử lý...</span>
        </>
      ) : (
        <>
          <CreditCard className="checkout-btn__icon" />
          <span className="checkout-btn__text">
            THANH TOÁN <span className="checkout-btn__hint">(F9)</span>
          </span>
          <ChevronRight className="checkout-btn__chevron" />
        </>
      )}
    </button>
  );
};
