class AddParentToCollections < ActiveRecord::Migration[8.1]
  def change
    add_reference :collections, :parent, foreign_key: { to_table: :collections, on_delete: :nullify }
  end
end
