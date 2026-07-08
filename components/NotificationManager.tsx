import React, { useEffect, useMemo, useState } from 'react';
import {
  Bell, Send, Search, Mail, Smartphone, MessageSquare,
} from 'lucide-react';
import { useDebounce } from '../hooks/useDebounce';
import {
  NotificationLog,
  NotificationChannel,
  NotificationStatus,
  NotificationLogFilters,
} from '../types/notification';
import {
  getNotificationLogs,
  sendInAppMessage,
  notificationChannelLabel,
  notificationStatusLabel,
  notificationStatusClass,
} from '../services/notificationService';
import { getAllTenants } from '../services/tenantService';
import { Tenant } from '../types/tenant';

const CHANNELS: NotificationChannel[] = ['in_app', 'email', 'sms'];
const STATUSES: NotificationStatus[] = ['pending', 'sent', 'delivered', 'read', 'failed'];
const PAGE_SIZE = 20;

const channelIcon = (channel: NotificationChannel) => {
  switch (channel) {
    case 'email': return <Mail className="w-4 h-4" />;
    case 'sms': return <Smartphone className="w-4 h-4" />;
    default: return <MessageSquare className="w-4 h-4" />;
  }
};

const formatDate = (d?: string) => {
  if (!d) return '-';
  return new Date(d).toLocaleString('vi-VN');
};

export default function NotificationManager() {
  const [logs, setLogs] = useState<NotificationLog[]>([]);
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [filters, setFilters] = useState<NotificationLogFilters>({});
  const [searchTerm, setSearchTerm] = useState('');
  const debouncedSearch = useDebounce(searchTerm, 250);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);

  const [showComposer, setShowComposer] = useState(false);
  const [tenantId, setTenantId] = useState('');
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [sending, setSending] = useState(false);

  const tenantMap = useMemo(() => {
    const map: Record<string, Tenant> = {};
    tenants.forEach(t => { map[t.id] = t; });
    return map;
  }, [tenants]);

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const [result, t] = await Promise.all([
        getNotificationLogs(
          { ...filters, searchTerm: debouncedSearch || undefined },
          { limit: PAGE_SIZE, offset: (page - 1) * PAGE_SIZE }
        ),
        getAllTenants(),
      ]);
      setLogs(result.data);
      setTotal(result.count);
      setTenants(t);
    } catch (err: any) {
      setError(err?.message || 'Không tải được nhật ký thông báo.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, [filters, debouncedSearch, page]);

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!tenantId.trim() || !title.trim() || !content.trim()) return;
    setSending(true);
    setError(null);
    try {
      await sendInAppMessage({ tenantId: tenantId.trim(), title: title.trim(), content: content.trim() });
      setTenantId('');
      setTitle('');
      setContent('');
      setShowComposer(false);
      setPage(1);
      await load();
    } catch (err: any) {
      setError(err?.message || 'Gửi tin nhắn thất bại.');
    } finally {
      setSending(false);
    }
  };

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="space-y-6">
      <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-50 rounded-lg">
              <Bell className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-gray-900">Nhật ký thông báo</h2>
              <p className="text-sm text-gray-500">Theo dõi mọi lần gửi và soạn tin nhắn in-app cho tenant.</p>
            </div>
          </div>
          <button
            onClick={() => setShowComposer(s => !s)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700"
          >
            <Send className="w-4 h-4" />
            Soạn tin nhắn
          </button>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-red-50 text-red-700 text-sm rounded-lg">
            {error}
          </div>
        )}

        {showComposer && (
          <form onSubmit={handleSend} className="mb-6 p-4 bg-gray-50 rounded-xl border border-gray-200 space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Cửa hàng nhận</label>
              <select
                value={tenantId}
                onChange={e => setTenantId(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              >
                <option value="">Chọn tenant</option>
                {tenants.map(t => (
                  <option key={t.id} value={t.id}>{t.name} ({t.subdomain})</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Tiêu đề</label>
              <input
                type="text"
                value={title}
                onChange={e => setTitle(e.target.value)}
                placeholder="Tiêu đề tin nhắn"
                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Nội dung</label>
              <textarea
                value={content}
                onChange={e => setContent(e.target.value)}
                placeholder="Nội dung tin nhắn..."
                rows={4}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                required
              />
            </div>
            <div className="flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setShowComposer(false)}
                className="px-4 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg text-sm"
              >
                Hủy
              </button>
              <button
                type="submit"
                disabled={sending}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700 disabled:opacity-60"
              >
                {sending ? 'Đang gửi...' : 'Gửi tin nhắn'}
              </button>
            </div>
          </form>
        )}

        <div className="flex flex-col sm:flex-row gap-3 mb-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={e => { setSearchTerm(e.target.value); setPage(1); }}
              placeholder="Tìm theo tiêu đề hoặc nội dung..."
              className="w-full pl-9 pr-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <select
            value={filters.channel || ''}
            onChange={e => { setFilters(f => ({ ...f, channel: e.target.value as NotificationChannel })); setPage(1); }}
            className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">Tất cả kênh</option>
            {CHANNELS.map(c => (
              <option key={c} value={c}>{notificationChannelLabel(c)}</option>
            ))}
          </select>
          <select
            value={filters.status || ''}
            onChange={e => { setFilters(f => ({ ...f, status: e.target.value as NotificationStatus })); setPage(1); }}
            className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">Tất cả trạng thái</option>
            {STATUSES.map(s => (
              <option key={s} value={s}>{notificationStatusLabel(s)}</option>
            ))}
          </select>
        </div>

        {loading ? (
          <p className="text-sm text-gray-500">Đang tải...</p>
        ) : logs.length === 0 ? (
          <p className="text-sm text-gray-500">Chưa có bản ghi thông báo nào.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-3 text-left font-medium text-gray-600">Thời gian</th>
                  <th className="px-4 py-3 text-left font-medium text-gray-600">Kênh</th>
                  <th className="px-4 py-3 text-left font-medium text-gray-600">Trạng thái</th>
                  <th className="px-4 py-3 text-left font-medium text-gray-600">Cửa hàng</th>
                  <th className="px-4 py-3 text-left font-medium text-gray-600">Tiêu đề</th>
                  <th className="px-4 py-3 text-left font-medium text-gray-600">Nội dung</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {logs.map(log => (
                  <tr key={log.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-gray-600 whitespace-nowrap">{formatDate(log.createdAt)}</td>
                    <td className="px-4 py-3">
                      <span className="inline-flex items-center gap-1.5 text-gray-700">
                        {channelIcon(log.channel)}
                        {notificationChannelLabel(log.channel)}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex px-2 py-0.5 text-xs font-medium rounded-full ${notificationStatusClass(log.status)}`}>
                        {notificationStatusLabel(log.status)}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-gray-700">
                      {tenantMap[log.tenantId]?.name || log.tenantId}
                    </td>
                    <td className="px-4 py-3 text-gray-900 font-medium max-w-xs truncate">{log.title}</td>
                    <td className="px-4 py-3 text-gray-600 max-w-md truncate">{log.content}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {totalPages > 1 && (
          <div className="flex items-center justify-between px-2 pt-4 border-t border-gray-100 mt-4">
            <p className="text-sm text-gray-600">Trang {page} / {totalPages} · {total} kết quả</p>
            <div className="flex gap-2">
              <button
                onClick={() => setPage(p => Math.max(1, p - 1))}
                disabled={page <= 1}
                className="px-3 py-1.5 text-sm rounded-lg border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
              >
                Trước
              </button>
              <button
                onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                disabled={page >= totalPages}
                className="px-3 py-1.5 text-sm rounded-lg border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
              >
                Sau
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
