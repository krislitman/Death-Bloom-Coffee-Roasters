class AddTrackingToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :carrier, :string
    add_column :orders, :tracking_number, :string
    add_column :orders, :shipped_at, :datetime
    add_column :orders, :delivered_at, :datetime
  end
end
