# Memory Index — Death Bloom Coffee Roasters

- [Project Overview](project_overview.md) — Tech stack, aesthetic, design references, Heroku/Docker deployment
- [Agent Workflow](project_workflow.md) — Four-agent pipeline: Planner → Engineer → Reviewer → PR (mandatory sequence)
- [Architecture Decisions](project_architecture_decisions.md) — Confirmed schema/integration choices: Billable concern, tasting_note_tags table, EasyPost, Mailgun, Propshaft, static assets
- [Checkout Implementation](checkout_implementation.md) — Stripe Checkout + Shippo rates + PendingCheckout pattern, pre-existing coffee_spec enum failure
