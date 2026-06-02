-- Ephemeral storage for Fayda OIDC handshake (state/nonce/PKCE)
create table public.fayda_oidc_sessions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  state text not null,
  nonce text not null,
  code_verifier text not null,
  created_at timestamptz default now()
);

alter table public.fayda_oidc_sessions enable row level security;

-- Only service role accesses this (no policies for authenticated users)
create policy "fayda_sess_admin" on public.fayda_oidc_sessions
  for all using (public.is_admin()) with check (public.is_admin());
