class Order < ApplicationRecord
  belongs_to :user, optional: true
  has_many :order_items, dependent: :destroy
  has_many :coffees, through: :order_items

  enum :status, { pending: 0, processing: 1, shipped: 2, delivered: 3, cancelled: 4 }

  validates :order_number, presence: true, uniqueness: true
  validates :total_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  before_validation :assign_order_number, on: :create

  CARRIER_TRACKING_URLS = {
    "usps"  => "https://tools.usps.com/go/TrackConfirmAction?tLabels=%s",
    "ups"   => "https://www.ups.com/track?tracknum=%s",
    "fedex" => "https://www.fedex.com/fedextrack/?trknbr=%s"
  }.freeze

  def total
    total_cents / 100.0
  end

  def tracked?
    tracking_number.present?
  end

  def tracking_url
    return unless tracked?

    template = CARRIER_TRACKING_URLS[carrier.to_s.downcase]
    format(template, ERB::Util.url_encode(tracking_number)) if template
  end

  private

  def assign_order_number
    self.order_number ||= "DB-#{SecureRandom.hex(3).upcase}"
  end
end
