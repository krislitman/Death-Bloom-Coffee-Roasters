ARG RUBY_VERSION=4.0.2
FROM ruby:${RUBY_VERSION}-slim AS base

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      libpq-dev \
      libyaml-dev \
      curl \
      git && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./

# ── Development ──────────────────────────────────────────────────────────────
FROM base AS development

RUN bundle install

COPY . .

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

# ── Production ───────────────────────────────────────────────────────────────
FROM base AS production

ENV RAILS_ENV=production \
    BUNDLE_WITHOUT="development:test"

RUN bundle install --without development test

COPY . .

RUN bundle exec rails assets:precompile

EXPOSE 3000
CMD ["bundle", "exec", "thrust", "bundle", "exec", "puma", "-C", "config/puma.rb"]
