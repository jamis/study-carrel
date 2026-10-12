# Notes set aside when their passage went away (see DetachedNote). The only thing to do with one is discard it.
class DetachedNotesController < ApplicationController
  def destroy
    detached = Current.user.detached_notes.find(params[:id])
    detached.destroy!
    redirect_to detached.kept? ? kept_path : focus_notes_path(detached.focus), status: :see_other
  end
end
