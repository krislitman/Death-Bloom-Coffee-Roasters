require "rails_helper"

RSpec.describe "Admin::Orders", type: :request do
  let(:admin)  { create(:user, :admin) }
  let(:coffee) { create(:coffee) }
  let(:order)  { create(:order, status: :processing) }

  before { create(:order_item, order: order, coffee: coffee) }

  describe "GET /admin/orders" do
    context "as an admin" do
      before { sign_in admin }

      it "lists orders" do
        get admin_orders_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(order.order_number)
      end
    end

    context "as a non-admin" do
      it "redirects to root" do
        sign_in create(:user)
        get admin_orders_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "as a guest" do
      it "redirects to sign in" do
        get admin_orders_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /admin/orders/:id" do
    before { sign_in admin }

    it "renders the fulfillment form" do
      get admin_order_path(order)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Fulfillment")
    end
  end

  describe "PATCH /admin/orders/:id" do
    before { sign_in admin }

    it "records status, carrier, and tracking number" do
      patch admin_order_path(order),
            params: { order: { status: "shipped", carrier: "UPS", tracking_number: "1Z999AA10123456784" } }

      order.reload
      aggregate_failures do
        expect(order).to be_shipped
        expect(order.carrier).to eq("UPS")
        expect(order.tracking_number).to eq("1Z999AA10123456784")
        expect(order.shipped_at).to be_present
      end
    end

    it "redirects to the order on success" do
      patch admin_order_path(order), params: { order: { status: "processing" } }
      expect(response).to redirect_to(admin_order_path(order))
    end

    context "as a non-admin" do
      it "does not update the order" do
        sign_in create(:user)
        patch admin_order_path(order), params: { order: { status: "shipped" } }
        expect(order.reload).not_to be_shipped
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
