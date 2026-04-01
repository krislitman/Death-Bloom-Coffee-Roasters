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

# ── Admin User ─────────────────────────────────────────────────────────────────
admin = User.find_or_initialize_by(email: "admin@dev.com")
admin.assign_attributes(password: "admindev123", password_confirmation: "admindev123", role: :admin)
admin.save!

puts "Admin user seeded: #{admin.email}"
