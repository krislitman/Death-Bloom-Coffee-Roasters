# Placeholder catalog for local development and test only — never seeded in production.
[
  {
    name:          "Midnight Sun",
    origin:        "Ethiopia",
    roast_level:   :medium,
    description:   "A well-balanced medium roast with notes of chocolate and caramel.",
    price_cents:   1800,
    position:      3,
    stock_quantity: 24,
    tasting_notes: [ "chocolate", "caramel", "brown sugar" ]
  },
  {
    name:          "Aurora Washed",
    origin:        "Kenya",
    roast_level:   :light,
    description:   "A vibrant light roast bursting with citrus brightness and delicate floral notes.",
    price_cents:   1950,
    position:      4,
    stock_quantity: 24,
    tasting_notes: [ "citrus", "jasmine", "blueberry" ]
  },
  {
    name:          "Dark Hollow",
    origin:        "Sumatra",
    roast_level:   :dark,
    description:   "A bold, full-bodied dark roast with deep earthy warmth and a long smoky finish.",
    price_cents:   1700,
    position:      5,
    stock_quantity: 24,
    tasting_notes: [ "chocolate", "vanilla", "hazelnut" ]
  }
].each { |attrs| seed_coffee(attrs) }

puts "Demo coffees seeded: #{Coffee.count}"
