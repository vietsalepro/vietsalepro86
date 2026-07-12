# Admin Dashboard Open-Source Reference Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Chuyển `PLAN_AdminDashboard_OpenSource_Reference.md` thành lộ trình 7 phase cụ thể, mỗi phase có thể thực hiện được trong codebase VietSalePro hiện tại (Vite + React 19 + Supabase + Tailwind 4).

**Architecture:** Giữ nguyên stack hiện tại. Mỗi tính năng admin mới sẽ được triển khai theo pattern: Supabase migration (nếu cần schema) → service trong `services/admin/` → component trong `components/admin/` → route/page trong `pages/admin/`. Các panel nặng phải lazy-load để giữ chunk nhỏ.

**Tech Stack:** Vite, React 19, TypeScript 5.8, Tailwind CSS 4, Supabase JS v2, recharts, lucide-react, vitest.

---

## Context / Assumptions

- Codebase đã có: `tenants`, `tenant_memberships`, `plans`, `tenant_subscriptions`, `app_audit_log`, `tenant_api_keys`, `tenant_webhooks`, `support_tickets`, `admin_login_history`, `admin_2fa_backup_codes`.
- Codebase đã có components: `AdminDashboardInner.tsx`, `AdminSidebar.tsx`, `AdminShell.tsx`, `SubscriptionManager.tsx`, `InvoiceManager.tsx`, `WebhookManager.tsx`, `ApiKeyManager.tsx`, `SystemHealthPanel.tsx`, `StorageBackupPanel.tsx`, `TicketInbox.tsx`, `EmailTemplateManager.tsx`, `AnnouncementManager.tsx`, `MemberManagement`.
- Các repo tham khảo chỉ đọc flow/schema; **không copy-paste** code từ AGPL/GPL.
- Mỗi phase kết thúc bằng: `npm run lint && npm run test && npm run build && npm run audit:rpc`.

---

## Proposed Approach

1. Đọc kỹ `PLAN_AdminDashboard_OpenSource_Reference.md`.
2. Map 29 tính năng từ `PLAN_AdminDashboard_OpenSource_Reference.md` vào 7 phase theo dependency (foundation → core UI → billing → advanced → ops → comms → enterprise).
3. Mỗi phase chia thành các task nhỏ (migration, service, component, test, verification).
4. Thực hiện từng task theo TDD nếu có logic nghiệp vụ.
5. Commit sau mỗi task.

---

## Non-Functional Requirements (for 20+ year operation)

> ponytail: Plan tính năng không đủ để sống > 20 năm. Các yêu cầu dưới đây phải được đo đạc và review định kỳ.

| NFR | Target | How to measure |
|-----|--------|----------------|
| Availability | SLO 99.9% admin dashboard | Uptime Robot / synthetic checks |
| RTO / RPO | <= 4h / <= 1h | DR drill mỗi 6 tháng |
| Performance | p95 API latency <= 500ms; first paint <= 2s | Supabase logs + web vitals |
| Security | MFA bắt buộc system admin; key rotation 90 ngày; pentest hàng năm | Policy + audit log |
| Scalability | 10,000 tenants / 1,000,000 users | Load test hàng quý |
| Data durability | Daily backups + PITR; audit log 7 năm | Backup verification + retention report |
| Compliance | PDPA/GDPR; Vietnam e-invoice; OSS license audit | Compliance review hàng năm |
| Vendor independence | Migrations portable sang PostgreSQL 15+; frontend build deployable to any CDN | Quarterly portability check |

---

## Data Lifecycle & Long-Term Retention

| Data type | Hot retention | Archive | Purge |
|-----------|---------------|---------|-------|
| `app_audit_log` | 1 year | 6 years (object storage) | After 7 years (summary only) |
| `admin_login_history` | 90 days | 1 year | After 2 years |
| `notification_log` | 30 days | 90 days | After 1 year |
| `rate_limit_logs` | 30 days | - | After 90 days |
| Tenant backups | 30 days | - | After 90 days |

- Archive old partitions bằng cron job hoặc pg_partman.
- GDPR deletion workflow: request -> soft-delete -> 30-day grace -> hard-delete -> verification log.
- Cold storage export định kỳ (JSON/Parquet) sang S3-compatible.

---

## Vendor & Dependency Management

- **Supabase:** giữ migrations portable; không dùng quá nhiều extension độc quyền; có option self-host.
- **Vercel:** build output là static SPA; có thể deploy lên bất kỳ CDN nào.
- **PostgreSQL:** migrations phải chạy được trên PostgreSQL 15+.
- **npm dependencies:** `npm audit` + review major version hàng quý; pin major versions in `package.json`.
- **OSS libraries:** duy trì `docs/opensource-references.md` với license và upgrade path.

---

## Compliance & Legal

