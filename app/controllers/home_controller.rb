class HomeController < ApplicationController
  def index
    return redirect_to new_focus_path unless Focus.current_one

    section = Section.joins(:work).order("works.id", :number).first
    return render plain: "No texts loaded. Run bin/rails db:seed" unless section

    redirect_to reading_path(section.work.slug, section.number)
  end
end
