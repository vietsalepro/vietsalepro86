# KẾ HOẠCH TỔNG THỂ: THAM KHẢO MÃ NGUỒN MỞ CHO ADMIN DASHBOARD CỦA VIETSALEPRO

> Mục đích: Tìm kiếm, đánh giá và đề xuất các dự án mã nguồn mở phù hợp để tham khảo phát triển đầy đủ, chính xác hơn các tính năng admin dashboard của VietSalePro.
> Thời điểm lập kế hoạch: 2026-07-12
> Người lập: Devin AI Assistant
> Đường dẫn file: `C:\Users\SUACAUBA\Downloads\Project\vietsale-pro-v7\Plan\PLAN_AdminDashboard_OpenSource_Reference.md`

---

## 1. TỔNG QUAN CHIẾN LƯỢC

### 1.1. Thực tế quan trọng

**Không tồn tại một dự án mã nguồn mở duy nhất nào cover đầy đủ toàn bộ 28 nhóm tính năng mà VietSalePro yêu cầu.**
Các dự án mã nguồn mở thường:
- Hoặc là **boilerplate / starter kit** (mạnh ở auth, multi-tenancy, billing cơ bản nhưng thiếu monitor, queue, cron, backup...)
- Hoặc là **sản phẩm chuyên biệt** (mạnh ở 1-2 domain như billing, feature flags, webhooks, email...)

Do đó, cách tiếp cận đúng là: **xây dựng một stack tham khảo kết hợp nhiều dự án**, chia theo từng domain tính năng.

### 1.2. Nguyên tắc chọn lựa

1. Ưu tiên các dự án có **stack tương đồng** với VietSalePro hiện tại (Supabase, PostgreSQL, React, TypeScript).
2. Ưu tiên các dự án có **database migrations rõ ràng** và **edge functions / API patterns** sạch sẽ.
3. Ưu tiên các dự án có **admin dashboard UI/UX hoàn chỉnh**, có thể tham khảo layout, navigation, data tables, forms.
4. Phân biệt rõ **license**: MIT/Apache/BSD cho phép tham khảo thoải mái; AGPL cần cẩn trọng, không copy code trực tiếp vào sản phẩm proprietary.
5. Mỗi tính năng cần có ít nhất 1-2 dự án tham khảo cụ thể.

### 1.3. Bối cảnh kỹ thuật hiện tại của VietSalePro

Theo `package.json` và `README.md`:
- **Frontend**: Vite + React 19 + React Router DOM + TypeScript + Tailwind CSS 4
- **Backend/Data**: Supabase (PostgreSQL + Auth + Storage + Edge Functions)
- **UI Components**: Tự xây dựng (dùng lucide-react, recharts)
- **Testing**: Vitest
- **Tính chất**: Proprietary, không phải open-source project

→ Các dự án Next.js vẫn có thể tham khảo về **database schema, migration, edge function, auth flow, admin patterns**, nhưng UI components cần adapt sang React + Vite.

---

## 2. BẢNG TỔNG HỢP 28 TÍNH NĂNG VÀ DỰ ÁN THAM KHẢO TƯƠNG ỨNG

