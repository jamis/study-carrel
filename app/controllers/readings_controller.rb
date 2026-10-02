class ReadingsController < ApplicationController
  def show
    work = Work.find_by!(slug: params[:slug])
    @section = work.sections.find_by!(number: params[:section])
    @units = @section.units.to_a
    @current = (params[:number] ? @units.find { |u| u.number == params[:number].to_i } : @units.first) or
      raise ActiveRecord::RecordNotFound
  end
end
