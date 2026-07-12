# Review & Corrective Plan: Admin Dashboard Plan Suite

> **For Hermes:** Use `subagent-driven-development` skill to implement the corrective tasks below task-by-task. Each task is a plan/doc edit, not production code.

**Goal:** Đánh giá xem 3 file plan trong `Plan/` đã phân rã đúng `PLAN_AdminDashboard_OpenSource_Reference.md` hay chưa, đồng thời xác định các điểm cần bổ sung/chỉnh sửa để plan thực sự dùng được cho hệ thống hoạt động thật, phân phối kinh doanh, và ổn định > 20 năm.

**Architecture / Context:**
- Plan tổng: `Plan/PLAN_AdminDashboard_OpenSource_Reference.md` (29 tính năng + danh sách dự án OSS tham khảo).
- Plan phân phase: `Plan/PLAN_AdminDashboard_Implementation_Phases.md` (7 phase, ~35 task).
- Plan sub-phase: `Plan/PLAN_AdminDashboard_SubPhases.md` (37 sub-phase SP-x.y/SP-C.3).
- Codebase hiện tại đã triển khai phần lớn các tính năng admin (commit `b6d362fe` "Complete Basejump Admin Dashboard Enterprise Upgrade Phase 0.1 -> 7.2" và các commit Phase A/B/C/D/5). Các file then chốt đã có: `services/admin/*.ts`, `pages/admin/*.tsx`, `components/admin/*.tsx`, `docs/admin-dashboard/RPC_CONTRACTS.md`, `docs/admin-dashboard/MIGRATION_RUNBOOK.md`, migration runbook với health-check, feature flags, explicit grants.

**Tech Stack:** Vite, React 19, TypeScript 5.8, Tailwind CSS 4, Supabase JS v2, Vitest, Supabase CLI, Vercel.

---

## Context / Assumptions

- Đã dùng skill `/systematic-debugging` để kiểm tra root cause (tại sao plan chưa đủ cho 20 năm vận hành): thiếu các yêu cầu phi chức năng, vận hành, tuân thủ, và quản lý vendor/dependency lifecycle.
- Đã dùng skill `/writing-plans` để định dạng kế hoạch chỉnh sửa.
- Các plan hiện tại **đã bao phủ đủ 29 tính năng** từ plan tổng, nhưng chưa đồng bộ với codebase thực tế và chưa đề cập đến nhiều mảng bắt buộc cho sản phẩm thương mại dài hạn.

---

## Proposed Approach

1. Đánh dấu trạng thái thực tế của từng task/sub-phase trong 3 file plan (done / partial / pending).
2. Sửa tên file, mã migration, đường dẫn trong plan cho khớp với codebase.
3. Bổ sung các section vận hành, tuân thủ, an ninh, kinh doanh vào plan phân phase và sub-phase.
4. Tạo các tài liệu/runbook hỗ trợ còn thiếu.
5. Xóa/gộp các bản sao trong `.hermes/plans/` để tránh nguồn sự thật bị phân mảnh.

---

## Executive Summary

| Tiêu chí | Kết quả | Ghi chú |
|----------|---------|---------|
| Bao phủ 29 tính năng | PASS | Tất cả các tính năng từ plan tổng đều có task/sub-phase tương ứng. |
| Phân rã phase/sub-phase | PASS | 7 phase, 37 sub-phase, cross-cutting tasks đầy đủ. |
| Đồng bộ với codebase hiện tại | FAIL | Nhiều file/tên migration trong plan không khớp thực tế. |
| Sẵn sàng vận hành > 20 năm | FAIL | Thiếu SLO, DR, data retention, vendor lock-in, compliance, business model. |
| Phân phối kinh doanh | FAIL | Chưa có plan onboarding, SLA, reseller/partner, billing operations. |
| Nguồn sự thật duy nhất | FAIL | Có bản sao plan trong `.hermes/plans/` và `Plan/`. |

---

## Mapping 29 Tính Năng -> Phase -> Sub-Phase (Đã Kiểm Chứng)

