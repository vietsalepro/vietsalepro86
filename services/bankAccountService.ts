import { supabase } from '../lib/supabase';
import { BankAccount, CompanyInfo } from '../types/billing';

export type { BankAccount, CompanyInfo } from '../types/billing';

const mapBankAccountFromDB = (row: any): BankAccount => ({
  id: row.id,
  accountName: row.account_name,
  accountNumber: row.account_number,
  bankName: row.bank_name,
  transferContent: row.transfer_content,
  isDefault: row.is_default ?? false,
  displayOrder: row.display_order ?? 0,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
});

const defaultCompanyInfo: CompanyInfo = {
  companyName: '',
  brandName: '',
  taxCode: '',
  address: '',
  phone: '',
  email: '',
};

export async function getBankAccounts(): Promise<BankAccount[]> {
  const { data, error } = await supabase
    .from('bank_accounts')
    .select('*')
    .order('display_order', { ascending: true });

  if (error) throw error;
  return (data || []).map(mapBankAccountFromDB);
}

export async function createBankAccount(
  input: Omit<BankAccount, 'id' | 'createdAt' | 'updatedAt'>
): Promise<BankAccount> {
  const { data, error } = await supabase
    .from('bank_accounts')
    .insert({
      account_name: input.accountName,
      account_number: input.accountNumber,
      bank_name: input.bankName,
      transfer_content: input.transferContent,
      is_default: input.isDefault,
      display_order: input.displayOrder,
    })
    .select()
    .single();

  if (error) throw error;
  return mapBankAccountFromDB(data);
}

export async function updateBankAccount(
  id: string,
  input: Partial<Omit<BankAccount, 'id' | 'createdAt' | 'updatedAt'>>
): Promise<BankAccount> {
  const update: Record<string, any> = {};
  if (input.accountName !== undefined) update.account_name = input.accountName;
  if (input.accountNumber !== undefined) update.account_number = input.accountNumber;
  if (input.bankName !== undefined) update.bank_name = input.bankName;
  if (input.transferContent !== undefined) update.transfer_content = input.transferContent;
  if (input.isDefault !== undefined) update.is_default = input.isDefault;
  if (input.displayOrder !== undefined) update.display_order = input.displayOrder;

  const { data, error } = await supabase
    .from('bank_accounts')
    .update(update)
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;
  return mapBankAccountFromDB(data);
}

export async function deleteBankAccount(id: string): Promise<void> {
  const { error } = await supabase.from('bank_accounts').delete().eq('id', id);
  if (error) throw error;
}

export async function getCompanyInfo(): Promise<CompanyInfo> {
  const { data, error } = await supabase
    .from('system_settings')
    .select('value')
    .eq('key', 'company_info')
    .single();

  if (error) {
    if (error.code === 'PGRST116') return defaultCompanyInfo;
    throw error;
  }

  const v = data?.value || {};
  return {
    companyName: v.companyName ?? '',
    brandName: v.brandName ?? '',
    taxCode: v.taxCode ?? '',
    address: v.address ?? '',
    phone: v.phone ?? '',
    email: v.email ?? '',
  };
}

export async function setCompanyInfo(info: CompanyInfo): Promise<CompanyInfo> {
  const { data: existing, error: selectError } = await supabase
    .from('system_settings')
    .select('key')
    .eq('key', 'company_info')
    .single();

  if (selectError && selectError.code !== 'PGRST116') throw selectError;

  if (existing) {
    const { error } = await supabase
      .from('system_settings')
      .update({ value: info })
      .eq('key', 'company_info');
    if (error) throw error;
  } else {
    const { error } = await supabase
      .from('system_settings')
      .insert({ key: 'company_info', value: info });
    if (error) throw error;
  }

  return info;
}
