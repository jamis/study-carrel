# A focus's scratchpad, rough thoughts while rereading its notes: an always-open editor that autosaves.
class ScratchpadsController < ApplicationController
  def update
    focus = Current.user.foci.find(params[:focus_id])
    focus.update!(scratchpad: params.expect(scratchpad: [ :content ])[:content])
    head :no_content
  end
end
