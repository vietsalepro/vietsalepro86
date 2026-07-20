// ponytail: admin dashboard audit log queries against the dedicated audit_log table.
// Sub-Phase 5.2 adds tenant-management audit logging separate from app_audit_log.

import { supabase } from '../../lib/supabase';
import { AppError } from '../../utils/errors';

export type AdminAuditAction = 'INSERT' | 'UPDATE' | 'DELETE';

export interface AdminAuditLogEntry {
  id: string;
  tenantId: string | null;
  actorId: string | null;
  action: AdminAuditAction;
  entityType: string;
  entityId: string;
  oldData: any;
  newData: any;
  ipAddress: string | null;
  createdAt: string;
}

export interface AdminAuditLogFilter {
  tenantId?: string | null;
  actorId?: string | null;
  action?: AdminAuditAction | null;
  entityType?: string | null;
  entityId?: string | null;
  dateFrom?: string | null;
  dateTo?: string | null;
}

const mapAdminAuditLogFromDB = (row: any): AdminAuditLogEntry => ({
  id: row.id,
  tenantId: row.tenant_id,
  actorId: row.actor_id,
  action: row.action,
  entityType: row.entity_type,
  entityId: row.entity_id,
  oldData: row.old_data,
  newData: row.new_data,
  ipAddress: row.ip_address,
  createdAt: row.created_at,
});

// ponytail: cap export to avoid browser memory blow-up on huge audit tables.
// Ceiling: 10k rows; for larger exports add server-side streaming/Edge Function.
const MAX_EXPORT_ROWS = 10000;

export type AdminAuditExportFormat = 'csv' | 'json';

export interface AdminAuditExportOptions extends AdminAuditLogFilter {
  format: AdminAuditExportFormat;
}

export interface AdminAuditExportResult {
  blob: Blob;
  filename: string;
}

const CSV_HEADER_KEYS = [
  'id',
  'tenantId',
  'actorId',
  'action',
  'entityType',
  'entityId',
  'oldData',
  'newData',
  'ipAddress',
  'createdAt',
] as const;

const CSV_HEADER_LABELS = [
  'id',
  'tenant_id',
  'actor_id',
  'action',
  'entity_type',
  'entity_id',
  'old_data',
  'new_data',
  'ip_address',
  'created_at',
];

function escapeCsvCell(value: unknown): string {
  if (value === null || value === undefined) return '';
  const str = typeof value === 'object' ? JSON.stringify(value) : String(value);
  if (/[",\n\r]/.test(str)) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

function formatAuditLogsAsCsv(rows: AdminAuditLogEntry[]): string {
  const lines = [CSV_HEADER_LABELS.join(',')];
  for (const row of rows) {
    lines.push(CSV_HEADER_KEYS.map((key) => escapeCsvCell(row[key])).join(','));
  }
  return lines.join('\n');
}

export async function exportAuditLogs(
  options: AdminAuditExportOptions
): Promise<AdminAuditExportResult> {
  const { format, ...filter } = options;
  const { data } = await getAdminAuditLogs({ ...filter, limit: MAX_EXPORT_ROWS, offset: 0 });
  const dateSuffix = new Date().toISOString().slice(0, 10);

  if (format === 'csv') {
    return {
      blob: new Blob([formatAuditLogsAsCsv(data)], { type: 'text/csv;charset=utf-8;' }),
      filename: `audit-log-${dateSuffix}.csv`,
    };
  }

  return {
    blob: new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' }),
    filename: `audit-log-${dateSuffix}.json`,
  };
}

export async function getAdminAuditLogs(
  options: AdminAuditLogFilter & { limit?: number; offset?: number } = {}
): Promise<{ data: AdminAuditLogEntry[]; count: number | null }> {
  const limit = options.limit ?? 50;
  const offset = options.offset ?? 0;

  let dateTo: string | null = null;
  if (options.dateTo) {
    const end = new Date(options.dateTo);
    end.setHours(23, 59, 59, 999);
    dateTo = end.toISOString();
  }

  const { data, error } = await supabase.rpc('get_admin_audit_logs', {
    p_limit: limit,
    p_offset: offset,
    p_tenant_id: options.tenantId ?? null,
    p_actor_id: options.actorId ?? null,
    p_action: options.action ?? null,
    p_entity_type: options.entityType ?? null,
    p_entity_id: options.entityId ?? null,
    p_date_from: options.dateFrom ?? null,
    p_date_to: dateTo,
  });

  if (error) {
    throw new AppError(error.message || 'Lỗi đọc audit log', 'AUDIT_LOG_READ_ERROR', { originalError: error });
  }

  const rows = (data ?? []) as any[];
  const count = rows.length ? Number(rows[0].total_count) : 0;

  return {
    data: rows.map(mapAdminAuditLogFromDB),
    count,
  };
}

export type { AdminLoginAlert, AdminLoginHistoryEntry, AdminLoginHistoryFilter } from '../loginHistoryService';
export {
  getAdminLoginAlerts,
  getAdminLoginHistory,
  recordAdminLogin,
} from '../loginHistoryService';

export type { RateLimitLog } from '../systemAdminService';
export { getRateLimitLogs } from '../systemAdminService';
