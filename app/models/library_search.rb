# Full-text search over the library's units (the unit_search FTS5 table), in one work, a collection with everything
# nested under it, or the whole library (place nil). Every word must appear; "quoted words" match as a phrase, and a
# trailing * matches the start of a word (sanctif*). Words are stemmed, so "holiness" finds "holy". Results come in
# reading order, with a count per work for narrowing.
class LibrarySearch
  PER_PAGE = 50

  # snippet() marks matches with these; the view escapes the text and then turns them into <mark>.
  MARK_START, MARK_END = "\u0002", "\u0003"

  attr_reader :query, :place, :user

  # Only the bundled library and the user's own texts are searched (see Work.visible_to).
  def initialize(query, place: nil, user: nil)
    @query, @place, @user = query.to_s.strip, place, user
  end

  # The FTS5 expression: each word or phrase quoted, so the reader's punctuation and words like NOT or OR are just
  # text, never FTS syntax. Nil when the query has nothing to search for.
  def expression
    @expression ||= query.scan(/"([^"]*)"?|([^\s"]+)/).filter_map do |phrase, word|
      text = (phrase || word).delete("*")
      next unless text.match?(/[[:alnum:]]/)

      %("#{text}"#{"*" if word&.end_with?("*")})
    end.join(" ").presence
  end

  def searching? = expression.present?

  # Matches per work, in reading order: { work => count }.
  def counts
    @counts ||= begin
      by_work = matches.group("sections.work_id").count
      Work.where(id: by_work.keys).in_order_of(:id, library_order).to_h { [ it, by_work[it.id] ] }
    end
  end

  def total = counts.values.sum
  def pages = (total / PER_PAGE.to_f).ceil

  # One page of matching units in reading order, each with an #excerpt around the match (see MARK_START).
  def page(number)
    matches.in_order_of(:"sections.work_id", library_order).order("sections.number", "units.number")
           .offset((number - 1) * PER_PAGE).limit(PER_PAGE)
           .select("units.*", "snippet(unit_search, 0, char(2), char(3), '…', 48) AS excerpt")
           .preload(section: :work)
  end

  private

  def library_order = @library_order ||= Work.ids_in_library_order

  def matches
    return Unit.none unless searching?

    units = Unit.visible_to(user).joins("JOIN unit_search ON unit_search.rowid = units.id")
                .where("unit_search MATCH ?", expression)
    case place
    when nil then units
    when Work then units.where(sections: { work_id: place.id })
    else units.where(works: { collection_id: place.self_and_descendant_ids })
    end
  end
end
