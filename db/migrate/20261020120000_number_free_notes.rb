# Notes on the focus as a whole are spoken of by number ("focus 2"), as a passage's note is by its verse. The number
# is stored and never reused: the focus counts the ones it has handed out, so a deleted note leaves a gap rather than
# its number passing to the next note written. Existing notes are numbered in the order they were written.
#
# Going up, only columns and an index are added, so no table is rebuilt. Going down, remove_column makes SQLite rebuild
# notes and foci. Rails turns foreign keys off for that, but SQLite ignores the pragma inside a transaction, so dropping
# the old tables would take every label off its notes and empty foci.reread_note_id, labels.example_note_id and
# detached_notes.focus_id. Outside the migration's transaction the pragma holds, and each rebuild has a transaction of
# its own.
class NumberFreeNotes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_column :foci, :free_notes_numbered, :integer, null: false, default: 0
    add_column :notes, :number, :integer
    add_index :notes, [ :focus_id, :number ], unique: true

    execute <<~SQL
      UPDATE notes SET number = (
        SELECT COUNT(*) FROM notes AS earlier
        WHERE earlier.focus_id = notes.focus_id AND earlier.unit_id IS NULL
          AND (earlier.created_at < notes.created_at OR (earlier.created_at = notes.created_at AND earlier.id <= notes.id))
      )
      WHERE unit_id IS NULL
    SQL
    execute <<~SQL
      UPDATE foci SET free_notes_numbered = COALESCE((SELECT MAX(number) FROM notes WHERE notes.focus_id = foci.id), 0)
    SQL
  end

  def down
    remove_index :notes, [ :focus_id, :number ]
    remove_column :notes, :number
    remove_column :foci, :free_notes_numbered
  end
end
