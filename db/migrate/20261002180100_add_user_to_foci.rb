# Foci (and through them, notes) belong to a user. Everything that exists so far is the owner's,
# the first user.
class AddUserToFoci < ActiveRecord::Migration[8.1]
  def up
    add_reference :foci, :user, foreign_key: true, null: true
    execute "UPDATE foci SET user_id = (SELECT id FROM users ORDER BY id LIMIT 1)"
    change_column_null :foci, :user_id, false
  end

  def down
    remove_reference :foci, :user, foreign_key: true
  end
end
