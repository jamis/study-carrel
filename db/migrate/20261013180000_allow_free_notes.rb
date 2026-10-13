# A free note belongs to its focus as a whole, not to a passage: what you noticed across passages. Its unit is empty.
# The unique (focus, unit) index still keeps one note per passage per focus, since SQLite treats each NULL as distinct.
class AllowFreeNotes < ActiveRecord::Migration[8.1]
  def change
    change_column_null :notes, :unit_id, true
  end
end
