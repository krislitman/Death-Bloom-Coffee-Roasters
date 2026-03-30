class PaymentProfile < ApplicationRecord
  belongs_to :user

  validates :processor,             presence: true
  validates :processor_customer_id, presence: true
  validates :processor, uniqueness: { scope: :user_id }
end
