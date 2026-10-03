class MakeNotesUniquePerUnitAndFocus < ActiveRecord::Migration[8.1]
  # Folds any verse that has several notes for one focus into its earliest note,
  # appending the later ones in order, before the unique index goes on.
  def up
    execute(<<~SQL).each { |row| merge(row["focus_id"], row["unit_id"]) }
      SELECT focus_id, unit_id FROM notes GROUP BY focus_id, unit_id HAVING COUNT(*) > 1
    SQL
    add_index :notes, %i[focus_id unit_id], unique: true
  end

  def down
    remove_index :notes, %i[focus_id unit_id]
  end

  private

  def merge(focus_id, unit_id)
    ids = select_values("SELECT id FROM notes WHERE focus_id = #{focus_id.to_i} AND unit_id = #{unit_id.to_i} ORDER BY created_at, id")
    keeper, *rest = ids
    bodies = ids.map { |id| select_value("SELECT body FROM action_text_rich_texts WHERE record_type = 'Note' AND name = 'content' AND record_id = #{id.to_i}").to_s }
    execute "UPDATE action_text_rich_texts SET body = #{quote(bodies.join)} WHERE record_type = 'Note' AND name = 'content' AND record_id = #{keeper.to_i}"
    execute "DELETE FROM action_text_rich_texts WHERE record_type = 'Note' AND name = 'content' AND record_id IN (#{rest.join(",")})"
    execute "DELETE FROM notes WHERE id IN (#{rest.join(",")})"
  end
end