| STT | Tính năng yêu cầu | Dự án tham khảo chính | Dự án tham khảo phụ | Ghi chú |
|-----|-------------------|----------------------|---------------------|---------|
| 1 | Dashboard | trentas/saas-scaffolding, Cal.com, Documenso | ixartz/SaaS-Boilerplate | Tham khảo layout KPI cards, charts, navigation |
| 2 | Tenant Management | trentas/saas-scaffolding, Basejump, Cal.com | b12 (schema-per-tenant) | Tham khảo RLS, tenant isolation, onboarding |
| 3 | Subdomain Management | trentas/saas-scaffolding, Cal.com | Basejump-next | Tham khảo routing, middleware, tenant resolution |
| 4 | Custom Domain | Cal.com, Dub.co, Papermark | Documenso | Tham khảo domain verification, SSL, routing |
| 5 | Subscription | trentas/saas-scaffolding, Basejump, Lago | Kill Bill | Billing lifecycle, plans, trials |
| 6 | Payment | trentas/saas-scaffolding, Lago, Kill Bill | Stripe docs | Stripe integration patterns |
| 7 | Feature Flag | Flagsmith, Unleash, Flipt | trentas/saas-scaffolding | Flag evaluation, plan-based gating |
| 8 | Package Management | Tự implement theo business logic VietSalePro | SaaSForge Core | Tham khảo plan limits, seat limits |
| 9 | System Settings | trentas/saas-scaffolding, Cal.com | Documenso | Organization settings, branding |
| 10 | Announcement | Cal.com, Documenso | Tự implement | Banner, changelog, maintenance notice |
| 11 | Audit Log | Cal.com, trentas/saas-scaffolding | Documenso | Event logging, actor tracking, impersonation |
| 12 | Support | Tự implement + tham khảo Cal.com | Outline (wiki) | Ticket system hoặc knowledge base |
| 13 | Impersonate User | Cal.com, ixartz/SaaS-Boilerplate | Tự implement | Audit log impersonation, session switch |
| 14 | System Monitor | Coolify, cvsloane/infra-dashboard | Tự implement + Supabase logs | CPU, memory, disk, health checks |
| 15 | Queue Monitor | Coolify (Horizon), cvsloane/infra-dashboard | Tự implement | BullMQ/Supabase queue monitoring |
| 16 | Cron Monitor | Coolify, cvsloane/infra-dashboard | Tự implement | Scheduled jobs, execution logs |
| 17 | Storage | Supabase Storage (native) | trentas/saas-scaffolding | Storage buckets, policies |
| 18 | Backup | Coolify, supabase-backup patterns | Tự implement | pg_dump, scheduled backups |
| 19 | Restore | Coolify, supabase-backup patterns | Tự implement | Restore procedures, point-in-time |
| 20 | Email Service | Listmonk | trentas/saas-scaffolding | Self-hosted email campaigns, transactional |
| 21 | SMS Service | Tích hợp Twilio/Vonage/provider địa phương | Tự implement | Open source SMS service thuần rất ít |
| 22 | Webhook | Svix | trentas/saas-scaffolding | Webhook delivery, retries, signatures |
| 23 | API Key | Unkey | trentas/saas-scaffolding | API key lifecycle, usage analytics |
| 24 | License | Tự implement theo business logic VietSalePro | Keygen (tham khảo) | License generation, validation |
| 25 | Usage | Lago, Kill Bill | trentas/saas-scaffolding | Usage metering, quota tracking |
| 26 | Invoice | Lago, Kill Bill | Stripe | Invoice generation, PDF, history |
| 27 | Activity | Cal.com, trentas/saas-scaffolding | Documenso | Activity feed, recent events |
| 28 | Database Maintenance | Supabase CLI + Coolify | Tự implement | Vacuum, analyze, index monitoring |
| 29 | Global Config | trentas/saas-scaffolding, Cal.com | Documenso | Feature flags, app settings, env config |

---

## 2.1. License Audit Checklist

> ponytail: VietSalePro là proprietary product. Các repo AGPL/GPL chỉ được tham khảo kiến trúc, không copy code.

| Dự án | License (cần verify) | Rủi ro | Hành động |
|-------|----------------------|--------|-----------|
| trentas/saas-scaffolding | Cần kiểm tra trực tiếp repo | Trung bình | Verify trước khi tham khảo sâu |
| usebasejump/basejump | MIT | Thấp | Có thể tham khảo thoải mái |
| usebasejump/basejump-next | Cần kiểm tra | Trung bình | Verify license |
| ixartz/SaaS-Boilerplate | MIT | Thấp | Tham khảo thoải mái |
| Cal.com | AGPL | Cao | Chỉ tham khảo flow/schema, không copy code |
| Documenso | AGPL | Cao | Chỉ tham khảo flow/schema, không copy code |
| Lago | AGPL | Cao | Chỉ tham khảo flow/schema, không copy code |
| Kill Bill | Apache 2.0 | Thấp | Tham khảo thoải mái |
| Flagsmith / Unleash / Flipt | BSD/Apache | Thấp | Tham khảo thoải mái |
| Svix | MIT | Thấp | Tham khảo thoải mái |
| Unkey | MIT | Thấp | Tham khảo thoải mái |
| Listmonk | AGPL | Cao | Chỉ tham khảo kiến trúc, không copy code |
| Coolify | AGPL | Cao | Chỉ tham khảo kiến trúc, không copy code |