- **OSS License Audit:** mỗi repo tham khảo trong `PLAN_AdminDashboard_OpenSource_Reference.md` phải ghi rõ license. Các repo AGPL/GPL chỉ được tham khảo kiến trúc, không copy code vào sản phẩm proprietary.
- **PDPA/GDPR:** data subject rights, consent log, DPA checklist, data processing agreement.
- **Vietnam regulations:** hóa đơn điện tử (e-invoice), thuế GTGT, lưu trữ dữ liệu trong nước nếu quy định.
- **Terms / Privacy:** mẫu TOS và Privacy Policy, quy trình cập nhật khi có thay đổi lớn.

---

## Go-to-Market & Business Operations

- **Self-service onboarding:** sign-up -> email verify -> subdomain -> plan -> payment -> wizard.
- **Support tiers:** Free (community), Business (24h response), Enterprise (4h response + Slack channel).
- **Reseller / Partner:** partner tenant, white-label, revenue-share tracking.
- **Billing operations:** dunning retries, invoice disputes, refunds, tax reports.
- **Customer success:** tenant health score, churn alerts, usage-based upsell triggers.

---

## Phase 1: Foundation — Multi-tenancy, Auth, Audit

**Objective:** Củng cố RLS, tenant isolation, và audit log trước khi xây UI.

### Task 1.1: Review current tenant schema

**Objective:** Xác định schema hiện tại có đủ `tenant_id` và FK chưa.

**Files:**
- Read: `supabase/migrations/20250703000000_baseline_pre_tenant_schema.sql`
- Read: `supabase/migrations/20250704000000_phase2_tenant_foundation.sql`

**Step 1: Liệt kê các bảng core chưa có tenant_id**

Run:
```bash
grep -n "CREATE TABLE" supabase/migrations/20250703000000_baseline_pre_tenant_schema.sql
```

**Step 2: So sánh với Basejump schema**

Clone/read `usebasejump/basejump` schema từ GitHub (read-only). Ghi lại diff.

**Verification:** Có danh sách bảng cần bổ sung tenant_id hoặc FK.

---

### Task 1.2: Verify tenant subdomain, custom domain and slug columns

**Objective:** Chuẩn bị schema cho subdomain/custom domain (các cột này đã có trong baseline migration).

**Files:**
- Read: `supabase/migrations/20250703000000_baseline_pre_tenant_schema.sql`
- Read: `supabase/migrations/20260713000001_standardize_tenants_and_memberships.sql`

**Step 1: Xác nhận các cột đã tồn tại**

```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'tenants'
  AND column_name IN ('subdomain','custom_domain','slug','white_label');
```

Expected: ít nhất `subdomain`, `custom_domain`, `slug`.

**Step 2: Xác nhận index**

```sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'tenants'
  AND schemaname = 'public';
```

Expected: `tenants_subdomain_key` hoặc tương đương.

**Step 3: Bổ sung migration nếu còn thiếu**

Chỉ tạo migration mới khi cột/index thực sự chưa có; ví dụ:

```sql
-- ponytail: learned from trentas/saas-scaffolding proxy.ts + Cal.com org routing
ALTER TABLE public.tenants
ADD COLUMN IF NOT EXISTS domain_verified_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS domain_verification_token TEXT;

CREATE INDEX IF NOT EXISTS idx_tenants_custom_domain ON public.tenants(custom_domain);
```

---

### Task 1.3: Audit existing RLS policies

**Objective:** Đảm bảo RLS policies hiện tại không cho phép cross-tenant read.

**Files:**
- Read: `supabase/migrations/20250705000008_phase10_1_db_policies_theo_role.sql`
- Read: `supabase/migrations/20250705000017_phase17_long_term_operations.sql`

**Step 1: Liệt kê policies theo bảng**

Run:
```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public';
```

**Step 2: Xác định bảng thiếu policy**

Tạo file ghi chú `docs/rls-gap-analysis.md`.

**Verification:** Danh sách bảng thiếu policy rõ ràng.

---

### Task 1.4: Add missing RLS policies

**Objective:** Bổ sung policies cho bảng chưa được bảo vệ.

**Files:**
- Create: `supabase/migrations/20250713000021_phase1_rls_missing_tables.sql`

**Step 1: Liệt kê bảng còn thiếu policy**

```sql
SELECT t.tablename
FROM pg_tables t
LEFT JOIN pg_policies p ON p.schemaname = t.schemaname AND p.tablename = t.tablename
WHERE t.schemaname = 'public'
GROUP BY t.tablename
HAVING COUNT(p.policyname) = 0;
```

**Step 2: Viết policy mẫu**

```sql
-- ponytail: replace some_new_table with actual table from gap analysis
ALTER TABLE public.some_new_table ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_select ON public.some_new_table
FOR SELECT USING (tenant_id = current_setting('app.current_tenant')::UUID);
```

