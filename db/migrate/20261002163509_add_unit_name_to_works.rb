class AddUnitNameToWorks < ActiveRecord::Migration[8.1]
  def change
    add_column :works, :unit_name, :string, null: false, default: "verse"
  end
end
