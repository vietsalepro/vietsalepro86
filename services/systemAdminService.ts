import { supabase } from '../lib/supabase';

export interface RateLimitLog {
  id: string;
  ipAddress: string;
  action: string;
  attemptCount: number;
  windowStart: string;
  createdAt: string;
}

export interface SystemAdmin {
  userId: string;
  email?: string;
  createdAt?: string;
}

const mapRateLimitLog = (row: any): RateLimitLog => ({
  id: row.id,
  ipAddress: row.ip_address,
  action: row.action,
  attemptCount: row.attempt_count,
  windowStart: row.window_start,
  createdAt: row.created_at,
});

const mapSystemAdmin = (row: any): SystemAdmin => ({
  userId: row.user_id,
  email: row.email,
  createdAt: row.created_at,
});

export async function getRateLimitLogs(options: { limit?: number; offset?: number } = {}): Promise<{
  data: RateLimitLog[];
  count: number;
}> {
  const { data, error } = await supabase.rpc('get_rate_limit_logs', {
    p_limit: options.limit ?? 50,
    p_offset: options.offset ?? 0,
  });
  if (error) throw error;
  return {
    data: (data?.data || []).map(mapRateLimitLog),
    count: data?.count ?? 0,
  };
}

export async function getSystemAdmins(): Promise<SystemAdmin[]> {
  const { data, error } = await supabase.rpc('get_system_admins');
  if (error) throw error;
  return (data || []).map(mapSystemAdmin);
}

export async function addSystemAdmin(userId: string): Promise<SystemAdmin> {
  const { data, error } = await supabase.rpc('add_system_admin', { p_user_id: userId });
  if (error) throw error;
  return mapSystemAdmin(data);
}

export async function removeSystemAdmin(userId: string): Promise<void> {
  const { error } = await supabase.rpc('remove_system_admin', { p_user_id: userId });
  if (error) throw error;
}
