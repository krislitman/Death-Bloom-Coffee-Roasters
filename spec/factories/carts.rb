FactoryBot.define do
  factory :cart do
    user { nil }
    sequence(:session_token) { |n| "guest_token_#{n}" }

    trait :for_user do
      association :user
      session_token { nil }
    end

    trait :guest do
      user { nil }
    end
  end

  factory :cart_item do
    association :cart
    association :coffee
    quantity { 1 }
  end
end
