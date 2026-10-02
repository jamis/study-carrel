class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.string :token_digest, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :label
      t.datetime :expires_at, null: false
      t.datetime :redeemed_at
      t.references :redeemed_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :revoked_at

      t.timestamps
    end
    add_index :invitations, :token_digest, unique: true
  end
end
