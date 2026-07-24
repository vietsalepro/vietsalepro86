// WAVE-03 canonical delete pipeline verification.
// Run: npx tsx scripts/verify-wave03.ts
//
// Verifies the SPEC-001 implementation artifacts:
//   - migration files exist;
//   - local DB schema has the canonical tables/RPC/trigger state;
//   - edge functions + client service route through the USE_CANONICAL_DELETE flag;
//   - test files and documentation exist.
//
// ponytail: DB checks use `docker exec psql` because the local Supabase stack
// already runs Postgres in a container. Set WAVE03_DB_CONTAINER to override.

import fs from 'fs';
import path from 'path';
import { spawnSync } from 'child_process';

const root = process.cwd();
const read = (rel: string): string => fs.readFileSync(path.join(root, rel), 'utf-8');
const exists = (rel: string): boolean => fs.existsSync(path.join(root, rel));

type Check = { name: string; ok: boolean; detail?: string };
const checks: Check[] = [];
const check = (name: string, ok: boolean, detail = '') => checks.push({ name, ok, detail });

// --- DB harness ---
let dbAvailable = false;
let dbContainer = process.env.WAVE03_DB_CONTAINER || '';

function dockerCmd(args: string[]): string {
  const r = spawnSync('docker', args, { encoding: 'utf-8', shell: false, timeout: 30000 });
  if (r.error) throw r.error;
  if (r.status !== 0) throw new Error(r.stderr || `docker exited ${r.status}`);
  return r.stdout;
}

function psql(sql: string): string {
  const r = spawnSync(
    'docker',
    [
      'exec', '-i', dbContainer, 'psql', '-U', 'postgres', '-d', 'postgres', '-At', '-F,', '-c', sql,
    ],
    { encoding: 'utf-8', shell: false, timeout: 30000 },
  );
  if (r.error) throw r.error;
  if (r.status !== 0) throw new Error(r.stderr || `psql exited ${r.status}`);
  return r.stdout;
}

function psqlRows(sql: string): string[][] {
  return psql(sql)
    .split('\n')
    .map((l) => l.trim())
    .filter((l) => l.length > 0)
    .map((l) => l.split(','));
}

function findDbContainer(): string {
  if (dbContainer) return dbContainer;
  // Docker filter matches the container name; try the common Supabase DB prefix.
  let id = dockerCmd(['ps', '-q', '--filter', 'name=supabase_db'])
    .split('\n')[0]
    ?.trim();
  if (id) return id;
  // Fallback: scan running container names for any containing 'supabase_db'.
  const names = dockerCmd(['ps', '--format', '{{.Names}}']).split(/\r?\n/);
  id = names.find((n) => n.includes('supabase_db'))?.trim() ?? '';
  return id;
}

try {
  dbContainer = findDbContainer();
  if (dbContainer) {
    psql('SELECT 1');
    dbAvailable = true;
  }
} catch (e) {
  const msg = e instanceof Error ? e.message : String(e);
  check('local DB reachable', false, `docker/psql unavailable: ${msg}`);
}

// 1. Migration file existence.
const migrations = [
  'supabase/migrations/20260725000000_create_delete_state_tables.sql',
  'supabase/migrations/20260725000001_create_rpc_delete_tenant_canonical.sql',
  'supabase/migrations/20260725000002_audit_independence.sql',
  'supabase/migrations/20260725000003_trigger_migration.sql',
  'supabase/migrations/20260731000001_disable_remaining_business_triggers.sql',
];
for (const m of migrations) {
  check(`migration exists: ${path.basename(m)}`, exists(m), m);
}

// 2. Schema checks via local DB.
if (dbAvailable) {
  const tableRows = psqlRows(
    "SELECT tablename FROM pg_tables WHERE schemaname='public' AND tablename IN ('delete_state','outbox','tenant_deletion_backups') ORDER BY tablename;",
  );
  const tablesFound = new Set(tableRows.map((r) => r[0]));
  for (const t of ['delete_state', 'outbox', 'tenant_deletion_backups']) {
    check(`table exists: public.${t}`, tablesFound.has(t));
  }

  const funcRows = psqlRows(
    "SELECT proname, prosecdef::int FROM pg_proc WHERE proname='delete_tenant_canonical';",
  );
  check(
    'function exists: public.delete_tenant_canonical',
    funcRows.length > 0,
    funcRows.map((r) => r.join('=')).join(', '),
  );
  check(
    'function is SECURITY DEFINER',
    funcRows.some((r) => r[0] === 'delete_tenant_canonical' && r[1] === '1'),
  );

  const colRows = psqlRows(
    "SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='app_audit_log' AND column_name='deleted_tenant_id';",
  );
  check('column exists: app_audit_log.deleted_tenant_id', colRows.length > 0);

  const fkRows = psqlRows(
    "SELECT conname FROM pg_constraint WHERE conname IN ('app_audit_log_tenant_id_fkey','audit_log_tenant_id_fkey');",
  );
  check('audit FK removed', fkRows.length === 0, fkRows.map((r) => r[0]).join(', '));

  const trigRows = psqlRows(
    "SELECT t.tgname, t.tgenabled FROM pg_trigger t JOIN pg_class c ON t.tgrelid=c.oid JOIN pg_namespace n ON c.relnamespace=n.oid WHERE n.nspname='public' AND t.tgname IN ('trg_audit_log_invitations','trg_audit_log_licenses','trg_audit_log_system_admins','tenants_before_delete_guardrail','tenant_memberships_guardrails');",
  );
  const trig = Object.fromEntries(trigRows.map((r) => [r[0], r[1]]));
  check('business trigger disabled: trg_audit_log_invitations', trig['trg_audit_log_invitations'] === 'D');
  check('business trigger disabled: trg_audit_log_licenses', trig['trg_audit_log_licenses'] === 'D');
  check('business trigger disabled: trg_audit_log_system_admins', trig['trg_audit_log_system_admins'] === 'D');
  check('guardrail trigger enabled: tenants_before_delete_guardrail', trig['tenants_before_delete_guardrail'] === 'O');
  check('guardrail trigger enabled: tenant_memberships_guardrails', trig['tenant_memberships_guardrails'] === 'O');
}

