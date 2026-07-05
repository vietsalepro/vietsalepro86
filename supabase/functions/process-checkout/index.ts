import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.97.0';
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-tenant-id, x-subdomain',
};

const RATE_LIMIT_WINDOW_MS = 60_000;
const RATE_LIMIT_MAX = 60;

const getClientIp = (req: Request): string => {
  const forwarded = req.headers.get('x-forwarded-for');
  if (forwarded) return forwarded.split(',')[0].trim();
  return req.headers.get('x-real-ip') || '0.0.0.0';
};

const isValidIp = (ip: string): boolean => {
  // ponytail: quick regex check; INET will reject anything that slips through.
  return /^((\d{1,3}\.){3}\d{1,3}|([0-9a-fA-F:]+))$/.test(ip);
};

const jsonResponse = (data: unknown, status: number) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const rawIp = getClientIp(req);
    const ip = isValidIp(rawIp) ? rawIp : '0.0.0.0';
    const windowStart = new Date(Date.now() - RATE_LIMIT_WINDOW_MS).toISOString();

    // Rate limiting: 60 requests per minute per IP.
    const { count, error: countError } = await supabaseAdmin
      .from('rate_limit_logs')
      .select('*', { count: 'exact', head: true })
      .eq('ip_address', ip)
      .eq('action', 'process_checkout')
      .gte('window_start', windowStart);

    if (countError) throw countError;
    if ((count ?? 0) >= RATE_LIMIT_MAX) {
      return jsonResponse({ error: 'Rate limit exceeded: 60 requests per minute' }, 429);
    }

    const { error: logError } = await supabaseAdmin.from('rate_limit_logs').insert({
      ip_address: ip,
      action: 'process_checkout',
      window_start: new Date().toISOString(),
    });
    if (logError) throw logError;

    // Caller authentication.
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse({ error: 'Missing Authorization header' }, 401);
    }
    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token);
    if (userError || !user) {
      return jsonResponse({ error: 'Invalid token' }, 401);
    }

    // Tenant resolution from x-tenant-id or x-subdomain.
    const tenantIdHeader = req.headers.get('x-tenant-id');
    const subdomainHeader = req.headers.get('x-subdomain');

    let tenantQuery = supabaseAdmin.from('tenants').select('id, subdomain, status');
    if (tenantIdHeader) {
      tenantQuery = tenantQuery.eq('id', tenantIdHeader);
    } else if (subdomainHeader) {
      tenantQuery = tenantQuery.eq('subdomain', subdomainHeader.trim().toLowerCase());
    } else {
      return jsonResponse({ error: 'Thiếu x-tenant-id hoặc x-subdomain' }, 400);
    }

    const { data: tenant, error: tenantError } = await tenantQuery.maybeSingle();
    if (tenantError) throw tenantError;
    if (!tenant) {
      return jsonResponse({ error: 'Tenant không tồn tại' }, 404);
    }
    if (tenant.status !== 'active') {
      return jsonResponse({ error: 'Tenant không hoạt động' }, 403);
    }
    const tenantId = tenant.id;

    // Caller authorization: must be a member of the tenant.
    const { data: membership, error: membershipError } = await supabaseAdmin
      .from('tenant_memberships')
      .select('id')
      .eq('tenant_id', tenantId)
      .eq('user_id', user.id)
      .maybeSingle();
    if (membershipError) throw membershipError;
    if (!membership) {
      return jsonResponse({ error: 'User không thuộc tenant này' }, 403);
    }

    // Request body.
    const body = await req.json();
    const {
      order,
      items,
      deltas,
      reward_deltas,
      customer_update,
      point_history,
      allow_negative,
      op_id,
    } = body;

    if (!order || typeof order !== 'object' || !order.id) {
      return jsonResponse({ error: 'order.id không hợp lệ' }, 400);
    }

    // Call the tenant-aware checkout RPC.
    const { data, error: rpcError } = await supabaseAdmin.rpc('process_checkout_tenant', {
      p_tenant_id: tenantId,
      p_order: order,
      p_items: items || [],
      p_deltas: deltas || [],
      p_reward_deltas: reward_deltas || [],
      p_customer_update: customer_update || null,
      p_point_history: point_history || [],
      p_allow_negative: allow_negative || false,
      p_op_id: op_id || null,
    });

    if (rpcError) throw rpcError;

    return jsonResponse(data, 200);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Unknown error';
    return jsonResponse({ error: message }, 500);
  }
});
