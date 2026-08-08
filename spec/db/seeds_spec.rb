require "rails_helper"

RSpec.describe "db/seeds" do
  let(:demo_coffee_names) { [ "Midnight Sun", "Aurora Washed", "Dark Hollow" ] }
  let(:edwin_norena_names) do
    [ "Edwin Norena — Light Roast", "Edwin Norena — Medium Roast", "Edwin Norena — Dark Roast" ]
  end

  def load_seeds
    original_stdout = $stdout
    $stdout = StringIO.new
    Rails.application.load_seed
  ensure
    $stdout = original_stdout
  end

  def with_env(values)
    originals = values.keys.index_with { |key| ENV[key] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    originals.each { |key, value| ENV[key] = value }
  end

  context "in production" do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    end

    it "does not create the development admin user" do
      load_seeds

      expect(User.exists?(email: "admin@dev.com")).to be false
    end

    it "does not create the demo coffees" do
      load_seeds

      expect(Coffee.where(name: demo_coffee_names)).to be_empty
    end

    it "creates the Edwin Norena coffees" do
      load_seeds

      expect(Coffee.where(name: edwin_norena_names).count).to eq 3
    end

    it "gives the Edwin Norena coffees stock" do
      load_seeds

      expect(Coffee.where(name: edwin_norena_names).pluck(:stock_quantity)).to all(be_positive)
    end

    it "leaves the inventory flag disabled" do
      load_seeds

      expect(Flipper.enabled?(:inventory)).to be false
    end

    it "creates the feature flags" do
      load_seeds

      expect(Flipper.features.map(&:key)).to include("subscriptions", "newsletter", "maintenance_mode", "inventory")
    end

    it "creates the tasting note vocabulary" do
      load_seeds

      expect(TastingNote.where(name: [ "stone fruit", "honey", "floral brightness" ]).count).to eq 3
    end

    context "when ADMIN_EMAIL and ADMIN_PASSWORD are set" do
      it "creates an admin user with those credentials" do
        with_env("ADMIN_EMAIL" => "owner@deathbloomcoffeeroasters.com", "ADMIN_PASSWORD" => "s3cret-launch-pw") do
          load_seeds
        end

        expect(User.find_by(email: "owner@deathbloomcoffeeroasters.com")).to be_admin
      end
    end

    context "when the admin credentials are absent" do
      it "creates no admin user" do
        with_env("ADMIN_EMAIL" => nil, "ADMIN_PASSWORD" => nil) do
          load_seeds
        end

        expect(User.where(role: :admin)).to be_empty
      end
    end

    context "when the admin already exists" do
      it "does not reset the existing password" do
        existing = create(:user, :admin,
                          email: "owner@deathbloomcoffeeroasters.com",
                          password: "original-password",
                          password_confirmation: "original-password")

        with_env("ADMIN_EMAIL" => "owner@deathbloomcoffeeroasters.com", "ADMIN_PASSWORD" => "rotated-password") do
          load_seeds
        end

        expect(existing.reload.valid_password?("original-password")).to be true
      end
    end
  end

  context "in development" do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
    end

    it "creates the development admin user" do
      load_seeds

      expect(User.find_by(email: "admin@dev.com")).to be_admin
    end

    it "creates the demo coffees" do
      load_seeds

      expect(Coffee.where(name: demo_coffee_names).count).to eq 3
    end

    it "creates the Edwin Norena coffees" do
      load_seeds

      expect(Coffee.where(name: edwin_norena_names).count).to eq 3
    end
  end

  describe "idempotency" do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    end

    it "does not duplicate coffees when run twice" do
      load_seeds

      expect { load_seeds }.not_to change(Coffee, :count)
    end

    it "does not duplicate tasting notes when run twice" do
      load_seeds

      expect { load_seeds }.not_to change(TastingNote, :count)
    end
  end
end
