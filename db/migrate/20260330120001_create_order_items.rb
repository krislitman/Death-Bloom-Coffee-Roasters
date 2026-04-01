class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.bigint   :order_id, null: false
      t.bigint   :coffee_id, null: false
      t.integer  :quantity, null: false, default: 1
      t.integer  :unit_price_cents, null: false
      t.timestamps
    end

    add_index :order_items, :order_id
    add_index :order_items, :coffee_id
    add_foreign_key :order_items, :orders
    add_foreign_key :order_items, :coffees
  end
end
