class CreateCoffeeTastingNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :coffee_tasting_notes do |t|
      t.references :coffee,       null: false, foreign_key: true
      t.references :tasting_note, null: false, foreign_key: true

      t.timestamps
    end

    add_index :coffee_tasting_notes, [:coffee_id, :tasting_note_id], unique: true
  end
end
