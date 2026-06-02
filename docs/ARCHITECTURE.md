# Architecture

```
┌────────────────────────────┐        ┌──────────────────────────┐
│      Flutter Client        │        │   Fayda eSignet (OIDC)   │
│ (Android / iOS / Web)      │ ──────▶│  /authorize → /token     │
│ Riverpod + GoRouter        │ ◀───── │  /userinfo  (claims)     │
└────────────┬───────────────┘        └────────────┬─────────────┘
             │ HTTPS                                │
             ▼                                      │
┌────────────────────────────────────────────────┐  │
│           Supabase Cloud (eu-central-1)        │  │
│                                                │  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │  │
│  │  Postgres   │  │   Auth      │  │ Storage │ │  │
│  │  + RLS      │  │  (PKCE)     │  │ (S3-compat) │
│  └─────────────┘  └─────────────┘  └─────────┘ │  │
│                                                │  │
│  ┌──────────────────────────────────────────┐  │  │
│  │ Edge Functions (Deno)                     │ ◀┼──┘
│  │  • fayda-oidc-init                        │  │
│  │  • fayda-oidc-callback                    │  │
│  │  • risk-score                             │  │
│  │  • generate-pdf                           │  │
│  │  • send-email (Resend)                    │  │
│  └──────────────────────────────────────────┘  │
└────────────────────────────────────────────────┘
```

## Modules

### Frontend (Flutter)
- **`core/`** – theme, router, env config
- **`data/models/`** – plain Dart models (Profile, Candidate, EmploymentRecord, BackgroundCheck, AppDocument, AppNotification)
- **`data/repositories/`** – `AuthRepository`, `BgCheckRepository` (single source of truth talking to Supabase)
- **`features/`** – feature-first folders: `auth`, `candidate`, `hr`, `admin`, `shared`

### Backend (Supabase)
- **`public.profiles`** – extends `auth.users` with role + Fayda fields.
- **`public.candidates`** – 1:1 with candidate profiles, adds career-specific fields.
- **`public.employment_history`, `education`, `references`, `criminal_records`** – child tables.
- **`public.background_checks`** – the central workflow object.
- **`public.documents`** – metadata for files stored in `documents` bucket.
- **`public.notifications`, `audit_logs`** – cross-cutting.
- **Views** – `v_candidate_summary`, `v_hr_dashboard_stats`.

### RLS model
- `candidate` → can only see/modify their own rows.
- `hr` → can see/modify all candidate-related rows in their org.
- `admin` → full access; only one who can read `audit_logs`.

### Risk scoring (rule-based)
Edge function `risk-score` aggregates weighted factors:
- Identity unverified (+30)
- Employment verification rate < 50% (proportional)
- Employment gaps > 6 months (+5 each)
- Missing references (+10) / negative references (+15 per "would not rehire")
- Criminal record found (+40)
- Low document count (+5)

Final score is clamped 0–100 → mapped to `low/medium/high/critical`.

## Data flow: HR creates a check
1. HR picks a candidate, selects check types (identity, employment, references, …).
2. App `POST` `/rest/v1/background_checks` (RLS allows because role=hr).
3. Candidate logs in, opens the check, taps "Give consent" (updates `consent_given`).
4. HR uploads/verifies docs, contacts references, fills criminal records.
5. HR triggers `risk-score` Edge Function → updates `risk_level`/`risk_score`/`risk_factors`.
6. HR triggers `generate-pdf` Edge Function → uploads HTML to `reports` bucket, returns signed URL.
7. Optional: trigger `send-email` to deliver report to the requester.
