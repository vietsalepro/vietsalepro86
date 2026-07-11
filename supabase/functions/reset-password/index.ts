import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.97.0';
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const jsonResponse = (data: unknown, status: number) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders },
  });

// FIX [5.2]: Rate limiting constants
const IP_RATE_LIMIT_WINDOW_MS = 60_000;      // 1 phút
const IP_RATE_LIMIT_MAX = 5;                   // 5 request/phút/IP
const TENANT_RATE_LIMIT_WINDOW_MS = 3_600_000; // 1 giờ
const TENANT_RATE_LIMIT_MAX = 10;              // 10 request/giờ/tenant
const USER_RATE_LIMIT_WINDOW_MS = 3_600_000;   // 1 giờ
const USER_RATE_LIMIT_MAX = 3;                 // 3 request/giờ/user

const getClientIp = (req: Request): string => {
  const forwarded = req.headers.get('x-forwarded-for');
  if (forwarded) return forwarded.split(',')[0].trim();
  return req.headers.get('x-real-ip') || '0.0.0.0';
};

const isValidIp = (ip: string): boolean => {
  return /^((\d{1,3}\.){3}\d{1,3}|([0-9a-fA-F:]+))$/.test(ip);
};

// FIX [5.2]: Rate limit check function
async function checkRateLimit(supabaseAdmin: any, ip: string, tenantId: string, targetUserId: string): Promise<Response | null> {
  const now = Date.now();
  
  // 1. IP rate limit: 5 request/phút
  const ipWindowStart = new Date(now - IP_RATE_LIMIT_WINDOW_MS).toISOString();
  const { count: ipCount } = await supabaseAdmin
    .from('rate_limit_logs')
    .select('*', { count: 'exact', head: true })
    .eq('ip_address', ip)
    .eq('action', 'reset_password')
    .gte('window_start', ipWindowStart);
  if ((ipCount ?? 0) >= IP_RATE_LIMIT_MAX) {
    return jsonResponse({ error: 'Rate limit exceeded: 5 requests per minute' }, 429);
  }
  
  // 2. Tenant rate limit: 10 request/giờ
  const tenantWindowStart = new Date(now - TENANT_RATE_LIMIT_WINDOW_MS).toISOString();
  const { count: tenantCount } = await supabaseAdmin
    .from('rate_limit_logs')
    .select('*', { count: 'exact', head: true })
    .eq('tenant_id', tenantId)
    .eq('action', 'reset_password')
    .gte('window_start', tenantWindowStart);
  if ((tenantCount ?? 0) >= TENANT_RATE_LIMIT_MAX) {
    return jsonResponse({ error: 'Rate limit exceeded: 10 password resets per hour for this tenant' }, 429);
  }
  
  // 3. User rate limit: 3 request/giờ (theo target user)
  const userWindowStart = new Date(now - USER_RATE_LIMIT_WINDOW_MS).toISOString();
  const { count: userCount } = await supabaseAdmin
    .from('rate_limit_logs')
    .select('*', { count: 'exact', head: true })
    .eq('target_user_id', targetUserId)
    .eq('action', 'reset_password')
    .gte('window_start', userWindowStart);
  if ((userCount ?? 0) >= USER_RATE_LIMIT_MAX) {
    return jsonResponse({ error: 'Rate limit exceeded: 3 password resets per hour for this user' }, 429);
  }
  
  // Log rate limit entry
  await supabaseAdmin.from('rate_limit_logs').insert({
    ip_address: ip,
    tenant_id: tenantId,
    target_user_id: targetUserId,
    action: 'reset_password',
    window_start: new Date().toISOString(),
  });
  
  return null; // OK, not rate limited
}

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

    // Request body.
    const body = await req.json();
    const { tenant_id, user_id, email } = body;

    if (!tenant_id || typeof tenant_id !== 'string') {
      return jsonResponse({ error: 'tenant_id không hợp lệ' }, 400);
    }
    if ((!user_id || typeof user_id !== 'string') && (!email || typeof email !== 'string')) {
      return jsonResponse({ error: 'Cần cung cấp user_id hoặc email' }, 400);
    }

    // Resolve tenant.
    const { data: tenant, error: tenantError } = await supabaseAdmin
      .from('tenants')
      .select('id, subdomain, status')
      .eq('id', tenant_id)
      .maybeSingle();
    if (tenantError) throw tenantError;
    if (!tenant) {
      return jsonResponse({ error: 'Tenant không tồn tại' }, 404);
    }
    if (tenant.status !== 'active') {
      return jsonResponse({ error: 'Tenant không hoạt động' }, 403);
    }

    // Caller authorization: system admin or tenant admin.
    const { data: adminRow, error: adminError } = await supabaseAdmin
      .from('system_admins')
      .select('user_id')
      .eq('user_id', user.id)
      .maybeSingle();
    if (adminError) throw adminError;

    if (!adminRow) {
      const { data: tenantAdmin, error: tenantAdminError } = await supabaseAdmin
        .from('tenant_memberships')
        .select('id')
        .eq('tenant_id', tenant_id)
        .eq('user_id', user.id)
        .eq('role', 'admin')
        .maybeSingle();
      if (tenantAdminError) throw tenantAdminError;
      if (!tenantAdmin) {
        return jsonResponse({ error: 'Chỉ admin của tenant hoặc system admin được reset mật khẩu' }, 403);
      }
    }

    // Resolve target user.
    let targetUser: { id: string; email: string; last_sign_in_at?: string | null } | null = null;

    if (user_id) {
      const { data: userById, error: userByIdError } = await supabaseAdmin.auth.admin.getUserById(user_id);
      if (userByIdError) {
        // Treat missing user as not found rather than 500.
        if (userByIdError.message.toLowerCase().includes('not found') || userByIdError.status === 404) {
          return jsonResponse({ error: 'User không tồn tại' }, 404);
        }
        throw userByIdError;
      }
      if (userById.user) {
        targetUser = {
          id: userById.user.id,
          email: userById.user.email ?? '',
          last_sign_in_at: userById.user.last_sign_in_at,
        };
      }
    }

    if (!targetUser && email) {
      const normalizedEmail = email.trim().toLowerCase();
      const { data: userRows, error: userByEmailError } = await supabaseAdmin.rpc(
        'get_user_by_email',
        { p_email: normalizedEmail }
      );
      if (userByEmailError) throw userByEmailError;
      const userByEmail = userRows && Array.isArray(userRows) && userRows.length > 0 ? userRows[0] : null;
      if (userByEmail) {
        targetUser = {
          id: userByEmail.id as string,
          email: userByEmail.email as string,
          last_sign_in_at: userByEmail.last_sign_in_at as string | null | undefined,
        };
      }
    }

    if (!targetUser) {
      return jsonResponse({ error: 'User không tồn tại' }, 404);
    }
    if (!targetUser.email) {
      return jsonResponse({ error: 'User không có email' }, 400);
    }

    // Verify target user belongs to the tenant.
    const { data: membership, error: membershipError } = await supabaseAdmin
      .from('tenant_memberships')
      .select('id')
      .eq('tenant_id', tenant_id)
      .eq('user_id', targetUser.id)
      .maybeSingle();
    if (membershipError) throw membershipError;
    if (!membership) {
      return jsonResponse({ error: 'User không thuộc tenant này' }, 403);
    }

    // FIX [5.2]: Rate limit check before processing
    const rawIp = getClientIp(req);
    const ip = isValidIp(rawIp) ? rawIp : '0.0.0.0';
    const rateLimitResponse = await checkRateLimit(supabaseAdmin, ip, tenant_id, targetUser.id);
    if (rateLimitResponse) return rateLimitResponse;

    // FIX [4.7]: Use email_confirmed_at instead of last_sign_in_at to determine link type
    // - If user has confirmed email → use 'recovery' (reset password)
    // - If user hasn't confirmed email → use 'invite' (set password lần đầu)
    let isEmailConfirmed = false;
    try {
      const { data: authUserData, error: authUserError } = await supabaseAdmin.auth.admin.getUserById(targetUser.id);
      if (!authUserError && authUserData?.user) {
        isEmailConfirmed = !!authUserData.user.email_confirmed_at;
      } else {
        // Fallback to last_sign_in_at if getUserById fails
        console.warn('Failed to get auth user details, falling back to last_sign_in_at:', authUserError?.message);
        isEmailConfirmed = !!targetUser.last_sign_in_at;
      }
    } catch (e) {
      // Fallback: if user has ever signed in, use recovery
      console.warn('Error checking email_confirmed_at, falling back to last_sign_in_at:', e);
      isEmailConfirmed = !!targetUser.last_sign_in_at;
    }

    const type = isEmailConfirmed ? 'recovery' : 'invite';
    const path = isEmailConfirmed ? 'reset-password' : 'set-password';
    const redirectTo = `https://${tenant.subdomain}.vietsalepro.com/${path}`;

    // ponytail: Supabase Auth default email provider sends the link. generateLink only
    // returns the link in environments without SMTP; the production project relies on
    // Auth's configured email provider for delivery.
    // In staging without email provider, we continue and report the intended redirectTo.
    const { data: linkData, error: linkError } = await supabaseAdmin.auth.admin.generateLink({
      type,
      email: targetUser.email,
      options: { redirectTo },
    });
    if (linkError) {
      console.warn('generateLink failed:', linkError.message);
    }

    // FIX [5.2]: Audit log for password reset
    await supabaseAdmin.from('app_audit_log').insert({
      tenant_id,
      user_id: user.id,
      table_name: 'tenant_memberships',
      record_id: targetUser.id,
      action: 'MEMBER_PASSWORD_RESET',
      new_data: { target_user_id: targetUser.id, type },
      ip_address: ip,
    }).catch(() => {});

    return jsonResponse({ success: true, action: type, redirectTo, link: linkData?.properties?.action_link ?? null }, 200);
  } catch (err) {
    const message = err instanceof Error ? err.message : (err && typeof err === 'object' && 'message' in err ? (err as { message: string }).message : 'Unknown error');
    return jsonResponse({ error: message }, 500);
  }
});