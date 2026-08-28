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

    context "when the inventory flag is enabled" do
      let(:user) { create(:user) }

      before do
        Flipper.enable(:inventory)
        sign_in user
      end

      it "caps the quantity at the available stock" do
        low = create(:coffee, :low_stock)

        post cart_cart_items_path, params: { cart_item: { coffee_id: low.id, quantity: 5 } }

        expect(CartItem.find_by(coffee: low).quantity).to eq(2)
      end

      it "tells the customer how many are left" do
        low = create(:coffee, :low_stock)

        post cart_cart_items_path, params: { cart_item: { coffee_id: low.id, quantity: 5 } }

        expect(flash[:alert]).to include("Only 2 left")
      end

      it "does not add a sold out coffee to the cart" do
        gone = create(:coffee, :out_of_stock)

        expect {
          post cart_cart_items_path, params: { cart_item: { coffee_id: gone.id, quantity: 1 } }
        }.not_to change(CartItem, :count)
      end

      it "accounts for stock already claimed by existing orders" do
        partly_sold = create(:coffee, stock_quantity: 5)
        create(:order_item, coffee: partly_sold, quantity: 4, order: create(:order))

        post cart_cart_items_path, params: { cart_item: { coffee_id: partly_sold.id, quantity: 3 } }

        expect(CartItem.find_by(coffee: partly_sold).quantity).to eq(1)
      end

      it "caps an existing cart item at the available stock" do
        low  = create(:coffee, :low_stock)
        cart = create(:cart, :for_user, user: user)
        create(:cart_item, cart: cart, coffee: low, quantity: 1)

        post cart_cart_items_path, params: { cart_item: { coffee_id: low.id, quantity: 5 } }

        expect(cart.cart_items.find_by(coffee: low).quantity).to eq(2)
      end
    end

    context "when the inventory flag is disabled" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "adds a sold out coffee without complaint" do
        gone = create(:coffee, :out_of_stock)

        expect {
          post cart_cart_items_path, params: { cart_item: { coffee_id: gone.id, quantity: 4 } }
        }.to change(CartItem, :count).by(1)
      end

      it "does not cap the quantity at the available stock" do
        low = create(:coffee, :low_stock)

        post cart_cart_items_path, params: { cart_item: { coffee_id: low.id, quantity: 5 } }

        expect(CartItem.find_by(coffee: low).quantity).to eq(5)
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

    context "when the inventory flag is enabled" do
      before { Flipper.enable(:inventory) }

      it "caps the quantity at the available stock" do
        low  = create(:coffee, :low_stock)
        item = create(:cart_item, cart: cart, coffee: low, quantity: 1)

        patch cart_cart_item_path(item), params: { cart_item: { quantity: 8 } },
                                         headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(item.reload.quantity).to eq(2)
      end
    end

    context "when the inventory flag is disabled" do
      it "does not cap the quantity at the available stock" do
        low  = create(:coffee, :low_stock)
        item = create(:cart_item, cart: cart, coffee: low, quantity: 1)

        patch cart_cart_item_path(item), params: { cart_item: { quantity: 8 } },
                                         headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(item.reload.quantity).to eq(8)
      end
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
