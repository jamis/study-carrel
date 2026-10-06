# A text a user adds to their own library, from plain text they paste or upload, read a sentence at a time like the
# bundled prose. Nothing here is saved until #publish!; the review page shows #sections and #checks first.
#
# The source is plain text:
#   - If a blank line falls between two lines of text, blank lines separate paragraphs and line breaks inside one are
#     joined. Otherwise every line is a paragraph. Blank lines around headings don't count either way.
#   - A line starting "# " starts a section named by the rest of the line. Text before the first heading is an
#     "Opening" section; with no headings at all the text is one unnamed section.
#   - A backslash beside . ? ! decides a split (see SentenceSplitter.split_marked). Everything else is literal.
class UserText
  include ActiveModel::Model
  include ActiveModel::Attributes

  MAX_BYTES = 5.megabytes
  HEADING = /\A# (.*)\z/
  OPENING = "Opening"

  Section = Struct.new(:label, :line, :paragraphs)
  Paragraph = Struct.new(:line, :sentences, :markers)
  Check = Struct.new(:message, :line, :section, :paragraph, :sentence, :excerpt, :mark, keyword_init: true)

  attribute :title, :string
  attribute :author, :string
  attribute :source, :string

  validates :title, presence: true, length: { maximum: 200 }
  validates :author, length: { maximum: 200 }
  validate :source_is_usable

  def title = super.to_s.strip
  def author = super.to_s.strip.presence
  def source = super.to_s.delete_prefix("\uFEFF").gsub(/\r\n?/, "\n")

  def sections = @sections ||= parse
  def blank_lines_separate? = sections && @blank_lines_separate
  def headed? = sections.any?(&:label)

  # The sections that will be kept: an empty one is left out.
  def kept_sections = sections.select { it.paragraphs.any? }

  # A section's label as it will be saved.
  def label_for(section) = section.label || (OPENING if headed?)

  # A sentence's reference as the reader will cite it (see Section#name): "Journal: 10 March 2024 3:2", or
  # "Journal 3:2" for a text with no headings.
  def reference(section, paragraph, sentence)
    label = label_for(section)
    place = "#{paragraph}:#{sentence}"
    return "#{title} #{place}" if label.nil?

    label.match?(/\A\d+\z/) ? "#{title} #{label} #{place}" : "#{title}: #{label} #{place}"
  end

  def paragraph_count = sections.sum { it.paragraphs.size }
  def sentence_count = sections.sum { |s| s.paragraphs.sum { it.sentences.size } }

  # Places in the text worth a second look before adding it, in reading order.
  def checks
    @checks ||= begin
      found, markdown = [], []
      sections.each_with_index do |section, si|
        found << check("Empty section; it will be left out.", section.line, si, excerpt: "# #{section.label}") if section.paragraphs.empty?
        if section.label.nil? && headed? && section.paragraphs.any?
          found << check("Text before the first heading becomes an untitled opening section.", section.line, si, 0, excerpt: section.paragraphs.first.sentences.first)
        end
        section.paragraphs.each_with_index do |paragraph, pi|
          found.concat(paragraph_checks(section, paragraph, si, pi))
          paragraph.sentences.each_with_index do |sentence, k|
            markdown << check(nil, paragraph.line, si, pi, k, excerpt: sentence, mark: sentence[MARKDOWN]) if sentence.match?(MARKDOWN)
          end
        end
      end
      if markdown.any?
        markdown.first.message = markdown.one? ? "Markdown formatting shows as typed (asterisks and all)." :
          "Markdown formatting shows as typed, in #{markdown.size} sentences."
        found << markdown.first
      end
      found
    end
  end

  # Adds the text to the user's library. Returns the new work.
  def publish!(user)
    Work.transaction do
      work = user.texts.create!(title:, author:, source:, slug: unique_slug, unit_name: "sentence", group_name: "paragraph")
      now = Time.current
      kept_sections.each.with_index(1) do |section, number|
        record = work.sections.create!(number:, label: label_for(section))
        rows = section.paragraphs.each.with_index(1).flat_map do |paragraph, p|
          paragraph.sentences.each.with_index(1).map { |body, s| { paragraph: p, sentence: s, body: } }
        end
        Unit.insert_all(rows.each.with_index(1).map { |row, n| row.merge(section_id: record.id, number: n, created_at: now, updated_at: now) })
      end
      Unit.reindex_search(work.sections.ids)
      work
    end
  end

  private

  MARKDOWN = /\*[^*\s][^*]*\*|_[^_\s][^_]*_|\[[^\]]+\]\([^)]+\)/
  NOT_SPLIT = /[[:space:]]([A-Z])\.[[:space:]]+(?=[“"‘]?[A-Z])/
  SPLIT_AFTER = /(?:\A|[[:space:]])([A-Z][A-Za-z]{0,3}|[A-Za-z]+\.[A-Za-z.]*)\.[”’")\]]*\z/

  def paragraph_checks(section, paragraph, si, pi)
    found = []
    text = paragraph.sentences.join(" ")
    if text.match?(/\A(#\S|\#{2,}[[:space:]])/)
      found << check("Starts with # but isn’t a heading (a heading is # and a space).", paragraph.line, si, pi, 0, excerpt: text)
    elsif paragraph.sentences.one? && text.length < 40 && !text.match?(/[.?!:;,”"’)]\z/) && section.paragraphs.size > 1
      found << check("Looks like a heading. Start the line with “# ” to make it one.", paragraph.line, si, pi, 0, excerpt: text)
    end

    paragraph.sentences.each_with_index do |sentence, k|
      markers = paragraph.markers.select { it[:sentence] == k }
      if (initial = sentence[NOT_SPLIT, 1]) && markers.none? { it[:kind] == :keep }
        found << check("Not split after “#{initial}.” If it ends a sentence, type #{initial}.\\ there.", paragraph.line, si, pi, k, excerpt: sentence, mark: "#{initial}.")
      end
      if (word = sentence[SPLIT_AFTER, 1]) && k < paragraph.sentences.size - 1 && !%w[I A].include?(word) && markers.none? { it[:kind] == :break }
        found << check("Split after “#{word}.” If it doesn’t end a sentence, type #{word}\\. there.", paragraph.line, si, pi, k, excerpt: sentence, mark: "#{word}.")
      end
      found << check("A long sentence (#{sentence.length.to_fs(:delimited)} characters).", paragraph.line, si, pi, k, excerpt: sentence) if sentence.length > 700
      markers.uniq { it[:kind] == :stray ? :stray : it }.each do |marker|
        message = case marker[:kind]
        when :stray then "A backslash shows as typed. Type \\\\ if you meant one."
        when :break then "You ended this sentence by hand."
        else "You kept this sentence together by hand."
        end
        message += " The marker isn’t needed; it would have been read this way anyway." if marker[:needless]
        found << check(message, paragraph.line, si, pi, k, excerpt: sentence, mark: ("\\" if marker[:kind] == :stray))
      end
    end
    found
  end

  def check(message, line, section, paragraph = nil, sentence = nil, excerpt:, mark: nil)
    Check.new(message:, line:, section:, paragraph:, sentence:, excerpt:, mark:)
  end

  def parse
    lines = source.split("\n", -1)
    @blank_lines_separate = blank_line_between_text?(lines)
    sections, current, buffer, buffer_line = [], nil, [], nil

    flush = lambda do
      text = buffer.join(" ").gsub(/[[:space:]]+/, " ").strip
      buffer = []
      next if text.empty?

      sections << (current = Section.new(nil, buffer_line, [])) unless current
      sentences, markers = SentenceSplitter.split_marked(text)
      current.paragraphs << Paragraph.new(buffer_line, sentences, markers)
    end

    lines.each.with_index(1) do |line, number|
      if (heading = line.match(HEADING))
        flush.()
        sections << (current = Section.new(heading[1].strip.presence || "Untitled", number, []))
      elsif line.strip.empty?
        flush.()
      else
        buffer_line = number if buffer.empty?
        buffer << line.strip
        flush.() unless @blank_lines_separate
      end
    end
    flush.()
    sections
  end

  def blank_line_between_text?(lines)
    text = lines.each_index.reject { lines[it].strip.empty? }
    text.each_cons(2).any? { |a, b| b > a + 1 && !lines[a].match?(HEADING) && !lines[b].match?(HEADING) }
  end

  def source_is_usable
    if source.bytesize > MAX_BYTES
      errors.add(:source, "is over #{MAX_BYTES / 1.megabyte} MB")
    elsif source.strip.empty?
      errors.add(:source, "is empty")
    elsif !source.valid_encoding? || source.match?(/[\u0000-\u0008\u000E-\u001F]/)
      errors.add(:source, "isn’t plain text")
    elsif sentence_count.zero?
      errors.add(:source, "has no text outside its headings")
    end
  end

  def unique_slug
    base = title.parameterize.first(60).presence || "text"
    loop do
      slug = "#{base}-#{SecureRandom.alphanumeric(4).downcase}"
      return slug unless Work.exists?(slug:)
    end
  end
end
