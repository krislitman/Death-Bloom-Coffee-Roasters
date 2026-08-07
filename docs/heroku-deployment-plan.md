# Heroku Deployment Plan — Death Bloom Coffee Roasters

Status: **Plan — not yet executed.** No application code has been changed by this document.

Target: Rails 8.1 app on Heroku Cedar / `heroku-24` stack with the custom domain
`deathbloomcoffeeroasters.com`, PostgreSQL (Heroku Postgres), Mailgun for mail, Stripe
Checkout for payments, Google OAuth for sign-in, Flipper for feature flags.

---

## 1. Blockers found in the current repo

These will fail a deploy — or silently misbehave — as the code stands today. They must be
fixed before the first `git push heroku`.

### 1.1 Ruby version is not available on Heroku — **hard blocker**

- `.ruby-version` pins `4.0.2`.
- `Gemfile` has **no `ruby` directive**, and `Gemfile.lock` has **no `RUBY VERSION` section**.
- Heroku's Ruby buildpack reads the version from `Gemfile.lock`'s `RUBY VERSION` block. With
  it absent, the build falls back to the stack default (MRI `3.3.9`) — a different major
  version than the app is developed against, and older than `BUNDLED WITH 4.0.6` expects.
- On `heroku-24`, supported Ruby versions are `3.3.12`, `3.4.10`, and `4.0.6`. Versions
  `4.0.0`–`4.0.5` are listed as unsupported/EOL, so **`4.0.2` cannot be installed at all**.

**Fix:** move to `4.0.6` everywhere.

```ruby
# Gemfile (top, under the source line)
ruby "4.0.6"
```

```
# .ruby-version
4.0.6
```

Then `bundle update --ruby` (or `bundle install`) to write the `RUBY VERSION` block into
`Gemfile.lock`, and commit the lock. Rebuild the Docker image locally so dev matches prod.

**Verify:** `grep -A2 "^RUBY VERSION" Gemfile.lock` returns `ruby 4.0.6`.

### 1.2 `Procfile` starts a Dart Sass **watcher** as a production dyno — **hard blocker**

```
web: bundle exec puma -C config/puma.rb
release: bundle exec rails db:migrate
css: bundle exec rails dartsass:watch      # <-- dev-only, must not ship
```

`dartsass:watch` is a development file watcher. On Heroku it becomes a scalable process type;
if ever scaled up it burns a dyno recompiling CSS on an ephemeral filesystem that the web dyno
cannot see. CSS is already built at slug-compile time by `assets:precompile`.

**Fix:** drop the `css:` line from `Procfile` (it belongs in `Procfile.dev`, which already
exists). Final production `Procfile`:

```
web: bundle exec puma -C config/puma.rb
release: bundle exec rails db:migrate
```

### 1.3 `config/database.yml` leaks development connection settings into production

```yaml
default: &default
  adapter: postgresql
  max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>   # not a valid AR key
  host: <%= ENV.fetch("POSTGRES_HOST", "db") %>                   # Docker service name
  username: <%= ENV.fetch("POSTGRES_USER", "death_bloom") %>
  password: <%= ENV.fetch("POSTGRES_PASSWORD", "") %>

production:
  <<: *default
  url: <%= ENV["DATABASE_URL"] %>
```

Two problems:

1. `max_connections` is not an Active Record configuration key — the correct key is `pool`.
   The connection pool is therefore silently sitting at the default, not tracking
   `RAILS_MAX_THREADS`.
2. The production block inherits `host`/`username`/`password` alongside `url`. On Heroku,
   `POSTGRES_HOST` etc. are unset, so the merged config carries `host: db`,
   `username: death_bloom`, `password: ""` next to the real `DATABASE_URL`. Whether the URL or
   the explicit keys win is a detail of `UrlConfig` merge order that this app should not be
   betting its production database connection on.

**Fix:** make production depend on `DATABASE_URL` alone.

