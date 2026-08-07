[
  "chocolate", "caramel", "brown sugar", "cherry", "citrus", "jasmine",
  "blueberry", "vanilla", "hazelnut", "almond", "peach", "plum",
  "stone fruit", "honey", "floral brightness"
].each { |name| TastingNote.find_or_create_by!(name: name) }

puts "Tasting notes seeded: #{TastingNote.count}"
