class AddGuestSupportAndStripeSessionToOrders < ActiveRecord::Migration[8.1]
  def change
    change_column_null :orders, :user_id, true

    add_column :orders, :email,                    :string
    add_column :orders, :stripe_checkout_session_id, :string
    add_column :orders, :shipping_address_name,    :string
    add_column :orders, :shipping_address_line2,   :string
    add_column :orders, :shipping_address_country, :string

    add_index :orders, :stripe_checkout_session_id, unique: true
  end
end
