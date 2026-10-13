# Rereading a focus's notes (the current focus's or a past one's): all of them in reading order, one lit at a time, to
# label as you go, with the focus's scratchpad beside them. ?label= rereads only the notes carrying one label.
class RereadsController < ApplicationController
  before_action :set_focus

  def show
    @label = Current.user.labels.find(params[:label]) if params[:label].present?
    @all = @focus.notes_in_reading_order.includes(:labels).to_a
    @notes = @label ? @all.select { it.label_ids.include?(@label.id) } : @all
    @here = @notes.find { it.id == @focus.reread_note_id } || @notes.first
    # A past focus's notes are read here; the current focus's can be edited, as in the reader.
    @editable = @focus == Current.focus
  end

  # Where the reread left off, so it opens there next time.
  def update
    @focus.update!(reread_note: @focus.notes.find(params[:note_id]))
    head :no_content
  end

  private

  # Only the reader's own focuses: anyone else's is a 404.
  def set_focus = @focus = Current.user.foci.find(params[:focus_id])
end
