# A user's own texts: private to them (user_id), with the source they pasted or uploaded, kept for revising later.
# Bundled texts have no user.
class AddUserToWorks < ActiveRecord::Migration[8.1]
  def change
    add_reference :works, :user, foreign_key: true
    add_column :works, :source, :text
  end
end
