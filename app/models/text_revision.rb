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
#
# Step 3 compares each leftover with every leftover sharing a word with it, which grows with the square of the text.
# Past a budget it isn't attempted, and the revision is refused as too different (#too_different?).
class TextRevision
  Old = Struct.new(:unit, :section, :paragraph, :sentence, :text, keyword_init: true)
  New = Struct.new(:section, :paragraph, :sentence, :text, keyword_init: true)
  # What happens to one note or keep: :stays (on the same sentence), :reworded (on a changed one), :detached, or
  # :dropped (a keep with no remark).
  Fate = Struct.new(:record, :fate, :was, :now, :old_citation, :new_citation, keyword_init: true)

  LIKENESS = 0.3
  # Matching the leftovers past this many comparisons (a couple of seconds) isn't attempted: see #too_different?.
  COMPARISONS = 10_000_000

  attr_reader :work, :text

  def initialize(work, text)
    @work, @text = work, text
  end

  # Too little of the text survives as it was for its leftovers to be matched in reasonable time, as with a different
  # text pasted over it: it can't be saved as a revision, only added as a new text. Nothing else here holds then.
  def too_different? = plan && @too_different

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
    raise ArgumentError, "too different to revise" if too_different?

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
      # By id alone: a sentence can come from a section that's gone (sections merged, headings removed).
      created = Unit.where(id: kept.map { it[:id] }).pluck(:id, :created_at).to_h
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
      @too_different = comparisons > COMPARISONS
      text.poetry? ? match_leftover_stanzas : match_leftovers_in_paired_paragraphs unless @too_different
      true
    end
  end

  # Old section index => new section index.
  def section_map
    @section_map ||= begin
      labels = text.kept_sections.map { text.label_for(it) }
      by_label = labels.each_index.group_by { labels[it] }
      map = {}
      old_sections.each_with_index do |section, i|
        j = by_label[section.label]&.shift
        map[i] = j if j
      end
      taken = map.values.to_set
      old_sections.each_index { |i| map[i] = i if !map.key?(i) && i < labels.size && !taken.include?(i) }
      map
    end
  end

  def claim(old, j, reworded: false)
    @matches[old.unit.id] = j
    @matched_news << j
    @reworded << j if reworded
  end

  def match_by_text_in_section
    free = news.each_index.group_by { [ news[it].text, news[it].section ] }
    olds.each do |old|
      section = section_map[old.section] or next
      js = free[[ old.text, section ]] or next
      k = nearest(js, old.paragraph)
      claim(old, js.delete_at(k)) if k
    end
  end

  # Where in js (new sentences, in reading order) the one nearest paragraph p is; of two as near, the earlier.
  def nearest(js, p)
    above = js.bsearch_index { news[it].paragraph >= p }
    return above if (above || js.size).zero?

    below = js.bsearch_index { news[it].paragraph >= news[js[(above || js.size) - 1]].paragraph }
    above.nil? || p - news[js[below]].paragraph <= news[js[above]].paragraph - p ? below : above
  end

  def match_by_text_anywhere
    old_counts = olds.map(&:text).tally
    olds.each do |old|
      next if @matches.key?(old.unit.id) || old_counts[old.text] > 1

      free = news_by_text.fetch(old.text, []).reject { @matched_news.include?(it) }
      claim(old, free.first) if free.one?
    end
  end

  def match_leftovers_in_paired_paragraphs
    by_id = olds.index_by { it.unit.id }
    votes = Hash.new { |h, k| h[k] = Hash.new(0) }
    @matches.each do |id, j|
      old = by_id.fetch(id)
      votes[[ old.section, old.paragraph ]][[ news[j].section, news[j].paragraph ]] += 1
    end
    pairs = votes.transform_values { |v| v.max_by(&:last).first }

    olds.each do |old|
      next if @matches.key?(old.unit.id)

      to = pairs[[ old.section, old.paragraph ]]
      section = section_map[old.section]
      next unless to || section

      best = alike(old).select { |j, _| to ? [ news[j].section, news[j].paragraph ] == to : news[j].section == section }
                       .max_by { |j, likeness| [ likeness, -(news[j].paragraph - old.paragraph).abs ] }
      claim(old, best.first, reworded: true) if best && best.last >= LIKENESS
    end
  end

  def match_leftover_stanzas
    pairs = olds.flat_map do |old|
      section = section_map[old.section]
      next [] if @matches.key?(old.unit.id) || section.nil?

      alike(old).filter_map do |j, likeness|
        [ old, j, likeness, (news[j].paragraph - old.paragraph).abs ] if news[j].section == section && likeness >= LIKENESS
      end
    end
    pairs.sort_by { |_, _, likeness, distance| [ -likeness, distance ] }.each do |old, j|
      claim(old, j, reworded: true) unless @matches.key?(old.unit.id) || @matched_news.include?(j)
    end
  end

  # The free new sentences sharing a word with old, in reading order, each with how alike the two are. One sharing no
  # word is 0 alike, so it's never a match and needn't be looked at.
  def alike(old)
    a = words(old.text)
    shared = Hash.new(0)
    a.each { |word| news_by_word.fetch(word, []).each { shared[it] += 1 unless @matched_news.include?(it) } }
    shared.keys.sort.map { |j| [ j, likeness(shared[j], a.size, words(news[j].text).size) ] }
  end

  # How much work matching the leftovers takes: for each, the free new sentences each of its words is in.
  def comparisons
    olds.sum { |old| @matches.key?(old.unit.id) ? 0 : words(old.text).sum { news_by_word.fetch(it, []).size } }
  end

  def likeness(shared, a, b) = shared.to_f / [ 1, [ a, b ].min + (a - b).abs / 2.0 ].max

  def words(text) = (@words ||= {})[text] ||= text.downcase.scan(/[a-z’']+/).to_set

  def news_by_text = @news_by_text ||= news.each_index.group_by { news[it].text }

  # The new sentences still free once those matched exactly are taken (it's first wanted after that), by word. Those
  # already matched would only be passed over, and in a long text the common words are in thousands of them.
  def news_by_word
    @news_by_word ||= news.each_index.each_with_object(Hash.new { |h, k| h[k] = [] }) do |j, index|
      words(news[j].text).each { index[it] << j } unless @matched_news.include?(j)
    end
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
