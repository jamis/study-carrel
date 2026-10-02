class CreateWorks < ActiveRecord::Migration[8.1]
  def change
    create_table :works do |t|
      t.string :title, null: false
      t.string :edition
      t.string :slug, null: false

      t.timestamps
    end
    add_index :works, :slug, unique: true
  end
end
