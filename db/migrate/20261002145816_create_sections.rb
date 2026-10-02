class CreateSections < ActiveRecord::Migration[8.1]
  def change
    create_table :sections do |t|
      t.references :work, null: false, foreign_key: true
      t.integer :number, null: false
      t.string :label

      t.timestamps
    end

    add_index :sections, [:work_id, :number], unique: true
  end
end
