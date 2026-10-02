class HomeController < ApplicationController
  def index
    section = Section.joins(:work).order("works.id", :number).first
    return render plain: "No texts loaded. Run bin/rails db:seed" unless section

    redirect_to reading_path(section.work.slug, section.number)
  end
end
