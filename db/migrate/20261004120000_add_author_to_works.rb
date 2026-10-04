class AddAuthorToWorks < ActiveRecord::Migration[8.0]
  def change
    add_column :works, :author, :string
    add_column :works, :author_short, :string
  end
end
