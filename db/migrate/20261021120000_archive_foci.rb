# Archiving a focus puts it away: off the focuses page, its notes read-only. Until now archived_at meant only "not the
# current focus" (starting or picking another one stamped it), so that column becomes made_current_at, when the focus
# was last made current; the latest of a user's is the current one. A fresh archived_at means archived, nothing else.
#
# Past foci keep their stamp (when they stopped being current is close enough to when they last were, and keeps their
# order); each user's current one is stamped now.
#
# The column is renamed in place (ALTER TABLE … RENAME COLUMN), not with rename_column, which on SQLite rebuilds the
# table and would null detached_notes.focus_id (on_delete: :nullify); going down, the column is dropped in place for the
# same reason. Only the index is dropped and remade, to rename it.
class ArchiveFoci < ActiveRecord::Migration[8.1]
  def up
    remove_index :foci, name: "index_foci_on_user_id_and_archived_at_and_created_at"
    execute "ALTER TABLE foci RENAME COLUMN archived_at TO made_current_at"
    execute "UPDATE foci SET made_current_at = #{connection.quote(Time.current)} WHERE made_current_at IS NULL"
    add_column :foci, :archived_at, :datetime
    add_index :foci, [ :user_id, :archived_at, :made_current_at ]
  end

  def down
    remove_index :foci, [ :user_id, :archived_at, :made_current_at ]
    execute "ALTER TABLE foci DROP COLUMN archived_at"
    # Back to "archived_at is set on every focus but the current one".
    execute <<~SQL
      UPDATE foci SET made_current_at = NULL
      WHERE id IN (SELECT id FROM foci AS f WHERE f.made_current_at = (SELECT MAX(made_current_at) FROM foci WHERE user_id = f.user_id))
    SQL
    execute "ALTER TABLE foci RENAME COLUMN made_current_at TO archived_at"
    add_index :foci, [ :user_id, :archived_at, :created_at ]
  end
end
