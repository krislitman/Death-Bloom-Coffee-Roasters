RSpec.describe Coffee, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:coffee_tasting_notes).dependent(:destroy) }
    it { is_expected.to have_many(:tasting_notes).through(:coffee_tasting_notes) }
    it { is_expected.to have_many(:order_items) }
  end

  describe "validations" do
    subject { build(:coffee) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:origin) }
    it { is_expected.to validate_presence_of(:price_cents) }
    it { is_expected.to validate_numericality_of(:price_cents).is_greater_than(0) }
    it { is_expected.to validate_uniqueness_of(:slug).case_insensitive }
    it { is_expected.to validate_numericality_of(:stock_quantity).only_integer.is_greater_than_or_equal_to(0) }
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

  describe "#sold_count" do
    let(:coffee) { create(:coffee) }

    it "returns zero when the coffee has never been ordered" do
      expect(coffee.sold_count).to eq(0)
    end

    it "sums quantities across processing, shipped, and delivered orders" do
      create(:order_item, coffee: coffee, quantity: 2, order: create(:order, status: :processing))
      create(:order_item, coffee: coffee, quantity: 3, order: create(:order, status: :shipped))
      create(:order_item, coffee: coffee, quantity: 4, order: create(:order, status: :delivered))

      expect(coffee.sold_count).to eq(9)
    end

    it "excludes cancelled orders" do
      create(:order_item, coffee: coffee, quantity: 2, order: create(:order, status: :processing))
      create(:order_item, coffee: coffee, quantity: 5, order: create(:order, status: :cancelled))

      expect(coffee.sold_count).to eq(2)
    end

    it "ignores order items belonging to other coffees" do
      create(:order_item, coffee: create(:coffee), quantity: 7, order: create(:order))

      expect(coffee.sold_count).to eq(0)
    end
  end

  describe "#available_stock" do
    it "subtracts sold units from the stock quantity" do
      coffee = create(:coffee, stock_quantity: 10)
      create(:order_item, coffee: coffee, quantity: 4, order: create(:order))

      expect(coffee.available_stock).to eq(6)
    end

    it "goes negative when more has been sold than stocked" do
      coffee = create(:coffee, stock_quantity: 1)
      create(:order_item, coffee: coffee, quantity: 3, order: create(:order))

      expect(coffee.available_stock).to eq(-2)
    end
  end

  describe "#sold_out?" do
    it "is false when stock remains" do
      expect(create(:coffee, stock_quantity: 1)).not_to be_sold_out
    end

    it "is true when availability is exactly zero" do
      expect(create(:coffee, :out_of_stock)).to be_sold_out
    end

    it "is true when availability is negative" do
      coffee = create(:coffee, stock_quantity: 1)
      create(:order_item, coffee: coffee, quantity: 3, order: create(:order))

      expect(coffee).to be_sold_out
    end
  end

  describe "#in_stock?" do
    it "is the inverse of sold_out?" do
      expect(create(:coffee, stock_quantity: 5)).to be_in_stock
    end
  end

  describe ".preload_sold_counts" do
    it "assigns the sold count for each coffee" do
      sold      = create(:coffee)
      never_sold = create(:coffee)
      create(:order_item, coffee: sold, quantity: 6, order: create(:order))

      described_class.preload_sold_counts([sold, never_sold])

      expect(sold.sold_count).to eq(6)
    end

    it "assigns zero to coffees that have never sold" do
      never_sold = create(:coffee)

      described_class.preload_sold_counts([never_sold])

      expect(never_sold.sold_count).to eq(0)
    end

    it "issues a single query regardless of how many coffees are given" do
      coffees = create_list(:coffee, 3)
      create(:order_item, coffee: coffees.first, quantity: 2, order: create(:order))

      expect { described_class.preload_sold_counts(coffees) }.to issue_queries(1)
    end

    it "does not re-query a preloaded coffee with zero sales" do
      never_sold = create(:coffee)
      described_class.preload_sold_counts([never_sold])

      expect { never_sold.sold_count }.to issue_queries(0)
    end
  end

  describe "#formatted_price" do
    it "returns the price formatted as dollars" do
      coffee = build(:coffee, price_cents: 1850)
      expect(coffee.formatted_price).to eq("$18.50")
    end
  end

  describe "#price" do
    it "returns price_cents as dollars" do
      expect(build(:coffee, price_cents: 1850).price).to eq(18.5)
    end
  end

  describe "#price=" do
    it "stores dollars as cents" do
      coffee = build(:coffee)
      coffee.price = "18.50"
      expect(coffee.price_cents).to eq(1850)
    end

    it "rounds to the nearest cent" do
      coffee = build(:coffee)
      coffee.price = "18.999"
      expect(coffee.price_cents).to eq(1900)
    end
  end
end