| STT | Tính năng (Plan tổng) | Task trong Implementation Phases | Sub-phase trong SubPhases |
|-----|-----------------------|----------------------------------|---------------------------|
| 1 | Dashboard | 2.0 Build Dashboard overview page | SP-2.0 |
| 2 | Tenant Management | 1.1, 1.3, 1.4, 1.5, 2.2 | SP-1.1, SP-1.3, SP-1.4, SP-1.5, SP-2.2 |
| 3 | Subdomain Management | 1.2, 7.1 | SP-1.2, SP-7.1 |
| 4 | Custom Domain | 1.2, 7.2 | SP-1.2, SP-7.2 |
| 5 | Subscription | 3.2 | SP-3.2 |
| 6 | Payment | 3.3 | SP-3.3 |
| 7 | Feature Flag | 4.1 | SP-4.1 |
| 8 | Package Management | 3.1 | SP-3.1 |
| 9 | System Settings | 2.3, 7.4 | SP-2.3, SP-7.4 |
| 10 | Announcement | 2.4 | SP-2.4 |
| 11 | Audit Log | 1.6, 2.9, 7.5 | SP-1.6, SP-2.9, SP-7.5 |
| 12 | Support | 6.3 | SP-6.3 |
| 13 | Impersonate User | 4.2 | SP-4.2 |
| 14 | System Monitor | 5.1 | SP-5.1 |
| 15 | Queue Monitor | 5.2 | SP-5.2 |
| 16 | Cron Monitor | 5.3 | SP-5.3 |
| 17 | Storage | 5.7 | SP-5.7 |
| 18 | Backup | 5.4 | SP-5.4 |
| 19 | Restore | 5.5 | SP-5.5 |
| 20 | Email Service | 6.1 | SP-6.1 |
| 21 | SMS Service | 6.2 | SP-6.2 |
| 22 | Webhook | 4.4 | SP-4.4 |
| 23 | API Key | 4.3 | SP-4.3 |
| 24 | License | 7.3 | SP-7.3 |
| 25 | Usage | 3.4 | SP-3.4 |
| 26 | Invoice | 3.5 | SP-3.5 |
| 27 | Activity | 2.5 | SP-2.5 |
| 28 | Database Maintenance | 5.6 | SP-5.6 |
| 29 | Global Config | 2.6 | SP-2.6 |
| Cross-cutting | Test harness / Permissions | C.1, C.2 (đã gộp trong SP-1.0) | SP-1.0 |
| Cross-cutting | OSS reference documentation | C.3 | SP-C.3 |

**Kết luận phân rã:** Đúng, không thiếu tính năng nào.

---

## Root Cause: Tại Sao Plan Chưa Đủ Cho > 20 Năm Vận Hành

1. **Plan là kế hoạch tính năng (feature-driven), chưa phải kế hoạch sản phẩm/sản phẩm dịch vụ (service-driven).**
2. **Thiếu mục tiêu SLO/SLA/SLI** -> không thể đo đạc "ổn định".
3. **Thiếu chiến lược dữ liệu dài hạn** -> archive, retention, purging, GDPR deletion, audit log rotation.
4. **Thiếu kế hoạch thoát khỏi vendor (vendor exit)** -> Supabase/Vercel lock-in, self-host option, migration path.
5. **Thiếu compliance & pháp lý** -> license audit của các repo OSS tham khảo, Vietnam PDPA, hóa đơn điện tử, thuế.
6. **Thiếu vận hành kinh doanh** -> SLA, support tier, reseller/partner, customer onboarding, billing operations.
7. **Thiếu incident/rollback/DR runbook cụ thể** -> chỉ có migration runbook và health-check chung.
8. **Plan không đồng bộ với codebase** -> tên file/migration sai, dễ gây làm lại hoặc bỏ sót.
9. **Nguồn sự thật bị phân mảnh** -> bản sao trong `.hermes/plans/` và `Plan/`.

---

## Cụ Thể Các Điểm Cần Chỉnh Sửa / Bổ Sung

### A. Đồng Bộ Plan Với Codebase Thực Tế

