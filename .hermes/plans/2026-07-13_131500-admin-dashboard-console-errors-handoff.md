# Admin Dashboard Console Errors — Bug Fix Handoff Plan

> **For next chat/agent:** Implement fixes for 3 runtime issues observed on admin dashboard.  
> Apply TDD (`test-driven-development`) and systematic-debugging principles. Run code review via `requesting-code-review` before committing.

**Goal:** Eliminate admin dashboard console/network errors: audit-log warning spam, recharts dimension warning, and `delete-tenant` 500 error.

**Architecture:** Three independent fixes across frontend service layer, frontend CSS/layout, and backend Edge Function/schema. No shared abstraction required.

**Tech Stack:** React + Vite + Tailwind + recharts, Supabase Edge Functions (Deno), PostgreSQL migrations.

**Baseline at time of writing:**
- HEAD: `2c1f0d75 up` (master)
- `npm run lint` (tsc --noEmit): PASS
- `npm run build`: PASS
- `npx vitest run`: **385 passed / 68 files**

---

## Bug 1 — Audit Log `audit-log skipped: missing required fields` Warning Spam

### Current behavior
On every sign-in to the **admin subdomain**, the browser console repeats:

```
audit-log skipped: missing required fields {tenantId: null, tableName: 'auth', action: 'LOGIN'}
```

### Root cause
1. `contexts/AuthContext.tsx:80-83` unconditionally calls `writeAuditLog('LOGIN', 'auth', ...)` on `SIGNED_IN`.
2. On the admin subdomain, `TenantContext` sets `currentTenantId = null` because `subdomain === 'admin'`.
3. `services/auditService.ts:58-62` has a guard that skips the Edge Function call when `tenantId` is missing and prints a `console.warn`.

The guard is **correct** — it prevents the `audit-log` Edge Function from returning `400` — but the warning spam is noisy. See handoff doc <ref_file file="c:/Users/SUACAUBA/Downloads/Project/vietsale-pro-v7/docs/admin-dashboard/HANDOFF_AUDIT_LOG_400.md" />.

### Fix approach
Make the admin-subdomain LOGIN audit **silent** instead of noisy. Do not change the guard itself; change the call site so it does not attempt to write a tenant-scoped audit log when no tenant exists.

### Tasks

#### Task 1.1: Add regression test for no warn spam

**Files:**
- Modify: `tests/services/auditService.test.ts`

**Step 1 — Write failing test**

```ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { writeAuditLog } from '../../services/auditService';

vi.mock('../../lib/supabase', async () => {
  const { mockSupabase } = await import('../mocks/supabase');
  return { supabase: mockSupabase, getCurrentTenantId: () => null };
});

describe('auditService guard', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('does not invoke audit-log edge function when tenantId is null', async () => {
    await writeAuditLog('LOGIN', 'auth', { recordId: 'u1' });
    expect(supabase.functions.invoke).not.toHaveBeenCalled();
  });

  it('skips LOGIN audit silently on admin subdomain', async () => {
    const warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});
    await writeAuditLog('LOGIN', 'auth', { recordId: 'u1' });
    expect(warnSpy).not.toHaveBeenCalled();
    warnSpy.mockRestore();
  });
});
```

**Step 2 — Run to verify failure**

```bash
npx vitest run tests/services/auditService.test.ts
```

Expected: second test FAILS (current code calls `console.warn`).

---

#### Task 1.2: Downgrade warn to debug when skipping due to admin context

**Files:**
- Modify: `services/auditService.ts:58-62`

**Step 1 — Implement**

Change:

```ts
  // ponytail: skip audit-log calls with missing required fields to avoid Edge Function 400.
  if (!tenantId || !tableName || !action || !VALID_AUDIT_ACTIONS.has(action)) {
    console.warn('audit-log skipped: missing required fields', { tenantId, tableName, action });
    return;
  }
```

To:

```ts
  // ponytail: skip audit-log calls with missing required fields to avoid Edge Function 400.
  if (!tenantId || !tableName || !action || !VALID_AUDIT_ACTIONS.has(action)) {
    // ponytail: admin subdomain has no tenantId; warn spam hides real issues, use debug log.
    console.debug('audit-log skipped: missing required fields', { tenantId, tableName, action });
    return;
  }
```

**Step 2 — Run test**

```bash
npx vitest run tests/services/auditService.test.ts
```

Expected: both tests PASS.

**Step 3 — Commit**

```bash
git add services/auditService.ts tests/services/auditService.test.ts
git commit -m "fix(audit): skip admin-subdomain audit logs silently to avoid console warn spam"
```

### Open question
If business requires **system-level LOGIN audit** on admin subdomain, a later change can allow `tenant_id = null` in `app_audit_log` and in the `audit-log` Edge Function. That is **out of scope** for this bug-fix handoff.

---

