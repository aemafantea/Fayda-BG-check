-- =====================================================================
-- Row Level Security policies
-- =====================================================================

alter table public.profiles            enable row level security;
alter table public.organizations       enable row level security;
alter table public.candidates          enable row level security;
alter table public.employment_history  enable row level security;
alter table public.education           enable row level security;
alter table public.background_checks   enable row level security;
alter table public.references          enable row level security;
alter table public.criminal_records    enable row level security;
alter table public.documents           enable row level security;
alter table public.notifications       enable row level security;
alter table public.audit_logs          enable row level security;

-- Helper: get current user's role
create or replace function public.current_role_name()
returns text language sql stable security definer as $$
  select role::text from public.profiles where id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

create or replace function public.is_hr()
returns boolean language sql stable security definer as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role in ('hr','admin'));
$$;

-- ---------- profiles ----------
create policy "profiles_select_self_or_hr" on public.profiles
  for select using (auth.uid() = id or public.is_hr());

create policy "profiles_update_self" on public.profiles
  for update using (auth.uid() = id)
  with check (auth.uid() = id and role = (select role from public.profiles where id = auth.uid()));

create policy "profiles_admin_all" on public.profiles
  for all using (public.is_admin()) with check (public.is_admin());

-- ---------- organizations ----------
create policy "orgs_select_all_auth" on public.organizations
  for select using (auth.uid() is not null);

create policy "orgs_admin_write" on public.organizations
  for all using (public.is_admin()) with check (public.is_admin());

-- ---------- candidates ----------
create policy "candidates_self_select" on public.candidates
  for select using (profile_id = auth.uid() or public.is_hr());

create policy "candidates_self_write" on public.candidates
  for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());

create policy "candidates_hr_all" on public.candidates
  for all using (public.is_hr()) with check (public.is_hr());

-- ---------- employment_history ----------
create policy "emp_history_self" on public.employment_history
  for all using (
    candidate_id in (select id from public.candidates where profile_id = auth.uid())
    or public.is_hr()
  ) with check (
    candidate_id in (select id from public.candidates where profile_id = auth.uid())
    or public.is_hr()
  );

-- ---------- education ----------
create policy "education_self" on public.education
  for all using (
    candidate_id in (select id from public.candidates where profile_id = auth.uid())
    or public.is_hr()
  ) with check (
    candidate_id in (select id from public.candidates where profile_id = auth.uid())
    or public.is_hr()
  );

-- ---------- background_checks ----------
create policy "bg_check_candidate_view" on public.background_checks
  for select using (
    candidate_id in (select id from public.candidates where profile_id = auth.uid())
    or public.is_hr()
  );

create policy "bg_check_hr_write" on public.background_checks
  for all using (public.is_hr()) with check (public.is_hr());

create policy "bg_check_candidate_consent" on public.background_checks
  for update using (
    candidate_id in (select id from public.candidates where profile_id = auth.uid())
  ) with check (
    candidate_id in (select id from public.candidates where profile_id = auth.uid())
  );

-- ---------- references ----------
create policy "references_hr_all" on public.references
  for all using (public.is_hr()) with check (public.is_hr());

create policy "references_candidate_view" on public.references
  for select using (
    background_check_id in (
      select bg.id from public.background_checks bg
      join public.candidates c on c.id = bg.candidate_id
      where c.profile_id = auth.uid()
    )
  );

-- ---------- criminal_records ----------
create policy "crim_hr_all" on public.criminal_records
  for all using (public.is_hr()) with check (public.is_hr());

create policy "crim_candidate_view" on public.criminal_records
  for select using (
    background_check_id in (
      select bg.id from public.background_checks bg
      join public.candidates c on c.id = bg.candidate_id
      where c.profile_id = auth.uid()
    )
  );

-- ---------- documents ----------
create policy "docs_owner_all" on public.documents
  for all using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy "docs_hr_view" on public.documents
  for select using (public.is_hr());

create policy "docs_hr_verify" on public.documents
  for update using (public.is_hr()) with check (public.is_hr());

-- ---------- notifications ----------
create policy "notif_self_all" on public.notifications
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------- audit_logs ----------
create policy "audit_admin_view" on public.audit_logs
  for select using (public.is_admin());

create policy "audit_insert_auth" on public.audit_logs
  for insert with check (auth.uid() is not null);
