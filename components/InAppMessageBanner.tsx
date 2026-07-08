import React, { useEffect, useState } from 'react';
import { Bell, X } from 'lucide-react';
import { useTenant } from '../contexts/TenantContext';
import { NotificationLog } from '../types/notification';
import { getInAppMessagesForTenant, markInAppMessageRead } from '../services/notificationService';

export default function InAppMessageBanner() {
  const { tenant } = useTenant();
  const [messages, setMessages] = useState<NotificationLog[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!tenant?.id) {
      setMessages([]);
      return;
    }
    let cancelled = false;
    const load = async () => {
      setLoading(true);
      try {
        const data = await getInAppMessagesForTenant(tenant.id, { limit: 10 });
        if (!cancelled) setMessages(data.filter(m => m.status !== 'read'));
      } catch {
        if (!cancelled) setMessages([]);
      } finally {
        if (!cancelled) setLoading(false);
      }
    };
    load();
    return () => { cancelled = true; };
  }, [tenant?.id]);

  const handleDismiss = async (m: NotificationLog) => {
    if (!tenant?.id) return;
    try {
      await markInAppMessageRead(m.id, tenant.id);
      setMessages(prev => prev.filter(x => x.id !== m.id));
    } catch {
      // best-effort
    }
  };

  if (loading || messages.length === 0) return null;

  return (
    <div className="space-y-2 pb-4">
      {messages.map(m => (
        <div
          key={m.id}
          className="bg-amber-50 border border-amber-200 text-amber-900 rounded-lg p-4 shadow-sm"
        >
          <div className="flex items-start gap-3">
            <Bell className="w-5 h-5 mt-0.5 flex-shrink-0 text-amber-600" />
            <div className="flex-1 min-w-0">
              <h4 className="font-semibold text-sm">{m.title}</h4>
              <p className="text-sm text-amber-800 whitespace-pre-wrap">{m.content}</p>
            </div>
            <button
              onClick={() => handleDismiss(m)}
              className="p-1 text-amber-700 hover:text-amber-900 hover:bg-amber-100 rounded-lg flex-shrink-0"
              aria-label="Đóng tin nhắn"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}
