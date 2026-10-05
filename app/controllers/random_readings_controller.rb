# Drops the reader into a random unit (see RandomScope) and on into lectio mode.
class RandomReadingsController < ApplicationController
  def show
    scope = self.scope
    unit = scope.unit or raise ActiveRecord::RecordNotFound
    section = unit.section
    redirect_to reading_path(section.work.slug, section.number, unit.number)
  end

  private

  def scope
    if params[:work] then RandomScope.new(Work.find_by!(slug: params[:work]))
    elsif params[:collection] then RandomScope.new(Collection.find_by!(slug: params[:collection]))
    else RandomScope.library
    end
  end
end
