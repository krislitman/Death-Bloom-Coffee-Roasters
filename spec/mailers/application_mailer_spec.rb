require "rails_helper"

RSpec.describe ApplicationMailer, type: :mailer do
  describe "defaults" do
    it "does not send from the Rails placeholder address" do
      expect(described_class.default[:from]).not_to include("example.com")
    end

    it "sends from the configured mail address" do
      expect(described_class.default[:from]).to eq(ENV.fetch("MAIL_FROM", "deathbloomcoffeeroasters@proton.me"))
    end

    it "sets a Reply-To so replies reach support" do
      expect(described_class.default[:reply_to]).to eq(ENV.fetch("SUPPORT_EMAIL", "deathbloomcoffeeroasters@proton.me"))
    end
  end
end
