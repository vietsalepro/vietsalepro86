# VietSalePro — Codebase Semantic Memory

> **Status**: READ-ONLY knowledge base. Built 2026-07-23 from commit `ec0f317b`.
> **Graph**: codebase-memory MCP project `vietsalepro` — 28,881 nodes / 42,874 edges, indexed in `full` mode.
> **Purpose**: Enable future sessions to answer architecture, business, and code-flow questions without rescanning.

---

## 0. Program Summary

VietSalePro is a **multi-tenant SaaS POS + inventory + retail-management platform** for the Vietnamese SMB market. It is a single-page React 19 + Vite 6 + TypeScript frontend backed by Supabase (Postgres 17 + Auth + Storage + Realtime + Edge Functions) and deployed on Vercel.

The product has two distinct surfaces sharing one codebase:
1. **Tenant app** — per-tenant retail workflow (POS, catalog, inventory, customers, suppliers, returns, reports) resolved by subdomain/custom domain.
2. **Admin platform** — system-admin-only SaaS control plane (tenants, members, billing, audit, security, health, analytics, compliance) at the `admin` subdomain.

Business domain is Vietnamese retail: dairy/baby-goods default seed, VND currency, Vietnamese-language UI, e-invoice providers (Sapo/m-Invoice/VNPT/Viettel), Vietnamese payment providers (Momo, VNPay, bank transfer) plus Stripe.

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  Vercel SPA (React 19 + Vite 6 + Tailwind 4 + PWA)              │
│  App.tsx (router) → AppShell/AppTopbar | MobileLayout | Admin   │
│  contexts: AuthContext, TenantContext                            │
│  hooks: usePOS, useReturnOrder, useBarcodeCapture, usePermissions│
└────────────┬────────────────────────────────────┬───────────────┘
             │ supabase-js (anon key)             │ Edge Function fetch
             ▼                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  Supabase Project (rsialbfjswnrkzcxarnj)                         │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐ │
