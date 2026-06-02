// Send transactional email via Resend (https://resend.com).
// Set RESEND_API_KEY and EMAIL_FROM in Edge Function secrets.
import { handleCors, corsHeaders } from '../_shared/cors.ts';
import { getUser } from '../_shared/supabase.ts';

const RESEND_KEY = Deno.env.get('RESEND_API_KEY') ?? '';
const FROM = Deno.env.get('EMAIL_FROM') ?? 'BG-Check <noreply@example.com>';

Deno.serve(async (req) => {
  const cors = handleCors(req); if (cors) return cors;
  try {
    await getUser(req);
    const { to, subject, html } = await req.json();
    if (!to || !subject || !html) throw new Error('to, subject, html required');
    if (!RESEND_KEY) {
      return new Response(JSON.stringify({ ok: false, error: 'RESEND_API_KEY not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }
    const r = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { Authorization: `Bearer ${RESEND_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ from: FROM, to, subject, html }),
    });
    const body = await r.json();
    return new Response(JSON.stringify({ ok: r.ok, body }),
      { status: r.ok ? 200 : 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }
});
