# Death Bloom Coffee Roasters — CLAUDE.md

## Project Overview

Ruby on Rails application for **Death Bloom Coffee Roasters**, a specialty coffee roasting business based in Denver, CO. Deployed on Heroku with a custom domain, Dockerized for local development and consistency.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Ruby on Rails (ERB), Hotwire (Turbo + Stimulus) |
| Backend | Ruby on Rails |
| Database | PostgreSQL |
| Authentication | Devise |
| Feature Flags | Flipper |
| Deployment | Heroku (custom domain) |
| Containerization | Docker + Docker Compose |
| Testing | RSpec (Better Specs), FactoryBot, Capybara |

---

## Development Philosophy

### Test-First (TDD)
Always write tests before implementing code. No feature or bug fix ships without a corresponding spec. The Red-Green-Refactor cycle is mandatory.

### Better Specs Guidelines
Follow [Better Specs](https://www.betterspecs.org/) strictly:
- Use `describe` for methods, `context` for conditions, `it` for behavior
- One expectation per example where practical
- Use `let` and `let!` over instance variables in `before` blocks
- Avoid `subject` unless it is truly the subject under test
- Use `described_class` instead of the class name inside `describe` blocks
- Keep examples short and focused — if it needs a paragraph of setup, extract a factory or helper
- Prefer `expect` syntax over `should`
- Shared examples only when the duplication is real and not incidental
- Name your examples so that `rspec --format documentation` reads like a spec document

### Code Quality
- Prefer small, focused methods and single-responsibility classes
- Rails conventions over custom abstractions — reach for the framework first
- No speculative abstractions or premature generalization
- Hotwire-first for interactivity before reaching for custom JavaScript
- Stimulus only for behavior that Turbo cannot handle

---

## Agent Workflow

This project uses four specialized Claude agents with clearly separated concerns. Always follow this sequence for any non-trivial change:

### 1. Planner Agent (`/agent:planner`)
**Responsibility:** Design the implementation strategy before any code is written.

Outputs:
- Step-by-step implementation plan
- Files that will be created or modified
- Database schema changes (migrations needed)
- Test scenarios that must pass
- Any architectural trade-offs or risks

Do not write code. Research the codebase, ask clarifying questions, and produce a plan document. The plan must be approved before the Engineer agent begins.

### 2. Engineer Agent (`/agent:engineer`)
**Responsibility:** Execute the approved plan — write tests first, then implementation.

Rules:
- Write the spec file(s) first and confirm they fail (Red)
- Implement the minimum code to make them pass (Green)
- Refactor while keeping tests green
- Do not expand scope beyond the approved plan
- Do not add features, extra error handling, or comments not required by the plan

### 3. Reviewer Agent (`/agent:reviewer`)
**Responsibility:** Review all changes produced by the Engineer agent.

Checks:
- Tests were written before implementation (verify by reading commit order or diff order)
- Better Specs compliance
- No N+1 queries (use `bullet` gem output if available)
- No security issues (mass assignment, SQL injection, XSS, CSRF gaps)
- Hotwire/Stimulus used appropriately
- Devise and Flipper integrations are correct
- Docker and environment config is not leaking secrets
- All Heroku-specific concerns (ENV vars, Procfile, release phase) are addressed

Outputs a structured review: **Approved**, **Approved with Comments**, or **Needs Changes** with specific line-level feedback.

### 4. PR Agent (`/agent:pr`)
**Responsibility:** Take reviewed, approved changes and open a pull request using the GitHub CLI (`gh`).

Steps:
1. `git status` + `git diff` + `git log` to understand the full change set
2. Stage specific files (never `git add -A` without explicit user approval)
3. Commit with a meaningful message following the project commit style
4. Push the branch
5. Open the PR with `gh pr create`, including a summary and test plan in the body
6. Return the PR URL

---

## Design Direction

### Aesthetic
Clean, dark, minimal. The page should feel alive as users scroll — sections shift in tone, content reveals progressively, and typography does the heavy lifting. No clutter. Let negative space breathe. Photography and product imagery are the primary visual elements.

### Scroll Behavior
Sections should change character as the user scrolls — shifting from a dark hero into lighter content blocks and back. Achieve this with:
- `IntersectionObserver` via a Stimulus controller that toggles CSS classes on the `<body>` or section wrappers
- CSS custom property swaps (`--bg-color`, `--text-color`) to transition between dark and light zones
- Prefer CSS transitions over JavaScript animations — `opacity`, `transform: translateY`, and `transition` only
- No heavy animation libraries (no GSAP, no AOS dependency) — keep the JS bundle lean

### Color System
Define all colors as CSS custom properties on `:root`. Dark zones flip these via a scoped class (e.g. `.zone--dark`):

```css
:root {
  --color-bg: #0a0a0a;
  --color-bg-surface: #141414;
  --color-text-primary: #f0ece4;
  --color-text-muted: #7a7670;
  --color-accent: /* TBD from brand assets */;
  --color-border: #2a2a2a;
}

.zone--light {
  --color-bg: #f5f2ed;
  --color-bg-surface: #ffffff;
  --color-text-primary: #0a0a0a;
  --color-text-muted: #5a5652;
  --color-border: #e0ddd8;
}
```

### Typography
- All sizing via CSS custom properties (`--font-size-xs` through `--font-size-display`)
- Large, confident display headings — geometric or humanist sans-serif
- Monospace or tabular figures for weights, dates, and tasting note metadata (referencing Sweet Bloom's `LM Mono` approach)
- Uppercase with letter-spacing for section labels and navigation
- Establish a modular scale: `--font-size-base: 1rem`, scale factor ~1.25

### Layout
- Max container: `1440px`, centered
- CSS Grid for all page-level layout; Flexbox for component internals
- Full-width hero sections; constrained content blocks
- Generous vertical rhythm — sections breathe, don't stack tightly
- 4-column product grid on desktop → 2-column tablet → 1-column mobile

### Stimulus Controllers (planned)
| Controller | Purpose |
|---|---|
| `scroll-zone` | Toggles `.zone--light` / `.zone--dark` on sections via IntersectionObserver |
| `dropdown` | Accessible nav dropdowns with ARIA attributes |
| `announcement-bar` | Dismissible top bar with localStorage persistence |
| `dialog` | Modal/popup with cookie frequency cap and focus trap |
| `cart-drawer` | Slide-in cart panel, AJAX quantity updates |
| `search` | Debounced predictive search via Turbo Stream |
| `image-reveal` | Staggered `opacity` + `translateY` reveal on scroll enter |

---

## Design References

Five established specialty coffee roasters studied for design patterns. Do not copy — draw inspiration and synthesize into Death Bloom's own identity.

### Thump Coffee — thumpcoffee.com
- Full-width atmospheric photography as the primary storytelling tool
- `backdrop-filter: blur()` with transparency for text overlays on images
- SVG curve/underline accents on headings — a small detail with high brand impact
- Generous whitespace; content is deliberately paced, not dense
- Sticky nav with scroll-back behavior; mobile hamburger with nested back-button menus
- **Takeaway:** pacing and photography-first layout

### Sweet Bloom Coffee — sweetbloomcoffee.com
- Scandinavian minimalism: black on white, vivid seasonal accent colors for featured items
- Monospace body font (`LM Mono`) — creates an editorial, considered feel
- Geometric sans-serif headings (Futura) at very large sizes (`10.8rem` display)
- Precise spacing tokens (`3.2rem` column gutters, `7.2rem` row gutters)
- Border-top `1px` dividers between sections — structure without decoration
- **Takeaway:** typography scale, monospace detail, strict spacing system

### Corvus Coffee — corvuscoffee.com
- Darkest palette of the five: `#1b1f23` header/footer, `#080808` heroes, warm cream `#dddbca` text
- True parallax on hero sections (`universalParallax`, speed 4–10)
- Scroll-triggered CSS animation classes (`.animate_right`, `.animate_left`, `.animate_up`)
- Hover reveals secondary product image — expected behavior for product cards
- Newsletter popup: 12-second delay, 365-day cookie — do not annoy, but capture
- **Takeaway:** dark palette execution, scroll animation approach, product card hover behavior

### Black & White Roasters — blackwhiteroasters.com
- Strictest grid discipline: `1480px` max, `20px` gutters, 4–6 col product grid
- AOS (Animate On Scroll) for reveal — replace with a lightweight Stimulus `IntersectionObserver` controller
- Three-zone sticky header: logo left, nav center, icons right
- Custom web components (`<product-card>`, `<add-to-cart>`) — map to Rails partials + Stimulus
- Sale/New/Sold Out label badges overlaid on product images — implement as Rails view helpers
- **Takeaway:** grid precision, header layout, product badge system

### Onyx Coffee Lab — onyxcoffeelab.com
- Most editorial — warm cream/off-white (`#fbfaf3`, `#eee9df`) with near-black text; photography carries warmth
- SVG path draw-in animation on load for logo/signature — consider for Death Bloom logo reveal
- Sequential staggered opacity cascade for logo/partner grids
- Scroll-threshold header style change at 30px (`scrollY > 30` → `.force-dark` class)
- Tasting note tags as scannable metadata on product cards ("Orange | Black Tea | Raisin | Juicy")
- Origin storytelling sections with producer spotlights — a content pattern worth adopting
- **Takeaway:** tasting note UI pattern, header scroll threshold, origin storytelling layout

---

## Assets

### Brand Assets
All brand assets live in `app/assets/images/brand/`. Never hotlink external images. All assets must be committed to the repo (use Git LFS for files over 5MB).

```
app/assets/images/
├── brand/
│   ├── logo.svg              # Primary logo (SVG preferred)
│   ├── logo-dark.svg         # Dark background variant
│   ├── logo-light.svg        # Light background variant
│   ├── wordmark.svg          # Text-only wordmark
│   └── favicon.png
├── products/                 # Coffee bag photography
│   └── <roast-slug>/
│       ├── bag-front.jpg
│       ├── bag-back.jpg
│       └── lifestyle.jpg
└── brand/
    └── og-image.jpg          # 1200×630 Open Graph default
```

### Image Guidelines
- SVG for all logos and icons — never rasterize what can be vector
- Product photography: minimum 2000px on long edge, exported as progressive JPEG at 85% quality
- Use Rails `image_tag` with explicit `width` and `height` attributes to prevent layout shift (CLS)
- Lazy-load all below-the-fold images: `image_tag src, loading: "lazy"`
- `app/assets/images` for static brand assets; Active Storage for user-uploaded or CMS-managed content

### Open Graph / Social
- Default OG image at `app/assets/images/og-image.jpg` (1200×630)
- Per-product OG images using the product's primary photo
- Set via a `content_for :meta_tags` pattern in the layout

---

## Repository Structure (expected after scaffold)

```
.
├── app/
│   ├── assets/
│   ├── controllers/
│   ├── javascript/          # Stimulus controllers live here
│   ├── models/
│   ├── views/
│   └── ...
├── config/
│   ├── initializers/
│   │   └── flipper.rb
│   └── ...
├── db/
│   └── migrate/
├── spec/                    # All tests — no test/ directory
│   ├── factories/
│   ├── models/
│   ├── requests/
│   ├── system/              # Capybara/system specs
│   └── support/
├── docker-compose.yml
├── Dockerfile
├── Procfile                 # Heroku process definitions
├── .env.example             # Committed template — never commit .env
└── CLAUDE.md
```

---

## Environment & Secrets

- **Never commit `.env`** — only `.env.example` with placeholder values
- All secrets and credentials must be set as Heroku config vars in production
- Docker Compose reads from `.env` locally — copy `.env.example` to `.env` to get started
- Rails credentials (`config/credentials.yml.enc`) used for secrets that must be version-controlled (e.g., Devise secret key)

---

## Docker

Local development runs entirely in Docker Compose:

```bash
docker compose up          # Start all services
docker compose run web rails db:create db:migrate
docker compose run web rails db:seed
docker compose run web bundle exec rspec
```

The `web` service runs the Rails app; `db` runs PostgreSQL. Never connect to a remote database during local development.

---

## Testing

```bash
bundle exec rspec                        # Full suite
bundle exec rspec spec/models            # Model specs only
bundle exec rspec spec/system            # System/integration specs
bundle exec rspec --format documentation # Readable output
```

- Use `FactoryBot` for all test data — no raw `Model.create` in specs
- Use `DatabaseCleaner` with transaction strategy (truncation for system specs)
- Capybara + a headless Chrome driver for system specs
- Feature flag specs must test both enabled and disabled states via `Flipper`

---

## Heroku Deployment

```bash
git push heroku main           # Deploy
heroku run rails db:migrate    # Run pending migrations
heroku logs --tail             # Tail logs
heroku config:set KEY=value    # Set environment variable
```

- Release phase command in `Procfile`: `release: bundle exec rails db:migrate`
- Health check endpoint should exist at `/up` (Rails default)

---

## Flipper (Feature Flags)

- All new features should be gated behind a Flipper flag during development
- Enable flags per-actor (user), percentage, or globally
- Remove flags once a feature is fully rolled out and stable
- Flipper UI should be mounted and protected behind admin authentication in production

---

## Commit Style

```
type: short imperative description (50 chars max)

Optional body explaining why, not what. Wrap at 72 chars.
```

Types: `feat`, `fix`, `test`, `refactor`, `chore`, `docs`, `style`

Example:
```
feat: add product listing page with Turbo pagination

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

---

## Branch Strategy

- `main` — production-ready, deployed to Heroku
- `feature/<description>` — all new work
- `fix/<description>` — bug fixes
- PRs require review before merging to `main`
- Squash merge to keep history clean

---

## Key Gems (expected)

```ruby
# Gemfile highlights
gem "devise"
gem "flipper"
gem "flipper-active_record"
gem "flipper-ui"

group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "database_cleaner-active_record"
  gem "shoulda-matchers"
  gem "bullet"
end
```
