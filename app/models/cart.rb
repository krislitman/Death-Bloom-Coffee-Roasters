class Cart < ApplicationRecord
  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :coffees, through: :cart_items

  validates :session_token, presence: true, if: -> { user_id.nil? }

  def self.current_for(user: nil, session_token: nil)
    if user
      find_or_create_by!(user: user)
    else
      find_or_create_by!(session_token: session_token)
    end
  end

  def merge_guest_cart(guest_cart)
    return if guest_cart.nil?

    guest_cart.cart_items.each do |guest_item|
      existing = cart_items.find_by(coffee_id: guest_item.coffee_id)
      if existing
        new_quantity = [ existing.quantity + guest_item.quantity, 10 ].min
        existing.update!(quantity: new_quantity)
      else
        cart_items.create!(coffee_id: guest_item.coffee_id, quantity: [ guest_item.quantity, 10 ].min)
      end
    end

    guest_cart.destroy
  end

  def total_cents
    cart_items.sum { |item| item.total_cents }
  end

  def item_count
    cart_items.sum(:quantity)
  end
end
