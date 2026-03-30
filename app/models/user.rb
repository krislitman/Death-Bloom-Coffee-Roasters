class User < ApplicationRecord
  include Billable

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :confirmable,
         :lockable,
         :timeoutable,
         :trackable

  enum :role, { customer: 0, admin: 1 }, default: :customer
end
