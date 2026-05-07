require "rails_helper"

RSpec.describe "Webhooks::Stripe", type: :request do
  let(:webhook_secret) { "whsec_test_secret" }
  let(:session_id)     { "cs_test_#{SecureRandom.hex(8)}" }

  let(:checkout_session_payload) do
    {
      id:   "evt_#{SecureRandom.hex(8)}",
      type: "checkout.session.completed",
      data: {
        object: {
          id:           session_id,
          object:       "checkout.session",
          amount_total: 2599,
          metadata:     { pending_checkout_token: "nonexistent-token" }
        }
      }
    }.to_json
  end

  def stripe_signature(payload, secret: webhook_secret, timestamp: Time.now.to_i)
    signed_payload = "#{timestamp}.#{payload}"
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
    "t=#{timestamp},v1=#{signature}"
  end

  around do |example|
    original = ENV["STRIPE_WEBHOOK_SECRET"]
    ENV["STRIPE_WEBHOOK_SECRET"] = webhook_secret
    example.run
    ENV["STRIPE_WEBHOOK_SECRET"] = original
  end

  describe "POST /webhooks/stripe" do
    context "with a valid Stripe signature" do
      context "when the PendingCheckout exists and fulfillment succeeds" do
        let(:cart)             { create(:cart) }
        let(:pending_checkout) { create(:pending_checkout, cart: cart) }
        let(:coffee)           { create(:coffee) }

        let(:payload_with_token) do
          {
            id:   "evt_#{SecureRandom.hex(8)}",
            type: "checkout.session.completed",
            data: {
              object: {
                id:           session_id,
                object:       "checkout.session",
                amount_total: 2599,
                metadata:     { pending_checkout_token: pending_checkout.token }
              }
            }
          }.to_json
        end

        before { create(:cart_item, cart: cart, coffee: coffee) }

        it "returns 200" do
          sig = stripe_signature(payload_with_token)
          post webhooks_stripe_path, params: payload_with_token,
               headers: { "HTTP_STRIPE_SIGNATURE" => sig, "CONTENT_TYPE" => "application/json" }
          expect(response).to have_http_status(:ok)
        end

        it "creates an Order" do
          sig = stripe_signature(payload_with_token)
          expect {
            post webhooks_stripe_path, params: payload_with_token,
                 headers: { "HTTP_STRIPE_SIGNATURE" => sig, "CONTENT_TYPE" => "application/json" }
          }.to change(Order, :count).by(1)
        end
      end

      context "when the session has already been fulfilled (idempotency)" do
        before do
          create(:order, :with_stripe_session, stripe_checkout_session_id: session_id,
                 email: "existing@example.com")
        end

        it "returns 200 without creating a duplicate order" do
          sig = stripe_signature(checkout_session_payload)
          expect {
            post webhooks_stripe_path, params: checkout_session_payload,
                 headers: { "HTTP_STRIPE_SIGNATURE" => sig, "CONTENT_TYPE" => "application/json" }
          }.not_to change(Order, :count)

          expect(response).to have_http_status(:ok)
        end
      end

      context "when the PendingCheckout is missing" do
        it "returns 500 so Stripe retries" do
          sig = stripe_signature(checkout_session_payload)
          post webhooks_stripe_path, params: checkout_session_payload,
               headers: { "HTTP_STRIPE_SIGNATURE" => sig, "CONTENT_TYPE" => "application/json" }
          expect(response).to have_http_status(:internal_server_error)
        end
      end
    end

    context "with an invalid Stripe signature" do
      it "returns 400" do
        post webhooks_stripe_path, params: checkout_session_payload,
             headers: { "HTTP_STRIPE_SIGNATURE" => "t=0,v1=badsig", "CONTENT_TYPE" => "application/json" }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with an unhandled event type" do
      let(:unhandled_payload) do
        { id: "evt_1", type: "customer.created", data: { object: {} } }.to_json
      end

      it "returns 200 and does nothing" do
        sig = stripe_signature(unhandled_payload)
        post webhooks_stripe_path, params: unhandled_payload,
             headers: { "HTTP_STRIPE_SIGNATURE" => sig, "CONTENT_TYPE" => "application/json" }
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
