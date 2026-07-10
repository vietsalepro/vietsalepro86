# Handoff — Admin Dashboard Sub-phase F30

> Chat date: 2026-07-10
> Source: `PLAN_CREATE_SHOP_SUB_PHASES.md`  
> Sub-phase: **F30 — Frontend service + types**  
> Previous handoff: `HANDOFF_F29.md` (Edge Function `create-tenant` đã được deploy với adminPassword + email)

---

## Bối cảnh

- F28/F29 đã xong backend.
- Cần thêm service function để `SystemAdminDashboard` gọi Edge Function `create-tenant` một cách type-safe.
- Pattern tham khảo:
  - `services/systemAdminService.ts` (`createSystemAdmin`) <ref_snippet file="c:/Users/SUACAUBA/Downloads/Project/vietsale-pro-v7/services/systemAdminService.ts" lines="76-79" />
  - `services/operationsService.ts` (`checkSubdomain`) <ref_snippet file="c:/Users/SUACAUBA/Downloads/Project/vietsale-pro-v7/services/operationsService.ts" lines="75-90" />

**Sub-phase này không có migration SQL và không deploy production** — chỉ là code TypeScript frontend.

---

## Mục tiêu F30

1. Thêm type `CreateTenantResult` vào `types/tenant.ts`.
2. Thêm hàm `createTenantWithCredentials(input)` vào `services/tenantService.ts`.
3. Hàm gọi `supabase.functions.invoke('create-tenant', ...)` và validate response shape.
4. Xử lý lỗi rõ ràng.
5. **Không đặt tên hàm mới là `createTenant`** vì `services/tenantService.ts` đã có hàm `createTenant` khác (insert trực tiếp vào `tenants`).

---

## Files cần sửa

- `types/tenant.ts`
- `services/tenantService.ts`

---

## Hướng giải quyết chi tiết

### Bước 1 — Thêm type

Trong `types/tenant.ts`, thêm (tìm vị trí gần các interface khác):

```ts
export interface CreateTenantResult {
  tenant: Tenant;
  adminUser: {
    id: string;
    email: string;
    created_at?: string;
  };
  initialPassword: string;
}
```

### Bước 2 — Thêm service function

Trong `services/tenantService.ts`, thêm hàm sau (đặt gần `createTenantWithAdmin`):

```ts
export interface CreateTenantInput {
  name: string;
  subdomain: string;
  plan: TenantPlan;
  adminEmail: string;
  adminPassword?: string;
}

export async function createTenantWithCredentials(
  input: CreateTenantInput
): Promise<CreateTenantResult> {
  const { data, error } = await supabase.functions.invoke<
    CreateTenantResult & { error?: string }
  >('create-tenant', {
    body: {
      name: input.name.trim(),
      subdomain: input.subdomain.trim().toLowerCase(),
      email: input.adminEmail.trim().toLowerCase(),
      plan: input.plan,
      adminPassword: input.adminPassword,
    },
  });

  if (error) {
    throw new Error(error.message || 'Tạo cửa hàng thất bại');
  }

  if (
    !data ||
    typeof data !== 'object' ||
    !data.tenant ||
    !data.adminUser ||
    typeof data.adminUser.id !== 'string' ||
    typeof data.adminUser.email !== 'string' ||
    typeof data.initialPassword !== 'string'
  ) {
    throw new Error(data?.error || 'Phản hồi tạo cửa hàng không hợp lệ');
  }

  return {
    tenant: mapTenantFromDB(data.tenant),
    adminUser: data.adminUser,
    initialPassword: data.initialPassword,
  };
}
```

> ponytail: validate shape trước khi map; kiểm tra cả `adminUser.id` và `adminUser.email` để tránh UI crash khi Edge Function trả response lạ hoặc thiếu trường.

### Bước 3 — Cập nhật export/import nếu cần

`createTenantWithCredentials` và `CreateTenantInput` sẽ được import trong `SystemAdminDashboard.tsx` ở F31. Không cần export gì thêm nếu hàm đã là `export`.

### Bước 4 — Kiểm tra

```bash
npm run lint
npx vitest run
```

Nếu có test cũ mock `supabase.functions.invoke`, đảm bảo mock vẫn hoạt động.

---

## Apply lên production

- Không deploy ở sub-phase này.
- Production deploy sẽ làm ở F32 cùng với UI.

---

## Acceptance criteria

- [ ] `CreateTenantResult` type tồn tại trong `types/tenant.ts`.
- [ ] `createTenantWithCredentials(input)` tồn tại trong `services/tenantService.ts`.
- [ ] `npm run lint` PASS.
- [ ] `npx vitest run` PASS (không làm hỏng test cũ).
- [ ] Có thể import `createTenantWithCredentials` từ `services/tenantService.ts` mà không lỗi type.

---

## Test gợi ý (viết nhanh)

Viết smoke test mock `supabase.functions.invoke('create-tenant', ...)` trả về object đúng shape:

```ts
const result = await createTenantWithCredentials({
  name: 'Shop Test',
  subdomain: 'shop-test',
  plan: 'free',
  adminEmail: 'test@example.com',
});
expect(result.tenant.subdomain).toBe('shop-test');
expect(result.initialPassword).toBeDefined();
```

Nếu chưa viết test ở F30, có thể để dành cho F32.

---

## Rollback

- Revert `services/tenantService.ts` và `types/tenant.ts`.
- Không ảnh hưởng DB hay production vì chưa deploy.

---

## Đã làm xong (điền sau khi hoàn thành)

- [x] `types/tenant.ts` updated
- [x] `services/tenantService.ts` updated
- [x] `npm run lint`: PASS
- [x] `npx vitest run`: PASS (237 tests, 40 files)
- [x] Commit hash: 6e14ba18

---

## Handoff tiếp theo

Sau khi F30 xong, copy nội dung `HANDOFF_F31.md` vào chat task mới để tiếp tục sửa Dashboard UI.
