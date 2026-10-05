class WorksController < ApplicationController
  def show
    @work = Work.find_by!(slug: params[:slug])
    @sections = @work.sections.to_a
    @first_unit_numbers = Unit.where(section: @sections).group(:section_id).minimum(:number)
    @noted_section_ids = Current.user.foci.current_one&.notes&.joins(:unit)&.distinct&.pluck("units.section_id").to_a
  end
end
