module ShippoHelpers
  SHIPPO_RATE_FIXTURE = {
    "object_id"      => "rate_abc123",
    "provider"       => "USPS",
    "servicelevel"   => { "name" => "Priority Mail" },
    "amount"         => "7.99",
    "estimated_days" => 2
  }.freeze

  def stub_shippo_shipment_create(rates: [SHIPPO_RATE_FIXTURE])
    stub_request(:post, "https://api.goshippo.com/shipments/")
      .to_return(
        status: 200,
        body: {
          "object_status" => "SUCCESS",
          "rates"         => rates
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_shippo_shipment_error
    stub_request(:post, "https://api.goshippo.com/shipments/")
      .to_return(status: 400, body: { "detail" => "Invalid address" }.to_json,
                 headers: { "Content-Type" => "application/json" })
  end
end

RSpec.configure do |config|
  config.include ShippoHelpers
end