│  │ Postgres 17  │  │ Auth (JWT)   │  │ Edge Functions (Deno)  │ │
│  │ 70+ tables   │  │ MFA/TOTP     │  │ 29 functions + 6 shared│ │
│  │ 100+ RPCs    │  │ Email OTP    │  │ Tenant lifecycle       │ │
│  │ RLS per      │  │              │  │ Auth/Security          │ │
│  │   tenant_id  │  │              │  │ Email/SMS/Billing      │ │
│  │ Triggers     │  │              │  │ System Admin/Ops       │ │
│  └──────────────┘  └──────────────┘  └────────────────────────┘ │
│  ┌──────────────┐  ┌──────────────┐                             │
│  │ Storage      │  │ Realtime     │                             │
│  │ tenant-assets│  │ admin_events │                             │
│  └──────────────┘  └──────────────┘                             │
└─────────────────────────────────────────────────────────────────┘
```

**Key architectural intent:**
- **Tenant isolation by subdomain** — `getSubdomain()` from `lib/tenant.ts` resolves tenant via `get_tenant_by_subdomain` RPC; tenant_id injected into every Supabase request via `x-tenant-id` header (`tenantFetch` in `lib/supabase.ts`).
- **RLS is the security boundary** — every tenant-scoped table enforces `tenant_id = current_tenant_id() OR is_system_admin()`. `current_tenant_id()` reads the header.
- **RPCs for atomicity** — every multi-step business mutation (checkout, return, exchange, disposal, import delete, invoice, payment) is a SECURITY DEFINER RPC to guarantee atomicity and stock correctness.
- **Edge Functions for privileged/cross-cutting ops** — service_role key operations (tenant create/delete, user create/delete, 2FA override, email/SMS send, billing webhooks, cron tasks) that can't run from the anon-key client.
- **Legacy fallbacks** — `_legacy*` functions in supabaseService.ts provide non-atomic paths if a migration wasn't applied (defensive backward compat).

---

## 2. Knowledge Graph Inventory

**Indexed via codebase-memory MCP** — project name `vietsalepro`, mode `full`, persistence artifact at `.codebase-memory/graph.db.zst` (7.8MB compressed / 43MB original).

| Layer | Count | Source |
|---|---|---|
| Graph nodes | 28,881 | artifact.json |
| Graph edges | 42,874 | artifact.json |
| Migrations | 137 SQL files | supabase/migrations/ |
| Edge functions | 29 (+ 6 shared helpers) | supabase/functions/ |
| Service files | 31 root + 11 admin + 4 providers | services/ |
| Page components | 38 tenant + 16 admin | pages/ |
| UI components | ~140 | components/ |
| Hooks | 11 | hooks/ |
| Contexts | 2 (Auth, Tenant) | contexts/ |
| Types files | 7 (types.ts + types/*) | types/ + types.ts |
| Utils | 14 | utils/ |
| Tests | 67 files | tests/ |
| RPC contracts documented | 100+ | docs/admin-dashboard/RPC_CONTRACTS.md |

**Graph queryability:** `search_graph` (BM25 + name_pattern + semantic), `query_graph` (Cypher), `trace_path` (calls/data_flow/cross_service) are all operational against the indexed project. Labels available: Function, Method, Class, Interface, Route, Variable, Module, Package, File, Folder.

---

## 3. Business Modules & Responsibilities

### 3.1 Tenant App Modules

| Module | Pages | Primary Service | Key RPCs |
|---|---|---|---|
| **Dashboard** | Dashboard | supabaseService.getDashboardSummary | — |
| **Catalog** | Products, BrandManagement, CategoryManagement | supabaseService (CRUD + filter_products_rpc) | check_product_code_exists, check_product_barcode_exists, filter_products_paginated |
| **Inventory** | InventoryCount, StockLedger | supabaseService | complete_inventory_count, cancel_inventory_count_rpc, check_stock_ledger_drift, backfill_stock_ledger_v2 |
| **POS/Checkout** | POS, MobilePOS | usePOS hook → supabaseService.pushCheckout | create_order (RPC), process_checkout_tenant (edge) |
| **Orders** | Orders, MobileOrders | supabaseService | get_orders_paginated, cancel_order, delete_order, pay_order_debt |
| **Returns** | ReturnOrders | useReturnOrder hook → supabaseService | create_return_order, cancel_return_order_v2, create_exchange_transaction |
| **Import/Purchasing** | ImportGoods | supabaseService | create_import_receipt, delete_import_v2, pay_supplier_debt, filter_import_receipts_paginated |
| **Suppliers** | Suppliers | supabaseService | search_suppliers_rpc, filter_suppliers_paginated, adjust_supplier_debt |
| **Disposals** | Disposals, DisposalForm | supabaseService | complete_disposal, delete_disposal_with_restore, get_disposal_auto_code |
| **Supplier Exchanges** | SupplierExchanges | supabaseService | create_supplier_exchange, update_supplier_exchange, cancel_supplier_exchange |
| **Customers/Loyalty** | Customers, MobileCustomers | supabaseService + rankingEngine | filter_customers_rpc, adjust_customer_debt, adjust_customer_points, get_next_customer_code |
| **Promotions/Vouchers** | (in POS/Orders) | promotionService + promotionUtils | apply_voucher_to_invoice |
| **Reports** | Reports | supabaseService | getDashboardSummary, getCategoryProductCounts |
| **Settings** | Settings, Profile | supabaseService | getSettings, saveSettings |
| **Audit** | AuditLog | auditService | writeAuditLog (edge), getAuditLogs |
| **Members** | MemberManagement | tenantService | invite_tenant_member, remove_tenant_member, update_tenant_member_role, toggle_tenant_member_active |
| **Tax** | TaxCalculation | (client-side) | — |

### 3.2 Admin Platform Modules

| Module | Pages | Primary Service | Key RPCs |
|---|---|---|---|
| **Overview** | Overview | tenantService | get_system_overview, get_top_tenants, get_tenant_growth |
| **Tenants** | Tenants, TenantDetail | tenantService + admin/tenantAdminService | search_tenants, get_tenants_admin, update_tenant, delete_tenant_safe, set_tenant_subdomain, get_or_create_custom_domain_token |
| **Members** | Members | admin/memberAdminService | search_members, get_tenant_members_with_email, accept_invitation |
| **Billing** | Billing, BillingInvoices, BillingPayments | invoiceService + billingAutomationService | create_invoice, confirm_payment, get_revenue_metrics, get_churn_cohort_metrics, get_billing_automation_status |
| **Audit** | Audit | admin/auditAdminService | get_admin_audit_logs |
| **Security** | Security | systemAdminService + admin/SecuritySettingsPanel | get_tenant_security_settings, update_tenant_ip_allowlist, get_login_attempts, get_locked_emails |
| **Health** | Health | systemHealthService + admin-health-check (edge) | get_connection_pool_stats, Supabase Metrics API |
| **Analytics** | Analytics | admin/analyticsAdminService | get_revenue_metrics, get_churn_cohort_metrics |
| **Compliance** | Compliance | complianceService + admin/complianceAdminService | export_tenant_data, gdpr_export_user_data, gdpr_delete_user_data, create_gdpr_request |
| **Onboarding** | Onboarding | (UI flow) | create_tenant_with_admin (via create-tenant edge) |
| **Settings** | Settings | (system_settings) | get_global_config, set_global_config |
| **Invitations** | InvitationsAccept | admin/memberAdminService | accept_invitation |

---

## 4. Cross-Module Relationship Map (Knowledge Graph)

### 4.1 Tenant Lifecycle Workflow
```
UI: Onboarding/LandingPage
  → Edge: create-tenant (system_admin auth)
    → RPC: get_default_plan_limit_values
    → Auth: admin.createUser (temp password)
    → Tables: tenants, tenant_subscriptions, tenant_memberships, tenant_credentials
    → Edge: send-invitation-email (via Resend)
    → Table: app_audit_log
