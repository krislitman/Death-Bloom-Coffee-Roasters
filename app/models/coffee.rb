class Coffee < ApplicationRecord
  has_many :coffee_tasting_notes, dependent: :destroy
  has_many :tasting_notes, through: :coffee_tasting_notes
  has_many :order_items

  enum :roast_level, {
    light:        0,
    medium:       2,
    dark:         4
  }, default: :light

  validates :name,        presence: true
  validates :origin,      presence: true
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  validates :slug,        presence: true, uniqueness: { case_sensitive: false }
  validates :stock_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :generate_slug, if: -> { slug.blank? }

  scope :active,  -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  def self.preload_sold_counts(coffees)
    counts = OrderItem.joins(:order)
                      .where(coffee_id: coffees.map(&:id))
                      .where.not(orders: { status: :cancelled })
                      .group(:coffee_id)
                      .sum(:quantity)

    coffees.each { |coffee| coffee.sold_count = counts.fetch(coffee.id, 0) }
  end

  attr_writer :sold_count

  def sold_count
    @sold_count ||= order_items.joins(:order)
                               .where.not(orders: { status: :cancelled })
                               .sum(:quantity)
  end

  def available_stock
    stock_quantity - sold_count
  end

  def sold_out?
    available_stock <= 0
  end

  def in_stock?
    !sold_out?
  end

  def formatted_price
    "$#{format('%.2f', price_cents / 100.0)}"
  end

  def price
    price_cents && price_cents / 100.0
  end

  def price=(dollars)
    self.price_cents = dollars.blank? ? nil : (BigDecimal(dollars.to_s) * 100).round
  end

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.to_s.parameterize
  end
end
