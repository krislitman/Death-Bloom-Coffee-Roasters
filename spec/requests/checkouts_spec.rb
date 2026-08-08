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

    context "when an item went out of stock before checkout" do
      before do
        cart_with_item
        coffee.update!(stock_quantity: 0)
        allow_any_instance_of(ApplicationController).to receive(:guest_session_token).and_return("guest_token_test")
        stub_stripe_checkout_session_create
      end

      context "and the inventory flag is enabled" do
        before { Flipper.enable(:inventory) }

        it "redirects back to the cart" do
          post checkout_path
          expect(response).to redirect_to(cart_path)
        end

        it "names the offending coffee in the alert" do
          post checkout_path
          expect(flash[:alert]).to include(coffee.name)
        end

        it "does not create a Stripe Checkout Session" do
          post checkout_path
          expect(WebMock).not_to have_requested(:post, "https://api.stripe.com/v1/checkout/sessions")
        end
      end

      context "and the inventory flag is disabled" do
        it "proceeds to Stripe as before" do
          post checkout_path
          expect(response).to redirect_to(StripeHelpers::STRIPE_SESSION_URL)
        end
      end
    end
  end

  describe "GET /checkout/success" do
    it "renders the success page" do
      get success_checkout_path
      expect(response).to have_http_status(:ok)
    end

    context "with a session_id whose order already exists" do
      let(:order) { create(:order, :with_stripe_session) }

      it "shows the existing order without calling Stripe" do
        get success_checkout_path(session_id: order.stripe_checkout_session_id)
        expect(response.body).to include(order.order_number)
        expect(WebMock).not_to have_requested(:get, /api.stripe.com/)
      end
    end

    context "with a paid session_id that has no order yet" do
      let(:session_id) { "cs_test_reconcile" }

      before do
        Stripe.api_key = "sk_test_dummy"
        cart = Cart.current_for(session_token: "reconcile_token")
        create(:cart_item, cart: cart, coffee: coffee)
        stub_stripe_session_retrieve(session_id: session_id, cart_id: cart.id, payment_status: "paid")
      end

      it "fulfills the order and shows its number" do
        expect { get success_checkout_path(session_id: session_id) }.to change(Order, :count).by(1)
        expect(response.body).to include(Order.last.order_number)
      end
    end

    context "with an unpaid session_id" do
      let(:session_id) { "cs_test_unpaid" }

      before do
        Stripe.api_key = "sk_test_dummy"
        stub_stripe_session_retrieve(session_id: session_id, cart_id: "0", payment_status: "unpaid")
      end

      it "does not create an order" do
        expect { get success_checkout_path(session_id: session_id) }.not_to change(Order, :count)
      end
    end
  end

  describe "GET /checkout/cancel" do
    it "renders the cancel page" do
      get cancel_checkout_path
      expect(response).to have_http_status(:ok)
    end
  end
end
