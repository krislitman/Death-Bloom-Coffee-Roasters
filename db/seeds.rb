# Idempotent — safe to run in any environment at any time.

# ── Feature Flags ─────────────────────────────────────────────────────────────
%i[
  subscriptions
  admin_tools
  announcement_bar
  maintenance_mode
].each do |flag|
  Flipper.add(flag) unless Flipper.exist?(flag)
end

puts "Feature flags seeded: #{Flipper.features.map(&:key).join(', ')}"
