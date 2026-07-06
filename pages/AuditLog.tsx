import React, { useEffect, useState } from 'react';
import { usePermissions } from '../hooks/usePermissions';
import { getAuditLogs, AuditLogEntry, AuditAction } from '../services/auditService';
import { Loader2, ShieldAlert, ChevronLeft, ChevronRight } from 'lucide-react';

const PAGE_SIZE = 50;

const ACTIONS: AuditAction[] = ['INSERT', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'EXPORT'];

const actionLabel: Record<string, string> = {
  INSERT: 'Thêm',
  UPDATE: 'Cập nhật',
  DELETE: 'Xoá',
  LOGIN: 'Đăng nhập',
  LOGOUT: 'Đăng xuất',
  EXPORT: 'Xuất dữ liệu',
};

const actionClass: Record<string, string> = {
  INSERT: 'bg-green-100 text-green-700',
  UPDATE: 'bg-blue-100 text-blue-700',
  DELETE: 'bg-red-100 text-red-700',
  LOGIN: 'bg-purple-100 text-purple-700',
  LOGOUT: 'bg-gray-100 text-gray-700',
  EXPORT: 'bg-yellow-100 text-yellow-700',
};

const formatDate = (value: string) =>
  new Intl.DateTimeFormat('vi-VN', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  }).format(new Date(value));

const DataPreview: React.FC<{ data: any }> = ({ data }) => {
  const [expanded, setExpanded] = useState(false);
  if (data === null || data === undefined) return <span className="text-gray-400 italic">—</span>;

  const text = JSON.stringify(data, null, 2);
  const short = text.length > 120 ? text.slice(0, 120) + '…' : text;

  return (
    <div className="max-w-xs">
      <pre className="text-xs whitespace-pre-wrap break-all text-gray-700 bg-gray-50 rounded p-1">
        {expanded ? text : short}
      </pre>
      {text.length > 120 && (
        <button
          onClick={() => setExpanded(prev => !prev)}
          className="text-xs text-blue-600 hover:text-blue-800 mt-1"
        >
          {expanded ? 'Thu gọn' : 'Mở rộng'}
        </button>
      )}
    </div>
  );
};

interface AuditLogProps {
  systemAdmin?: boolean;
  tenants?: { id: string; name: string }[];
}

