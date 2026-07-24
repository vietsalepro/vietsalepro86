-- === MIGRATION START: 20260725000000_create_delete_state_tables.sql ===
-- Scope: SPEC-001 Delete Framework — Wave-03 Phase 5.1 Step 1
-- Creates state-machine, outbox, and snapshot tables for canonical tenant deletion.
-- Safe to run: only adds empty tables, no production data mutation.
-- Rollback: drop the three new tables (see ROLLBACK section at end).

-- ============================================================
-- 1. delete_state — tracks the canonical deletion lifecycle
-- ============================================================

CREATE TABLE IF NOT EXISTS public.delete_state (
  request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  actor_id UUID,
  correlation_id UUID,
  action TEXT NOT NULL CHECK (action IN ('soft','hard','purge','archive')),
  status TEXT NOT NULL DEFAULT 'DELETE_REQUESTED'
    CHECK (status IN (
      'DELETE_REQUESTED','VALIDATING','PREPARING','TRANSACTION_STARTED',
      'EXECUTING','SIDE_EFFECTS_PENDING','COMMITTING','COMPLETED',
      'FAILED','ROLLBACK','RECOVERABLE','CLOSED'
    )),
  payload JSONB DEFAULT '{}',
  started_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_delete_state_tenant_id
  ON public.delete_state(tenant_id);

CREATE INDEX IF NOT EXISTS idx_delete_state_status
  ON public.delete_state(status);

-- ============================================================
-- 2. outbox — idempotent side-effect queue for post-commit work
-- ============================================================

CREATE TABLE IF NOT EXISTS public.outbox (
  message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES public.delete_state(request_id) ON DELETE CASCADE,
  topic TEXT NOT NULL,
  payload JSONB NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','processing','processed','failed')),
  attempts INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  processed_at TIMESTAMPTZ,
  error TEXT
);

CREATE INDEX IF NOT EXISTS idx_outbox_status_created
  ON public.outbox(status, created_at)
  WHERE status IN ('pending','failed');

CREATE INDEX IF NOT EXISTS idx_outbox_request_id
  ON public.outbox(request_id);

-- ============================================================
-- 3. tenant_deletion_backups — JSON snapshot for recovery
-- ============================================================

CREATE TABLE IF NOT EXISTS public.tenant_deletion_backups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES public.delete_state(request_id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL,
  snapshot JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tenant_deletion_backups_tenant_id
  ON public.tenant_deletion_backups(tenant_id);

CREATE INDEX IF NOT EXISTS idx_tenant_deletion_backups_request_id
  ON public.tenant_deletion_backups(request_id);

-- ============================================================
-- 4. Privileges (service_role owns the pipeline; RPCs are SECURITY DEFINER)
-- ============================================================

GRANT ALL ON TABLE public.delete_state TO service_role;
GRANT ALL ON TABLE public.outbox TO service_role;
GRANT ALL ON TABLE public.tenant_deletion_backups TO service_role;

GRANT SELECT, INSERT, UPDATE ON TABLE public.delete_state TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.outbox TO authenticated;
GRANT SELECT, INSERT ON TABLE public.tenant_deletion_backups TO authenticated;

-- ROLLBACK (run manually if Step 1 needs to be reverted):
-- DROP TABLE IF EXISTS public.tenant_deletion_backups CASCADE;
-- DROP TABLE IF EXISTS public.outbox CASCADE;
-- DROP TABLE IF EXISTS public.delete_state CASCADE;

-- === MIGRATION END: 20260725000000_create_delete_state_tables.sql ===
