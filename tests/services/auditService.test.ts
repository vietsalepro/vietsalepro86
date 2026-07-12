import { describe, it, expect, vi, beforeEach } from 'vitest';
import { writeAuditLog } from '../../services/auditService';

vi.mock('../../lib/supabase', async () => {
  const { mockSupabase } = await import('../mocks/supabase');
  return {
    supabase: mockSupabase,
    getCurrentTenantId: vi.fn(() => null),
  };
});

describe('auditService guard', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('does not invoke audit-log edge function when tenantId is null', async () => {
    const { supabase } = await import('../../lib/supabase');

    await writeAuditLog('LOGIN', 'auth', { recordId: 'u1' });

    expect(supabase.functions.invoke).not.toHaveBeenCalled();
  });
});
