<p align="center">
  <img src="app/assets/images/logo/1. DBCR - logo - w - final files_Artboard 4 - wordmark only.png" alt="Death Bloom Coffee Roasters" width="420" />
</p>

<p align="center">
  A specialty coffee e-commerce platform built with Ruby on Rails, deployed on Heroku, and containerized with Docker.
</p>

---

## Overview

Death Bloom Coffee Roasters is a full-stack Rails application for a specialty coffee roasting business based in Denver, CO. It handles the full customer experience — browsing and purchasing single-origin and blended roasts, account management, order tracking, and shipping label generation.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Ruby on Rails 8.1.3 |
| Ruby | 4.0.2 |
| Frontend | ERB, Hotwire (Turbo + Stimulus), Dart Sass |
| Database | PostgreSQL 16 |
| Authentication | Devise |
| Payments | Stripe |
| Shipping | EasyPost |
| Email | Mailgun (production), Letter Opener (development) |
| Feature Flags | Flipper |
| Deployment | Heroku |
| Containerization | Docker + Docker Compose |
| Testing | RSpec, FactoryBot, Capybara, VCR |

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                     Browser                         │
│         Hotwire (Turbo + Stimulus)                  │
└──────────────────┬──────────────────────────────────┘
                   │ HTTP
┌──────────────────▼──────────────────────────────────┐
│              Rails 8.1.3 (Puma + Thruster)          │
│                                                     │
│  Controllers → Models → Views (ERB)                 │
│  ├── Devise (auth)                                  │
│  ├── Flipper (feature flags)                        │
│  ├── Stripe (payments)                              │
│  ├── EasyPost (shipping labels)                     │
│  └── Pagy (pagination)                              │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│              PostgreSQL 16                          │
└─────────────────────────────────────────────────────┘
```

Docker Compose runs three services locally:

- **`db`** — PostgreSQL 16 (Alpine)
- **`web`** — Rails application server on port 3000
- **`css`** — Dart Sass watcher for live stylesheet compilation

In production, Heroku runs the `web` process (Puma wrapped by Thruster for HTTP/2 and asset serving) and executes `rails db:migrate` as a release phase command.

---

## Local Development Setup

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- [Git](https://git-scm.com/)

That's it — Ruby, PostgreSQL, and all dependencies run inside Docker.

---

### Step 1 — Clone the repository

```bash
git clone <repository-url>
cd DeathBloom
```

---

### Step 2 — Copy the environment file

```bash
cp .env.example .env
```

Open `.env` and fill in the required values:

| Variable | Description |
|---|---|
| `POSTGRES_PASSWORD` | Any password you choose for local Postgres |
| `SECRET_KEY_BASE` | Run `openssl rand -hex 64` to generate |
| `DEVISE_SECRET_KEY` | Run `openssl rand -hex 64` to generate |
| `STRIPE_PUBLISHABLE_KEY` | From your [Stripe dashboard](https://dashboard.stripe.com) (test key) |
| `STRIPE_SECRET_KEY` | From your Stripe dashboard (test key) |
| `STRIPE_WEBHOOK_SECRET` | From your Stripe webhook endpoint config |
| `EASYPOST_API_KEY` | From your [EasyPost dashboard](https://www.easypost.com) (test key) |

Mailgun and other production-only variables can be left as placeholders for local development — email is handled by Letter Opener (opens in browser) in development mode.

---

### Step 3 — Build the Docker images

```bash
docker compose build
```

---

### Step 4 — Create and migrate the database

```bash
docker compose run --rm web rails db:create db:migrate
```

---

### Step 5 — (Optional) Seed the database

```bash
docker compose run --rm web rails db:seed
```

---

### Step 6 — Start the application

```bash
docker compose up
```

This starts all three services (`db`, `web`, `css`) concurrently. The app will be available at:

```
http://localhost:3000
```

To stop: `Ctrl+C`, then `docker compose down`.

---

### Step 7 — Verify everything is working

```bash
# Check running containers
docker compose ps

# Tail logs
docker compose logs -f web

# Open a Rails console
docker compose run --rm web rails console
```

---

## Running Tests

```bash
# Full test suite
docker compose run --rm web bundle exec rspec

# Model specs only
docker compose run --rm web bundle exec rspec spec/models

# System/integration specs (requires headless Chrome — included in Docker image)
docker compose run --rm web bundle exec rspec spec/system

# Readable documentation output
docker compose run --rm web bundle exec rspec --format documentation
```

---

## Flipper Feature Flags

New features are gated behind Flipper flags. To enable a flag locally:

```bash
docker compose run --rm web rails runner "Flipper.enable(:your_flag_name)"
```

The Flipper UI is available at `/flipper` when running locally (protected by admin auth in production).

---

## Project Structure

```
.
├── app/
│   ├── assets/
│   │   └── images/
│   │       ├── logo/          # Brand logo files (PNG, multiple variants)
│   │       └── products/      # Product photography
│   ├── controllers/
│   │   ├── admin/
│   │   └── webhooks/          # Stripe webhook handler
│   ├── javascript/
│   │   └── controllers/       # Stimulus controllers
│   ├── models/
│   │   └── concerns/
│   └── views/
├── config/
│   ├── initializers/          # Stripe, Flipper, etc.
│   └── routes.rb
├── db/
│   └── migrate/
├── spec/                      # RSpec — no test/ directory
│   ├── factories/             # FactoryBot factories
│   ├── models/
│   ├── requests/
│   ├── support/               # Shared helpers, DatabaseCleaner config
│   └── system/                # Capybara end-to-end specs
├── docker-compose.yml
├── Dockerfile
├── Procfile                   # Heroku process definitions
└── .env.example               # Committed template — never commit .env
```

---

## Heroku Deployment

```bash
# Deploy
git push heroku main

# Run pending migrations (handled automatically via release phase)
heroku run rails db:migrate

# Set an environment variable
heroku config:set STRIPE_SECRET_KEY=sk_live_...

# Tail logs
heroku logs --tail
```

All secrets must be set as Heroku config vars — never commit `.env` or credentials to the repository.

---

## Contributing

This project follows a Test-First (TDD) workflow. Before submitting changes:

1. Write the spec first and confirm it fails
2. Implement the minimum code to make it pass
3. Refactor while keeping tests green
4. Run the full suite (`bundle exec rspec`) and confirm it passes

Branch naming: `feature/<description>` or `fix/<description>`. All PRs target `main`.
