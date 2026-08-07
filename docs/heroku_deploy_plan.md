# Heroku Deploy Plan — Death Bloom Coffee Roasters

A step-by-step runbook to take the app from `main` to a live, custom-domain,
payment-taking site on Heroku.

> **Domain: `deathbloomcoffeeroasters.com`** (confirmed; wired into
> `config/environments/production.rb` and the mailer/support-email defaults).
> Commands assume the Heroku app is named `death-bloom` — rename to taste.

---

## 0. Prerequisites

- Heroku CLI installed and logged in (`heroku login`).
- Payment + email accounts ready in **live** mode: Stripe (live keys + a webhook
  endpoint), Mailgun (verified sending domain, e.g. `mg.deathbloomcoffeeroasters.com`).
- Access to the domain registrar's DNS panel.
- Green build locally: `docker compose run --rm -e RAILS_ENV=test web bundle exec rspec`
  (one known unrelated failure: `Coffee#roast_level` enum drift — see readiness doc M1).

---

## 1. Create the app + Postgres

```bash
heroku create death-bloom --region us
heroku addons:create heroku-postgresql:essential-0 -a death-bloom
heroku stack:set heroku-24 -a death-bloom            # Ruby buildpack, standard stack
```

Deploy uses the **standard Ruby buildpack** (no `heroku.yml`). The Dockerfile is for
local Compose only. The buildpack auto-runs `rails assets:precompile` at build time;
`tailwindcss-rails` and `dartsass-rails` both hook into it, so `tailwind.css` and
`application.css` are built during the slug compile — no manual asset step needed.

---

## 2. Set config vars

Generate secrets with `bin/rails secret`. Set everything the app reads from ENV:

```bash
heroku config:set -a death-bloom \
  RAILS_ENV=production \
  RACK_ENV=production \
  SECRET_KEY_BASE="$(bin/rails secret)" \
  DEVISE_SECRET_KEY="$(bin/rails secret)" \
  APP_HOST="deathbloomcoffeeroasters.com" \
  SUPPORT_EMAIL="deathbloomcoffeeroasters@proton.me" \
  MAIL_FROM="deathbloomcoffeeroasters@proton.me" \
  STRIPE_PUBLISHABLE_KEY="pk_live_…" \
  STRIPE_SECRET_KEY="sk_live_…" \
  STRIPE_WEBHOOK_SECRET="whsec_…"       `# from step 6, set after registering the endpoint` \
  MAILGUN_API_KEY="key-…" \
  MAILGUN_DOMAIN="mg.deathbloomcoffeeroasters.com" \
  GOOGLE_CLIENT_ID="…" \
  GOOGLE_CLIENT_SECRET="…"
```

Notes:
- `DATABASE_URL` and `POSTGRES_*` are provided by the Postgres addon — don't set them.
- `APP_HOST` is a **bare host, no scheme** — it drives Stripe `success_url`/`cancel_url`
  (forced to `https` in production) and `action_mailer.default_url_options`.
- If the `google_auth` Flipper flag stays off, the Google vars can be placeholders,
  but omitting them entirely may raise at boot — set harmless placeholders if unused.
- **Email identities:** both `MAIL_FROM` (the `From:` header) and `SUPPORT_EMAIL`
  (customer-facing contact + Reply-To) are set to `deathbloomcoffeeroasters@proton.me`
  — everything runs from one inbox.
  **Deliverability caveat:** Mailgun cannot DKIM-sign for `proton.me`, so mail sent
  From this address via Mailgun is **not DMARC-aligned** and may be spam-filtered or
  rejected by strict receivers. To fix without giving up the single-inbox setup, either:
  (a) send outbound mail through **Proton's own SMTP** (Proton Mail Bridge / paid
  business SMTP) instead of Mailgun, so the domain that signs the mail matches the
  From; or (b) set `MAIL_FROM` back to an on-domain address like
  `orders@deathbloomcoffeeroasters.com` (Mailgun-signed) while keeping `SUPPORT_EMAIL`
  as the Proton Reply-To — replies still land in Proton. Verify inbox placement during
  the smoke test (step 8) before relying on it.

---

## 3. Fix the Procfile `css` worker before deploy

`Procfile` currently has:

```
css: bundle exec rails dartsass:watch
```

`dartsass:watch` is a **development file-watcher** — it must not run as a Heroku dyno.
Assets are already compiled at build time (step 1). Either remove the `css:` line or
never scale that dyno. Ensure only `web` and `release` run:

```bash
heroku ps:scale web=1 css=0 -a death-bloom
```

The `release:` phase (`bundle exec rails db:migrate`) runs automatically on every
deploy — including the new `AddTrackingToOrders` migration.

---

## 4. Deploy

```bash
git push heroku main
```

Watch the release phase migrate the DB:

```bash
heroku logs --tail -a death-bloom
```

---

## 5. Seed flags + a real admin (careful)

`db/seeds.rb` registers Flipper flags and creates an admin **`admin@dev.com` /
`admindev123`** — fine for local, **unacceptable in production**. Two options:

**A. Seed flags only, create admin manually (recommended):**
```bash
heroku run -a death-bloom rails runner '
  %i[subscriptions admin_tools announcement_bar maintenance_mode newsletter google_auth].each { |f| Flipper.add(f) unless Flipper.exist?(f) }
  User.create!(email: "you@deathbloomcoffeeroasters.com", password: ENV.fetch("ADMIN_SEED_PASSWORD"), role: :admin)
