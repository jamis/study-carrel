class HomeController < ApplicationController
  def index
    return redirect_to new_focus_path unless Focus.current_one

    if (unit = Focus.current_one.last_unit)
      return redirect_to reading_path(unit.section.work.slug, unit.section.number, unit.number)
    end

    section = Section.joins(:work).order("works.id", :number).first
    return render plain: "No texts loaded. Run bin/rails db:seed" unless section

    redirect_to reading_path(section.work.slug, section.number)
  end
end