**Action item:** Tạo `docs/opensource-references.md` với license đã xác nhận và link commit hash tại thời điểm tham khảo.

---

## 3. CHI TIẾT CÁC DỰ ÁN ĐỀ XUẤT

### 3.1. Nhóm dự án Full-Stack / Admin Dashboard gần nhất yêu cầu

#### 3.1.1. trentas/saas-scaffolding
- **GitHub**: https://github.com/trentas/saas-scaffolding
- **Stack**: Next.js 16, React 19, TypeScript 5.9, Tailwind CSS 4, shadcn/ui, Supabase, Stripe v21, Resend, NextAuth.js v4
- **License**: Cần kiểm tra trực tiếp repo
- **Tính năng liên quan**: Multi-tenant subdomain routing, auth (email verification, 2FA TOTP, password reset), user management, team management, organization management (logo, settings, rename, delete), Stripe billing, email system, rate limiting, audit logging, feature flags, API keys, webhooks, analytics dashboard, OpenAPI 3.1 spec, RLS policies, storage policies.
- **Tại sao chọn**: Gần với yêu cầu nhất trong các dự án tìm được. Cùng dùng Supabase, có migrations, RLS, subdomain routing, subscription, feature flags, audit log, API keys, webhooks.
- **Cách tham khảo cho VietSalePro**:
  - Xem cách tổ chức migrations trong `supabase/migrations/`
  - Xem cách viết RLS policies trong `supabase/policies/rls_policies.sql`
  - Xem `proxy.ts` để hiểu subdomain routing
  - Xem `src/app/[tenant]/` để tham khảo tenant-scoped pages
  - Xem `lib/permissions.ts` cho RBAC
  - Xem `lib/audit-logger.ts` cho audit log pattern
  - Xem `lib/tenant.ts` cho tenant resolution
  - Xem `features/` và `config/` cho feature flag system

#### 3.1.2. usebasejump/basejump
- **GitHub**: https://github.com/usebasejump/basejump
- **Stack**: Supabase extension (PostgreSQL), có thể dùng với bất kỳ frontend nào
- **License**: MIT
- **Tính năng liên quan**: Personal accounts, team accounts, permissions qua RLS, billing support cho Stripe, testing tools (pgtap), dbdev package.
- **Tại sao chọn**: Basejump là nguồn đối chiếu hiện tại của VietSalePro, có thể dùng để mở rộng các tính năng còn thiếu.
- **Cách tham khảo**:
  - Nghiên cứu schema accounts, memberships, invitations
  - Xem cách tích hợp billing lifecycle
  - Dùng `supabase_test_helpers` để viết test

#### 3.1.3. usebasejump/basejump-next
- **GitHub**: https://github.com/usebasejump/basejump-next
- **Stack**: Next.js, Supabase, Tailwind/shadcn
- **License**: Cần kiểm tra repo
- **Tính năng liên quan**: Complete UI cho personal accounts, team accounts, invitations, member/permission management, subscription billing.
- **Cách tham khảo**:
  - Tham khảo UI components cho tenant switcher, team settings, billing portal
  - Xem cách xử lý invitations và role management

