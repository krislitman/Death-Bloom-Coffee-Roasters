class User < ApplicationRecord
  include Billable

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :lockable,
         :timeoutable,
         :trackable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  enum :role, { customer: 0, admin: 1 }, default: :customer

  has_many :orders, dependent: :destroy

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_initialize.tap do |user|
      user.provider = auth.provider
      user.uid      = auth.uid
      user.email    = auth.info.email
      user.password = Devise.friendly_token[0, 20] if user.new_record?
      user.save!
    end
  end
end