- **Tên file page sai:** Plan ghi `pages/admin/OverviewPage.tsx`, thực tế là `pages/admin/Overview.tsx`.
- **Tên file service sai:** Plan đề cập `services/admin/auditAdminService.ts`, thực tế là `services/admin/auditAdminService.ts` vẫn đúng; nhưng nhiều service khác (`systemAdminService.ts`, `complianceAdminService.ts`) chưa được liệt kê.
- **Mã migration lỗi thời:** Plan đề xuất `20250713000020_phase1_tenant_subdomain_domain.sql`, nhưng codebase đã có migration mới hơn nhiều (`20250706*`, `202607*`, `20260710*`, `20260711*`). Cần cập nhật danh sách migration cần đọc/sửa.
- **Thư mục backup chưa tồn tại:** Plan SubPhases giả định `C:\Users\SUACAUBA\Downloads\Project\Back up Admin dashboard step\` đã tạo, nhưng thực tế chưa có.
- **Thư mục `Plan/Log`, `Plan/Migration`, `Plan/EdgeFunction` chưa tồn tại.**
- **`tests/test-helpers.ts` chưa tồn tại**; test helpers đang nằm rải rác trong `tests/setup.ts`, `tests/mocks/supabase.ts`.

### B. Bổ Sung Yêu Cầu Phi Chức Năng (Non-Functional Requirements)

Thêm vào đầu `PLAN_AdminDashboard_Implementation_Phases.md` một section `Non-Functional Requirements`:

- **Availability:** SLO 99.9% cho admin dashboard; RTO < 4h, RPO < 1h.
- **Performance:** 95th percentile API latency < 500ms; dashboard first paint < 2s.
- **Security:** Pentest hàng năm, key rotation 90 ngày, MFA bắt buộc cho system admin.
- **Scalability:** Hỗ trợ 10,000 tenants/1M users trên Supabase; read-replica và caching strategy.
- **Data durability:** Backup daily + point-in-time recovery; giữ audit log ít nhất 7 năm.
- **Compliance:** PDPA/GDPR, e-invoice, OSS license audit.

### C. Bổ Sung Chiến Lược Dữ Liệu Dài Hạn

Tạo section `Data Lifecycle & Long-Term Retention`:

- Partition/partition-like archive cho `app_audit_log`, `admin_login_history`, `notification_log`, `rate_limit_logs`.
- Retention policy theo loại dữ liệu (audit 7 năm, login history 2 năm, system metrics 1 năm).
- GDPR deletion workflow (soft-delete -> hard-delete sau 30 ngày -> verify).
- Cold storage export định kỳ sang object storage/S3-compatible.

### D. Bổ Sung Vendor Lock-in & Exit Strategy

Tạo section `Vendor & Dependency Management`:

- **Supabase:** giữ schema/migration portable (không dùng quá nhiều extension độc quyền), có thể self-host Supabase nếu cần.
- **Vercel:** build output là static SPA, có thể deploy lên bất kỳ CDN nào.
- **PostgreSQL:** đảm bảo migrations chạy được trên bất kỳ Postgres 15+.
- **Dependency cadence:** npm audit + dependency update quarterly; pin major versions; có smoke test sau mỗi lần nâng cấp.

### E. Bổ Sung Compliance & Pháp Lý

Tạo section `Compliance & Legal`:

- **OSS License Audit:** liệt kê license của từng repo trong `PLAN_AdminDashboard_OpenSource_Reference.md` (MIT/Apache/BSD/AGPL). Các repo AGPL/GPL chỉ được tham khảo kiến trúc, không copy code.
- **PDPA/GDPR:** data subject rights, consent log, DPA checklist.
- **Vietnam regulations:** hóa đơn điện tử (e-invoice), thuế GTGT, lưu trữ dữ liệu trong nước nếu có quy định.
- **Terms of Service / Privacy Policy:** mẫu và quy trình cập nhật.

### F. Bổ Sung Vận Hành Kinh Doanh (Business Distribution)

Tạo section `Go-to-Market & Operations`:

- **Tenant onboarding flow:** sign-up -> email verify -> subdomain -> plan selection -> payment -> wizard.
- **SLA/Support tiers:** Free/Business/Enterprise với thời gian phản hồi khác nhau.
- **Reseller/Partner model:** multi-tenant admin cho partner, white-label (migrations `20260708*__white_label` đã có dấu hiệu).
- **Billing operations:** dunning, retry, invoice dispute, refund, tax report.

### G. Bổ Sung Incident Response & Disaster Recovery

Tạo các runbook/tài liệu:

- `docs/admin-dashboard/INCIDENT_RESPONSE_RUNBOOK.md`
- `docs/admin-dashboard/DISASTER_RECOVERY_RUNBOOK.md`
- `docs/admin-dashboard/ROLLBACK_RUNBOOK.md`
- `docs/admin-dashboard/KEY_ROTATION_RUNBOOK.md`

Nội dung tối thiểu: trigger, owner, step-by-step, verification, communication template.

### H. Cải Thiện Monitoring & Alerting

Hiện tại chỉ có `admin-health-check` edge function + Uptime Robot. Cần:

- **Metrics:** latency, error rate, DB connection count, storage usage, queue depth.
- **Alerting channels:** email, Slack/PagerDuty (nếu có).
- **Dashboard:** Grafana hoặc Supabase Logs + custom dashboard.
- **Synthetic tests:** Playwright hoặc `webapp-testing` skill kiểm tra critical admin flows hàng ngày.

### I. Xóa/Gộp Các Bản Sao Plan

Các file sau là bản sao hoặc gần giống:

- `.hermes/plans/2026-07-12_110737-admin-dashboard-phases.md` == `Plan/PLAN_AdminDashboard_Implementation_Phases.md`
- `.hermes/plans/2026-07-12_114312-admin-dashboard-sub-phases.md` == `Plan/PLAN_AdminDashboard_SubPhases.md`

**Hành động:**
- Giữ `Plan/PLAN_AdminDashboard_Implementation_Phases.md` và `Plan/PLAN_AdminDashboard_SubPhases.md` làm canonical.
- Các file `.hermes/plans/...` chỉ nên là symlink hoặc note tham khảo, hoặc xóa sau khi đã chỉnh sửa xong plan gốc.

---

## Corrective Tasks (Actionable)

### Task 1: Audit và cập nhật trạng thái thực tế cho từng sub-phase

**Objective:** Đánh dấu sub-phase nào đã làm, đang làm, chưa làm.

**Files:**
- Modify: `Plan/PLAN_AdminDashboard_SubPhases.md`

**Step 1:** Thêm cột `Status` vào bảng Index các Sub-Phase.

```markdown
| SP | Tên | Phase | Tính năng chính | Status |
|----|-----|-------|-----------------|--------|
| SP-1.0 | Setup Test Harness | Cross-cutting | Foundation | Done |
| SP-1.1 | Review Current Tenant Schema | 1 | Tenant Management | Done |
...
```

**Step 2:** Đối chiếu với git log và `supabase/migrations/` để xác định status.

**Verification:** Tất cả SP có status rõ ràng.

---

### Task 2: Sửa tên file và mã migration trong plan cho khớp codebase

**Objective:** Loại bỏ các đường dẫn/migration lỗi thời.

**Files:**
- Modify: `Plan/PLAN_AdminDashboard_Implementation_Phases.md`
- Modify: `Plan/PLAN_AdminDashboard_SubPhases.md`

**Step 1:** Thay `pages/admin/OverviewPage.tsx` -> `pages/admin/Overview.tsx`.
**Step 2:** Thay `pages/admin/AdminShell.tsx` -> `components/AdminShell.tsx` hoặc `pages/admin/AdminLayout.tsx` tùy ngữ cảnh.
**Step 3:** Cập nhật danh sách migration cần đọc trong Task 1.1/1.3/1.4 thành các migration thực tế (`20250703*`, `20250704*`, `20250705*`, `20250706*`, `20260708*`, ...).
**Step 4:** Bỏ `supabase/migrations/20250713000020_phase1_tenant_subdomain_domain.sql` nếu đã được thay thế bởi migration khác.

**Verification:** Grep từng đường dẫn trong plan, đảm bảo file tồn tại.

---

### Task 3: Tạo thư mục backup và thư mục artifacts cho plan

**Objective:** Đảm bảo cấu trúc thư mục trong SubPhases thực sự tồn tại.

**Files:**
- Create directory: `C:\Users\SUACAUBA\Downloads\Project\Back up Admin dashboard step\`
- Create directory: `Plan/Log/`
- Create directory: `Plan/Migration/`
- Create directory: `Plan/EdgeFunction/`

**Step 1:** Dùng PowerShell tạo thư mục.

```powershell
New-Item -ItemType Directory -Force -Path "C:\Users\SUACAUBA\Downloads\Project\Back up Admin dashboard step"
New-Item -ItemType Directory -Force -Path "C:\Users\SUACAUBA\Downloads\Project\vietsale-pro-v7\Plan\Log"
New-Item -ItemType Directory -Force -Path "C:\Users\SUACAUBA\Downloads\Project\vietsale-pro-v7\Plan\Migration"
New-Item -ItemType Directory -Force -Path "C:\Users\SUACAUBA\Downloads\Project\vietsale-pro-v7\Plan\EdgeFunction"
```

**Verification:** `ls Plan/` hiển thị 4 thư mục con.

---

### Task 4: Thêm NFR section vào Implementation Phases

**Objective:** Định nghĩa rõ "ổn định > 20 năm" bằng các chỉ số đo được.

**Files:**
- Modify: `Plan/PLAN_AdminDashboard_Implementation_Phases.md`

**Step 1:** Thêm section sau sau `Context / Assumptions`:

```markdown
## Non-Functional Requirements (for 20+ year operation)