```yaml
production:
  adapter: postgresql
  encoding: unicode
  url: <%= ENV["DATABASE_URL"] %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

And correct `max_connections` → `pool` in the `default` anchor for dev/test.

**Verify after deploy:** `heroku run rails runner 'puts ActiveRecord::Base.connection_db_config.configuration_hash.except(:password).inspect'`
should show the Heroku Postgres host, not `db`.

### 1.4 `production.rb` uses `ENV.fetch` with no default for Mailgun — boot-time crash

```ruby
config.action_mailer.mailgun_settings = {
  api_key: ENV.fetch("MAILGUN_API_KEY"),
  domain:  ENV.fetch("MAILGUN_DOMAIN")
}
```

`ENV.fetch` without a default raises `KeyError` **during environment load**. If these config
vars are not set before the first deploy, the release-phase `db:migrate` crashes, the release
fails, and the app never boots — with an error that reads like a mailer problem rather than a
missing-config problem.

**Fix (choose one):**
- **Preferred, no code change:** set `MAILGUN_API_KEY` and `MAILGUN_DOMAIN` as config vars
  *before* the first push (see §4). Fail-fast on missing mail credentials is defensible.
- **Alternative:** soften to `ENV.fetch("MAILGUN_API_KEY", nil)` so the app boots without mail.
  Not recommended — a silently non-mailing store is worse than a loud boot failure.

This plan assumes the preferred option: **config vars are set before the first push.**

### 1.5 `db/seeds.rb` creates a hardcoded admin — must never run as-is in production

```ruby
admin = User.find_or_initialize_by(email: "admin@dev.com")
admin.assign_attributes(password: "admindev123", ...)
admin.role = :admin
```

Running `heroku run rails db:seed` would create a publicly-known admin account with a
publicly-known password on the live store, behind which sits the Flipper UI and the full
admin namespace.

Seeds are otherwise genuinely needed in production — the Flipper flags
(`subscriptions`, `admin_tools`, `announcement_bar`, `maintenance_mode`, `newsletter`,
`google_auth`) and the tasting-note vocabulary must exist.

**Fix:** split the seed file so the admin block is environment-aware and credential-driven:

```ruby
# db/seeds.rb — admin section
if Rails.env.production?
  email = ENV["ADMIN_EMAIL"]
  password = ENV["ADMIN_PASSWORD"]
  if email.present? && password.present?
    admin = User.find_or_initialize_by(email: email)
    admin.assign_attributes(password: password, password_confirmation: password, role: :admin)
    admin.save!
  end
else
  # existing admin@dev.com block
end
```

Set `ADMIN_EMAIL` / `ADMIN_PASSWORD` as config vars for the single seed run, then
`heroku config:unset ADMIN_PASSWORD` immediately afterward and rotate the password through
the app's own password-reset flow.

**Spec to add (TDD, per project workflow):** a request or model spec asserting that
`User.exists?(email: "admin@dev.com")` is false after seeding with `Rails.env` stubbed to
production. This is the one piece of §1 that carries a test.

### 1.6 Secrets: `RAILS_MASTER_KEY` and `DEVISE_SECRET_KEY`

- `config/master.key` is correctly gitignored (verified) and `config/credentials.yml.enc` is
  committed. Heroku therefore **must** receive `RAILS_MASTER_KEY`, or credentials decryption
  fails at boot.
- `config/initializers/devise.rb` sets `config.secret_key = ENV["DEVISE_SECRET_KEY"]`. If that
  var is unset in production it evaluates to `nil`, and Devise falls back to `secret_key_base`.
  That fallback is fine *functionally*, but it means the value must be set consistently from
  day one — changing it later invalidates every outstanding password-reset and confirmation
  token. Set it explicitly before launch and never rotate it casually.
- `SECRET_KEY_BASE`: set explicitly rather than relying on credentials, so key rotation and
  credential rotation stay independent.

---

## 2. Non-blocking risks — decide before launch, not after

| # | Item | Impact | Recommendation |
|---|---|---|---|
| 2.1 | **Active Job adapter is `:async`** (default; nothing set in `production.rb`) | Order confirmation mail is enqueued in-process. A dyno restart — which Heroku does at least daily — drops any in-flight job silently. A customer pays and never gets a receipt. | For launch volume this is a real but low-frequency risk. Either accept it explicitly, or add `solid_queue` + a `worker:` dyno. Given Stripe Checkout already emails its own receipt, accepting it for v1 is defensible — but log every `OrderMailer` delivery so drops are detectable. |
| 2.2 | **Cache store is the default file store** on an ephemeral dyno | Fragment caches are per-dyno and vanish on restart. Correct, just not shared. | Fine at one web dyno. Revisit (`solid_cache`, or Redis) when scaling past one. |
| 2.3 | `thruster` is in the Gemfile but unused by the `Procfile` | No impact; the Dockerfile's production stage uses it, Heroku won't. | Leave as-is. Heroku's router already handles compression/caching concerns Thruster targets. |
| 2.4 | No CI workflow (`.github/workflows` is absent) | 21 spec files, nothing runs them on push. Regressions reach `main` unchecked. | Add a GitHub Actions workflow running `bundle exec rspec` before enabling any auto-deploy from `main`. |
| 2.5 | `config.hosts` not configured | Rails 8 applies host authorization in development only, so this is not a production hole today. | Optional hardening: set `config.hosts` to the apex + `www` + `*.herokuapp.com`. |
| 2.6 | Deploying from a **worktree branch** | This plan lives on `worktree-heroku-deploy-plan`. | Merge to `main` before deploying; Heroku deploys `main`. |

---

## 3. Provisioning steps

The Heroku CLI is **not installed on this machine** (`which heroku` → not found). First:

```bash
brew tap heroku/brew && brew install heroku
heroku login
```

Then:

```bash
# 3.1 Create the app on the current stack
heroku create death-bloom-coffee --stack heroku-24 --region us

