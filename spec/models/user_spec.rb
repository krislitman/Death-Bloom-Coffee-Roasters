RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:password) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:role).with_values(customer: 0, admin: 1) }
  end

  describe "defaults" do
    it "defaults to customer role" do
      expect(described_class.new.role).to eq("customer")
    end
  end

  describe "#admin?" do
    it "returns true for admin role" do
      expect(build(:user, :admin)).to be_admin
    end

    it "returns false for customer role" do
      expect(build(:user)).not_to be_admin
    end
  end
end
