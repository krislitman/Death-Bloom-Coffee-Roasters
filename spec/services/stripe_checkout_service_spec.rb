require "rails_helper"

RSpec.describe StripeCheckoutService do
  let(:cart)             { create(:cart) }
  let(:coffee)           { create(:coffee, price_cents: 1800) }
  let(:pending_checkout) { create(:pending_checkout, cart: cart) }

  before { create(:cart_item, cart: cart, coffee: coffee, quantity: 1) }

  describe "#call" do
    context "for a guest (no user)" do
      before do
        stub_stripe_customer_create
        stub_stripe_checkout_session_create
      end

      it "creates a Stripe Customer" do
        described_class.new(cart: cart, pending_checkout: pending_checkout).call
        expect(WebMock).to have_requested(:post, "https://api.stripe.com/v1/customers")
      end

      it "returns a Stripe Checkout Session with a url" do
        session = described_class.new(cart: cart, pending_checkout: pending_checkout).call
        expect(session.url).to eq(StripeHelpers::STRIPE_SESSION_URL)
      end

      it "creates a Checkout Session" do
        described_class.new(cart: cart, pending_checkout: pending_checkout).call
        expect(WebMock).to have_requested(:post, "https://api.stripe.com/v1/checkout/sessions")
      end
    end

    context "for an authenticated user without an existing Stripe customer" do
      let(:user) { create(:user) }

      before do
        stub_stripe_customer_create
        stub_stripe_checkout_session_create
      end

      it "creates a new Stripe Customer" do
        described_class.new(cart: cart, pending_checkout: pending_checkout, user: user).call
        expect(WebMock).to have_requested(:post, "https://api.stripe.com/v1/customers")
      end

      it "persists the Stripe customer ID on the user" do
        described_class.new(cart: cart, pending_checkout: pending_checkout, user: user).call
        expect(user.reload.stripe_customer_id).to eq(StripeHelpers::STRIPE_CUSTOMER_ID)
      end
    end

    context "for an authenticated user with an existing Stripe customer" do
      let(:user) { create(:user) }

      before do
        user.stripe_customer_id = StripeHelpers::STRIPE_CUSTOMER_ID
        stub_stripe_customer_retrieve
        stub_stripe_customer_update
        stub_stripe_checkout_session_create
      end

      it "retrieves the existing Stripe Customer instead of creating one" do
        described_class.new(cart: cart, pending_checkout: pending_checkout, user: user).call
        expect(WebMock).to have_requested(:get, "https://api.stripe.com/v1/customers/#{StripeHelpers::STRIPE_CUSTOMER_ID}")
        expect(WebMock).not_to have_requested(:post, "https://api.stripe.com/v1/customers")
      end
    end
  end
end
