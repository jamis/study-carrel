# One note per verse per focus, in an always-open editor that autosaves.
# Clearing the editor deletes the note.
class UnitNotesController < ApplicationController
  include RequiresFocus

  before_action :set_unit
  before_action :set_note

  def show
  end

  def update
    # The editor was opened under another focus (one started since, maybe in another tab).
    return head :conflict if params[:focus_id].present? && params[:focus_id].to_i != @focus.id

    @note ||= @focus.notes.build(unit: @unit)
    @note.content = params.expect(note: [ :content ])[:content]

    if @note.save
      noted = true
    else
      @note.destroy! if @note.persisted?
      noted = false
    end

    response.set_header "X-Noted", noted.to_s
    respond_to { |format| format.turbo_stream }
  end

  private

  def set_unit = @unit = Unit.find(params[:unit_id])
  def set_note = @note = @focus.notes.find_by(unit: @unit)
end