'
```
(Set `ADMIN_SEED_PASSWORD` as a one-off config var, then unset it.)

**B. Run seeds, then immediately rotate the admin:**
```bash
heroku run -a death-bloom rails db:seed
heroku run -a death-bloom rails runner 'User.find_by(email:"admin@dev.com").update!(email:"you@deathbloomcoffeeroasters.com", password: SecureRandom.base58(24))'
```

Admin UI lives at `/admin` (dashboard → **Orders** for fulfillment, **Feature Manager**
for flags). Flipper UI is at `/admin/flipper`, gated by `AdminConstraint`.

---

## 6. Register the Stripe webhook

Fulfillment depends on it (the `/checkout/success` fallback is a safety net, not a
substitute).

1. Stripe Dashboard → Developers → Webhooks → **Add endpoint**
   `https://deathbloomcoffeeroasters.com/webhooks/stripe`
2. Event: **`checkout.session.completed`**.
3. Copy the endpoint's **Signing secret** → set `STRIPE_WEBHOOK_SECRET` (step 2) and
   redeploy or `heroku config:set`.
4. Confirm you're using **live** API keys, not test.

---

## 7. Custom domain + SSL

```bash
heroku domains:add deathbloomcoffeeroasters.com      -a death-bloom
heroku domains:add www.deathbloomcoffeeroasters.com  -a death-bloom
heroku domains -a death-bloom                # prints the DNS targets to use
```

Heroku returns a DNS target per domain (e.g. `xxxx.herokudns.com`). At your registrar:

| Record | Host | Points to |
|--------|------|-----------|
| `ALIAS`/`ANAME` (or apex `CNAME` flattening) | `@` (apex) | apex DNS target from `heroku domains` |
| `CNAME` | `www` | www DNS target from `heroku domains` |

Apex domains can't use a plain `CNAME` — use your registrar's ALIAS/ANAME/CNAME-flattening
(Cloudflare, DNSimple, Route 53 alias all support this). If the registrar only does
plain records, front the apex with a redirect to `www` or move DNS to a provider that
supports ALIAS.

Then enable automated certs:

```bash
heroku certs:auto:enable -a death-bloom
heroku certs:auto -a death-bloom             # watch until status = Cert issued
```

`force_ssl` + `assume_ssl` are already on in production, so HTTP → HTTPS is automatic
once the cert is live. Decide whether apex or `www` is canonical and 301 the other.

**Also update, for the live domain:**
- Google OAuth (if `google_auth` on): add `https://deathbloomcoffeeroasters.com/users/auth/google_oauth2/callback` as an authorized redirect URI.
- Mailgun: verify `mg.deathbloomcoffeeroasters.com` DNS (SPF/DKIM/MX) so confirmation emails deliver.

---

## 8. Post-deploy smoke test (do this before announcing)

The one thing the automated suite can't cover is Stripe's hosted page. Run a real
end-to-end pass:

1. Visit `https://deathbloomcoffeeroasters.com`, register, add a coffee, check out.
2. Complete payment with a **live** card (or a Stripe test card if the endpoint is
   still in test mode for the dry run).
3. Confirm: webhook fires (`heroku logs`), order appears with a `DB-XXXXXX` number,
   confirmation email arrives.
4. In `/admin/orders`, mark it **shipped** with a carrier + tracking number; confirm
   the tracking link renders on the customer's order page and `/orders/lookup` works
   for the same order via email.
5. Refund/clean up the test order in Stripe.

Health check: `https://deathbloomcoffeeroasters.com/up` should return 200 — point Heroku
monitoring / an uptime pinger at it.

---

## 9. Rollback

```bash
heroku releases -a death-bloom
heroku rollback vNNN -a death-bloom          # reverts code + config to a prior release
```

Migrations are not auto-reverted by `rollback` — the `AddTrackingToOrders` migration
is additive (nullable columns), so a code rollback is safe without a DB rollback.

---

## 10. Close before / soon after launch (from the readiness doc)

**Before taking real orders:**
- Rotate/replace the seed admin credentials (step 5).
- Confirm Mailgun deliverability end to end (H4).
- (Admin catalog/user/fulfillment UI is now in place; `admin/audit_logs` was removed.)

**Soon after:**
- Inventory/stock control to prevent overselling (B3).
- Re-validate cart pricing/availability at fulfillment (H1) and handle the
  zero-line-item fallback (H2).
- Add `rack-attack` throttling on `/orders/lookup` (M2).
- Reconcile the `Coffee#roast_level` enum (M1).
