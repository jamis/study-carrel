class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # An archived focus is read-only: nothing is written, labelled or grouped under it until it's unarchived.
  def refuse_archived_focus
    head :forbidden if @focus&.archived?
  end

  # Admin-only pages look like they don't exist to everyone else.
  def require_admin
    head :not_found unless Current.user&.admin?
  end
end
