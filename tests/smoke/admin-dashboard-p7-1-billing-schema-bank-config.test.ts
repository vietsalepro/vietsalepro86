import { describe, it, expect, vi, beforeEach } from 'vitest';
import { resetMockData, setCurrentUserId, setSystemAdmin } from '../mocks/supabase';

vi.mock('../../lib/supabase', async () => {
  const { mockSupabase } = await import('../mocks/supabase');
  return { supabase: mockSupabase };
});

import {
  getBankAccounts,
  createBankAccount,
  updateBankAccount,
  deleteBankAccount,
  getCompanyInfo,
  setCompanyInfo,
} from '../../services/bankAccountService';

// ponytail: smoke test P7.1 billing schema + bank/company config. Dùng mock in-memory để xác minh
// CRUD bank account và đọc/ghi thông tin công ty qua system_settings.

describe('smoke: admin dashboard P7.1 billing schema + bank/company config', () => {
  beforeEach(() => {
    resetMockData();
    setCurrentUserId('sys-admin');
    setSystemAdmin(true);
  });

  it('chỉ system admin mới CRUD tài khoản ngân hàng', async () => {
    setSystemAdmin(false);
    await expect(createBankAccount({
      accountName: 'A',
      accountNumber: '1',
      bankName: 'B',
      transferContent: 'C',
      isDefault: false,
      displayOrder: 0,
    })).rejects.toThrow();
  });

  it('CRUD tài khoản ngân hàng', async () => {
    const created = await createBankAccount({
      accountName: 'NGUYEN VAN A',
      accountNumber: '1234567890',
      bankName: 'Vietcombank',
      transferContent: 'Thanh toan hoa don',
      isDefault: true,
      displayOrder: 0,
    });
    expect(created.accountName).toBe('NGUYEN VAN A');
    expect(created.isDefault).toBe(true);

    let list = await getBankAccounts();
    expect(list.length).toBe(1);
    expect(list[0].bankName).toBe('Vietcombank');

    await updateBankAccount(created.id, { bankName: 'BIDV', accountNumber: '0987654321' });
    list = await getBankAccounts();
    expect(list[0].bankName).toBe('BIDV');
    expect(list[0].accountNumber).toBe('0987654321');
    expect(list[0].accountName).toBe('NGUYEN VAN A');

    await deleteBankAccount(created.id);
    list = await getBankAccounts();
    expect(list.length).toBe(0);
  });

  it('đọc/ghi thông tin công ty/thương hiệu/MST', async () => {
    const initial = await getCompanyInfo();
    expect(initial.companyName).toBe('');
    expect(initial.taxCode).toBe('');

    const info = {
      companyName: 'Công ty TNHH VietSale Pro',
      brandName: 'VietSale Pro',
      taxCode: '0123456789',
      address: 'TP. Hồ Chí Minh',
      phone: '0901234567',
      email: 'contact@vietsale.pro',
    };
    await setCompanyInfo(info);

    const stored = await getCompanyInfo();
    expect(stored).toEqual(info);
  });
});
