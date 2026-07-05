class StripeCheckoutService
  PRODUCT_TAX_CODE  = "txcd_10000000"
  SHIPPING_TAX_CODE = "txcd_92010001"

  STANDARD_SHIPPING_CENTS = 600
  EXPRESS_SHIPPING_CENTS  = 1500

  def initialize(cart:, user: nil)
    @cart = cart
    @user = user
  end

  def call
    Stripe::Checkout::Session.create(session_params)
  end

  private

  def session_params
    params = {
      mode:                        "payment",
      line_items:                  coffee_line_items,
      automatic_tax:               { enabled: true },
      shipping_address_collection: { allowed_countries: [ "US" ] },
      shipping_options:            shipping_options,
      success_url:                 success_url,
      cancel_url:                  cancel_url,
      metadata:                    { cart_id: @cart.id }
    }
    params[:customer_email] = @user.email if @user
    params
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

  def shipping_options
    [
      shipping_option("Standard", STANDARD_SHIPPING_CENTS),
      shipping_option("Express",  EXPRESS_SHIPPING_CENTS)
    ]
  end

  def shipping_option(display_name, amount_cents)
    {
      shipping_rate_data: {
        type:         "fixed_amount",
        fixed_amount: { amount: amount_cents, currency: "usd" },
        display_name: display_name,
        tax_behavior: "exclusive",
        tax_code:     SHIPPING_TAX_CODE
      }
    }
  end

  def success_url
    "#{base_url}/checkout/success?session_id={CHECKOUT_SESSION_ID}"
  end

  def cancel_url
    "#{base_url}/checkout/cancel"
  end

  def base_url
    host     = ENV.fetch("APP_HOST", "localhost:3000")
    protocol = Rails.env.production? ? "https" : "http"
    "#{protocol}://#{host}"
  end
end
