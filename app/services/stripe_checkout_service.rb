class StripeCheckoutService
  # NOTE: txcd_10000000 = "Food for home consumption". Requires legal/tax review
  # before treating as production-ready for all jurisdictions.
  PRODUCT_TAX_CODE  = "txcd_10000000"
  SHIPPING_TAX_CODE = "txcd_92010001"

  def initialize(cart:, pending_checkout:, user: nil)
    @cart             = cart
    @pending_checkout = pending_checkout
    @user             = user
  end

  def call
    customer = find_or_create_stripe_customer

    Stripe::Checkout::Session.create(
      customer:                   customer.id,
      customer_update:            { address: "auto" },
      payment_method_types:       [ "card" ],
      mode:                       "payment",
      line_items:                 line_items,
      automatic_tax:              { enabled: true },
      billing_address_collection: "auto",
      success_url:                success_url,
      cancel_url:                 cancel_url,
      metadata:                   { pending_checkout_token: @pending_checkout.token }
    )
  end

  private

  def find_or_create_stripe_customer
    if @user&.stripe_customer_id
      customer = Stripe::Customer.retrieve(@user.stripe_customer_id)
      Stripe::Customer.update(customer.id, address: stripe_address)
      customer
    else
      customer = Stripe::Customer.create(
        email:    @pending_checkout.email,
        address:  stripe_address,
        metadata: { guest: @user.nil?.to_s }
      )
      @user&.update!(stripe_customer_id: customer.id)
      customer
    end
  end

  def stripe_address
    {
      line1:       @pending_checkout.shipping_address_line1,
      line2:       @pending_checkout.shipping_address_line2,
      city:        @pending_checkout.shipping_address_city,
      state:       @pending_checkout.shipping_address_state,
      postal_code: @pending_checkout.shipping_address_zip,
      country:     @pending_checkout.shipping_address_country
    }
  end

  def line_items
    coffee_line_items + [ shipping_line_item ]
  end

  def coffee_line_items
    @cart.cart_items.includes(:coffee).map do |item|
      {
        price_data: {
          currency:     "usd",
          product_data: {
            name:     item.coffee.name,
            tax_code: PRODUCT_TAX_CODE,
            metadata: { coffee_id: item.coffee.id.to_s }
          },
          unit_amount:  item.coffee.price_cents,
          tax_behavior: "exclusive"
        },
        quantity: item.quantity
      }
    end
  end

  def shipping_line_item
    {
      price_data: {
        currency:     "usd",
        product_data: {
          name:     "Shipping — #{@pending_checkout.shippo_rate_carrier} #{@pending_checkout.shippo_rate_service}",
          tax_code: SHIPPING_TAX_CODE
        },
        unit_amount:  @pending_checkout.shippo_rate_amount_cents,
        tax_behavior: "exclusive"
      },
      quantity: 1
    }
  end

  def success_url
    host = ENV.fetch("APP_HOST", "localhost:3000")
    protocol = Rails.env.production? ? "https" : "http"
    "#{protocol}://#{host}/checkout/success?session_id={CHECKOUT_SESSION_ID}"
  end

  def cancel_url
    host = ENV.fetch("APP_HOST", "localhost:3000")
    protocol = Rails.env.production? ? "https" : "http"
    "#{protocol}://#{host}/checkout/cancel"
  end
end
