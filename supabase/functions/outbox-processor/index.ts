import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.97.0';
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

const BATCH_SIZE = 20;
const MAX_ATTEMPTS = 5;

const jsonResponse = (data: unknown, status: number) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });

interface OutboxMessage {
  message_id: string;
  request_id: string;
  topic: string;
  payload: {
    tenant_id: string;
    user_ids?: string[];
  };
  attempts: number;
}

async function cleanupStorage(supabaseAdmin: any, tenantId: string) {
  const bucket = supabaseAdmin.storage.from('tenant-assets');
  let deleted = 0;
  let failures = 0;
  let offset = 0;
  const limit = 100;

  while (true) {
    const { data: items, error: listError } = await bucket.list(tenantId, {
      limit,
      offset,
      sortBy: { column: 'name', order: 'asc' },
    });
    if (listError) {
      console.error(`[outbox-processor] Failed to list storage for tenant ${tenantId}`, listError);
      throw listError;
    }

    const files = (items || []).filter((item: any) => item.id && item.name);
    if (files.length === 0) break;

    const paths = files.map((file: any) => `${tenantId}/${file.name}`);
    const { error: removeError, data: removed } = await bucket.remove(paths);
    if (removeError) {
      console.error(`[outbox-processor] Failed to remove storage objects ${paths}`, removeError);
      failures += files.length;
      throw removeError;
    }
    deleted += (removed?.length ?? files.length);

    if (files.length < limit) break;
    offset += limit;
  }

  return { deleted, failures };
}

async function cleanupAuth(supabaseAdmin: any, userIds: string[]) {
  let deleted = 0;
  let failures = 0;

  if (userIds.length === 0) return { deleted, failures };

  // Skip any user that is a system admin or belongs to another tenant.
  const { data: systemAdmins } = await supabaseAdmin
    .from('system_admins')
    .select('user_id')
    .in('user_id', userIds);
  const adminIds = new Set((systemAdmins || []).map((a: any) => a.user_id));

  for (const userId of userIds) {
    if (adminIds.has(userId)) continue;

    const [{ count: otherMemberships }, { count: otherOwnerships }] = await Promise.all([
      supabaseAdmin
        .from('tenant_memberships')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', userId),
      supabaseAdmin
        .from('tenants')
        .select('*', { count: 'exact', head: true })
        .eq('owner_id', userId),
    ]);

    if ((otherMemberships ?? 0) > 0 || (otherOwnerships ?? 0) > 0) continue;

    const { error: authDeleteError } = await supabaseAdmin.auth.admin.deleteUser(userId);
    if (authDeleteError) {
      console.error(`[outbox-processor] Failed to delete auth user ${userId}`, authDeleteError);
      failures += 1;
    } else {
      deleted += 1;
    }
  }

  return { deleted, failures };
}

async function handleMessage(supabaseAdmin: any, message: OutboxMessage) {
  const { topic, payload } = message;
  const tenantId = payload.tenant_id;

  switch (topic) {
    case 'storage.cleanup': {
      const { deleted, failures } = await cleanupStorage(supabaseAdmin, tenantId);
      return { success: true, deleted, failures };
    }
    case 'auth.cleanup': {
      const { deleted, failures } = await cleanupAuth(supabaseAdmin, payload.user_ids ?? []);
      return { success: true, deleted, failures };
    }
    default:
      return { success: false, error: `Unknown topic ${topic}` };
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { status: 200 });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: messages, error: fetchError } = await supabaseAdmin
      .from('outbox')
      .select('message_id, request_id, topic, payload, attempts')
      .eq('status', 'pending')
      .order('created_at', { ascending: true })
      .limit(BATCH_SIZE);

    if (fetchError) throw fetchError;

    const processed: string[] = [];
    const failed: string[] = [];

    for (const message of (messages || []) as OutboxMessage[]) {
      const messageId = message.message_id;

      const { error: lockError } = await supabaseAdmin
        .from('outbox')
        .update({ status: 'processing' })
        .eq('message_id', messageId)
        .eq('status', 'pending');

      if (lockError) {
        console.error(`[outbox-processor] Failed to lock ${messageId}`, lockError);
        failed.push(messageId);
        continue;
      }

      try {
        const result = await handleMessage(supabaseAdmin, message);
        const { error: completeError } = await supabaseAdmin
          .from('outbox')
          .update({
            status: 'processed',
            processed_at: new Date().toISOString(),
            error: null,
          })
          .eq('message_id', messageId);
        if (completeError) throw completeError;
        processed.push(messageId);
        console.log(`[outbox-processor] processed ${message.topic} ${messageId}`, result);
      } catch (err) {
        const messageErr = err instanceof Error ? err.message : 'unknown error';
        const nextAttempts = (message.attempts ?? 0) + 1;
        const finalFail = nextAttempts >= MAX_ATTEMPTS;

        await supabaseAdmin
          .from('outbox')
          .update({
            status: finalFail ? 'failed' : 'pending',
            attempts: nextAttempts,
            error: finalFail ? messageErr : null,
            processed_at: finalFail ? new Date().toISOString() : null,
          })
          .eq('message_id', messageId);

        if (finalFail) {
          failed.push(messageId);
          console.error(`[outbox-processor] ${messageId} failed after ${nextAttempts} attempts`, err);
        } else {
          console.log(`[outbox-processor] ${messageId} attempt ${nextAttempts} failed, will retry`, err);
        }
      }
    }

    return jsonResponse(
      {
        success: true,
        processed: processed.length,
        failed: failed.length,
        ids: { processed, failed },
      },
      200
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Unknown error';
    return jsonResponse({ success: false, error: message }, 500);
  }
});
