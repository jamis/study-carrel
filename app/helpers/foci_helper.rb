module FociHelper
  # "since September 14, 2026" for the current focus; "Jun – Sep 2026" or "Nov 2025 – Jan 2026" for a past one.
  def focus_span(focus)
    return "since #{l focus.created_at.to_date, format: :long}" unless focus.archived?

    from, to = focus.created_at.to_date, focus.archived_at.to_date
    if from.beginning_of_month == to.beginning_of_month then to.strftime("%b %Y")
    elsif from.year == to.year then "#{from.strftime("%b")} – #{to.strftime("%b %Y")}"
    else "#{from.strftime("%b %Y")} – #{to.strftime("%b %Y")}"
    end
  end

  # "12 notes in Ruth, Leviticus and Deuteronomy", or "No notes yet". The count can link (to the notes page).
  def notes_line(count, works, link: nil)
    return "No notes yet" if count.zero?

    number = link ? link_to(pluralize(count, "note"), link) : pluralize(count, "note")
    works.any? ? safe_join([ number, " in ", works.to_sentence ]) : number
  end
end
