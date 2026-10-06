class NotesController < ApplicationController
  include RequiresFocus

  def index
    @notes = @focus.notes_in_reading_order
    @detached = @focus.detached_notes.includes(:rich_text_content)
  end

  def export
    export = MarkdownExport.new(@focus)
    send_data export.to_s, filename: export.filename, type: "text/markdown; charset=utf-8", disposition: "attachment"
  end
end
