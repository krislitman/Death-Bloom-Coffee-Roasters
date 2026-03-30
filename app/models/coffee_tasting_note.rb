class CoffeeTastingNote < ApplicationRecord
  belongs_to :coffee
  belongs_to :tasting_note
end