```

### 4.2 POS Checkout Workflow (the critical path)
```
UI: POS.tsx / MobilePOS.tsx
  → Hook: usePOS (cart state, lot selection, promotion calc)
  → Utils: promotionUtils.calculatePromotionDiscount, lotUtils.selectBestLotForQuantity
  → Service: supabaseService.pushCheckout
    → RPC: create_order (atomic: order + items + stock decrement + points + ledger)
  OR (offline):
    → Utils: offlineManager.offlineQueue
    → Service: supabaseService.syncOfflineQueue → _legacyPushCheckout (fallback)
  OR (server-side atomic via edge):
    → Edge: process-checkout (tenant member auth, rate-limited)
      → RPC: process_checkout_tenant
```

### 4.3 Return + Exchange Workflow
```
UI: ReturnOrders.tsx
  → Hook: useReturnOrder (fee calc, exchange items)
  → Utils: returnFeeEngine.computeReturnFee
  → Service: supabaseService.createExchangeTransaction
    → RPC: create_exchange_transaction (atomic: return + optional new order + stock restore + debt/credit + ledger)
  OR (return only):
    → RPC: create_return_order
  Cancel:
    → RPC: cancel_return_order_v2
```

### 4.4 Member Invitation Workflow
```
UI: MemberManagement.tsx (tenant admin)
  → Service: tenantService.inviteMemberByEmail
    → Edge: invite-member (system_admin or tenant_admin)
      → RPC: get_user_by_email (find existing)
      → Auth: admin.createUser (if new) + admin.generateLink (magiclink/recovery)
      → Table: tenant_memberships (status='pending')
      → Edge: send-invitation-email
      → Table: app_audit_log, rate_limit_logs
  Accept:
    → UI: InvitationsAccept.tsx
    → Service: admin/memberAdminService.acceptInvite
      → RPC: accept_invitation (token-based)
```

### 4.5 Billing Workflow
```
Invoice creation:
  UI: InvoiceCreator → invoiceService.createInvoice → RPC: create_invoice
Payment:
  UI: InvoicePaymentConfirm → invoiceService.confirmPayment → RPC: confirm_payment
  OR external: Edge billing-webhooks (Stripe/Momo/VNPay/bank_transfer) → audit_log
Reminders:
  Cron: Edge cron-admin-tasks (job='billing_reminders')
    → Query: tenant_subscriptions (expiring in 7 days)
    → Edge: send-template-email
    → Table: billing_reminder_logs
Revenue analytics:
  UI: Analytics/Billing → billingAutomationService → RPCs: get_revenue_metrics, get_churn_cohort_metrics
