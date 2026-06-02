-- =====================================================================
-- Fayda BG-Check — Initial Schema
-- Multi-role employee background check & HR consultant platform
-- =====================================================================

-- Extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ---------- Enums ----------
create type user_role as enum ('admin', 'hr', 'candidate');
create type verification_status as enum ('pending', 'verified', 'failed', 'expired');
create type check_status as enum ('draft', 'submitted', 'in_review', 'completed', 'rejected');
create type check_type as enum (
  'identity',
  'employment_history',
  'education',
  'criminal_record',
  'reference',
  'credit',
  'driving_record'
);
create type risk_level as enum ('low', 'medium', 'high', 'critical');
create type doc_type as enum (
  'national_id',
  'passport',
  'certificate',
  'transcript',
  'reference_letter',
  'employment_letter',
  'police_clearance',
  'other'
);

-- ---------- Profiles (extends auth.users) ----------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role user_role not null default 'candidate',
  full_name text,
  phone text,
  avatar_url text,
  organization_id uuid,
  fayda_fcn text unique,                       -- Fayda Citizen Number (16 digits)
  fayda_fin text,                              -- Fayda Identification Number
  fayda_verified_at timestamptz,
  fayda_verification_status verification_status default 'pending',
  fayda_claims jsonb,                          -- raw OIDC claims for audit
  date_of_birth date,
  gender text,
  nationality text default 'ET',
  address jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index profiles_role_idx on public.profiles(role);
create index profiles_org_idx on public.profiles(organization_id);

-- ---------- Organizations (HR firms / employers) ----------
create table public.organizations (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  tin text,                                    -- Tax Identification Number
  industry text,
  contact_email text,
  contact_phone text,
  address jsonb,
  logo_url text,
  is_active boolean default true,
  owner_id uuid references public.profiles(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.profiles
  add constraint profiles_org_fk foreign key (organization_id)
  references public.organizations(id) on delete set null;

-- ---------- Candidates (extended candidate-specific data) ----------
create table public.candidates (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null unique references public.profiles(id) on delete cascade,
  current_position text,
  years_experience int,
  linkedin_url text,
  bio text,
  skills text[],
  languages text[],
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ---------- Employment history ----------
create table public.employment_history (
  id uuid primary key default uuid_generate_v4(),
  candidate_id uuid not null references public.candidates(id) on delete cascade,
  employer_name text not null,
  position_title text not null,
  start_date date not null,
  end_date date,                               -- null = current
  is_current boolean default false,
  employment_type text,                        -- full-time, part-time, contract...
  location text,
  responsibilities text,
  reason_for_leaving text,
  supervisor_name text,
  supervisor_phone text,
  supervisor_email text,
  monthly_salary numeric,
  verified boolean default false,
  verified_by uuid references public.profiles(id),
  verified_at timestamptz,
  verification_notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index emp_history_candidate_idx on public.employment_history(candidate_id);

-- ---------- Education ----------
create table public.education (
  id uuid primary key default uuid_generate_v4(),
  candidate_id uuid not null references public.candidates(id) on delete cascade,
  institution_name text not null,
  degree text,
  field_of_study text,
  start_date date,
  end_date date,
  gpa numeric,
  verified boolean default false,
  verified_at timestamptz,
  created_at timestamptz default now()
);

-- ---------- Background check requests ----------
create table public.background_checks (
  id uuid primary key default uuid_generate_v4(),
  candidate_id uuid not null references public.candidates(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete set null,
  requested_by uuid references public.profiles(id),
  assigned_to uuid references public.profiles(id),
  check_types check_type[] not null default '{identity}',
  status check_status not null default 'draft',
  risk_level risk_level,
  risk_score int,                              -- 0-100
  risk_factors jsonb,
  consent_given boolean default false,
  consent_signed_at timestamptz,
  consent_ip text,
  notes text,
  report_url text,                             -- generated PDF
  submitted_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index bg_checks_candidate_idx on public.background_checks(candidate_id);
create index bg_checks_org_idx on public.background_checks(organization_id);
create index bg_checks_status_idx on public.background_checks(status);

-- ---------- Reference checks ----------
create table public.references (
  id uuid primary key default uuid_generate_v4(),
  background_check_id uuid not null references public.background_checks(id) on delete cascade,
  employment_history_id uuid references public.employment_history(id),
  referee_name text not null,
  referee_position text,
  referee_company text,
  referee_phone text,
  referee_email text,
  relationship text,
  contacted boolean default false,
  contacted_at timestamptz,
  response_received boolean default false,
  response_received_at timestamptz,
  rating int,                                  -- 1-5
  feedback text,
  would_rehire boolean,
  created_at timestamptz default now()
);

-- ---------- Criminal record checks ----------
create table public.criminal_records (
  id uuid primary key default uuid_generate_v4(),
  background_check_id uuid not null references public.background_checks(id) on delete cascade,
  jurisdiction text,
  check_date date,
  has_records boolean default false,
  record_details jsonb,
  clearance_certificate_url text,
  status verification_status default 'pending',
  notes text,
  created_at timestamptz default now()
);

-- ---------- Documents ----------
create table public.documents (
  id uuid primary key default uuid_generate_v4(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  background_check_id uuid references public.background_checks(id) on delete cascade,
  doc_type doc_type not null,
  file_name text not null,
  file_path text not null,                     -- Supabase Storage path
  file_size bigint,
  mime_type text,
  description text,
  is_verified boolean default false,
  verified_by uuid references public.profiles(id),
  verified_at timestamptz,
  uploaded_at timestamptz default now()
);

create index documents_owner_idx on public.documents(owner_id);
create index documents_bg_check_idx on public.documents(background_check_id);

-- ---------- Notifications ----------
create table public.notifications (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text,
  type text,                                   -- info, success, warning, error
  link text,
  is_read boolean default false,
  created_at timestamptz default now()
);

create index notifications_user_idx on public.notifications(user_id, is_read);

-- ---------- Audit log ----------
create table public.audit_logs (
  id uuid primary key default uuid_generate_v4(),
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,                        -- e.g., 'bg_check.created', 'document.viewed'
  resource_type text,
  resource_id uuid,
  details jsonb,
  ip_address text,
  user_agent text,
  created_at timestamptz default now()
);

create index audit_logs_actor_idx on public.audit_logs(actor_id, created_at desc);
create index audit_logs_resource_idx on public.audit_logs(resource_type, resource_id);

-- ---------- updated_at trigger ----------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare t text;
begin
  for t in select unnest(array[
    'profiles','organizations','candidates','employment_history',
    'background_checks'
  ]) loop
    execute format(
      'create trigger %I_set_updated_at before update on public.%I
       for each row execute function public.set_updated_at();', t, t);
  end loop;
end$$;

-- ---------- Auto-create profile on signup ----------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)),
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'candidate')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();
