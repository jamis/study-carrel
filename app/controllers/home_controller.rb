class HomeController < ApplicationController
  allow_unauthenticated_access only: :index

  # Visitors get the landing page; signed in, home is the focuses page.
  def index
    authenticated? ? redirect_to(foci_path) : render_landing
  end

  private

  # The library as the landing page lists it: each top-level collection with its child collections
  # (one item each) and its own works, so the list follows the corpus.
  def render_landing
    @collections = Collection.top_level.ordered.includes(:children, :works).select { |c| c.children.any? || c.works.any? }
    render :landing, layout: "landing"
  end
end