```

### 4.6 Audit Logging (dual system)
```
Business audit (tenant-scoped):
  DB triggers: trg_audit_log_orders, trg_audit_log_products, etc. → app_audit_log
  Manual events: auditService.writeAuditLog → Edge: audit-log → app_audit_log
Admin audit (platform-scoped):
  DB triggers: audit_log_trigger_system_admins, audit_log_trigger_invitations, audit_log_trigger_licenses → audit_log
  Read: admin/auditAdminService.getAdminAuditLogs → RPC: get_admin_audit_logs
```

### 4.7 Permission/Authorization Flow
```
Frontend:
  contexts/AuthContext → user, mfaPending
  contexts/TenantContext → tenant, membership, role (via get_tenant_by_subdomain RPC)
  lib/permissions.ts → isSystemAdmin (RPC), hasTenantRole (RPC), canUseFeature (RPC)
  hooks/usePermissions → canCreateOrder, canManageInventory, etc. (client-side role matrix)
Backend:
  RLS: tenant_id = current_tenant_id() OR is_system_admin()
  Edge _shared/permissions.ts: checkIsSystemAdmin, checkIsTenantAdmin, checkIsTenantOwner
  DB helpers: is_system_admin(), is_tenant_member(), is_tenant_admin(), has_tenant_role(), is_tenant_owner()
```

---

## 5. Database Schema Summary

### 5.1 Tables by Domain (70+ total)

**Tenant/Core (11):** tenants, tenant_memberships, tenant_subscriptions, tenant_api_keys, tenant_webhooks, tenant_credentials, invitations, tenant_registration_events, system_admins, admin_roles, admin_role_assignments

**Catalog (4):** products, categories, brands, product_lots

**Inventory (8):** inventory_counts, inventory_count_items, inventory_movements, stock_movements, import_receipts, import_items, disposals, disposal_items

**Sales (6):** orders, order_items, orders_archive, order_items_archive, return_orders, return_order_items

**Customers/Loyalty (10):** customers, customer_payment_ledger, point_history, rank_configs, rank_history, rewards, promo_codes, promo_code_usages, promotions, promotion_rules

**Suppliers (5):** suppliers, supplier_payment_ledger, supplier_exchanges, supplier_exchange_received_items, supplier_exchange_return_items

**Billing (13):** invoices, invoice_items, invoice_number_counters, invoice_reminder_logs, payments, billing_job_logs, billing_email_logs, billing_reminder_logs, plans, plan_features, licenses, tenant_usage_records, bank_accounts

**Admin/Platform (13):** system_settings, app_settings, app_audit_log, app_audit_log_partitioned, audit_log, admin_events, cron_job_logs, maintenance_windows, error_logs, rate_limit_logs, heavy_ops_jobs, processed_operations, db_maintenance_jobs

**Security/Audit (7):** admin_login_history, login_attempts, admin_2fa_backup_codes, admin_2fa_backup_code_attempts, gdpr_requests, gdpr_deletion_logs, terms_acceptance

**Other (8):** support_tickets, ticket_replies, ticket_reply_templates, announcements, notification_logs, partners, integrations, webhook_deliveries, tenant_restore_snapshots, tenant_backup_jobs, fraud_queue, email_templates

### 5.2 RPC Functions (100+)

Grouped by domain — see §3 for service→RPC mapping and `docs/admin-dashboard/RPC_CONTRACTS.md` for the canonical contract table. Notable patterns:
- **SECURITY DEFINER** for privileged ops (tenant create/delete, user management, billing, GDPR)
- **SECURITY INVOKER** for read RPCs (Wave04 canonical: get_tenant_subscription, get_user_accounts)
- **Helper functions** (SECURITY INVOKER): current_tenant_id, is_system_admin, is_tenant_member, calc_qty_after_transaction, sync_product_quantity_from_lots, insert_stock_ledger_entry

### 5.3 RLS Policy Pattern
```sql
-- Standard tenant-scoped table
CREATE POLICY ON products FOR SELECT TO authenticated
  USING (tenant_id = current_tenant_id() OR is_system_admin());