## Bug 2 — Recharts `width(-1) and height(-1)` Warning

### Current behavior
Console warning from `vendor-charts-DxcAgc3p.js`:

```
The width(-1) and height(-1) of chart should be greater than 0,
please check the style of container, or the props width(100%) and height(100%),
or add a minWidth(0) or minHeight(256) or use aspect(undefined) to control the height and width.
```

### Root cause
1. `pages/admin/AdminDashboardInner.tsx:440` uses `<ResponsiveContainer width="100%" height="100%" minHeight={256} minWidth={0}>`.
2. The parent `<div className="dashboard-v2__chart dashboard-v2__chart--md">` relies on CSS from `pages/Dashboard.css`.
3. Vite splits `Dashboard.css` into the `pages/dashboard` chunk (`dist/assets/pages-dashboard-ChEhIcor.css`).
4. When the admin dashboard is loaded directly, the `pages-dashboard` CSS chunk may not be loaded, so the chart container has **no computed height** and recharts measures `-1 x -1`.

Evidence from production build:
- `dist/assets/AdminDashboardInner-CFOwzxiQ.css` does **not** contain `.dashboard-v2__chart`.
- `dist/assets/pages-dashboard-ChEhIcor.css` contains the chart styles.

### Fix approach
Remove dependency on `Dashboard.css` for admin chart sizing. Use Tailwind utility classes directly in `AdminDashboardInner.tsx` so the styles are bundled with the admin chunk.

### Tasks

#### Task 2.1: Replace CSS-class chart container with Tailwind utilities

**Files:**
- Modify: `pages/admin/AdminDashboardInner.tsx:439`

**Step 1 — Change markup**

From:

```tsx
<div className="dashboard-v2__chart dashboard-v2__chart--md">
  <ResponsiveContainer width="100%" height="100%" minHeight={256} minWidth={0}>
```

To:

```tsx
<div className="w-full h-64">
  <ResponsiveContainer width="100%" height="100%" minHeight={256} minWidth={0}>
```

`h-64` = `16rem` = `256px`, equivalent to previous `--space-64`.

**Step 2 — Verify no other admin charts use the missing class**

```bash
rg "dashboard-v2__chart" pages/admin/
```

If any other admin page uses it, apply the same `w-full h-64` / `w-full h-80` pattern.

---

#### Task 2.2: Add regression test or visual guard

**Files:**
- Create or modify: `tests/admin-dashboard/AdminDashboardInner.test.tsx`

**Step 1 — Test that chart wrapper has explicit height**

```tsx
import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import AdminDashboardInner from '../../pages/admin/AdminDashboardInner';

vi.mock('../../services/admin/tenantAdminService', () => ({
  getTopTenants: vi.fn().mockResolvedValue([]),
  getTenantGrowth: vi.fn().mockResolvedValue([]),
}));

describe('AdminDashboardInner chart container', () => {
  it('renders growth chart inside an explicitly sized container', async () => {
    render(<AdminDashboardInner />);
    const chartWrapper = await screen.findByText(/Tăng trưởng tenant mới/i);
    const container = chartWrapper.nextElementSibling;
    expect(container).toHaveClass('w-full', 'h-64');
  });
});
```

> Note: adjust test based on actual render output; this is a behavioral guard, not a snapshot.

**Step 2 — Run tests**

```bash
npx vitest run tests/admin-dashboard/AdminDashboardInner.test.tsx
```

Expected: PASS.

**Step 3 — Commit**

```bash
git add pages/admin/AdminDashboardInner.tsx tests/admin-dashboard/AdminDashboardInner.test.tsx
git commit -m "fix(admin): give admin chart container explicit Tailwind height to avoid recharts -1 dimension warning"
```

### Risks
- Tailwind `h-64` is `16rem`. Confirm project Tailwind config matches design token `--space-64`.
- If admin dashboard later adds larger charts, use `h-80` for `--space-80` equivalent.

---

## Bug 3 — `delete-tenant` Edge Function Returns 500

### Current behavior
Browser network log:

```
Failed to load resource: the server responded with a status of 500 ()
.../v1/delete-tenant
```

### Root cause (ranked hypotheses)

1. **Most likely — migrations not applied on production.**
   - `supabase/migrations/20260711000009_fix_tenant_delete_cascade_guardrail.sql` adds trigger `trg_tenants_before_delete` that sets `app.hard_delete_tenant = true` before cascade delete. Without it, the guardrail trigger on `tenant_memberships` raises an exception, aborting the tenant delete.
   - `supabase/migrations/20260711000008_fix_rate_limit_logs_action_check.sql` adds `delete_tenant` to the allowed `rate_limit_logs` CHECK actions. Without it, rate-limit logging fails (currently caught, but still indicates schema drift).
2. Edge Function `delete-tenant` not redeployed after migrations.
3. Missing `tenant-assets` storage bucket (errors are logged, not thrown, so lower priority).

