require "rails_helper"

RSpec.describe OrderFulfillmentService do
  let(:user)       { create(:user) }
  let(:cart)       { create(:cart, user: user) }
  let(:coffee)     { create(:coffee, price_cents: 1800) }
  let(:session_id) { "cs_test_#{SecureRandom.hex(8)}" }

  let(:address) do
    double(
      "Stripe::Address",
      line1:       "123 Main St",
      line2:       nil,
      city:        "Denver",
      state:       "CO",
      postal_code: "80203",
      country:     "US"
    )
  end

  let(:shipping_details) { double("Stripe::ShippingDetails", name: "Jane Doe", address: address) }

  let(:stripe_session) do
    double(
      "Stripe::Checkout::Session",
      id:                    session_id,
      amount_total:          2599,
      customer_details:      double(email: user.email),
      collected_information: double(shipping_details: shipping_details),
      metadata:              double(cart_id: cart.id.to_s)
    )
  end

  before { create(:cart_item, cart: cart, coffee: coffee, quantity: 2) }

  describe "#call" do
    it "creates an Order with the total and address from the session" do
      expect {
        described_class.new(checkout_session: stripe_session).call
      }.to change(Order, :count).by(1)

      order = Order.last
      expect(order.total_cents).to eq(2599)
      expect(order.email).to eq(user.email)
      expect(order.stripe_checkout_session_id).to eq(session_id)
      expect(order.shipping_address_line1).to eq("123 Main St")
      expect(order.shipping_address_name).to eq("Jane Doe")
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

    it "enqueues an order confirmation email" do
      expect {
        described_class.new(checkout_session: stripe_session).call
      }.to have_enqueued_mail(OrderMailer, :confirmation)
    end

    it "sets the order status to processing" do
      described_class.new(checkout_session: stripe_session).call
      expect(Order.last.status).to eq("processing")
    end

    context "when the session has already been fulfilled" do
      before { create(:order, :with_stripe_session, stripe_checkout_session_id: session_id) }

      it "does not create a duplicate order" do
        expect {
          described_class.new(checkout_session: stripe_session).call
        }.not_to change(Order, :count)
      end
    end

    context "when the cart is missing but the session is paid" do
      let(:stripe_session) do
        double(
          "Stripe::Checkout::Session",
          id:                    session_id,
          amount_total:          2599,
          customer_details:      double(email: user.email),
          collected_information: double(shipping_details: shipping_details),
          metadata:              double(cart_id: "0")
        )
      end

      it "still records an order" do
        expect {
          described_class.new(checkout_session: stripe_session).call
        }.to change(Order, :count).by(1)
      end

      it "records no order items" do
        described_class.new(checkout_session: stripe_session).call
        expect(Order.last.order_items).to be_empty
      end
    end

    context "when the inventory flag is enabled" do
      before { Flipper.enable(:inventory) }

      context "and stock covers the order" do
        it "does not flag the order as oversold" do
          coffee.update!(stock_quantity: 10)

          described_class.new(checkout_session: stripe_session).call

          expect(Order.last).not_to be_oversold
        end
      end

      context "and stock ran out while the customer was paying" do
        before { coffee.update!(stock_quantity: 1) }

        it "still records the order" do
          expect {
            described_class.new(checkout_session: stripe_session).call
          }.to change(Order, :count).by(1)
        end

        it "flags the order as oversold" do
          described_class.new(checkout_session: stripe_session).call

          expect(Order.last).to be_oversold
        end

        it "still records the order items" do
          described_class.new(checkout_session: stripe_session).call

          expect(Order.last.order_items.sum(:quantity)).to eq(2)
        end

        it "logs an error naming the coffee" do
          allow(Rails.logger).to receive(:error)

          described_class.new(checkout_session: stripe_session).call

          expect(Rails.logger).to have_received(:error).with(/#{Regexp.escape(coffee.name)}/)
        end

        it "lets available stock go negative" do
          described_class.new(checkout_session: stripe_session).call

          expect(coffee.reload.available_stock).to eq(-1)
        end
      end
    end

    context "when the inventory flag is disabled" do
      it "never flags the order as oversold" do
        coffee.update!(stock_quantity: 0)

        described_class.new(checkout_session: stripe_session).call

        expect(Order.last).not_to be_oversold
      end
    end

    context "when fulfillment fails mid-transaction" do
      before do
        allow_any_instance_of(Order).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "does not persist an order" do
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
