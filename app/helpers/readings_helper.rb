module ReadingsHelper
  # Breadcrumb trail for the reading nav: [[label, path_or_nil, title], ...], Library first, the section last.
  # The work is skipped when the section's name already starts with its title ("Isaiah 40"), and the
  # edition and author ride along as the work crumb's tooltip.
  def reading_crumbs(section)
    work = section.work
    trail = [ [ "Library", library_path, nil ] ]
    collections = work.collection ? work.collection.ancestors + [ work.collection ] : []
    collections.each { |c| trail << [ c.name, collection_path(c), nil ] }
    trail << [ work.title, work_path(work), [ work.byline, work.edition ].compact_blank.join(" · ").presence ] unless section.name.start_with?(work.title)
    trail << [ section.name, work_path(work), "Chapters in #{work.title}#{" (#{work.edition})" if work.edition.present?}" ]
  end

  def unit_ref(section, unit) = section.reference(unit.number)

  # Work title, section name and unit in separate spans (see .ref-work / .ref-section / .ref-unit); the browser updates the unit as the reader moves.
  def unit_ref_parts(section, unit)
    work, name = section.reference_name_parts
    safe_join([
      (tag.span(work, class: "ref-work") if work.present?),
      tag.span(name, class: "ref-section"),
      tag.span(section.reference_unit_template.sub("{n}", unit.number.to_s), class: "ref-unit", data: { lectio_target: "refUnit" })
    ])
  end

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