**Step 2: Áp dụng migration**

Run:
```bash
supabase migration up
```

**Verification:**
```sql
SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public';
```

---

### Task 1.5: Write RLS isolation test

**Objective:** Kiểm tra user của tenant A không đọc được data tenant B.

**Files:**
- Create: `tests/integration/tenant-isolation.test.ts`

**Step 1: Viết test**

```typescript
import { describe, it, expect } from 'vitest';
import { createTestTenant, createTestUser, getClientForUser } from '../test-helpers';

describe('RLS isolation', () => {
  it('tenant A user cannot read tenant B data', async () => {
    const tenantA = await createTestTenant('tenant-a');
    const tenantB = await createTestTenant('tenant-b');
    const userA = await createTestUser(tenantA.id);
    const clientA = getClientForUser(userA);
    // expect query scoped to tenantA
  });
});
```

**Step 2: Chạy test**

Run:
```bash
npm run test -- tests/integration/tenant-isolation.test.ts
```

Expected: PASS.

---

### Task 1.6: Expand audit log event types

**Objective:** Bổ sung event types theo Cal.com pattern.

**Files:**
- Modify: `services/admin/auditAdminService.ts`
- Modify: `supabase/migrations/20250705000009_phase11_audit_log_triggers.sql`

**Step 1: Định nghĩa enum/types**

```typescript
export type AuditAction =
  | 'login'
  | 'logout'
  | 'impersonation_start'
  | 'impersonation_stop'
  | 'role_changed'
  | 'password_changed'
  | 'tenant_created'
  | 'tenant_deleted'
  | 'subscription_created'
  | 'subscription_cancelled';
```

**Step 2: Thêm helper ghi audit**

```typescript
export async function logAudit(
  supabase: SupabaseClient,
  action: AuditAction,
  payload: { tenant_id?: string; target_id?: string; metadata?: object }
) {
  // insert into app_audit_log
}
```

**Step 3: Test**

Run:
```bash
npm run test -- tests/admin-dashboard/audit-admin-service.test.ts
```

Expected: PASS.

---

### Task 1.7: Commit Phase 1

Run:
```bash
# chỉ add migration nếu thực sự tạo mới trong phase này
git add supabase/migrations/<new_migration_if_any>.sql

git add tests/integration/tenant-isolation.test.ts

git add services/admin/auditAdminService.ts

git commit -m "feat(admin): phase 1 foundation - tenant columns, RLS, audit events"
```

---

## Phase 2: Admin Dashboard Core

**Objective:** Xây layout admin hoàn chỉnh và các trang cơ bản.

### Task 2.0: Build Dashboard overview page

**Objective:** Trang tổng quan admin với KPI cards và charts.

**Files:**
- Create: `pages/admin/Overview.tsx`
- Create: `components/admin/OverviewPanel.tsx`
- Modify: `services/admin/dashboardAdminService.ts`

**Step 1: Service**

```typescript
export async function getDashboardKPIs() { /* tenants, revenue, active users, failed jobs */ }
export async function getDashboardTrends(days: number) { /* time-series for charts */ }
```

**Step 2: Component**

Hiển thị KPI cards và `recharts` line/bar charts cho trends.

**Step 3: Route**

```typescript
{ path: 'overview', element: <OverviewPage /> }
```

**Verification:**
```bash
npm run test -- tests/admin-dashboard/OverviewPage.test.tsx
```

---

### Task 2.1: Refactor AdminShell navigation

**Objective:** Tổ chức sidebar thành nhóm rõ ràng.

**Files:**
- Modify: `components/AdminSidebar.tsx`

**Step 1: Định nghĩa nav groups**

```typescript
const navGroups = [
  { label: 'Overview', items: [{ to: '/admin/overview', icon: Home, label: 'Dashboard' }] },
  { label: 'Management', items: [
    { to: '/admin/tenants', icon: Building, label: 'Tenants' },
    { to: '/admin/members', icon: Users, label: 'Members' },
  ]},
  { label: 'Billing', items: [
    { to: '/admin/plans', icon: CreditCard, label: 'Plans' },
    { to: '/admin/invoices', icon: FileText, label: 'Invoices' },
  ]},
  { label: 'Operations', items: [
    { to: '/admin/health', icon: Activity, label: 'Health' },
    { to: '/admin/backups', icon: Database, label: 'Backups' },
  ]},
];
```

**Step 2: Render groups với collapsible sections**

**Verification:** Chạy dev và kiểm tra sidebar hiển thị đúng nhóm.

---

### Task 2.2: Build Tenant Management page

**Objective:** Trang quản lý tenants với CRUD cơ bản.

