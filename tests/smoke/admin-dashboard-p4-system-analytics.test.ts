import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  resetMockData,
  setCurrentUserId,
  setSystemAdmin,
  addMockRow,
  getMockRows,
} from '../mocks/supabase';

vi.mock('../../lib/supabase', async () => {
  const { mockSupabase } = await import('../mocks/supabase');
  return { supabase: mockSupabase };
});

import {
  createTenantWithAdmin,
  getSystemOverview,
  getTopTenants,
  getTenantGrowth,
} from '../../services/tenantService';

// ponytail: smoke test P4 system analytics. Dùng mock in-memory để xác minh
// system overview, top tenants, tenant growth và phân quyền system admin.

describe('smoke: admin dashboard P4 system analytics', () => {
  beforeEach(() => {
    resetMockData();
  });

  const seedTenant = async (name: string, subdomain: string, plan: 'free' | 'vip' = 'free') => {
    setCurrentUserId('sys-admin');
    setSystemAdmin(true);
    return createTenantWithAdmin({ name, subdomain, plan });
  };

  it('get_system_overview trả về đúng tổng quan', async () => {
    await seedTenant('P4 Store A', 'p4-store-a');
    await seedTenant('P4 Store B', 'p4-store-b', 'vip');

    const overview = await getSystemOverview();
    expect(overview.totalTenants).toBe(2);
    expect(overview.activeTenants).toBe(2);
    expect(overview.vipTenants).toBe(1);
    expect(overview.newThisMonth).toBe(2);
  });

  it('get_system_overview phát hiện tenant sắp hết hạn', async () => {
    const tenant = await seedTenant('P4 Expiring', 'p4-expiring');
    const sub = getMockRows('tenant_subscriptions').find(s => s.tenant_id === tenant.id);
    if (sub) sub.expires_at = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString();

    const overview = await getSystemOverview();
    expect(overview.expiringSoon).toBe(1);
    expect(overview.expiringTenants.length).toBe(1);
    expect(overview.expiringTenants[0].daysRemaining).toBeLessThanOrEqual(2);
  });

  it('get_system_overview phát hiện tenant gần giới hạn', async () => {
    const tenant = await seedTenant('P4 Near Limit', 'p4-near-limit');
    const sub = getMockRows('tenant_subscriptions').find(s => s.tenant_id === tenant.id);
    if (sub) sub.max_products = 10;
    for (let i = 0; i < 9; i++) {
      addMockRow('products', { name: `P${i}`, code: `P${i}`, tenant_id: tenant.id });
    }

    const overview = await getSystemOverview();
    expect(overview.nearLimit).toBe(1);
    expect(overview.nearLimitTenants.length).toBe(1);
    expect(overview.nearLimitTenants[0].productPercent).toBeGreaterThanOrEqual(80);
  });

  it('get_top_tenants sắp xếp theo đơn hàng tháng', async () => {
    const a = await seedTenant('P4 Top A', 'p4-top-a');
    const b = await seedTenant('P4 Top B', 'p4-top-b');
    const subA = getMockRows('tenant_subscriptions').find(s => s.tenant_id === a.id);
    const subB = getMockRows('tenant_subscriptions').find(s => s.tenant_id === b.id);
    if (subA) subA.current_month_orders = 100;
    if (subB) subB.current_month_orders = 50;

    const top = await getTopTenants({ limit: 2 });
    expect(top.data.length).toBe(2);
    expect(top.data[0].id).toBe(a.id);
    expect(top.data[0].ordersThisMonth).toBe(100);
    expect(top.data[1].ordersThisMonth).toBe(50);
  });

  it('get_tenant_growth trả về đủ số tháng', async () => {
    await seedTenant('P4 Growth', 'p4-growth');
    const growth = await getTenantGrowth({ months: 6 });
    expect(growth.length).toBe(6);
    const currentMonth = new Date().toISOString().slice(0, 7);
    const currentPoint = growth.find(g => g.month === currentMonth);
    expect(currentPoint?.count).toBe(1);
  });

  it('non-system admin bị từ chối xem tổng quan', async () => {
    await seedTenant('P4 Store', 'p4-store');
    setSystemAdmin(false);
    await expect(getSystemOverview()).rejects.toThrow();
  });
});
