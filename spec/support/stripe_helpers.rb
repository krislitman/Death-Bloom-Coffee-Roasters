require "webmock/rspec"

# Allow all local connections; disable external ones by default.
WebMock.disable_net_connect!(allow_localhost: true)

module StripeHelpers
  STRIPE_CUSTOMER_ID    = "cus_test_123"
  STRIPE_SESSION_ID     = "cs_test_abc123"
  STRIPE_SESSION_URL    = "https://checkout.stripe.com/pay/cs_test_abc123"

  def stub_stripe_customer_create(id: STRIPE_CUSTOMER_ID)
    stub_request(:post, "https://api.stripe.com/v1/customers")
      .to_return(
        status: 200,
        body: { id: id, object: "customer", email: "guest@example.com" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_stripe_customer_retrieve(id: STRIPE_CUSTOMER_ID)
    stub_request(:get, "https://api.stripe.com/v1/customers/#{id}")
      .to_return(
        status: 200,
        body: { id: id, object: "customer" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_stripe_customer_update(id: STRIPE_CUSTOMER_ID)
    stub_request(:post, "https://api.stripe.com/v1/customers/#{id}")
      .to_return(
        status: 200,
        body: { id: id, object: "customer" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_stripe_checkout_session_create(session_id: STRIPE_SESSION_ID, url: STRIPE_SESSION_URL)
    stub_request(:post, "https://api.stripe.com/v1/checkout/sessions")
      .to_return(
        status: 200,
        body: {
          id:     session_id,
          object: "checkout.session",
          url:    url
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_stripe_payment_intent_create(amount:, id: "pi_test_123")
    stub_request(:post, "https://api.stripe.com/v1/payment_intents")
      .to_return(
        status: 200,
        body: {
          id: id,
          object: "payment_intent",
          amount: amount,
          currency: "usd",
          status: "requires_payment_method",
          client_secret: "#{id}_secret_test"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_stripe_payment_intent_retrieve(id: "pi_test_123", status: "succeeded")
    stub_request(:get, "https://api.stripe.com/v1/payment_intents/#{id}")
      .to_return(
        status: 200,
        body: {
          id: id,
          object: "payment_intent",
          status: status,
          amount: 1800,
          currency: "usd"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end

RSpec.configure do |config|
  config.include StripeHelpers

  config.after(:each) do
    WebMock.reset!
  end
end
