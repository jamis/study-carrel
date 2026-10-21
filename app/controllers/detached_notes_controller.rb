# Notes set aside when their passage went away (see DetachedNote). The only thing to do with one is discard it, unless
# its focus is archived (read-only).
class DetachedNotesController < ApplicationController
  def destroy
    detached = Current.user.detached_notes.find(params[:id])
    return head(:forbidden) if detached.focus&.archived?

    detached.destroy!
    redirect_to detached.kept? ? kept_path : focus_notes_path(detached.focus), status: :see_other
  end
end