#### 3.1.4. ixartz/SaaS-Boilerplate
- **GitHub**: https://github.com/ixartz/SaaS-Boilerplate
- **Stack**: Next.js, Tailwind CSS, shadcn/ui, TypeScript, Clerk, Drizzle ORM, Sentry
- **License**: MIT
- **Tính năng liên quan**: Authentication, multi-tenancy & team support, role & permissions, user impersonation, i18n, landing page, user dashboard, form handling, SEO, logging, error monitoring, testing, deployment, monitoring.
- **Tại sao chọn**: Rất phù hợp để tham khảo user impersonation flow (một tính năng cụ thể bạn yêu cầu).
- **Cách tham khảo**:
  - Tìm module impersonation
  - Xem cách integrate Clerk với multi-tenancy
  - Tham khảo dashboard layout và settings pages

#### 3.1.5. Cal.com
- **GitHub**: https://github.com/calcom/cal.com
- **Stack**: Next.js, Prisma, TypeScript, PostgreSQL
- **License**: AGPLv3 (chú ý: không copy code trực tiếp vào sản phẩm proprietary)
- **Tính năng liên quan**: Organizations (multi-tenant), teams, custom subdomain, custom domain, impersonation, audit logs, webhooks, API keys, PBAC (Permission-Based Access Control), SAML/OIDC SSO, billing seats, role-based access, workflow automation.
- **Tại sao chọn**: Đây là một trong những dự án mã nguồn mở có enterprise admin dashboard hoàn chỉnh nhất.
- **Cách tham khảo cho VietSalePro**:
  - Tham khảo organization admin dashboard UI/UX
  - Tham khảo audit log schema và event types (login, impersonation_start, impersonation_stop, role_changed...)
  - Tham khảo subdomain/custom domain routing
  - Tham khảo PBAC pattern
  - Tham khảo webhook và API key management flows

---

### 3.2. Nhóm dự án chuyên biệt theo domain

#### 3.2.1. Billing / Subscription / Invoice / Usage

##### Lago
- **GitHub**: https://github.com/getlago/lago
- **Stack**: Ruby on Rails, PostgreSQL, React frontend
- **License**: AGPLv3
- **Tính năng liên quan**: Usage-based billing, subscription billing, hybrid pricing, invoice generation, customer portal, wallet/credits, entitlements, revenue analytics, webhooks.
- **Cách tham khảo**: Tham khảo data model cho plans, subscriptions, usage events, invoices, credits. Có thể dùng như một dịch vụ billing tích hợp qua API.

##### Kill Bill
- **GitHub**: https://github.com/killbill/killbill
- **Stack**: Java
- **License**: Apache 2.0
- **Tính năng liên quan**: Subscription billing, payments, invoices, multi-tenant, usage-based, trials, add-ons, payment retries, plugins, Kaui admin UI.
- **Cách tham khảo**: Dùng cho các case billing phức tạp, nhiều plans, nhiều payment gateways.

#### 3.2.2. Feature Flag

##### Flagsmith
- **GitHub**: https://github.com/Flagsmith/flagsmith
- **Stack**: Python backend, TypeScript/JavaScript frontend
- **License**: BSD-3-Clause
- **Tính năng liên quan**: Feature flags, remote config, A/B testing, segments, organization/project/roles, SDK cho React/Next.js/TypeScript.
- **Cách tham khảo**: Tích hợp SDK vào React app. Tham khảo cách tổ chức flags theo environment và user segments.

##### Unleash
- **GitHub**: https://github.com/Unleash/unleash
- **Stack**: Node.js, TypeScript
- **License**: Apache 2.0
- **Tính năng liên quan**: Feature flags enterprise-ready, SDK đa dạng.
- **Cách tham khảo**: Alternative cho Flagsmith nếu cần enterprise governance.

##### Flipt
- **GitHub**: https://github.com/flipt-io/flipt
- **Stack**: Go
- **License**: GPL
- **Tính năng liên quan**: 100% open-source, Git-native flag management.
- **Cách tham khảo**: Nếu muốn quản lý flags qua GitOps.

#### 3.2.3. Webhook

