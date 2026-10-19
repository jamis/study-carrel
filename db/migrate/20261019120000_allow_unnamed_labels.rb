# A label can be a group of notes that go together before there are words for it: unnamed, and known by one of its
# notes, its example. SQLite treats each NULL as distinct, so the unique (user, name) index lets a user have any number
# of unnamed labels while names stay unique. A note that goes leaves its labels without an example; the label then
# shows by another of its notes.
#
# Both changes make SQLite rebuild labels (copy, drop, recreate). Rails turns foreign keys off for that, but SQLite
# ignores the pragma inside a transaction, so dropping the old table would cascade into note_labels and take every
# label off its notes. Outside the migration's transaction the pragma holds, and each rebuild has a transaction of its
# own.
class AllowUnnamedLabels < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    change_column_null :labels, :name, true
    add_reference :labels, :example_note, foreign_key: { to_table: :notes, on_delete: :nullify }
  end
end
