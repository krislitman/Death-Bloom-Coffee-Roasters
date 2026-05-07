class ShippoRateService
  Error = Class.new(StandardError)

  WEIGHT_OZ_PER_BAG = 16

  ORIGIN = {
    name:    ENV.fetch("SHIPPING_FROM_NAME",    "Death Bloom Coffee Roasters"),
    street1: ENV.fetch("SHIPPING_FROM_STREET1", ""),
    city:    ENV.fetch("SHIPPING_FROM_CITY",    "Denver"),
    state:   ENV.fetch("SHIPPING_FROM_STATE",   "CO"),
    zip:     ENV.fetch("SHIPPING_FROM_ZIP",     ""),
    country: ENV.fetch("SHIPPING_FROM_COUNTRY", "US"),
    phone:   ENV.fetch("SHIPPING_FROM_PHONE",   "")
  }.freeze

  def initialize(cart:, destination:)
    @cart        = cart
    @destination = destination
  end

  def call
    Shippo::API.token = ENV.fetch("SHIPPO_API_KEY", "")

    shipment = Shippo::Shipment.create(
      address_from: ORIGIN.dup,
      address_to:   {
        name:    @destination[:name],
        street1: @destination[:line1],
        street2: @destination[:line2],
        city:    @destination[:city],
        state:   @destination[:state],
        zip:     @destination[:zip],
        country: @destination[:country] || "US"
      },
      parcels: [ parcel ],
      async:   false
    )

    raise Error, "Shippo shipment failed" unless shipment["object_status"] == "SUCCESS"

    shipment["rates"].map do |rate|
      {
        id:             rate["object_id"],
        carrier:        rate["provider"],
        service:        rate["servicelevel"]["name"],
        amount_cents:   (rate["amount"].to_f * 100).round,
        estimated_days: rate["estimated_days"]
      }
    end
  rescue Shippo::Exceptions::APIServerError, Shippo::Exceptions::ConnectionError => e
    raise Error, e.message
  end

  private

  def parcel
    total_weight_oz = @cart.cart_items.sum { |item| item.quantity * WEIGHT_OZ_PER_BAG }
    {
      length:        "9",
      width:         "6",
      height:        "3",
      distance_unit: "in",
      weight:        total_weight_oz,
      mass_unit:     "oz"
    }
  end
end
