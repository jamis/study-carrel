class WorksController < ApplicationController
  def show
    @work = Work.find_by!(slug: params[:slug])
    @sections = @work.sections.includes(:units).to_a
    @noted_section_ids = Focus.current_one&.notes&.joins(:unit)&.distinct&.pluck("units.section_id").to_a
  end
end
