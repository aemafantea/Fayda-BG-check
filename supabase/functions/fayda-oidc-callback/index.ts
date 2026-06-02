// Fayda eSignet OIDC — step 2: exchange code, fetch userinfo, mark profile verified
import { handleCors, corsHeaders } from '../_shared/cors.ts';
import { getUser, getServiceClient } from '../_shared/supabase.ts';

const FAYDA_BASE   = Deno.env.get('FAYDA_BASE_URL')   ?? 'https://esignet.ida.fayda.et';
const CLIENT_ID    = Deno.env.get('FAYDA_CLIENT_ID')  ?? '';
const CLIENT_SECRET = Deno.env.get('FAYDA_CLIENT_SECRET') ?? ''; // for client_secret_post
const REDIRECT_URI = Deno.env.get('FAYDA_REDIRECT_URI') ?? '';

Deno.serve(async (req) => {
  const cors = handleCors(req); if (cors) return cors;
  try {
    const user = await getUser(req);
    const { code, state } = await req.json();
    if (!code || !state) throw new Error('Missing code or state');

    const sb = getServiceClient();
    const { data: sess, error: sErr } = await sb
      .from('fayda_oidc_sessions')
      .select('*')
      .eq('user_id', user.id)
      .eq('state', state)
      .single();
    if (sErr || !sess) throw new Error('Invalid state');

    // Exchange code for tokens
    const tokenRes = await fetch(`${FAYDA_BASE}/oauth/token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code,
        redirect_uri: REDIRECT_URI,
        client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET,
        code_verifier: sess.code_verifier,
      }),
    });
    if (!tokenRes.ok) throw new Error(`token exchange failed: ${await tokenRes.text()}`);
    const tokens = await tokenRes.json();

    // Fetch userinfo (may be a JWT/JWE in Fayda; we accept either)
    const uiRes = await fetch(`${FAYDA_BASE}/oidc/userinfo`, {
      headers: { Authorization: `Bearer ${tokens.access_token}` },
    });
    if (!uiRes.ok) throw new Error(`userinfo failed: ${await uiRes.text()}`);
    const ct = uiRes.headers.get('content-type') ?? '';
    let claims: Record<string, unknown>;
    if (ct.includes('application/jwt') || ct.includes('application/jose')) {
      const jwt = await uiRes.text();
      // Decode payload (signature/decryption verification should be added per Fayda spec)
      const payload = jwt.split('.')[1] ?? '';
      claims = JSON.parse(atob(payload.replace(/-/g, '+').replace(/_/g, '/')));
    } else {
      claims = await uiRes.json();
    }

    const fcn = String(claims['individual_id'] ?? claims['sub'] ?? '');
    const updates = {
      fayda_fcn: fcn || null,
      fayda_fin: (claims['fin'] as string) ?? null,
      fayda_verified_at: new Date().toISOString(),
      fayda_verification_status: 'verified',
      fayda_claims: claims,
      full_name: (claims['name'] as string) ?? undefined,
      date_of_birth: (claims['birthdate'] as string) ?? null,
      gender: (claims['gender'] as string) ?? null,
      phone: (claims['phone_number'] as string) ?? null,
    };

    const { error: upErr } = await sb.from('profiles').update(updates).eq('id', user.id);
    if (upErr) throw upErr;

    // Audit log
    await sb.from('audit_logs').insert({
      actor_id: user.id, action: 'fayda.verified',
      resource_type: 'profile', resource_id: user.id,
      details: { fcn_last4: fcn.slice(-4) },
    });

    // Cleanup session
    await sb.from('fayda_oidc_sessions').delete().eq('user_id', user.id);

    return new Response(JSON.stringify({ ok: true, fcn_last4: fcn.slice(-4) }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
