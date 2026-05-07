class CreatePendingCheckouts < ActiveRecord::Migration[8.1]
  def change
    create_table :pending_checkouts do |t|
      t.references :cart, null: false, foreign_key: true
      t.string :token,                      null: false
      t.string :email,                      null: false
      t.string :shipping_address_name,      null: false
      t.string :shipping_address_line1,     null: false
      t.string :shipping_address_line2
      t.string :shipping_address_city,      null: false
      t.string :shipping_address_state,     null: false
      t.string :shipping_address_zip,       null: false
      t.string :shipping_address_country,   null: false, default: "US"
      t.string  :shippo_rate_id,            null: false
      t.integer :shippo_rate_amount_cents,  null: false
      t.string  :shippo_rate_carrier
      t.string  :shippo_rate_service
      t.datetime :expires_at

      t.timestamps
    end

    add_index :pending_checkouts, :token, unique: true
  end
end
