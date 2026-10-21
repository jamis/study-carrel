# Pages that only make sense with a current focus send you to choose one first (on the cards), or to make one if there's
# none to choose. A save (an autosave, say) can't follow a redirect to a form, so it's refused instead.
module RequiresFocus
  extend ActiveSupport::Concern

  included do
    before_action :require_focus
  end

  private

  def require_focus
    @focus = Current.focus or (request.get? || request.head? ? redirect_to(choose_focus_path) : head(:conflict))
  end

  def choose_focus_path = Current.user.foci.active.exists? ? foci_path : new_focus_path
end
