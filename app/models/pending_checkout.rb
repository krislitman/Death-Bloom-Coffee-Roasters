class PendingCheckout < ApplicationRecord
  belongs_to :cart

  before_validation :assign_token, on: :create

  validates :token, presence: true, uniqueness: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :shipping_address_name,    presence: true
  validates :shipping_address_line1,   presence: true
  validates :shipping_address_city,    presence: true
  validates :shipping_address_state,   presence: true
  validates :shipping_address_zip,     presence: true
  validates :shipping_address_country, presence: true
  validates :shippo_rate_id,           presence: true
  validates :shippo_rate_amount_cents, numericality: { greater_than_or_equal_to: 0 }

  private

  def assign_token
    self.token ||= SecureRandom.hex(16)
  end
end
