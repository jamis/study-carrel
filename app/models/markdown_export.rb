# Renders a focus and its notes as Markdown: the focus, then each noted verse
# (quoted) with its note underneath, in reading order, then any notes set aside
# because their passage changed or was removed (see DetachedNote).
class MarkdownExport
  def initialize(focus)
    @focus = focus
  end

  def filename = "#{@focus.title.parameterize.presence || "focus"}.md"

  def to_s
    out = [ "# #{@focus.title}" ]
    out << @focus.description.strip if @focus.description.present?

    @focus.notes_in_reading_order.each do |note|
      out << "## #{note.unit.reference}"
      out << quote(note.unit.body)
      out << note_markdown(note)
    end

    detached = @focus.detached_notes.includes(:rich_text_content)
    if detached.any?
      out << "## From passages that changed or were removed"
      detached.each do |note|
        out << "### #{note.citation}"
        out << quote(note.passage)
        out << note_markdown(note)
      end
    end

    out.join("\n\n") + "\n"
  end

  private

  def quote(text) = text.lines.map { |l| "> #{l.chomp}" }.join("\n")

  def note_markdown(note)
    md = ReverseMarkdown.convert(note.content.body.to_html, unknown_tags: :bypass, github_flavored: true).strip
    md.gsub(/^(#+) /) { "#{"#" * [ 2, 6 - $1.length ].min}#{$1} " }.gsub(/\n{3,}/, "\n\n")
  end
end
