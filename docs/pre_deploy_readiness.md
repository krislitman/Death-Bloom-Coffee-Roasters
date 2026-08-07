# Pre-Deploy Readiness — Purchase Journey

Findings from tracing the end-to-end shopper flow: **sign up → log in → select a
coffee → purchase → order number → track**. Produced alongside
`spec/requests/purchase_journey_spec.rb`, which exercises the whole chain
(the Stripe-hosted payment page is stubbed; fulfillment is driven by replaying
the `checkout.session.completed` webhook, exactly as Stripe would).

Severity key: **BLOCKER** (breaks the flow or loses money/data),
**HIGH** (real risk, ship with mitigation), **MEDIUM** (address soon after launch).

---

## Fixed in this branch

| # | Was | Now |
|---|-----|-----|
| F1 | `My Orders` (`/orders`) crashed — `orders/index.html.erb` called `datagrid_table_for`, which does not exist in datagrid 2.0.9. Any signed-in user viewing order history got a 500. | Rendered as a plain table over `@grid.assets`, matching the hand-rolled table style on `orders/show`. |
| F2 | A dropped or delayed Stripe webhook meant the shopper saw "Order confirmed" but **no order row existed** — a silently lost order. The success page only echoed the raw session id. | `/checkout/success` retrieves the session and fulfills idempotently (guarded on `payment_status == "paid"`), then shows the real order number and a track link. |
| F3 | Guest orders were untraceable — `/orders` is auth-only and keyed to `current_user`, so a guest who checked out could never see their order. | Public order lookup at `/orders/lookup` (order number + email), linked from the footer as "Track Order". Wrong email does not reveal order details. |
| F4 | "Tracking" existed only as a `status` word; no shipment fields. | Added `carrier`, `tracking_number`, `shipped_at`, `delivered_at` to `orders`; `Order#tracking_url` builds USPS/UPS/FedEx links; surfaced on the order detail page when present. |

> Note on F4: the **columns and display** exist, but nothing **populates** them yet
> — see B1 (no admin fulfillment UI) and B2 (no EasyPost). Tracking data will not
> appear until one of those is built.

---

## Remaining holes

### BLOCKER

- **B1 — Admin namespace is partially implemented.** `admin/orders` fulfillment UI
  now exists (index/show/update: set status + carrier + tracking number, auto-stamps
  `shipped_at`/`delivered_at`), so orders can be fulfilled and tracked end to end.
  Still missing: `admin/users`, `admin/coffees`, and `admin/audit_logs` controllers —
  those routes still 500. No admin UI to add or edit coffees means the catalog is
  seed/console-managed for now. Implement or remove those three route sets before launch.

- **B2 — No shipping integration.** The architecture names EasyPost, but nothing is
  wired. Combined with B1, an order can be paid but never fulfilled or tracked from
  within the app. Decide launch scope: manual fulfillment (needs B1 admin UI) vs.
  EasyPost.

- **B3 — No inventory / stock control.** Nothing prevents overselling a coffee.
  A sold-out roast can still be added to cart and purchased.

### HIGH

- **H1 — Fulfillment trusts cart state at webhook time.** `OrderFulfillmentService`
  copies price/quantity straight from the cart with no re-validation against the
  coffee's current `active`/`price_cents`. If a coffee is deactivated or repriced
  between add-to-cart and payment, the order still fulfills at cart-time values.

- **H2 — Zero-line-item orders on missing cart.** When the cart is gone at webhook
  time (`fulfill_without_cart`), an order is recorded with **no line items** (logged
  only). The customer paid; the order shows nothing purchased. Needs reconciliation
  from Stripe line items or an alert.

- **H3 — `allow_browser versions: :modern`** on `ApplicationController` returns 406
  to older browsers, including on the return trip from Stripe Checkout. Confirm this
  is acceptable or relax it for the checkout/return paths.

- **H4 — Silent email failures.** `OrderMailer.confirmation` is `deliver_later` via
  Mailgun. If `MAILGUN_API_KEY` / domain / `SUPPORT_EMAIL` are unset or wrong in
  prod, confirmations vanish with no surfaced error. Verify config and add job
  failure monitoring.

### MEDIUM

- **M1 — `Coffee#roast_level` enum drift (pre-existing failing spec).**
  `spec/models/coffee_spec.rb` expects five values
  (`light, medium_light, medium, medium_dark, dark`); the model defines only three
  (`light: 0, medium: 2, dark: 4`). One suite failure today. Reconcile model and
  spec (and any roast filtering UI that assumes five).

- **M2 — Order lookup enumeration.** `/orders/lookup` requires a matching email, but
  there is no rate limiting (no `rack-attack`). Add throttling to blunt guessing.

- **M3 — Guest→user order linkage is email-only.** Orders link via
  `User.find_by(email:)`. A logged-in shopper who changes the email on Stripe's page
  gets an order not linked to their account (mitigated: `customer_email` is prefilled
  for signed-in users).

- **M4 — Devise `:confirmable` is off** (columns exist, module not included). Signup
  logs in immediately with no email verification. Fine for launch, but means no
  proof-of-email; revisit if abuse appears.

---

## Deploy checklist (Heroku)

- **Config vars:** `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `APP_HOST`
  (custom domain, no scheme), `MAILGUN_API_KEY` + Mailgun domain, `SUPPORT_EMAIL`,
  `POSTGRES_*`/`DATABASE_URL`, Google OAuth creds if `google_auth` flag is on.
- **Stripe dashboard:** register the webhook endpoint → `https://<APP_HOST>/webhooks/stripe`
  for `checkout.session.completed`; confirm the signing secret matches
  `STRIPE_WEBHOOK_SECRET`.
- **Migrations:** `Procfile` release phase runs `db:migrate` — includes the new
  `AddTrackingToOrders`. Confirm it runs clean on Heroku Postgres.
- **Assets:** both `tailwindcss:build` and `dartsass:build` must run at deploy;
  `stylesheet_link_tag "tailwind"` fails hard if `tailwind.css` is missing (this
  bit the test env). Verify `assets:precompile` produces both builds.
- **Health check:** `/up` exists (Rails default) — wire it to Heroku/monitoring.
- **Smoke test in staging:** the one thing specs can't cover is Stripe's hosted page
  itself. Run a real test-mode purchase end to end and confirm the webhook creates
  the order and the confirmation email arrives.
