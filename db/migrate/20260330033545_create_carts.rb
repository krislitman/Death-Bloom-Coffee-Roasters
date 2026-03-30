class CreateCarts < ActiveRecord::Migration[8.1]
  def change
    create_table :carts do |t|
      t.references :user, null: true, foreign_key: true
      t.string :session_token

      t.timestamps
    end

    add_index :carts, :session_token, unique: true
  end
end
