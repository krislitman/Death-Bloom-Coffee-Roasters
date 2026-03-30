module Billable
  extend ActiveSupport::Concern

  included do
    has_many :payment_profiles, dependent: :destroy
  end

  def payment_profile_for(processor)
    payment_profiles.find_by(processor: processor.to_s)
  end

  def stripe_customer_id
    payment_profile_for(:stripe)&.processor_customer_id
  end

  def stripe_customer_id=(id)
    profile = payment_profiles.find_or_initialize_by(processor: "stripe")
    profile.processor_customer_id = id
    profile.save!
  end
end
