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
end

RSpec.configure do |config|
  config.include StripeHelpers

  config.after(:each) do
    WebMock.reset!
  end
end
