# The notes page opens at the top now, so where its reread left off is no longer kept.
#
# remove_reference makes SQLite rebuild foci, going up and going down. Rails turns foreign keys off for that, but SQLite
# ignores the pragma inside a transaction, so dropping the old table would empty detached_notes.focus_id (and fail on,
# or take with it, the notes and scratchpads that hang off it). Outside the migration's transaction the pragma holds,
# and the rebuild has a transaction of its own.
class RemoveRereadNoteFromFoci < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_reference :foci, :reread_note, foreign_key: { to_table: :notes, on_delete: :nullify }
  end
end
