# One note per verse per focus, in an always-open editor that autosaves.
# Clearing the editor deletes the note.
#
# The note is the current focus's (/units/:unit_id/note), or, written from the reader without changing which focus is
# current, another of the reader's focuses' (/foci/:focus_id/units/:unit_id/note). An archived focus's note is only
# shown ("Also noted under …"), read-only.
class UnitNotesController < ApplicationController
  include RequiresFocus

  skip_before_action :require_focus, if: :elsewhere?
  before_action :set_focus_elsewhere, if: :elsewhere?
  before_action :set_unit
  before_action :set_note
  before_action :refuse_archived_focus, only: :update

  def show
  end

  def update
    # The editor was opened under another focus (one started since, maybe in another tab).
    return head :conflict if !elsewhere? && params[:focus_id].present? && params[:focus_id].to_i != @focus.id

    @note ||= @focus.notes.build(unit: @unit)
    @note.content = params.expect(note: [ :content ])[:content]

    if @note.save
      noted = true
    else
      @note.destroy! if @note.persisted?
      noted = false
    end

    response.set_header "X-Noted", noted.to_s
    response.set_header "X-Note-Id", @note.id.to_s if noted
    respond_to { |format| format.turbo_stream }
  end

  private

  # The route names the focus (a body's focus_id is only the editor saying which focus it was opened under).
  def elsewhere? = request.path_parameters.key?(:focus_id)

  # Only the reader's own focuses: anyone else's is a 404.
  def set_focus_elsewhere = @focus = Current.user.foci.find(params[:focus_id])
  def set_unit = @unit = Unit.visible_to(Current.user).find(params[:unit_id])
  def set_note = @note = @focus.notes.find_by(unit: @unit)
end
