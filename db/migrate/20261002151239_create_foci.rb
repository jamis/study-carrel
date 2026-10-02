class CreateFoci < ActiveRecord::Migration[8.1]
  def change
    create_table :foci do |t|
      t.string :title, null: false
      t.text :description
      t.datetime :archived_at

      t.timestamps
    end
  end
end
