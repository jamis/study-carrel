# Focus.current_one filters on user and archived_at and sorts by created_at; the old user_id index is its prefix.
class IndexFociForCurrentLookup < ActiveRecord::Migration[8.1]
  def change
    add_index :foci, [ :user_id, :archived_at, :created_at ]
    remove_index :foci, :user_id
  end
end
