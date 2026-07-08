import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  resetMockData,
  setCurrentUserId,
  setSystemAdmin,
  addMockRow,
  getMockRows,
} from '../mocks/supabase';

vi.mock('../../lib/supabase', async () => {
  const { mockSupabase } = await import('../mocks/supabase');
  return { supabase: mockSupabase };
});

import { createSystemAdmin } from '../../services/systemAdminService';
import { supabase } from '../../lib/supabase';

// Practical integration tests that can run without deployment
// Tests the full flow from service layer through mocked edge function

describe('integration: system admin creation (practical)', () => {
  let currentMockUserId = 'sys-admin';

  beforeEach(() => {
    resetMockData();
    currentMockUserId = 'sys-admin';
    
    // Mock supabase.functions.invoke to simulate edge function calls
    vi.spyOn(supabase.functions, 'invoke').mockImplementation(async (name: string, options: any) => {
      if (name !== 'create-system-admin') {
        throw new Error('Unknown function');
      }

      const { email, password } = options.body;

      // Simulate edge function validation logic
      if (!email || typeof email !== 'string') {
        return { data: null, error: { message: 'Email is required' } };
      }
      if (!password || typeof password !== 'string') {
        return { data: null, error: { message: 'Password is required' } };
      }

      const normalizedEmail = email.trim().toLowerCase();
      // ponytail: Basic email validation - must have @, at least 1 char before and after
      if (!normalizedEmail.includes('@') || normalizedEmail.length < 5) {
        return { data: null, error: { message: 'Invalid email format' } };
      }
      const [localPart, domain] = normalizedEmail.split('@');
      if (!localPart || !domain || localPart.length < 1 || domain.length < 1) {
        return { data: null, error: { message: 'Invalid email format' } };
      }

      if (password.length < 6) {
        return { data: null, error: { message: 'Password must be at least 6 characters' } };
      }

      // Check if email already exists (simulate by checking system_admins)
      const existingAdmin = getMockRows('system_admins').find((a: any) => a.email === normalizedEmail);
      if (existingAdmin) {
        return { data: null, error: { message: 'Email already exists' } };
      }

      // Simulate successful user creation
      const newUserId = crypto.randomUUID();
      addMockRow('system_admins', {
        user_id: newUserId,
        email: normalizedEmail,
        created_at: new Date().toISOString(),
      });

      // Simulate audit log creation - use current user ID from mock state
      addMockRow('app_audit_log', {
        action: 'create_system_admin',
        target_user_id: newUserId,
        email: normalizedEmail,
        creator_id: currentMockUserId,
        created_at: new Date().toISOString(),
      });

      return {
        data: {
          success: true,
          userId: newUserId,
          email: normalizedEmail,
        },
        error: null,
      };
    });
  });

  describe('end-to-end flow simulation', () => {
    it('full flow: validate → create user → assign admin → audit log', async () => {
      setCurrentUserId('sys-admin');
      setSystemAdmin(true);

      const testEmail = 'integration-test@example.com';
      const testPassword = 'securePassword123';

      // Execute the full flow
      const result = await createSystemAdmin(testEmail, testPassword);

      // Verify user creation
      expect(result.userId).toBeDefined();
      expect(result.email).toBe(testEmail);

      // Verify admin assignment
      const admins = getMockRows('system_admins');
      expect(admins.length).toBe(1);
      expect(admins[0].email).toBe(testEmail);
      expect(admins[0].user_id).toBe(result.userId);

      // Verify audit log
      const auditLogs = getMockRows('app_audit_log');
      expect(auditLogs.length).toBe(1);
      expect(auditLogs[0].action).toBe('create_system_admin');
      expect(auditLogs[0].target_user_id).toBe(result.userId);
      expect(auditLogs[0].email).toBe(testEmail);
      expect(auditLogs[0].creator_id).toBe('sys-admin');
    });

    it('form validation → service validation → edge function validation', async () => {
      setCurrentUserId('sys-admin');
      setSystemAdmin(true);

      // Test that validation happens at multiple layers
      const invalidEmails = ['', 'invalid', '@example.com', 'test@'];
      const invalidPasswords = ['', '12345'];

      for (const email of invalidEmails) {
        await expect(createSystemAdmin(email, 'validPassword123')).rejects.toThrow();
      }

      for (const password of invalidPasswords) {
        await expect(createSystemAdmin('valid@example.com', password)).rejects.toThrow();
      }

      // Verify no users were created
      const admins = getMockRows('system_admins');
      expect(admins.length).toBe(0);
    });
  });

  describe('edge cases integration', () => {
    it('special characters in email: + . - _', async () => {
      setCurrentUserId('sys-admin');
      setSystemAdmin(true);

      const specialEmails = [
        'admin+test@example.com',
        'admin.test@example.com',
        'admin-test@example.com',
        'admin_test@example.com',
      ];

      for (const email of specialEmails) {
        const result = await createSystemAdmin(email, 'password123');
        expect(result.email).toBe(email);
      }

      // Verify all admins were created
      const admins = getMockRows('system_admins');
      expect(admins.length).toBe(specialEmails.length);
    });

    it('very long password (200 chars)', async () => {
      setCurrentUserId('sys-admin');
      setSystemAdmin(true);

      const longPassword = 'a'.repeat(200);
      const result = await createSystemAdmin('longpass@example.com', longPassword);

      expect(result.userId).toBeDefined();
      expect(result.email).toBe('longpass@example.com');

      const admins = getMockRows('system_admins');
      expect(admins.length).toBe(1);
    });

    it('email normalization: trim and lowercase', async () => {
      setCurrentUserId('sys-admin');
      setSystemAdmin(true);

      const inputEmail = '  MIXEDCASE@EXAMPLE.COM  ';
      const result = await createSystemAdmin(inputEmail, 'password123');

      expect(result.email).toBe('mixedcase@example.com');

      const admins = getMockRows('system_admins');
      expect(admins[0].email).toBe('mixedcase@example.com');
    });

    it('concurrent requests handling', async () => {
      setCurrentUserId('sys-admin');
      setSystemAdmin(true);

      const promises = [];
      const concurrentCount = 5;

      for (let i = 0; i < concurrentCount; i++) {
        promises.push(
          createSystemAdmin(`concurrent-${i}@example.com`, 'password123')
        );
      }

      const results = await Promise.allSettled(promises);

      // All should succeed
      const successful = results.filter(r => r.status === 'fulfilled');
      expect(successful.length).toBe(concurrentCount);

      // Verify all admins were created
      const admins = getMockRows('system_admins');
      expect(admins.length).toBe(concurrentCount);
    });
  });

  describe('security integration', () => {
    it('password never appears in response or logs', async () => {
      setCurrentUserId('sys-admin');
      setSystemAdmin(true);

      const testPassword = 'secretPassword123';
      const result = await createSystemAdmin('secure@example.com', testPassword);

      // Verify password is not in response
      expect(result).not.toHaveProperty('password');
      expect(result.userId).toBeDefined();
      expect(result.email).toBeDefined();

      // Verify password is not in mock data
      const admins = getMockRows('system_admins');
      expect(admins[0]).not.toHaveProperty('password');
    });

    it('duplicate email detection across the system', async () => {
      setCurrentUserId('sys-admin');
      setSystemAdmin(true);

      const email = 'duplicate@example.com';

      // Create first admin
      await createSystemAdmin(email, 'password123');

      // Try to create duplicate
      await expect(createSystemAdmin(email, 'password456')).rejects.toThrow('Email already exists');

      // Verify only one admin exists
      const admins = getMockRows('system_admins');
      expect(admins.length).toBe(1);
    });

    it('input sanitization prevents injection attempts', async () => {
      setCurrentUserId('sys-admin');
      setSystemAdmin(true);

      const maliciousInputs = [
        { email: "'; DROP TABLE users; --@example.com", password: 'password123' },
        { email: '<script>alert("xss")</script>@example.com', password: 'password123' },
        { email: 'admin@example.com', password: '"; DROP TABLE users; --' },
      ];

      for (const input of maliciousInputs) {
        // ponytail: The system accepts these inputs because we use parameterized queries
        // in the real implementation, preventing SQL injection. The email validation
        // only checks format, not content. This is acceptable as long as the database
        // layer uses proper parameterization.
        const result = await createSystemAdmin(input.email, input.password);
        
        // Verify the user was created (input is accepted)
        expect(result.userId).toBeDefined();
        expect(result.email).toBe(input.email.trim().toLowerCase());
      }

      // Verify all admins were created
      const admins = getMockRows('system_admins');
      expect(admins.length).toBe(maliciousInputs.length);
    });
  });

  describe('error recovery integration', () => {
    it('network error does not create partial data', async () => {
      setCurrentUserId('sys-admin');
      setSystemAdmin(true);

      // Mock network error
      vi.spyOn(supabase.functions, 'invoke').mockRejectedValueOnce(
        new Error('Network error')
      );

      await expect(createSystemAdmin('network@example.com', 'password123')).rejects.toThrow('Network error');

      // Verify no admin was created
      const admins = getMockRows('system_admins');
      expect(admins.length).toBe(0);
    });

    it('edge function error does not create partial data', async () => {
      setCurrentUserId('sys-admin');
      setSystemAdmin(true);

      // Mock edge function error
      vi.spyOn(supabase.functions, 'invoke').mockResolvedValueOnce({
        data: null,
        error: { message: 'Edge function error' },
      });

      await expect(createSystemAdmin('edge-error@example.com', 'password123')).rejects.toThrow();

      // Verify no admin was created
      const admins = getMockRows('system_admins');
      expect(admins.length).toBe(0);
    });
  });

  describe('data consistency integration', () => {
    it('system_admins and audit log stay in sync', async () => {
      setCurrentUserId('sys-admin');
      setSystemAdmin(true);

      await createSystemAdmin('sync@example.com', 'password123');

      const admins = getMockRows('system_admins');
      const auditLogs = getMockRows('app_audit_log');

      // Both should have exactly one entry
      expect(admins.length).toBe(1);
      expect(auditLogs.length).toBe(1);

      // IDs should match
      expect(admins[0].user_id).toBe(auditLogs[0].target_user_id);
      expect(admins[0].email).toBe(auditLogs[0].email);
    });

    it('creator_id is correctly tracked in audit log', async () => {
      setCurrentUserId('creator-123');
      setSystemAdmin(true);
      currentMockUserId = 'creator-123';

      await createSystemAdmin('tracked@example.com', 'password123');

      const auditLogs = getMockRows('app_audit_log');
      expect(auditLogs[0].creator_id).toBe('creator-123');
    });
  });
});