**Files:**
- Create: `pages/admin/TenantsPage.tsx`
- Create: `components/admin/TenantManagementPanel.tsx`
- Modify: `services/admin/tenantAdminService.ts`

**Step 1: Service functions**

```typescript
export async function getTenants(filter?: { status?: string; search?: string }) { /* ... */ }
export async function updateTenantStatus(tenantId: string, status: string) { /* ... */ }
```

**Step 2: Component TenantManagementPanel**

Hiển thị bảng tenants với columns: name, slug, subdomain, status, created_at.
Hỗ trợ filter theo status và search theo name/slug.

**Step 3: Route**

```typescript
{ path: 'tenants', element: <TenantsPage /> }
```

**Verification:**
```bash
npm run test -- tests/admin-dashboard/TenantsPage.test.tsx
```

---

### Task 2.3: Build System Settings page

**Objective:** Cho phép admin cấu hình app-level settings.

**Files:**
- Create: `pages/admin/SystemSettingsPage.tsx`
- Create: `components/admin/SystemSettingsPanel.tsx`
- Modify: `services/admin/systemAdminService.ts`

**Step 1: RPC / service**

```typescript
export async function getSystemSettings() { /* ... */ }
export async function updateSystemSettings(settings: Partial<SystemSettings>) { /* ... */ }
```

**Step 2: Component form**

Form gồm: app_name, default_language, timezone, session_timeout_minutes, ip_allowlist.

**Verification:** Test submit form cập nhật settings.

---

### Task 2.4: Build Announcement Manager page

**Objective:** CRUD announcement banner / maintenance mode.

**Files:**
- Modify: `components/AnnouncementManager.tsx` (refactor hoặc wrap)
- Create: `pages/admin/AnnouncementsPage.tsx`

**Step 1: Schema migration nếu thiếu cột**

```sql
ALTER TABLE public.announcements
ADD COLUMN IF NOT EXISTS audience TEXT DEFAULT 'all',
ADD COLUMN IF NOT EXISTS active_from TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS active_to TIMESTAMPTZ;
```

**Step 2: Component**

CRUD với preview banner.

**Verification:** Test tạo announcement và kiểm tra hiển thị ở `AnnouncementBanner.tsx`.

---

### Task 2.5: Build Activity Feed page

**Objective:** Hiển thị audit log dưới dạng activity feed.

**Files:**
- Create: `pages/admin/ActivityPage.tsx`
- Create: `components/admin/ActivityFeedPanel.tsx`
- Modify: `services/admin/auditAdminService.ts`

**Step 1: Service query**

```typescript
export async function getActivityFeed(filter: { tenant_id?: string; action?: string; from?: string; to?: string }) { /* ... */ }
```

**Step 2: Component**

Hiển thị timeline với actor, action, target, timestamp, metadata.

**Verification:** Test filter theo action type.

---

### Task 2.6: Build Global Config page

**Objective:** Quản lý app_settings với caching.

**Files:**
- Create: `pages/admin/GlobalConfigPage.tsx`
- Create: `components/admin/GlobalConfigPanel.tsx`
- Modify hoặc create: `services/admin/globalConfigService.ts`

**Step 1: Service**

```typescript
export async function getGlobalConfig() { /* ... */ }
export async function setGlobalConfig(key: string, value: unknown) { /* ... */ }
```

**Step 2: Context caching**

Tạo `hooks/useGlobalConfig.ts` với TTL 5 phút.

**Verification:** Test cache invalidation sau khi update.

---

### Task 2.7: Build User Management page

**Objective:** Trang quản lý users trong hệ thống.

**Files:**
- Create: `pages/admin/UsersPage.tsx`
- Create: `components/admin/UserManagementPanel.tsx`
- Modify: `services/admin/userAdminService.ts`

**Step 1: Service**

```typescript
export async function getUsers(filter?: { status?: string; search?: string }) { /* ... */ }
export async function updateUserStatus(userId: string, status: string) { /* ... */ }
```

**Step 2: Component**

Bảng users với columns: email, name, tenant, role, status, last_login.
Hỗ trợ filter theo status và search theo email/name.

**Verification:**
```bash
npm run test -- tests/admin-dashboard/UsersPage.test.tsx
```

---

### Task 2.8: Build Team/Role Management page

**Objective:** Quản lý teams/roles và permissions.

**Files:**
- Create: `pages/admin/RolesPage.tsx`
- Create: `components/admin/RoleManagementPanel.tsx`
- Modify: `services/admin/permissions.ts`

**Step 1: Service**

```typescript
export async function getRoles() { /* ... */ }
export async function createRole(name: string, permissions: string[]) { /* ... */ }
export async function assignUserRole(userId: string, roleId: string) { /* ... */ }
```

**Step 2: Component**

CRUD roles, gán permissions, gán role cho user.

