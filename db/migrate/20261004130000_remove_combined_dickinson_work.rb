# Dickinson's three series are now separate works (dickinson-first-series, ...), so the old combined
# "dickinson" work goes, along with its units and any notes on them (those were test data).
class RemoveCombinedDickinsonWork < ActiveRecord::Migration[8.0]
  def up
    work_id = select_value("SELECT id FROM works WHERE slug = 'dickinson'")
    return unless work_id

    sections = "SELECT id FROM sections WHERE work_id = #{work_id.to_i}"
    units = "SELECT id FROM units WHERE section_id IN (#{sections})"
    execute "DELETE FROM action_text_rich_texts WHERE record_type = 'Note' AND record_id IN (SELECT id FROM notes WHERE unit_id IN (#{units}))"
    execute "DELETE FROM notes WHERE unit_id IN (#{units})"
    execute "DELETE FROM units WHERE section_id IN (#{sections})"
    execute "DELETE FROM sections WHERE work_id = #{work_id.to_i}"
    execute "DELETE FROM works WHERE id = #{work_id.to_i}"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
