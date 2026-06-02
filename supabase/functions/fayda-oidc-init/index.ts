// Fayda eSignet OIDC — step 1: build authorization URL
// Docs: https://esignet.ida.fayda.et / https://docs.fayda.et
import { handleCors, corsHeaders } from '../_shared/cors.ts';
import { getUser, getServiceClient } from '../_shared/supabase.ts';

const FAYDA_BASE = Deno.env.get('FAYDA_BASE_URL') ?? 'https://esignet.ida.fayda.et';
const CLIENT_ID = Deno.env.get('FAYDA_CLIENT_ID') ?? '';
const REDIRECT_URI = Deno.env.get('FAYDA_REDIRECT_URI') ?? '';
const SCOPES = Deno.env.get('FAYDA_SCOPES') ?? 'openid profile email';
const ACR = Deno.env.get('FAYDA_ACR_VALUES') ?? 'mosip:idp:acr:generated-code';
const CLAIMS = Deno.env.get('FAYDA_CLAIMS') ??
  JSON.stringify({
    userinfo: {
      name:                 { essential: true },
      birthdate:            { essential: true },
      gender:               { essential: true },
      phone_number:         { essential: true },
      email:                { essential: false },
      picture:              { essential: false },
      address:              { essential: false },
      individual_id:        { essential: true },
    },
    id_token: {},
  });

function base64url(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function genCodeVerifierAndChallenge() {
  const v = base64url(crypto.getRandomValues(new Uint8Array(32)));
  const hash = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(v));
  const challenge = base64url(new Uint8Array(hash));
  return { verifier: v, challenge };
}

Deno.serve(async (req) => {
  const cors = handleCors(req); if (cors) return cors;
  try {
    const user = await getUser(req);
    const { verifier, challenge } = await genCodeVerifierAndChallenge();
    const state = base64url(crypto.getRandomValues(new Uint8Array(16)));
    const nonce = base64url(crypto.getRandomValues(new Uint8Array(16)));

    // Persist verifier+state keyed by user
    const sb = getServiceClient();
    await sb.from('fayda_oidc_sessions').upsert({
      user_id: user.id,
      state, nonce, code_verifier: verifier,
      created_at: new Date().toISOString(),
    });

    const params = new URLSearchParams({
      response_type: 'code',
      client_id: CLIENT_ID,
      redirect_uri: REDIRECT_URI,
      scope: SCOPES,
      state,
      nonce,
      acr_values: ACR,
      claims: CLAIMS,
      code_challenge: challenge,
      code_challenge_method: 'S256',
      display: 'page',
      prompt: 'consent',
      max_age: '21',
    });
    const url = `${FAYDA_BASE}/authorize?${params.toString()}`;

    return new Response(JSON.stringify({ url, state }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
