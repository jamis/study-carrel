module UserTextsHelper
  # A sentence's reference as the reader will cite it (see Section#name): "Journal: 10 March 2024 3:2", or "Journal 3:2"
  # for a text with no headings.
  def review_reference(text, section, paragraph, sentence)
    label = text.label_for(section)
    place = "#{paragraph}:#{sentence}"
    return "#{text.title} #{place}" if label.nil?

    label.match?(/\A\d+\z/) ? "#{text.title} #{label} #{place}" : "#{text.title}: #{label} #{place}"
  end

  # The excerpt for a check, with what it's about marked.
  def check_excerpt(check)
    excerpt = check.excerpt.to_s.truncate(160)
    return excerpt unless check.mark && excerpt.include?(check.mark)

    before, after = excerpt.split(check.mark, 2)
    safe_join([ before, tag.mark(check.mark), after ])
  end
end
