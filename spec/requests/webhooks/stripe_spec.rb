require "rails_helper"

RSpec.describe "Webhooks::Stripe", type: :request do
  let(:webhook_secret) { "whsec_test_secret" }
  let(:session_id)     { "cs_test_#{SecureRandom.hex(8)}" }

  def session_object(cart_id:)
    {
      id:           session_id,
      object:       "checkout.session",
      amount_total: 2599,
      customer_details: { email: "guest@example.com" },
      collected_information: {
        shipping_details: {
          name:    "Jane Doe",
          address: {
            line1:       "123 Main St",
            line2:       nil,
            city:        "Denver",
            state:       "CO",
            postal_code: "80203",
            country:     "US"
          }
        }
      },
      metadata: { cart_id: cart_id }
    }
  end

  def completed_event(cart_id:)
    {
      id:   "evt_#{SecureRandom.hex(8)}",
      type: "checkout.session.completed",
      data: { object: session_object(cart_id: cart_id) }
    }.to_json
  end

  def stripe_signature(payload, secret: webhook_secret, timestamp: Time.now.to_i)
    signed_payload = "#{timestamp}.#{payload}"
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
    "t=#{timestamp},v1=#{signature}"
  end

  def post_webhook(payload, signature: stripe_signature(payload))
    post webhooks_stripe_path, params: payload,
         headers: { "HTTP_STRIPE_SIGNATURE" => signature, "CONTENT_TYPE" => "application/json" }
  end

  around do |example|
    original = ENV["STRIPE_WEBHOOK_SECRET"]
    ENV["STRIPE_WEBHOOK_SECRET"] = webhook_secret
    example.run
    ENV["STRIPE_WEBHOOK_SECRET"] = original
  end

  describe "POST /webhooks/stripe" do
    context "with a valid Stripe signature" do
      context "when the cart exists and fulfillment succeeds" do
        let(:cart)   { create(:cart) }
        let(:coffee) { create(:coffee) }
        let(:payload) { completed_event(cart_id: cart.id.to_s) }

        before { create(:cart_item, cart: cart, coffee: coffee) }

        it "returns 200" do
          post_webhook(payload)
          expect(response).to have_http_status(:ok)
        end

        it "creates an Order" do
          expect { post_webhook(payload) }.to change(Order, :count).by(1)
        end
      end

      context "when the session has already been fulfilled" do
        let(:payload) { completed_event(cart_id: "0") }

        before do
          create(:order, :with_stripe_session, stripe_checkout_session_id: session_id,
                 email: "existing@example.com")
        end

        it "returns 200 without creating a duplicate order" do
          expect { post_webhook(payload) }.not_to change(Order, :count)
          expect(response).to have_http_status(:ok)
        end
      end

      context "when the cart is missing but the session is paid" do
        let(:payload) { completed_event(cart_id: "0") }

        it "returns 200 and still records an order" do
          expect { post_webhook(payload) }.to change(Order, :count).by(1)
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "with an invalid Stripe signature" do
      it "returns 400" do
        post_webhook(completed_event(cart_id: "0"), signature: "t=0,v1=badsig")
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with an unhandled event type" do
      let(:unhandled_payload) do
        { id: "evt_1", type: "customer.created", data: { object: {} } }.to_json
      end

      it "returns 200 and does nothing" do
        post_webhook(unhandled_payload)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
