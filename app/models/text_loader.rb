# Loads a bundled text file into Work > Section > Unit. Format:
#
#   work: Isaiah
#   edition: KJV
#   slug: isaiah-kjv        (optional; defaults to the parameterized name)
#
#   section: 40
#   label: 40               (optional; defaults to the number)
#   1. Comfort ye, comfort ye my people...
#   2. Speak ye comfortably...
#
# A unit continues on following lines until the next "N. " line, a blank line,
# or a "section:" line, so a prose paragraph may be wrapped. Reloading a file
# replaces that work (and anything attached to its units).
class TextLoader
  class Error < StandardError; end

  UNIT = /\A(\d+)\.\s+(.*)\z/

  def self.load_all(dir = Rails.root.join("db/texts"))
    Dir[File.join(dir, "*.txt")].sort.map { |path| load_file(path) }
  end

  def self.load_file(path) = new(File.read(path), source: path).load

  def initialize(text, source: "text")
    @text, @source = text, source
  end

  def load
    meta, sections = parse
    title = meta["work"] or fail_with("missing 'work:'")
    slug = meta["slug"].presence || [ title, meta["edition"] ].compact.join(" ").parameterize

    Work.transaction do
      Work.find_by(slug: slug)&.destroy!
      work = Work.create!(title: title, edition: meta["edition"], slug: slug)
      sections.each do |s|
        section = work.sections.create!(number: s[:number], label: s[:label])
        s[:units].each { |number, body| section.units.create!(number: number, body: body) }
      end
      work
    end
  end

  private

  def fail_with(msg) = raise(Error, "#{@source}: #{msg}")

  def parse
    meta, sections = {}, []
    section = unit = nil

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
        unit[1] << " " << line
      else
        fail_with("line #{lineno}: text outside a numbered unit")
      end
    end

    [ meta, sections ]
  end
end
