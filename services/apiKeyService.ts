import { supabase } from '../lib/supabase';
import { TenantApiKey } from '../types/tenant';

const mapApiKeyFromDB = (row: any): TenantApiKey => ({
  id: row.id,
  tenantId: row.tenantId ?? row.tenant_id,
  name: row.name,
  apiKey: row.apiKey ?? row.api_key,
  apiKeyPreview: row.apiKeyPreview ?? row.api_key_preview,
  version: row.version,
  status: row.status,
  createdBy: row.createdBy ?? row.created_by,
  revokedAt: row.revokedAt ?? row.revoked_at,
  revokedBy: row.revokedBy ?? row.revoked_by,
  lastUsedAt: row.lastUsedAt ?? row.last_used_at,
  createdAt: row.createdAt ?? row.created_at,
  updatedAt: row.updatedAt ?? row.updated_at,
});

export async function getTenantApiKeys(tenantId: string): Promise<TenantApiKey[]> {
  const { data, error } = await supabase.rpc('list_tenant_api_keys', { p_tenant_id: tenantId });
  if (error) throw error;
  return (data || []).map(mapApiKeyFromDB);
}

export async function createTenantApiKey(
  tenantId: string,
  name: string,
  version = 1
): Promise<TenantApiKey> {
  const { data, error } = await supabase.rpc('create_tenant_api_key', {
    p_tenant_id: tenantId,
    p_name: name,
    p_version: version,
  });
  if (error) throw error;
  return mapApiKeyFromDB(data);
}

export async function revokeTenantApiKey(keyId: string): Promise<TenantApiKey> {
  const { data, error } = await supabase.rpc('revoke_tenant_api_key', { p_key_id: keyId });
  if (error) throw error;
  return mapApiKeyFromDB(data);
}
