# Library search (see LibrarySearch): the whole library, or ?work= / ?collection= to search inside one place.
class SearchesController < ApplicationController
  include LibraryPlace

  def show
    @place = library_place
    @search = LibrarySearch.new(params[:q], place: @place, user: Current.user)
    @page = [ params[:page].to_i, 1 ].max
    @units = @search.page(@page) if @search.searching?
    remember_place if @search.searching?
  end

  # The reader's band steps through the results of the search it came from (back_slip_controller.js): where they stand
  # around the section being read (LibrarySearch#around), once per section, since the reader moves within one itself.
  def around
    section = Section.joins(:work).merge(Work.visible_to(Current.user)).find(params[:section])
    around = LibrarySearch.new(params[:q], place: library_place, user: Current.user).around(section)
    render json: {
      total: around.total, before: around.before, per_page: LibrarySearch::PER_PAGE,
      hits: around.hits.map { around_result(it, section) },
      previous: around_result(around.previous), next: around_result(around.next)
    }
  end

  private

  # A result, with its reference in two parts so a long title can shorten while its number stays.
  def around_result(unit, section = unit&.section)
    return unless unit

    { id: unit.id, number: unit.number, url: reading_path(section.work.slug, section.number, unit.number),
      name: section.name, unit: section.reference_unit_template.sub("{n}", unit.label) }
  end

  # The places searched lately, newest first, for the rail's Search to open on and the picker to offer (see
  # SearchHelper#searched_places). In the session cookie, so per device.
  def remember_place
    keys = helpers.search_place_params(@place).stringify_keys
    session[:search_places] = [ keys, *Array(session[:search_places]) - [ keys ] ].first(SearchHelper::SEARCHED_PLACES)
  end
end
