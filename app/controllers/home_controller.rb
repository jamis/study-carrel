class HomeController < ApplicationController
  allow_unauthenticated_access only: :index

  def index
    return render_landing unless authenticated?

    focus = Current.user.foci.current_one or return redirect_to new_focus_path

    if (unit = focus.last_unit)
      return redirect_to reading_path(unit.section.work.slug, unit.section.number, unit.number)
    end

    # Nothing read yet under this focus: let them choose where to begin.
    redirect_to library_path
  end

  private

  # The library as the landing page lists it: each top-level collection with its child collections
  # (one item each) and its own works, so the list follows the corpus.
  def render_landing
    @collections = Collection.top_level.ordered.includes(:children, :works).select { |c| c.children.any? || c.works.any? }
    render :landing, layout: "landing"
  end
end
