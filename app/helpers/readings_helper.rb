module ReadingsHelper
  def unit_ref(section, unit) = section.reference(unit.number)

  def unit_noun(section) = section.work.unit_name.capitalize

  # Where Next/Previous lead when you reach the end of a chapter (or poem, or chapter of prose).
  def edge_url(section, which)
    return unless section

    number = which == :previous ? section.units.last.number : section.units.first.number
    reading_path(section.work.slug, section.number, number)
  end

  # Longer units step down in size so prose paragraphs stay readable.
  def unit_size_class(body)
    body.length > 450 ? "long" : body.length > 180 ? "mid" : ""
  end
end
