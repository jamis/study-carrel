# The reread used to be a page of its own: its old address leads to the notes page.
class RereadsController < ApplicationController
  before_action :set_focus

  def show
    redirect_to focus_notes_path(@focus, label: params[:label].presence)
  end

  private

  # Only the reader's own focuses: anyone else's is a 404.
  def set_focus = @focus = Current.user.foci.find(params[:focus_id])
end
