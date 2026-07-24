import { describe, it, expect } from 'vitest';
import { readFileSync } from 'fs';
import { resolve } from 'path';

/**
 * Wave-03 Phase 5.1 Step 3 — outbox-processor Edge Function structural regression.
 *
 * No live DB is required; this scans the source to confirm the processor implements
 * the expected side-effect topics and retry/failure states.
 */

const repoRoot = resolve(__dirname, '../..');
const processor = readFileSync(resolve(repoRoot, 'supabase/functions/outbox-processor/index.ts'), 'utf8');

describe('outbox-processor edge function structure', () => {
  it('handles storage.cleanup and auth.cleanup topics', () => {
    expect(processor).toContain("case 'storage.cleanup':");
    expect(processor).toContain("case 'auth.cleanup':");
    expect(processor).toContain('tenant-assets');
    expect(processor).toContain('auth.admin.deleteUser');
  });

  it('moves messages through processing -> processed/failed states', () => {
    expect(processor).toContain("'processing'");
    expect(processor).toContain("'processed'");
    expect(processor).toContain("'failed'");
  });

  it('implements bounded retry logic', () => {
    expect(processor).toMatch(/attempts[^;]*\+\s*1/);
    expect(processor).toMatch(/MAX_ATTEMPTS\s*=\s*5/);
  });

  it('uses the service_role key and has no public anon access', () => {
    expect(processor).toContain('SUPABASE_SERVICE_ROLE_KEY');
    expect(processor).not.toContain('SUPABASE_ANON_KEY');
  });
});
