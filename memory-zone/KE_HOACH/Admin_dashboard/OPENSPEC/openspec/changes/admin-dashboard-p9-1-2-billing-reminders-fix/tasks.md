## 0. Pre-Flight

- [ ] 0.1 Create project backup to `C:\Users\SUACAUBA\Downloads\Project\vietsale-pro-v7_backup_admin_dashboard_p9-1-2-billing-reminders-fix_<YYYYMMDD_HHMMSS>`
- [ ] 0.2 Confirm `npm run lint` passes (baseline)
- [ ] 0.3 Read `memory-zone/HANDOFF_P9_1_2.md`

## 1. P9.1.2 Billing Reminders Fix

- [ ] 1.1 Add `GRANT EXECUTE` for `set_billing_reminder_config` and `get_pending_billing_reminders` to `authenticated` and `service_role`
- [ ] 1.2 Reject empty milestones array `[]` in `set_billing_reminder_config` SQL
- [ ] 1.3 Update mock `set_billing_reminder_config` error message to match SQL

## 2. Verification

- [ ] 2.1 Run `npm run lint`
- [ ] 2.2 Run `npm run build`
- [ ] 2.3 Run `npx vitest run tests/smoke/admin-dashboard-p9-1-billing-reminders.test.ts`
- [ ] 2.4 Run `openspec validate --changes --store admin-dashboard`
- [ ] 2.5 Apply delta SQL to Supabase project and test authenticated RPC calls

## Acceptance Criteria

- [ ] Authenticated frontend can call `set_billing_reminder_config` and `get_pending_billing_reminders`
- [ ] Empty milestones array is rejected
- [ ] `npm run lint` passes
- [ ] `npm run build` passes
- [ ] All smoke tests pass
- [ ] OpenSpec validation passes

## Rollback Plan

- Backup: `C:\Users\SUACAUBA\Downloads\Project\vietsale-pro-v7_backup_admin_dashboard_p9-1-2-billing-reminders-fix_<YYYYMMDD_HHMMSS>`
- Restore migration from backup if SQL deployment fails.
