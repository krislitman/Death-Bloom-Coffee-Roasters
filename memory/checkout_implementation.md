---
name: Checkout Implementation
description: Stripe Checkout + Shippo live rates + PendingCheckout pattern — architecture decisions and known issues
type: project
---

Checkout implemented using Stripe hosted Checkout page + Shippo for live shipping rates.

**Key architectural decisions:**
- `PendingCheckout` model (with `token` UUID) stores frozen cart snapshot + address + selected rate. Only the token goes into Stripe session metadata — avoids the metadata-only fragility problem.
- `OrderFulfillmentService` creates Order + OrderItems inside a single DB transaction on `checkout.session.completed` webhook. Idempotent via `stripe_checkout_session_id` unique index.
- Guest Stripe Customers are created ephemerally for tax address purposes — not stored in `PaymentProfile` (which requires a user). They accumulate in Stripe; may want a cleanup job.
- Shippo `ORIGIN` constant is frozen; must `.dup` before passing to Shippo gem (which calls `stringify_keys!` in-place).
- Shipping rate IDs are stored in `session[:shippo_rates]` after the GET /checkout/rates call — submitted `rate_id` is validated server-side against this list (prevents rate tampering).
- `CheckoutsController#rates` uses `render partial:` directly (Turbo Frame handles the targeting via `data-turbo-frame="shipping-rates"` on the address form).

**Tax:** `automatic_tax: { enabled: true }` with Stripe Customer pre-populated with shipping address. Tax code `txcd_10000000` (food for home consumption) — needs legal review.

**Parcel weight:** Default 16 oz per bag. No `weight_oz` field on Coffee model.

**Pre-existing failing spec:** `spec/models/coffee_spec.rb:18` — tests for `medium_light`/`medium_dark` enum values that were removed from `Coffee` model before this session. Unrelated to checkout.

**System specs:** Chrome not in Docker image — Turbo Frame interaction tests are marked pending. Non-JS paths covered in `spec/requests/checkouts_spec.rb`.

**Why:** Guest checkout required order creation without a user; Stripe Tax required a Customer with a pre-collected address; PendingCheckout prevents cart mutation between Stripe redirect and webhook delivery.

**How to apply:** When adding future payment features (subscriptions, refunds), follow the same PendingCheckout → webhook → fulfillment pattern. Do not create orders synchronously on the success redirect.
