require "rails_helper"

RSpec.describe CartItem, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:cart) }
    it { is_expected.to belong_to(:coffee) }
  end

  describe "validations" do
    subject { create(:cart_item) }

    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0).only_integer }
    it { is_expected.to validate_numericality_of(:quantity).is_less_than_or_equal_to(10) }
    it { is_expected.to validate_uniqueness_of(:coffee_id).scoped_to(:cart_id) }
  end

  describe "#total_cents" do
    let(:coffee) { create(:coffee, price_cents: 1500) }
    let(:cart_item) { build(:cart_item, coffee: coffee, quantity: 3) }

    it "returns price_cents multiplied by quantity" do
      expect(cart_item.total_cents).to eq(4500)
    end
  end
end