# 3.2 Buildpack — classic Ruby buildpack (not the Dockerfile; see note below)
heroku buildpacks:set heroku/ruby

# 3.3 Database
heroku addons:create heroku-postgresql:essential-0
# Confirm DATABASE_URL was set automatically:
heroku config:get DATABASE_URL

# 3.4 Papertrail or equivalent for log retention (optional but strongly advised for a store)
heroku addons:create papertrail:choklad
```

**Note on Docker vs. buildpack:** the repo has a production-stage `Dockerfile`, so
`heroku container:push` is possible. This plan uses the **classic Ruby buildpack** because:
release-phase migrations, `RAILS_MASTER_KEY` handling, and asset precompilation all work
out of the box; the Dockerfile's production stage runs `bundle exec rails assets:precompile`
without `SECRET_KEY_BASE_DUMMY`, which would need fixing first; and the buildpack keeps the
deploy to a plain `git push`. The Dockerfile remains the local-development path via Docker
Compose, unchanged.

---

## 4. Config vars — set **all** of these before the first push

Missing values here cause boot failures (§1.4) or broken checkout, so this step precedes
deployment.

```bash
heroku config:set \
  RAILS_ENV=production \
  RACK_ENV=production \
  RAILS_LOG_LEVEL=info \
  RAILS_MAX_THREADS=3 \
  WEB_CONCURRENCY=2 \
  RAILS_MASTER_KEY="$(cat config/master.key)" \
  SECRET_KEY_BASE="$(bin/rails secret)" \
  DEVISE_SECRET_KEY="$(bin/rails secret)" \
  APP_HOST=deathbloomcoffeeroasters.com \
  SUPPORT_EMAIL=hello@deathbloomcoffeeroasters.com \
  MAIL_FROM="Death Bloom Coffee <hello@deathbloomcoffeeroasters.com>"

# Mailgun — required for boot (§1.4)
heroku config:set MAILGUN_API_KEY=... MAILGUN_DOMAIN=mg.deathbloomcoffeeroasters.com

# Stripe — LIVE keys; webhook secret comes from §6
heroku config:set STRIPE_PUBLISHABLE_KEY=pk_live_... STRIPE_SECRET_KEY=sk_live_...

