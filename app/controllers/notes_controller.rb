class NotesController < ApplicationController
  include RequiresFocus

  def index
    @notes = @focus.notes_in_reading_order
    @groups = @notes.group_by(&:unit)
  end

  def export
    export = MarkdownExport.new(@focus)
    send_data export.to_s, filename: export.filename, type: "text/markdown; charset=utf-8", disposition: "attachment"
  end

  def show
    @note = @focus.notes.find(params[:id])
    redirect_to notes_path unless turbo_frame_request?
  end

  def edit
    @note = @focus.notes.find(params[:id])
    redirect_to notes_path unless turbo_frame_request?
  end

  def update
    @note = @focus.notes.find(params[:id])
    if @note.update(params.expect(note: [ :content ]))
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to notes_path }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @note = @focus.notes.build(note_params)
    if @note.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: root_path }
      end
    else
      head :unprocessable_entity
    end
  end

  def destroy
    @note = @focus.notes.find(params[:id])
    @note.destroy!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: root_path }
    end
  end

  private

  def note_params = params.expect(note: [ :unit_id, :content ])
end