- **Availability:** Admin dashboard SLO 99.9% (max ~8.7h downtime/tháng). RTO <= 4h, RPO <= 1h.
- **Performance:** p95 API latency <= 500ms; dashboard first paint <= 2s on 4G.
- **Security:** MFA bắt buộc cho system admin; key rotation 90 ngày; pentest hàng năm.
- **Scalability:** Hỗ trợ 10,000 active tenants / 1,000,000 users; read-replica + caching strategy.
- **Durability:** Daily automated backups + point-in-time recovery; audit log retained 7 years.
- **Compliance:** PDPA/GDPR, Vietnam e-invoice, OSS license audit.
- **Vendor independence:** Migrations portable to any PostgreSQL 15+; frontend static build deployable to any CDN.
```

**Verification:** Section xuất hiện trong file.

---

### Task 5: Thêm Data Lifecycle & Retention section

**Objective:** Tránh dữ liệu audit/log phình to không kiểm soát.

**Files:**
- Modify: `Plan/PLAN_AdminDashboard_Implementation_Phases.md`

**Step 1:** Thêm section:

```markdown
## Data Lifecycle & Long-Term Retention

| Data type | Hot retention | Archive | Cold storage | Purge |
|-----------|---------------|---------|--------------|-------|
| Audit log (`app_audit_log`) | 1 year | 6 years (S3) | After 7 years | Anonymized summary kept |
| Login history (`admin_login_history`) | 90 days | 1 year | After 2 years | Hard delete |
| Notification log | 30 days | 90 days | After 1 year | Hard delete |
| Rate limit logs | 30 days | - | After 90 days | Hard delete |
| Tenant backups | 30 days | - | After 90 days | Hard delete |

