class AddSingleWorkToCollections < ActiveRecord::Migration[8.1]
  def change
    add_column :collections, :single_work, :boolean, default: false, null: false
  end
end
