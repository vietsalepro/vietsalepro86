// WAVE-02 read-only reconciliation checker.
// Run: npx tsx scripts/verify-wave02.ts
//
// Verifies the *adapted* Wave-02 scope (Option B — Adapt to reality):
//  - the delete-tenant HTTP 500 root-cause fix is present in the migration chain;
//  - the delete-tenant edge function + client service propagate a correlation id;
//  - the reconciliation report and runbook updates exist.
// It also reports which speculative components are intentionally ABSENT (deferred).
//
// ponytail: file/migration based so it runs in CI without DB creds. Live-DB state
// was captured in ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE-02_RECONCILIATION_REPORT.md.

import fs from 'fs';
import path from 'path';

const root = process.cwd();
const read = (rel: string): string => fs.readFileSync(path.join(root, rel), 'utf-8');
const exists = (rel: string): boolean => fs.existsSync(path.join(root, rel));

type Check = { name: string; ok: boolean; detail?: string };
const checks: Check[] = [];
const check = (name: string, ok: boolean, detail = '') => checks.push({ name, ok, detail });

// 1. Root-cause fix present and correct.
const FIX = 'supabase/migrations/20260715000011_fix_audit_log_trigger_tenant_delete.sql';
if (exists(FIX)) {
  const sql = read(FIX);
  check(
    'root-cause fix: audit_log_trigger nulls tenant_id on tenants DELETE',
    /IF\s+TG_OP\s*=\s*'DELETE'\s+THEN[\s\S]*?v_tenant_id\s*:=\s*NULL;/.test(sql),
  );
} else {
  check('root-cause fix migration exists', false, `${FIX} not found`);
}

// 2. Correlation-id observability (SPEC-006).
const edge = read('supabase/functions/delete-tenant/index.ts');
check('edge fn resolves a correlation id', edge.includes('resolveCorrelationId'));
check('edge fn CORS allows x-correlation-id', /Access-Control-Allow-Headers[^\n]*x-correlation-id/.test(edge));
check('edge fn writes correlation_id to audit new_data', edge.includes('correlation_id: correlationId'));

const service = read('services/tenantService.ts');
check('client forwards correlation_id in body', /correlation_id:\s*cid/.test(service));
check('client forwards x-correlation-id header', /'x-correlation-id':\s*cid/.test(service));

// 3. Documentation deliverables.
check('reconciliation report exists', exists('ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE-02_RECONCILIATION_REPORT.md'));
check(
  'ROLLBACK runbook has tenant-deletion section',
  exists('docs/admin-dashboard/ROLLBACK_RUNBOOK.md') &&
    read('docs/admin-dashboard/ROLLBACK_RUNBOOK.md').includes('Tenant Deletion Administration'),
);

// 4. Informational: speculative components intentionally deferred (must NOT appear as
//    new applied migrations). We only scan migration filenames/content, not the DB.
const migDir = path.join(root, 'supabase/migrations');
const migText = fs
  .readdirSync(migDir)
  .filter((f) => f.endsWith('.sql'))
  .map((f) => fs.readFileSync(path.join(migDir, f), 'utf-8'))
  .join('\n');
const deferred = [
  'delete_tenant_canonical',
  'CREATE TABLE IF NOT EXISTS public.delete_state',
  'CREATE TABLE IF NOT EXISTS public.outbox',
  'CREATE TABLE IF NOT EXISTS public.tenant_deletion_backups',
  'DROP CONSTRAINT IF EXISTS audit_log_tenant_id_fkey',
];
const leaked = deferred.filter((token) => migText.includes(token));
check(
  'deferred architecture not silently added to migrations',
  leaked.length === 0,
  leaked.length ? `unexpected: ${leaked.join(', ')}` : 'none present (as expected)',
);

// Report.
let failed = 0;
for (const c of checks) {
  const status = c.ok ? 'PASS' : 'FAIL';
  if (!c.ok) failed++;
  console.log(`[${status}] ${c.name}${c.detail ? ` — ${c.detail}` : ''}`);
}
console.log(`\nWave-02 verification: ${checks.length - failed}/${checks.length} checks passed.`);
if (failed > 0) {
  console.error('Wave-02 verification FAILED.');
  process.exit(1);
}
console.log('Wave-02 verification OK (adapted scope).');
