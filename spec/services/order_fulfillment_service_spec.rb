require "rails_helper"

RSpec.describe OrderFulfillmentService do
  let(:user)             { create(:user) }
  let(:cart)             { create(:cart, user: user) }
  let(:coffee)           { create(:coffee, price_cents: 1800) }
  let(:pending_checkout) { create(:pending_checkout, cart: cart, email: user.email) }
  let(:session_id)       { "cs_test_#{SecureRandom.hex(8)}" }

  let(:stripe_session) do
    double(
      "Stripe::Checkout::Session",
      id:           session_id,
      amount_total: 2599,
      metadata:     double(pending_checkout_token: pending_checkout.token)
    )
  end

  before { create(:cart_item, cart: cart, coffee: coffee, quantity: 2) }

  describe "#call" do
    it "creates an Order with the correct totals and address" do
      expect {
        described_class.new(checkout_session: stripe_session).call
      }.to change(Order, :count).by(1)

      order = Order.last
      expect(order.total_cents).to eq(2599)
      expect(order.email).to eq(user.email)
      expect(order.stripe_checkout_session_id).to eq(session_id)
      expect(order.shipping_address_line1).to eq(pending_checkout.shipping_address_line1)
    end

    it "creates OrderItems from the cart" do
      expect {
        described_class.new(checkout_session: stripe_session).call
      }.to change(OrderItem, :count).by(1)

      item = OrderItem.last
      expect(item.quantity).to eq(2)
      expect(item.unit_price_cents).to eq(1800)
    end

    it "destroys the cart after fulfillment" do
      described_class.new(checkout_session: stripe_session).call
      expect(Cart.exists?(cart.id)).to be false
    end

    it "destroys the PendingCheckout after fulfillment" do
      described_class.new(checkout_session: stripe_session).call
      expect(PendingCheckout.exists?(pending_checkout.id)).to be false
    end

    it "enqueues an order confirmation email" do
      expect {
        described_class.new(checkout_session: stripe_session).call
      }.to have_enqueued_mail(OrderMailer, :confirmation)
    end

    it "sets the order status to processing" do
      described_class.new(checkout_session: stripe_session).call
      expect(Order.last.status).to eq("processing")
    end

    context "when the session has already been fulfilled (idempotency)" do
      before { create(:order, :with_stripe_session, stripe_checkout_session_id: session_id) }

      it "does not create a duplicate order" do
        expect {
          described_class.new(checkout_session: stripe_session).call
        }.not_to change(Order, :count)
      end
    end

    context "when the PendingCheckout is missing" do
      let(:stripe_session) do
        double(
          "Stripe::Checkout::Session",
          id:           session_id,
          amount_total: 2599,
          metadata:     double(pending_checkout_token: "nonexistent-token")
        )
      end

      it "raises an error" do
        expect {
          described_class.new(checkout_session: stripe_session).call
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when fulfillment fails mid-transaction" do
      before do
        allow_any_instance_of(Order).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "rolls back the transaction — no order is persisted" do
        expect {
          described_class.new(checkout_session: stripe_session).call rescue nil
        }.not_to change(Order, :count)
      end

      it "does not destroy the cart" do
        described_class.new(checkout_session: stripe_session).call rescue nil
        expect(Cart.exists?(cart.id)).to be true
      end
    end
  end
end
