# Notes (and kept remarks) whose passage is gone, after a user revised or deleted their own text, kept with a frozen copy
# of where they were and what they were written on. A kept remark has no focus.
class CreateDetachedNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :detached_notes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :focus, foreign_key: { on_delete: :nullify }
      t.boolean :kept, null: false, default: false
      t.string :citation, null: false
      t.string :work_title, null: false
      t.text :passage, null: false
      t.string :reason, null: false
      t.datetime :noted_at, null: false
      t.datetime :edited_at, null: false
      t.timestamps
    end
    add_index :detached_notes, %i[user_id kept created_at]
  end
end