- Implement partition-like archive using ` RANGE ` on `created_at` or cron job moving old rows.
- GDPR deletion workflow: request -> soft-delete -> 30-day grace -> hard-delete -> verification log.
```

**Verification:** Section xuất hiện.

---

### Task 6: Thêm Vendor & Dependency Management section

**Objective:** Giảm rủi ro vendor lock-in.

**Files:**
- Modify: `Plan/PLAN_AdminDashboard_Implementation_Phases.md`

**Step 1:** Thêm section với các mục Supabase, Vercel, PostgreSQL, npm dependencies.

**Verification:** Section xuất hiện.

---

### Task 7: Thêm Compliance & Legal section

**Objective:** Đảm bảo sản phẩm phân phối hợp pháp.

**Files:**
- Modify: `Plan/PLAN_AdminDashboard_OpenSource_Reference.md`
- Modify: `Plan/PLAN_AdminDashboard_Implementation_Phases.md`

**Step 1:** Trong Reference plan, thêm cột `License` đã xác nhận cho từng repo.
**Step 2:** Thêm mục `Compliance & Legal` trong Implementation Phases với PDPA, GDPR, Vietnam e-invoice, OSS license audit.

**Verification:** Có ít nhất 1 dòng mô tả rủi ro AGPL/GPL.

---

### Task 8: Thêm Go-to-Market & Operations section

**Objective:** Plan không chỉ là kỹ thuật mà còn là kinh doanh.

**Files:**
- Modify: `Plan/PLAN_AdminDashboard_Implementation_Phases.md`

**Step 1:** Thêm section:

```markdown
## Go-to-Market & Business Operations

