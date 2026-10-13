module ShelvesHelper
  # A work or collection as a shelf names it.
  def shelf_thing_name(thing) = thing.is_a?(Work) ? thing.title : thing.name
end
