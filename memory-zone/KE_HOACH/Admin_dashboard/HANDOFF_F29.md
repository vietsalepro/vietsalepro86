# Handoff — Admin Dashboard Sub-phase F29

> Chat date: 2026-07-10  
> Source: `PLAN_CREATE_SHOP_SUB_PHASES.md`  
> Sub-phase: **F29 — Update Edge Function `create-tenant` (adminPassword + gửi email credential)**  
> Previous handoff: `HANDOFF_F28.md` (template `tenant_credentials` đã có trên production)

---

## Bối cảnh

- F28 đã xong:
  - template `tenant_credentials` đã có trong DB production.
  - CHECK constraint của `app_audit_log.action` đã được sửa để cho phép `EMAIL_FAILED`.
- Edge Function `create-tenant` hiện tại:
  - tạo tenant + subscription + membership,
  - tạo auth user với password tự sinh UUID,
  - trả về `tenant`, `adminUser`, `initialPassword`.
- Cần mở rộng để:
  1. cho phép gửi `adminPassword` tùy chọn,
  2. sau tạo thành công, gọi `send-template-email` gửi credential.

**Sub-phase này không có migration SQL mới** (migration CHECK constraint đã làm ở F28). Bước apply production là deploy Edge Function.

---

## Mục tiêu F29

1. `create-tenant` nhận thêm `adminPassword?: string`.
2. Validate password tối thiểu 6 ký tự nếu được gửi.
3. Nếu không gửi password, giữ `crypto.randomUUID()`.
4. Sau tạo tenant/membership/subscription/audit log thành công, gọi `send-template-email` với template `tenant_credentials`.
5. Lỗi gửi email chỉ ghi log, **không rollback tenant**.

---

## Files cần sửa

- `supabase/functions/create-tenant/index.ts`

---

## Hướng giải quyết chi tiết

### Bước 1 — Parse body thêm `adminPassword`

Tìm đoạn parse body:

```ts
const { name, subdomain, email, plan = 'free' } = body;
```

Sửa thành:

```ts
const { name, subdomain, email, plan = 'free', adminPassword } = body;
```

### Bước 2 — Validate password

Thêm sau validation email:

```ts
const initialPassword = typeof adminPassword === 'string' && adminPassword.length >= 6
  ? adminPassword
  : crypto.randomUUID();

if (typeof adminPassword === 'string' && adminPassword.length < 6) {
  return jsonResponse({ error: 'Mật khẩu admin phải có ít nhất 6 ký tự' }, 400);
}
```

> ponytail: chỉ validate khi adminPassword được gửi; undefined hoặc chuỗi rỗng → tự sinh UUID.

### Bước 3 — Sử dụng `initialPassword` đã tính

Tìm dòng:

```ts
const initialPassword = crypto.randomUUID();
```

Thay bằng logic ở Bước 2 (xóa dòng cũ).

Đảm bảo `supabaseAdmin.auth.admin.createUser` dùng `initialPassword`:

```ts
const { data: createUserData, error: createUserError } = await supabaseAdmin.auth.admin.createUser({
  email: email.trim().toLowerCase(),
  password: initialPassword,
  email_confirm: true,
});
```

### Bước 4 — Đồng bộ limits với Plan Builder

Thay vì hard-code `max_users / max_products / max_orders_per_month`, lấy từ Plan Builder:

```ts
const { data: limits, error: limitsError } = await supabaseAdmin.rpc(
  'get_default_plan_limit_values',
  { p_plan: plan }
);
if (limitsError) throw limitsError;

const maxUsers = (limits?.max_users as number) ?? (plan === 'vip' ? 999 : 1);
const maxProducts = (limits?.max_products as number) ?? (plan === 'vip' ? 999999 : 50);
const maxOrdersPerMonth = (limits?.max_orders_per_month as number) ?? (plan === 'vip' ? 999999 : 300);
```

Sau đó dùng các giá trị này khi insert `tenant_subscriptions`.

> ponytail: fallback trên khớp với Plan Builder (`phase_p8_1_plan_builder_schema.sql`): free = 1/50/300, vip = 999/999999/999999. KHÔNG gọi `public.create_tenant_with_admin` từ Edge Function — RPC là `SECURITY INVOKER` và check `is_system_admin()` qua `auth.uid()`, service role không có `auth.uid()` nên sẽ bị từ chối.

### Bước 5 — Gửi email credential

Sau audit log insert, thêm đoạn gửi email (best-effort):

