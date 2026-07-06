import React from 'react';
import { AlertTriangle } from 'lucide-react';
import { useTenant } from '../hooks/useTenant';

export const ReadOnlyBanner: React.FC = () => {
  const { isReadOnly } = useTenant();
  if (!isReadOnly) return null;

  return (
    <div className="bg-amber-50 border-b border-amber-200 px-4 py-2">
      <div className="max-w-7xl mx-auto flex items-center gap-2 text-amber-800 text-sm">
        <AlertTriangle className="w-4 h-4 shrink-0" />
        <span className="font-medium">Tài khoản hết hạn — vui lòng thanh toán để tiếp tục.</span>
      </div>
    </div>
  );
};

export default ReadOnlyBanner;
