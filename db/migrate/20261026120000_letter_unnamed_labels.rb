# An unnamed label is spoken of by a letter ("group D"), the same from every note in it, where it used to be shown
# "like" one of its notes, which changed with the note it was seen from. The letter is stored as a number and never
# reused: the user counts the ones handed out, so a dropped label leaves a gap. A label named later keeps its number, to
# have it back if the name is taken away again. Existing unnamed labels are lettered in the order they were made.
#
# Going up, only columns and an index are added, so no table is rebuilt. Going down, remove_column makes SQLite rebuild
# labels and users. Rails turns foreign keys off for that, but SQLite ignores the pragma inside a transaction, so
# dropping the old tables would take every label off its notes and delete the users' foci, notes and the rest. Outside
# the migration's transaction the pragma holds, and each rebuild has a transaction of its own.
class LetterUnnamedLabels < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_column :users, :labels_lettered, :integer, null: false, default: 0
    add_column :labels, :number, :integer
    add_index :labels, [ :user_id, :number ], unique: true

    execute <<~SQL
      UPDATE labels SET number = (
        SELECT COUNT(*) FROM labels AS earlier
        WHERE earlier.user_id = labels.user_id AND earlier.name IS NULL AND earlier.id <= labels.id
      )
      WHERE name IS NULL
    SQL
    execute <<~SQL
      UPDATE users SET labels_lettered = COALESCE((SELECT MAX(number) FROM labels WHERE labels.user_id = users.id), 0)
    SQL
  end

  def down
    remove_index :labels, [ :user_id, :number ]
    remove_column :labels, :number
    remove_column :users, :labels_lettered
  end
end
