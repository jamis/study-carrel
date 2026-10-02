# Drops the reader into a random unit and on into lectio mode. A work or a
# collection picks uniformly from its units; the whole library first picks a
# collection (or loose work) so the Old Testament doesn't drown out the rest.
class RandomReadingsController < ApplicationController
  def show
    unit = random_unit(scope) or raise ActiveRecord::RecordNotFound
    section = unit.section
    redirect_to reading_path(section.work.slug, section.number, unit.number)
  end

  private

  def scope
    if params[:work] then Work.find_by!(slug: params[:work])
    elsif params[:collection] then Collection.find_by!(slug: params[:collection])
    end
  end

  def random_unit(scope)
    scope ||= (Collection.top_level.to_a + Work.where(collection_id: nil).to_a).select { |s| units_in(s).exists? }.sample
    scope && pick(units_in(scope))
  end

  # A random offset, not ORDER BY RANDOM(): SQLite returns the same row for the
  # latter when the scope is a subquery.
  def pick(units)
    units.order(:id).offset(rand(units.count)).first
  end

  def units_in(scope)
    units = Unit.joins(:section).includes(section: :work)
    case scope
    when Work then units.where(sections: { work_id: scope.id })
    else units.where(sections: { work_id: scope.all_works.select(:id) })
    end
  end
end
