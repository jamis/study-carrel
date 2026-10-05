class Current < ActiveSupport::CurrentAttributes
  attribute :session, :focus
  delegate :user, to: :session, allow_nil: true

  # The user's current focus, looked up once per request. Nothing needs to clear it: every action that changes
  # which focus is current ends in a redirect, so the next request looks it up afresh.
  def focus = super || (self.focus = user&.foci&.current_one)
end
