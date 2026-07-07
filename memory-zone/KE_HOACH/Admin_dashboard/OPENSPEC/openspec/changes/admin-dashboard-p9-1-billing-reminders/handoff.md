## What Was Done

- P9.1 — Billing reminders T-7/T-3/T-1.
- Backend: migration `20250707000000_phase_p9_1_billing_reminders.sql` tạo bảng `invoice_reminder_logs`, RPC `get_billing_reminder_config`, `set_billing_reminder_config`, `get_pending_billing_reminders`, `send_billing_reminders`, và cron job daily 09:00 Asia/Ho_Chi_Minh.
- Edge Function `send-billing-email` (P7.5) được tái dụng: thêm log reminder `invoice_reminder_logs` khi scheduler gửi.
- Frontend: component `BillingReminderConfig` trong tab Thanh toán để cấu hình mốc nhắc, giờ gửi, URL/service role key, và chạy thủ công.
- Service layer: `services/billingReminderService.ts` + types `BillingReminderConfig`, `BillingReminderLog`, `PendingReminder`.
- Smoke test: `tests/smoke/admin-dashboard-p9-1-billing-reminders.test.ts`.

## What Was Verified

- [x] `npm run lint` pass
- [x] `npm run build` pass
- [x] `npx vitest run` pass (97 tests)
- [x] Deploy migration + Edge Function lên Supabase project `rsialbfjswnrkzcxarnj` (QLBH)
  - Migration `20250707000000_phase_p9_1_billing_reminders.sql` đã apply.
  - Edge Function `send-billing-email` đã redeploy với `verify_jwt = false` trong `supabase/config.toml`.
  - Config `billing_reminder_config` đã set trong `system_settings` với `function_url` và `reminder_secret` (custom secret, không còn service role key).
  - Secret `BILLING_REMINDERS_SECRET` đã set trong Supabase secrets.
  - Cron job `billing-reminders-daily` đã tạo.
  - End-to-end test: scheduler tìm đúng invoice T-7, gọi Edge Function thành công, log reminder ghi `failed` với lỗi Resend 403 domain chưa verify.
  - Cách bảo mật: cron dùng `X-Internal-Secret` thay vì `Authorization: Bearer service_role_key`; Edge Function chỉ accept secret này từ cron/backend.

## Next Phase

- P9.2 — Dashboard automation trạng thái billing (danh sách sắp hết hạn/quá hạn, dunning, log job chạy).

## Blockers / Decisions

- None.

## Backup Location

- `C:\Users\SUACAUBA\Downloads\Project\vietsale-pro-v7_backup_admin_dashboard_p9_1_secure_reminders_20260707_082248`
- `C:\Users\SUACAUBA\Downloads\Project\vietsale-pro-v7_backup_admin_dashboard_admin-dashboard-p9-1-billing-reminders_20260707_070139` (backup trước khi refactor bảo mật)
