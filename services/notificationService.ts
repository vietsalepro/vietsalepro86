import { supabase } from '../lib/supabase';
import {
  NotificationLog,
  NotificationChannel,
  NotificationStatus,
  NotificationLogFilters,
  NotificationLogListResult,
  CreateInAppMessageInput,
} from '../types/notification';

const mapNotificationLogFromDB = (row: any): NotificationLog => ({
  id: row.id,
  tenantId: row.tenant_id,
  channel: row.channel,
  title: row.title,
  content: row.content,
  status: row.status,
  errorMessage: row.error_message,
  metadata: row.metadata ?? undefined,
  sentBy: row.sent_by,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
});

// --- admin: log viewer ---

export async function getNotificationLogs(
  filters: NotificationLogFilters = {},
  options: { limit?: number; offset?: number } = {}
): Promise<NotificationLogListResult> {
  const limit = options.limit ?? 50;
  const offset = options.offset ?? 0;

  let query = supabase
    .from('notification_logs')
    .select('*', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (filters.channel) {
    query = query.eq('channel', filters.channel);
  }
  if (filters.status) {
    query = query.eq('status', filters.status);
  }
  if (filters.tenantId) {
    query = query.eq('tenant_id', filters.tenantId);
  }
  if (filters.searchTerm) {
    query = query.or(`title.ilike.%${filters.searchTerm}%,content.ilike.%${filters.searchTerm}%`);
  }

  const { data, error, count } = await query;
  if (error) throw error;
  return {
    data: (data || []).map(mapNotificationLogFromDB),
    count: count ?? 0,
  };
}

// --- admin: message composer ---

export async function sendInAppMessage(input: CreateInAppMessageInput): Promise<NotificationLog> {
  const { data, error } = await supabase.rpc('send_in_app_message', {
    p_tenant_id: input.tenantId,
    p_title: input.title.trim(),
    p_content: input.content.trim(),
    p_metadata: input.metadata ?? null,
  });
  if (error) throw error;
  return mapNotificationLogFromDB(data);
}

// --- tenant-facing API ---

export async function getInAppMessagesForTenant(
  tenantId: string,
  options: { limit?: number; offset?: number } = {}
): Promise<NotificationLog[]> {
  const { data, error } = await supabase.rpc('get_in_app_messages_for_tenant', {
    p_tenant_id: tenantId,
    p_limit: options.limit ?? 50,
    p_offset: options.offset ?? 0,
  });
  if (error) throw error;
  return (data || []).map(mapNotificationLogFromDB);
}

export async function markInAppMessageRead(logId: string, tenantId: string): Promise<boolean> {
  const { data, error } = await supabase.rpc('mark_in_app_message_read', {
    p_log_id: logId,
    p_tenant_id: tenantId,
  });
  if (error) throw error;
  return !!data;
}

// --- helpers ---

export const notificationChannelLabel = (channel: NotificationChannel) => {
  switch (channel) {
    case 'in_app': return 'In-app';
    case 'email': return 'Email';
    case 'sms': return 'SMS';
    default: return channel;
  }
};

export const notificationStatusLabel = (status: NotificationStatus) => {
  switch (status) {
    case 'pending': return 'Đang chờ';
    case 'sent': return 'Đã gửi';
    case 'delivered': return 'Đã phân phối';
    case 'read': return 'Đã đọc';
    case 'failed': return 'Thất bại';
    default: return status;
  }
};

export const notificationStatusClass = (status: NotificationStatus) => {
  switch (status) {
    case 'read': return 'bg-green-100 text-green-700';
    case 'sent': return 'bg-blue-100 text-blue-700';
    case 'delivered': return 'bg-purple-100 text-purple-700';
    case 'failed': return 'bg-red-100 text-red-700';
    default: return 'bg-gray-100 text-gray-700';
  }
};