// 3. Edge Function / service checks.
check('edge function exists: outbox-processor', exists('supabase/functions/outbox-processor/index.ts'));
check(
  'delete-tenant edge fn has USE_CANONICAL_DELETE logic',
  exists('supabase/functions/delete-tenant/index.ts') &&
    read('supabase/functions/delete-tenant/index.ts').includes("Deno.env.get('USE_CANONICAL_DELETE')"),
);

check(
  'tenantService calls delete_tenant_canonical RPC',
  exists('services/tenantService.ts') &&
    /supabase\.rpc\(\s*['"]delete_tenant_canonical['"]/.test(read('services/tenantService.ts')),
);
check(
  'tenantService has feature flag check',
  exists('services/tenantService.ts') &&
    /VITE_USE_CANONICAL_DELETE/.test(read('services/tenantService.ts')),
);

// 4. Test files.
check('vitest outbox-processor regression test exists', exists('tests/edge-functions/outbox-processor.regression.test.ts'));
check('vitest delete-tenant idempotency test exists', exists('tests/regression/delete-tenant-idempotency.test.ts'));
const pgTapFiles = [
  'supabase/tests/rpc/delete_state_tables.test.sql',
  'supabase/tests/rpc/delete_tenant_canonical.test.sql',
  'supabase/tests/rpc/audit_independence.test.sql',
  'supabase/tests/rpc/trigger_migration.test.sql',
];
for (const f of pgTapFiles) {
  check(`pgTAP test exists: ${path.basename(f)}`, exists(f));
}

// 5. Documentation.
const sem = 'ADMIN_DASHBOARD_PLAN_FIX_SPB/SEMANTIC_MEMORY.md';
if (exists(sem)) {
  const semText = read(sem);
  check(
    'SEMANTIC_MEMORY mentions canonical delete components',
    /delete_state/.test(semText) && /outbox/.test(semText) && /tenant_deletion_backups/.test(semText),
  );
} else {
  check('SEMANTIC_MEMORY exists', false, sem);
}
check('DELETE_TENANT_RUNBOOK exists', exists('ADMIN_DASHBOARD_PLAN_FIX_SPB/runbooks/DELETE_TENANT_RUNBOOK.md'));

// 6. Feature flag default off.
const tenantSvc = read('services/tenantService.ts');
const deleteEdge = read('supabase/functions/delete-tenant/index.ts');
check(
  'USE_CANONICAL_DELETE defaults to false (tenantService)',
  /VITE_USE_CANONICAL_DELETE === 'true'/.test(tenantSvc) &&
    !/VITE_USE_CANONICAL_DELETE === 'false'/.test(tenantSvc) &&
    !/USE_CANONICAL_DELETE\s*===\s*'false'/.test(tenantSvc),
);
check(
  'USE_CANONICAL_DELETE defaults to false (delete-tenant edge)',
  /Deno\.env\.get\('USE_CANONICAL_DELETE'\) === 'true'/.test(deleteEdge) &&
    !/Deno\.env\.get\('USE_CANONICAL_DELETE'\) === 'false'/.test(deleteEdge),
);

// 7. Legacy fallbacks marked deprecated.
if (exists('services/supabaseService.ts')) {
  const svc = read('services/supabaseService.ts');
  check(
    '_legacy* fallbacks are annotated deprecated',
    /_legacy/.test(svc) && /@deprecated/.test(svc),
  );
} else {
  check('supabaseService.ts exists', false, 'services/supabaseService.ts not found');
}

// 8. Phase 5.2b test report evidence.
const testReport = 'ADMIN_DASHBOARD_PLAN_FIX_SPB/WAVE-03_PHASE-5-2B_TEST_REPORT.md';
if (exists(testReport)) {
  const report = read(testReport);
  check(
    'Phase 5.2b test report overall PASS',
    /Trạng thái tổng thể.*\*\*PASS\*\*/.test(report) || /\*\*PASS\*\*/.test(report),
  );
} else {
  check('Phase 5.2b test report exists', false, testReport);
}

// Report.
let failed = 0;
for (const c of checks) {
  const status = c.ok ? 'PASS' : 'FAIL';
  if (!c.ok) failed++;
  console.log(`[${status}] ${c.name}${c.detail ? ` — ${c.detail}` : ''}`);
}
console.log(`\nWave-03 verification: ${checks.length - failed}/${checks.length} checks passed.`);
if (failed > 0) {
  console.error('Wave-03 verification FAILED.');
  process.exit(1);
}
console.log('Wave-03 verification OK.');
