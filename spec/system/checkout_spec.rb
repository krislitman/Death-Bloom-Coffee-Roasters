require "rails_helper"

# NOTE: Tests that exercise Turbo Frame rate loading or the Stripe redirect
# require a JavaScript-capable driver (headless Chrome). Those examples are
# marked pending until Chrome is added to the Docker test environment.
# All non-JS paths are covered by spec/requests/checkouts_spec.rb.

RSpec.describe "Checkout flow", type: :system do
  let(:coffee) { create(:coffee, name: "Ethiopia Yirgacheffe", price_cents: 1800) }
  let(:cart)   { create(:cart) }

  before do
    coffee
    create(:cart_item, cart: cart, coffee: coffee)
    allow_any_instance_of(ApplicationController).to receive(:current_cart).and_return(cart)
    driven_by :rack_test
  end

  describe "empty cart guard" do
    before do
      empty_cart = create(:cart)
      allow_any_instance_of(ApplicationController).to receive(:current_cart).and_return(empty_cart)
    end

    it "redirects to the cart page when the cart is empty" do
      visit checkout_path
      expect(page).to have_current_path(cart_path)
    end
  end

  describe "GET /checkout (show)" do
    it "displays the order summary with cart items" do
      visit checkout_path
      expect(page).to have_content("Ethiopia Yirgacheffe")
    end

    it "displays the address form" do
      visit checkout_path
      expect(page).to have_field("destination[email]")
      expect(page).to have_field("destination[name]")
      expect(page).to have_field("destination[line1]")
    end

    it "displays the Get Shipping Rates button" do
      visit checkout_path
      expect(page).to have_button("Get Shipping Rates")
    end
  end

  describe "GET /checkout/success" do
    it "renders the order confirmed message" do
      visit success_checkout_path
      expect(page).to have_content("Order confirmed")
    end
  end

  describe "GET /checkout/cancel" do
    it "renders the payment cancelled message" do
      visit cancel_checkout_path
      expect(page).to have_content("Payment cancelled")
    end

    it "has a link back to the cart" do
      visit cancel_checkout_path
      expect(page).to have_link("Return to cart", href: cart_path)
    end
  end

  describe "Turbo Frame rate loading (requires JavaScript)", :pending do
    it "fetches and displays shipping rates after address entry"
    it "allows selecting a rate and submitting to Stripe"
  end
end
