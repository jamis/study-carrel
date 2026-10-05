module RandomHelper
  def random_scope_path(scope)
    case scope.place
    when nil then random_path
    when Work then random_work_path(scope.place.slug)
    else random_collection_path(scope.place.slug)
    end
  end
end