```ts
// Best-effort: gửi email credential. Lỗi email không rollback tenant.
const { error: emailErr } = await supabaseAdmin.functions.invoke('send-template-email', {
  body: {
    template_key: 'tenant_credentials',
    to: adminUser.email,
    variables: {
      shop_name: tenant.name as string,
      shop_url: `https://${tenant.subdomain}.vietsalepro.com/`,
      admin_email: adminUser.email as string,
      admin_password: initialPassword,
    },
  },
});

if (emailErr) {
  console.error('Failed to send tenant credentials email:', emailErr);
  await supabaseAdmin.from('app_audit_log').insert({
    tenant_id: tenant.id as string,
    user_id: adminUser.id,
    table_name: 'tenants',
    record_id: tenant.id as string,
    action: 'EMAIL_FAILED',
    new_data: { error: emailErr.message || String(emailErr) },
  }).catch(() => {});
}
```

> ponytail: `supabaseAdmin.functions.invoke` trả về `{ data, error }`, không throw. Phải kiểm tra `error` rõ ràng.
> ponytail: Đoạn insert `EMAIL_FAILED` dưới đây yêu cầu migration F28 (`allow_email_failed_audit_action.sql`) đã chạy. Nếu chưa chạy, audit log insert sẽ bị DB từ chối và Edge Function trả về lỗi 500 thay vì tenant vẫn được tạo.

### Bước 6 — Sửa lỗi chính tả

Tìm `"dấu gạng ngang"` trong message lỗi subdomain, sửa thành `"dấu gạch ngang"`.

### Bước 7 — Kiểm tra CORS và method

Function hiện chỉ xử lý POST. Đảm bảo không vô tình chặn OPTIONS (logic hiện tại đã có).

---

## Apply lên production

Project linked: `rsialbfjswnrkzcxarnj`.

```bash
supabase functions deploy create-tenant
```

---

## Acceptance criteria

- [ ] Gọi `create-tenant` **không** có `adminPassword` → tạo user thành công với UUID password.
- [ ] Gọi `create-tenant` có `adminPassword` = `mypass123` → user được tạo với password đó.
- [ ] Gọi `create-tenant` có `adminPassword` ngắn hơn 6 ký tự → trả lỗi 400.
- [ ] Tạo thành công → email credential được gửi đến admin email.
- [ ] Nếu `send-template-email` lỗi (giả lập bằng cách đổi `template_key` sai chẳng hạn) → tenant vẫn được tạo, credential vẫn trả về response, và có audit log `EMAIL_FAILED`.
- [ ] Rollback vẫn hoạt động: nếu insert `tenant_subscriptions` hoặc `tenant_memberships` lỗi, auth user bị xóa.
- [ ] `tenant_subscriptions` được tạo với limits đúng theo Plan Builder (`get_default_plan_limit_values`).
- [ ] Verify `app_audit_log` cho phép `EMAIL_FAILED` (query constraint ở F28 đã pass).

---

## Test command (local/prod)

```bash
curl -X POST "https://rsialbfjswnrkzcxarnj.supabase.co/functions/v1/create-tenant" \
  -H "Authorization: Bearer <JWT_CUA_SYSTEM_ADMIN>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Shop Test F29",
    "subdomain": "shop-test-f29",
    "email": "test-f29@example.com",
    "plan": "free",
    "adminPassword": "pass123456"
  }'
```

Expected: `201 Created` với `tenant`, `adminUser`, `initialPassword: "pass123456"`.

Sau test, xóa dữ liệu test theo thứ tự:
1. Archive tenant qua UI hoặc RPC `delete_tenant_safe`.
2. Xóa audit log test liên quan đến tenant/user test.
3. Xóa `rate_limit_logs` của IP test.
4. Xóa user test khỏi `auth.users`.

> ponytail: thứ tự này tránh vi phạm FK constraint từ `tenant_memberships` và `app_audit_log` trỏ đến `auth.users`.

---

## Rollback

- Redeploy version cũ của `create-tenant` bằng git revert + `supabase functions deploy create-tenant`.
- Xóa các tenant/user test đã tạo trong quá trình verify.

---

## Đã làm xong (điền sau khi hoàn thành)

- [x] `supabase/functions/create-tenant/index.ts` updated
- [x] `supabase functions deploy create-tenant` result: **SUCCESS** on project `rsialbfjswnrkzcxarnj`
- [ ] Test with auto password result: pending (needs system admin JWT)
- [ ] Test with custom password result: pending (needs system admin JWT)
- [ ] Test email sent: pending (needs system admin JWT)
- [ ] Test email failure does not rollback tenant: pending (needs system admin JWT)
- [x] Commit hash: `af824f567aa04509f048f1aca4c3ed9f4600418c`

---

## Handoff tiếp theo

Sau khi F29 xong, copy nội dung `HANDOFF_F30.md` vào chat task mới để tiếp tục frontend service + types.
