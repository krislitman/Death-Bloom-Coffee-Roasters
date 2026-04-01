class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :coffees, through: :order_items

  enum :status, { pending: 0, processing: 1, shipped: 2, delivered: 3, cancelled: 4 }

  validates :order_number, presence: true, uniqueness: true
  validates :total_cents, numericality: { greater_than_or_equal_to: 0 }

  before_validation :assign_order_number, on: :create

  def total
    total_cents / 100.0
  end

  private

  def assign_order_number
    self.order_number ||= "DB-#{format('%06d', self.class.count + 1)}"
  end
end
