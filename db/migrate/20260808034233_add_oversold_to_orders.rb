class AddOversoldToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :oversold, :boolean, null: false, default: false
  end
end