##### Svix
- **GitHub**: https://github.com/svix/svix-webhooks
- **Stack**: Rust
- **License**: MIT
- **Tính năng liên quan**: Webhook sending infrastructure, retries, signature verification, delivery logs, application portal, event types, message fanout.
- **Cách tham khảo**: Tự host Svix hoặc tham khảo cách thiết kế webhook delivery system (attempts, signatures, endpoint management).

#### 3.2.4. API Key Management

##### Unkey
- **GitHub**: https://github.com/unkeyed/unkey
- **Stack**: TypeScript
- **License**: AGPLv3 (source-available)
- **Tính năng liên quan**: API key creation/revocation, rate limiting, usage analytics, verification SDK.
- **Cách tham khảo**: Tham khảo schema và flow quản lý API keys. Có thể tích hợp qua API hoặc tự implement theo pattern.

#### 3.2.5. Email Service

##### Listmonk
- **GitHub**: https://github.com/knadh/listmonk
- **Stack**: Go, PostgreSQL
- **License**: AGPLv3
- **Tính năng liên quan**: Newsletter, mailing list manager, transactional emails, media library, S3 storage, OIDC SSO, granular API tokens, analytics.
- **Cách tham khảo**: Dùng làm self-hosted email service. Tham khảo API coverage và template system.

#### 3.2.6. System / Queue / Cron Monitor

##### Coolify
- **GitHub**: https://github.com/coollabsio/coolify
- **Stack**: PHP (Laravel Livewire)
- **License**: Cần kiểm tra chính xác (thường là Apache hoặc custom)
- **Tính năng liên quan**: Self-hosted PaaS, deploy apps/databases, scheduled jobs, queue monitoring (Horizon), backups, server metrics, cron jobs.
- **Cách tham khảo**: Tham khảo dashboard design cho monitoring, scheduled jobs, backup management.

##### cvsloane/infra-dashboard
- **GitHub**: https://github.com/cvsloane/infra-dashboard
- **Stack**: Next.js 16, React 19, TypeScript
- **License**: MIT
- **Tính năng liên quan**: Unified dashboard cho Coolify, BullMQ queues, PostgreSQL metrics, backups, VPS health, site health, worker supervisor.
- **Cách tham khảo**: Tham khảo giao diện tổng hợp system/queue/database/server metrics.

#### 3.2.7. E-signature / Document (tham khảo admin patterns)

##### Documenso
- **GitHub**: https://github.com/documenso/documenso
- **Stack**: Next.js, Prisma, TypeScript, PostgreSQL
- **License**: AGPLv3
- **Tính năng liên quan**: Organizations, teams, admin dashboard, user impersonation, audit trail, custom branding, webhooks, API.
- **Cách tham khảo**: Tham khảo admin organization dashboard, member invitations, team management UI.

#### 3.2.8. Link Management / Multi-tenant SaaS (tham khảo subdomain & subscription)

##### Dub.co
- **GitHub**: https://github.com/dubinc/dub
- **Stack**: Next.js, Prisma, TypeScript, Tailwind, Upstash, Tinybird, PlanetScale
- **License**: AGPLv3 (Open Core, 99% open-source)
- **Tính năng liên quan**: Multi-tenant workspaces, subscription billing, custom domains, analytics, API keys.
- **Cách tham khảo**: Tham khảo subdomain/custom domain, workspace switching, billing dashboard.

#### 3.2.9. Form Builder / Multi-tenant (tham khảo organization & permissions)

##### Formbricks
- **GitHub**: https://github.com/formbricks/formbricks
- **Stack**: Next.js, Prisma, TypeScript, PostgreSQL
- **License**: AGPLv3
- **Tính năng liên quan**: Organizations, team collaboration, role-based access, webhooks, API.
- **Cách tham khảo**: Tham khảo organization/team settings, permission models.

---

## 4. LỘ TRÌNH TRIỂN KHAI CHO VIETSALEPRO

### Giai đoạn 1: Chuẩn bị nền tảng (Foundation)
**Mục tiêu**: Củng cố multi-tenancy, auth, RLS, audit log cơ bản.