- **Self-service onboarding:** sign-up -> email verify -> subdomain -> plan -> payment -> wizard.
- **Support tiers:** Free (community), Business (24h response), Enterprise (4h response + Slack).
- **Reseller/Partner:** partner tenant, white-label, revenue share tracking.
- **Billing operations:** dunning retries, invoice disputes, refunds, tax reports.
- **Customer success:** health score, churn alerts, usage-based upsell triggers.
```

**Verification:** Section xuất hiện.

---

### Task 9: Tạo 4 runbook còn thiếu

**Objective:** Có quy trình vận hành rõ ràng.

**Files:**
- Create: `docs/admin-dashboard/INCIDENT_RESPONSE_RUNBOOK.md`
- Create: `docs/admin-dashboard/DISASTER_RECOVERY_RUNBOOK.md`
- Create: `docs/admin-dashboard/ROLLBACK_RUNBOOK.md`
- Create: `docs/admin-dashboard/KEY_ROTATION_RUNBOOK.md`

**Step 1:** Mỗi runbook tối thiểu 5 phần: trigger, owner, steps, verification, communication.

**Verification:** 4 file tồn tại và được liệt kê trong `docs/admin-dashboard/`.

---

### Task 10: Mở rộng monitoring/alerting plan

**Objective:** Không chỉ health-check mà còn metrics/alerting.

**Files:**
- Modify: `docs/admin-dashboard/MIGRATION_RUNBOOK.md` hoặc tạo `docs/admin-dashboard/MONITORING_RUNBOOK.md`

**Step 1:** Định nghĩa SLIs, SLOs, alert thresholds.
**Step 2:** Liệt kê synthetic tests cho critical admin flows.
**Step 3:** Định nghĩa on-call rotation / escalation.

**Verification:** Có bảng metrics + alert thresholds.

---

### Task 11: Deduplicate plan files

**Objective:** Một nguồn sự thật.

**Files:**
- Delete (hoặc ghi chú redirect): `.hermes/plans/2026-07-12_110737-admin-dashboard-phases.md`
- Delete (hoặc ghi chú redirect): `.hermes/plans/2026-07-12_114312-admin-dashboard-sub-phases.md`

**Step 1:** Thay nội dung 2 file `.hermes` thành redirect note:

```markdown
# Redirect

Canonical plan is now in `Plan/PLAN_AdminDashboard_Implementation_Phases.md` (or SubPhases).
Do not edit this file.
```

**Verification:** `grep "Canonical plan" .hermes/plans/2026-07-12_110737-admin-dashboard-phases.md` matches.

---

### Task 12: Commit kết quả review

**Objective:** Lưu lại thay đổi plan.

**Step 1:**

```bash
git add Plan/ docs/admin-dashboard/INCIDENT_RESPONSE_RUNBOOK.md docs/admin-dashboard/DISASTER_RECOVERY_RUNBOOK.md docs/admin-dashboard/ROLLBACK_RUNBOOK.md docs/admin-dashboard/KEY_ROTATION_RUNBOOK.md

git commit -m "docs(plan): review admin dashboard plans and add 20-year operations coverage"
```

**Verification:** `git log --oneline -1` hiển thị commit.

---

## Verification Checklist

- [ ] 29 tính năng vẫn được bao phủ đầy đủ.
- [ ] Tên file/page/service/migration trong plan khớp với codebase.
- [ ] Có section NFR với SLO/SLA/SLI.
- [ ] Có section Data Lifecycle & Retention.
- [ ] Có section Vendor & Dependency Management.
- [ ] Có section Compliance & Legal.
- [ ] Có section Go-to-Market & Business Operations.
- [ ] Có 4 runbook mới: incident, DR, rollback, key rotation.
- [ ] Có monitoring/alerting plan.
- [ ] Các bản sao trong `.hermes/plans/` đã được redirect hoặc xóa.
- [ ] `npm run lint && npm run build && npx vitest run` vẫn PASS (plan edit không ảnh hưởng code).

---

## Risks, Tradeoffs, and Open Questions

- **Risk:** Việc cập nhật plan tốn thời gian nhưng giảm rủi ro làm lại hoặc bỏ sót trong tương lai.
- **Tradeoff:** Bổ sung nhiều section vận hành làm plan dài hơn; có thể tách thành `Plan/PLAN_AdminDashboard_Operations.md` nếu muốn ngắn gọn.
- **Open Question:** Owner có muốn tách plan vận hành ra file riêng thay vì nhét vào Implementation Phases?
- **Open Question:** Có cần lưu trữ dữ liệu trong Vietnam hay không? (ảnh hưởng vendor selection).
- **Open Question:** Có dùng Stripe hay chỉ dùng VNPay/Momo? (ảnh hưởng subscription/billing plan).

---

## Execution Handoff

Plan review complete. Ready to execute using `subagent-driven-development` — dispatch a fresh subagent per task with two-stage review (spec compliance then doc quality). Tasks 1-12 are documentation/plan edits only; no production code changes until plans are approved.
