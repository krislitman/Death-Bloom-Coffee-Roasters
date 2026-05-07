FactoryBot.define do
  factory :pending_checkout do
    association :cart
    email                    { Faker::Internet.email }
    shipping_address_name    { Faker::Name.name }
    shipping_address_line1   { Faker::Address.street_address }
    shipping_address_line2   { nil }
    shipping_address_city    { Faker::Address.city }
    shipping_address_state   { Faker::Address.state_abbr }
    shipping_address_zip     { Faker::Address.zip_code }
    shipping_address_country { "US" }
    shippo_rate_id           { "rate_#{SecureRandom.hex(8)}" }
    shippo_rate_amount_cents { 799 }
    shippo_rate_carrier      { "USPS" }
    shippo_rate_service      { "Priority Mail" }
  end
end