1. Rà soát lại schema hiện tại, so sánh với:
   - `trentas/saas-scaffolding/supabase/migrations/`
   - `usebasejump/basejump/supabase/`
2. Chuẩn hóa bảng:
   - `tenants` / `organizations`
   - `tenant_members` / `memberships`
   - `roles` và `permissions`
   - `audit_logs`
   - `subscriptions` / `plans`
3. Củng cố RLS policies cho tất cả các bảng đã tồn tại.
4. Thiết lập audit log writer (đã có trong dự án, cần mở rộng event types).
5. Tham khảo `Cal.com audit log events` để bổ sung các event types: login, impersonation, role_changed, password_changed, etc.

### Giai đoạn 2: Admin Dashboard Core
**Mục tiêu**: Xây dựng layout và các trang admin cơ bản.

1. Tham khảo UI/UX từ:
   - `trentas/saas-scaffolding/src/components/tenant/`
   - `Cal.com` admin settings pages
   - `Documenso` organization settings
2. Xây dựng layout admin với:
   - Sidebar navigation
   - Tenant/Organization switcher
   - Breadcrumb
   - Top bar với user menu, notifications
3. Xây dựng các trang:
   - Dashboard overview (KPI cards, charts)
   - Tenant Management
   - User Management
   - Team/Role Management
   - Organization Settings
   - Audit Log
   - Activity Feed

### Giai đoạn 3: Billing & Subscription
**Mục tiêu**: Hoàn thiện subscription, payment, usage, invoice.

1. Tham khảo `trentas/saas-scaffolding` Stripe integration.
2. Tham khảo `Lago` hoặc `Kill Bill` cho usage-based billing nếu cần.
3. Xây dựng:
   - Plans & Packages management
   - Subscription lifecycle (trials, upgrades, downgrades, cancellations)
   - Invoice list & PDF generation
   - Usage tracking dashboard
   - Payment history
4. Tích hợp payment gateway (Stripe hoặc local provider).

### Giai đoạn 4: Advanced Admin Features
**Mục tiêu**: Bổ sung các tính năng nâng cao cho admin.

1. **Feature Flags**: Tích hợp `Flagsmith` SDK hoặc tự implement simple feature flag system.
2. **Impersonate User**: Tham khảo `Cal.com` và `ixartz/SaaS-Boilerplate`, implement với audit log.
3. **API Keys**: Tham khảo `Unkey` hoặc tự implement.
4. **Webhooks**: Tham khảo `Svix` hoặc tự implement webhook delivery system.
5. **Global Config**: Xây dựng bảng `app_config` với caching.
6. **Announcement**: Banner system, maintenance mode.

### Giai đoạn 5: Operations & Monitoring
**Mục tiêu**: System health, queue, cron, backup, storage.

1. **System Monitor**: Health checks, CPU/memory/disk (edge function hoặc external agent).
2. **Queue Monitor**: Nếu dùng Supabase pg-boss / BullMQ, xây dựng dashboard.
3. **Cron Monitor**: Scheduled jobs dashboard, execution logs.
4. **Backup/Restore**: Tự động hóa pg_dump, restore drills.
5. **Storage Management**: Supabase Storage buckets, usage stats, cleanup policies.
6. **Database Maintenance**: Vacuum, analyze, index monitoring.

### Giai đoạn 6: Communication Services
**Mục tiêu**: Email, SMS, support.

1. **Email Service**: Tích hợp `Listmonk` hoặc dùng Resend/SendGrid qua Supabase Edge Functions.
2. **SMS Service**: Tích hợp Twilio/Vonage/local SMS provider.
3. **Support**: Xây dựng ticket system hoặc tích hợp helpdesk.

### Giai đoạn 7: Polish & Enterprise Features
**Mục tiêu**: SSO, custom domain, license, advanced audit.

