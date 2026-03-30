FactoryBot.define do
  factory :user do
    email            { Faker::Internet.unique.email }
    password         { "Password1!" }
    password_confirmation { "Password1!" }
    confirmed_at     { Time.current }
    role             { :customer }

    trait :admin do
      role { :admin }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
