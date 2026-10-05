# Full-text index over unit bodies for library search. It keeps its own copy of the text (rowid = units.id) so the
# loader can refresh a section's rows without the old values, and snippet() can highlight matches.
class CreateUnitSearch < ActiveRecord::Migration[8.1]
  def up
    create_virtual_table :unit_search, :fts5, [ "body", "tokenize = 'porter unicode61 remove_diacritics 2'" ]
    execute "INSERT INTO unit_search(rowid, body) SELECT id, body FROM units"
  end

  def down
    drop_table :unit_search
  end
end