export const AuditLog: React.FC<AuditLogProps> = ({ systemAdmin, tenants }) => {
  const permissions = usePermissions();
  const [logs, setLogs] = useState<AuditLogEntry[]>([]);
  const [count, setCount] = useState<number | null>(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [error, setError] = useState<string | null>(null);
  const [filters, setFilters] = useState({
    tenantId: '',
    userId: '',
    action: '' as AuditAction | '',
    tableName: '',
    dateFrom: '',
    dateTo: '',
  });

  const totalPages = Math.max(1, Math.ceil((count || 0) / PAGE_SIZE));

  const fetchLogs = async (currentPage: number) => {
    setLoading(true);
    setError(null);
    try {
      const offset = (currentPage - 1) * PAGE_SIZE;
      const result = await getAuditLogs({
        limit: PAGE_SIZE,
        offset,
        tenantId: systemAdmin ? filters.tenantId || null : null,
        userId: filters.userId || null,
        action: filters.action || null,
        tableName: filters.tableName || null,
        dateFrom: filters.dateFrom || null,
        dateTo: filters.dateTo || null,
      });
      setLogs(result.data);
      setCount(result.count);
    } catch (err: any) {
      setError(err?.message || 'Không thể tải nhật ký hoạt động.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    setPage(1);
  }, [filters.tenantId, filters.userId, filters.action, filters.tableName, filters.dateFrom, filters.dateTo]);

  useEffect(() => {
    fetchLogs(page);
    // ponytail: eslint exhaustive-deps không được bật trong tsc-only lint; deps giữ ở mức tối thiểu.
  }, [page, filters]);

  if (!systemAdmin && !permissions.canViewAuditLogs) {
    return (
      <div className="flex min-h-[60vh] items-center justify-center bg-gray-50 p-6">
        <div className="text-center space-y-3">
          <ShieldAlert className="w-12 h-12 text-red-500 mx-auto" />
          <h2 className="text-lg font-semibold text-gray-900">Không có quyền truy cập</h2>
          <p className="text-gray-600">Chỉ quản trị viên mới có thể xem nhật ký hoạt động.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="p-4 md:p-6 space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-gray-900">Nhật ký hoạt động</h1>
          <p className="text-sm text-gray-600">Ghi lại các thao tác quan trọng trong hệ thống.</p>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 text-red-700 p-4 rounded-lg border border-red-100">
          {error}
        </div>
      )}

      {/* Filters */}
      <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
        {systemAdmin && (
          <div>
            <label className="block text-xs font-medium text-gray-700 mb-1">Cửa hàng</label>
            {tenants && tenants.length > 0 ? (
              <select
                value={filters.tenantId}
                onChange={(e) => setFilters({ ...filters, tenantId: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Tất cả</option>
                {tenants.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
              </select>
            ) : (
              <input
                type="text"
                value={filters.tenantId}
                onChange={(e) => setFilters({ ...filters, tenantId: e.target.value })}
                placeholder="ID cửa hàng"
                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            )}
          </div>
        )}
        <div>
          <label className="block text-xs font-medium text-gray-700 mb-1">User ID</label>
          <input
            type="text"
            value={filters.userId}
            onChange={(e) => setFilters({ ...filters, userId: e.target.value })}
            placeholder="User ID"
            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <div>
          <label className="block text-xs font-medium text-gray-700 mb-1">Hành động</label>
          <select
            value={filters.action}
            onChange={(e) => setFilters({ ...filters, action: e.target.value as AuditAction | '' })}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">Tất cả</option>
            {ACTIONS.map(a => <option key={a} value={a}>{actionLabel[a]}</option>)}
          </select>
        </div>
        <div>
          <label className="block text-xs font-medium text-gray-700 mb-1">Bảng</label>
          <input
            type="text"
            value={filters.tableName}
            onChange={(e) => setFilters({ ...filters, tableName: e.target.value })}
            placeholder="Tên bảng"
            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <div>
          <label className="block text-xs font-medium text-gray-700 mb-1">Từ ngày</label>
          <input
            type="date"
            value={filters.dateFrom}
            onChange={(e) => setFilters({ ...filters, dateFrom: e.target.value })}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <div>
          <label className="block text-xs font-medium text-gray-700 mb-1">Đến ngày</label>
          <input
            type="date"
            value={filters.dateTo}
            onChange={(e) => setFilters({ ...filters, dateTo: e.target.value })}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        {loading && logs.length === 0 && (
          <div className="flex items-center justify-center p-12">
            <Loader2 className="w-6 h-6 animate-spin text-blue-600 mr-2" />
            <span className="text-gray-600">Đang tải…</span>
          </div>
        )}

        {!loading && logs.length === 0 && !error && (
          <div className="p-8 text-center text-gray-500">Không có bản ghi nào.</div>
        )}

        {(logs.length > 0 || loading) && (
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead className="bg-gray-50 text-gray-700">
                <tr>
                  <th className="px-4 py-3 text-left font-medium">Thời gian</th>
                  <th className="px-4 py-3 text-left font-medium">Hành động</th>
                  <th className="px-4 py-3 text-left font-medium">Bảng</th>
                  <th className="px-4 py-3 text-left font-medium">Bản ghi</th>
                  {systemAdmin && <th className="px-4 py-3 text-left font-medium">Cửa hàng</th>}
                  <th className="px-4 py-3 text-left font-medium">Dữ liệu cũ</th>
                  <th className="px-4 py-3 text-left font-medium">Dữ liệu mới</th>
                  <th className="px-4 py-3 text-left font-medium">IP / User-Agent</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {logs.map(log => (
                  <tr key={log.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 whitespace-nowrap text-gray-700">
                      {formatDate(log.createdAt)}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap">
                      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${actionClass[log.action] || 'bg-gray-100 text-gray-700'}`}>
                        {actionLabel[log.action] || log.action}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-gray-700">{log.tableName}</td>
                    <td className="px-4 py-3 text-gray-700 max-w-[160px] truncate" title={log.recordId ?? undefined}>
                      {log.recordId ?? <span className="text-gray-400">—</span>}
                    </td>
                    {systemAdmin && (
                      <td className="px-4 py-3 text-gray-700 max-w-[160px] truncate" title={log.tenantId ?? undefined}>
                        {log.tenantId ?? <span className="text-gray-400">—</span>}
                      </td>
                    )}
                    <td className="px-4 py-3 align-top">
                      <DataPreview data={log.oldData} />
                    </td>
                    <td className="px-4 py-3 align-top">
                      <DataPreview data={log.newData} />
                    </td>
                    <td className="px-4 py-3 text-gray-600">
                      <div className="max-w-[200px] truncate" title={log.userAgent ?? undefined}>
                        {log.ipAddress ?? <span className="text-gray-400">—</span>}
                      </div>
                      {log.userAgent && (
                        <div className="text-xs text-gray-400 max-w-[200px] truncate" title={log.userAgent}>
                          {log.userAgent}
                        </div>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <span className="text-sm text-gray-600">
            {count ?? 0} bản ghi · Trang {page}/{totalPages}
          </span>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setPage(p => Math.max(1, p - 1))}
              disabled={page === 1 || loading}
              className="p-2 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50"
            >
              <ChevronLeft size={16} />
            </button>
            <button
              onClick={() => setPage(p => Math.min(totalPages, p + 1))}
              disabled={page === totalPages || loading}
              className="p-2 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50"
            >
              <ChevronRight size={16} />
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default AuditLog;
