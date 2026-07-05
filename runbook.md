# Runbook vận hành — VietSales Pro v7 Multi-Tenant

> Phiên bản: 1.0  
> Cập nhật: 2026-07-05  
> Áp dụng cho: production + staging multi-tenant Supabase project

---

## 1. Tổng quan vận hành

Hệ thống VietSales Pro v7 chạy trên nền React SPA + Vite + Supabase, multi-tenant theo subdomain. Runbook này tập trung các thao tác cần thiết để vận hành ổn định, xử lý sự cố thường gặp và đảm bảo data retention / backup / monitoring.

---

## 2. Backup strategy

### 2.1. Giai đoạn đầu (Free plan / chưa bật PITR)

Chạy định kỳ bằng Supabase CLI:

```bash
# Link project (chỉ cần 1 lần)
supabase link --project-ref <PROJECT_REF>

# Backup schema + data
supabase db dump -f backups/vietsale_pro_$(date +%Y%m%d_%H%M%S).sql

# Backup remote config (auth, storage, edge functions)
supabase config dump -f backups/config_$(date +%Y%m%d_%H%M%S).toml
```

Lưu file backup vào nơi an toàn (cloud storage, S3, NAS). Giữ tối thiểu 7 bản gần nhất.

### 2.2. Khi vận hành thật (bắt buộc nâng Pro)

- Nâng project lên Supabase Pro.
- Bật PITR (Point-in-Time Recovery) trong dashboard.
- Test restore ít nhất 1 lần sau khi bật PITR.
- Vẫn giữ `supabase db dump` định kỳ (hàng tuần) làm bản dự phòng ngoài PITR.

### 2.3. Restore từ SQL dump (không PITR)

1. Dừng traffic frontend (turn off deploy / maintenance mode).
2. Tạo project staging từ backup trước để test:
   ```bash
   supabase db reset
   psql -h <STAGING_HOST> -U postgres -d postgres < backups/vietsale_pro_YYYYMMDD_HHMMSS.sql
   ```
3. Nếu staging pass, chạy trên production:
   ```bash
   psql -h <PROD_HOST> -U postgres -d postgres < backups/vietsale_pro_YYYYMMDD_HHMMSS.sql
   ```
4. Verify: mở app, kiểm tra tenant đầu, đăng nhập, đọc/ghi 1 bản ghi.

### 2.4. Restore từ PITR

1. Vào Supabase Dashboard → Database → Backups → Point-in-Time Recovery.
2. Chọn thời điểm restore (trước thời điểm sự cố vài phút).
3. Xác nhận restore. Project sẽ tạm dừng trong vài phút.
4. Sau restore, verify tenant isolation, RLS, và cron job `data-retention-daily`.

---

## 3. Monitoring

### 3.1. Supabase Log Explorer

- Mở Dashboard → Logs → Log Explorer.
- Tạo saved query theo dõi lỗi RLS / auth / edge functions:
  ```
  metadata.level = 'error' OR metadata.status_code >= 400
  ```
- Kiểm tra hàng ngày, đặc biệt sau deploy.

### 3.2. Disk usage alert

- Trong Dashboard → Database → Reports hoặc Integrations.
- Cấu hình alert khi disk usage > 80%.
- Hành động: chạy `CALL public.run_data_retention();` thủ công, xem xét nâng cấp storage, archive thêm dữ liệu cũ.

### 3.3. Tenant / user growth alert

- Chạy query hàng tuần:
  ```sql
  SELECT
    DATE_TRUNC('day', created_at) AS day,
    COUNT(*) FILTER (WHERE status = 'active') AS active_tenants,
    COUNT(*) AS total_tenants
  FROM public.tenants
  GROUP BY day
  ORDER BY day DESC
  LIMIT 7;

  SELECT
    DATE_TRUNC('day', created_at) AS day,
    COUNT(*) AS new_users
  FROM auth.users
  GROUP BY day
  ORDER BY day DESC
  LIMIT 7;
  ```
- Nếu tăng đột biến > 200% so với ngày trước: kiểm tra log, xác minh không bị spam tạo tenant, xem rate_limit_logs.

---

## 4. Data retention

### 4.1. Cron job

- Job `data-retention-daily` chạy lúc 03:00 hàng ngày.
- Gọi `CALL public.run_data_retention();`.

### 4.2. Nội dung retention

- Archive đơn hàng > 2 năm vào `public.orders_archive` + `public.order_items_archive`.
- Xóa `public.processed_operations` cũ > 90 ngày.
- Xóa `public.rate_limit_logs` cũ > 24 giờ.
- Xóa partition cũ của `public.app_audit_log_partitioned` > 24 tháng (nếu đã chuyển sang partitioned).

