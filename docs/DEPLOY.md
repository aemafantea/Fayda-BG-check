# Deployment Guide — Fayda BG-Check

End-to-end setup: Supabase + Flutter + Fayda OIDC.

---

## 1. Prerequisites

- Node 18+ and Deno (Supabase CLI uses both)
- Flutter SDK 3.22+
- Supabase account → project `dzqinurnkdcwhsbfmzrm`
- Fayda eSignet client credentials (sandbox or production)
- (Optional) Resend account for emails
- A GitHub repo (already set up at `aemafantea/Fayda-BG-check`)

## 2. Supabase setup

### 2.1 Install the Supabase CLI
```bash
brew install supabase/tap/supabase   # or npm i -g supabase
```

### 2.2 Link the project
```bash
cd fayda-bg-check
supabase login
supabase link --project-ref dzqinurnkdcwhsbfmzrm
```

### 2.3 Push migrations
```bash
supabase db push
```
You should see four migrations applied:
- `20260602000001_init_schema.sql`
- `20260602000002_rls_policies.sql`
- `20260602000003_storage_and_views.sql`
- `20260602000004_fayda_sessions.sql`

### 2.4 Configure storage buckets
The migration `20260602000003` creates `documents`, `avatars`, and `reports` buckets automatically — verify in Supabase Studio → Storage.

### 2.5 Set Edge Function secrets
```bash
supabase secrets set \
  FAYDA_BASE_URL="https://esignet.ida.fayda.et" \
  FAYDA_CLIENT_ID="YOUR_CLIENT_ID" \
  FAYDA_CLIENT_SECRET="YOUR_CLIENT_SECRET" \
  FAYDA_REDIRECT_URI="io.supabase.faydabgcheck://login-callback" \
  FAYDA_SCOPES="openid profile email" \
  FAYDA_ACR_VALUES="mosip:idp:acr:generated-code" \
  RESEND_API_KEY="re_..." \
  EMAIL_FROM="BG-Check <noreply@yourdomain.com>"
```

### 2.6 Deploy Edge Functions
```bash
supabase functions deploy fayda-oidc-init
supabase functions deploy fayda-oidc-callback
supabase functions deploy risk-score
supabase functions deploy generate-pdf
supabase functions deploy send-email
```

### 2.7 Create the first admin user
1. Sign up via the app or Supabase dashboard → Auth → Users → Add user.
2. In the SQL editor:
```sql
update public.profiles set role = 'admin' where id = '<that user id>';
```

## 3. Fayda eSignet configuration

1. Go to your Fayda Partner Portal and add the redirect URIs:
   - `io.supabase.faydabgcheck://login-callback` (mobile)
   - `https://YOUR_DOMAIN/auth/fayda-callback` (web)
2. Whitelist the scopes / claims you'll request (see `supabase/functions/fayda-oidc-init/index.ts`).
3. Copy `client_id` + `client_secret` into the Edge Function secrets above.

## 4. Flutter app

### 4.1 Install
```bash
cd app
flutter pub get
```

### 4.2 Run
```bash
# Web
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://dzqinurnkdcwhsbfmzrm.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...

# Android
flutter run -d <device-id> --dart-define=...

# iOS
flutter run -d <ios-device> --dart-define=...
```

### 4.3 Build
```bash
flutter build apk --release --dart-define=...
flutter build web --release --dart-define=...
flutter build ipa --release --dart-define=...
```

## 5. GitHub repo

Already pushed to: <https://github.com/aemafantea/Fayda-BG-check>

CI runs on every push: analyze → test → build web.
Set repo secrets in GitHub → Settings → Secrets → Actions:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## 6. Security checklist

- [ ] Rotate the GitHub PAT (and any keys shared in chat) after deployment.
- [ ] Enable Supabase 2FA on the account.
- [ ] Review RLS policies in `supabase/migrations/20260602000002_rls_policies.sql`.
- [ ] Restrict `FAYDA_CLIENT_SECRET` to Edge Function secrets (never bundle in the app).
- [ ] Configure Supabase Auth → URL Configuration → Site URL + Redirect URLs.
- [ ] Set up backups (Supabase → Database → Backups).
- [ ] Enable email rate limits for sign-up.
