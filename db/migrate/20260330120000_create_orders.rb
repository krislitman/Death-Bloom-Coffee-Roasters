class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.bigint   :user_id, null: false
      t.string   :order_number, null: false
      t.integer  :status, null: false, default: 0
      t.integer  :total_cents, null: false, default: 0
      t.string   :shipping_address_line1
      t.string   :shipping_address_city
      t.string   :shipping_address_state
      t.string   :shipping_address_zip
      t.timestamps
    end

    add_index :orders, :user_id
    add_index :orders, :order_number, unique: true
    add_foreign_key :orders, :users
  end
end
