import { useEffect, useState } from 'react';
import { getTenantFeatureFlags } from '../services/tenantService';
import { TenantFeatureFlags, DEFAULT_TENANT_FEATURE_FLAGS } from '../types/tenant';

interface AdminFeatureFlags extends TenantFeatureFlags {
  gdprEnabled: boolean;
  auditRealtimeEnabled: boolean;
  advancedAnalyticsEnabled: boolean;
  impersonationEnabled: boolean;
  readReplicaQueueEnabled: boolean;
  isLoading: boolean;
}

export function useAdminFeatureFlags(tenantId: string | null | undefined): AdminFeatureFlags {
  const [flags, setFlags] = useState<TenantFeatureFlags>(DEFAULT_TENANT_FEATURE_FLAGS);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (!tenantId) {
      setFlags(DEFAULT_TENANT_FEATURE_FLAGS);
      return;
    }

    setIsLoading(true);
    let cancelled = false;

    getTenantFeatureFlags(tenantId)
      .then((next) => {
        if (!cancelled) setFlags(next);
      })
      .catch(() => {
        if (!cancelled) setFlags(DEFAULT_TENANT_FEATURE_FLAGS);
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false);
      });

    return () => { cancelled = true; };
  }, [tenantId]);

  return {
    ...flags,
    gdprEnabled: flags.adminGdprEnabled ?? false,
    auditRealtimeEnabled: flags.adminAuditRealtimeEnabled ?? false,
    advancedAnalyticsEnabled: flags.adminAdvancedAnalyticsEnabled ?? false,
    impersonationEnabled: flags.adminImpersonationEnabled ?? false,
    readReplicaQueueEnabled: flags.adminReadReplicaQueueEnabled ?? false,
    isLoading,
  };
}
