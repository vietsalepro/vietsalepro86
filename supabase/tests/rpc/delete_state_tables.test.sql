-- Wave-03 Phase 5.1 Step 1 smoke test
-- Verifies delete_state, outbox, and tenant_deletion_backups tables exist with expected columns.

BEGIN;
SET LOCAL search_path = public, extensions;

SELECT plan(9);

SELECT has_table('public', 'delete_state', 'delete_state table exists');
SELECT has_column('public', 'delete_state', 'request_id', 'delete_state has request_id');
SELECT has_column('public', 'delete_state', 'status', 'delete_state has status');

SELECT has_table('public', 'outbox', 'outbox table exists');
SELECT has_column('public', 'outbox', 'message_id', 'outbox has message_id');
SELECT has_column('public', 'outbox', 'topic', 'outbox has topic');
SELECT has_column('public', 'outbox', 'status', 'outbox has status');

SELECT has_table('public', 'tenant_deletion_backups', 'tenant_deletion_backups table exists');
SELECT has_column('public', 'tenant_deletion_backups', 'snapshot', 'tenant_deletion_backups has snapshot');

SELECT * FROM finish();
ROLLBACK;
