# Integration Testing Guide for System Admin Creation

## Overview
This guide provides manual testing steps for sub-phase 7 integration testing of the system admin creation feature.

## Prerequisites
1. Edge function `create-system-admin` deployed to staging/production
2. Frontend changes deployed to staging/production
3. Access to Supabase dashboard for verification
4. System admin account for testing

## Test Environment Variables
```bash
VITE_SUPABASE_URL=your_staging_url
VITE_SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

## Test Cases

### 1. End-to-End Flow Test

**Steps:**
1. Login as system admin to admin dashboard
2. Navigate to "System Admins" tab
3. Enter email: `test-admin@example.com`
4. Enter password: `testPassword123`
5. Click "Thêm" button
6. Verify success message appears
7. Verify new admin appears in the list

**Verification:**
- [ ] Success message shows "Đã thêm system admin thành công"
- [ ] New admin appears in system admins list with correct email
- [ ] Form is cleared after success
- [ ] No error messages in console

**Database Verification:**
```sql
-- Check auth.users
SELECT id, email, created_at FROM auth.users WHERE email = 'test-admin@example.com';

-- Check system_admins
SELECT user_id, email, created_at FROM system_admins WHERE email = 'test-admin@example.com';

-- Check audit log
SELECT * FROM app_audit_log WHERE action = 'create_system_admin' ORDER BY created_at DESC LIMIT 1;
```

**Expected Results:**
- User exists in `auth.users` with correct email
- User exists in `system_admins` with correct user_id and email
- Audit log entry exists with action='create_system_admin', target_user_id, email, creator_id

---

### 2. Edge Cases Testing

#### 2.1 Special Characters in Email

**Test Emails:**
- `admin+test@example.com`
- `admin.test@example.com`
- `admin-test@example.com`
- `admin_test@example.com`

**Steps:**
1. For each test email, repeat the end-to-end flow
2. Verify each is handled correctly

**Expected Results:**
- All special characters are accepted
- Email is normalized (trim + lowercase)
- User is created successfully

#### 2.2 Very Long Password

**Test Password:** `a` (repeated 200 times)

**Steps:**
1. Enter email: `long-password@example.com`
2. Enter password: 200 character string
3. Submit form

**Expected Results:**
- Password is accepted
- User is created successfully
- No truncation or errors

#### 2.3 Unicode Characters in Email

**Test Emails:**
- `admin@例え.jp`
- `admin@例子.cn`
- `admin@пример.ru`

**Steps:**
1. For each test email, repeat the end-to-end flow
2. Verify handling

**Expected Results:**
- Unicode emails are accepted (if supported by Supabase)
- Or appropriate error message if not supported

#### 2.4 Concurrent Requests

**Steps:**
1. Open multiple browser tabs (5 tabs)
2. In each tab, prepare to create a different admin
3. Submit all forms within 1-2 seconds
4. Verify all requests complete

**Expected Results:**
- All requests complete successfully
- No race conditions
- All users are created correctly
- Rate limiting doesn't block legitimate concurrent requests

---

### 3. Security Testing

#### 3.1 Non-Admin Token Rejection

**Steps:**
1. Login as regular user (not system admin)
2. Navigate to admin dashboard (should be blocked)
3. Or use API directly with non-admin token

**Expected Results:**
- Request is rejected with 403 error
- Error message: "Only system admins can create system admins"
- No user is created

#### 3.2 Rate Limiting

**Steps:**
1. Using API client or script, make 11 rapid requests within 1 minute
2. Monitor response codes

**Expected Results:**
- First 10 requests succeed (200)
- 11th request fails with 429
- Error message: "Rate limit exceeded: 10 requests per minute"
- After 60 seconds, requests succeed again

**Test Script:**
```javascript
const testRateLimit = async () => {
  const results = [];
  for (let i = 0; i < 12; i++) {
    const start = Date.now();
    const response = await fetch('/functions/v1/create-system-admin', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: `test${i}@example.com`,
        password: 'password123',
      }),
    });
    results.push({
      attempt: i + 1,
      status: response.status,
      time: Date.now() - start,
    });
    await new Promise(r => setTimeout(r, 100)); // 100ms between requests
  }
  console.table(results);
};
```

#### 3.3 Invalid/Malformed Input

**Test Cases:**
- Empty email: `{ email: '', password: 'test123' }`
- Invalid email: `{ email: 'invalid', password: 'test123' }`
- Empty password: `{ email: 'test@example.com', password: '' }`
- Short password: `{ email: 'test@example.com', password: '12345' }`
- Missing fields: `{}` or `{ email: 'test@example.com' }`

**Expected Results:**
- All invalid inputs return 400 error
- Appropriate error message for each case
- No user is created
- No partial data in database

#### 3.4 Password Security

**Steps:**
1. Create a system admin
2. Check network tab for request/response
3. Check browser console for logs
4. Check Supabase logs

**Expected Results:**
- Password never appears in response body
- Password never appears in console logs
- Password never appears in Supabase logs
- Password is only sent in request body (encrypted via HTTPS)

---

### 4. Database Verification Tests

#### 4.1 User Creation in auth.users

**SQL Query:**
```sql
SELECT id, email, created_at, last_sign_in_at 
FROM auth.users 
WHERE email = 'test-admin@example.com';
```

**Expected Results:**
- User exists with correct email
- created_at is recent
- last_sign_in_at is null (user hasn't logged in yet)

#### 4.2 System Admin Assignment

**SQL Query:**
```sql
SELECT user_id, email, created_at 
FROM system_admins 
WHERE email = 'test-admin@example.com';
```

**Expected Results:**
- Entry exists in system_admins
- user_id matches auth.users.id
- email matches
- created_at is recent

#### 4.3 Audit Log Entry

**SQL Query:**
```sql
SELECT * 
FROM app_audit_log 
WHERE action = 'create_system_admin' 
  AND email = 'test-admin@example.com'
