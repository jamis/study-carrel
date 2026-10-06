module SearchHelper
  # The query params that keep a search inside a work or collection (none for the whole library).
  def search_place_params(place)
    case place
    when nil then {}
    when Work then { work: place.slug }
    when OwnTexts then { texts: "yours" }
    else { collection: place.slug }
    end
  end

  def search_in_path(query, place, **params) = search_path(q: query, **search_place_params(place), **params)

  # A snippet from LibrarySearch, escaped, with its match markers turned into <mark>.
  def search_excerpt(text)
    h(text).gsub(LibrarySearch::MARK_START, "<mark>").gsub(LibrarySearch::MARK_END, "</mark>").html_safe
  end
end
