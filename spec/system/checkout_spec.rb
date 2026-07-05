require "rails_helper"

RSpec.describe "Checkout flow", type: :system do
  before { driven_by :rack_test }

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

  describe "Checkout redirect to Stripe (requires JavaScript)", :pending do
    it "redirects to the Stripe hosted checkout after clicking Checkout"
  end
end