ORDER BY created_at DESC 
LIMIT 1;
```

**Expected Results:**
- Audit log entry exists
- action = 'create_system_admin'
- target_user_id matches created user
- email matches
- creator_id is the system admin who created the user
- created_at is recent

---

### 5. Error Recovery Testing

#### 5.1 Rollback on Admin Assignment Failure

**Steps:**
1. Temporarily break the `add_system_admin` RPC function
2. Attempt to create system admin
3. Verify user is NOT created in auth.users

**Expected Results:**
- Request fails with 500 error
- User is not created in auth.users (rollback successful)
- No orphaned users in database

#### 5.2 Network Error Handling

**Steps:**
1. Disconnect network during form submission
2. Verify error handling

**Expected Results:**
- Appropriate error message shown to user
- No partial data created
- User can retry after network is restored

---

### 6. Performance Testing

#### 6.1 Response Time

**Steps:**
1. Measure time from form submit to success message
2. Repeat 10 times
3. Calculate average

**Expected Results:**
- Average response time < 2 seconds
- No significant outliers

#### 6.2 Concurrent Load

**Steps:**
1. Simulate 10 concurrent users creating admins
2. Monitor system performance

**Expected Results:**
- All requests complete successfully
- No significant performance degradation
- No database locks or timeouts

---

## Test Results Checklist

### End-to-End Flow
- [ ] Valid email/password creates admin successfully
- [ ] Success message displays correctly
- [ ] Admin appears in list
- [ ] Form clears after success
- [ ] User verified in auth.users
- [ ] User verified in system_admins
- [ ] Audit log entry created

### Edge Cases
- [ ] Special characters in email work
- [ ] Long password works
- [ ] Unicode characters handled appropriately
- [ ] Concurrent requests work correctly

### Security
- [ ] Non-admin token rejected (403)
- [ ] Rate limiting works (429 after 10 requests)
- [ ] Invalid input rejected (400)
- [ ] Password never logged or returned

### Database
- [ ] User created in auth.users
- [ ] User added to system_admins
- [ ] Audit log entry created
- [ ] Rollback works on failure

### Performance
- [ ] Response time acceptable (< 2s)
- [ ] Concurrent load handled well

---

## Known Limitations

1. Some tests require actual edge function deployment
2. Unicode email support depends on Supabase configuration
3. Rate limiting tests may need test environment with separate rate limit table
4. Performance tests may need load testing tools

## Next Steps

After completing integration testing:
1. Document any issues found
2. Fix any bugs discovered
3. Re-test after fixes
4. Proceed to sub-phase 8: Deployment & Monitoring
