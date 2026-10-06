class AddSentencesToUnits < ActiveRecord::Migration[8.1]
  def change
    # Prose is read a sentence at a time: a sentence unit knows its paragraph (or thought, or section) and its
    # place in it. Both stay empty for verses and stanzas.
    add_column :units, :paragraph, :integer
    add_column :units, :sentence, :integer
    # What a sentence work's groups are called ("paragraph", "thought"); empty for other works.
    add_column :works, :group_name, :string
  end
end
