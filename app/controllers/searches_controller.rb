# Library search (see LibrarySearch): the whole library, or ?work= / ?collection= to search inside one place.
class SearchesController < ApplicationController
  include LibraryPlace

  def show
    @place = library_place
    @search = LibrarySearch.new(params[:q], place: @place, user: Current.user)
    @page = [ params[:page].to_i, 1 ].max
    @units = @search.page(@page) if @search.searching?
  end
end