1. **Custom Domain**: Tham khảo `Cal.com`, `Dub.co`, `Papermark`.
2. **SSO/SAML**: Có thể tích hợp BoxyHQ hoặc WorkOS.
3. **License Management**: Tự implement theo business model.
4. **Advanced Audit & Compliance**: Retention policies, export audit logs.
5. **Rate Limiting & Security**: Tham khảo `trentas/saas-scaffolding`.

---

## 5. QUY TẮC THAM KHẢO MÃ NGUỒN MỞ (QUAN TRỌNG)

### 5.1. Phân biệt license

| License | Mô tả | Có thể copy code? | Có thể tham khảo ý tưởng? |
|---------|-------|-------------------|---------------------------|
| MIT | Rất permissive | Có, với điều kiện giữ copyright | Có |
| Apache 2.0 | Permissive, có patent grant | Có, với điều kiện giữ copyright | Có |
| BSD-3-Clause | Permissive | Có | Có |
| AGPLv3 | Copyleft mạnh, yêu cầu open-source nếu distribute | **Không** nếu VietSalePro là proprietary | Có |
| GPL | Copyleft | **Không** nếu VietSalePro là proprietary | Có |

### 5.2. Cách tham khảo an toàn

1. **Đọc flow và architecture**, sau đó tự implement lại bằng code của VietSalePro.
2. **Tham khảo database schema** và tự viết migrations phù hợp với domain VietSalePro.
3. **Tham khảo UI/UX patterns** (layout, navigation, data tables) nhưng tự viết components bằng React + Tailwind.
4. **Không copy-paste code** từ các dự án AGPL/GPL.
5. **Ghi chép nguồn tham khảo** trong tài liệu nội bộ để tránh vấn đề pháp lý sau này.

---

## 6. CÁC BƯỚC TIẾP THEO ĐỀ XUẤT

1. **Review kế hoạch này** và xác nhận priority các tính năng cần làm trước.
2. **Clone các repo đề xuất** về môi trường local để explore.
3. **Lập danh sách shortlist** cho từng domain (ví dụ: chọn 1 dự án chính cho billing, 1 cho feature flags).
4. **Tạo tài liệu so sánh chi tiết** cho các dự án shortlist (pros/cons, stack, license, community).
5. **Bắt đầu từ Giai đoạn 1** (foundation) và ưu tiên các tính năng admin dashboard core.
6. **Cập nhật kế hoạch** định kỳ khi có thông tin mới hoặc khi chọn lựa thay đổi.

---

## 7. TÀI LIỆU THAM KHẢO TỔNG HỢP

### 7.1. Full-Stack / Admin Dashboard
- trentas/saas-scaffolding: https://github.com/trentas/saas-scaffolding
- usebasejump/basejump: https://github.com/usebasejump/basejump
- usebasejump/basejump-next: https://github.com/usebasejump/basejump-next
- ixartz/SaaS-Boilerplate: https://github.com/ixartz/SaaS-Boilerplate
- Cal.com: https://github.com/calcom/cal.com
- Documenso: https://github.com/documenso/documenso
- Dub.co: https://github.com/dubinc/dub
- Formbricks: https://github.com/formbricks/formbricks

### 7.2. Billing
- Lago: https://github.com/getlago/lago
- Kill Bill: https://github.com/killbill/killbill

### 7.3. Feature Flags
- Flagsmith: https://github.com/Flagsmith/flagsmith
- Unleash: https://github.com/Unleash/unleash
- Flipt: https://github.com/flipt-io/flipt

### 7.4. Webhooks & API Keys
- Svix: https://github.com/svix/svix-webhooks
- Unkey: https://github.com/unkeyed/unkey

### 7.5. Email & Communication
- Listmonk: https://github.com/knadh/listmonk

### 7.6. Monitoring & Infrastructure
- Coolify: https://github.com/coollabsio/coolify
- cvsloane/infra-dashboard: https://github.com/cvsloane/infra-dashboard

---

> Kết thúc kế hoạch. File này cần được review và cập nhật định kỳ khi có quyết định chọn lựa cụ thể cho từng domain tính năng.
