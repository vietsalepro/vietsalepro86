# Admin Dashboard — RPC Contracts

Tài liệu này liệt kê các Supabase RPC functions được gọi bởi service layer (services/, lib/, utils/).

> ponytail: Chỉ bao gồm các RPC thực sự xuất hiện dưới dạng supabase.rpc(...). Các thao tác đọc/ghi bảng thông thường qua .from(...) không nằm trong danh sách này.

## Tổng quan

| RPC | Mục đích | Tham số chính | Trả về | File/service sử dụng |
|-----|----------|---------------|--------|----------------------|
| `accept_invitation` | Thực hiện accept invitation | `p_token` | public.tenant_memberships | services/admin/memberAdminService.ts |
| `add_system_admin` | Thêm system admin | `p_user_id` | public.system_admins | services/systemAdminService.ts |
| `adjust_customer_debt` | Điều chỉnh customer debt | `p_customer_id`, `p_amount`, `p_reason` | "jsonb" | services/supabaseService.ts |
| `adjust_supplier_debt` | Điều chỉnh supplier debt | `p_supplier_id`, `p_amount`, `p_reason` | "jsonb" | services/supabaseService.ts |
| `apply_voucher_to_invoice` | Áp dụng voucher to invoice | `p_invoice_id`, `p_code` | JSONB | services/promotionService.ts |
| `bulk_update_tenants` | Cập nhật hàng loạt update tenants | `p_tenant_ids`, `p_status?`, `p_plan?` | JSON | services/maintenanceService.ts |
| `can_use_feature` | Kiểm tra use feature | `p_tenant_id`, `p_feature_key`, `p_current_usage?` | BOOLEAN | lib/permissions.ts |
| `cancel_inventory_count_rpc` | Hủy inventory count rpc | `p_count_id` | "void" | services/supabaseService.ts |
| `cancel_order` | Hủy order | `p_order_id` | "jsonb" | services/supabaseService.ts |
| `cancel_return_order_v2` | Hủy return order v2 | `p_return_id` | "jsonb" | services/supabaseService.ts |
| `cancel_supplier_exchange` | Hủy supplier exchange | `p_exchange_id` | "jsonb" | services/supabaseService.ts |
| `check_product_barcode_exists` | Kiểm tra product barcode exists | `p_barcode` | boolean | services/supabaseService.ts |
| `check_product_code_exists` | Kiểm tra product code exists | `p_code` | BOOLEAN | services/supabaseService.ts |
| `check_stock_ledger_drift` | Kiểm tra stock ledger drift | — | TABLE("product_id" "text", "lot_id" "text", "products_quantity" numeric, "lot_sum" numeric, "movement_sum" numeric, "diff" numeric) | services/supabaseService.ts |
| `claim_heavy_op_job` | Claim heavy op job | — | public.heavy_ops_jobs | services/heavyOpsQueueService.ts |
| `complete_heavy_op_job` | Hoàn thành heavy op job | `p_job_id`, `p_status`, `p_result?`, `p_error_message?` | public.heavy_ops_jobs | services/heavyOpsQueueService.ts |
| `complete_inventory_count` | Hoàn thành inventory count | `p_count_id` | "void" | services/supabaseService.ts |
| `confirm_payment` | Xác nhận payment | `p_invoice_id`, `p_payment_method?`, `p_reference_code?`, `p_notes?` | public.payments | services/invoiceService.ts |
| `count_point_products` | Thực hiện count point products | — | integer | services/supabaseService.ts |
| `create_exchange_transaction` | Tạo exchange transaction | `p_return_id`, `p_original_order_id`, `p_customer_id`, `p_customer_name`, `p_return_items?`, `p_total_refund_amount?`, `p_gross_refund_amount?`, `p_fee_percent?`, `p_fee_amount?`, `p_days_since_purchase?`, `p_original_payment_method?`, `p_reason?`, `p_note?`, `p_debt_reduction?`, `p_cash_refund?`, `p_exchange_order_id?`, `p_exchange_items?`, `p_exchange_total?`, `p_exchange_paid_amount?`, `p_exchange_debt_recorded?`, `p_exchange_payment_method?`, `p_is_delivery?`, `p_offset_amount?`, `p_cash_diff?`, `p_allow_negative?` | "jsonb" | services/supabaseService.ts |
| `create_gdpr_request` | Tạo gdpr request | `p_user_id`, `p_type`, `p_reason?`, `p_dry_run?` | UUID | services/admin/complianceAdminService.ts |
| `create_integration` | Tạo integration | `p_partner_id`, `p_name`, `p_slug?`, `p_description?`, `p_category?`, `p_status?`, `p_documentation_url?` | JSON | services/integrationService.ts |
| `create_invoice` | Tạo invoice | `p_tenant_id`, `p_cycle_type?`, `p_quantity?`, `p_bonus_months?`, `p_notes?` | public.invoices | services/invoiceService.ts |
| `create_maintenance_window` | Tạo maintenance window | `p_title`, `p_description?`, `p_starts_at?`, `p_ends_at?` | JSON | services/maintenanceService.ts |
| `create_partner` | Tạo partner | `p_name`, `p_slug?`, `p_description?`, `p_website?`, `p_contact_email?`, `p_logo_url?` | JSON | services/integrationService.ts |
| `create_plan` | Tạo plan | `p_key`, `p_name`, `p_description?`, `p_max_users?`, `p_max_products?`, `p_max_orders_per_month?`, `p_monthly_price?`, `p_yearly_price?` | JSON | services/planService.ts |
| `create_return_order` | Tạo return order | `p_id`, `p_original_order_id`, `p_customer_id`, `p_customer_name`, `p_items`, `p_total_refund_amount`, `p_debt_reduction?`, `p_cash_refund?`, `p_reason?`, `p_note?`, `p_gross_refund_amount?`, `p_fee_percent?`, `p_fee_amount?`, `p_days_since_purchase?`, `p_original_payment_method?` | "jsonb" | services/supabaseService.ts |
| `create_supplier_exchange` | Tạo supplier exchange | `p_payload` | "jsonb" | services/supabaseService.ts |
| `create_tenant_api_key` | Tạo tenant api key | `p_tenant_id`, `p_name`, `p_version?` | JSON | services/apiKeyService.ts |
| `create_tenant_webhook` | Tạo tenant webhook | `p_tenant_id`, `p_name`, `p_url`, `p_events?`, `p_secret?` | JSON | services/webhookService.ts |
| `create_tenant_with_admin` | Tạo tenant with admin | `p_name`, `p_subdomain`, `p_plan?`, `p_owner_user_id?` | public.tenants | services/tenantService.ts |
| `delete_2fa_backup_codes` | Xóa 2fa backup codes | `p_user_id` | VOID | services/twoFactorService.ts |
| `delete_disposal_with_restore` | Xóa disposal with restore | `p_disposal_id` | "void" | services/supabaseService.ts |
| `delete_import_v2` | Xóa import v2 | `p_receipt_id` | "jsonb" | services/supabaseService.ts |
| `delete_integration` | Xóa integration | `p_integration_id` | VOID | services/integrationService.ts |
| `delete_inventory_count_rpc` | Xóa inventory count rpc | `p_count_id` | "void" | services/supabaseService.ts |
| `delete_maintenance_window` | Xóa maintenance window | `p_id` | JSON | services/maintenanceService.ts |
| `delete_order` | Xóa order | `p_order_id` | "jsonb" | services/supabaseService.ts |
| `delete_partner` | Xóa partner | `p_partner_id` | VOID | services/integrationService.ts |
| `delete_plan` | Xóa plan | `p_key` | BOOLEAN | services/planService.ts |
| `delete_tenant_safe` | Xóa tenant safe | `p_tenant_id` | public.tenants | services/tenantService.ts |
| `delete_tenant_webhook` | Xóa tenant webhook | `p_webhook_id` | VOID | services/webhookService.ts |
| `enqueue_heavy_op_job` | Thêm vào hàng heavy op job | `p_tenant_id`, `p_job_type`, `p_payload?`, `p_max_attempts?`, `p_scheduled_at?` | "public"."heavy_ops_jobs" | services/heavyOpsQueueService.ts |
| `export_tenant_data` | Xuất tenant data | `p_tenant_id` | JSON | services/complianceService.ts |
| `filter_customers_rpc` | Thực hiện filter customers rpc | `p_search_term?`, `p_page?`, `p_page_size?`, `p_sort_by?`, `p_sort_order?`, `p_min_points?`, `p_max_points?`, `p_has_debt?` | json | services/supabaseService.ts |
| `filter_disposals_rpc` | Thực hiện filter disposals rpc | `p_search_term?`, `p_page?`, `p_page_size?`, `p_from_date?`, `p_to_date?`, `p_status?` | json | services/supabaseService.ts |
| `filter_import_receipts_rpc` | Thực hiện filter import receipts rpc | `p_search_term?`, `p_page?`, `p_page_size?`, `p_from_date?`, `p_to_date?`, `p_supplier_id?`, `p_status?` | json | services/supabaseService.ts |
| `filter_products_rpc` | Thực hiện filter products rpc | `p_search_term?`, `p_page?`, `p_page_size?`, `p_category_id?`, `p_brand_id?`, `p_sort_by?`, `p_sort_order?`, `p_stock_status?` | JSON | services/supabaseService.ts |
| `filter_return_orders_rpc` | Thực hiện filter return orders rpc | `p_search_term?`, `p_page?`, `p_page_size?`, `p_from_date?`, `p_to_date?`, `p_status?` | json | services/supabaseService.ts |
| `filter_suppliers_rpc` | Thực hiện filter suppliers rpc | `p_search_term?`, `p_page?`, `p_page_size?`, `p_sort_by?`, `p_sort_order?` | json | services/supabaseService.ts |
| `gdpr_delete_user_data` | Thực hiện gdpr delete user data | `p_user_id`, `p_dry_run?` | JSON | services/admin/complianceAdminService.ts |
| `gdpr_export_user_data` | Thực hiện gdpr export user data | `p_user_id` | JSON | services/admin/complianceAdminService.ts |
| `generate_2fa_backup_codes` | Sinh 2fa backup codes | `p_user_id`, `p_count?` | JSON | services/twoFactorService.ts |
| `generate_tenant_license` | Sinh tenant license | `p_tenant_id`, `p_plan`, `p_max_users?`, `p_max_products?`, `p_max_orders_per_month?`, `p_expires_at?` | public.licenses | services/admin/licenseService.ts |
| `get_admin_login_alerts` | Lấy admin login alerts | `p_hours_ago?` | JSON | services/loginHistoryService.ts |
| `get_admin_login_history` | Lấy admin login history | `p_limit?`, `p_offset?`, `p_status?`, `p_date_from?`, `p_date_to?` | JSON | services/loginHistoryService.ts |
| `get_billing_automation_status` | Lấy billing automation status | — | JSONB | services/billingAutomationService.ts |
| `get_billing_job_logs` | Lấy billing job logs | `p_limit?` | TABLE("id" "uuid", "job_name" "text", "status" "text", "run_at" timestamp with time zone, "duration_ms" integer, "records_affected" integer, "message" "text", "details" "jsonb", "created_at" timestamp with time zone) | services/billingAutomationService.ts |
| `get_billing_reminder_config` | Lấy billing reminder config | — | JSONB | services/billingReminderService.ts |
| `get_brand_product_counts` | Lấy brand product counts | — | json | services/supabaseService.ts |
| `get_category_product_counts` | Lấy category product counts | — | json | services/supabaseService.ts |
| `get_churn_cohort_metrics` | Lấy churn cohort metrics | `p_start_date?`, `p_end_date?`, `p_cohort_months?` | JSON | services/admin/analyticsAdminService.ts, services/billingAutomationService.ts |
| `get_connection_pool_stats` | Lấy connection pool stats | — | JSONB | services/heavyOpsQueueService.ts |
| `get_current_announcements_for_tenant` | Lấy current announcements for tenant | `p_tenant_id?` | TABLE ( id UUID, title TEXT, content TEXT, target_type TEXT, targets JSONB, status TEXT, scheduled_at TIMESTAMPTZ, published_at TIMESTAMPTZ, expires_at TIMESTAMPTZ, audience TEXT, active_from TIMESTAMPTZ, active_to TIMESTAMPTZ, created_by UUID, created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ ) | services/announcementService.ts |
| `get_current_user_tenants` | Lấy current user tenants | — | JSON | services/tenantService.ts |
| `get_customer_debt_ledger` | Lấy customer debt ledger | `p_customer_id`, `p_limit?`, `p_offset?` | json | services/supabaseService.ts |
| `get_customer_report` | Lấy customer report | `p_start_date`, `p_end_date` | json | services/supabaseService.ts |
| `get_customer_stats` | Lấy customer stats | — | json | services/supabaseService.ts |
| `get_dashboard_summary` | Lấy dashboard summary | `p_from?`, `p_to?` | json | services/supabaseService.ts |
| `get_data_retention_config` | Lấy data retention config | — | JSON | services/fraudRetentionService.ts |
| `get_data_retention_status` | Lấy data retention status | — | JSON | services/operationsService.ts |
| `get_default_plan_limits` | Lấy default plan limits | — | JSON | services/operationsService.ts |
| `get_disposal_auto_code` | Lấy disposal auto code | — | "text" | services/supabaseService.ts |
| `get_fraud_detection_config` | Lấy fraud detection config | — | JSON | services/fraudRetentionService.ts |
| `get_fraud_queue` | Lấy fraud queue | `p_status?`, `p_severity?`, `p_limit?`, `p_offset?` | JSON | services/fraudRetentionService.ts |
| `get_fraud_stats` | Lấy fraud stats | — | JSON | services/fraudRetentionService.ts |
| `get_gdpr_requests` | Lấy gdpr requests | `p_status?`, `p_type?`, `p_limit?`, `p_offset?` | JSON | services/admin/complianceAdminService.ts |
| `get_heavy_op_jobs` | Lấy heavy op jobs | `p_tenant_id?`, `p_status?`, `p_limit?`, `p_offset?` | TABLE("id" "uuid", "tenant_id" "uuid", "job_type" "text", "payload" "jsonb", "status" "text", "attempts" integer, "max_attempts" integer, "error_message" "text", "result" "jsonb", "scheduled_at" timestamp with time zone, "created_at" timestamp with time zone, "updated_at" timestamp with time zone) | services/heavyOpsQueueService.ts |
| `get_import_receipt_count_by_date` | Lấy import receipt count by date | `p_date` | integer | services/supabaseService.ts |
| `get_import_receipts_by_product_and_lot` | Lấy import receipts by product and lot | `p_product_id`, `p_lot_id?` | json | services/supabaseService.ts |
| `get_import_receipts_by_supplier_id` | Lấy import receipts by supplier id | `p_supplier_id`, `p_limit?` | json | services/supabaseService.ts |
| `get_import_stats` | Lấy import stats | `p_from_date?`, `p_to_date?` | json | services/supabaseService.ts |
| `get_in_app_messages_for_tenant` | Lấy in app messages for tenant | `p_tenant_id?`, `p_limit?`, `p_offset?` | TABLE ( id UUID, tenant_id UUID, channel TEXT, title TEXT, content TEXT, status TEXT, error_message TEXT, metadata JSONB, sent_by UUID, created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ ) | services/notificationService.ts |
| `get_inventory_report` | Lấy inventory report | `p_start_date`, `p_end_date`, `p_category?`, `p_stock_status?` | JSON | services/supabaseService.ts |
| `get_locked_emails` | Lấy locked emails | — | JSONB | services/systemAdminService.ts |
| `get_login_attempts` | Lấy login attempts | `p_email?`, `p_limit?`, `p_offset?` | JSONB | services/systemAdminService.ts |
| `get_maintenance_mode` | Lấy maintenance mode | — | JSONB | services/operationsService.ts |
| `get_maintenance_windows` | Lấy maintenance windows | `p_start?`, `p_end?` | JSON | services/maintenanceService.ts |
| `get_order_auto_code` | Lấy order auto code | — | "text" | utils/invoiceNumber.ts |
| `get_pending_billing_reminders` | Lấy pending billing reminders | — | TABLE ( invoice_id UUID, milestone TEXT, due_date DATE ) | services/billingReminderService.ts |
| `get_plan_by_key` | Lấy plan by key | `p_key` | JSON | services/planService.ts |
| `get_plans` | Lấy plans | — | JSON | services/planService.ts |
| `get_product_by_barcode` | Lấy product by barcode | `p_barcode` | TABLE ( id TEXT, name TEXT, display_name TEXT, code TEXT, barcode TEXT, price NUMERIC, cost NUMERIC, quantity NUMERIC, unit TEXT, location TEXT, category TEXT, brand TEXT, image TEXT, min_stock NUMERIC, max_stock NUMERIC, safety_stock NUMERIC, is_point_accumulation_enabled BOOLEAN, conversion_units JSONB, created_at TIMESTAMPTZ, has_lots BOOLEAN, category_id TEXT, brand_id TEXT, product_lots JSONB ) | services/supabaseService.ts |
| `get_product_stats` | Lấy product stats | — | json | services/supabaseService.ts |
| `get_profit_report` | Lấy profit report | `p_start_date`, `p_end_date`, `p_status?`, `p_payment_method?`, `p_product_keyword?`, `p_customer_keyword?`, `p_compare_mode?` | json | services/supabaseService.ts |
| `get_promo_code_usage_counts` | Lấy promo code usage counts | `p_promo_code_id` | JSONB | services/promotionService.ts |
| `get_rate_limit_logs` | Lấy rate limit logs | `p_limit?`, `p_offset?` | JSON | services/systemAdminService.ts |
| `get_read_replica_status` | Lấy read replica status | — | JSONB | services/heavyOpsQueueService.ts |
| `get_return_order_auto_code` | Lấy return order auto code | — | "text" | services/supabaseService.ts |
| `get_revenue_metrics` | Lấy revenue metrics | `p_start_date?`, `p_end_date?` | JSON | services/admin/analyticsAdminService.ts, services/billingAutomationService.ts |
| `get_sales_report` | Lấy sales report | `p_start_date`, `p_end_date`, `p_status?`, `p_payment_method?`, `p_product_keyword?`, `p_customer_keyword?` | json | services/supabaseService.ts |
| `get_stock_ledger` | Lấy stock ledger | `p_product_id`, `p_from_date`, `p_to_date`, `p_lot_id?`, `p_voucher_type?`, `p_is_cancelled?`, `p_limit?`, `p_offset?` | TABLE("id" "uuid", "posting_date" timestamp with time zone, "voucher_type" "text", "voucher_no" "text", "voucher_detail_no" "text", "product_id" "text", "product_name" "text", "lot_id" "text", "lot_code" "text", "warehouse" "text", "actual_qty" numeric, "qty_after_transaction" numeric, "valuation_rate" numeric, "incoming_rate" numeric, "outgoing_rate" numeric, "stock_value" numeric, "balance_value" numeric, "reason" "text", "is_cancelled" boolean, "created_at" timestamp with time zone) | services/supabaseService.ts |
| `get_supplier_debt_ledger` | Lấy supplier debt ledger | `p_supplier_id`, `p_limit?`, `p_offset?` | json | services/supabaseService.ts |
| `get_supplier_report` | Lấy supplier report | `p_start_date`, `p_end_date` | json | services/supabaseService.ts |
| `get_supplier_stats` | Lấy supplier stats | — | json | services/supabaseService.ts |
| `get_system_admins` | Lấy system admins | — | JSON | services/systemAdminService.ts |
| `get_system_overview` | Lấy system overview | — | JSON | services/tenantService.ts |
| `get_tenant_by_domain` | Lấy tenant by domain | `p_domain` | public.tenants | lib/tenant.ts |
| `get_tenant_by_subdomain` | Lấy tenant by subdomain | `p_subdomain` | public.tenants | lib/tenant.ts |
| `get_tenant_feature_flags` | Lấy tenant feature flags | `p_tenant_id` | JSONB | services/tenantService.ts |
| `get_tenant_growth` | Lấy tenant growth | `p_months?` | JSON | services/tenantService.ts |
| `get_tenant_members_with_email` | Lấy tenant members with email | `p_tenant_id` | JSON | services/tenantService.ts |
| `get_tenant_security_settings` | Lấy tenant security settings | `p_tenant_id` | JSONB | services/systemAdminService.ts |
| `get_tenant_storage_usage` | Lấy tenant storage usage | — | JSON | services/tenantService.ts |
| `get_tenant_usage_summary` | Lấy tenant usage summary | `p_tenant_id` | JSON | services/admin/memberAdminService.ts, services/tenantService.ts |
| `get_tenants_admin` | Lấy tenants admin | `p_page?`, `p_limit?`, `p_search?`, `p_status?`, `p_plan?`, `p_sort_by?`, `p_sort_order?` | JSON | services/tenantService.ts |
| `get_terms_acceptances` | Lấy terms acceptances | `p_tenant_id?`, `p_terms_type?`, `p_limit?`, `p_offset?` | JSON | services/complianceService.ts |
| `get_top_tenants` | Lấy top tenants | `p_limit?`, `p_offset?` | JSON | services/tenantService.ts |
| `get_unsynced_brands` | Lấy unsynced brands | — | json | services/supabaseService.ts |
| `get_unsynced_categories` | Lấy unsynced categories | — | json | services/supabaseService.ts |
| `has_tenant_role` | Kiểm tra tenant role | `p_tenant_id`, `p_role` | BOOLEAN | lib/permissions.ts |
| `increment_product_quantity` | Thực hiện increment product quantity | `p_product_id`, `p_quantity` | "void" | services/supabaseService.ts |
| `is_2fa_enabled` | Kiểm tra 2fa enabled | `p_user_id` | BOOLEAN | services/twoFactorService.ts |
| `is_system_admin` | Kiểm tra system admin | — | BOOLEAN | lib/permissions.ts, services/tenantService.ts |
| `is_tenant_owner` | Kiểm tra tenant owner | `p_tenant_id` | BOOLEAN | lib/permissions.ts |
| `list_2fa_backup_codes` | Liệt kê 2fa backup codes | `p_user_id` | JSON | services/twoFactorService.ts |
| `list_integrations` | Liệt kê integrations | — | JSON | services/integrationService.ts |
| `list_partners` | Liệt kê partners | — | JSON | services/integrationService.ts |
| `list_tenant_api_keys` | Liệt kê tenant api keys | `p_tenant_id` | JSON | services/apiKeyService.ts |
| `list_tenant_webhooks` | Liệt kê tenant webhooks | `p_tenant_id` | JSON | services/webhookService.ts |
| `list_webhook_deliveries` | Liệt kê webhook deliveries | `p_webhook_id`, `p_limit?`, `p_offset?` | JSON | services/webhookService.ts |
| `lookup_invitation` | Thực hiện lookup invitation | `p_token` | TABLE( tenant_id UUID, tenant_name TEXT, tenant_subdomain TEXT, tenant_custom_domain TEXT, role TEXT, email TEXT, active BOOLEAN, expired BOOLEAN ) | services/admin/memberAdminService.ts |
| `mark_in_app_message_read` | Đánh dấu in app message read | `p_log_id`, `p_tenant_id?` | BOOLEAN | services/notificationService.ts |
| `migrate_tenant_data` | Migrate tenant data | `p_source_tenant_id`, `p_target_tenant_id` | JSONB | services/tenantMigrationService.ts |
| `pay_order_debt` | Thực hiện pay order debt | `p_order_id`, `p_amount` | "jsonb" | services/supabaseService.ts |
| `pay_supplier_debt` | Thực hiện pay supplier debt | `p_receipt_id`, `p_amount` | "jsonb" | services/supabaseService.ts |
| `process_checkout` | Thực hiện process checkout | `p_order`, `p_items?`, `p_deltas?`, `p_reward_deltas?`, `p_customer_update?`, `p_point_history?`, `p_allow_negative?`, `p_op_id?` | JSONB | services/supabaseService.ts |
| `process_import_v2` | Thực hiện process import v2 | `p_payload` | "jsonb" | services/supabaseService.ts |
| `record_admin_login` | Ghi admin login | `p_user_id`, `p_email?`, `p_ip_address?`, `p_user_agent?`, `p_status?`, `p_failure_reason?` | UUID | services/loginHistoryService.ts |
| `record_login_attempt` | Ghi login attempt | `p_email`, `p_ip_address`, `p_success?` | UUID | services/systemAdminService.ts |
| `record_terms_acceptance` | Ghi terms acceptance | `p_user_id`, `p_tenant_id?`, `p_terms_version?`, `p_terms_type?`, `p_ip_address?`, `p_user_agent?`, `p_metadata?` | UUID | services/complianceService.ts |
| `remove_system_admin` | Xóa system admin | `p_user_id` | BOOLEAN | services/systemAdminService.ts |
| `remove_tenant_member` | Xóa tenant member | `p_tenant_id`, `p_user_id` | void | services/tenantService.ts |
| `reset_demo_data` | Reset demo data | `p_tenant_id` | JSONB | services/tenantMigrationService.ts |
| `reset_monthly_order_counter` | Reset monthly order counter | `p_tenant_id` | public.tenant_subscriptions | services/tenantService.ts |
| `retry_heavy_op_job` | Thử lại heavy op job | `p_job_id` | public.heavy_ops_jobs | services/heavyOpsQueueService.ts |
| `retry_webhook_delivery` | Thử lại webhook delivery | `p_delivery_id` | JSON | services/webhookService.ts |
| `revoke_tenant_api_key` | Thu hồi tenant api key | `p_key_id` | public.tenant_api_keys | services/apiKeyService.ts |
| `run_data_retention` | Chạy data retention | — | JSON | services/fraudRetentionService.ts |
| `run_fraud_detection` | Chạy fraud detection | — | JSON | services/fraudRetentionService.ts |
| `search_customers_rpc` | Tìm kiếm customers rpc | `search_term` | SETOF "public"."customers" | services/supabaseService.ts |
| `search_orders_rpc` | Tìm kiếm orders rpc | `p_search_term`, `p_limit?` | json | services/supabaseService.ts |
| `search_products_rpc` | Tìm kiếm products rpc | `p_search_term?`, `p_limit?` | TABLE ( id TEXT, name TEXT, display_name TEXT, code TEXT, barcode TEXT, price NUMERIC, cost NUMERIC, quantity NUMERIC, unit TEXT, location TEXT, category TEXT, brand TEXT, image TEXT, min_stock NUMERIC, max_stock NUMERIC, safety_stock NUMERIC, is_point_accumulation_enabled BOOLEAN, conversion_units JSONB, created_at TIMESTAMPTZ, has_lots BOOLEAN, category_id TEXT, brand_id TEXT, product_lots JSONB ) | services/supabaseService.ts |
| `search_suppliers_rpc` | Tìm kiếm suppliers rpc | `p_search_term?`, `p_limit?` | SETOF "public"."suppliers" | services/supabaseService.ts |
| `search_tenant_members` | Tìm kiếm tenant members | `p_tenant_id`, `p_search?`, `p_role?`, `p_status?`, `p_is_active?`, `p_sort_by?`, `p_sort_dir?`, `p_page?`, `p_page_size?` | json | services/tenantService.ts |
| `search_tenants` | Tìm kiếm tenants | `p_search_term?`, `p_status?`, `p_plan?`, `p_page?`, `p_page_size?` | JSON | services/tenantService.ts |
| `send_billing_reminders` | Gửi billing reminders | — | JSONB | services/billingReminderService.ts |
| `send_in_app_message` | Gửi in app message | `p_tenant_id`, `p_title`, `p_content`, `p_metadata?` | public.notification_logs | services/notificationService.ts |
| `set_billing_reminder_config` | Thiết lập billing reminder config | `p_enabled`, `p_milestones`, `p_send_time?`, `p_function_url?`, `p_reminder_secret?` | "jsonb" | services/billingReminderService.ts |
| `set_data_retention_config` | Thiết lập data retention config | `p_retention_days_orders?`, `p_retention_days_processed_operations?`, `p_retention_days_rate_limit_logs?`, `p_retention_days_fraud_queue?`, `p_retention_days_registration_events?`, `p_cron_schedule?` | JSON | services/fraudRetentionService.ts |
| `set_default_plan_limits` | Thiết lập default plan limits | `p_plan`, `p_max_users`, `p_max_products`, `p_max_orders_per_month` | JSONB | services/operationsService.ts |
| `set_fraud_detection_config` | Thiết lập fraud detection config | `p_enabled?`, `p_ip_window_hours?`, `p_ip_max?`, `p_email_domain_window_hours?`, `p_email_domain_max?`, `p_owner_window_hours?`, `p_owner_max?` | JSON | services/fraudRetentionService.ts |
| `set_maintenance_mode` | Thiết lập maintenance mode | `p_enabled`, `p_message?` | JSONB | services/operationsService.ts |
| `set_tenant_subdomain` | Thiết lập tenant subdomain | `p_tenant_id`, `p_subdomain` | public.tenants | services/admin/tenantAdminService.ts |
| `toggle_tenant_member_active` | Bật/tắt tenant member active | `p_tenant_id`, `p_user_id`, `p_is_active` | public.tenant_memberships | services/tenantService.ts |
| `trigger_webhook_event` | Kích hoạt webhook event | `p_tenant_id`, `p_event_type`, `p_payload?`, `p_idempotency_key?` | JSON | services/webhookService.ts |
| `unlock_login_attempts` | Mở khóa login attempts | `p_email` | VOID | services/systemAdminService.ts |
| `update_fraud_queue_status` | Cập nhật fraud queue status | `p_id`, `p_status`, `p_notes?` | JSON | services/fraudRetentionService.ts |
| `update_import_v2` | Cập nhật import v2 | `p_receipt_id`, `p_payload` | "jsonb" | services/supabaseService.ts |
| `update_integration` | Cập nhật integration | `p_integration_id`, `p_partner_id?`, `p_name?`, `p_slug?`, `p_description?`, `p_category?`, `p_status?`, `p_documentation_url?` | JSON | services/integrationService.ts |
| `update_maintenance_window` | Cập nhật maintenance window | `p_id`, `p_title?`, `p_description?`, `p_starts_at?`, `p_ends_at?`, `p_status?` | JSON | services/maintenanceService.ts |
| `update_partner` | Cập nhật partner | `p_partner_id`, `p_name?`, `p_slug?`, `p_description?`, `p_website?`, `p_contact_email?`, `p_logo_url?`, `p_status?` | JSON | services/integrationService.ts |
| `update_plan` | Cập nhật plan | `p_key`, `p_name?`, `p_description?`, `p_max_users?`, `p_max_products?`, `p_max_orders_per_month?`, `p_monthly_price?`, `p_yearly_price?`, `p_is_active?` | JSON | services/planService.ts |
| `update_tenant` | Cập nhật tenant | `p_tenant_id`, `p_name?`, `p_plan?`, `p_status?`, `p_isolation_mode?`, `p_isolation_schema?`, `p_isolation_project_ref?`, `p_custom_domain?`, `p_white_label?`, `p_read_replica_url?`, `p_connection_pool_config?` | public.tenants | services/tenantService.ts |
| `update_tenant_feature_flags` | Cập nhật tenant feature flags | `p_tenant_id`, `p_features` | JSONB | services/tenantService.ts |
| `update_tenant_ip_allowlist` | Cập nhật tenant ip allowlist | `p_tenant_id`, `p_allowed_ips` | VOID | services/systemAdminService.ts |
| `update_tenant_member_role` | Cập nhật tenant member role | `p_tenant_id`, `p_user_id`, `p_role` | public.tenant_memberships | services/tenantService.ts |
| `update_tenant_session_timeout` | Cập nhật tenant session timeout | `p_tenant_id`, `p_minutes` | VOID | services/systemAdminService.ts |
| `update_tenant_subscription` | Cập nhật tenant subscription | `p_tenant_id`, `p_plan?`, `p_max_users?`, `p_max_products?`, `p_max_orders_per_month?`, `p_max_storage_gb?`, `p_billing_status?`, `p_expires_at?` | public.tenant_subscriptions | services/tenantService.ts |
| `update_tenant_webhook` | Cập nhật tenant webhook | `p_webhook_id`, `p_name?`, `p_url?`, `p_events?`, `p_secret?`, `p_status?` | JSON | services/webhookService.ts |
| `validate_promo_code` | Xác thực promo code | `p_code`, `p_tenant_id`, `p_invoice_subtotal?` | JSONB | services/promotionService.ts |
| `validate_tenant_license` | Xác thực tenant license | `p_license_key` | TABLE ( valid BOOLEAN, license_id UUID, tenant_id UUID, plan TEXT, reason TEXT ) | services/admin/licenseService.ts |
| `verify_2fa_backup_code` | Thực hiện verify 2fa backup code | `p_user_id`, `p_code` | JSON | services/twoFactorService.ts |

## Ghi chú

- Tài liệu được tái sinh từ supabase/migrations/*.sql (nguồn canonical) và các file service layer.
- Cột Mục đích được tự động sinh từ tên hàm để làm tài liệu tham khảo; nội dung nghiệp vụ chi tiết cần xác nhận với Product Owner.
- Các RPC trong services/supabaseService.ts thuộc về ứng dụng POS chính và vẫn được liệt kê vì nằm trong phạm vi cross-check của services/.

*End of Admin Dashboard — RPC Contracts*
