require "webmock/rspec"

WebMock.disable_net_connect!(allow_localhost: true)

module StripeHelpers
  STRIPE_SESSION_ID  = "cs_test_abc123"
  STRIPE_SESSION_URL = "https://checkout.stripe.com/pay/cs_test_abc123"

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

  def stub_stripe_session_retrieve(session_id:, cart_id:, email: "buyer@example.com",
                                   amount_total: 4200, payment_status: "paid")
    body = {
      id:               session_id,
      object:           "checkout.session",
      payment_status:   payment_status,
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
      metadata: { cart_id: cart_id.to_s }
    }.to_json

    stub_request(:get, %r{\Ahttps://api\.stripe\.com/v1/checkout/sessions/#{session_id}})
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })
  end
end

RSpec.configure do |config|
  config.include StripeHelpers

  config.after(:each) do
    WebMock.reset!
  end
end
