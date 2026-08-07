require "rails_helper"

RSpec.describe Order, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:order_items).dependent(:destroy) }
    it { is_expected.to have_many(:coffees).through(:order_items) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }

    it "rejects a duplicate order_number" do
      existing = create(:order)
      duplicate = build(:order, order_number: existing.order_number)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:order_number]).to be_present
    end

    it { is_expected.to validate_numericality_of(:total_cents).is_greater_than_or_equal_to(0) }

    context "with an invalid email" do
      it "is invalid" do
        order = build(:order, email: "not-an-email")
        expect(order).not_to be_valid
        expect(order.errors[:email]).to be_present
      end
    end

    context "with a valid email" do
      it "is valid" do
        order = build(:order, email: "guest@example.com")
        expect(order).to be_valid
      end
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, processing: 1, shipped: 2, delivered: 3, cancelled: 4) }
  end

  describe "guest orders" do
    it "is valid without a user" do
      order = build(:order, :guest)
      expect(order).to be_valid
    end
  end

  describe "#assign_order_number" do
    it "generates a DB- prefixed order number on create" do
      order = create(:order)
      expect(order.order_number).to match(/\ADB-[0-9A-F]{6}\z/)
    end

    it "does not overwrite an existing order number" do
      order = create(:order, order_number: "DB-CUSTOM")
      expect(order.order_number).to eq("DB-CUSTOM")
    end

    it "generates unique order numbers for concurrent orders" do
      numbers = 10.times.map { create(:order).order_number }
      expect(numbers.uniq.length).to eq(10)
    end
  end

  describe "#total" do
    it "returns total_cents as a float in dollars" do
      order = build(:order, total_cents: 1800)
      expect(order.total).to eq(18.0)
    end
  end

  describe "fulfillment timestamps" do
    context "when status changes to shipped" do
      it "stamps shipped_at" do
        order = create(:order, status: :processing)
        expect { order.update!(status: :shipped) }.to change(order, :shipped_at).from(nil)
      end

      it "does not overwrite an existing shipped_at" do
        shipped = create(:order, status: :shipped)
        original = shipped.shipped_at
        shipped.update!(carrier: "UPS")
        expect(shipped.reload.shipped_at).to be_within(1.second).of(original)
      end
    end

    context "when status changes to delivered" do
      it "stamps delivered_at" do
        order = create(:order, status: :shipped)
        expect { order.update!(status: :delivered) }.to change(order, :delivered_at).from(nil)
      end

      it "backfills shipped_at if it was never set" do
        order = create(:order, status: :processing)
        order.update!(status: :delivered)
        expect(order.shipped_at).to be_present
      end
    end

    context "when status stays processing" do
      it "leaves the timestamps nil" do
        order = create(:order, status: :processing)
        order.update!(carrier: "USPS")
        expect(order.shipped_at).to be_nil
      end
    end
  end

  describe "#tracked?" do
    context "without a tracking number" do
      it "returns false" do
        expect(build(:order, tracking_number: nil)).not_to be_tracked
      end
    end

    context "with a tracking number" do
      it "returns true" do
        expect(build(:order, tracking_number: "1Z999")).to be_tracked
      end
    end
  end

  describe "#tracking_url" do
    context "without a tracking number" do
      it "returns nil" do
        expect(build(:order, tracking_number: nil).tracking_url).to be_nil
      end
    end

    context "with a known carrier" do
      it "builds the carrier tracking URL" do
        order = build(:order, carrier: "UPS", tracking_number: "1Z999AA10123456784")
        expect(order.tracking_url).to eq("https://www.ups.com/track?tracknum=1Z999AA10123456784")
      end
    end

    context "with an unknown carrier" do
      it "returns nil" do
        order = build(:order, carrier: "PonyExpress", tracking_number: "ABC123")
        expect(order.tracking_url).to be_nil
      end
    end
  end
end
