FactoryBot.define do
  factory :tasting_note do
    sequence(:name) { |n| "#{Faker::Coffee.notes}-#{n}" }
  end
end
