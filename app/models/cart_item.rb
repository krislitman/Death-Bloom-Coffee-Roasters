class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :coffee

  validates :quantity, presence: true,
                       numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 10 }
  validates :coffee_id, uniqueness: { scope: :cart_id }

  def total_cents
    coffee.price_cents * quantity
  end
end
