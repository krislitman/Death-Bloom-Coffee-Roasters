class TastingNote < ApplicationRecord
  has_many :coffee_tasting_notes, dependent: :destroy
  has_many :coffees, through: :coffee_tasting_notes

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
