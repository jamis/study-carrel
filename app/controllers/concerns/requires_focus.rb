# Pages that only make sense with a current focus send you to make one first.
# A save (an autosave, say) can't follow a redirect to a form, so it's refused instead.
module RequiresFocus
  extend ActiveSupport::Concern

  included do
    before_action :require_focus
  end

  private

  def require_focus
    @focus = Current.focus or (request.get? ? redirect_to(new_focus_path) : head(:conflict))
  end
end
