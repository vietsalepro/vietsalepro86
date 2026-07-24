import { describe, it, expect } from 'vitest';
import { readFileSync } from 'fs';
import { resolve } from 'path';

/**
 * Wave-03 Phase 5.1 Step 8 — delete idempotency regression.
 *
 * Confirms the canonical delete pipeline has a unique request_id key, idempotency
 * guards in the RPC, and that the client/edge paths propagate the request id.
 */

const repoRoot = resolve(__dirname, '../..');
const migration = readFileSync(
  resolve(repoRoot, 'supabase/migrations/20260725000000_create_delete_state_tables.sql'),
  'utf8'
);
const rpcMigration = readFileSync(
  resolve(repoRoot, 'supabase/migrations/20260725000001_create_rpc_delete_tenant_canonical.sql'),
  'utf8'
);
const tenantService = readFileSync(resolve(repoRoot, 'services/tenantService.ts'), 'utf8');
const edgeFn = readFileSync(resolve(repoRoot, 'supabase/functions/delete-tenant/index.ts'), 'utf8');

describe('delete_tenant_canonical idempotency', () => {
  it('delete_state.request_id is the primary key', () => {
    expect(migration).toMatch(/request_id\s+UUID\s+PRIMARY\s+KEY/);
  });

  it('delete_tenant_canonical registers request with ON CONFLICT DO NOTHING', () => {
    expect(rpcMigration).toContain('ON CONFLICT (request_id) DO NOTHING');
  });

  it('delete_tenant_canonical checks existing terminal status before re-running', () => {
    expect(rpcMigration).toMatch(/v_existing_status\s+IN\s*\([^)]*SIDE_EFFECTS_PENDING/);
  });
});

describe('request_id propagation', () => {
  it('tenantService hardDeleteTenant generates and sends p_request_id', () => {
    expect(tenantService).toMatch(/p_request_id:\s*requestId/);
    expect(tenantService).toMatch(/p_correlation_id:\s*cid/);
  });

  it('delete-tenant edge function sends p_request_id to canonical RPC', () => {
    expect(edgeFn).toMatch(/p_request_id:\s*requestId/);
    expect(edgeFn).toMatch(/p_actor_id:\s*user\.id/);
    expect(edgeFn).toMatch(/p_correlation_id:\s*correlationId/);
  });
});
