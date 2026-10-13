module RandomHelper
  # The user's shelves to offer beside a page's own places to roll: those holding its work or collection, or, from
  # the library (and pages with no place), every shelf with something on it.
  def shelf_scopes(scopes)
    place = scopes.first&.place
    shelves = Current.user.shelves.includes(:items).select { it.items.any? }
    shelves = case place
    when nil then shelves
    when Work, Collection then shelves.select { it.holds?(place) }
    else []
    end
    shelves.map { RandomScope.new(it) } - scopes
  end

  def random_scope_path(scope)
    case scope.place
    when nil then random_path
    when Work then random_work_path(scope.place.slug)
    when OwnTexts then random_texts_path
    when Shelf then random_shelf_path(scope.place)
    else random_collection_path(scope.place.slug)
    end
  end
end
