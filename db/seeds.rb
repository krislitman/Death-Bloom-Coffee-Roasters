# Idempotent — safe to run in any environment at any time.

seed_files = %w[coffee_seeder feature_flags tasting_notes coffees admin]
seed_files << "demo_coffees" unless Rails.env.production?

seed_files.each { |file| load Rails.root.join("db", "seeds", "#{file}.rb") }