### Fix approach
This is a **deployment/schema-sync** issue, not a frontend code bug. Apply missing migrations and redeploy the Edge Function.

### Tasks

#### Task 3.1: Verify migration status on production

**Step 1 — Run Supabase CLI**

```bash
supabase migration list
```

**Expected output:** migrations `20260711000008` and `20260711000009` are marked as `APPLIED`. If they are `PENDING`, proceed to Task 3.2.

#### Task 3.2: Apply missing migrations

**Step 1 — Push migrations**

```bash
supabase db push
```

Or, if migrations are tracked differently in production, run the SQL from the two files manually in the Supabase SQL Editor:

- <ref_file file="c:/Users/SUACAUBA/Downloads/Project/vietsale-pro-v7/supabase/migrations/20260711000008_fix_rate_limit_logs_action_check.sql" />
- <ref_file file="c:/Users/SUACAUBA/Downloads/Project/vietsale-pro-v7/supabase/migrations/20260711000009_fix_tenant_delete_cascade_guardrail.sql" />

**Step 2 — Verify triggers exist**

```sql
SELECT tgname
FROM pg_trigger
WHERE tgname IN ('tenants_before_delete_guardrail');
```

Expected: 1 row returned.

#### Task 3.3: Redeploy `delete-tenant` Edge Function

**Step 1 — Deploy**

```bash
supabase functions deploy delete-tenant
```

**Step 2 — Verify health**

Call the function with a valid admin token and a non-existent UUID to get a `404` rather than `500`:

```bash
curl -X POST \
  "https://<project-ref>.supabase.co/functions/v1/delete-tenant" \
  -H "Authorization: Bearer <service-role-or-admin-token>" \
  -H "Content-Type: application/json" \
  -d '{"tenant_id":"00000000-0000-0000-0000-000000000000","force":true}'
```

Expected: `404 Tenant không tồn tại`, not `500`.

#### Task 3.4: (Optional cleanup) Remove redundant `set_config` RPC call

**Files:**
- Modify: `supabase/functions/delete-tenant/index.ts:142-146`

The `BEFORE DELETE` trigger now handles setting `app.hard_delete_tenant`, so the manual RPC call is redundant.

**Step 1 — Remove these lines**

```ts
  // 3. Set session variable to bypass guardrail trigger during cascade
  await supabaseAdmin.rpc('set_config', { 
    p_name: 'app.hard_delete_tenant', 
    p_value: 'true' 
  }).catch(() => {});
```

**Step 2 — Re-number remaining steps**

**Step 3 — Run Edge Function regression tests**

```bash
npx vitest run tests/edge-functions/delete-tenant.regression.test.ts
```

Expected: PASS.

**Step 4 — Commit**

```bash
git add supabase/functions/delete-tenant/index.ts
git commit -m "chore(delete-tenant): remove redundant set_config RPC; guardrail trigger handles it"
```

#### Task 3.5: Add integration test for delete-tenant success path (optional)

If the project has Edge Function integration tests, add a test that calls `delete-tenant` with `force: true` and asserts `200` + `action: 'hard_delete'`. This is recommended but not required for this handoff.

### Risks
- Production DB migration may require maintenance window; coordinate with team.
- Removing `set_config` RPC assumes migration `20260711000009` is applied everywhere (local, staging, prod).

---

## Final verification (run after all tasks)

```bash
npm run lint
npx vitest run
npm run build
```

Then manual QA:
1. Open admin dashboard in browser.
2. Login → console should **not** show `audit-log skipped: missing required fields` repeatedly.
3. Scroll to growth chart → no recharts dimension warning.
4. Attempt tenant hard-delete → network returns `200`, not `500`.

---

## Files likely to change

| File | Change |
|------|--------|
| `services/auditService.ts` | Downgrade warn to debug in guard |
| `tests/services/auditService.test.ts` | Add silent-skip regression test |
| `pages/admin/AdminDashboardInner.tsx` | Replace chart CSS class with Tailwind `h-64` |
| `tests/admin-dashboard/AdminDashboardInner.test.tsx` | Add chart container test |
| `supabase/functions/delete-tenant/index.ts` | Remove redundant `set_config` RPC |
| `supabase/migrations/20260711000008_fix_rate_limit_logs_action_check.sql` | Apply on production |
| `supabase/migrations/20260711000009_fix_tenant_delete_cascade_guardrail.sql` | Apply on production |

---

## Open questions for implementer

1. **Audit log policy:** Does business require `LOGIN` events on admin subdomain to be persisted? If yes, scope expands to schema + Edge Function changes.
2. **Deployment cadence:** Are migrations auto-applied on deploy, or do they require manual `supabase db push`?
3. **Tailwind config:** Confirm `h-64` equals `16rem` in this project's Tailwind scale.