**Verification:**
```bash
npm run test -- tests/admin-dashboard/RolesPage.test.tsx
```

---

### Task 2.9: Build Audit Log page

**Objective:** Trang xem audit log đầy đủ (khác Activity Feed ở chỗ focused vào security events).

**Files:**
- Create: `pages/admin/AuditLogPage.tsx`
- Create: `components/admin/AuditLogPanel.tsx`
- Modify: `services/admin/auditAdminService.ts`

**Step 1: Service**

```typescript
export async function getAuditLogs(filter: { action?: string; actor_id?: string; from?: string; to?: string }) { /* ... */ }
```

**Step 2: Component**

Bảng audit log có phân trang, filter theo action/actor/date range.

**Verification:**
```bash
npm run test -- tests/admin-dashboard/AuditLogPage.test.tsx
```

---

## Phase 3: Billing, Subscription, Usage, Invoice

**Objective:** Hoàn thiện billing lifecycle.

### Task 3.1: Refactor Plans CRUD

**Objective:** Quản lý plans với features và limits.

**Files:**
- Modify: `components/SubscriptionManager.tsx`
- Modify: `services/admin/billingAdminService.ts`
- Read: `supabase/migrations/20260713000009_create_plan_features.sql`

**Step 1: Service functions**

```typescript
export async function getPlans() { /* ... */ }
export async function createPlan(plan: PlanInput) { /* ... */ }
export async function updatePlan(id: string, plan: Partial<PlanInput>) { /* ... */ }
```

**Step 2: UI form**

Fields: name, price, interval, seat_limit, usage_limits (JSONB), features (array).

**Verification:** Test create/update plan.

---

### Task 3.2: Subscription lifecycle RPC

**Objective:** Xử lý trial, active, past_due, canceled, **upgrade, downgrade, cancellation**.

**Files:**
- Create: `supabase/migrations/20250713000022_phase3_subscription_lifecycle_rpc.sql`

**Step 1: Viết RPC**

```sql
CREATE OR REPLACE FUNCTION public.create_subscription(
  p_tenant_id UUID,
  p_plan_id UUID,
  p_stripe_subscription_id TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
  -- insert tenant_subscriptions với status trialing/active
  -- log audit
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.upgrade_subscription(
  p_tenant_id UUID,
  p_new_plan_id UUID
) RETURNS VOID AS $$
BEGIN
  -- update tenant_subscriptions, prorate nếu cần, log audit
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.downgrade_subscription(
  p_tenant_id UUID,
  p_new_plan_id UUID
) RETURNS VOID AS $$
BEGIN
  -- schedule downgrade at end of billing period, log audit
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.cancel_subscription(
  p_tenant_id UUID,
  p_immediate BOOLEAN DEFAULT FALSE
) RETURNS VOID AS $$
BEGIN
  -- set status canceled/cancel_at_period_end, log audit
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Step 2: Test**

Run:
```bash
supabase migration up
```

**Verification:** Gọi RPC từ test và kiểm tra status.

---

### Task 3.3: Payment provider registry

**Objective:** Chuẩn hóa interface giữa Stripe/VNPay/MoMo.

**Files:**
- Modify: `services/admin/billingProviderRegistry.ts`
- Read: `services/admin/providers/stripeProvider.ts`
- Read: `services/admin/providers/momoProvider.ts`
- Read: `services/admin/providers/vnpayProvider.ts`

**Step 1: Định nghĩa interface**

```typescript
export interface BillingProvider {
  name: string;
  createPaymentIntent(amount: number, currency: string, metadata: object): Promise<{ client_secret: string }>;
  handleWebhook(payload: unknown, signature: string): Promise<{ status: string }>;
}
```

**Step 2: Implement/refactor providers**

**Verification:** Test mỗi provider implements interface.

---

### Task 3.4: Usage metering

**Objective:** Theo dõi usage theo tenant.

**Files:**
- Modify: `supabase/migrations/20250706000001_phase_p2_subscription_usage.sql`
- Create: `services/admin/usageService.ts`

**Step 1: Bảng usage records**

```sql
CREATE TABLE IF NOT EXISTS public.tenant_usage_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  feature_key TEXT NOT NULL,
  quantity NUMERIC NOT NULL DEFAULT 0,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**Step 2: Service**

```typescript
export async function recordUsage(tenantId: string, featureKey: string, quantity: number) { /* ... */ }
export async function getUsageSummary(tenantId: string, featureKey: string) { /* ... */ }
```

**Verification:** Test tổng usage trong kỳ.

---

### Task 3.5: Invoice PDF generation

**Objective:** Tạo PDF hóa đơn từ invoice data.

**Files:**
- Modify: `components/InvoiceManager.tsx`
- Create: `lib/invoicePdf.ts`

**Step 1: Sử dụng jspdf**

