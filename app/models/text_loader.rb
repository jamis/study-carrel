# Loads the bundled texts into Collection > Work > Section > Unit.
#
# db/texts/collections.yml lists the collections:
#
#   - slug: old-testament
#     name: Old Testament
#     position: 1
#     parent: bible           (optional; the slug of the collection this one is nested in)
#     description: ...
#
# Each db/texts/*.txt file is one work:
#
#   work: Isaiah
#   edition: KJV
#   slug: isaiah-kjv        (optional; defaults to the parameterized name)
#   collection: old-testament   (optional; a slug from collections.yml)
#   position: 23            (optional; order within the whole library)
#   unit: paragraph         (optional; what a unit is called, default "verse")
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
# Loading is an update in place: works, sections and units are matched by slug
# and number and keep their ids, so notes attached to verses survive a reload.
# Units that disappear from a file are left alone.
class TextLoader
  class Error < StandardError; end

  UNIT = /\A(\d+)\.\s+(.*)\z/

  def self.load_all(dir = Rails.root.join("db/texts"))
    load_collections(File.join(dir, "collections.yml"))
    Dir[File.join(dir, "*.txt")].sort.map { |path| load_file(path) }
  end

  def self.load_collections(path)
    return unless File.exist?(path)

    entries = YAML.safe_load_file(path)
    entries.each do |attrs|
      Collection.find_or_initialize_by(slug: attrs.fetch("slug")).update!(attrs.slice("name", "position", "description"))
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
      work.update!(title: title, edition: meta["edition"], collection: collection, position: meta["position"].to_i,
                   unit_name: meta["unit"].presence || "verse")
      sections.each { |s| load_section(work, s) }
      work
    end
  end

  private

  def load_section(work, data)
    section = work.sections.find_or_initialize_by(number: data[:number])
    section.update!(label: data[:label])

    rows = data[:units].map { |number, body| { section_id: section.id, number: number, body: body } }
    Unit.upsert_all(rows, unique_by: %i[section_id number]) if rows.any?
  end

  def find_collection(slug)
    return if slug.blank?

    Collection.find_by(slug: slug) or fail_with("unknown collection '#{slug}'")
  end

  def fail_with(msg) = raise(Error, "#{@source}: #{msg}")

  def parse
    meta, sections = {}, []
    section = unit = nil
    @keep_lines = @text[/^lines:\s*keep\s*$/]

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
      elsif line =~ UNIT
        unit = [ $1.to_i, +$2 ]
        section[:units] << unit
      elsif unit
        unit[1] << (@keep_lines ? "\n" : " ") << line
      else
        fail_with("line #{lineno}: text outside a numbered unit")
      end
    end

    [ meta, sections ]
  end
end
