import { describe, it, expect } from 'vitest';
import { readFileSync } from 'fs';
import { resolve } from 'path';

/**
 * WAVE-02 Condition F — RT-01 (root-cause regression) + SPEC-006 (observability).
 *
 * The original `delete-tenant` HTTP 500 was caused by the AFTER DELETE trigger on
 * public.tenants inserting an audit_log row whose tenant_id referenced the
 * just-deleted tenant, violating audit_log_tenant_id_fkey.
 *
 * The deployed fix (migration 20260715000011) makes audit_log_trigger() write
 * tenant_id = NULL on a tenants DELETE. These tests assert that fix stays in the
 * migration chain and that the edge function/service propagate a correlation id.
 *
 * ponytail: source/migration scanning keeps this runnable in CI without a live DB.
 * The live-DB assertion is covered by scripts/verify-wave02.ts.
 */

const repoRoot = resolve(__dirname, '../..');
const read = (rel: string) => readFileSync(resolve(repoRoot, rel), 'utf8');

const FIX_MIGRATION =
  'supabase/migrations/20260715000011_fix_audit_log_trigger_tenant_delete.sql';
const EDGE_FN = 'supabase/functions/delete-tenant/index.ts';
const SERVICE = 'services/tenantService.ts';

describe('delete-tenant HTTP 500 root-cause regression (RT-01)', () => {
  const migration = read(FIX_MIGRATION);

  it('audit_log_trigger sets tenant_id NULL on a tenants DELETE', () => {
    expect(migration).toContain('CREATE OR REPLACE FUNCTION public.audit_log_trigger()');
    // The DELETE branch for tenants must null out tenant_id so the FK is not violated.
    expect(migration).toMatch(/IF\s+TG_OP\s*=\s*'DELETE'\s+THEN[\s\S]*?v_tenant_id\s*:=\s*NULL;/);
  });

  it('does not re-introduce a raw OLD.tenant_id insert for the tenants DELETE path', () => {
    // The unguarded COALESCE(NEW.tenant_id, OLD.tenant_id) is only for non-tenants tables.
    const tenantsBranch = migration.slice(
      migration.indexOf("TG_TABLE_NAME = 'tenants'"),
      migration.indexOf('ELSE', migration.indexOf("TG_TABLE_NAME = 'tenants'")),
    );
    expect(tenantsBranch).toContain('v_tenant_id := NULL;');
  });
});

describe('delete-tenant observability — correlation id (SPEC-006)', () => {
  const edge = read(EDGE_FN);
  const service = read(SERVICE);

  it('edge function resolves and threads a correlation id', () => {
    expect(edge).toContain('resolveCorrelationId');
    expect(edge).toContain("'x-correlation-id'");
    expect(edge).toContain('correlation_id: correlationId');
  });

  it('edge function CORS allows the x-correlation-id header', () => {
    expect(edge).toMatch(/Access-Control-Allow-Headers[^\n]*x-correlation-id/);
  });

  it('client hardDeleteTenant forwards a correlation id in body and header', () => {
    expect(service).toMatch(/correlation_id:\s*cid/);
    expect(service).toMatch(/'x-correlation-id':\s*cid/);
  });
});
