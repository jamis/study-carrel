class HomeController < ApplicationController
  def index
    focus = Current.user.foci.current_one or return redirect_to new_focus_path

    if (unit = focus.last_unit)
      return redirect_to reading_path(unit.section.work.slug, unit.section.number, unit.number)
    end

    section = Section.joins(:work).order("works.position", "works.id", :number).first
    return render :no_texts unless section

    redirect_to reading_path(section.work.slug, section.number)
  end
end
