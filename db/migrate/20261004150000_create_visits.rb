class CreateVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :visits do |t|
      t.references :user, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true
      t.datetime :visited_at, null: false
    end
    add_index :visits, %i[user_id unit_id], unique: true
    add_index :visits, %i[user_id visited_at]
  end
end
