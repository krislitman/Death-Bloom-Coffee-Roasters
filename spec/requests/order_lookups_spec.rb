require "rails_helper"

RSpec.describe "Order lookups", type: :request do
  describe "GET /orders/lookup" do
    it "renders the lookup form" do
      get order_lookup_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Track your order")
    end
  end

  describe "POST /orders/lookup" do
    let(:coffee) { create(:coffee) }
    let(:order)  { create(:order, :guest, email: "guest@example.com") }

    before { create(:order_item, order: order, coffee: coffee) }

    context "with a matching order number and email" do
      it "shows the order" do
        post order_lookup_path, params: { order_number: order.order_number, email: "guest@example.com" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(order.order_number)
      end

      it "matches the email case-insensitively and ignores surrounding whitespace" do
        post order_lookup_path, params: { order_number: " #{order.order_number.downcase} ", email: "GUEST@example.com" }
        expect(response.body).to include(order.order_number)
      end
    end

    context "with a wrong email" do
      it "does not reveal the order details" do
        post order_lookup_path, params: { order_number: order.order_number, email: "attacker@example.com" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).not_to include(coffee.name)
      end
    end

    context "with an unknown order number" do
      it "renders the form with an error" do
        post order_lookup_path, params: { order_number: "DB-000000", email: "guest@example.com" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("find an order matching")
      end
    end
  end
end
