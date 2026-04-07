# Idempotent — safe to run in any environment at any time.

# ── Feature Flags ─────────────────────────────────────────────────────────────
# Flags are added if missing; their enabled/disabled state is never overwritten
# so toggling in the admin UI persists across re-seeds.
%i[
  subscriptions
  admin_tools
  announcement_bar
  maintenance_mode
  newsletter
  google_auth
].each do |flag|
  Flipper.add(flag) unless Flipper.exist?(flag)
end

# newsletter defaults to disabled — Flipper.add without .enable leaves it off.
# Admins toggle it via the Feature Manager; re-seeding never overrides their choice.

puts "Feature flags seeded: #{Flipper.features.map(&:key).join(', ')}"

# ── Admin User ─────────────────────────────────────────────────────────────────
admin = User.find_or_initialize_by(email: "admin@dev.com")
admin.assign_attributes(password: "admindev123", password_confirmation: "admindev123", role: :admin)
admin.save!

puts "Admin user seeded: #{admin.email}"

# ── Tasting Notes ──────────────────────────────────────────────────────────────
tasting_note_names = %w[
  chocolate caramel brown\ sugar cherry citrus jasmine
  blueberry vanilla hazelnut almond peach plum
]

tasting_notes = tasting_note_names.each_with_object({}) do |name, hash|
  hash[name] = TastingNote.find_or_create_by!(name: name)
end

puts "Tasting notes seeded: #{TastingNote.count}"

# ── Coffees ────────────────────────────────────────────────────────────────────
coffees_data = [
  {
    name: "Midnight Sun",
    origin: "Ethiopia",
    roast_level: :medium,
    description: "A well-balanced medium roast with notes of chocolate and caramel.",
    price_cents: 1800,
    tasting_notes: %w[chocolate caramel brown\ sugar]
  },
  {
    name: "Aurora Washed",
    origin: "Kenya",
    roast_level: :light,
    description: "A vibrant light roast bursting with citrus brightness and delicate floral notes.",
    price_cents: 1950,
    tasting_notes: %w[citrus jasmine blueberry]
  },
  {
    name: "Dark Hollow",
    origin: "Sumatra",
    roast_level: :dark,
    description: "A bold, full-bodied dark roast with deep earthy warmth and a long smoky finish.",
    price_cents: 1700,
    tasting_notes: %w[chocolate vanilla hazelnut]
  }
]

coffees_data.each_with_index do |attrs, index|
  notes = attrs.delete(:tasting_notes)
  coffee = Coffee.find_or_create_by!(name: attrs[:name]) do |c|
    c.slug        = attrs[:name].parameterize
    c.origin      = attrs[:origin]
    c.roast_level = attrs[:roast_level]
    c.description = attrs[:description]
    c.price_cents = attrs[:price_cents]
    c.active      = true
    c.position    = index
  end

  notes.each do |note_name|
    note = tasting_notes[note_name]
    coffee.tasting_notes << note unless coffee.tasting_notes.include?(note)
  end
end

puts "Coffees seeded: #{Coffee.count}"
