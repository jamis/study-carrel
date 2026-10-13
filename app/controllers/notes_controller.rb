class NotesController < ApplicationController
  before_action :set_focus, except: :current

  def index
    @notes = @focus.notes_in_reading_order.includes(:labels)
    @detached = @focus.detached_notes.includes(:rich_text_content)
  end

  def export
    export = MarkdownExport.new(@focus)
    send_data export.to_s, filename: export.filename, type: "text/markdown; charset=utf-8", disposition: "attachment"
  end

  def current
    redirect_to Current.focus ? focus_notes_path(Current.focus) : new_focus_path
  end

  private

  # Only the reader's own focuses: anyone else's is a 404.
  def set_focus = @focus = Current.user.foci.find(params[:focus_id])
end
