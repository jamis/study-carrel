# A free note belongs to its focus as a whole, not to a passage: what you noticed across passages. Its unit is empty.
# The unique (focus, unit) index still keeps one note per passage per focus, since SQLite treats each NULL as distinct.
#
# change_column_null makes SQLite rebuild notes, going up and going down. Rails turns foreign keys off for that, but
# SQLite ignores the pragma inside a transaction, so dropping the old table would take every label off its notes and
# empty foci.reread_note_id and labels.example_note_id. Outside the migration's transaction the pragma holds, and the
# rebuild has a transaction of its own.
class AllowFreeNotes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    change_column_null :notes, :unit_id, true
  end
end
