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

  private

  # The places searched lately, newest first, for the rail's Search to open on and the picker to offer (see
  # SearchHelper#searched_places). In the session cookie, so per device.
  def remember_place
    keys = helpers.search_place_params(@place).stringify_keys
    session[:search_places] = [ keys, *Array(session[:search_places]) - [ keys ] ].first(SearchHelper::SEARCHED_PLACES)
  end
end