```typescript
import { jsPDF } from 'jspdf';

export function generateInvoicePdf(invoice: Invoice): Blob {
  const doc = new jsPDF();
  // header, items, totals
  return doc.output('blob');
}
```

**Step 2: Nút download trong InvoiceManager**

**Verification:** Test tạo PDF và kiểm tra nội dung cơ bản.

---

## Phase 4: Advanced Admin Features

**Objective:** Feature flags, impersonate, API keys, webhooks.

### Task 4.1: Feature Flag service

**Objective:** Đánh giá feature theo plan/tenant/user.

**Files:**
- Create: `services/admin/featureFlagService.ts`
- Read: `supabase/migrations/20260713000009_create_plan_features.sql`

**Step 1: Service**

```typescript
export async function isFeatureEnabled(featureKey: string, context: { tenantId: string; plan: string }) { /* ... */ }
```

**Step 2: Component toggle**

Modify `components/FeaturePicker.tsx` để kết nối service.

**Verification:** Test feature bật/tắt theo plan.

---

### Task 4.2: Impersonation flow

**Objective:** Admin switch session sang user khác với audit log.

**Files:**
- Modify: `components/ImpersonationBanner.tsx`
- Modify: `services/admin/systemAdminService.ts`
- Modify: `pages/admin/AdminDashboardInner.tsx`

**Step 1: Service**

```typescript
export async function startImpersonation(targetUserId: string) { /* store original session, set impersonated session */ }
export async function endImpersonation() { /* restore original session */ }
```

**Step 2: Audit log**

Ghi `impersonation_start` và `impersonation_stop`.

**Verification:** Test start/end impersonation và kiểm tra audit log.

---

### Task 4.3: API Key lifecycle

**Objective:** Create/revoke/rotate API keys.

**Files:**
- Modify: `components/ApiKeyManager.tsx`
- Modify: `services/admin/permissions.ts` (nếu cần)

**Step 1: Service functions**

```typescript
export async function createApiKey(name: string, permissions: string[]) { /* ... */ }
export async function revokeApiKey(id: string) { /* ... */ }
```

**Step 2: UI**

Hiển thị key 1 lần sau khi tạo.

**Verification:** Test revoke key ngăn chặn request.

---

### Task 4.4: Webhook delivery system

**Objective:** Gửi webhook với retry và signature.

**Files:**
- Modify: `components/WebhookManager.tsx`
- Create: `supabase/functions/webhook-delivery/index.ts`

**Step 1: Edge function**

```typescript
// HMAC-SHA256 signature, retry 3 lần với exponential backoff
```

**Step 2: Delivery logs**

Sử dụng `webhook_deliveries` table.

**Verification:** Test failed webhook retry đúng 3 lần.

---

## Phase 5: Operations & Monitoring

**Objective:** Health, queue, cron, backup, restore, storage, DB maintenance.

### Task 5.1: System Health panel data

**Objective:** Thu thập metrics từ Supabase / edge function.

**Files:**
- Modify: `components/SystemHealthPanel.tsx`
- Create: `supabase/functions/system-health/index.ts`

**Step 1: Edge function**

Trả về: cpu_percent, memory_percent, disk_percent, active_connections, edge_function_status.

**Step 2: Component chart**

Dùng recharts hiển thị trends.

**Verification:** Test health API trả về đúng shape.

---

### Task 5.2: Queue Monitor

**Objective:** Hiển thị heavy_ops_jobs queue.

**Files:**
- Modify: `components/ReadReplicaQueueManager.tsx`
- Create: `services/admin/queueService.ts`

**Step 1: Service**

```typescript
export async function getQueueStatus() { /* pending, running, failed counts */ }
export async function retryJob(jobId: string) { /* ... */ }
```

**Verification:** Test retry failed job.

---

### Task 5.3: Cron Monitor

**Objective:** Dashboard cron jobs.

**Files:**
- Create: `components/admin/CronMonitorPanel.tsx`
- Read: `supabase/functions/cron-admin-tasks/`

**Step 1: Service**

```typescript
export async function getCronLogs() { /* from cron_job_logs */ }
```

**Step 2: Component**

Hiển thị last run, next run, success/failure.

**Verification:** Test hiển thị log mới nhất.

---

### Task 5.4: Backup automation

**Objective:** Tự động pg_dump và lưu storage.

**Files:**
- Modify: `components/StorageBackupPanel.tsx`
- Modify: `services/tenantBackupService.ts`

**Step 1: Backup job**

Edge function gọi `pg_dump` qua Supabase management API hoặc scheduled job.

**Step 2: Lưu snapshot metadata**

Sử dụng `tenant_restore_snapshots`.

**Verification:** Test backup tạo ra file và metadata.

---

### Task 5.5: Restore workflow

**Objective:** Restore từ snapshot.

