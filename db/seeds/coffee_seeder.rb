def seed_coffee(attrs)
  notes = attrs.fetch(:tasting_notes)

  coffee = Coffee.find_or_create_by!(name: attrs[:name]) do |c|
    c.slug        = attrs[:name].parameterize
    c.origin      = attrs[:origin]
    c.roast_level = attrs[:roast_level]
    c.processing  = attrs[:processing]
    c.description = attrs[:description]
    c.price_cents = attrs[:price_cents]
    c.active         = true
    c.position       = attrs[:position]
    c.stock_quantity = attrs.fetch(:stock_quantity, 0)
  end

  notes.each do |note_name|
    note = TastingNote.find_or_create_by!(name: note_name)
    coffee.tasting_notes << note unless coffee.tasting_notes.include?(note)
  end

  coffee
end
