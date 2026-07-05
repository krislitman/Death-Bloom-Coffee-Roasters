require "rails_helper"

RSpec.describe "Checkouts", type: :request do
  let(:coffee) { create(:coffee, price_cents: 1800) }

  def cart_with_item
    cart = Cart.current_for(session_token: "guest_token_test")
    create(:cart_item, cart: cart, coffee: coffee)
    cart
  end

  describe "POST /checkout" do
    context "with items in the cart" do
      before do
        cart_with_item
        allow_any_instance_of(ApplicationController).to receive(:guest_session_token).and_return("guest_token_test")
        stub_stripe_checkout_session_create
      end

      it "redirects to the Stripe Checkout URL" do
        post checkout_path
        expect(response).to redirect_to(StripeHelpers::STRIPE_SESSION_URL)
      end

      it "creates a Stripe Checkout Session" do
        post checkout_path
        expect(WebMock).to have_requested(:post, "https://api.stripe.com/v1/checkout/sessions")
      end
    end

    context "with an empty cart" do
      it "redirects to the cart" do
        post checkout_path
        expect(response).to redirect_to(cart_path)
      end
    end
  end

  describe "GET /checkout/success" do
    it "renders the success page" do
      get success_checkout_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /checkout/cancel" do
    it "renders the cancel page" do
      get cancel_checkout_path
      expect(response).to have_http_status(:ok)
    end
  end
end
