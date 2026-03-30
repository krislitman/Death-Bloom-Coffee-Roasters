FactoryBot.define do
  factory :coffee do
    sequence(:name)  { |n| "#{Faker::Coffee.blend_name} #{n}" }
    sequence(:slug)  { |n| "#{Faker::Internet.slug}-#{n}" }
    origin           { Faker::Coffee.country }
    roast_level      { :medium }
    description      { Faker::Lorem.paragraph }
    price_cents      { 1800 }
    active           { true }
    position         { 0 }

    trait :inactive do
      active { false }
    end

    trait :light do
      roast_level { :light }
    end

    trait :dark do
      roast_level { :dark }
    end

    trait :with_tasting_notes do
      after(:create) do |coffee|
        ["chocolate", "cherry", "caramel"].each do |note|
          tasting_note = TastingNote.find_or_create_by!(name: note)
          coffee.tasting_notes << tasting_note
        end
      end
    end
  end
end
