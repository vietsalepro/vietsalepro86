// ============================================================
// NOTIFICATION LOG TYPES — P12.3
// ============================================================

export type NotificationChannel = 'in_app' | 'email' | 'sms';
export type NotificationStatus = 'pending' | 'sent' | 'delivered' | 'read' | 'failed';

export interface NotificationLog {
  id: string;
  tenantId: string;
  channel: NotificationChannel;
  title: string;
  content: string;
  status: NotificationStatus;
  errorMessage?: string;
  metadata?: Record<string, any>;
  sentBy?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface CreateInAppMessageInput {
  tenantId: string;
  title: string;
  content: string;
  metadata?: Record<string, any>;
}

export interface NotificationLogFilters {
  channel?: NotificationChannel | '';
  status?: NotificationStatus | '';
  searchTerm?: string;
  tenantId?: string;
}

export interface NotificationLogListResult {
  data: NotificationLog[];
  count: number;
}
