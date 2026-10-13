# Rereading a focus's notes (the current focus's or a past one's): those on passages in reading order, then those on
# the focus as a whole, one lit at a time, to label as you go, with the focus's scratchpad beside them. ?label= rereads
# only the notes carrying one label.
class RereadsController < ApplicationController
  before_action :set_focus

  def show
    @label = Current.user.labels.find(params[:label]) if params[:label].present?
    @all = @focus.notes_for_reread
    @notes = @label ? @all.select { it.label_ids.include?(@label.id) } : @all
    @here = @notes.find { it.id == @focus.reread_note_id } || @notes.first
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
