-- =====================================================================
-- Storage buckets and helpful views
-- =====================================================================

-- Buckets
insert into storage.buckets (id, name, public)
values
  ('documents', 'documents', false),
  ('avatars', 'avatars', true),
  ('reports', 'reports', false)
on conflict (id) do nothing;

-- Storage policies: documents bucket
create policy "documents_owner_rw" on storage.objects
  for all to authenticated
  using (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "documents_hr_read" on storage.objects
  for select to authenticated
  using (bucket_id = 'documents' and public.is_hr());

-- Storage policies: avatars (public read, owner write)
create policy "avatars_public_read" on storage.objects
  for select to public using (bucket_id = 'avatars');

create policy "avatars_owner_write" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "avatars_owner_update" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- Storage policies: reports (HR write, candidate read own)
create policy "reports_hr_write" on storage.objects
  for all to authenticated
  using (bucket_id = 'reports' and public.is_hr())
  with check (bucket_id = 'reports' and public.is_hr());

create policy "reports_candidate_read" on storage.objects
  for select to authenticated
  using (bucket_id = 'reports' and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------- Views ----------
create or replace view public.v_candidate_summary as
select
  c.id as candidate_id,
  p.id as profile_id,
  p.full_name,
  p.phone,
  p.fayda_fcn,
  p.fayda_verification_status,
  p.fayda_verified_at,
  c.current_position,
  c.years_experience,
  (select count(*) from public.employment_history e where e.candidate_id = c.id) as total_jobs,
  (select count(*) from public.employment_history e where e.candidate_id = c.id and e.verified) as verified_jobs,
  (select count(*) from public.documents d where d.owner_id = p.id) as total_documents,
  (select count(*) from public.background_checks b where b.candidate_id = c.id) as total_checks,
  (select status from public.background_checks b where b.candidate_id = c.id order by created_at desc limit 1) as latest_check_status,
  (select risk_level from public.background_checks b where b.candidate_id = c.id order by created_at desc limit 1) as latest_risk
from public.candidates c
join public.profiles p on p.id = c.profile_id;

grant select on public.v_candidate_summary to authenticated;

create or replace view public.v_hr_dashboard_stats as
select
  (select count(*) from public.profiles where role = 'candidate') as total_candidates,
  (select count(*) from public.background_checks) as total_checks,
  (select count(*) from public.background_checks where status = 'in_review') as in_review,
  (select count(*) from public.background_checks where status = 'completed') as completed,
  (select count(*) from public.background_checks where risk_level = 'high') as high_risk,
  (select count(*) from public.background_checks where risk_level = 'critical') as critical_risk,
  (select count(*) from public.profiles where fayda_verification_status = 'verified') as fayda_verified;

grant select on public.v_hr_dashboard_stats to authenticated;