-- System-admin-only table
CREATE POLICY ON system_admins FOR ALL TO authenticated
  USING (is_system_admin()) WITH CHECK (is_system_admin());
```
70+ tables have RLS enabled. `service_role` bypasses RLS for edge functions.

### 5.4 Triggers
- **Audit**: write_audit_log + per-table triggers (orders, products, import_receipts, disposals, app_settings, tenants, tenant_memberships, tenant_subscriptions, system_admins, invitations, licenses)
- **User tracking**: set_tenant_record_user_tracking (created_by/updated_by)
- **Guardrails**: tenants_before_delete_guardrail, tenant_memberships_guardrails (seat limits), support_tickets_update_guard
- **Tenant limits**: trg_check_tenant_user_limit, trg_check_tenant_product_limit, trg_check_tenant_order_limit
- **Business**: trg_orders_set_order_code (auto order_code from id)
- **updated_at**: standard maintenance triggers

### 5.5 Enums/Types
- `tenant_role` enum: owner, admin, member, viewer
- `invitation_status` enum: pending, accepted, expired, revoked
- Check constraints: tenants.status, tenants.isolation_mode, tenants.plan, payments.payment_method/status, invoices.status, disposals.status, announcements.status/target_type, app_audit_log.action, billing_job_logs.status, heavy_ops_jobs.status, admin_login_history.status, admin_roles.permissions

### 5.6 Migration Evolution (137 migrations, 2025-07 to 2026-08)
1. **Baseline** (20250703) — F26 full schema recreation
2. **Phase 2-5** (20250704-05) — Multi-tenancy foundation: tenants table, tenant_id on all business tables, backfill, RLS policies, unique indexes
3. **Phase 7-11** (20250705) — Subscription limits, admin dashboard RPCs, audit triggers
4. **Phase P1-P17** (20250706-09) — Platform features: tenant management, subscription usage, members, analytics, audit, billing schema, invoices, payments, plans, feature flags, reminders, vouchers, tickets, impersonation, announcements, email templates, notifications, error/performance, storage/backup, maintenance, API keys, webhooks, integrations, revenue/churn, 2FA, login history, GDPR, fraud
5. **Phase P18** (20260708) — Advanced: tenant isolation modes, white-label, read replica queue
6. **F33 series** (20260710-12) — Member management foundation, guardrails, rate limiting, status activation, fixes
7. **SP series** (20260712-13) — Usage metering, missing RLS, audit event types, announcements, custom domains, global config, licenses, user/role management RPCs, plans CRUD, DB maintenance
8. **Wave02-04** (20260729-20260801) — Canonical read RPCs, audit triggers, security context (SECURITY DEFINER), service-layer permissions, edge audit, canonical read RPCs
9. **G1** (20260723) — max_storage_gb on tenant_subscriptions

---

## 6. Edge Functions (29 + 6 shared)

### 6.1 Shared Helpers (`_shared/`)
- **permissions.ts** — checkIsSystemAdmin, checkIsTenantAdmin, checkIsTenantOwner, checkHasTenantRole + role constants
- **email.ts** — renderTemplate, wrapWithBrand (logo + brand color + signature)
- **sms.ts** — normalizePhone (E.164), TwilioSmsProvider factory
- **domain-verification.ts** — isValidDomain, generateVerificationToken, parseTxtRecords (Google DNS), findVerificationToken
- **systemHealth.ts** — parseProjectRef, fetchSupabaseMetrics (Prometheus), buildResourceMetrics (CPU/mem/disk %)
- **webhookDelivery.ts** — deliverWebhook (retry 1-5x, 1s backoff, 30s timeout), signPayload (HMAC-SHA256)

### 6.2 Edge Functions by Domain

| Domain | Function | Auth | Purpose |
|---|---|---|---|
| **Tenant lifecycle** | create-tenant | system_admin | Create tenant + admin user + subscription + membership |
| | delete-tenant | system_admin or tenant_owner | Soft/hard delete tenant with cascade |
| | tenant-backup | system_admin | Export tenant data to JSON |
| | tenant-restore | system_admin | Restore tenant from backup JSON |
| **Auth/Security** | admin-2fa-override | system_admin (caller + approver) | Emergency 2FA disable (dual approval) |
| | create-system-admin | system_admin | Create new system admin user |
| | delete-user | system_admin | Delete auth user if no memberships |
| | impersonate-tenant | system_admin | Create temp admin membership (1h expiry) |
| | end-impersonation | system_admin | End active impersonation sessions |
| | reset-password | system_admin or tenant_admin | Send password reset link |
| **Email/Notifications** | send-email | service_role or system_admin | Generic template email (Resend) |
| | send-template-email | service_role or system_admin | Branded template email |
| | send-invitation-email | system_admin or tenant_admin | Tenant member invitation email |
| | send-billing-email | internal secret or service_role | Billing reminder/confirmation email |
| | send-ticket-email | service_role or system_admin | Support ticket notification email |
| | send-sms | service_role or system_admin | SMS via Twilio |
| | invite-member | system_admin or tenant_admin | Invite user (create if new) + send email |
| **Billing** | billing-webhooks | webhook key or provider signature | Route Stripe/Momo/VNPay/bank_transfer webhooks |
| | process-checkout | tenant_member | Atomic POS checkout via process_checkout_tenant RPC |
| **System Admin/Ops** | admin-health-check | public (service_role internal) | External health endpoint for monitoring |
| | system-health | system_admin | Comprehensive health + resource metrics |
| | system-backup | system_admin | Supabase backup status via Management API |
| | db-maintenance | system_admin | Vacuum/reindex/bloat/index stats |
| | cron-admin-tasks | internal secret or service_role | Cron worker: billing_reminders, audit_cleanup |
| | error-performance | system_admin | Error log summary + query performance metrics |
| **Webhooks** | webhook-delivery | internal secret or service_role | Deliver pending webhooks with retry |
| **Domains** | check-subdomain | public (rate-limited) | Check subdomain availability |
| | verify-domain | system_admin or tenant_admin | Custom domain DNS TXT verification |
| **Audit/Logging** | audit-log | any authenticated user | Centralized audit log + rate limiting service |

### 6.3 verify_jwt Settings (config.toml)
- `verify_jwt = false`: send-billing-email, send-ticket-email, billing-webhooks, cron-admin-tasks, check-subdomain
- All others: default (verify_jwt = true)

---

## 7. Services Layer

### 7.1 supabaseService.ts (147KB — the god-service)
~150+ exported functions covering all tenant-app business operations. Mix of direct CRUD (`supabase.from(...)`) and RPC calls (`supabase.rpc(...)`). Contains `_legacy*` fallbacks for checkout, deleteOrder, createReturnOrder (non-atomic, used if migrations not applied).

### 7.2 Other Root Services (31 files)
- **tenantService.ts** (33KB) — tenant/membership/subscription/usage management (heavy RPC user)
- **systemAdminService.ts** — system admin CRUD, security settings, rate limiting
- **twoFactorService.ts** — TOTP enrollment/verification, backup codes, 2FA override
- **invoiceService.ts** — invoice creation, payment confirmation, billing email
- **promotionService.ts** — promo codes and promotion rules CRUD
- **billingAutomationService.ts** — billing status, revenue/churn metrics
- **webhookService.ts** — tenant webhook config + delivery
- **integrationService.ts** — partners + integrations
- **auditService.ts** — manual audit log writes (via edge) + reads
- **announcementService, apiKeyService, bankAccountService, billingReminderService, complianceService, cronJobService, emailTemplateService, errorPerformanceService, fraudRetentionService, heavyOpsQueueService, loginHistoryService, maintenanceService, notificationService, operationsService, planService, subscriptionService, systemBackupService, systemHealthService, tenantBackupService, tenantMigrationService, tenantRestoreService, ticketService**

### 7.3 Admin Services (services/admin/)
- **tenantAdminService.ts** — tenant admin operations (subdomain, custom domain, user accounts)
- **memberAdminService.ts** — member management, invitation acceptance
- **auditAdminService.ts** — admin audit log reads
- **billingAdminService.ts** — billing admin operations
- **complianceAdminService.ts** — GDPR export/delete
- **analyticsAdminService.ts** — revenue/churn analytics
- **licenseService.ts** — license key generation
- **supportService.ts** — support tickets + replies + templates + SLA
- **smsService.ts** — SMS service
- **systemAdminService.ts** — system admin service (admin variant)
- **billingProviderRegistry.ts** — billing provider factory
- **providers/** — stripeProvider, vnpayProvider, momoProvider, bankTransferProvider (all stub implementations)

---

## 8. UI/Routing/State

### 8.1 Routing (App.tsx, 1767 lines)
- **Public**: `/` (context redirect), `/gioi-thieu` (LandingPage), `/admin/invitations/accept`
- **Tenant desktop** (auth + membership): `/tong-quan`, `/products`, `/brands`, `/categories`, `/inventory-count`, `/stock-ledger`, `/inventory/disposals`, `/inventory/supplier-exchanges`, `/pos`, `/orders`, `/return-orders`, `/tax`, `/import`, `/suppliers`, `/customers`, `/reports`, `/audit-log`, `/settings`, `/profile`, `/members`
- **Tenant mobile** (below lg): MobileHome, MobilePOS, MobileOrders, MobileCustomers, MobileInventory + MobileLayout wrapper + BottomNav
- **Admin** (auth + system_admin, lazy-loaded): `/admin/overview`, `/admin/tenants`, `/admin/tenants/:id`, `/admin/members`, `/admin/billing`, `/admin/billing/invoices`, `/admin/billing/payments`, `/admin/audit`, `/admin/settings`, `/admin/security`, `/admin/health`, `/admin/analytics`, `/admin/compliance`, `/admin/onboarding`

### 8.2 State
- **AuthContext** — session, user, signOut, loading, mfaPending, setMfaPending. Listens to onAuthStateChange, records admin login history, activates membership on sign-in.
- **TenantContext** — tenant, membership, role, isLoading, isReadOnly, isImpersonating, impersonatedBy. Resolves via get_tenant_by_subdomain RPC, sets setCurrentTenantId for RLS.

### 8.3 Hooks
- **usePOS** (30KB) — cart state machine, product/customer search, promotions, payments, lot selection, checkout
- **useReturnOrder** (24KB) — return creation, fee calc, pagination, filters, atomic exchange
- **useBarcodeCapture** — HID barcode scanner detection via keystroke timing
- **usePermissions** — client-side role permission matrix
- **useAdminFeatureFlags** — tenant feature flags
- **useAdminList** — generic paginated admin list
- **useAdminRealtime** — admin_events realtime subscription
- **useConfirmDialog, useDebounce, useClickOutside, useTenant** — utilities

### 8.4 Feature Flags (features.ts)
All 27 flags currently `true` (incremental UI rollout flags: useNewAppShell, useNewDataGrid*, useRefactored*Modal, etc.)

---

## 9. Deployment & Config

### 9.1 Frontend (Vercel)
- **vercel.json**: SPA rewrite `/(.*) → /index.html`
- **_redirects**: Netlify-style SPA fallback
- **vite.config.ts**: port 3000, PWA plugin (prompt updates, Workbox caching), manual chunks (vendor-core, vendor-icons, vendor-motion, vendor-charts, vendor-supabase, vendor-xlsx, vendor-qrcode, app-services, page-specific)
- **Env vars** (from lib/supabase.ts): `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`
- **Auth site_url**: `https://master.vietsalepro.com`, redirect URLs: `https://*.vietsalepro.com`

