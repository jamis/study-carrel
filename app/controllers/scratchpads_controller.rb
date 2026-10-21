# A focus's scratchpad, rough thoughts while rereading its notes: an always-open editor that autosaves.
class ScratchpadsController < ApplicationController
  before_action :set_focus, :refuse_archived_focus

  def update
    @focus.update!(scratchpad: params.expect(scratchpad: [ :content ])[:content])
    head :no_content
  end

  private

  def set_focus = @focus = Current.user.foci.find(params[:focus_id])
end
