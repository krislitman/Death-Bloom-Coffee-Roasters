class CreatePaymentProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :processor,              null: false
      t.string :processor_customer_id,  null: false

      t.timestamps
    end

    add_index :payment_profiles, [:user_id, :processor], unique: true
  end
end
