class HomeController < ApplicationController
  allow_unauthenticated_access only: :index

  def index
    return render :landing, layout: "landing" unless authenticated?

    focus = Current.user.foci.current_one or return redirect_to new_focus_path

    if (unit = focus.last_unit)
      return redirect_to reading_path(unit.section.work.slug, unit.section.number, unit.number)
    end

    # Nothing read yet under this focus: let them choose where to begin.
    redirect_to library_path
  end
end
