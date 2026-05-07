class Coffee < ApplicationRecord
  has_many :coffee_tasting_notes, dependent: :destroy
  has_many :tasting_notes, through: :coffee_tasting_notes

  enum :roast_level, {
    light:        0,
    medium:       2,
    dark:         4
  }, default: :light

  validates :name,        presence: true
  validates :origin,      presence: true
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  validates :slug,        presence: true, uniqueness: { case_sensitive: false }

  before_validation :generate_slug, if: -> { slug.blank? }

  scope :active,  -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  def formatted_price
    "$#{format('%.2f', price_cents / 100.0)}"
  end

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.to_s.parameterize
  end
end