**Files:**
- Modify: `services/tenantRestoreService.ts`
- Create: `components/admin/RestorePanel.tsx`

**Step 1: Validate snapshot**

Kiểm tra checksum, schema version.

**Step 2: Restore flow**

```typescript
export async function restoreTenantFromSnapshot(tenantId: string, snapshotId: string) { /* ... */ }
```

**Verification:** Test restore trên test tenant.

---

### Task 5.6: Database maintenance panel

**Objective:** VACUUM ANALYZE, index rebuild, bloat monitoring.

**Files:**
- Modify: `components/BulkMaintenancePanel.tsx`
- Create: `supabase/functions/db-maintenance/index.ts`

**Step 1: Edge function**

Chạy `VACUUM ANALYZE` hoặc `REINDEX` qua RPC.

**Step 2: Component**

Nút chạy maintenance, hiển thị bloat report.

**Verification:** Test maintenance job ghi log.

---

### Task 5.7: Storage Management panel

**Objective:** Quản lý Supabase Storage buckets, usage stats, cleanup policies.

**Files:**
- Modify: `components/StorageBackupPanel.tsx` (hoặc tách thành `components/admin/StorageManagementPanel.tsx`)
- Create: `services/admin/storageAdminService.ts`

**Step 1: Service**

```typescript
export async function getBuckets() { /* ... */ }
export async function getBucketUsage(bucketId: string) { /* size, object count */ }
export async function setBucketLifecycle(bucketId: string, days: number) { /* cleanup policy */ }
```

**Step 2: Component**

Liệt kê buckets, hiển thị usage bar, cấu hình lifecycle/cleanup policy.

**Verification:**
```bash
npm run test -- tests/admin-dashboard/StorageManagementPanel.test.tsx
```

---

## Phase 6: Communication Services

**Objective:** Email, SMS, support tickets.

### Task 6.1: Email service integration

**Objective:** Gửi email qua Resend/SendGrid hoặc Listmonk.

**Files:**
- Modify: `components/EmailTemplateManager.tsx`
- Create: `supabase/functions/send-email/index.ts`

**Step 1: Edge function**

```typescript
// Nhận template_key, to, variables; render template; gọi Resend API
```

**Step 2: Template variables**

Hỗ trợ `{{user_name}}`, `{{tenant_name}}`, v.v.

**Verification:** Test gửi email với template.

---

### Task 6.2: SMS service integration

**Objective:** Gửi SMS qua local provider.

**Files:**
- Create: `services/admin/smsService.ts`
- Create: `supabase/functions/send-sms/index.ts`

**Step 1: Service**

```typescript
export async function sendSms(to: string, message: string, provider: 'twilio' | 'viettel' | 'vonage') { /* ... */ }
```

**Verification:** Test gửi SMS với provider mock.

---

### Task 6.3: Support ticket system

**Objective:** Hoàn thiện ticket inbox.

**Files:**
- Modify: `components/TicketInbox.tsx`
- Modify: `services/admin/supportService.ts` (nếu chưa có)

**Step 1: CRUD tickets, replies, templates**

```typescript
export async function createTicket(tenantId: string, subject: string, body: string) { /* ... */ }
export async function replyToTicket(ticketId: string, body: string) { /* ... */ }
```

**Step 2: SLA tracking**

Thêm `sla_due_at` vào `support_tickets`.

**Verification:** Test thread reply.

---

## Phase 7: Enterprise & Polish

**Objective:** Subdomain, custom domain, license, SSO, advanced security.

### Task 7.1: Subdomain availability check

**Objective:** Cho phép tenant chọn subdomain.

**Files:**
- Modify: `services/admin/tenantAdminService.ts`
- Create: `components/admin/SubdomainManagerPanel.tsx`

**Step 1: Service**

```typescript
export async function checkSubdomainAvailability(subdomain: string) { /* ... */ }
export async function setTenantSubdomain(tenantId: string, subdomain: string) { /* ... */ }
```

**Verification:** Test subdomain duplicate bị từ chối.

---

### Task 7.2: Custom domain verification

**Objective:** Verify custom domain qua DNS TXT.

**Files:**
- Create: `components/admin/CustomDomainPanel.tsx`
- Create: `supabase/functions/verify-domain/index.ts`

**Step 1: Verification token**

Tạo token, yêu cầu user thêm TXT record.

**Step 2: Edge function verify**

Lookup DNS và cập nhật `domain_verified_at`.

**Verification:** Test verify domain thành công/thất bại.

---

### Task 7.3: License management

**Objective:** Quản lý license key theo business model.

**Files:**
- Create: `components/admin/LicenseManagerPanel.tsx`
- Create: `services/admin/licenseService.ts`
- Create: `supabase/migrations/20250713000023_phase7_licenses.sql`

