# A keep needn't have a passage: an idea is a keep with only its remark. The unique (user_id, unit_id) index stays, since
# SQLite counts nulls as distinct, so a user can have any number of ideas.
#
# change_column_null rebuilds the table on SQLite. Nothing points a foreign key at keeps, so the rebuild can't cascade,
# but it runs outside the migration's transaction anyway (disable_ddl_transaction!), as every rebuild here does, so that
# Rails' PRAGMA foreign_keys = OFF takes effect. Going down, ideas have nowhere to go and are deleted.
class LetKeepsBeIdeas < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    change_column_null :keeps, :unit_id, true
  end

  def down
    execute "DELETE FROM keeps WHERE unit_id IS NULL"
    change_column_null :keeps, :unit_id, false
  end
end
