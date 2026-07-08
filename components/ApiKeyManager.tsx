import React, { useEffect, useState } from 'react';
import { Key, Plus, RefreshCw, Trash2, Copy, Check } from 'lucide-react';
import { Tenant, TenantApiKey } from '../types/tenant';
import { getAllTenants } from '../services/tenantService';
import { createTenantApiKey, getTenantApiKeys, revokeTenantApiKey } from '../services/apiKeyService';

const statusLabel = (status: TenantApiKey['status']) => {
  switch (status) {
    case 'active': return 'Đang hoạt động';
    case 'revoked': return 'Đã thu hồi';
    default: return status;
  }
};

const statusClass = (status: TenantApiKey['status']) => {
  switch (status) {
    case 'active': return 'bg-green-100 text-green-700';
    case 'revoked': return 'bg-gray-200 text-gray-600';
    default: return 'bg-gray-100 text-gray-700';
  }
};

function formatDateTime(iso?: string): string {
  if (!iso) return '-';
  return new Date(iso).toLocaleString('vi-VN');
}

export default function ApiKeyManager() {
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [tenantsLoading, setTenantsLoading] = useState(false);
  const [tenantId, setTenantId] = useState<string>('');

  const [keys, setKeys] = useState<TenantApiKey[]>([]);
  const [keysLoading, setKeysLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [name, setName] = useState('');
  const [version, setVersion] = useState(1);
  const [submitting, setSubmitting] = useState(false);

  const [newKey, setNewKey] = useState<TenantApiKey | null>(null);
  const [copied, setCopied] = useState(false);

  const loadTenants = async () => {
    setTenantsLoading(true);
    try {
      const data = await getAllTenants();
      setTenants(data);
    } catch (err: any) {
      setError(err?.message || 'Không thể tải danh sách cửa hàng.');
    } finally {
      setTenantsLoading(false);
    }
  };

  const loadKeys = async (id: string) => {
    if (!id) {
      setKeys([]);
      return;
    }
    setKeysLoading(true);
    setError(null);
    try {
      const data = await getTenantApiKeys(id);
      setKeys(data);
    } catch (err: any) {
      setError(err?.message || 'Không thể tải danh sách API key.');
    } finally {
      setKeysLoading(false);
    }
  };

  useEffect(() => {
    loadTenants();
  }, []);

  useEffect(() => {
    loadKeys(tenantId);
  }, [tenantId]);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!tenantId) {
      setError('Vui lòng chọn cửa hàng.');
      return;
    }
    if (!name.trim()) {
      setError('Vui lòng nhập tên API key.');
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const key = await createTenantApiKey(tenantId, name.trim(), version || 1);
      setNewKey(key);
      setName('');
      setVersion(1);
      await loadKeys(tenantId);
    } catch (err: any) {
      setError(err?.message || 'Tạo API key thất bại.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleRevoke = async (keyId: string) => {
    if (!window.confirm('Thu hồi API key này? Hành động này không thể hoàn tác.')) return;
    setError(null);
    try {
      await revokeTenantApiKey(keyId);
      await loadKeys(tenantId);
    } catch (err: any) {
      setError(err?.message || 'Thu hồi API key thất bại.');
    }
  };

  const copyKey = async () => {
    if (!newKey?.apiKey) return;
    try {
      await navigator.clipboard.writeText(newKey.apiKey);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      setError('Không thể sao chép key.');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-gray-800">API Keys</h2>
        <button
          onClick={() => loadKeys(tenantId)}
          disabled={keysLoading || tenantsLoading}
          className="inline-flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 disabled:opacity-50"
        >
          <RefreshCw className={`w-4 h-4 ${keysLoading || tenantsLoading ? 'animate-spin' : ''}`} />
          Làm mới
        </button>
      </div>

      {error && (
        <div className="bg-red-50 text-red-700 p-4 rounded-lg border border-red-100">
          {error}
        </div>
      )}

      <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100">
        <label className="block text-sm font-medium text-gray-700 mb-1">Chọn cửa hàng</label>
        <select
          value={tenantId}
          onChange={(e) => setTenantId(e.target.value)}
          disabled={tenantsLoading}
          className="w-full md:w-1/2 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="">-- Chọn cửa hàng --</option>
          {tenants.map((t) => (
            <option key={t.id} value={t.id}>{t.name} ({t.subdomain})</option>
          ))}
        </select>
      </div>

      {tenantId && (
        <form onSubmit={handleCreate} className="bg-white p-4 rounded-xl shadow-sm border border-gray-100">
          <h3 className="text-sm font-semibold text-gray-700 mb-3">Tạo API key mới</h3>
          <div className="flex flex-col md:flex-row gap-3 items-end">
            <div className="flex-1 w-full">
              <label className="block text-xs font-medium text-gray-600 mb-1">Tên key</label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="ví dụ: Production integration"
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div className="w-full md:w-32">
              <label className="block text-xs font-medium text-gray-600 mb-1">Phiên bản API</label>
              <input
                type="number"
                min={1}
                value={version}
                onChange={(e) => setVersion(parseInt(e.target.value || '1', 10))}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <button
              type="submit"
              disabled={submitting}
              className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-60"
            >
              <Plus className="w-4 h-4" />
              {submitting ? 'Đang tạo...' : 'Tạo API key'}
            </button>
          </div>
        </form>
      )}

      <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
        <h3 className="text-sm font-semibold text-gray-700 mb-4">Danh sách API key</h3>
        {keysLoading ? (
          <p className="text-gray-600">Đang tải...</p>
        ) : keys.length === 0 ? (
          <p className="text-sm text-gray-500">
            {tenantId ? 'Chưa có API key nào.' : 'Vui lòng chọn cửa hàng.'}
          </p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-gray-500 border-b border-gray-100">
                  <th className="pb-2 font-medium">Tên</th>
                  <th className="pb-2 font-medium">Key</th>
                  <th className="pb-2 font-medium">Phiên bản</th>
                  <th className="pb-2 font-medium">Trạng thái</th>
                  <th className="pb-2 font-medium">Lần dùng cuối</th>
                  <th className="pb-2 font-medium">Ngày tạo</th>
                  <th className="pb-2 font-medium text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {keys.map((k) => (
                  <tr key={k.id} className="border-b border-gray-50 last:border-0">
                    <td className="py-3 font-medium text-gray-700">{k.name}</td>
                    <td className="py-3 font-mono text-gray-600">
                      {k.apiKeyPreview ? `••••••${k.apiKeyPreview}` : '••••••••'}
                    </td>
                    <td className="py-3 text-gray-600">{k.version}</td>
                    <td className="py-3">
                      <span className={`inline-flex px-2 py-0.5 text-xs font-medium rounded-full ${statusClass(k.status)}`}>
                        {statusLabel(k.status)}
                      </span>
                    </td>
                    <td className="py-3 text-gray-600">{formatDateTime(k.lastUsedAt)}</td>
                    <td className="py-3 text-gray-600">{formatDateTime(k.createdAt)}</td>
                    <td className="py-3 text-right">
                      {k.status === 'active' && (
                        <button
                          onClick={() => handleRevoke(k.id)}
                          className="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium text-red-600 bg-red-50 rounded hover:bg-red-100"
                        >
                          <Trash2 className="w-3 h-3" />
                          Thu hồi
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {newKey && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-lg max-w-lg w-full p-6 space-y-4">
            <div className="flex items-center gap-2 text-green-600">
              <Key className="w-5 h-5" />
              <h3 className="font-semibold">API key đã được tạo</h3>
            </div>
            <p className="text-sm text-gray-600">
              Sao chép key ngay — đây là lần duy nhất hệ thống hiển thị key đầy đủ.
            </p>
            <div className="flex items-center gap-2 p-3 bg-gray-50 rounded-lg border border-gray-200">
              <code className="flex-1 font-mono text-sm break-all">{newKey.apiKey}</code>
              <button
                onClick={copyKey}
                className="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-blue-600 bg-blue-50 rounded hover:bg-blue-100"
              >
                {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                {copied ? 'Đã copy' : 'Copy'}
              </button>
            </div>
            <div className="flex justify-end">
              <button
                onClick={() => setNewKey(null)}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                Đóng
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
