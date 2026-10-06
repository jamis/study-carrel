module UserTextsHelper
  # The top bar's trail on the add and revise pages.
  def user_text_crumbs(work)
    trail = [ [ "Library", library_path ], [ "Your Texts", texts_path ] ]
    return trail << [ "Add a text", new_text_path ] unless work

    trail << [ work.title, work_path(work) ] << [ "Revise", edit_text_path(work) ]
  end

  # How a note or keep is named in a revision's review: "Note in “What is grief for?”", "Kept, with a remark".
  def fate_subject(record)
    words = case record
    when Note then [ tag.b("Note"), " in “#{record.focus.title}”" ]
    when Keep then [ tag.b("Kept"), (", with a remark" if record.remark) ]
    end
    tag.span(safe_join(words))
  end

  FATE_TAGS = {
    stays: "stays, sentence unchanged", reworded: "stays, on the reworded sentence",
    detached: "set aside as a detached note", dropped: "bookmark removed (it had no remark)"
  }.freeze

  def fate_tag(fate)
    label = fate.fate == :detached && fate.record.is_a?(Keep) ? "remark set aside, shown on the Kept page" : FATE_TAGS.fetch(fate.fate)
    tag.span(label, class: [ "texts-tag", ("quiet" if fate.fate == :stays) ])
  end

  # The excerpt for a check, with what it's about marked.
  def check_excerpt(check)
    excerpt = check.excerpt.to_s.truncate(160)
    return excerpt unless check.mark && excerpt.include?(check.mark)

    before, after = excerpt.split(check.mark, 2)
    safe_join([ before, tag.mark(check.mark), after ])
  end
end
