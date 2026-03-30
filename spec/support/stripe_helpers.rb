require "webmock/rspec"

# Allow all local connections; disable external ones by default.
WebMock.disable_net_connect!(allow_localhost: true)

module StripeHelpers
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