**Step 1: Schema**

```sql
CREATE TABLE public.licenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id),
  license_key TEXT UNIQUE NOT NULL,
  plan TEXT NOT NULL,
  expires_at TIMESTAMPTZ,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT now()
);
```

**Step 2: Service**

```typescript
export async function generateLicense(tenantId: string, plan: string, expiresAt: string) { /* ... */ }
export async function validateLicense(key: string) { /* ... */ }
```

**Verification:** Test validate license hết hạn.

---

### Task 7.4: Rate limiting & security settings

**Objective:** Thêm rate limit, lockout, session timeout.

**Files:**
- Modify: `services/admin/systemAdminService.ts`
- Read: `supabase/migrations/20250715000003_admin_security_settings.sql`

**Step 1: Service**

```typescript
export async function recordLoginAttempt(email: string, ip: string, success: boolean) { /* ... */ }
export async function updateTenantSessionTimeout(tenantId: string, minutes: number) { /* ... */ }
```

**Step 2: UI**

Tạo `components/admin/SecuritySettingsPanel.tsx`.

**Verification:** Test lockout sau N lần fail.

---

### Task 7.5: Advanced audit export

**Objective:** Export audit log theo filter.

**Files:**
- Create: `components/admin/AuditExportPanel.tsx`
- Modify: `services/admin/auditAdminService.ts`

**Step 1: Service export**

```typescript
export async function exportAuditLogs(filter: object, format: 'csv' | 'json') { /* ... */ }
```

**Step 2: Component**

Chọn date range, action types, format, download.

**Verification:** Test export CSV đúng số dòng.

---

> **Out-of-scope for Phase 7:** SSO/SAML (đề cập trong Plan tổng Phase 7 nhưng không nằm trong 29 tính năng core; xem xét triển khai ở phase sau).

## Cross-Cutting Tasks

### Task C.1: Setup test harness

**Objective:** Có test helpers chuẩn cho admin tests.

**Files:**
- Read: `tests/setup.ts`
- Read: `tests/mocks/supabase.ts`
- Refactor: `tests/test-helpers.ts` (consolidate từ các file trên nếu cần)

**Step 1: Helpers**

```typescript
// ponytail: helpers hiện đang nằm rải rác ở tests/setup.ts và tests/mocks/supabase.ts
export async function createTestTenant(slug: string) { /* ... */ }
export async function createTestUser(tenantId: string, role?: string) { /* ... */ }
export function getClientForUser(user: User) { /* ... */ }
```

**Verification:** `npx vitest run tests/integration/tenant-isolation.test.ts` PASS.

---

### Task C.2: Define admin permission constants

**Objective:** Chuẩn hóa permissions.

**Files:**
- Modify: `services/admin/permissions.ts`

**Step 1: Constants**

```typescript
export const ADMIN_PERMISSIONS = {
  TENANT_READ: 'tenant:read',
  TENANT_WRITE: 'tenant:write',
  BILLING_READ: 'billing:read',
  BILLING_WRITE: 'billing:write',
  // ...
} as const;
```

**Verification:** Không có hard-coded permission string ở các file khác.

---

### Task C.3: Documentation of open-source references

**Objective:** Ghi lại nguồn tham khảo để tránh vấn đề license.

**Files:**
- Create: `docs/opensource-references.md`

**Step 1: Ghi danh sách**

Liệt kê repo, license, phần tham khảo, cách implement lại.

**Verification:** Review file với team.

---

## Risks, Tradeoffs, and Open Questions

| Risk | Mitigation |
|------|------------|
| AGPL/GPL code accidentally copied | Code review + `docs/opensource-references.md` |
| RLS leak after schema changes | Mỗi migration mới phải có RLS test |
| Bundle chunk too large | Lazy-load panels > 50 kB |
| Webhook retry storm | Max 3 retries, exponential backoff, circuit breaker |
| Payment idempotency failure | Always send `Idempotency-Key` |

**Open Questions:**
1. Có cần self-host Listmonk hay chỉ dùng Resend/SendGrid?
2. Custom domain SSL dùng Supabase hay Cloudflare?
3. SSO/SAML đã ghi rõ ngoài scope Phase 7 — cần lập plan riêng nếu triển khai.

---

## Verification Checklist (Per Phase)

- [ ] `npm run lint` passes
- [ ] `npm run test` passes
- [ ] `npm run build` passes
- [ ] `npm run audit:rpc` passes
- [ ] New RLS policies tested with multi-tenant isolation
- [ ] Lazy-loaded panels verified in network tab
- [ ] Audit log events recorded for security-sensitive actions

---

## Execution Handoff

Plan complete and saved. Ready to execute using subagent-driven-development — I'll dispatch a fresh subagent per task with two-stage review (spec compliance then code quality). Shall I proceed?
