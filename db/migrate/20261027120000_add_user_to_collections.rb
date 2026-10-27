# A user's own collections, private to them like their own texts (see Collection.visible_to).
#
# Adding the foreign key, and removing the column going down, make SQLite rebuild collections. Rails turns foreign keys
# off for that, but SQLite ignores the pragma inside a transaction, so dropping the old table would delete every shelf
# item on a collection and clear every collection's parent. Outside the migration's transaction the pragma holds.
class AddUserToCollections < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :collections, :user, foreign_key: true
  end
end
