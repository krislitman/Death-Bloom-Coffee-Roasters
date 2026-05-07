FactoryBot.define do
  factory :order do
    association :user
    email       { user&.email || Faker::Internet.email }
    status      { :processing }
    total_cents { 1800 }
    shipping_address_name    { Faker::Name.name }
    shipping_address_line1   { Faker::Address.street_address }
    shipping_address_city    { Faker::Address.city }
    shipping_address_state   { Faker::Address.state_abbr }
    shipping_address_zip     { Faker::Address.zip_code }
    shipping_address_country { "US" }

    trait :guest do
      user  { nil }
      email { Faker::Internet.email }
    end

    trait :with_stripe_session do
      stripe_checkout_session_id { "cs_test_#{SecureRandom.hex(8)}" }
    end
  end

  factory :order_item do
    association :order
    association :coffee
    quantity         { 1 }
    unit_price_cents { coffee.price_cents }
  end
end
