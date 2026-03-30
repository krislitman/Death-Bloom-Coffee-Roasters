RSpec.describe Coffee, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:coffee_tasting_notes).dependent(:destroy) }
    it { is_expected.to have_many(:tasting_notes).through(:coffee_tasting_notes) }
  end

  describe "validations" do
    subject { build(:coffee) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:origin) }
    it { is_expected.to validate_presence_of(:price_cents) }
    it { is_expected.to validate_numericality_of(:price_cents).is_greater_than(0) }
    it { is_expected.to validate_uniqueness_of(:slug).case_insensitive }
  end

  describe "enums" do
    it do
      is_expected.to define_enum_for(:roast_level)
        .with_values(light: 0, medium_light: 1, medium: 2, medium_dark: 3, dark: 4)
    end
  end

  describe "slug generation" do
    context "when slug is blank" do
      it "generates a slug from the name before validation" do
        coffee = build(:coffee, name: "Ethiopian Yirgacheffe", slug: nil)
        coffee.valid?
        expect(coffee.slug).to eq("ethiopian-yirgacheffe")
      end
    end

    context "when slug is already set" do
      it "does not overwrite an existing slug" do
        coffee = build(:coffee, name: "Ethiopian Yirgacheffe", slug: "my-custom-slug")
        coffee.valid?
        expect(coffee.slug).to eq("my-custom-slug")
      end
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active coffees" do
        active   = create(:coffee)
        inactive = create(:coffee, :inactive)
        expect(described_class.active).to include(active)
        expect(described_class.active).not_to include(inactive)
      end
    end

    describe ".ordered" do
      it "returns coffees sorted by position then name" do
        second = create(:coffee, position: 1, name: "B Coffee")
        first  = create(:coffee, position: 0, name: "A Coffee")
        expect(described_class.ordered.first).to eq(first)
        expect(described_class.ordered.second).to eq(second)
      end
    end
  end

  describe "#formatted_price" do
    it "returns the price formatted as dollars" do
      coffee = build(:coffee, price_cents: 1850)
      expect(coffee.formatted_price).to eq("$18.50")
    end
  end
end
