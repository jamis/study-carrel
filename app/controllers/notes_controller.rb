class NotesController < ApplicationController
  before_action :set_focus, except: :current
  before_action :set_free_note, only: %i[show update]

  def index
    @notes = @focus.notes_in_reading_order.includes(:labels)
    @free = @focus.free_notes
    @detached = @focus.detached_notes.includes(:rich_text_content)
  end

  # The editor for a new note on the focus as a whole, and for one already written. Any focus's, past ones too: unlike
  # a passage's note, which the reader saves under the current focus, these are saved to their own focus.
  def new = render(partial: "notes/free_editor", locals: { focus: @focus, note: nil })
  def show = render(partial: "notes/free_editor", locals: { focus: @focus, note: @note })

  # A new free note: its editor's first save, or text made a note of from the scratchpad (lift). The reply says where
  # the editor saves from now on.
  def create
    @note = @focus.notes.build(content: params.expect(note: [ :content ])[:content])
    return head(:no_content) unless @note.save

    @lifted = params[:lift].present?
    saved_to focus_note_path(@focus, @note), "PUT"
    respond_to { |format| format.turbo_stream }
  end

  # Autosave. Clearing it deletes the note, and the editor starts again from a new one.
  def update
    @note.content = params.expect(note: [ :content ])[:content]
    if @note.save
      saved_to focus_note_path(@focus, @note), "PUT"
    else
      @note.destroy!
      saved_to focus_notes_path(@focus), "POST"
    end
    respond_to { |format| format.turbo_stream }
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
  def set_free_note = @note = @focus.notes.free.find(params[:id])

  def saved_to(url, method)
    response.set_header "X-Noted", @note.persisted?.to_s
    response.set_header "X-Note-Id", @note.id.to_s if @note.persisted?
    response.set_header "X-Save-Url", url
    response.set_header "X-Save-Method", method
  end
end