### 4.3. Chạy thủ công

```sql
CALL public.run_data_retention();
```

### 4.4. Kiểm tra kết quả

```sql
SELECT COUNT(*) FROM public.orders_archive;
SELECT COUNT(*) FROM public.order_items_archive;
SELECT COUNT(*) FROM public.rate_limit_logs WHERE created_at < now() - INTERVAL '24 hours';
SELECT COUNT(*) FROM public.processed_operations WHERE created_at < now() - INTERVAL '90 days';
```

---

## 5. Xử lý sự cố thường gặp

### 5.1. Tenant bị suspend

1. Kiểm tra status:
   ```sql
   SELECT id, name, subdomain, status, plan, expires_at
   FROM public.tenants
   WHERE subdomain = '<tenant_subdomain>';
   ```
2. Nếu `status = 'suspended'`:
   - Liên hệ chủ tenant qua email / phone trong `tenants.settings`.
   - Xác nhận lý do (hết hạn subscription, vi phạm, yêu cầu chủ tenant).
3. Reactivate:
   ```sql
   UPDATE public.tenants
   SET status = 'active', updated_at = now()
   WHERE id = '<tenant_id>';
   ```
4. Kiểm tra `tenant_subscriptions` nếu suspend do hết hạn hoặc vượt giới hạn.

### 5.2. User quên mật khẩu

1. Sử dụng Edge Function `reset-password`:
   - Frontend: gọi `/functions/v1/reset-password` với email và subdomain.
   - Kiểm tra email thuộc tenant của subdomain.
2. Nếu user không còn active hoặc cần gán lại quyền:
   - Sử dụng Edge Function `invite-member` với role phù hợp.
   - Hoặc system admin tạo user mới và thêm vào `tenant_memberships`.

### 5.3. Data isolation bug (tenant A thấy dữ liệu tenant B)

1. Kiểm tra custom fetch wrapper gửi header `x-tenant-id`:
   - Header phải được lấy từ subdomain, không từ `localStorage`.
2. Kiểm tra `current_tenant_id()` trong Supabase:
   ```sql
   SELECT public.current_tenant_id();
   ```
3. Kiểm tra RLS policies trên bảng bị lộ dữ liệu:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = '<table_name>';
   ```
4. Kiểm tra `tenant_id` của records bị lộ:
   ```sql
   SELECT tenant_id, COUNT(*) FROM <table_name> GROUP BY tenant_id;
   ```
5. Fix: cập nhật RLS policy hoặc sửa custom fetch wrapper, rồi test lại với 2 tenant khác nhau.

### 5.4. Migration failed

1. Ngừng chạy migration mới.
2. Kiểm tra lỗi trong Supabase Logs / SQL editor output.
3. Nếu có rủi ro data loss:
   - Chuyển maintenance mode (tắt frontend deploy).
   - Restore từ backup gần nhất (xem mục 2.3 / 2.4).
4. Sau restore, verify acceptance criteria trước khi bật lại traffic.

### 5.5. Audit log không hoạt động hoặc chậm

1. Kiểm tra trigger `trg_audit_log_*` trên các bảng.
2. Kiểm tra dung lượng `public.app_audit_log`:
   ```sql
   SELECT pg_size_pretty(pg_total_relation_size('public.app_audit_log'));
   ```
3. Nếu > 10M rows hoặc > vài GB: lập kế hoạch chuyển sang `public.app_audit_log_partitioned`.
4. Đảm bảo chỉ tenant admin / system admin mới xem được audit log.

---

## 6. Kiểm tra định kỳ (checklist)

- [ ] Hàng ngày: kiểm tra Log Explorer, disk usage.
- [ ] Hàng tuần: chạy backup `supabase db dump`, review tenant/user growth.
- [ ] Hàng tháng: verify `run_data_retention()` hoạt động, kiểm tra archive tables.
- [ ] Hàng quý: test restore từ backup hoặc PITR.
- [ ] Hàng năm: review retention policy, backup strategy, và lộ trình nâng cấp PITR.

---

## 7. Liên hệ & tài liệu liên quan

- Kế hoạch chi tiết: `memory-zone/KE_HOACH/NHOM_1/KE_HOACH_CHI_TIET_MULTI_TENANCY_SUB_PHASE.md` section Phase 17.
- Migration: `supabase/migrations/20250705000017_phase17_long_term_operations.sql`.
- Edge Functions: `supabase/functions/reset-password`, `supabase/functions/invite-member`.
