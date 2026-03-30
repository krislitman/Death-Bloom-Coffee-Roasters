class CreateTastingNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :tasting_notes do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :tasting_notes, :name, unique: true
  end
end
