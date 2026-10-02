class ReadingsController < ApplicationController
  before_action :require_focus

  def show
    work = Work.find_by!(slug: params[:slug])
    @section = work.sections.find_by!(number: params[:section])
    @units = @section.units.to_a
    @current = (params[:number] ? @units.find { |u| u.number == params[:number].to_i } : resume_unit || @units.first) or
      raise ActiveRecord::RecordNotFound
    @notes_by_unit = @focus.notes.where(unit: @units).chronological.group_by(&:unit_id)
  end

  private

  def resume_unit = @units.find { |u| u.id == @focus.last_unit_id }

  def require_focus
    @focus = Focus.current_one or redirect_to new_focus_path
  end
end
