# 🧪 Demo sign-in credentials

> These accounts exist in the live Supabase project `dzqinurnkdcwhsbfmzrm`.
> Use them to explore each role in the app **without** signing up yourself.
> **Please don't change passwords** — others rely on them.

| Role | Email | Password |
|---|---|---|
| 👤 **Candidate** | `fayda.demo.candidate@gmail.com` | `Demo@1234` |
| 💼 **HR Officer** | `fayda.demo.hr@gmail.com` | `Demo@1234` |
| 🛡️ **Admin** | `fayda.demo.admin@gmail.com` | `Demo@1234` |

## What each role sees

### 👤 Candidate
- Personal dashboard with profile-completeness checklist
- Fayda verification banner (mock until OIDC creds are configured)
- CRUD their **own** employment history
- Upload/view their **own** documents
- View any background check that targets them (and give consent)

### 💼 HR Officer
- KPI dashboard (total candidates, in-review, completed, high-risk, etc.) with risk-distribution pie chart
- Search & browse all candidates
- View any candidate's full profile, employment history, docs
- Verify employment records
- Create new background checks (pick candidate + check types)
- Run risk scoring & generate PDF reports

### 🛡️ Admin
- Everything HR can do, plus:
- Promote/demote any user's role (candidate ↔ hr ↔ admin)
- Read the full audit log
- View platform stats

## Want your own account instead?
Sign up from the app — you'll start as `candidate` by default. To upgrade yourself, sign in as the demo admin and use **Admin → Users → ⋮ → Make admin**.

## Resetting demo data
If the demos get cluttered, an admin can:
```sql
-- in Supabase SQL editor
delete from public.background_checks where requested_by in (
  select id from public.profiles where full_name like 'Demo %'
);
delete from public.employment_history where candidate_id in (
  select id from public.candidates where profile_id in (
    select id from public.profiles where full_name like 'Demo %'
  )
);
```
