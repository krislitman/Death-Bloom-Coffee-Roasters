require "rails_helper"

RSpec.describe "Users::Sessions", type: :request do
  describe "POST /users/sign_in (guest cart merge)" do
    let(:user) { create(:user) }
    let(:coffee) { create(:coffee) }

    context "when a guest cart exists in the session" do
      before do
        # Establish a guest session with a cart item
        post cart_cart_items_path, params: { cart_item: { coffee_id: coffee.id, quantity: 3 } }
      end

      it "merges the guest cart into the user cart on sign in" do
        post user_session_path, params: {
          user: { email: user.email, password: "Password1!" }
        }

        user_cart = Cart.find_by(user: user)
        expect(user_cart).to be_present
        expect(user_cart.cart_items.find_by(coffee: coffee)&.quantity).to eq(3)
      end

      it "destroys the guest cart after merge" do
        guest_cart_count_before = Cart.where(user: nil).count

        post user_session_path, params: {
          user: { email: user.email, password: "Password1!" }
        }

        expect(Cart.where(user: nil).count).to be < guest_cart_count_before
      end
    end

    context "when no guest cart exists" do
      it "signs in successfully without error" do
        post user_session_path, params: {
          user: { email: user.email, password: "Password1!" }
        }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
