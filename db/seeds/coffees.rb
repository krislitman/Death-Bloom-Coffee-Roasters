edwin_norena = {
  origin:        "Colombia",
  processing:    "Carbonic Honey, Peach Co-ferment",
  description:   "A 12 oz Colombian lot named for its cultivator, Edwin Norena.",
  price_cents:   1999,
  tasting_notes: [ "stone fruit", "honey", "floral brightness" ]
}

[
  { name: "Edwin Norena — Light Roast",  roast_level: :light,  position: 0 },
  { name: "Edwin Norena — Medium Roast", roast_level: :medium, position: 1 },
  { name: "Edwin Norena — Dark Roast",   roast_level: :dark,   position: 2 }
].each { |attrs| seed_coffee(edwin_norena.merge(attrs)) }

puts "Coffees seeded: #{Coffee.count}"
