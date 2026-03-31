require "rails_helper"

RSpec.describe "CartItems", type: :request do
  let(:coffee) { create(:coffee) }

  describe "POST /cart/cart_items" do
    context "when signed in" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "returns a Turbo Stream response" do
        post cart_cart_items_path, params: { cart_item: { coffee_id: coffee.id, quantity: 1 } },
                                   headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "adds an item to the user's cart" do
        expect {
          post cart_cart_items_path, params: { cart_item: { coffee_id: coffee.id, quantity: 2 } }
        }.to change(CartItem, :count).by(1)
      end

      it "increments quantity when item already in cart" do
        cart = create(:cart, :for_user, user: user)
        create(:cart_item, cart: cart, coffee: coffee, quantity: 3)

        post cart_cart_items_path, params: { cart_item: { coffee_id: coffee.id, quantity: 2 } }

        expect(cart.cart_items.find_by(coffee: coffee).quantity).to eq(5)
        expect(CartItem.count).to eq(1)
      end

      it "caps quantity at 10 when adding would exceed it" do
        cart = create(:cart, :for_user, user: user)
        create(:cart_item, cart: cart, coffee: coffee, quantity: 9)

        post cart_cart_items_path, params: { cart_item: { coffee_id: coffee.id, quantity: 5 } }

        expect(cart.cart_items.find_by(coffee: coffee).quantity).to eq(10)
      end
    end

    context "when a guest" do
      it "adds an item to the guest cart" do
        expect {
          post cart_cart_items_path, params: { cart_item: { coffee_id: coffee.id, quantity: 1 } }
        }.to change(CartItem, :count).by(1)
      end
    end
  end

  describe "PATCH /cart/cart_items/:id" do
    let(:user) { create(:user) }
    let(:cart) { create(:cart, :for_user, user: user) }
    let(:cart_item) { create(:cart_item, cart: cart, coffee: coffee) }

    before { sign_in user }

    it "updates the quantity" do
      patch cart_cart_item_path(cart_item), params: { cart_item: { quantity: 4 } },
                                            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(cart_item.reload.quantity).to eq(4)
    end

    it "returns a Turbo Stream response" do
      patch cart_cart_item_path(cart_item), params: { cart_item: { quantity: 4 } },
                                            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "rejects quantity above 10" do
      patch cart_cart_item_path(cart_item), params: { cart_item: { quantity: 11 } },
                                            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(cart_item.reload.quantity).to eq(1)
    end
  end

  describe "DELETE /cart/cart_items/:id" do
    let(:user) { create(:user) }
    let(:cart) { create(:cart, :for_user, user: user) }
    let(:cart_item) { create(:cart_item, cart: cart, coffee: coffee) }

    before { sign_in user }

    it "removes the item from the cart" do
      cart_item
      expect {
        delete cart_cart_item_path(cart_item), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      }.to change(CartItem, :count).by(-1)
    end

    it "returns a Turbo Stream response" do
      delete cart_cart_item_path(cart_item), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end
