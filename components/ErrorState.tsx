/**
 * ═══════════════════════════════════════════════════════════════
 *  ERROR STATE COMPONENT — Sprint_05
 *  Source: MASTER_STATE_STANDARD_V1.md (Section XIX-XXI)
 *  ═══════════════════════════════════════════════════════════════
 *
 *  Purpose:
 *    Display error state with icon, message, and optional retry action.
 *
 *  Design Tokens:
 *    All values use var(--color-*), var(--space-*), var(--radius-*),
 *    var(--text-*), var(--font-*) — no hardcoded values.
 *
 *  Accessibility:
 *    - role="alert" for live region announcements
 *    - Keyboard accessible retry button (via ActionButton)
 */

import React from 'react';
import { AlertCircle } from 'lucide-react';
import { ActionButton } from './ActionButton';
import './ErrorState.css';

/* ─── Types ──────────────────────────────────────────── */

export interface ErrorStateProps {
  /** Title text (defaults to "Error") */
  title?: string;
  /** Error message describing what went wrong */
  message: string;
  /** Label for the retry button */
  retryLabel?: string;
  /** Callback fired when retry is clicked */
  onRetry?: () => void;
  /** Additional class names for custom styling */
  className?: string;
  /** Compact variant for smaller spaces */
  compact?: boolean;
}

/* ─── Component ──────────────────────────────────────── */

export const ErrorState: React.FC<ErrorStateProps> = ({
  title = 'Error',
  message,
  retryLabel = 'Try Again',
  onRetry,
  className,
  compact = false,
}) => {
  const containerClass = [
    'error-state',
    compact ? 'error-state--compact' : '',
    className || '',
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <div
      className={containerClass}
      role="alert"
      aria-live="assertive"
    >
      <div className="error-state__icon" aria-hidden="true">
        <AlertCircle size={48} />
      </div>
      <h3 className="error-state__title">{title}</h3>
      <p className="error-state__message">{message}</p>
      {onRetry && (
        <div className="error-state__action">
          <ActionButton
            variant="primary"
            size="md"
            onClick={onRetry}
            aria-label={retryLabel}
          >
            {retryLabel}
          </ActionButton>
        </div>
      )}
    </div>
  );
};

export default ErrorState;