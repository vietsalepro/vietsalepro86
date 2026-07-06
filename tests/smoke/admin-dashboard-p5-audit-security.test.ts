import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  resetMockData,
  setCurrentUserId,
  setCurrentTenantId,
  setSystemAdmin,
  addMockRow,
} from '../mocks/supabase';

vi.mock('../../lib/supabase', async () => {
  const { mockSupabase } = await import('../mocks/supabase');
  return { supabase: mockSupabase };
});

import { getAuditLogs } from '../../services/auditService';
import {
  getRateLimitLogs,
  getSystemAdmins,
  addSystemAdmin,
  removeSystemAdmin,
} from '../../services/systemAdminService';

// ponytail: smoke test P5 audit & security. Dùng mock in-memory để xác minh
// filter audit log, rate limit logs, và system admin CRUD.

describe('smoke: admin dashboard P5 audit & security', () => {
  beforeEach(() => {
    resetMockData();
  });

  const seedAuditLogs = () => {
    const tenantA = 'tenant-a';
    const tenantB = 'tenant-b';
    addMockRow('app_audit_log', {
      tenant_id: tenantA,
      user_id: 'user-1',
      table_name: 'products',
      action: 'INSERT',
      record_id: 'rec-1',
      old_data: null,
      new_data: { name: 'Nước ngọt' },
      ip_address: '127.0.0.1',
      user_agent: 'Mozilla/5.0',
      created_at: '2026-07-05T10:00:00Z',
    });
    addMockRow('app_audit_log', {
      tenant_id: tenantA,
      user_id: 'user-1',
      table_name: 'products',
      action: 'UPDATE',
      record_id: 'rec-1',
      old_data: { name: 'Nước ngọt' },
      new_data: { name: 'Nước ngọt 2' },
      ip_address: '127.0.0.1',
      user_agent: 'Mozilla/5.0',
      created_at: '2026-07-06T10:00:00Z',
    });
    addMockRow('app_audit_log', {
      tenant_id: tenantB,
      user_id: 'user-2',
      table_name: 'orders',
      action: 'INSERT',
      record_id: 'rec-2',
      old_data: null,
      new_data: { total: 100000 },
      ip_address: '127.0.0.2',
      user_agent: 'Mozilla/5.0',
      created_at: '2026-07-06T12:00:00Z',
    });
    return { tenantA, tenantB };
  };

  it('system admin lọc audit log theo tenant, action và ngày', async () => {
    const { tenantA, tenantB } = seedAuditLogs();
    setCurrentUserId('sys-admin');
    setSystemAdmin(true);

    const all = await getAuditLogs({});
    expect(all.data.length).toBe(3);

    const tenantAOnly = await getAuditLogs({ tenantId: tenantA });
    expect(tenantAOnly.data.length).toBe(2);

    const updates = await getAuditLogs({ action: 'UPDATE' });
    expect(updates.data.length).toBe(1);
    expect(updates.data[0].tableName).toBe('products');

    const orders = await getAuditLogs({ tableName: 'orders' });
    expect(orders.data.length).toBe(1);
    expect(orders.data[0].tenantId).toBe(tenantB);

    const fromDate = await getAuditLogs({ dateFrom: '2026-07-06T00:00:00Z' });
    expect(fromDate.data.length).toBe(2);

    const toDate = await getAuditLogs({ dateTo: '2026-07-05' });
    expect(toDate.data.length).toBe(1);
  });

  it('tenant admin chỉ xem audit log của tenant hiện tại', async () => {
    const { tenantA } = seedAuditLogs();
    setCurrentUserId('user-1');
    setSystemAdmin(false);
    setCurrentTenantId(tenantA);

    const logs = await getAuditLogs({});
    expect(logs.data.length).toBe(2);
    expect(logs.data.every(l => l.tenantId === tenantA)).toBe(true);
  });

  it('rate limit logs chỉ system admin mới xem được', async () => {
    setCurrentUserId('sys-admin');
    setSystemAdmin(true);
    addMockRow('rate_limit_logs', {
      ip_address: '127.0.0.1',
      action: 'login',
      attempt_count: 5,
      window_start: '2026-07-06T10:00:00Z',
      created_at: '2026-07-06T10:00:00Z',
    });

    const res = await getRateLimitLogs({});
    expect(res.data.length).toBe(1);
    expect(res.data[0].action).toBe('login');

    setSystemAdmin(false);
    await expect(getRateLimitLogs({})).rejects.toThrow();
  });

  it('thêm và xóa system admin', async () => {
    setCurrentUserId('sys-admin');
    setSystemAdmin(true);
    addMockRow('users', { id: 'admin-2', email: 'admin-2@example.com' });

    await addSystemAdmin('admin-2');
    let list = await getSystemAdmins();
    expect(list.some(a => a.userId === 'admin-2')).toBe(true);

    await removeSystemAdmin('admin-2');
    list = await getSystemAdmins();
    expect(list.some(a => a.userId === 'admin-2')).toBe(false);
  });

  it('non-system admin không thêm/xem system admin', async () => {
    setCurrentUserId('user-1');
    setSystemAdmin(false);
    addMockRow('users', { id: 'admin-2', email: 'admin-2@example.com' });

    await expect(addSystemAdmin('admin-2')).rejects.toThrow();
    await expect(getSystemAdmins()).rejects.toThrow();
  });
});
