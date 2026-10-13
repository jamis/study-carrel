# Putting a note on a label (by name, made if it's new) or taking it off, while rereading its focus. The page's
# labels (the note's own, the cloud and the tallies) are redrawn from the reply.
class NoteLabelsController < ApplicationController
  before_action :set_note

  def create
    @note.label!(params[:name].to_s)
    render :update
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  def destroy
    @note.unlabel!(Current.user.labels.find(params[:id]))
    render :update
  end

  private

  # Only the reader's own focuses and notes: anyone else's is a 404.
  def set_note
    @focus = Current.user.foci.find(params[:focus_id])
    @note = @focus.notes.find(params[:note_id])
  end
end
