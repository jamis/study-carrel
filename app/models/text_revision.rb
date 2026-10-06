# Replaces a user's own text with a revised source (a UserText), keeping every sentence that survives, with its notes,
# keeps and history. The bundled loader matches by section and paragraph number, which a revision upsets (a heading or
# a paragraph added renumbers everything after it), so this matches more loosely:
#
#   1. Sections by name, then by place.
#   2. Sentences by their exact text, in their own section (the nearest paragraph first), then anywhere in the text if
#      only one sentence has that text.
#   3. Each old paragraph is paired with the new one most of its sentences went to; a sentence still unmatched takes the
#      most alike leftover sentence in that paragraph (a rewording, or one half of a sentence split in two), or, if its
#      paragraph has no pair (a one-line paragraph reworded), in its section, as long as they share enough words. A
#      sentence merely in the same place is not a match: a note on it is set aside with its passage rather than quietly
#      hung on words it wasn't written about.
#
# Poetry is matched the same way a stanza at a time, except that stanzas have no paragraph to pair: in step 2 the
# nearest place sorts out a chorus sung twice, and in step 3 a leftover stanza takes the most alike leftover in its
# section, the most alike pairs first.
#
# A sentence left over is gone: its notes and remarked keeps are set aside as detached notes (see DetachedNote).
# #changes describes all this before anything is saved, for the review.
class TextRevision
  Old = Struct.new(:unit, :section, :paragraph, :sentence, :text, keyword_init: true)
  New = Struct.new(:section, :paragraph, :sentence, :text, keyword_init: true)
  # What happens to one note or keep: :stays (on the same sentence), :reworded (on a changed one), :detached, or
  # :dropped (a keep with no remark).
  Fate = Struct.new(:record, :fate, :was, :now, :old_citation, :new_citation, keyword_init: true)

  LIKENESS = 0.3

  attr_reader :work, :text

  def initialize(work, text)
    @work, @text = work, text
  end

  # Old units' ids mapped to the index of the new sentence each became.
  def matches = plan && @matches

  # :same, :reworded or :new for each new sentence, in reading order.
  def statuses = @statuses ||= news.each_index.map { |j| reworded.include?(j) ? :reworded : matched_news.include?(j) ? :same : :new }

  def gone = olds.reject { matches.key?(it.unit.id) }

  def counts = statuses.tally.merge(gone: gone.size)

  # Every note and keep on the text, and what the revision does to it: the ones that move or go first.
  def fates
    @fates ||= begin
      by_id = olds.index_by { it.unit.id }
      records = Note.where(unit_id: by_id.keys).includes(:focus, :rich_text_content).to_a +
                Keep.where(unit_id: by_id.keys).to_a
      records.map { |record| fate_for(record, by_id.fetch(record.unit_id)) }
             .sort_by { [ %i[detached dropped reworded stays].index(it.fate), it.old_citation ] }
    end
  end

  # The reference a new sentence will have, as in the reader.
  def citation_for(j)
    new = news[j]
    text.reference(text.kept_sections[new.section], new.paragraph + 1, new.sentence + 1)
  end

  def apply!
    Work.transaction do
      DetachedNote.set_aside!(Unit.where(id: gone.map { it.unit.id }), reason: "revised")
      Unit.unindex_search(gone.map { it.unit.id })
      Unit.where(id: gone.map { it.unit.id }).delete_all

      sections = save_sections
      units = Unit.where(section_id: sections.values.map(&:id))
      units.update_all("number = -id") # out of the unique (section, number) index's way while renumbering
      now = Time.current
      by_new = matches.invert
      numbers = Hash.new(0)
      rows = news.each_with_index.map do |new, j|
        section_id = sections.fetch(new.section).id
        { section_id:, number: numbers[section_id] += 1, **text.unit_place(new.paragraph + 1, new.sentence + 1), body: new.text,
          updated_at: now, id: by_new[j] }
      end
      kept, added = rows.partition { it[:id] }
      created = units.where(id: kept.map { it[:id] }).pluck(:id, :created_at).to_h
      Unit.upsert_all(kept.map { it.merge(created_at: created.fetch(it[:id])) }) if kept.any?
      Unit.insert_all(added.map { it.except(:id).merge(created_at: now) }) if added.any?

      Section.where(work_id: work.id).where.not(id: sections.values.map(&:id)).delete_all
      work.update!(title: text.title, author: text.author, source: text.source)
      Unit.reindex_search(sections.values.map(&:id))
    end
    work
  end

  private

  def olds
    @olds ||= begin
      old_sections.each_with_index.flat_map do |section, si|
        section.units.map do |unit|
          Old.new(unit:, section: si, paragraph: (unit.paragraph || unit.number) - 1, sentence: (unit.sentence || 1) - 1, text: unit.body)
        end
      end
    end
  end

  def old_sections = @old_sections ||= Section.where(work_id: work.id).order(:number).includes(:work, units: :section).to_a

  def news
    @news ||= text.kept_sections.each_with_index.flat_map do |section, si|
      section.paragraphs.each_with_index.flat_map do |paragraph, pi|
        paragraph.sentences.each_with_index.map { |sentence, k| New.new(section: si, paragraph: pi, sentence: k, text: sentence) }
      end
    end
  end

  def matched_news = plan && @matched_news
  def reworded = plan && @reworded

  def plan
    @plan ||= begin
      @matches, @matched_news, @reworded = {}, Set.new, Set.new
      match_by_text_in_section
      match_by_text_anywhere
      text.poetry? ? match_leftover_stanzas : match_leftovers_in_paired_paragraphs
      true
    end
  end

  # Old section index => new section index.
  def section_map
    @section_map ||= begin
      labels = text.kept_sections.map { text.label_for(it) }
      map = {}
      old_sections.each_with_index do |section, i|
        j = labels.each_index.find { |j| !map.value?(j) && labels[j] == section.label }
        map[i] = j if j
      end
      old_sections.each_index { |i| map[i] = i if !map.key?(i) && i < labels.size && !map.value?(i) }
      map
    end
  end

  def claim(old, j, reworded: false)
    @matches[old.unit.id] = j
    @matched_news << j
    @reworded << j if reworded
  end

  def match_by_text_in_section
    by_text = news.each_index.group_by { news[it].text }
    olds.each do |old|
      section = section_map[old.section] or next
      j = by_text.fetch(old.text, []).reject { @matched_news.include?(it) }.select { news[it].section == section }
                 .min_by { (news[it].paragraph - old.paragraph).abs }
      claim(old, j) if j
    end
  end

  def match_by_text_anywhere
    old_counts = olds.map(&:text).tally
    olds.each do |old|
      next if @matches.key?(old.unit.id) || old_counts[old.text] > 1

      free = news.each_index.select { !@matched_news.include?(it) && news[it].text == old.text }
      claim(old, free.first) if free.one?
    end
  end

  def match_leftovers_in_paired_paragraphs
    votes = Hash.new { |h, k| h[k] = Hash.new(0) }
    @matches.each do |id, j|
      old = olds.find { it.unit.id == id }
      votes[[ old.section, old.paragraph ]][[ news[j].section, news[j].paragraph ]] += 1
    end
    pairs = votes.transform_values { |v| v.max_by(&:last).first }

    olds.each do |old|
      next if @matches.key?(old.unit.id)

      to = pairs[[ old.section, old.paragraph ]]
      section = section_map[old.section]
      next unless to || section

      free = news.each_index.select do |j|
        !@matched_news.include?(j) && (to ? [ news[j].section, news[j].paragraph ] == to : news[j].section == section)
      end
      best = free.max_by { [ likeness(old.text, news[it].text), -(news[it].paragraph - old.paragraph).abs ] }
      claim(old, best, reworded: true) if best && likeness(old.text, news[best].text) >= LIKENESS
    end
  end

  def match_leftover_stanzas
    pairs = olds.flat_map do |old|
      section = section_map[old.section]
      next [] if @matches.key?(old.unit.id) || section.nil?

      news.each_index.filter_map do |j|
        next if @matched_news.include?(j) || news[j].section != section

        likeness = likeness(old.text, news[j].text)
        [ old, j, likeness, (news[j].paragraph - old.paragraph).abs ] if likeness >= LIKENESS
      end
    end
    pairs.sort_by { |_, _, likeness, distance| [ -likeness, distance ] }.each do |old, j|
      claim(old, j, reworded: true) unless @matches.key?(old.unit.id) || @matched_news.include?(j)
    end
  end

  def likeness(a, b)
    words = ->(s) { s.downcase.scan(/[a-z’']+/).to_set }
    a, b = words.(a), words.(b)
    (a & b).size.to_f / [ 1, [ a.size, b.size ].min + (a.size - b.size).abs / 2.0 ].max
  end

  def fate_for(record, old)
    j = matches[old.unit.id]
    fate = if j then reworded.include?(j) ? :reworded : :stays
    elsif record.is_a?(Keep) && record.remark.nil? then :dropped
    else :detached
    end
    Fate.new(record:, fate:, was: old.text, now: (news[j].text if j), old_citation: old.unit.reference, new_citation: (citation_for(j) if j))
  end

  # The new sections' records, by index: a matched old section keeps its record (renumbered and relabelled), and the
  # rest are created.
  def save_sections
    Section.where(work_id: work.id).update_all("number = -id")
    by_new = section_map.invert
    text.kept_sections.each_with_index.to_h do |section, j|
      attrs = { number: j + 1, label: text.label_for(section) }
      record = by_new[j] ? old_sections[by_new[j]].tap { it.update_columns(attrs) } : Section.create!(work:, **attrs)
      [ j, record ]
    end
  end
end
