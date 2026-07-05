class AddProcessingToCoffees < ActiveRecord::Migration[8.1]
  def change
    add_column :coffees, :processing, :string
  end
end
