require "rails_helper"

RSpec.describe "Purchase journey", type: :request do
  let(:email)          { "buyer@example.com" }
  let(:password)       { "password123" }
  let(:webhook_secret) { "whsec_test_secret" }
  let!(:coffee)        { create(:coffee, name: "Ethiopia Guji", price_cents: 1800) }

  around do |example|
    original = ENV["STRIPE_WEBHOOK_SECRET"]
    ENV["STRIPE_WEBHOOK_SECRET"] = webhook_secret
    example.run
    ENV["STRIPE_WEBHOOK_SECRET"] = original
  end

  def sign_up(email:, password:)
    post user_registration_path, params: {
      user: { email: email, password: password, password_confirmation: password }
    }
  end

  def log_in(email:, password:)
    post user_session_path, params: { user: { email: email, password: password } }
  end

  def stripe_signature(payload, timestamp: Time.now.to_i)
    signed = "#{timestamp}.#{payload}"
    "t=#{timestamp},v1=#{OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, signed)}"
  end

  def completed_event(session_id:, cart_id:, email:, amount_total:)
    {
      id:   "evt_#{SecureRandom.hex(8)}",
      type: "checkout.session.completed",
      data: { object: {
        id:               session_id,
        object:           "checkout.session",
        amount_total:     amount_total,
        customer_details: { email: email },
        collected_information: {
          shipping_details: {
            name:    "Jane Buyer",
            address: {
              line1: "123 Main St", line2: nil, city: "Denver",
              state: "CO", postal_code: "80203", country: "US"
            }
          }
        },
        metadata: { cart_id: cart_id }
      } }
    }.to_json
  end

  def fulfill_via_webhook(session_id:, cart_id:, email:, amount_total:)
    payload = completed_event(
      session_id: session_id, cart_id: cart_id, email: email, amount_total: amount_total
    )
    post webhooks_stripe_path, params: payload, headers: {
      "HTTP_STRIPE_SIGNATURE" => stripe_signature(payload),
      "CONTENT_TYPE"          => "application/json"
    }
  end

  it "carries a shopper from sign up through order tracking" do
    session_id = StripeHelpers::STRIPE_SESSION_ID

    aggregate_failures "sign up" do
      expect { sign_up(email: email, password: password) }.to change(User, :count).by(1)
      expect(response).to have_http_status(:redirect)
    end

    delete destroy_user_session_path

    post cart_cart_items_path, params: { cart_item: { coffee_id: coffee.id, quantity: 2 } }
    guest_cart = Cart.find_by(user: nil)
    expect(guest_cart.item_count).to eq(2)

    log_in(email: email, password: password)

    user      = User.find_by(email: email)
    user_cart = Cart.find_by(user: user)
    aggregate_failures "cart merged on login" do
      expect(user_cart.item_count).to eq(2)
      expect(Cart.find_by(user: nil)).to be_nil
    end

    stub_stripe_checkout_session_create(session_id: session_id)
    post checkout_path
    aggregate_failures "checkout hands off to Stripe" do
      expect(WebMock).to have_requested(:post, "https://api.stripe.com/v1/checkout/sessions")
      expect(response).to redirect_to(StripeHelpers::STRIPE_SESSION_URL)
    end

    amount_total = coffee.price_cents * 2 + StripeCheckoutService::STANDARD_SHIPPING_CENTS
    expect {
      fulfill_via_webhook(
        session_id: session_id, cart_id: user_cart.id, email: email, amount_total: amount_total
      )
    }.to change(Order, :count).by(1)

    order = Order.last
    aggregate_failures "order created with a number and line items" do
      expect(order.order_number).to match(/\ADB-[A-F0-9]{6}\z/)
      expect(order.user).to eq(user)
      expect(order.total_cents).to eq(amount_total)
      expect(order.order_items.sum(:quantity)).to eq(2)
      expect(Cart.find_by(user: user)).to be_nil
    end

    log_in(email: email, password: password)

    get orders_path
    expect(response.body).to include(order.order_number)

    get order_path(order)
    aggregate_failures "order tracking page" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(order.order_number)
      expect(response.body).to include("Ethiopia Guji")
      expect(response.body).to include("Processing")
    end
  end
end
