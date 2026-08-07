require "rails_helper"

RSpec.describe "Admin::Coffees", type: :request do
  let(:admin) { create(:user, :admin) }

  describe "authorization" do
    it "redirects a guest to sign in" do
      get admin_coffees_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects a non-admin to root" do
      sign_in create(:user)
      get admin_coffees_path
      expect(response).to redirect_to(root_path)
    end
  end

  context "as an admin" do
    before { sign_in admin }

    describe "GET /admin/coffees" do
      it "lists coffees" do
        coffee = create(:coffee, name: "Ethiopia Guji")
        get admin_coffees_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Ethiopia Guji")
      end
    end

    describe "GET /admin/coffees/new" do
      it "renders the form" do
        get new_admin_coffee_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/coffees" do
      let(:note) { TastingNote.create!(name: "cherry") }

      let(:valid_params) do
        { coffee: { name: "Colombia Huila", origin: "Colombia", roast_level: "medium",
                    price: "19.00", processing: "Washed", active: "1",
                    tasting_note_ids: [note.id] } }
      end

      it "creates a coffee with price converted to cents" do
        expect { post admin_coffees_path, params: valid_params }.to change(Coffee, :count).by(1)
        coffee = Coffee.find_by(name: "Colombia Huila")
        expect(coffee.price_cents).to eq(1900)
        expect(coffee.tasting_notes).to include(note)
        expect(response).to redirect_to(admin_coffees_path)
      end

      it "re-renders the form on invalid input" do
        post admin_coffees_path, params: { coffee: { name: "", origin: "", price: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "GET /admin/coffees/:slug/edit" do
      it "renders the edit form" do
        coffee = create(:coffee)
        get edit_admin_coffee_path(coffee)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "PATCH /admin/coffees/:slug" do
      it "updates the coffee" do
        coffee = create(:coffee, price_cents: 1800)
        patch admin_coffee_path(coffee), params: { coffee: { price: "22.00" } }
        expect(coffee.reload.price_cents).to eq(2200)
        expect(response).to redirect_to(admin_coffees_path)
      end
    end

    describe "DELETE /admin/coffees/:slug" do
      it "deletes the coffee" do
        coffee = create(:coffee)
        expect { delete admin_coffee_path(coffee) }.to change(Coffee, :count).by(-1)
        expect(response).to redirect_to(admin_coffees_path)
      end
    end
  end
end
