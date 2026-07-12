-- Phase 5 long-term hardening: add admin dashboard feature flags.
-- Flags are stored inside tenants.settings->features JSONB (existing P8.2 design).
-- New flags default to false so advanced features can be enabled per tenant.

UPDATE public.tenants
SET settings = jsonb_set(
  COALESCE(settings, '{}'::jsonb),
  '{features}',
  COALESCE(settings->'features', '{}'::jsonb) || jsonb_build_object(
    'adminGdprEnabled', COALESCE((settings->'features'->>'adminGdprEnabled')::boolean, false),
    'adminAuditRealtimeEnabled', COALESCE((settings->'features'->>'adminAuditRealtimeEnabled')::boolean, false),
    'adminAdvancedAnalyticsEnabled', COALESCE((settings->'features'->>'adminAdvancedAnalyticsEnabled')::boolean, false),
    'adminImpersonationEnabled', COALESCE((settings->'features'->>'adminImpersonationEnabled')::boolean, false),
    'adminReadReplicaQueueEnabled', COALESCE((settings->'features'->>'adminReadReplicaQueueEnabled')::boolean, false)
  )
)
WHERE settings IS NULL OR settings->'features' IS NULL OR TRUE;
-- ponytail: WHERE TRUE ensures every existing row gets the defaults without overwriting
-- already-true values thanks to the COALESCE above.
