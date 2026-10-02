class MoveNoteBodyToRichText < ActiveRecord::Migration[8.1]
  def up
    select_rows("SELECT id, body FROM notes").each do |id, body|
      html = body.to_s.split(/\n{2,}/).map { |p| "<p>#{ERB::Util.html_escape(p.strip).gsub("\n", "<br>")}</p>" }.join
      execute <<~SQL.squish
        INSERT INTO action_text_rich_texts (name, body, record_type, record_id, created_at, updated_at)
        VALUES ('content', #{quote(html)}, 'Note', #{id.to_i}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      SQL
    end
    remove_column :notes, :body
  end

  def down
    add_column :notes, :body, :text
    select_rows("SELECT record_id, body FROM action_text_rich_texts WHERE record_type = 'Note' AND name = 'content'").each do |id, html|
      text = ActionText::Content.new(html).to_plain_text
      execute "UPDATE notes SET body = #{quote(text)} WHERE id = #{id.to_i}"
    end
    change_column_null :notes, :body, false, ""
  end
end
