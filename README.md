# Fayda Background Check — HR Consultant

A full-stack employee background-check platform for Ethiopian employers, integrating **Fayda National ID (eSignet OIDC)** for identity verification.

- **Frontend:** Flutter (Android, iOS, Web)
- **Backend:** Supabase (Postgres + Auth + Storage + Edge Functions)
- **Identity:** Fayda eSignet OIDC
- **Roles:** Admin · HR · Candidate

## Features
- 🔐 Fayda OIDC identity verification (FCN/FIN)
- 👤 Multi-role auth (Admin, HR Officer, Candidate)
- 🧾 Employment history CRUD with verification status
- 📎 Document uploads (ID, certificates, reference letters) to Supabase Storage
- ☎️ Reference checks workflow
- ⚖️ Criminal record check requests + status tracking
- 📊 Risk scoring (rule-based) + analytics dashboard
- 📄 PDF report generation
- 📧 Email notifications (Supabase Edge Function + Resend)
- 🗂️ Audit logs for every sensitive action
- 🔍 HR consultant dashboard with filters & search

## Repo Layout
```
fayda-bg-check/
├── app/                     # Flutter app
├── supabase/
│   ├── migrations/          # SQL schema + RLS policies
│   └── functions/           # Edge Functions (Fayda OIDC, PDF, email, risk score)
├── docs/                    # Architecture, API, deploy guide
└── .github/workflows/       # CI: Flutter analyze/test/build
```

See [`docs/DEPLOY.md`](docs/DEPLOY.md) for setup.
