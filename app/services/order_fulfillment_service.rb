class OrderFulfillmentService
  def initialize(checkout_session:)
    @session = checkout_session
  end

  def call
    return if Order.exists?(stripe_checkout_session_id: @session.id)

    pending_checkout = PendingCheckout.find_by!(token: @session.metadata.pending_checkout_token)
    cart = pending_checkout.cart

    ActiveRecord::Base.transaction do
      order = build_order(pending_checkout)
      build_order_items(order, cart)
      pending_checkout.destroy!
      cart.destroy!
      OrderMailer.confirmation(order).deliver_later
    end
  end

  private

  def build_order(pending_checkout)
    Order.create!(
      user:                        User.find_by(email: pending_checkout.email),
      email:                       pending_checkout.email,
      status:                      :processing,
      total_cents:                 @session.amount_total,
      stripe_checkout_session_id:  @session.id,
      shipping_address_name:       pending_checkout.shipping_address_name,
      shipping_address_line1:      pending_checkout.shipping_address_line1,
      shipping_address_line2:      pending_checkout.shipping_address_line2,
      shipping_address_city:       pending_checkout.shipping_address_city,
      shipping_address_state:      pending_checkout.shipping_address_state,
      shipping_address_zip:        pending_checkout.shipping_address_zip,
      shipping_address_country:    pending_checkout.shipping_address_country
    )
  end

  def build_order_items(order, cart)
    cart.cart_items.includes(:coffee).each do |item|
      order.order_items.create!(
        coffee:           item.coffee,
        quantity:         item.quantity,
        unit_price_cents: item.coffee.price_cents
      )
    end
  end
end
