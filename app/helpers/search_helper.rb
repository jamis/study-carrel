module SearchHelper
  SEARCHED_PLACES = 3

  # The query params that keep a search inside a work or collection (none for the whole library).
  def search_place_params(place)
    case place
    when nil then {}
    when Work then { work: place.slug }
    when OwnTexts then { texts: "yours" }
    when Shelf then { shelf: place.slug }
    else { collection: place.slug }
    end
  end

  def search_in_path(query, place, **params) = search_path(q: query, **search_place_params(place), **params)

  # The places searched in lately on this device (SearchesController#remember_place), newest first, as RandomScopes (a
  # nil place is the whole library). One gone since, or no longer the user's, drops out.
  def searched_places
    @searched_places ||= Array(session[:search_places]).filter_map do |keys|
      RandomScope.new(LibraryPlace.find(keys.to_h.with_indifferent_access, Current.user))
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end

  # Where the rail's Search opens off a page of its own place: the last place searched, then the work last read, then
  # the whole library (nil).
  def default_search_place
    return searched_places.first.place if searched_places.any?

    Current.user.visits.recent.first&.unit&.section&.work
  end

  # "in Isaiah", "in the library": the second line of the rail's Search.
  def search_place_in_words(place) = "in #{place ? RandomScope.new(place).label : "the library"}"

  # The picker's list to filter by title: every collection, then every work the user can see, each with the trail of
  # collections it sits in ("Sacred Texts › Bible").
  def search_picker_places
    collections = Collection.ordered.to_a
    by_id = collections.index_by(&:id)
    trail = lambda do |id|
      names = []
      while (collection = by_id[id]) && names.size < by_id.size
        names.unshift(collection.name)
        id = collection.parent_id
      end
      names
    end
    works = Work.visible_to(Current.user).order(:title, :id).select(:id, :slug, :title, :edition, :collection_id, :user_id)
    collections.sort_by { it.name.downcase }.map { [ it, trail.(it.parent_id).join(" › ") ] } +
      works.map { [ it, it.own_text? ? "Your Texts" : trail.(it.collection_id).join(" › ") ] }
  end

  # A snippet from LibrarySearch, escaped, with its match markers turned into <mark>.
  def search_excerpt(text)
    h(text).gsub(LibrarySearch::MARK_START, "<mark>").gsub(LibrarySearch::MARK_END, "</mark>").html_safe
  end
end
