class AddLastUnitToFoci < ActiveRecord::Migration[8.1]
  def change
    add_reference :foci, :last_unit, foreign_key: { to_table: :units, on_delete: :nullify }
  end
end
