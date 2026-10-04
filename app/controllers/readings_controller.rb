class ReadingsController < ApplicationController
  include RequiresFocus

  def show
    work = Work.find_by!(slug: params[:slug])
    @section = work.sections.find_by!(number: params[:section])
    @units = @section.units.to_a
    @current = (params[:number] ? @units.find { |u| u.number == params[:number].to_i } : resume_unit || @units.first) or
      raise ActiveRecord::RecordNotFound
    @previous_section = @section.previous_section
    @next_section = @section.next_section
    @notes_by_unit = @focus.notes.where(unit: @units).index_by(&:unit_id)
    @kept = Current.user.keeps.where(unit: @units).pluck(:unit_id, :remark).to_h { |id, remark| [ id, remark.to_s ] }
  end

  private

  def resume_unit = @units.find { |u| u.id == @focus.last_unit_id }
end
