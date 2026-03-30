class CreateCoffees < ActiveRecord::Migration[8.1]
  def change
    create_table :coffees do |t|
      t.string  :name,        null: false
      t.string  :slug,        null: false
      t.string  :origin,      null: false
      t.integer :roast_level, null: false, default: 2
      t.text    :description
      t.integer :price_cents, null: false
      t.boolean :active,      null: false, default: true
      t.integer :position,    null: false, default: 0

      t.timestamps
    end

    add_index :coffees, :slug,        unique: true
    add_index :coffees, :active
    add_index :coffees, :roast_level
    add_index :coffees, :position
  end
end
