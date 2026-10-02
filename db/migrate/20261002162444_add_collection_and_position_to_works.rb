class AddCollectionAndPositionToWorks < ActiveRecord::Migration[8.1]
  def change
    add_reference :works, :collection, foreign_key: true
    add_column :works, :position, :integer, null: false, default: 0
  end
end
