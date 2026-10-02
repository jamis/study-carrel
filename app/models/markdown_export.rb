# Renders a focus and its notes as Markdown: the focus, then each noted verse
# (quoted) with its notes underneath, in reading order.
class MarkdownExport
  def initialize(focus)
    @focus = focus
  end

  def filename = "#{@focus.title.parameterize.presence || "focus"}.md"

  def to_s
    out = [ "# #{@focus.title}" ]
    out << @focus.description.strip if @focus.description.present?

    @focus.notes_in_reading_order.group_by(&:unit).each do |unit, notes|
      out << "## #{unit.reference}"
      out << quote(unit.body)
      notes.each { |note| out << note_markdown(note) }
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
