require "rails_helper"

RSpec.describe ShippoRateService do
  let(:cart)        { create(:cart) }
  let(:coffee)      { create(:coffee, price_cents: 1800) }
  let(:destination) do
    {
      name:    "Jane Doe",
      line1:   "123 Main St",
      line2:   nil,
      city:    "Denver",
      state:   "CO",
      zip:     "80203",
      country: "US"
    }
  end

  before { create(:cart_item, cart: cart, coffee: coffee, quantity: 2) }

  describe "#call" do
    context "when Shippo returns rates" do
      before { stub_shippo_shipment_create }

      it "returns an array of rate hashes" do
        rates = described_class.new(cart: cart, destination: destination).call
        expect(rates).to be_an(Array)
        expect(rates.length).to eq(1)
      end

      it "includes the expected keys on each rate" do
        rate = described_class.new(cart: cart, destination: destination).call.first
        expect(rate).to include(:id, :carrier, :service, :amount_cents, :estimated_days)
      end

      it "converts the Shippo amount string to cents" do
        rate = described_class.new(cart: cart, destination: destination).call.first
        expect(rate[:amount_cents]).to eq(799)
      end

      it "maps carrier and service from the Shippo response" do
        rate = described_class.new(cart: cart, destination: destination).call.first
        expect(rate[:carrier]).to eq("USPS")
        expect(rate[:service]).to eq("Priority Mail")
      end
    end

    context "when Shippo returns multiple rates" do
      let(:rates) do
        [
          ShippoHelpers::SHIPPO_RATE_FIXTURE,
          ShippoHelpers::SHIPPO_RATE_FIXTURE.merge("object_id" => "rate_xyz", "provider" => "UPS", "amount" => "12.50")
        ]
      end

      before { stub_shippo_shipment_create(rates: rates) }

      it "returns all rates" do
        result = described_class.new(cart: cart, destination: destination).call
        expect(result.length).to eq(2)
      end
    end

    context "when Shippo returns an error" do
      before { stub_shippo_shipment_error }

      it "raises a ShippoRateService::Error" do
        expect {
          described_class.new(cart: cart, destination: destination).call
        }.to raise_error(ShippoRateService::Error)
      end
    end
  end
end
