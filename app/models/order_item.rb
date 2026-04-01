class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :coffee

  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price_cents, numericality: { greater_than: 0 }

  def total_cents
    quantity * unit_price_cents
  end
end
