require "rails_helper"

RSpec.describe "Carts", type: :request do
  describe "GET /cart stock ceiling" do
    let(:user) { create(:user) }
    let(:cart) { create(:cart, :for_user, user: user) }
    let(:low)  { create(:coffee, :low_stock) }

    before { sign_in user }

    context "when the inventory flag is enabled" do
      before { Flipper.enable(:inventory) }

      it "disables the increment button at the available stock" do
        create(:cart_item, cart: cart, coffee: low, quantity: 2)

        get cart_path

        expect(response.body).to include("disabled")
      end

      it "does not issue an extra query per additional cart item" do
        create(:cart_item, cart: cart, coffee: low, quantity: 1)
        get cart_path
        baseline = count_queries { get cart_path }
        create_list(:coffee, 3).each { |coffee| create(:cart_item, cart: cart, coffee: coffee, quantity: 1) }

        expect { get cart_path }.to issue_queries(baseline)
      end
    end

    context "when the inventory flag is disabled" do
      it "still returns 200" do
        create(:cart_item, cart: cart, coffee: low, quantity: 2)

        get cart_path

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /cart" do
    context "when signed in" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "returns 200" do
        get cart_path
        expect(response).to have_http_status(:ok)
      end

      it "creates a cart for the user if one does not exist" do
        expect { get cart_path }.to change(Cart, :count).by(1)
      end

      it "does not create a second cart on repeat visits" do
        create(:cart, :for_user, user: user)
        expect { get cart_path }.not_to change(Cart, :count)
      end
    end

    context "when a guest" do
      it "returns 200" do
        get cart_path
        expect(response).to have_http_status(:ok)
      end

      it "creates a guest cart keyed to the session token" do
        expect { get cart_path }.to change(Cart, :count).by(1)
      end
    end
  end
end