### 9.2 Backend (Supabase)
- **project_id**: rsialbfjswnrkzcxarnj
- **DB**: Postgres 17, port 54322, migrations enabled, seed enabled (seed.sql)
- **API**: port 54321, schemas public + graphql_public, max_rows 1000, auto_expose_new_tables disabled
- **Auth**: signup disabled, anonymous disabled, email confirmation required, MFA TOTP enabled, JWT expiry 1h, refresh token rotation enabled
- **Storage**: enabled, 50MiB limit, S3 protocol enabled, bucket `tenant-assets`
- **Realtime**: enabled (admin_events table)
- **Edge Functions**: 29 deployed, 5 with verify_jwt=false (see §6.3)

### 9.3 External Integrations
- **Resend** (email) — RESEND_API_KEY
- **Twilio** (SMS) — SUPABASE_AUTH_SMS_TWILIO_AUTH_TOKEN
- **Stripe/Momo/VNPay/bank_transfer** (billing) — provider-specific webhook secrets
- **Supabase Metrics API** (system health) — SUPABASE_PROJECT_REF, SUPABASE_MANAGEMENT_TOKEN
- **Google DNS API** (domain verification)

---

## 10. Tests & Governance

### 10.1 Tests (67 files)
- **Unit/Component** (vitest + jsdom): tests/admin-dashboard/* (16 files), tests/components/, tests/services/
- **Integration**: tests/integration/ (tenant isolation, system admin creation)
- **Smoke**: tests/smoke/ (28 files covering P2-P18 features, RBAC, offline, subscription, member management)
- **Edge function tests**: tests/edge-functions/ (delete-tenant regression, domain-verification, send-sms)
- **DB tests (pgTAP)**: supabase/tests/admin/ (audit_log, billing, helper functions, RLS policies)
- **Mocks**: tests/mocks/supabase.ts (325KB comprehensive mock)

### 10.2 Governance Docs
- **docs/admin-dashboard/**: RPC_CONTRACTS.md, runbooks (DISASTER_RECOVERY, INCIDENT_RESPONSE, KEY_ROTATION, MIGRATION, MONITORING, ROLLBACK), deployment/remediation plans
- **Root**: 80+ governance MD files (PRODUCTION_DEPLOYMENT_PROGRAM_CHARTER, RELEASE_CERTIFICATION, BUSINESS_ACCEPTANCE_RECORD, etc.) — extensive production deployment program documentation

### 10.3 Build/Verify Commands
- `npm run dev` — Vite dev server
- `npm run build` — Vite build
- `npm run lint` — `tsc --noEmit`
- `npm run test` — Vitest
- `npm run audit:rpc` — `npx tsx scripts/audit-rpc-contracts.ts`
- `npm run pre-commit` — lint + test + build + audit:rpc

---

## 11. Confidence Level & Gaps

### Confidence: **HIGH** for architecture, modules, DB schema, edge functions, services, routing.
### Confidence: **MEDIUM** for component-level internals (140+ components categorized but not individually read).

### Not Indexed / Gaps
1. **Individual component internals** — 140+ components in components/ were categorized by folder/name only, not read individually. The graph indexes their functions/methods but semantic intent per component is inferred from naming.
2. **supabaseService.ts function bodies** — 150+ functions documented by name + RPC/CRUD classification from RPC_CONTRACTS.md and graph metadata; individual function bodies not all read.
3. **supabase/schema.sql** (1.38MB) — not read directly; schema inferred from migrations (which are the source of truth).
4. **Root governance MD files** (80+) — listed but content not indexed; they document the production deployment program history.
5. **archive/experiments/frappe-docker** — present in repo (graph shows Route noise from it) but out of scope for VietSalePro semantic memory.
6. **scripts/** — `audit-rpc-contracts.ts` and other scripts not individually documented.
7. **Actual .env values** — not read (correctly, for security). Env var names inferred from lib/supabase.ts and config.toml.
8. **Edge function deployment state** — config.toml shows local config; production verify_jwt settings may differ (governance docs reference production deployments).

### Graph Limitations
- Cypher `labels(n)` and `keys(n)` returned aggregate counts rather than per-label breakdowns (MCP quirk); label distribution inferred from `search_graph` with label filter + file_pattern.
- Route nodes include noise from `archive/experiments/frappe-docker` (17 Route nodes, most irrelevant).

---

## 12. How to Use This Memory

Future sessions can query the codebase-memory MCP graph directly:
- **Find a function**: `search_graph(query="checkout", project="vietsalepro")`
- **Find callers of an RPC**: `trace_path(function_name="create_order", mode="calls", direction="inbound")`
- **Cross-service trace**: `trace_path(mode="cross_service")` for edge→DB flows
- **Cypher queries**: `query_graph(query="MATCH (f:Function) WHERE f.file_path STARTS WITH 'services/' RETURN ...")`

This SEMANTIC_MEMORY.md provides the business intent, module responsibilities, and cross-module relationships that the graph alone (which is structural) doesn't capture. Use both together.
