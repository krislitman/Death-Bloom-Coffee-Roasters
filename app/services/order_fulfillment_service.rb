class OrderFulfillmentService
  def initialize(checkout_session:)
    @session = checkout_session
  end

  def call
    return if Order.exists?(stripe_checkout_session_id: @session.id)

    cart = Cart.find_by(id: @session.metadata.cart_id)

    if cart
      fulfill_with_cart(cart)
    else
      fulfill_without_cart
    end
  end

  private

  def fulfill_with_cart(cart)
    ActiveRecord::Base.transaction do
      lock_coffees(cart)
      order = build_order
      build_order_items(order, cart)
      flag_oversold(order, cart)
      cart.destroy!
      OrderMailer.confirmation(order).deliver_later
    end
  end

  def lock_coffees(cart)
    return unless Flipper.enabled?(:inventory)

    cart.cart_items.map(&:coffee).uniq.sort_by(&:id).each(&:lock!)
  end

  def flag_oversold(order, cart)
    return unless Flipper.enabled?(:inventory)

    shortfalls = cart.cart_items.map(&:coffee).uniq.select { |coffee| coffee.reload.available_stock.negative? }
    return if shortfalls.empty?

    order.update!(oversold: true)
    Rails.logger.error(
      "OrderFulfillmentService: order #{order.order_number} oversold #{shortfalls.map(&:name).join(', ')}"
    )
  end

  def fulfill_without_cart
    Rails.logger.error(
      "OrderFulfillmentService: no cart for paid session #{@session.id}; recording order without line items"
    )

    ActiveRecord::Base.transaction do
      order = build_order
      OrderMailer.confirmation(order).deliver_later
    end
  end

  def build_order
    email   = @session.customer_details&.email
    details = @session.collected_information&.shipping_details
    address = details&.address

    Order.create!(
      user:                       User.find_by(email: email),
      email:                      email,
      status:                     :processing,
      total_cents:                @session.amount_total,
      stripe_checkout_session_id: @session.id,
      shipping_address_name:      details&.name,
      shipping_address_line1:     address&.line1,
      shipping_address_line2:     address&.line2,
      shipping_address_city:      address&.city,
      shipping_address_state:     address&.state,
      shipping_address_zip:       address&.postal_code,
      shipping_address_country:   address&.country
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
