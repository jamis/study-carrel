# A user's own labels, put on notes while rereading a focus to sort them like index cards into piles. A label belongs to
# the user, not to a focus, so the same label can gather notes from several focuses. Names are unique per user, ignoring
# case.
class CreateLabels < ActiveRecord::Migration[8.1]
  def change
    create_table :labels do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :name, null: false, collation: "NOCASE"
      t.timestamps
      t.index %i[user_id name], unique: true
    end

    create_table :note_labels do |t|
      t.references :note, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :label, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
      t.index %i[note_id label_id], unique: true
    end

    # Where the reread of a focus left off.
    add_reference :foci, :reread_note, foreign_key: { to_table: :notes, on_delete: :nullify }

    # A note set aside keeps its labels' names, as text: nothing is lost, but they no longer count anywhere.
    add_column :detached_notes, :label_names, :json, null: false, default: []
  end
end
