require "rails_helper"

RSpec.describe Cart, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:cart_items).dependent(:destroy) }
    it { is_expected.to have_many(:coffees).through(:cart_items) }
  end

  describe "validations" do
    context "when user is present" do
      subject { build(:cart, user: create(:user)) }

      it "is valid without a session token" do
        expect(subject).to be_valid
      end
    end

    context "when user is absent (guest)" do
      subject { build(:cart, :guest) }

      it "is valid with a session token" do
        expect(subject).to be_valid
      end

      it "is invalid without a session token" do
        guest = build(:cart, user: nil, session_token: nil)
        expect(guest).not_to be_valid
        expect(guest.errors[:session_token]).to be_present
      end
    end
  end

  describe ".current_for" do
    context "when a user is provided" do
      let(:user) { create(:user) }

      it "creates a cart for the user if none exists" do
        expect { described_class.current_for(user: user) }
          .to change(Cart, :count).by(1)
      end

      it "returns the existing cart for the user" do
        cart = create(:cart, :for_user, user: user)
        expect(described_class.current_for(user: user)).to eq(cart)
      end

      it "ignores session_token when user is present" do
        cart = create(:cart, :for_user, user: user)
        expect(described_class.current_for(user: user, session_token: "other_token")).to eq(cart)
      end
    end

    context "when only a session_token is provided" do
      let(:token) { "session_abc123" }

      it "creates a guest cart if none exists" do
        expect { described_class.current_for(session_token: token) }
          .to change(Cart, :count).by(1)
      end

      it "returns the existing guest cart for the token" do
        cart = create(:cart, :guest, session_token: token)
        expect(described_class.current_for(session_token: token)).to eq(cart)
      end
    end
  end

  describe "#merge_guest_cart" do
    let(:user) { create(:user) }
    let(:coffee) { create(:coffee) }
    let(:user_cart) { create(:cart, :for_user, user: user) }
    let(:guest_cart) { create(:cart, :guest) }

    context "when the guest cart has items not in the user cart" do
      before { create(:cart_item, cart: guest_cart, coffee: coffee, quantity: 2) }

      it "moves the items to the user cart" do
        user_cart.merge_guest_cart(guest_cart)
        expect(user_cart.cart_items.find_by(coffee: coffee).quantity).to eq(2)
      end

      it "destroys the guest cart" do
        user_cart # force evaluation before measuring the change
        expect { user_cart.merge_guest_cart(guest_cart) }
          .to change(Cart, :count).by(-1)
      end
    end

    context "when both carts have the same coffee" do
      before do
        create(:cart_item, cart: user_cart, coffee: coffee, quantity: 3)
        create(:cart_item, cart: guest_cart, coffee: coffee, quantity: 6)
      end

      it "sums the quantities" do
        user_cart.merge_guest_cart(guest_cart)
        expect(user_cart.cart_items.find_by(coffee: coffee).quantity).to eq(9)
      end
    end

    context "when summed quantity would exceed 10" do
      before do
        create(:cart_item, cart: user_cart, coffee: coffee, quantity: 7)
        create(:cart_item, cart: guest_cart, coffee: coffee, quantity: 6)
      end

      it "caps the quantity at 10" do
        user_cart.merge_guest_cart(guest_cart)
        expect(user_cart.cart_items.find_by(coffee: coffee).quantity).to eq(10)
      end
    end

    context "when the guest cart is nil" do
      it "does nothing" do
        expect { user_cart.merge_guest_cart(nil) }.not_to change(CartItem, :count)
      end
    end
  end

  describe "#total_cents" do
    let(:cart) { create(:cart, :for_user) }
    let(:coffee_a) { create(:coffee, price_cents: 1800) }
    let(:coffee_b) { create(:coffee, price_cents: 2200) }

    before do
      create(:cart_item, cart: cart, coffee: coffee_a, quantity: 2)
      create(:cart_item, cart: cart, coffee: coffee_b, quantity: 1)
    end

    it "returns the sum of (price * quantity) for all items" do
      expect(cart.total_cents).to eq((1800 * 2) + (2200 * 1))
    end

    context "when the cart is empty" do
      let(:empty_cart) { create(:cart, :for_user) }

      it "returns 0" do
        expect(empty_cart.total_cents).to eq(0)
      end
    end
  end

  describe "#item_count" do
    let(:cart) { create(:cart, :for_user) }

    before do
      create(:cart_item, cart: cart, quantity: 3)
      create(:cart_item, cart: cart, quantity: 2)
    end

    it "returns the total number of individual items" do
      expect(cart.item_count).to eq(5)
    end

    context "when the cart is empty" do
      let(:empty_cart) { create(:cart, :for_user) }

      it "returns 0" do
        expect(empty_cart.item_count).to eq(0)
      end
    end
  end
end
