require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:admin) { create(:user, :admin) }

  describe "authorization" do
    it "redirects a guest to sign in" do
      get admin_users_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects a non-admin to root" do
      sign_in create(:user)
      get admin_users_path
      expect(response).to redirect_to(root_path)
    end
  end

  context "as an admin" do
    before { sign_in admin }

    describe "GET /admin/users" do
      it "lists users" do
        customer = create(:user, email: "shopper@example.com")
        get admin_users_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("shopper@example.com")
      end
    end

    describe "GET /admin/users/:id" do
      it "shows the user and their orders" do
        customer = create(:user)
        order = create(:order, user: customer)
        get admin_user_path(customer)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(order.order_number)
      end
    end

    describe "PATCH /admin/users/:id" do
      it "promotes a customer to admin" do
        customer = create(:user, role: :customer)
        patch admin_user_path(customer), params: { user: { role: "admin" } }
        expect(customer.reload).to be_admin
        expect(response).to redirect_to(admin_user_path(customer))
      end
    end
  end
end
