require "rails_helper"

RSpec.describe PendingCheckout, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:cart) }
  end

  describe "validations" do
    subject { build(:pending_checkout) }

    it "rejects a duplicate token" do
      existing = create(:pending_checkout)
      duplicate = build(:pending_checkout, token: existing.token)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:token]).to be_present
    end
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:shipping_address_name) }
    it { is_expected.to validate_presence_of(:shipping_address_line1) }
    it { is_expected.to validate_presence_of(:shipping_address_city) }
    it { is_expected.to validate_presence_of(:shipping_address_state) }
    it { is_expected.to validate_presence_of(:shipping_address_zip) }
    it { is_expected.to validate_presence_of(:shipping_address_country) }
    it { is_expected.to validate_presence_of(:shippo_rate_id) }
    it { is_expected.to validate_numericality_of(:shippo_rate_amount_cents).is_greater_than_or_equal_to(0) }

    context "with an invalid email" do
      it "is invalid" do
        pc = build(:pending_checkout, email: "bad")
        expect(pc).not_to be_valid
        expect(pc.errors[:email]).to be_present
      end
    end
  end

  describe "#assign_token" do
    it "generates a token before validation on create" do
      pc = build(:pending_checkout, token: nil)
      pc.valid?
      expect(pc.token).to be_present
    end

    it "does not overwrite an existing token" do
      pc = build(:pending_checkout, token: "my-token")
      pc.valid?
      expect(pc.token).to eq("my-token")
    end

    it "generates unique tokens" do
      tokens = 5.times.map { create(:pending_checkout, cart: create(:cart)).token }
      expect(tokens.uniq.length).to eq(5)
    end
  end
end
