import React, { useEffect, useRef } from 'react';
import { AlertCircle, AlertTriangle, Info } from 'lucide-react';
import { ActionButton } from './ActionButton';
import './ConfirmDialog.css';

export interface ConfirmDialogProps {
  open: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  variant?: 'danger' | 'warning' | 'info';
  loading?: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

const ICONS = {
  danger: AlertCircle,
  warning: AlertTriangle,
  info: Info,
};

const ICON_COLORS: Record<string, string> = {
  danger: 'var(--color-danger-500)',
  warning: 'var(--color-warning-500)',
  info: 'var(--color-info-500)',
};

const FOCUSABLE_SELECTOR = 'button:not([disabled]), a[href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';

export const ConfirmDialog: React.FC<ConfirmDialogProps> = ({
  open,
  title,
  message,
  confirmLabel = 'Xác nhận',
  cancelLabel = 'Hủy',
  variant = 'danger',
  loading = false,
  onConfirm,
  onCancel,
}) => {
  const dialogRef = useRef<HTMLDivElement>(null);
  const previousActiveElement = useRef<Element | null>(null);
  const Icon = ICONS[variant];

  useEffect(() => {
    if (open) {
      previousActiveElement.current = document.activeElement;
      const focusable = dialogRef.current?.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR);
      (focusable?.[0] ?? dialogRef.current)?.focus();
    }
  }, [open]);

  useEffect(() => {
    if (!open) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        onCancel();
        return;
      }

      if (e.key === 'Enter') {
        e.preventDefault();
        onConfirm();
        return;
      }

      if (e.key === 'Tab' && dialogRef.current) {
        const focusable = Array.from(dialogRef.current.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR));
        if (focusable.length === 0) return;

        const first = focusable[0];
        const last = focusable[focusable.length - 1];

        if (e.shiftKey && document.activeElement === first) {
          e.preventDefault();
          last.focus();
        } else if (!e.shiftKey && document.activeElement === last) {
          e.preventDefault();
          first.focus();
        }
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [open, onCancel, onConfirm]);

  useEffect(() => {
    if (open) return;
    const target = previousActiveElement.current;
    if (target && target instanceof HTMLElement && target.isConnected) {
      target.focus();
    }
    previousActiveElement.current = null;
  }, [open]);

  if (!open) return null;

  return (
    <div
      className="confirm-dialog-overlay"
      onClick={onCancel}
      role="presentation"
      aria-hidden="false"
    >
      <div
        ref={dialogRef}
        className="confirm-dialog"
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="confirm-dialog-title"
        aria-describedby="confirm-dialog-message"
        tabIndex={-1}
        onClick={(e) => e.stopPropagation()}
      >
        <div
          className="confirm-dialog__icon"
          style={{ color: ICON_COLORS[variant] }}
          aria-hidden="true"
        >
          <Icon size={40} />
        </div>

        <h2 id="confirm-dialog-title" className="confirm-dialog__title">
          {title}
        </h2>

        <p id="confirm-dialog-message" className="confirm-dialog__message">
          {message}
        </p>

        <div className="confirm-dialog__actions">
          <ActionButton
            variant="secondary"
            size="md"
            onClick={onCancel}
            disabled={loading}
          >
            {cancelLabel}
          </ActionButton>
          <ActionButton
            variant={variant === 'danger' ? 'danger' : 'primary'}
            size="md"
            loading={loading}
            onClick={onConfirm}
          >
            {confirmLabel}
          </ActionButton>
        </div>
      </div>
    </div>
  );
};

export default ConfirmDialog;
