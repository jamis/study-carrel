module ReadingsHelper
  # Breadcrumb trail for the top bar: [[label, path, tooltip], ...], Library first, the current page last.
  # Collections nest, so a collection's trail runs through its ancestors; a work adds itself (the edition and
  # author ride along as its tooltip). A user's own text or collection sits in Your Texts (own_text:, which defaults to
  # the work's or collection's, so the reading view can keep it when it drops the work crumb).
  def library_crumbs(collection = nil, work: nil, own_text: work&.own_text? || collection&.own?)
    trail = [ [ "Library", library_path, nil ] ]
    trail << [ "Your Texts", texts_path, "Only you can see these" ] if own_text
    (collection ? collection.ancestors + [ collection ] : []).each { |c| trail << [ c.name, collection_path(c), nil ] }
    trail << [ work.title, work_path(work), [ work.byline, work.edition ].compact_blank.join(" · ").presence ] if work
    trail
  end

  # Above a page's title, quietly, the way up: every step of its crumbs but the last (the title names the page itself).
  # A block adds the page's actions at the right (Kept's order, the notes page's export).
  def page_head(crumbs = [], &actions)
    up = crumbs[0...-1]
    return if up.empty? && !actions

    trail = tag.nav(class: "page-trail", aria: { label: "Breadcrumb" }) do
      tag.ol { safe_join(up.map { |label, path, title| tag.li(link_to(label, path, title: title)) }) }
    end
    tag.div(class: "page-head") { safe_join([ up.any? ? trail : tag.span, (capture(&actions) if actions) ]) }
  end

  # The reading view's trail ends with the chapter. When the chapter's name is the work's title plus a number
  # ("Isaiah 40") the work crumb is skipped; when it is "Work: Label" (Pensées: Of the Means of Belief) the work
  # stays as its own crumb and the last one shows just the label, so it reads as a chapter of that work.
  def reading_crumbs(section)
    work = section.work
    label = section.name.delete_prefix("#{work.title}: ")
    own_crumb = label != section.name || !section.name.start_with?(work.title)
    trail = library_crumbs(work.collection, work: (work if own_crumb), own_text: work.own_text?)
    trail << [ label, work_path(work), "Chapters in #{work.title}#{" (#{work.edition})" if work.edition.present?}" ]
  end

  # A chapter either side, as the trail names it: one in the same work by its own name ("Economy", not "Walden:
  # Economy"), so a long work title doesn't crowd it out; a numbered chapter, or one in another work, in full.
  def neighbor_name(section, neighbor)
    neighbor.work == section.work ? neighbor.reference_name_parts.last : neighbor.name
  end

  def unit_ref(section, unit) = section.reference(unit.label)

  # Work title, section name and unit in separate spans (see .ref-work / .ref-section / .ref-unit); the browser updates the unit as the reader moves.
  def unit_ref_parts(section, unit)
    work, name = section.reference_name_parts
    safe_join([
      (tag.span(work, class: "ref-work") if work.present?),
      tag.span(name, class: "ref-section"),
      tag.span(section.reference_unit_template.sub("{n}", unit.label), class: "ref-unit", data: { lectio_target: "refUnit" })
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
