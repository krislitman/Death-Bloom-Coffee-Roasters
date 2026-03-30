require "rails_helper"

RSpec.describe "Carts", type: :request do
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
