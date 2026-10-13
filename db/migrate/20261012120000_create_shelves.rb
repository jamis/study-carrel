# A user's own grouping of works and collections, to roll Random and search in. Private to its owner, like their texts.
class CreateShelves < ActiveRecord::Migration[8.1]
  def change
    create_table :shelves do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :slug, null: false, index: { unique: true }
      t.timestamps
    end

    # One work or one collection on a shelf. A collection brings everything nested under it, now and later.
    create_table :shelf_items do |t|
      t.references :shelf, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :work, foreign_key: { on_delete: :cascade }
      t.references :collection, foreign_key: { on_delete: :cascade }
      t.timestamps
      t.index %i[shelf_id work_id], unique: true
      t.index %i[shelf_id collection_id], unique: true
      t.check_constraint "(work_id IS NULL) <> (collection_id IS NULL)", name: "shelf_item_is_one_thing"
    end
  end
end
