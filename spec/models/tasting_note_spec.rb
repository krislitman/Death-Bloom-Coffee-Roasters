RSpec.describe TastingNote, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:coffee_tasting_notes).dependent(:destroy) }
    it { is_expected.to have_many(:coffees).through(:coffee_tasting_notes) }
  end

  describe "validations" do
    subject { build(:tasting_note) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end
end
