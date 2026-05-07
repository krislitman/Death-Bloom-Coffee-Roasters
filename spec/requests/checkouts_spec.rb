require "rails_helper"

RSpec.describe "Checkouts", type: :request do
  let(:coffee) { create(:coffee, price_cents: 1800) }

  def cart_with_item(user: nil)
    cart = user ? Cart.current_for(user: user) : Cart.current_for(session_token: "guest_token_test")
    create(:cart_item, cart: cart, coffee: coffee)
    cart
  end

  def set_guest_session
    get cart_path
    # set the session cart_token so the controller can find the guest cart
  end

  describe "GET /checkout" do
    context "with items in the cart" do
      before do
        cart = cart_with_item
        allow_any_instance_of(ApplicationController).to receive(:guest_session_token).and_return("guest_token_test")
      end

      it "renders the checkout form" do
        get checkout_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "with an empty cart" do
      it "redirects to the cart" do
        get checkout_path
        expect(response).to redirect_to(cart_path)
      end
    end
  end

  describe "GET /checkout/rates" do
    let(:destination_params) do
      {
        destination: {
          name: "Jane Doe", line1: "123 Main St", line2: "",
          city: "Denver", state: "CO", zip: "80203", country: "US"
        }
      }
    end

    before do
      cart_with_item
      allow_any_instance_of(ApplicationController).to receive(:guest_session_token).and_return("guest_token_test")
    end

    context "when Shippo returns rates" do
      before { stub_shippo_shipment_create }

      it "renders the rates partial" do
        get rates_checkout_path, params: destination_params
        expect(response).to have_http_status(:ok)
      end

      it "stores rates in the session" do
        get rates_checkout_path, params: destination_params
        expect(session[:shippo_rates]).to be_present
      end
    end

    context "when Shippo returns an error" do
      before { stub_shippo_shipment_error }

      it "renders an error partial with 422" do
        get rates_checkout_path, params: destination_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "POST /checkout" do
    let(:checkout_params) do
      {
        checkout: {
          email: "guest@example.com",
          name: "Jane Doe",
          line1: "123 Main St", line2: "",
          city: "Denver", state: "CO", zip: "80203", country: "US",
          rate_id: ShippoHelpers::SHIPPO_RATE_FIXTURE["object_id"]
        }
      }
    end

    before do
      cart_with_item
      allow_any_instance_of(ApplicationController).to receive(:guest_session_token).and_return("guest_token_test")
    end

    context "with a valid rate in session" do
      before do
        stub_stripe_customer_create
        stub_stripe_checkout_session_create
      end

      it "creates a PendingCheckout" do
        # Seed the session with valid rates via the rates endpoint
        stub_shippo_shipment_create
        get rates_checkout_path, params: { destination: { name: "Jane", line1: "123 Main St", line2: "",
          city: "Denver", state: "CO", zip: "80203", country: "US" } }

        expect {
          post checkout_path, params: checkout_params
        }.to change(PendingCheckout, :count).by(1)
      end

      it "redirects to the Stripe Checkout URL" do
        stub_shippo_shipment_create
        get rates_checkout_path, params: { destination: { name: "Jane", line1: "123 Main St", line2: "",
          city: "Denver", state: "CO", zip: "80203", country: "US" } }

        post checkout_path, params: checkout_params
        expect(response).to redirect_to(StripeHelpers::STRIPE_SESSION_URL)
      end
    end

    context "with a tampered rate_id not in session" do
      it "redirects back to checkout with an alert" do
        post checkout_path, params: checkout_params
        expect(response).to redirect_to(checkout_path)
      end
    end

    context "with a missing email" do
      before do
        stub_shippo_shipment_create
        get rates_checkout_path, params: { destination: { name: "Jane", line1: "123 Main St", line2: "",
          city: "Denver", state: "CO", zip: "80203", country: "US" } }
      end

      it "redirects back to checkout" do
        post checkout_path, params: { checkout: checkout_params[:checkout].merge(email: "") }
        expect(response).to redirect_to(checkout_path)
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
