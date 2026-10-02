class CreateUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units do |t|
      t.references :section, null: false, foreign_key: true
      t.integer :number, null: false
      t.text :body, null: false

      t.timestamps
    end

    add_index :units, [ :section_id, :number ], unique: true
  end
end
