module ReadingsHelper
  # Breadcrumb trail for the top bar: [[label, path, tooltip], ...], Library first, the current page last.
  # Collections nest, so a collection's trail runs through its ancestors; a work adds itself (the edition and
  # author ride along as its tooltip).
  def library_crumbs(collection = nil, work: nil)
    trail = [ [ "Library", library_path, nil ] ]
    (collection ? collection.ancestors + [ collection ] : []).each { |c| trail << [ c.name, collection_path(c), nil ] }
    trail << [ work.title, work_path(work), [ work.byline, work.edition ].compact_blank.join(" · ").presence ] if work
    trail
  end

  # The reading view's trail ends with the chapter. The work is skipped when the chapter's name already
  # starts with its title ("Isaiah 40").
  def reading_crumbs(section)
    work = section.work
    trail = library_crumbs(work.collection, work: (work unless section.name.start_with?(work.title)))
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
