class NotesController < ApplicationController
  before_action :require_focus

  def index
    @notes = @focus.notes.includes(:rich_text_content, unit: { section: :work })
                   .joins(unit: { section: :work })
                   .order("works.id", "sections.number", "units.number", :created_at, :id)
    @groups = @notes.group_by(&:unit)
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

  def require_focus
    @focus = Focus.current_one or redirect_to new_focus_path
  end

  def note_params = params.expect(note: [ :unit_id, :content ])
end
