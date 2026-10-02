# Pages that only make sense with a current focus send you to make one first.
module RequiresFocus
  extend ActiveSupport::Concern

  included do
    before_action :require_focus
  end

  private

  def require_focus
    @focus = Focus.current_one or redirect_to new_focus_path
  end
end
