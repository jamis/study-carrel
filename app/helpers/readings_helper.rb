module ReadingsHelper
  def unit_ref(section, unit) = "#{section.name}:#{unit.number}"

  # Longer units step down in size so prose paragraphs stay readable.
  def unit_size_class(body)
    body.length > 450 ? "long" : body.length > 180 ? "mid" : ""
  end
end
