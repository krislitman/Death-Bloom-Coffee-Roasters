require "rails_helper"

RSpec.describe StripeCheckoutService do
  let(:cart)           { create(:cart) }
  let(:coffee)         { create(:coffee, price_cents: 1800) }
  let(:session_double) { double("Stripe::Checkout::Session", url: StripeHelpers::STRIPE_SESSION_URL) }

  before do
    create(:cart_item, cart: cart, coffee: coffee, quantity: 1)
    allow(Stripe::Checkout::Session).to receive(:create).and_return(session_double)
  end

  describe "#call" do
    it "returns the Stripe Checkout Session" do
      expect(described_class.new(cart: cart).call).to eq(session_double)
    end

    it "creates the session in payment mode" do
      described_class.new(cart: cart).call
      expect(Stripe::Checkout::Session).to have_received(:create).with(hash_including(mode: "payment"))
    end

    it "enables automatic tax" do
      described_class.new(cart: cart).call
      expect(Stripe::Checkout::Session).to have_received(:create).with(hash_including(automatic_tax: { enabled: true }))
    end

    it "collects the shipping address for the US" do
      described_class.new(cart: cart).call
      expect(Stripe::Checkout::Session).to have_received(:create)
        .with(hash_including(shipping_address_collection: { allowed_countries: [ "US" ] }))
    end

    it "passes the cart id in metadata" do
      described_class.new(cart: cart).call
      expect(Stripe::Checkout::Session).to have_received(:create).with(hash_including(metadata: { cart_id: cart.id }))
    end

    it "builds one line item per cart item with the coffee price" do
      described_class.new(cart: cart).call
      expect(Stripe::Checkout::Session).to have_received(:create) do |args|
        expect(args[:line_items].size).to eq(1)
        expect(args[:line_items].first[:price_data][:unit_amount]).to eq(1800)
      end
    end

    it "does not add a shipping line item" do
      described_class.new(cart: cart).call
      expect(Stripe::Checkout::Session).to have_received(:create) do |args|
        expect(args[:line_items].map { |i| i[:price_data][:product_data][:name] }).to eq([ coffee.name ])
      end
    end

    it "offers a flat-rate Standard shipping option" do
      described_class.new(cart: cart).call
      expect(Stripe::Checkout::Session).to have_received(:create) do |args|
        standard = args[:shipping_options].first[:shipping_rate_data]
        expect(standard[:type]).to eq("fixed_amount")
        expect(standard[:fixed_amount]).to eq(amount: described_class::STANDARD_SHIPPING_CENTS, currency: "usd")
        expect(standard[:display_name]).to eq("Standard")
      end
    end

    it "offers a flat-rate Express shipping option" do
      described_class.new(cart: cart).call
      expect(Stripe::Checkout::Session).to have_received(:create) do |args|
        express = args[:shipping_options].last[:shipping_rate_data]
        expect(express[:fixed_amount]).to eq(amount: described_class::EXPRESS_SHIPPING_CENTS, currency: "usd")
        expect(express[:display_name]).to eq("Express")
      end
    end

    context "for a guest with no user" do
      it "does not pre-create a Stripe Customer" do
        described_class.new(cart: cart).call
        expect(Stripe::Checkout::Session).to have_received(:create) do |args|
          expect(args).not_to have_key(:customer)
          expect(args).not_to have_key(:customer_email)
        end
      end
    end

    context "for an authenticated user" do
      let(:user) { create(:user) }

      it "prefills the customer email" do
        described_class.new(cart: cart, user: user).call
        expect(Stripe::Checkout::Session).to have_received(:create).with(hash_including(customer_email: user.email))
      end
    end
  end
end
