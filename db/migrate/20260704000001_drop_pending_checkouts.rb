class DropPendingCheckouts < ActiveRecord::Migration[8.1]
  def change
    drop_table :pending_checkouts do |t|
      t.bigint "cart_id", null: false
      t.string "email", null: false
      t.datetime "expires_at"
      t.string "shipping_address_city", null: false
      t.string "shipping_address_country", default: "US", null: false
      t.string "shipping_address_line1", null: false
      t.string "shipping_address_line2"
      t.string "shipping_address_name", null: false
      t.string "shipping_address_state", null: false
      t.string "shipping_address_zip", null: false
      t.integer "shippo_rate_amount_cents", null: false
      t.string "shippo_rate_carrier"
      t.string "shippo_rate_id", null: false
      t.string "shippo_rate_service"
      t.string "token", null: false
      t.timestamps
      t.index ["cart_id"], name: "index_pending_checkouts_on_cart_id"
      t.index ["token"], name: "index_pending_checkouts_on_token", unique: true
    end
  end
end
