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
} from '../services/tenantService';

describe('RLS tenant isolation', () => {
  beforeEach(() => {
    resetMockData();
  });

  it('cross-tenant query trả về 0 row', async () => {
    const ownerA = 'owner-a';
    const ownerB = 'owner-b';

    // Tenant A
    setCurrentUserId(ownerA);
    const tenantA = await createTenantWithAdmin({
      name: 'Tenant A',
      subdomain: 'tenant-a',
      plan: 'free',
    });

    // Thêm sản phẩm vào tenant A
    const product = { name: 'Sản phẩm A', code: 'P-A', tenant_id: tenantA.id };
    const insertA = await mockSupabase.from('products').insert(product).select().single();
    expect(insertA.error).toBeNull();

    // Query trong tenant A: thấy sản phẩm
    const queryA = await mockSupabase.from('products').select('*').eq('tenant_id', tenantA.id);
    expect(queryA.data).toHaveLength(1);

    // Chuyển sang tenant B (vẫn là owner A)
    const tenantB = await createTenantWithAdmin({
      name: 'Tenant B',
      subdomain: 'tenant-b',
      plan: 'free',
    });
    setCurrentTenantId(tenantB.id);

    // Cross-tenant query về tenant A trả về 0 row
    const crossQuery = await mockSupabase.from('products').select('*').eq('tenant_id', tenantA.id);
    expect(crossQuery.data).toHaveLength(0);
  });

  it('insert với tenant_id sai bị từ chối', async () => {
    const owner = 'owner-c';
    setCurrentUserId(owner);

    const tenant = await createTenantWithAdmin({
      name: 'Tenant C',
      subdomain: 'tenant-c',
      plan: 'free',
    });

    // Cố tình insert với tenant_id khác tenant hiện tại
    const wrongProduct = { name: 'Sản phẩm lạ', code: 'P-X', tenant_id: 'tenant-khac' };
    const { data, error } = await mockSupabase.from('products').insert(wrongProduct).select().single();
    expect(error).toMatchObject({ code: '42501' });
    expect(data).toBeNull();

    // Đảm bảo dữ liệu không được ghi
    const rows = await mockSupabase.from('products').select('*');
    expect(rows.data).toHaveLength(0);
  });

  it('membership query cross-tenant trả về 0 row', async () => {
    const owner = 'owner-d';
    const cashier = 'cashier-d';
    setCurrentUserId(owner);

    const tenantD = await createTenantWithAdmin({
      name: 'Tenant D',
      subdomain: 'tenant-d',
      plan: 'free',
    });
    await inviteMember(tenantD.id, cashier, 'cashier');

    // Tạo tenant E với owner khác
    setCurrentUserId('owner-e');
    const tenantE = await createTenantWithAdmin({
      name: 'Tenant E',
      subdomain: 'tenant-e',
      plan: 'free',
    });

    // Cashier của tenant D query memberships của tenant E: không thấy gì
    setCurrentUserId(cashier);
    setCurrentTenantId(tenantE.id);
    const crossMembership = await mockSupabase.from('tenant_memberships').select('*').eq('tenant_id', tenantE.id);
    expect(crossMembership.data).toHaveLength(0);
  });
});
