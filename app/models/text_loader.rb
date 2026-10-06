# Loads the bundled texts into Collection > Work > Section > Unit.
#
# db/texts/collections.yml lists the collections:
#
#   - slug: old-testament
#     name: Old Testament
#     position: 1
#     parent: bible           (optional; the slug of the collection this one is nested in)
#     single_work: true       (optional; the collection is one work in its own right, e.g. the Bible: it counts as one
#                              item in its parent and shows no count of its own)
#     description: ...
#
# Each db/texts/*.txt file is one work:
#
#   work: Isaiah
#   edition: KJV
#   author: Robert Frost    (optional; shown with the title in the library)
#   author_short: Frost     (optional; used in the reading view, defaults to author)
#   slug: isaiah-kjv        (optional; defaults to the parameterized name)
#   collection: old-testament   (optional; a slug from collections.yml)
#   position: 23            (optional; order within the whole library)
#   unit: paragraph         (optional; what a unit is called, default "verse")
#   group: paragraph        (with "unit: sentence": what a group of sentences is called)
#   lines: keep             (optional; keep line breaks inside a unit, for poetry)
#
#   section: 40
#   label: 40               (optional; defaults to the number)
#   1. Comfort ye, comfort ye my people...
#   2. Speak ye comfortably...
#
# A unit continues on following lines until the next "N. " line, a blank line,
# or a "section:" line, so a prose paragraph may be wrapped.
#
# Prose is read a sentence at a time. A work with "unit: sentence" numbers each
# sentence by its paragraph (or thought, or section) and its place in it, and the
# loader numbers the units in reading order through the section:
#
#   12.1 But men labor under a mistake.
#   12.2 The better part of the man is soon plowed into the soil for compost.
#
# Loading is an update in place: works, sections and units are matched by slug
# and number and keep their ids, so notes attached to verses survive a reload.
# Units that disappear from a file are left alone. Sentences are matched by their
# text within the paragraph, then by their place in it (see #load_sentences).
class TextLoader
  class Error < StandardError; end

  UNIT = /\A(\d+)\.\s+(.*)\z/
  SENTENCE = /\A(\d+)\.(\d+)\s+(.*)\z/

  def self.load_all(dir = Rails.root.join("db/texts"))
    load_collections(File.join(dir, "collections.yml"))
    Dir[File.join(dir, "*.txt")].sort.map { |path| load_file(path) }
  end

  def self.load_collections(path)
    return unless File.exist?(path)

    entries = YAML.safe_load_file(path)
    entries.each do |attrs|
      Collection.find_or_initialize_by(slug: attrs.fetch("slug")).update!(attrs.slice("name", "position", "description", "single_work"))
    end

    # Parents are linked in a second pass so a file can list them in any order.
    entries.each do |attrs|
      parent = attrs["parent"] && (Collection.find_by(slug: attrs["parent"]) or
        raise Error, "#{path}: unknown parent '#{attrs["parent"]}' for '#{attrs["slug"]}'")
      Collection.find_by!(slug: attrs.fetch("slug")).update!(parent: parent)
    end
  end

  def self.load_file(path) = new(File.read(path), source: path).load

  def initialize(text, source: "text")
    @text, @source = text, source
  end

  def load
    meta, sections = parse
    title = meta["work"] or fail_with("missing 'work:'")
    slug = meta["slug"].presence || [ title, meta["edition"] ].compact.join(" ").parameterize
    collection = find_collection(meta["collection"])

    Work.transaction do
      work = Work.find_or_initialize_by(slug: slug)
      work.update!(title: title, edition: meta["edition"], author: meta["author"].presence,
                   author_short: meta["author_short"].presence, collection: collection, position: meta["position"].to_i,
                   unit_name: meta["unit"].presence || "verse", group_name: meta["group"].presence)
      sections.each { |s| load_section(work, s) }
      work
    end
  end

  private

  def load_section(work, data)
    section = work.sections.find_or_initialize_by(number: data[:number])
    section.update!(label: data[:label])

    if work.sentences?
      load_sentences(section, data[:units])
    else
      rows = data[:units].map { |number, body| { section_id: section.id, number: number, body: body } }
      Unit.upsert_all(rows, unique_by: %i[section_id number]) if rows.any?
    end
    Unit.reindex_search([ section.id ])
  end

  # Sentences are numbered in reading order, so splitting a sentence in two renumbers everything after it. Existing
  # rows keep their ids (and so their notes, keeps and history) by matching first on the same text in the same
  # paragraph, then on the same place in it. A paragraph loaded before prose was split into sentences becomes its
  # first sentence. A row left unmatched is deleted, unless something hangs off it; then it waits after the last
  # sentence.
  def load_sentences(section, sentences)
    existing = section.units.to_a
    by_text = existing.select(&:paragraph).index_by { [ it.paragraph, it.body ] }
    by_place = existing.index_by { it.paragraph ? [ it.paragraph, it.sentence ] : [ it.number, 1 ] }

    claimed = Set.new
    claim = ->(row) { row if row && claimed.add?(row.id) }
    rows = sentences.map { |p, _s, body| claim.(by_text[[ p, body ]]) }
    rows = rows.zip(sentences).map { |row, (p, s, _)| row || claim.(by_place[[ p, s ]]) }

    orphans = existing.reject { claimed.include?(it.id) }
    attached = attached_unit_ids(orphans.map(&:id))
    gone = orphans.map(&:id) - attached

    Unit.unindex_search(gone)
    Unit.where(id: gone).delete_all
    # Park the rest out of the unique (section, number) index's way while they are renumbered.
    Unit.where(section_id: section.id).update_all("number = -id")

    now = Time.current
    values = sentences.each_with_index.map do |(p, s, body), i|
      { section_id: section.id, number: i + 1, body: body, paragraph: p, sentence: s, updated_at: now }
    end
    updates, inserts = values.zip(rows).partition { |_, row| row }
    Unit.upsert_all(updates.map { |v, row| v.merge(id: row.id, created_at: row.created_at) }) if updates.any?
    Unit.insert_all(inserts.map { |v, _| v.merge(created_at: now) }) if inserts.any?
    orphans.select { attached.include?(it.id) }.each.with_index(sentences.size + 1) { |row, n| row.update_columns(number: n) }
  end

  def attached_unit_ids(ids)
    [ Note, Keep, Visit ].flat_map { it.where(unit_id: ids).distinct.pluck(:unit_id) } +
      Focus.where(last_unit_id: ids).distinct.pluck(:last_unit_id)
  end

  def find_collection(slug)
    return if slug.blank?

    Collection.find_by(slug: slug) or fail_with("unknown collection '#{slug}'")
  end

  def fail_with(msg) = raise(Error, "#{@source}: #{msg}")

  # Each paragraph starts at sentence 1 and counts up; paragraphs count up too.
  def check_sentence_order(prev, (p, s, _), lineno)
    ok = prev ? (p == prev[0] && s == prev[1] + 1) || (p > prev[0] && s == 1) : s == 1
    fail_with("line #{lineno}: sentence #{p}.#{s} out of order") unless ok
  end

  def parse
    meta, sections = {}, []
    section = unit = nil
    @keep_lines = @text[/^lines:\s*keep\s*$/]
    sentences = @text.match?(/^unit:\s*sentence\s*$/)

    @text.each_line.with_index(1) do |raw, lineno|
      line = raw.strip
      if line.empty?
        unit = nil
      elsif line =~ /\Asection:\s*(\d+)\z/
        section = { number: $1.to_i, label: nil, units: [] }
        sections << section
        unit = nil
      elsif section.nil?
        key, value = line.split(/:\s*/, 2)
        fail_with("line #{lineno}: expected 'key: value'") if value.nil?
        meta[key] = value
      elsif line =~ /\Alabel:\s*(.+)\z/ && section[:units].empty?
        section[:label] = $1
      elsif sentences && line =~ SENTENCE
        unit = [ $1.to_i, $2.to_i, +$3 ]
        check_sentence_order(section[:units].last, unit, lineno)
        section[:units] << unit
      elsif line =~ UNIT
        fail_with("line #{lineno}: expected a numbered sentence (\"#{$1}.1 …\")") if sentences
        unit = [ $1.to_i, +$2 ]
        section[:units] << unit
      elsif unit
        unit.last << (@keep_lines ? "\n" : " ") << line
      else
        fail_with("line #{lineno}: text outside a numbered unit")
      end
    end

    [ meta, sections ]
  end
end
