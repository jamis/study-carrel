class CreateKeeps < ActiveRecord::Migration[8.1]
  def change
    create_table :keeps do |t|
      t.references :user, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true
      t.string :remark
      t.timestamps
    end
    add_index :keeps, %i[user_id unit_id], unique: true
  end
end