# Google OAuth — see §7 for redirect URI registration
heroku config:set GOOGLE_CLIENT_ID=... GOOGLE_CLIENT_SECRET=...
```

Do **not** set `POSTGRES_HOST`, `POSTGRES_USER`, or `POSTGRES_PASSWORD` on Heroku — after the
§1.3 fix they are dev/Docker-only, and setting them would reintroduce the conflict.

`WEB_CONCURRENCY=2` with `RAILS_MAX_THREADS=3` gives 6 concurrent request slots against a
`pool: 3` per process — comfortable on an Essential-0 Postgres (20 connection limit): 2 workers
× 3 = 6 connections. Start at `WEB_CONCURRENCY=1` on a Basic dyno if memory is tight, and
raise only after watching R14 memory warnings.

**Checklist before pushing** — every one of these must return a value:

```bash
for k in RAILS_MASTER_KEY SECRET_KEY_BASE DEVISE_SECRET_KEY MAILGUN_API_KEY \
         MAILGUN_DOMAIN STRIPE_SECRET_KEY STRIPE_PUBLISHABLE_KEY APP_HOST DATABASE_URL; do
  printf '%s: %s\n' "$k" "$(heroku config:get "$k" | head -c 6)"
done
```

---

## 5. First deploy

```bash
# From main, after §1 fixes are merged
heroku git:remote -a death-bloom-coffee
git push heroku main
```

What should happen, in order:

1. Buildpack detects Ruby `4.0.6` from `Gemfile.lock` (this is the §1.1 fix paying off).
2. `bundle install --without development:test`.
3. `rails assets:precompile` — this is where **both** `dartsass:build` and `tailwindcss:build`
   run, since both gems hook the precompile task. `app/assets/builds/` is gitignored, so these
   two builds are what produce `application.css` and `tailwind.css` in the slug. Both gems ship
   `x86_64-linux` native executables and `Gemfile.lock`'s `PLATFORMS` already includes
   `x86_64-linux` — verified, so no `bundle lock --add-platform` is needed.
4. Release phase: `bundle exec rails db:migrate` against the empty database — applies all
   migrations through `20260806000001_add_tracking_to_orders`.
5. Web dyno boots Puma.

**If the release phase fails**, the deploy is rolled back and the app stays down. Read
`heroku logs --tail --dyno=release` first; the most likely causes are a missing config var
from §4 (§1.4) or the database.yml issue (§1.3).

**Post-deploy verification, in this order:**

```bash
curl -sS -o /dev/null -w '%{http_code}\n' https://death-bloom-coffee-<hash>.herokuapp.com/up   # expect 200
heroku run rails runner 'puts ActiveRecord::Base.connection.active?'                            # expect true
heroku run rails runner 'puts Rails.application.credentials.config.keys.inspect'                # proves RAILS_MASTER_KEY works
heroku logs --tail
```

Then seed (with §1.5 fixed and `ADMIN_EMAIL`/`ADMIN_PASSWORD` set):

```bash
heroku run rails db:seed
heroku run rails runner 'puts Flipper.features.map(&:key).inspect'   # expect the six flags
heroku config:unset ADMIN_PASSWORD
```

Smoke-test the storefront manually before touching DNS: browse `/`, `/coffees`, add to cart,
reach Stripe Checkout in **test mode** first if possible, sign in with Google, and open
`/admin` and `/admin/flipper` as the admin user — `AdminConstraint` reads the Warden session
key directly, so a signed-in non-admin must get a 404 on `/admin/flipper`. Confirm that.

---

## 6. Stripe

1. Register the production webhook endpoint in the Stripe dashboard:
   `https://deathbloomcoffeeroasters.com/webhooks/stripe`
2. Subscribe to the events the app's `Webhooks::StripeController` handles — at minimum
   `checkout.session.completed`.
3. Copy the endpoint's signing secret and set it:
   `heroku config:set STRIPE_WEBHOOK_SECRET=whsec_...`
4. Send a test event from the dashboard and confirm a 200 in `heroku logs`. A webhook that
   silently 4xx's means paid orders never get fulfilled — verify this explicitly, do not assume.
5. Switch from test to live keys only after an end-to-end test-mode purchase succeeds.

