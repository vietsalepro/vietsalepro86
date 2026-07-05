import { describe, it, expect, beforeEach, vi } from 'vitest';
import {
  resetMockData,
  setCurrentUserId,
  setCurrentTenantId,
  mockSupabase,
} from './mocks/supabase';

vi.mock('../lib/supabase', async () => {
  const { mockSupabase } = await import('./mocks/supabase');
  return { supabase: mockSupabase };
});

import {
  createTenantWithAdmin,
  inviteMember,
  getMembership,
  getTenantMembers,
  getTenantById,
  getCurrentUserTenants,
} from '../services/tenantService';

describe('tenant/auth/membership', () => {
  beforeEach(() => {
    resetMockData();
  });

  it('tạo tenant, user owner và membership admin', async () => {
    const ownerId = 'owner-001';
    setCurrentUserId(ownerId);

    const tenant = await createTenantWithAdmin({
      name: 'Cửa hàng A',
      subdomain: 'store-a',
      plan: 'free',
    });

    expect(tenant).toBeTruthy();
    expect(tenant.name).toBe('Cửa hàng A');
    expect(tenant.subdomain).toBe('store-a');
    expect(tenant.ownerId).toBe(ownerId);

    const members = await getTenantMembers(tenant.id);
    expect(members).toHaveLength(1);
    expect(members[0].userId).toBe(ownerId);
    expect(members[0].role).toBe('admin');

    const membership = await getMembership(tenant.id, ownerId);
    expect(membership).not.toBeNull();
    expect(membership?.role).toBe('admin');
  });

  it('invite member tạo membership cho user trong tenant', async () => {
    const ownerId = 'owner-002';
    const cashierId = 'cashier-002';
    setCurrentUserId(ownerId);

    const tenant = await createTenantWithAdmin({
      name: 'Cửa hàng B',
      subdomain: 'store-b',
      plan: 'free',
    });

    const invited = await inviteMember(tenant.id, cashierId, 'cashier');
    expect(invited.tenantId).toBe(tenant.id);
    expect(invited.userId).toBe(cashierId);
    expect(invited.role).toBe('cashier');

    const members = await getTenantMembers(tenant.id);
    expect(members).toHaveLength(2);

    const found = await getMembership(tenant.id, cashierId);
    expect(found).not.toBeNull();
    expect(found?.role).toBe('cashier');
  });

  it('getCurrentUserTenants chỉ trả về tenant mà user là member', async () => {
    const ownerId = 'owner-003';
    setCurrentUserId(ownerId);

    const tenant = await createTenantWithAdmin({
      name: 'Cửa hàng C',
      subdomain: 'store-c',
      plan: 'free',
    });

    // Đổi user khác: không thấy tenant trên.
    setCurrentUserId('stranger-003');
    const empty = await getCurrentUserTenants();
    expect(empty).toHaveLength(0);

    // Quay lại owner: thấy tenant.
    setCurrentUserId(ownerId);
    const tenants = await getCurrentUserTenants();
    expect(tenants).toHaveLength(1);
    expect(tenants[0].id).toBe(tenant.id);
  });

  it('getTenantById trả về null khi user không thuộc tenant', async () => {
    const ownerId = 'owner-004';
    setCurrentUserId(ownerId);

    const tenant = await createTenantWithAdmin({
      name: 'Cửa hàng D',
      subdomain: 'store-d',
      plan: 'free',
    });

    setCurrentUserId('stranger-004');
    const found = await getTenantById(tenant.id);
    expect(found).toBeNull();

    setCurrentUserId(ownerId);
    const found2 = await getTenantById(tenant.id);
    expect(found2).not.toBeNull();
    expect(found2?.id).toBe(tenant.id);
  });
});
