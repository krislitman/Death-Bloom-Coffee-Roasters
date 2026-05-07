require "rails_helper"

RSpec.describe OrderMailer, type: :mailer do
  let(:order) do
    create(:order,
      email:                   "guest@example.com",
      total_cents:             2599,
      shipping_address_name:   "Jane Doe",
      shipping_address_line1:  "123 Main St",
      shipping_address_city:   "Denver",
      shipping_address_state:  "CO",
      shipping_address_zip:    "80203",
      shipping_address_country: "US"
    )
  end

  before { create(:order_item, order: order) }

  describe "#confirmation" do
    subject(:mail) { described_class.confirmation(order) }

    it "sends to the order email" do
      expect(mail.to).to eq([ "guest@example.com" ])
    end

    it "includes the order number in the subject" do
      expect(mail.subject).to include(order.order_number)
    end

    it "includes the order number in the body" do
      expect(mail.body.encoded).to include(order.order_number)
    end

    it "includes the order total in the body" do
      expect(mail.body.encoded).to include("25.99")
    end

    it "includes the shipping address in the body" do
      expect(mail.body.encoded).to include("123 Main St")
      expect(mail.body.encoded).to include("Denver")
    end
  end
end