Note the route is `post "/webhooks/stripe"` outside any authenticated scope, with CSRF skipped
in favor of Stripe signature verification — confirm the controller actually verifies the
signature against `STRIPE_WEBHOOK_SECRET` before trusting the payload.

---

## 7. Google OAuth

Add the production redirect URI to the Google Cloud console OAuth client:

```
https://deathbloomcoffeeroasters.com/users/auth/google_oauth2/callback
https://www.deathbloomcoffeeroasters.com/users/auth/google_oauth2/callback
```

Add the apex domain to Authorized JavaScript origins. Sign-in silently fails with
`redirect_uri_mismatch` until these are registered — do it before the domain goes live, not
after the first customer reports it.

---

## 8. Custom domain and TLS

```bash
heroku domains:add deathbloomcoffeeroasters.com
heroku domains:add www.deathbloomcoffeeroasters.com
heroku domains          # prints the DNS targets to configure
heroku certs:auto:enable
```

At the DNS registrar:
- `www` → `CNAME` to the Heroku DNS target.
- Apex → `ALIAS`/`ANAME` to the Heroku DNS target (a plain `A` record will not work; if the
  registrar has no ALIAS support, move DNS to one that does — Cloudflare, DNSimple).

Then `heroku certs:auto` until status is `Cert issued`. `config.force_ssl = true` is already
set in `production.rb`, and `assume_ssl = true` is correct for Heroku's terminating proxy —
both verified in the current code, no change needed.

Mailgun also needs its own DNS records (SPF/DKIM on `mg.deathbloomcoffeeroasters.com`) before
mail deliverability is trustworthy. Verify the domain in the Mailgun dashboard and send a real
password-reset to a live inbox — including checking that it does not land in spam.

---

## 9. Execution order

```
[1] Fix blockers §1.1–§1.6 on a feature branch  ← code changes, spec for §1.5 first
[2] bundle update --ruby; docker compose build; bundle exec rspec  (all green)
[3] PR → review → merge to main
[4] Install Heroku CLI, create app + Postgres  (§3)
[5] Set every config var  (§4)  ← before any push
[6] git push heroku main; verify /up, DB, credentials  (§5)
[7] Seed; verify flags; unset ADMIN_PASSWORD  (§5)
[8] Stripe webhook in test mode; end-to-end purchase  (§6)
[9] Google OAuth redirect URIs  (§7)
[10] Domain + ACM + Mailgun DNS  (§8)
[11] Switch Stripe to live keys; re-test one real purchase
[12] Decide §2.1 (job durability) explicitly before announcing the store
```

Steps [1]–[3] are ordinary development work and follow the project's Planner → Engineer →
Reviewer → PR workflow. Steps [4]–[12] require Heroku, Stripe, Google, and registrar
credentials, so they need to be run by the account owner.

---

## 10. Rollback

```bash
heroku releases                 # find the last good version
heroku rollback v<N>            # code only — does NOT undo migrations
```

Migrations are not rolled back by `heroku rollback`. For anything destructive, capture a
backup first:

```bash
heroku pg:backups:capture
heroku pg:backups:download
```

Schedule daily backups before launch: `heroku pg:backups:schedule DATABASE_URL --at '04:00 America/Denver'`.

---

## Appendix — files this plan changes

| File | Change | Why |
|---|---|---|
| `Gemfile` | add `ruby "4.0.6"` | §1.1 |
| `Gemfile.lock` | regenerated `RUBY VERSION` block | §1.1 |
| `.ruby-version` | `4.0.2` → `4.0.6` | §1.1 |
| `Procfile` | remove `css:` watcher line | §1.2 |
| `config/database.yml` | `max_connections` → `pool`; standalone production block | §1.3 |
| `db/seeds.rb` | environment-aware admin seeding | §1.5 |
| `spec/` | seed spec asserting no dev admin in production | §1.5 |
| `.env.example` | add `MAIL_FROM`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`; correct `APP_HOST` domain | §4 |

No changes are required to `config/environments/production.rb` (SSL, logging, mailer,
health-check silencing are all already correct), `config/puma.rb`, or `config/routes.rb`.
