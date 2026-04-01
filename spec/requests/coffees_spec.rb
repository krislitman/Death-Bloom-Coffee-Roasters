# frozen_string_literal: true

RSpec.describe "Coffees", type: :request do
  describe "GET /coffees" do
    let!(:ethiopian) { create(:coffee, name: "Ethiopian Yirgacheffe", roast_level: :light,  position: 0) }
    let!(:guatemalan) { create(:coffee, name: "Guatemalan Huehue",    roast_level: :medium, position: 1) }
    let!(:inactive)   { create(:coffee, :inactive) }

    it "returns 200" do
      get coffees_path
      expect(response).to have_http_status(:ok)
    end

    it "displays active coffees" do
      get coffees_path
      expect(response.body).to include("Ethiopian Yirgacheffe")
      expect(response.body).to include("Guatemalan Huehue")
    end

    it "does not display inactive coffees" do
      get coffees_path
      expect(response.body).not_to include(inactive.name)
    end

    it "renders an add-to-cart form for each active coffee" do
      get coffees_path
      expect(response.body).to include(cart_cart_items_path)
    end

    context "when filtering by roast level" do
      it "returns only coffees matching the roast level" do
        get coffees_path, params: { roast_level: "light" }
        expect(response.body).to include("Ethiopian Yirgacheffe")
        expect(response.body).not_to include("Guatemalan Huehue")
      end

      it "responds to Turbo Frame requests" do
        get coffees_path,
            params: { roast_level: "light" },
            headers: { "Turbo-Frame" => "coffees-grid" }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /coffees/:slug" do
    let!(:coffee) { create(:coffee, :with_tasting_notes) }

    it "returns 200" do
      get coffee_path(coffee)
      expect(response).to have_http_status(:ok)
    end

    it "displays the coffee name" do
      get coffee_path(coffee)
      expect(response.body).to include(coffee.name)
    end

    it "displays the formatted price" do
      get coffee_path(coffee)
      expect(response.body).to include(coffee.formatted_price)
    end

    it "displays tasting notes" do
      get coffee_path(coffee)
      expect(response.body).to include("Chocolate")
    end

    it "displays the origin" do
      get coffee_path(coffee)
      expect(response.body).to include(coffee.origin)
    end

    it "displays the roast level" do
      get coffee_path(coffee)
      expect(response.body).to include(coffee.roast_level.humanize)
    end

    it "displays the description" do
      get coffee_path(coffee)
      expect(response.body).to include(coffee.description)
    end

    it "renders an add-to-cart form" do
      get coffee_path(coffee)
      expect(response.body).to include(cart_cart_items_path)
    end

    context "when the coffee is inactive" do
      let!(:inactive) { create(:coffee, :inactive) }

      it "returns 404" do
        get coffee_path(inactive)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with an unknown slug" do
      it "returns 404" do
        get coffee_path("does-not-exist")
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
